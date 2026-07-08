## CSV关卡配置解析器
## 将CSV格式的关卡波次配置文件解析为字典数组
## CSV格式：time,enemy_type,count,formation,spawn_x,spawn_y,speed_mult,path_id
class_name CSVParser
extends RefCounted

## 解析波次配置CSV文件
## [param file_path]: CSV文件的资源路径（res://...）
## [return]: 字典数组，每个字典包含一行波次配置数据
static func parse_wave_config(file_path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("[CSVParser] 文件不存在: %s" % file_path)
		return result

	# 打开文件
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[CSVParser] 无法打开文件: %s, 错误: %s" % [file_path, FileAccess.get_open_error()])
		return result

	# 读取所有行
	var lines: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		# 跳过空行和注释行
		if line.is_empty() or line.begins_with("#"):
			continue
		lines.append(line)

	file.close()

	# 第一行为表头，跳过
	if lines.size() <= 1:
		push_warning("[CSVParser] 配置文件为空或只有表头: %s" % file_path)
		return result

	# 解析数据行（从第二行开始）
	for i in range(1, lines.size()):
		var line: String = lines[i]
		if line.is_empty():
			continue

		var dict := _parse_line(line)
		if dict.is_empty():
			push_warning("[CSVParser] 第 %d 行解析失败: %s" % [i + 1, line])
			continue

		result.append(dict)

	print("[CSVParser] 成功解析 %d 条波次配置: %s" % [result.size(), file_path])
	return result


## 解析单行CSV数据
## [param line]: 一行CSV字符串
## [return]: 包含解析后键值对的字典，解析失败返回空字典
static func _parse_line(line: String) -> Dictionary:
	var parts := line.split(",")
	if parts.size() < 8:
		# 允许path_id为空，最少需要7个字段
		if parts.size() < 7:
			return {}

	var result: Dictionary = {}

	# 按CSV格式解析各字段
	# time -> float: 出现时间（秒）
	result["time"] = parts[0].strip_edges().to_float()

	# enemy_type -> String: 敌机类型标识
	result["enemy_type"] = parts[1].strip_edges()

	# count -> int: 同波敌机数量
	result["count"] = parts[2].strip_edges().to_int()

	# formation -> String: 编队方式
	result["formation"] = parts[3].strip_edges()

	# spawn_x -> float: 生成X坐标
	result["spawn_x"] = parts[4].strip_edges().to_float()

	# spawn_y -> float: 生成Y坐标
	result["spawn_y"] = parts[5].strip_edges().to_float()

	# speed_mult -> float: 速度倍率
	result["speed_mult"] = parts[6].strip_edges().to_float()

	# path_id -> String: 路径ID（可选，默认为straight）
	if parts.size() >= 8:
		result["path_id"] = parts[7].strip_edges()
	else:
		result["path_id"] = "straight"

	return result


## 将波次配置数组按时间排序
## [param waves]: 波次字典数组
## [return]: 按time字段升序排列的新数组
static func sort_by_time(waves: Array[Dictionary]) -> Array[Dictionary]:
	var sorted_waves := waves.duplicate(true)
	sorted_waves.sort_custom(func(a, b): return a.get("time", 0.0) < b.get("time", 0.0))
	return sorted_waves


## 按时间过滤波次配置
## [param waves]: 波次字典数组
## [param from_time]: 起始时间（包含）
## [param to_time]: 结束时间（不包含）
## [return]: 时间范围内的波次子集
static func filter_by_time(
	waves: Array[Dictionary],
	from_time: float,
	to_time: float
) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for wave in waves:
		var wave_time: float = wave.get("time", 0.0)
		if wave_time >= from_time and wave_time < to_time:
			filtered.append(wave)
	return filtered


## 获取波次中所有唯一的敌机类型
## [param waves]: 波次字典数组
## [return]: 包含所有唯一enemy_type的数组
static func get_unique_enemy_types(waves: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for wave in waves:
		var enemy_type: String = wave.get("enemy_type", "")
		if enemy_type != "" and enemy_type not in types:
			types.append(enemy_type)
	return types


## 获取BOSS波次（enemy_type包含"BOSS"的波次）
## [param waves]: 波次字典数组
## [return]: BOSS波次的字典数组
static func get_boss_waves(waves: Array[Dictionary]) -> Array[Dictionary]:
	var bosses: Array[Dictionary] = []
	for wave in waves:
		var enemy_type: String = wave.get("enemy_type", "")
		if enemy_type.to_upper().begins_with("BOSS"):
			bosses.append(wave)
	return bosses


## 获取关卡总时长（最后一个波次的出现时间 + 预留时间）
## [param waves]: 波次字典数组
## [param buffer]: 额外缓冲时间（秒），默认5.0
## [return]: 估计的关卡总时长
static func get_total_duration(waves: Array[Dictionary], buffer: float = 5.0) -> float:
	var max_time: float = 0.0
	for wave in waves:
		var wave_time: float = wave.get("time", 0.0)
		if wave_time > max_time:
			max_time = wave_time
	return max_time + buffer
