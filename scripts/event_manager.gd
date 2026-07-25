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

## v1.5 C12: 情报牛皮纸袋场景路径（用于 intel_event_briefcase 事件掉落）
const INTEL_BRIEFCASE_SCENE_PATH: String = "res://scenes/powerups/intel_briefcase.tscn"

## v1.5 C13: 友军阵地场景路径（用于 protect_ally_event）
const ALLY_POSITION_SCENE_PATH: String = "res://scenes/map_objects/ally_position.tscn"

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

## area_stay 事件状态：event_id -> {area_center, area_radius, stay_duration, current_stay_time}
var _area_stay_states: Dictionary = {}

## v1.5 C13: protect_ally_event 状态：
## event_id -> {allies: Array[AllyPosition], required_count: int, lost_count: int, duration: float, elapsed: float}
var _protect_ally_states: Dictionary = {}

## v1.5 C11: intel_event_briefcase 状态：
## event_id -> {intel_id: String, briefcase_spawned: bool, target_destroyed: bool}
var _intel_event_states: Dictionary = {}

## v1.5 E12 修复：最后被摧毁目标的位置：event_id -> Vector2
## 用于 destroy_targets 事件掉落情报纸袋时定位（_active_targets 不存储 DestructibleObject）
var _last_destroyed_pos: Dictionary = {}


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
	_process_area_stay_check(delta)
	# v1.5 C13: 友军保护事件计时检查（超时且关键友军存活 → 事件成功）
	_process_protect_ally_check(delta)


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
		"area_stay":
			_start_area_stay_event(event_id, event)
		"intel_event_briefcase":
			# v1.5 C11: 隐藏情报事件（目标击毁后掉落牛皮纸袋，玩家碰触完成）
			_spawn_kill_target(event_id, event)
			_init_intel_event_state(event_id, event)
		"protect_ally_event":
			# v1.5 C13: 友军保护事件（生成友军阵地，限时保护关键友军）
			_start_protect_ally_event(event_id, event)
		_:
			print("[EventManager] 事件类型 '%s' 暂未实现" % event_type)


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
		# v1.5 修复：类型不匹配时也需清理 pending 状态并断开信号，避免永久泄漏
		# （原代码直接 return 导致 _pending_event_id 残留 + 信号永久连接）
		print("[EventManager] 警告：生成的敌人不是 EventTargetBase，事件 %s 失败" % _pending_event_id)
		_pending_event_id = ""
		if SpawnManager.enemy_spawned.is_connected(_on_event_target_spawned):
			SpawnManager.enemy_spawned.disconnect(_on_event_target_spawned)
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


## 启动区域停留事件（area_stay）
## 玩家在指定区域内停留指定时间后完成事件
func _start_area_stay_event(event_id: String, event: Dictionary) -> void:
	var target: Dictionary = event.get("target", {})
	var area_x: float = float(target.get("area_x", 540.0))
	var area_y: float = float(target.get("area_y", 960.0))
	var area_radius: float = float(target.get("area_radius", 300.0))
	var stay_duration: float = float(target.get("stay_duration", 3.0))

	_area_stay_states[event_id] = {
		"area_center": Vector2(area_x, area_y),
		"area_radius": area_radius,
		"stay_duration": stay_duration,
		"current_stay_time": 0.0,
	}

	print("[EventManager] 区域停留事件已激活: %s（中心: (%.0f, %.0f), 半径: %.0f, 需停留: %.1fs）" % [
		event_id, area_x, area_y, area_radius, stay_duration
	])


## 每帧检查区域停留事件
func _process_area_stay_check(delta: float) -> void:
	if _area_stay_states.is_empty():
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null or not (player is Node2D):
		return
	var player_pos: Vector2 = (player as Node2D).global_position
	var completed_events: Array[String] = []
	for event_id in _area_stay_states:
		if _event_states.get(event_id, EventState.INACTIVE) != EventState.ACTIVE:
			continue
		var state: Dictionary = _area_stay_states[event_id]
		var area_center: Vector2 = state["area_center"]
		var area_radius: float = state["area_radius"]
		var distance: float = player_pos.distance_to(area_center)
		if distance <= area_radius:
			state["current_stay_time"] += delta
			if state["current_stay_time"] >= state["stay_duration"]:
				completed_events.append(event_id)
		else:
			state["current_stay_time"] = 0.0
	for eid in completed_events:
		report_event_completed(eid)
		_area_stay_states.erase(eid)


# ============================================================
# 事件结果报告（供 EventTargetBase / DestructibleObject 调用）
# ============================================================

## 报告目标被摧毁（由 DestructibleObject._destroy() 调用）
## 用于 destroy_targets 事件：当所有目标被摧毁时自动完成事件
## [param target_id]: 被摧毁目标的 object_id
## [param position]: 被摧毁目标的世界坐标（用于情报纸袋掉落定位）
func report_target_destroyed(target_id: String, position: Vector2 = Vector2.ZERO) -> void:
	# 查找目标所属事件
	var event_id: String = _target_to_event.get(target_id, "")
	if event_id.is_empty():
		return

	if not _events.has(event_id):
		return

	if _event_states.get(event_id, EventState.INACTIVE) != EventState.ACTIVE:
		return

	# v1.5 E12 修复：记录最后被摧毁目标的位置，供 report_event_completed 掉落情报纸袋定位
	# destroy_targets 事件的目标不存入 _active_targets，原代码导致纸袋掉落在 (0,0)
	if position != Vector2.ZERO:
		_last_destroyed_pos[event_id] = position

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
	elif _last_destroyed_pos.has(event_id):
		# v1.5 E12 修复：destroy_targets 事件的目标不存入 _active_targets，
		# 使用 report_target_destroyed 中记录的最后摧毁位置作为掉落点
		target_pos = _last_destroyed_pos[event_id]

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
	# v1.5 E12 修复：清理最后摧毁位置记录
	_last_destroyed_pos.erase(event_id)

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
		# v1.5 修复：原代码未读取 JSON 中的 ui.escape_text 字段，
		# 导致设计要求的"情报已转移"失败提示永远不显示。
		# 通过 GameManager.event_alert 信号通知 HUD 显示文本。
		var event: Dictionary = _events[event_id]
		var ui: Dictionary = event.get("ui", {})
		var escape_text: String = String(ui.get("escape_text", ""))
		if not escape_text.is_empty() and GameManager.has_signal("event_alert"):
			GameManager.event_alert.emit(escape_text)

	# 清理活跃目标引用
	_active_targets.erase(event_id)
	_last_destroyed_pos.erase(event_id)

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

	# v1.5 C11: 情报纸袋掉落（destroy_targets 等多目标事件完成后掉落 IntelBriefcase）
	# v1.5 修复：intel_event_briefcase 类型的纸袋已在 report_intel_target_destroyed 中掉落，
	# 此处再次掉落会导致玩家拾取后原地生成第二个重复纸袋（BUG #2）。
	# 通过 event_type 判断跳过：仅 destroy_targets 类型走此处统一掉落。
	var event_type: String = String(_events.get(event_id, {}).get("event_type", ""))
	if rewards.has("drop_intel") and event_type != "intel_event_briefcase":
		var intel_id: String = String(rewards["drop_intel"])
		var unlock_hidden: String = String(rewards.get("unlock_hidden", ""))
		_spawn_intel_briefcase(intel_id, event_id, unlock_hidden, position)

	# 隐藏关卡解锁由 UnlockManager 双重条件判定（情报已获取 AND 军衔达标）
	# 事件完成后自动记录到 event_progress，无需直接调用 unlock_hidden_stage
	if rewards.has("unlock_hidden"):
		var hidden_id: String = rewards["unlock_hidden"]
		print("[EventManager] 事件完成，隐藏关卡解锁条件已满足（情报）: %s" % hidden_id)


## v1.5 C11: 在指定位置掉落情报牛皮纸袋
## 用于 destroy_targets 等多目标事件完成后的纸袋掉落
func _spawn_intel_briefcase(intel_id: String, event_id: String, unlock_hidden: String, position: Vector2) -> void:
	var scene: PackedScene = load(INTEL_BRIEFCASE_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("[EventManager] 无法加载情报纸袋场景: %s" % INTEL_BRIEFCASE_SCENE_PATH)
		return
	var briefcase: Node = scene.instantiate()
	if briefcase == null:
		return
	if briefcase is IntelBriefcase:
		var ib: IntelBriefcase = briefcase as IntelBriefcase
		ib.intel_id = intel_id
		ib.event_id = event_id
		ib.unlock_hidden = unlock_hidden
		ib.intel_display_name = _get_intel_display_name(event_id)
		ib.global_position = position
	var parent_node: Node = get_parent()
	if parent_node != null:
		parent_node.add_child(briefcase)
	print("[EventManager] 情报纸袋已掉落（多目标事件）: intel_id=%s, pos=(%.0f, %.0f)" % [
		intel_id, position.x, position.y
	])


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


# ============================================================
# v1.5 C11: 隐藏情报系统（intel_event_briefcase）
# ============================================================

## v1.5: 统一的事件目标被击毁报告入口
## 由 EventTargetBase.die() 调用，EventManager 内部根据事件类型路由：
## - intel_event_briefcase: 在原位置掉落 IntelBriefcase（玩家拾取后才完成事件）
## - kill_target / destroy_targets / area_stay: 直接完成事件
func report_target_killed(event_id: String, position: Vector2) -> void:
	if not _events.has(event_id):
		return
	var event: Dictionary = _events[event_id]
	var event_type: String = String(event.get("event_type", ""))
	if event_type == "intel_event_briefcase":
		report_intel_target_destroyed(event_id, position)
	else:
		# 普通事件：直接完成
		report_event_completed(event_id)


## 初始化情报事件状态（在 trigger_event 中调用）
## 读取 rewards.drop_intel / rewards.unlock_hidden 字段
func _init_intel_event_state(event_id: String, event: Dictionary) -> void:
	var rewards: Dictionary = event.get("rewards", {})
	var intel_id: String = String(rewards.get("drop_intel", ""))
	if intel_id.is_empty():
		# 兼容旧配置：从 drop_items 数组中查找 intel_ 前缀
		var drop_items: Array = rewards.get("drop_items", [])
		for item in drop_items:
			var s: String = String(item)
			if s.begins_with("intel_"):
				intel_id = s
				break
	if intel_id.is_empty():
		push_warning("[EventManager] 情报事件 '%s' 缺少 drop_intel 配置" % event_id)
		intel_id = event_id  # 退化处理：用 event_id 作为 intel_id

	var unlock_hidden: String = String(rewards.get("unlock_hidden", ""))

	_intel_event_states[event_id] = {
		"intel_id": intel_id,
		"unlock_hidden": unlock_hidden,
		"briefcase_spawned": false,
		"target_destroyed": false,
	}
	print("[EventManager] 情报事件状态已初始化: %s (intel_id=%s, unlock=%s)" % [
		event_id, intel_id, unlock_hidden
	])


## 报告情报事件的目标已被击毁（由 EventTargetBase.die() 调用）
## 在目标原位置掉落 IntelBriefcase 道具
func report_intel_target_destroyed(event_id: String, position: Vector2) -> void:
	if not _intel_event_states.has(event_id):
		# 非情报事件，回退到普通报告
		report_event_completed(event_id)
		return

	var state: Dictionary = _intel_event_states[event_id]
	if state["briefcase_spawned"]:
		return  # 已掉落，防止重复

	state["target_destroyed"] = true

	# 加载并生成牛皮纸袋道具
	var scene: PackedScene = load(INTEL_BRIEFCASE_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("[EventManager] 无法加载情报纸袋场景: %s" % INTEL_BRIEFCASE_SCENE_PATH)
		report_event_failed(event_id)
		return

	var briefcase: Node = scene.instantiate()
	if briefcase == null:
		report_event_failed(event_id)
		return

	# 配置 IntelBriefcase 属性
	if briefcase is IntelBriefcase:
		var ib: IntelBriefcase = briefcase as IntelBriefcase
		ib.intel_id = String(state["intel_id"])
		ib.event_id = event_id
		ib.unlock_hidden = String(state["unlock_hidden"])
		ib.intel_display_name = _get_intel_display_name(event_id)
		ib.global_position = position

	# 添加到场景树
	var parent_node: Node = get_parent()
	if parent_node != null:
		parent_node.add_child(briefcase)

	state["briefcase_spawned"] = true
	print("[EventManager] 情报纸袋已掉落: event_id=%s, intel_id=%s, pos=(%.0f, %.0f)" % [
		event_id, state["intel_id"], position.x, position.y
	])


## 由 IntelBriefcase._apply_effect() 在玩家拾取后调用
## 触发事件完成 + 隐藏关解锁条件检查
func report_intel_collected(event_id: String, intel_id: String) -> void:
	if not _intel_event_states.has(event_id):
		return

	var state: Dictionary = _intel_event_states[event_id]
	if String(state["intel_id"]) != intel_id:
		push_warning("[EventManager] 情报 ID 不匹配: 期望=%s, 实际=%s" % [state["intel_id"], intel_id])

	# 写入存档（防双保险，IntelBriefcase 已写过一次）
	if SaveManager and not SaveManager.has_intel(intel_id):
		SaveManager.add_intel(intel_id)

	# 完成事件（触发奖励发放 + 信号）
	report_event_completed(event_id)

	# 清理状态
	_intel_event_states.erase(event_id)
	print("[EventManager] 情报已收集完成: event_id=%s, intel_id=%s" % [event_id, intel_id])


## 获取情报显示名（从事件配置的 ui.complete_text 或 fallback）
func _get_intel_display_name(event_id: String) -> String:
	if not _events.has(event_id):
		return "机密情报"
	var event: Dictionary = _events[event_id]
	var ui: Dictionary = event.get("ui", {})
	var complete_text: String = String(ui.get("complete_text", ""))
	if not complete_text.is_empty():
		return complete_text
	return "机密情报"


# ============================================================
# v1.5 C13: 友军保护系统（protect_ally_event）
# ============================================================

## 启动友军保护事件
## 读取 allies 数组生成友军阵地，限时保护关键友军
func _start_protect_ally_event(event_id: String, event: Dictionary) -> void:
	var target: Dictionary = event.get("target", {})
	var allies_config: Array = target.get("allies", [])
	var duration: float = float(target.get("duration", 30.0))
	var required_count: int = int(target.get("required_count", allies_config.size()))

	if allies_config.is_empty():
		push_error("[EventManager] protect_ally_event '%s' 缺少 allies 配置" % event_id)
		_mark_failed(event_id)
		return

	# 加载友军阵地场景（可通过 target.scene_path 指定自定义场景）
	var scene_path: String = String(target.get("scene_path", ALLY_POSITION_SCENE_PATH))
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[EventManager] 无法加载友军阵地场景: %s" % scene_path)
		_mark_failed(event_id)
		return

	var allies: Array = []
	for ally_cfg in allies_config:
		var ally_id: String = String(ally_cfg.get("id", ""))
		var x: float = float(ally_cfg.get("x", 0.0))
		var y: float = float(ally_cfg.get("y", 0.0))
		var hp: int = int(ally_cfg.get("hp", 50))
		var ally_type: String = String(ally_cfg.get("ally_type", "mg_nest"))
		var is_critical: bool = bool(ally_cfg.get("is_critical", true))

		if ally_id.is_empty():
			continue

		var ally: Node = scene.instantiate()
		if ally == null:
			continue

		# 设置 AllyPosition 属性
		if ally is AllyPosition:
			var ap: AllyPosition = ally as AllyPosition
			ap.object_id = ally_id
			ap.protect_event_id = event_id
			ap.ally_type = ally_type
			ap.is_critical = is_critical
			ap._max_hp = hp
			ap._hp = hp
			ap.position = Vector2(x, y)

		# 注册到保护事件状态
		var parent_node: Node = get_parent()
		if parent_node != null:
			parent_node.add_child(ally)
			allies.append(ally)

	# 初始化事件状态
	_protect_ally_states[event_id] = {
		"allies": allies,
		"required_count": required_count,
		"lost_count": 0,
		"duration": duration,
		"elapsed": 0.0,
	}

	print("[EventManager] 友军保护事件已激活: %s（生成 %d 个友军，限时 %.1fs）" % [
		event_id, allies.size(), duration
	])

	# v1.5: 通知 HUD 显示友军保护进度条
	_notify_hud_ally_protect(duration, event)


## v1.5: 查找关卡中的 HUD 节点并调用 show_ally_protect_progress
## EventManager 是 LevelBase 的子节点，通过父节点链查找 HUD
func _notify_hud_ally_protect(duration: float, event: Dictionary) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	# LevelBase 中保存了 hud_node 引用
	if "hud_node" in parent and parent.hud_node != null:
		var hud = parent.hud_node
		if hud.has_method("show_ally_protect_progress"):
			var ui: Dictionary = event.get("ui", {})
			var alert_text: String = String(ui.get("alert_text", "友军保护"))
			hud.show_ally_protect_progress(duration, alert_text)


## v1.5: 通知 HUD 隐藏友军保护进度条
func _hide_hud_ally_protect() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	if "hud_node" in parent and parent.hud_node != null:
		var hud = parent.hud_node
		if hud.has_method("hide_ally_protect_progress"):
			hud.hide_ally_protect_progress()


## 每帧检查友军保护事件计时
## 超时且关键友军存活 → 事件成功；所有友军被毁 → 事件失败
func _process_protect_ally_check(delta: float) -> void:
	if _protect_ally_states.is_empty():
		return
	var completed_events: Array[String] = []
	var failed_events: Array[String] = []
	for event_id in _protect_ally_states:
		if _event_states.get(event_id, EventState.INACTIVE) != EventState.ACTIVE:
			continue
		var state: Dictionary = _protect_ally_states[event_id]
		state["elapsed"] = float(state["elapsed"]) + delta
		# 检查友军存活情况
		var allies: Array = state["allies"]
		var alive_critical: int = 0
		var alive_total: int = 0
		for ally in allies:
			if is_instance_valid(ally) and ally is AllyPosition:
				var ap: AllyPosition = ally as AllyPosition
				if ap._is_alive:
					alive_total += 1
					if ap.is_critical:
						alive_critical += 1
		# 失败条件：所有关键友军被毁
		if alive_critical == 0:
			failed_events.append(event_id)
			continue
		# 成功条件：超时且关键友军仍存活
		if float(state["elapsed"]) >= float(state["duration"]):
			completed_events.append(event_id)
	for eid in completed_events:
		_complete_protect_ally_event(eid, true)
	for eid in failed_events:
		_complete_protect_ally_event(eid, false)


## 由 AllyPosition._on_destroyed() 在友军被毁时调用
## 累加 lost_count，但不立即失败（关键友军被毁才在下一帧检测中失败）
func report_ally_lost(event_id: String, ally_id: String) -> void:
	if not _protect_ally_states.has(event_id):
		return
	var state: Dictionary = _protect_ally_states[event_id]
	state["lost_count"] = int(state["lost_count"]) + 1
	print("[EventManager] 友军 '%s' 被毁（事件: %s，累计损失: %d/%d）" % [
		ally_id, event_id, state["lost_count"], state["required_count"]
	])
	# 显示"友军损失"提示（无扣分）
	var event: Dictionary = _events.get(event_id, {})
	var ui: Dictionary = event.get("ui", {})
	var alert_text: String = String(ui.get("ally_lost_text", "友军损失！"))
	if not alert_text.is_empty() and GameManager:
		if GameManager.has_signal("event_alert"):
			GameManager.event_alert.emit(alert_text)
		else:
			print("[EventManager] %s" % alert_text)


## 完成友军保护事件
## [param success] true=保护成功（发放奖励），false=保护失败（无惩罚）
func _complete_protect_ally_event(event_id: String, success: bool) -> void:
	if not _protect_ally_states.has(event_id):
		return

	var state: Dictionary = _protect_ally_states[event_id]
	var allies: Array = state["allies"]

	# 清理存活的友军节点（事件结束）
	for ally in allies:
		if is_instance_valid(ally):
			ally.queue_free()

	_protect_ally_states.erase(event_id)

	# v1.5: 通知 HUD 隐藏友军保护进度条
	_hide_hud_ally_protect()

	if success:
		# 保护成功：记录到存档 + 发放奖励
		if SaveManager:
			SaveManager.add_ally_protected(event_id)
		report_event_completed(event_id)
		print("[EventManager] 友军保护成功: %s（奖励 +5000）" % event_id)
	else:
		# 保护失败：无扣分，仅记录事件失败状态
		_mark_failed(event_id)
		var event: Dictionary = _events.get(event_id, {})
		var ui: Dictionary = event.get("ui", {})
		var fail_text: String = String(ui.get("fail_text", "友军阵地失守"))
		print("[EventManager] 友军保护失败: %s — %s（无惩罚）" % [event_id, fail_text])
		if GameManager and GameManager.has_signal("event_alert"):
			GameManager.event_alert.emit(fail_text)
		event_failed.emit(event_id)
