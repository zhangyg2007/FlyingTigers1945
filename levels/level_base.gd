## 关卡基类脚本
## 管理关卡的背景滚动、敌人生成、BOSS战、结算等核心流程
## 继承Node，作为关卡场景的根节点使用
class_name LevelBase
extends Node

# ============================================================
# 信号
# ============================================================
## 关卡开始时发射
signal level_started()
## BOSS出场时发射
signal boss_appeared(boss: Node2D)
## 关卡通关时发射
signal level_cleared()

# ============================================================
# 导出参数
# ============================================================
## 关卡ID
@export var level_id: String = ""
## 关卡名称
@export var level_name: String = "未命名关卡"
## 波次配置CSV文件路径
@export var wave_config_path: String = ""
## 背景图层场景数组（从远到近排列）
@export var bg_layer_scenes: Array[PackedScene] = []
## 背景滚动速度
@export var bg_scroll_speed: float = 80.0
## BOSS场景路径
@export var boss_scene_path: String = ""
## 关卡BGM资源路径
@export var bgm_path: String = ""
## 是否允许暂停
@export var can_pause: bool = true

# ============================================================
# 内部状态
# ============================================================
## 关卡是否已开始
var is_level_active: bool = false
## 关卡是否已结束
var is_level_ended: bool = false
## 关卡计时器（从0开始计时）
var level_timer: float = 0.0
## 当前波次索引
var current_wave_index: int = 0
## 所有波次配置数据
var wave_configs: Array[Dictionary] = []
## BOSS是否已经出场
var boss_spawned: bool = false
## BOSS是否已被击败
var boss_defeated: bool = false
## 当前BOSS引用
var current_boss: Node2D = null
## 背景视差层节点数组
var bg_layers: Array[ParallaxLayer] = []
## 关卡结束计时器（BOSS击败后延迟结算）
var end_timer: float = 0.0
## 关卡结束延迟时间
const END_DELAY: float = 3.0

# ============================================================
## 节点引用（运行时获取）
# ============================================================
var parallax_background: ParallaxBackground = null
var ui_layer: CanvasLayer = null

## 事件管理器（隐藏事件系统，M3-B）
var event_manager: EventManager = null

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	# 暂停处理，防止未准备好就开始
	set_process(false)
	set_physics_process(false)

	# 创建背景视差滚动层
	_create_parallax_background()

	# 加载波次配置
	_load_wave_config()

	# 确保UI层存在
	_ensure_ui_layer()

	# 连接GameManager信号（如果存在）
	_connect_signals()

	# 准备完毕
	print("[LevelBase] 关卡 '%s' 准备完毕，波次数: %d" % [level_name, wave_configs.size()])

	# 创建事件管理器并加载关卡事件配置（M3-B 隐藏事件系统）
	# 无 events_stage_XX.json 的关卡正常运行，load_events 会静默跳过
	event_manager = EventManager.new()
	event_manager.name = "EventManager"
	add_child(event_manager)
	event_manager.load_events(level_id)

	# 自动开始关卡（M2阶段简化：场景加载后立即开始，无需按键触发）
	# 未来如有"按任意键开始"需求，可移除此行改为外部调用 start_level()
	start_level()


func _process(delta: float) -> void:
	if not is_level_active or is_level_ended:
		return

	# 更新关卡计时器
	level_timer += delta

	# 更新背景滚动
	_update_bg_scroll(delta)

	# 检查并生成敌机波次
	_check_and_spawn_waves()

	# 检查BOSS战结束
	_check_level_complete(delta)


# ============================================================
# 关卡流程控制
# ============================================================

## 开始关卡
func start_level() -> void:
	if is_level_active:
		return

	is_level_active = true
	is_level_ended = false
	level_timer = 0.0
	current_wave_index = 0
	boss_spawned = false
	boss_defeated = false

	# 启用处理
	set_process(true)
	set_physics_process(true)

	# 播放BGM
	_play_bgm()

	# 发射关卡开始信号
	level_started.emit()

	print("[LevelBase] 关卡 '%s' 开始!" % level_name)


## 结束关卡
func end_level() -> void:
	if is_level_ended:
		return

	is_level_ended = true
	is_level_active = false

	# 停止BGM
	_stop_bgm()

	# 场景切换前清理对象池（归还所有活跃对象，避免内存泄漏/残留）
	if PoolManager.has_method("return_all_active"):
		PoolManager.return_all_active()

	# 发射关卡通关信号
	level_cleared.emit()

	print("[LevelBase] 关卡 '%s' 通关! 用时: %.1f秒" % [level_name, level_timer])

	# 延迟后跳转到结算场景
	_goto_result_scene()


## 强制结束关卡（玩家死亡等）
func force_end_level() -> void:
	is_level_ended = true
	is_level_active = false
	set_process(false)
	set_physics_process(false)
	_stop_bgm()

	# 场景切换前清理对象池
	if PoolManager.has_method("return_all_active"):
		PoolManager.return_all_active()

	print("[LevelBase] 关卡 '%s' 强制结束" % level_name)


# ============================================================
# 背景系统
# ============================================================

## 创建视差背景
func _create_parallax_background() -> void:
	parallax_background = ParallaxBackground.new()
	parallax_background.name = "ParallaxBackground"
	add_child(parallax_background)

	# 如果有预配置的背景图层场景，实例化添加
	for i in range(bg_layer_scenes.size()):
		var layer_scene: PackedScene = bg_layer_scenes[i]
		if layer_scene == null:
			continue
		var layer: ParallaxLayer = layer_scene.instantiate()
		layer.name = "BgLayer_%d" % i
		parallax_background.add_child(layer)
		bg_layers.append(layer)

	# 设置默认滚动速度
	parallax_background.scroll_base_offset = Vector2.ZERO
	parallax_background.scroll_ignore_camera_zoom = true

	print("[LevelBase] 创建 %d 层视差背景" % bg_layers.size())


## 更新背景滚动（模拟向上飞行）
func _update_bg_scroll(delta: float) -> void:
	if parallax_background == null:
		return

	# 向下滚动视差背景，模拟飞机向上飞行
	for layer in bg_layers:
		layer.motion_offset.y += bg_scroll_speed * delta * layer.motion_mirroring.y * 0.01


## 动态替换背景图层（用于关卡中途切换场景）
func change_bg_layer(index: int, new_scene: PackedScene) -> void:
	if index < 0 or index >= bg_layers.size():
		push_warning("[LevelBase] 无效的背景层索引: %d" % index)
		return

	var old_layer: ParallaxLayer = bg_layers[index]
	var new_layer: ParallaxLayer = new_scene.instantiate()
	new_layer.name = old_layer.name

	parallax_background.remove_child(old_layer)
	old_layer.queue_free()

	parallax_background.add_child(new_layer)
	bg_layers[index] = new_layer


# ============================================================
# 敌机生成系统
# ============================================================

## 加载波次配置
func _load_wave_config() -> void:
	if wave_config_path.is_empty():
		push_warning("[LevelBase] 未设置波次配置路径")
		return

	# 优先使用SpawnManager加载（自动注册）
	if SpawnManager.has_method("load_stage_config"):
		SpawnManager.load_stage_config(wave_config_path)
		# 如果SpawnManager已经解析完毕，直接获取
		if SpawnManager.has_method("get_wave_configs"):
			wave_configs = SpawnManager.get_wave_configs()
			return

	# 直接使用CSVParser.parse_wave_config（static 方法，可直接通过类名调用）
	# 注：CSVParser 是 class_name 声明的类，parse_wave_config 是 static func，
	# 不能对类名调用 has_method（实例方法），故直接调用 static 函数。
	wave_configs = CSVParser.parse_wave_config(wave_config_path)

	# 按时间排序
	wave_configs = _sort_waves_by_time(wave_configs)


## 检查并生成敌机波次
func _check_and_spawn_waves() -> void:
	# 遍历未处理的波次
	while current_wave_index < wave_configs.size():
		var wave: Dictionary = wave_configs[current_wave_index]
		var wave_time: float = wave.get("time", 0.0)

		# 时间未到，停止检查
		if level_timer < wave_time:
			break

		# 生成此波次
		_spawn_wave(wave)
		current_wave_index += 1


## 生成单个波次
func _spawn_wave(wave: Dictionary) -> void:
	var enemy_type: String = wave.get("enemy_type", "")
	var count: int = wave.get("count", 1)
	var formation: String = wave.get("formation", "line")
	var spawn_x: float = wave.get("spawn_x", 540.0)
	var spawn_y: float = wave.get("spawn_y", -50.0)
	var speed_mult: float = wave.get("speed_mult", 1.0)
	var path_id: String = wave.get("path_id", "straight")

	# 检查是否为BOSS波次
	if enemy_type.to_upper().begins_with("BOSS"):
		_spawn_boss(wave)
		return

	# 通过SpawnManager生成敌机（优先）
	if SpawnManager.has_method("spawn_wave"):
		SpawnManager.spawn_wave(enemy_type, count, formation, spawn_x, spawn_y, speed_mult, path_id)
		return

	# 直接实例化生成（后备方案）
	_spawn_enemies_direct(enemy_type, count, formation, spawn_x, spawn_y, speed_mult, path_id)

	print("[LevelBase] 生成波次: type=%s, count=%d, formation=%s, time=%.1f" % [
		enemy_type, count, formation, level_timer
	])


## 直接实例化敌机（当SpawnManager不可用时）
func _spawn_enemies_direct(
	enemy_type: String,
	count: int,
	formation: String,
	spawn_x: float,
	spawn_y: float,
	speed_mult: float,
	path_id: String
) -> void:
	# 根据敌机类型确定场景路径
	var scene_path := _get_enemy_scene_path(enemy_type)
	var enemy_scene := load(scene_path)
	if enemy_scene == null:
		push_warning("[LevelBase] 无法加载敌机场景: %s" % scene_path)
		return

	# 根据编队方式计算每个敌机的位置偏移
	var offsets: Array[Vector2] = _get_formation_offsets(formation, count)

	for i in range(count):
		var enemy: Node2D = enemy_scene.instantiate()
		var offset := offsets[i] if i < offsets.size() else Vector2.ZERO
		enemy.global_position = Vector2(spawn_x + offset.x, spawn_y + offset.y)

		# 应用速度倍率
		if "speed_multiplier" in enemy:
			enemy.speed_multiplier = speed_mult

		# 设置路径
		if enemy.has_method("set_path"):
			enemy.set_path(path_id)

		add_child(enemy)


## 获取敌机场景路径
## 优先委托给 SpawnManager（保持映射一致性），后备硬编码路径
func _get_enemy_scene_path(enemy_type: String) -> String:
	# 优先委托给 SpawnManager 的映射表（单一数据源，避免不一致）
	if SpawnManager.has_method("_get_enemy_scene_path"):
		return SpawnManager._get_enemy_scene_path(enemy_type)
	# 后备：硬编码路径（仅当 SpawnManager 不可用时使用）
	match enemy_type:
		"ki27_fighter":
			return "res://scenes/enemies/enemy_fighter.tscn"
		"ki43_hayabusa":
			return "res://scenes/enemies/enemy_fighter.tscn"
		"ki21_bomber":
			return "res://scenes/enemies/enemy_fighter.tscn"
		_:
			return "res://scenes/enemies/enemy_fighter.tscn"


## 获取编队偏移数组
func _get_formation_offsets(formation: String, count: int) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var spacing: float = 60.0  # 敌机间距

	match formation:
		"line":
			# 水平一字排列
			for i in range(count):
				offsets.append(Vector2((i - count / 2.0 + 0.5) * spacing, 0.0))

		"v_formation":
			# V字形排列
			for i in range(count):
				var side := 1 if i % 2 == 0 else -1
				var depth := (i / 2 + 1)
				offsets.append(Vector2(
					side * depth * spacing * 0.5,
					depth * spacing * 0.3
				))

		"diamond":
			# 菱形排列
			var diamond_offsets: Array[Vector2] = [
				Vector2(0, -spacing),
				Vector2(-spacing, 0),
				Vector2(spacing, 0),
				Vector2(0, spacing),
			]
			for i in range(min(count, diamond_offsets.size())):
				offsets.append(diamond_offsets[i])
			# 多余的敌机追加在后面
			for i in range(diamond_offsets.size(), count):
				offsets.append(Vector2(0, spacing + (i - 3) * spacing))

		"swarm":
			# 蜂群散布（随机偏移）
			for i in range(count):
				offsets.append(Vector2(
					randf_range(-spacing * 2, spacing * 2),
					randf_range(0, spacing * 2)
				))

		"solo":
			# 单机，无偏移
			offsets.append(Vector2.ZERO)

		"boss":
			# BOSS位置，无偏移
			offsets.append(Vector2.ZERO)

		_:
			# 默认线性排列
			for i in range(count):
				offsets.append(Vector2((i - count / 2.0 + 0.5) * spacing, 0.0))

	return offsets


# ============================================================
# BOSS战系统
# ============================================================

## 生成BOSS
func _spawn_boss(wave: Dictionary) -> void:
	if boss_spawned:
		return

	boss_spawned = true

	# 显示BOSS出场警告
	show_boss_warning()

	# 延迟后生成BOSS（等警告动画播放完毕）
	var _timer := create_tween()
	_timer.tween_callback(
		func():
			# 获取BOSS场景路径
			var boss_type: String = wave.get("enemy_type", "boss_bomber")
			var scene_path := "res://scenes/bosses/%s.tscn" % boss_type.to_lower()
			var boss_scene := load(scene_path)

			if boss_scene == null:
				push_error("[LevelBase] 无法加载BOSS场景: %s" % scene_path)
				return

			current_boss = boss_scene.instantiate()
			current_boss.global_position = Vector2(
				wave.get("spawn_x", 540.0),
				wave.get("spawn_y", -150.0)
			)

			# 连接BOSS信号
			if current_boss.has_signal("boss_defeated"):
				current_boss.boss_defeated.connect(_on_boss_defeated)

			add_child(current_boss)

			# 发射BOSS出场信号
			boss_appeared.emit(current_boss)

			# 通知事件管理器 BOSS 已出场（触发 on_boss_appear 事件）
			if event_manager != null:
				event_manager.notify_boss_appeared()

			# 通知AudioManager播放BOSS战BGM
			if AudioManager.has_method("play_music"):
				AudioManager.play_music("bgm_boss_fight.ogg")

			print("[LevelBase] BOSS '%s' 出场!" % boss_type)
	).set_delay(2.0)


## 显示BOSS出场警告效果
func show_boss_warning() -> void:
	# 创建警告UI
	if ui_layer == null:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		add_child(ui_layer)

	var warning_panel := PanelContainer.new()
	warning_panel.name = "BossWarning"
	warning_panel.set_anchors_preset(Control.PRESET_CENTER)

	# 创建警告标签
	var label := Label.new()
	label.text = "WARNING"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color.RED)

	warning_panel.add_child(label)
	ui_layer.add_child(warning_panel)

	# 动画效果：闪烁数次后消失
	var tween := create_tween()
	tween.set_parallel(true)

	# 标签闪烁
	tween.set_loops(4)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_property(label, "modulate:a", 0.2, 0.2)

	# 整体放大后消失
	tween.set_parallel(false)
	tween.tween_property(warning_panel, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(warning_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(warning_panel.queue_free)


## BOSS被击败回调
func _on_boss_defeated() -> void:
	boss_defeated = true
	end_timer = END_DELAY
	print("[LevelBase] BOSS已被击败，%.1f秒后结算" % END_DELAY)


## 检查关卡是否完成
func _check_level_complete(delta: float) -> void:
	# 判断关卡完成的条件：
	# 1. 所有波次已生成（包括BOSS）
	# 2. BOSS已被击败（如果有BOSS）
	# 3. 或所有普通敌机已被消灭
	if current_wave_index >= wave_configs.size():
		if boss_spawned:
			# 有BOSS的关卡：等待BOSS被击败
			if boss_defeated:
				end_timer -= delta
				if end_timer <= 0.0:
					end_level()
		else:
			# 无BOSS的关卡：检查场景中是否还有敌人
			var enemies := get_tree().get_nodes_in_group("enemies")
			if enemies.size() == 0:
				end_timer -= delta
				if end_timer <= 0.0:
					end_level()


# ============================================================
# UI系统
# ============================================================

## 确保UI层存在
func _ensure_ui_layer() -> void:
	if ui_layer != null:
		return

	# 查找已有UI层
	var existing_layers := get_children().filter(
		func(node): return node is CanvasLayer and node.name == "UILayer"
	)
	if existing_layers.size() > 0:
		ui_layer = existing_layers[0] as CanvasLayer
		return

	# 创建新的UI层
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10  # UI层在较高层级
	add_child(ui_layer)


# ============================================================
# 音频系统
# ============================================================

## 播放关卡BGM
func _play_bgm() -> void:
	if bgm_path.is_empty():
		return
	if AudioManager.has_method("play_music"):
		AudioManager.play_music(bgm_path)


## 停止BGM
func _stop_bgm() -> void:
	if AudioManager.has_method("stop_music"):
		AudioManager.stop_music()


# ============================================================
# 信号连接
# ============================================================

## 连接全局信号
func _connect_signals() -> void:
	# 玩家死亡时强制结束关卡
	if GameManager.has_signal("player_died"):
		if not GameManager.player_died.is_connected(force_end_level):
			GameManager.player_died.connect(force_end_level)


# ============================================================
# 场景跳转
# ============================================================

## 跳转到结算场景
func _goto_result_scene() -> void:
	# 保存关卡结果数据
	var result_data: Dictionary = {
		"level_id": level_id,
		"level_name": level_name,
		"time": level_timer,
		"boss_defeated": boss_defeated,
	}

	# 通过GameManager保存并跳转（场景文件名为 result_screen.tscn，对应 result_screen.gd）
	if GameManager.has_method("set_level_result"):
		GameManager.set_level_result(result_data)
		GameManager.goto_scene("res://scenes/ui/result_screen.tscn")
	else:
		# 后备方案：直接切换场景
		get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")


## 重新开始当前关卡
func restart_level() -> void:
	get_tree().reload_current_scene()


# ============================================================
# 辅助方法
# ============================================================

## 按时间排序波次
func _sort_waves_by_time(waves: Array[Dictionary]) -> Array[Dictionary]:
	var sorted_waves := waves.duplicate(true)
	sorted_waves.sort_custom(func(a, b): return a.get("time", 0.0) < b.get("time", 0.0))
	return sorted_waves


## 获取关卡剩余敌机数量
func get_remaining_enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


## 暂停/恢复关卡
func toggle_pause() -> void:
	if not can_pause:
		return
	get_tree().paused = not get_tree().paused
