extends Node
## 敌人生成与波次控制器（Autoload单例）
## 负责读取关卡CSV配置、按时间轴生成敌人波次、管理编队生成逻辑。
##
## CSV关卡文件格式（存放在 res://data/stages/ 目录下）：
##   wave_index,time,enemy_type,count,formation,spawn_x,spawn_y,speed_mult,path_id
##   0,0.0,scout,5,line,540,0,1.0,0
##   1,3.0,fighter,3,v_formation,540,0,1.2,1
##   ...
##
## formation 编队类型：line, v_formation, diamond, swarm, solo
## path_id: 预定义的移动路径ID（0=无，直线下降）

# ============================================================
# 信号定义
# ============================================================

## 当一个敌人被生成时发出
signal enemy_spawned(enemy: Node)

## 当一波敌人全部生成完毕时发出
signal wave_complete(wave_index: int)

## 当关卡所有波次全部生成完毕时发出
signal all_waves_complete()

# ============================================================
# 枚举：编队类型
# ============================================================

## 编队类型枚举
enum Formation {
	LINE,       ## 一字横排
	V_FORMATION,## V字形
	DIAMOND,    ## 菱形
	SWARM,      ## 蜂群（随机散布）
	SOLO        ## 单独一架
}

# ============================================================
# 导出 / 配置常量
# ============================================================

## 关卡配置文件目录
const STAGE_DATA_DIR: String = "res://data/stages/"

## 关卡配置文件后缀
const STAGE_FILE_EXTENSION: String = ".csv"

## 默认关卡数量（0~15）
const MAX_STAGE_INDEX: int = 15

# ============================================================
# 公开变量
# ============================================================

## 当前关卡的波次配置数据
## 每个元素是一个字典：{wave_index, time, enemy_type, count, formation, spawn_x, spawn_y, speed_mult, path_id}
var wave_data: Array[Dictionary] = []

## 关卡开始后的已用时间（秒）
var elapsed_time: float = 0.0

## 当前已生成到的波次索引
var current_wave_index: int = 0

## 是否正在生成
var is_spawning: bool = false

## 当前关卡ID
var current_stage_id: String = ""

## 场景中当前存活的敌人数量（由外部调用 update_alive_count 更新）
var alive_enemy_count: int = 0

# ============================================================
# 内部变量
# ============================================================

## 当前关卡的敌人场景映射表
## key: enemy_type字符串, value: PackedScene路径
var _enemy_scene_map: Dictionary = {}

## 预定义的移动路径资源映射表
## key: path_id (int), value: Curve2D 或 Path2D资源
var _path_map: Dictionary = {}

## 是否所有波次已全部生成
var _all_waves_spawned: bool = false

## 关卡超时时间（秒），超过此时间视为关卡完成
var stage_timeout: float = 120.0

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化时不启动处理
	set_process(false)

	# 初始化敌人场景映射
	_init_enemy_scene_map()

	# 初始化路径映射
	_init_path_map()


func _process(delta: float) -> void:
	## 每帧检查是否到时间生成下一波敌人
	if not is_spawning:
		return

	elapsed_time += delta

	# 检查是否超过关卡超时时间
	if elapsed_time >= stage_timeout:
		stop_stage()
		all_waves_complete.emit()
		return

	# 依次检查是否有到时间的波次需要生成
	_spawn_due_waves()

	# 检查是否所有波次已生成且所有敌人已被消灭
	if _all_waves_spawned and alive_enemy_count <= 0:
		stop_stage()
		all_waves_complete.emit()

# ============================================================
# 初始化
# ============================================================

## 初始化敌人类型到场景路径的映射
func _init_enemy_scene_map() -> void:
	_enemy_scene_map = {
		"scout": "res://scenes/enemies/enemy_scout.tscn",
		"fighter": "res://scenes/enemies/enemy_fighter.tscn",
		"bomber": "res://scenes/enemies/enemy_bomber.tscn",
		"ace": "res://scenes/enemies/enemy_ace.tscn",
		"boss": "res://scenes/enemies/boss.tscn",
		"mid_boss": "res://scenes/enemies/mid_boss.tscn",
		"turret": "res://scenes/enemies/turret.tscn",
		"ground_unit": "res://scenes/enemies/ground_unit.tscn",
	}


## 初始化路径映射
func _init_path_map() -> void:
	# path_id=0 表示无特殊路径，直线下降
	# 其他路径ID可扩展加载
	_path_map[0] = null  # 直线下降
	_path_map[1] = "res://data/paths/path_sine.tres"
	_path_map[2] = "res://data/paths/path_zigzag.tres"
	_path_map[3] = "res://data/paths/path_curve_left.tres"
	_path_map[4] = "res://data/paths/path_curve_right.tres"
	_path_map[5] = "res://data/paths/path_dive.tres"

# ============================================================
# 关卡配置加载
# ============================================================

## 加载关卡配置文件
## [param stage_id]: 关卡标识符，如 "stage_01"
func load_stage_config(stage_id: String) -> bool:
	var file_path: String = STAGE_DATA_DIR + stage_id + STAGE_FILE_EXTENSION

	# 尝试加载CSV文件
	if not FileAccess.file_exists(file_path):
		push_warning("SpawnManager: 关卡配置文件不存在 '%s'，使用默认波次。" % file_path)
		_generate_default_waves()
		current_stage_id = stage_id
		return true

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("SpawnManager: 无法打开关卡配置文件 '%s'" % file_path)
		_generate_default_waves()
		current_stage_id = stage_id
		return false

	wave_data.clear()

	# 跳过表头行
	if not file.eof_reached():
		file.get_line()

	# 逐行解析CSV
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts: PackedStringArray = line.split(",")
		if parts.size() < 8:
			push_warning("SpawnManager: 跳过格式错误的行: %s" % line)
			continue

		var wave := {
			"wave_index": int(parts[0]),
			"time": float(parts[1]),
			"enemy_type": parts[2].strip_edges(),
			"count": int(parts[3]),
			"formation": parts[4].strip_edges(),
			"spawn_x": float(parts[5]),
			"spawn_y": float(parts[6]),
			"speed_mult": float(parts[7]),
		}

		# 可选字段：path_id
		if parts.size() >= 9:
			wave["path_id"] = int(parts[8])
		else:
			wave["path_id"] = 0

		wave_data.append(wave)

	# 按时间排序波次
	wave_data.sort_custom(func(a, b): return a["time"] < b["time"])

	file.close()
	current_stage_id = stage_id
	print("SpawnManager: 加载关卡 '%s'，共 %d 波。" % [stage_id, wave_data.size()])
	return true


## 生成默认波次（当CSV文件不存在时的兜底方案）
func _generate_default_waves() -> void:
	wave_data.clear()

	var viewport_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")

	# 生成10波默认敌人
	for i in range(10):
		var formation_str: String = "line"
		match i % 5:
			0:
				formation_str = "line"
			1:
				formation_str = "v_formation"
			2:
				formation_str = "diamond"
			3:
				formation_str = "swarm"
			4:
				formation_str = "solo"

		var count: int = 5 if formation_str != "solo" else 1
		if i == 9:
			# 最后一波：Boss
			formation_str = "solo"
			count = 1

		wave_data.append({
			"wave_index": i,
			"time": float(i) * 4.0,  # 每4秒一波
			"enemy_type": "boss" if i == 9 else "scout",
			"count": count,
			"formation": formation_str,
			"spawn_x": viewport_width / 2.0,
			"spawn_y": -50.0,
			"speed_mult": 1.0,
			"path_id": 0,
		})

# ============================================================
# 生成控制
# ============================================================

## 开始当前关卡的敌人生成
func start_stage() -> void:
	elapsed_time = 0.0
	current_wave_index = 0
	_all_waves_spawned = false
	alive_enemy_count = 0
	is_spawning = true
	set_process(true)
	print("SpawnManager: 开始生成关卡 '%s'，共 %d 波。" % [current_stage_id, wave_data.size()])


## 停止敌人生成
func stop_stage() -> void:
	is_spawning = false
	set_process(false)
	print("SpawnManager: 停止生成。已用时间 %.1f 秒，已生成 %d 波。" % [elapsed_time, current_wave_index])


## 检查并生成到时间的波次
func _spawn_due_waves() -> void:
	while current_wave_index < wave_data.size():
		var wave: Dictionary = wave_data[current_wave_index]
		if elapsed_time >= wave["time"]:
			_spawn_wave(wave)
			current_wave_index += 1

			# 发出波次完成信号
			wave_complete.emit(wave["wave_index"])
		else:
			break

	# 检查是否所有波次已生成
	if current_wave_index >= wave_data.size() and not _all_waves_spawned:
		_all_waves_spawned = true
		print("SpawnManager: 所有问题波次已生成。")

# ============================================================
# 波次生成
# ============================================================

## 生成单个波次
func _spawn_wave(wave: Dictionary) -> void:
	var enemy_type: String = wave["enemy_type"]
	var count: int = wave["count"]
	var formation_str: String = wave["formation"]
	var spawn_x: float = wave["spawn_x"]
	var spawn_y: float = wave["spawn_y"]
	var speed_mult: float = wave["speed_mult"]
	var path_id: int = wave.get("path_id", 0)

	# 解析编队类型
	var formation: Formation = _parse_formation(formation_str)

	# 获取敌人场景
	var scene_path: String = _get_enemy_scene_path(enemy_type)

	# 计算编队位置
	var positions: Array[Vector2] = _calculate_formation_positions(
		formation, count, spawn_x, spawn_y
	)

	# 逐个生成敌人
	for i in range(count):
		var pos: Vector2 = positions[i] if i < positions.size() else Vector2(spawn_x, spawn_y)
		_spawn_single_enemy(scene_path, enemy_type, pos, speed_mult, path_id, i, count)

	print("SpawnManager: 波次 %d - 生成 %d 架 %s（编队：%s）" % [
		wave["wave_index"], count, enemy_type, formation_str
	])


## 生成单个敌人实例
func _spawn_single_enemy(
	scene_path: String,
	enemy_type: String,
	position: Vector2,
	speed_mult: float,
	path_id: int,
	index_in_wave: int,
	total_in_wave: int
) -> void:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("SpawnManager: 无法加载敌人场景 '%s'" % scene_path)
		return

	# 通过对象池获取敌人实例
	var enemy: Node = PoolManager.get_object(scene)
	if enemy == null:
		push_warning("SpawnManager: 无法获取敌人实例（池已满？）。")
		return

	# 设置初始位置
	if enemy is Node2D:
		(enemy as Node2D).global_position = position

	# 设置敌人属性
	if enemy.has_method("setup"):
		enemy.setup({
			"enemy_type": enemy_type,
			"speed_mult": speed_mult,
			"path_id": path_id,
			"index_in_wave": index_in_wave,
			"total_in_wave": total_in_wave,
		})

	# 应用难度倍率
	if enemy.has_method("apply_difficulty"):
		var hp_mult: float = GameManager.get_enemy_hp_multiplier()
		enemy.apply_difficulty(hp_mult)

	alive_enemy_count += 1

	# 发出敌人已生成信号
	enemy_spawned.emit(enemy)

# ============================================================
# 公开的生成接口（供外部手动调用）
# ============================================================

## 手动生成敌人（供外部脚本直接调用）
## [param enemy_type]: 敌人类型字符串（如 "scout", "fighter"）
## [param count]: 生成数量
## [param formation]: 编队类型字符串（如 "line", "v_formation"）
## [param spawn_x]: 生成X坐标
## [param spawn_y]: 生成Y坐标
## [param speed_mult]: 速度倍率
## [param path_id]: 移动路径ID
func spawn_enemy(
	enemy_type: String,
	count: int = 1,
	formation: String = "solo",
	spawn_x: float = 540.0,
	spawn_y: float = -50.0,
	speed_mult: float = 1.0,
	path_id: int = 0
) -> void:
	var formation_enum: Formation = _parse_formation(formation)
	var scene_path: String = _get_enemy_scene_path(enemy_type)
	var positions: Array[Vector2] = _calculate_formation_positions(
		formation_enum, count, spawn_x, spawn_y
	)

	for i in range(count):
		var pos: Vector2 = positions[i] if i < positions.size() else Vector2(spawn_x, spawn_y)
		_spawn_single_enemy(scene_path, enemy_type, pos, speed_mult, path_id, i, count)

# ============================================================
# 编队位置计算
# ============================================================

## 计算指定编队中每个敌人的位置
func _calculate_formation_positions(
	formation: Formation,
	count: int,
	center_x: float,
	center_y: float
) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var spacing: float = 60.0  # 编队间距

	match formation:
		Formation.LINE:
			## 一字横排：等间距水平排列
			if count == 1:
				positions.append(Vector2(center_x, center_y))
			else:
				var total_width: float = spacing * float(count - 1)
				var start_x: float = center_x - total_width / 2.0
				for i in range(count):
					positions.append(Vector2(start_x + spacing * i, center_y))

		Formation.V_FORMATION:
			## V字形编队：领头在前，两翼向后展开
			positions.append(Vector2(center_x, center_y))  # 领头
			for i in range(1, count):
				var side: int = 1 if i % 2 == 0 else -1
				var pair_index: int = ceilf(float(i) / 2.0)
				var offset_x: float = side * spacing * pair_index * 0.5
				var offset_y: float = spacing * pair_index * 0.5
				positions.append(Vector2(center_x + offset_x, center_y + offset_y))

		Formation.DIAMOND:
			## 菱形编队
			if count == 1:
				positions.append(Vector2(center_x, center_y))
			else:
				# 第一行：1架（领头）
				positions.append(Vector2(center_x, center_y))
				# 后续行按菱形展开
				var row: int = 1
				var placed: int = 1
				while placed < count:
					# 左侧和右侧各一架
					var left_x: float = center_x - spacing * row * 0.5
					var right_x: float = center_x + spacing * row * 0.5
					var y: float = center_y + spacing * row * 0.5
					if placed < count:
						positions.append(Vector2(left_x, y))
						placed += 1
					if placed < count:
						positions.append(Vector2(right_x, y))
						placed += 1
					row += 1

		Formation.SWARM:
			## 蜂群编队：在中心点附近随机分布
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			for i in range(count):
				var rand_x: float = center_x + rng.randf_range(-spacing * 2.0, spacing * 2.0)
				var rand_y: float = center_y + rng.randf_range(-spacing * 0.5, spacing * 1.5)
				positions.append(Vector2(rand_x, rand_y))

		Formation.SOLO:
			## 单独一架
			positions.append(Vector2(center_x, center_y))

		_:
			positions.append(Vector2(center_x, center_y))

	return positions

# ============================================================
# 辅助方法
# ============================================================

## 解析编队类型字符串为枚举
func _parse_formation(formation_str: String) -> Formation:
	match formation_str.to_lower():
		"line":
			return Formation.LINE
		"v_formation", "v":
			return Formation.V_FORMATION
		"diamond":
			return Formation.DIAMOND
		"swarm":
			return Formation.SWARM
		"solo", "single":
			return Formation.SOLO
		_:
			push_warning("SpawnManager: 未知编队类型 '%s'，默认使用 solo。" % formation_str)
			return Formation.SOLO


## 获取敌人类型对应的场景路径
func _get_enemy_scene_path(enemy_type: String) -> String:
	if _enemy_scene_map.has(enemy_type):
		return _enemy_scene_map[enemy_type]
	push_warning("SpawnManager: 未知敌人类型 '%s'，默认使用 scout。" % enemy_type)
	return _enemy_scene_map.get("scout", "res://scenes/enemies/enemy_scout.tscn")


## 更新存活敌人数量（由敌人死亡时调用）
func update_alive_count(delta: int) -> void:
	alive_enemy_count = maxi(0, alive_enemy_count + delta)


## 获取剩余波次数
func get_remaining_waves() -> int:
	if wave_data.is_empty():
		return 0
	return maxi(0, wave_data.size() - current_wave_index)


## 获取关卡进度百分比（0.0~1.0）
func get_stage_progress() -> float:
	if wave_data.is_empty():
		return 1.0
	return clampf(float(current_wave_index) / float(wave_data.size()), 0.0, 1.0)


## 获取当前难度下的速度倍率
func get_difficulty_speed_mult(base_mult: float) -> float:
	var bullet_mult: float = GameManager.get_bullet_speed_multiplier()
	return base_mult * bullet_mult
