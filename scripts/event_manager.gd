class_name EventManager
extends Node
## 隐藏事件系统管理器（M3-B P0）
## 负责加载事件配置、按触发时机激活事件、管理事件状态、发放奖励。
## 与 CSV 波次系统解耦，向后兼容（无事件配置的关卡正常运行）。
##
## 事件配置文件路径：res://resources/level_data/events_stage_<stage_id>.json
## 文件不存在时静默跳过，不影响关卡正常运行。

# ============================================================
# 信号定义
# ============================================================

## 事件被触发（激活）时发出
signal event_triggered(event_id: String, event_type: String)

## 事件完成时发出，rewards 为奖励字典
signal event_completed(event_id: String, rewards: Dictionary)

## 事件失败时发出
signal event_failed(event_id: String)

# ============================================================
# 枚举
# ============================================================

## 事件状态
enum EventState {
	INACTIVE,   ## 未触发
	ACTIVE,     ## 进行中
	COMPLETED,  ## 已完成
	FAILED,     ## 已失败
}

# ============================================================
# 常量
# ============================================================

## 事件配置文件目录
const EVENTS_DIR: String = "res://resources/level_data/"

## 道具场景路径（用于 drop_items 奖励掉落）
const POWERUP_SCENE_PATH: String = "res://scenes/powerups/powerup.tscn"

## 可摧毁物体场景路径（渡桥等静态目标，用于 destroy_targets 事件）
const DESTRUCTIBLE_SCENE_PATH: String = "res://scenes/events/event_target_bridge.tscn"

# ============================================================
# 内部状态
# ============================================================

## 所有事件配置：event_id -> 事件字典
var _events: Dictionary = {}

## 事件状态：event_id -> EventState
var _event_states: Dictionary = {}

## 关卡已用时间（秒）
var _elapsed_time: float = 0.0

## 活跃的事件目标：event_id -> EventTargetBase 节点引用
var _active_targets: Dictionary = {}

## 待处理的事件 ID（用于 _spawn_kill_target 与信号回调之间传递）
var _pending_event_id: String = ""

## 待处理的逃脱时间
var _pending_escape_time: float = 0.0

## 待处理的目标 HP
var _pending_hp: int = 50

## 待处理的目标速度
var _pending_speed: float = 180.0

## 当前关卡 ID
var _stage_id: String = ""

## 已摧毁目标计数：event_id -> int（用于 destroy_targets 事件）
var _destroyed_count: Dictionary = {}

## 需要摧毁的目标数量：event_id -> int
var _required_count: Dictionary = {}

## 目标 ID → 事件 ID 映射（用于 report_target_destroyed 查找所属事件）
var _target_to_event: Dictionary = {}


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	add_to_group("event_manager")
	set_process(true)


func _process(delta: float) -> void:
	# 仅在父级关卡激活时计时
	var parent: Node = get_parent()
	if parent != null and "is_level_active" in parent:
		if not parent.is_level_active:
			return

	_elapsed_time += delta
	_check_time_triggers()


# ============================================================
# 事件加载
# ============================================================

## 加载指定关卡的事件配置
## [param stage_id]: 关卡标识符（如 "01_kunming"）
## 文件不存在时静默跳过，保证向后兼容
func load_events(stage_id: String) -> void:
	_stage_id = stage_id
	var path: String = EVENTS_DIR + "events_stage_" + stage_id + ".json"

	if not FileAccess.file_exists(path):
		# 静默跳过，向后兼容
		return

	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_warning("[EventManager] 事件配置文件为空: %s" % path)
		return

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("[EventManager] 事件配置解析失败: %s (行 %d: %s)" % [path, json.get_error_line(), json.get_error_message()])
		return

	var data: Dictionary = json.data
	var events: Array = data.get("events", [])

	for event in events:
		var eid: String = event.get("event_id", "")
		if eid.is_empty():
			continue
		_events[eid] = event
		_event_states[eid] = EventState.INACTIVE

	print("[EventManager] 关卡 '%s' 已加载 %d 个事件" % [stage_id, _events.size()])

	# 处理 on_stage_start 触发时机
	for eid in _events:
		var event: Dictionary = _events[eid]
		var trigger: Dictionary = event.get("trigger", {})
		if trigger.get("timing", "") == "on_stage_start":
			_try_trigger_event(eid)


# ============================================================
# 触发检查
# ============================================================

## 检查 on_time 触发时机的事件
func _check_time_triggers() -> void:
	for eid in _events:
		if _event_states.get(eid, EventState.INACTIVE) != EventState.INACTIVE:
			continue
		var event: Dictionary = _events[eid]
		var trigger: Dictionary = event.get("trigger", {})
		if trigger.get("timing", "") == "on_time":
			var trigger_time: float = float(trigger.get("time", 0.0))
			if _elapsed_time >= trigger_time:
				_try_trigger_event(eid)


## 通知 BOSS 已出场（供 LevelBase 调用，触发 on_boss_appear 事件）
func notify_boss_appeared() -> void:
	for eid in _events:
		if _event_states.get(eid, EventState.INACTIVE) != EventState.INACTIVE:
			continue
		var event: Dictionary = _events[eid]
		var trigger: Dictionary = event.get("trigger", {})
		if trigger.get("timing", "") == "on_boss_appear":
			_try_trigger_event(eid)


## 尝试触发事件（含概率检查）
func _try_trigger_event(event_id: String) -> void:
	if not _events.has(event_id):
		return
	if _event_states.get(event_id, EventState.INACTIVE) != EventState.INACTIVE:
		return

	var event: Dictionary = _events[event_id]
	var trigger: Dictionary = event.get("trigger", {})
	var probability: float = float(trigger.get("probability", 1.0))

	# 概率检查：未通过则跳过（标记为 FAILED 表示不再触发）
	if randf() > probability:
		_event_states[event_id] = EventState.FAILED
		print("[EventManager] 事件 '%s' 概率检查未通过，跳过" % event_id)
		return

	trigger_event(event_id)


# ============================================================
# 事件触发与目标管理
# ============================================================

## 触发指定事件
func trigger_event(event_id: String) -> void:
	if not _events.has(event_id):
		push_warning("[EventManager] 未知事件: %s" % event_id)
		return

	var event: Dictionary = _events[event_id]
	var event_type: String = event.get("event_type", "")

	_event_states[event_id] = EventState.ACTIVE

	# 发射本地信号
	event_triggered.emit(event_id, event_type)

	# 转发到 GameManager 全局信号（供 HUD 等全局 UI 监听）
	if GameManager:
		GameManager.event_triggered.emit(event_id, event_type)

	# 显示 UI 提示
	var ui: Dictionary = event.get("ui", {})
	var alert_text: String = ui.get("alert_text", "")
	if not alert_text.is_empty():
		print("[EventManager] 事件提示: %s" % alert_text)

	print("[EventManager] 事件已触发: %s (类型: %s)" % [event_id, event_type])

	# 按事件类型处理
	match event_type:
		"kill_target":
			_spawn_kill_target(event_id, event)
		"destroy_targets":
			_spawn_destroy_targets(event_id, event)
		_:
			print("[EventManager] 事件类型 '%s' 暂未实现（P0 仅支持 kill_target/destroy_targets）" % event_type)


## 生成击杀目标事件的目标
func _spawn_kill_target(event_id: String, event: Dictionary) -> void:
	var target: Dictionary = event.get("target", {})
	var enemy_type: String = target.get("enemy_type", "")
	var spawn_x: float = float(target.get("spawn_x", 540.0))
	var spawn_y: float = float(target.get("spawn_y", -50.0))
	var speed: float = float(target.get("speed", 180.0))
	var hp: int = int(target.get("hp", 50))
	var escape_time: float = float(target.get("escape_time", 0.0))

	if enemy_type.is_empty():
		push_error("[EventManager] kill_target 事件 '%s' 缺少 enemy_type" % event_id)
		_mark_failed(event_id)
		return

	# 设置待处理参数（供 enemy_spawned 信号回调使用）
	_pending_event_id = event_id
	_pending_escape_time = escape_time
	_pending_hp = hp
	_pending_speed = speed

	# 连接到 SpawnManager 的 enemy_spawned 信号以捕获生成的目标
	if not SpawnManager.enemy_spawned.is_connected(_on_event_target_spawned):
		SpawnManager.enemy_spawned.connect(_on_event_target_spawned)

	# 通过 SpawnManager 生成目标（复用现有敌人生成流程）
	SpawnManager.spawn_enemy(enemy_type, 1, "solo", spawn_x, spawn_y, 1.0, "straight")


## enemy_spawned 信号回调：捕获事件目标并设置 event_id
func _on_event_target_spawned(enemy: Node) -> void:
	# 仅处理待处理的事件目标
	if _pending_event_id.is_empty():
		return

	# 类型检查：仅 EventTargetBase 携带 event_id/escape_timer 等事件属性
	# 使用 is 操作符比 "prop" in node 更可靠（class_name 全局注册）
	if not (enemy is EventTargetBase):
		return

	var target: EventTargetBase = enemy
	target.event_id = _pending_event_id
	target.escape_timer = _pending_escape_time
	target.hp = _pending_hp
	target.current_hp = _pending_hp
	target.speed = _pending_speed

	# 存储活跃目标引用（用于奖励掉落定位）
	_active_targets[_pending_event_id] = target

	print("[EventManager] 事件目标已生成: event_id=%s, hp=%d, speed=%.0f" % [_pending_event_id, _pending_hp, _pending_speed])

	# 清理待处理状态
	_pending_event_id = ""

	# 断开信号连接（避免后续普通敌人生成触发此回调）
	if SpawnManager.enemy_spawned.is_connected(_on_event_target_spawned):
		SpawnManager.enemy_spawned.disconnect(_on_event_target_spawned)


## 生成摧毁多目标事件的目标（渡桥等静态可摧毁物体）
## 直接实例化 DestructibleObject 场景，不经过 SpawnManager（静态目标非敌机）
func _spawn_destroy_targets(event_id: String, event: Dictionary) -> void:
	var target: Dictionary = event.get("target", {})
	var required_count: int = int(target.get("count", 0))
	var targets: Array = target.get("targets", [])

	if required_count <= 0 or targets.is_empty():
		push_error("[EventManager] destroy_targets 事件 '%s' 缺少 count 或 targets" % event_id)
		_mark_failed(event_id)
		return

	# 加载可摧毁物体场景（可通过 target.scene_path 指定自定义场景）
	var scene_path: String = String(target.get("scene_path", DESTRUCTIBLE_SCENE_PATH))
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[EventManager] 无法加载可摧毁物体场景: %s" % scene_path)
		_mark_failed(event_id)
		return

	_required_count[event_id] = required_count
	_destroyed_count[event_id] = 0

	# 逐个生成目标
	for t in targets:
		var obj_id: String = String(t.get("id", ""))
		var x: float = float(t.get("x", 0.0))
		var y: float = float(t.get("y", 0.0))
		var hp: int = int(t.get("hp", 30))

		if obj_id.is_empty():
			continue

		var obj: Node = scene.instantiate()
		if obj == null:
			continue

		# 设置目标属性
		if obj is DestructibleObject:
			(obj as DestructibleObject).object_id = obj_id
			(obj as DestructibleObject).max_hp = hp
			(obj as DestructibleObject).current_hp = hp

		# 设置位置
		if obj is Node2D:
			(obj as Node2D).position = Vector2(x, y)

		# 注册 object_id → event_id 映射（供 report_target_destroyed 查找）
		_target_to_event[obj_id] = event_id

		# 添加到场景树（与 EventManager 同级，即 LevelBase 下）
		var parent_node: Node = get_parent()
		if parent_node != null:
			parent_node.add_child(obj)

	print("[EventManager] 摧毁多目标事件已激活: %s（需摧毁 %d 个目标，已生成 %d 个）" % [event_id, required_count, targets.size()])


# ============================================================
# 事件结果报告（供 EventTargetBase / DestructibleObject 调用）
# ============================================================

## 报告目标被摧毁（由 DestructibleObject._destroy() 调用）
## 用于 destroy_targets 事件：当所有目标被摧毁时自动完成事件
func report_target_destroyed(target_id: String) -> void:
	# 查找目标所属事件
	var event_id: String = _target_to_event.get(target_id, "")
	if event_id.is_empty():
		return

	if not _events.has(event_id):
		return

	if _event_states.get(event_id, EventState.INACTIVE) != EventState.ACTIVE:
		return

	# 增加已摧毁计数
	var count: int = int(_destroyed_count.get(event_id, 0)) + 1
	_destroyed_count[event_id] = count

	# 清理映射
	_target_to_event.erase(target_id)

	var required: int = int(_required_count.get(event_id, 0))
	print("[EventManager] 目标已摧毁: %s（进度 %d/%d）" % [target_id, count, required])

	# 达到所需数量时完成事件
	if count >= required:
		report_event_completed(event_id)

## 报告事件完成
## 由 EventTargetBase.die() 在目标被击毁时调用
func report_event_completed(event_id: String) -> void:
	if not _events.has(event_id):
		return

	if _event_states.get(event_id, EventState.INACTIVE) != EventState.ACTIVE:
		return

	_event_states[event_id] = EventState.COMPLETED

	# 获取目标位置（用于掉落奖励）
	var target_pos: Vector2 = Vector2.ZERO
	if _active_targets.has(event_id) and is_instance_valid(_active_targets[event_id]):
		target_pos = (_active_targets[event_id] as Node2D).global_position

	# 发放奖励
	var event: Dictionary = _events[event_id]
	var rewards: Dictionary = event.get("rewards", {})
	_grant_rewards(event_id, rewards, target_pos)

	# 记录到存档
	if SaveManager:
		SaveManager.set_event_completed(event_id, true)

	# 发射本地信号
	event_completed.emit(event_id, rewards)

	# 转发到 GameManager 全局信号
	if GameManager:
		GameManager.event_completed.emit(event_id, rewards)

	# 显示完成提示
	var ui: Dictionary = event.get("ui", {})
	var complete_text: String = ui.get("complete_text", "")
	if not complete_text.is_empty():
		print("[EventManager] 事件完成: %s — %s" % [event_id, complete_text])

	# 清理活跃目标引用
	_active_targets.erase(event_id)

	print("[EventManager] 事件已完成: %s" % event_id)


## 报告事件失败
## 由 EventTargetBase._on_escape() 在目标逃脱时调用
func report_event_failed(event_id: String) -> void:
	if not _events.has(event_id):
		return

	if _event_states.get(event_id, EventState.INACTIVE) != EventState.ACTIVE:
		return

	_event_states[event_id] = EventState.FAILED

	# 发射本地信号
	event_failed.emit(event_id)

	# 转发到 GameManager 全局信号
	if GameManager:
		GameManager.event_failed.emit(event_id)

	# 清理活跃目标引用
	_active_targets.erase(event_id)

	print("[EventManager] 事件已失败: %s" % event_id)


## 内部标记失败（无信号发射，用于配置异常等静默失败）
func _mark_failed(event_id: String) -> void:
	_event_states[event_id] = EventState.FAILED


# ============================================================
# 奖励发放
# ============================================================

## 发放事件奖励
func _grant_rewards(event_id: String, rewards: Dictionary, position: Vector2) -> void:
	# 分数奖励
	if rewards.has("score"):
		var score_reward: int = int(rewards["score"])
		if GameManager:
			GameManager.add_score(score_reward)
		print("[EventManager] 发放分数奖励: %d" % score_reward)

	# 掉落道具
	if rewards.has("drop_items"):
		var items: Array = rewards["drop_items"]
		_drop_items(items, position)

	# 解锁隐藏关卡
	if rewards.has("unlock_hidden"):
		var hidden_id: String = rewards["unlock_hidden"]
		if GameManager:
			GameManager.unlock_hidden_stage(hidden_id)
		print("[EventManager] 解锁隐藏关卡: %s" % hidden_id)


## 在指定位置掉落道具
func _drop_items(item_types: Array, position: Vector2) -> void:
	var powerup_scene: PackedScene = load(POWERUP_SCENE_PATH) as PackedScene
	if powerup_scene == null:
		push_warning("[EventManager] 无法加载道具场景: %s" % POWERUP_SCENE_PATH)
		return

	for i in range(item_types.size()):
		var item_type: String = item_types[i]
		var powerup: Node = powerup_scene.instantiate()
		if powerup == null:
			continue

		# 在目标位置附近散布掉落
		var offset: Vector2 = Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
		if powerup is Node2D:
			(powerup as Node2D).global_position = position + offset

		# 根据字符串映射到道具类型枚举
		if "powerup_type" in powerup:
			match item_type:
				"powerup_p":
					powerup.powerup_type = PowerupBase.PowerupType.POWER
				"powerup_b":
					powerup.powerup_type = PowerupBase.PowerupType.BOMB
				"powerup_coin":
					powerup.powerup_type = PowerupBase.PowerupType.SCORE
				"powerup_medkit":
					powerup.powerup_type = PowerupBase.PowerupType.MEDKIT
				_:
					powerup.powerup_type = PowerupBase.PowerupType.POWER

		# 添加到场景树（与 EventManager 同级，即 LevelBase 下）
		var parent_node: Node = get_parent()
		if parent_node != null:
			parent_node.add_child(powerup)

		print("[EventManager] 掉落道具: %s" % item_type)


# ============================================================
# 查询接口
# ============================================================

## 获取当前活跃（进行中）的事件 ID 列表
func get_active_events() -> Array[String]:
	var result: Array[String] = []
	for eid in _event_states:
		if _event_states[eid] == EventState.ACTIVE:
			result.append(eid)
	return result


## 获取指定事件的状态
func get_event_status(event_id: String) -> EventState:
	return _event_states.get(event_id, EventState.INACTIVE)


## 获取所有事件 ID
func get_all_event_ids() -> Array[String]:
	var result: Array[String] = []
	for eid in _events:
		result.append(eid)
	return result


## 获取关卡已用时间（供调试查询）
func get_elapsed_time() -> float:
	return _elapsed_time
