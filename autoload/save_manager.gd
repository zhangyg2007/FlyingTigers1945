extends Node
## 存档管理器（Autoload单例）
## 负责游戏数据的保存与加载，使用 ConfigFile 格式存储到 user:// 目录。
##
## 存档文件路径：user://save_data.cfg
##
## 保存内容包括：
##   - highest_stage: 最高解锁关卡
##   - total_score: 总分
##   - unlocked_planes: 已解锁的飞机列表
##   - abyss_best_floor: 无尽模式最高层数
##   - abyss_best_score: 无尽模式最高分
##   - settings: 音量等设置

# ============================================================
# 信号定义
# ============================================================

## 存档数据加载完成后发出
signal data_loaded()

## 存档保存完成后发出
signal save_complete(success: bool)

# ============================================================
# 常量
# ============================================================

## 存档文件路径
const SAVE_FILE_PATH: String = "user://save_data.cfg"

## 存档版本号（用于未来数据格式升级兼容）
const SAVE_VERSION: int = 1

## 默认已解锁飞机列表
const DEFAULT_UNLOCKED_PLANES: Array[String] = ["p40_warhawk"]

# ============================================================
# 存档数据变量
# ============================================================

## 最高解锁关卡索引（0~15）
var highest_stage: int = 0

## 总分（所有关卡累计）
var total_score: int = 0

## 已解锁的飞机标识符列表
var unlocked_planes: Array[String] = DEFAULT_UNLOCKED_PLANES.duplicate()

## 无尽模式最高层数
var abyss_best_floor: int = 0

## 无尽模式最高分
var abyss_best_score: int = 0

## 设置数据
var settings: Dictionary = {
	"master_volume": 1.0,
	"bgm_volume": 0.7,
	"sfx_volume": 0.8,
}

## 最高分（每关最高分记录）
## key: 关卡索引字符串, value: 最高分
var stage_high_scores: Dictionary = {}

## 已解锁的隐藏关卡列表（如 "H1_hump_extreme"）
var unlocked_hidden_stages: Array[String] = []

## 事件进度记录
## key: event_id, value: true=已完成, false=已失败
var event_progress: Dictionary = {}

## S评级数量（军衔系统使用）
var s_rank_count: int = 0

## 各关卡S评级状态：key=关卡索引字符串, value=true表示已获得S
var stage_s_ranks: Dictionary = {}

# ============================================================
# 内部变量
# ============================================================

## 上次保存时间戳
var _last_save_time: int = 0

## 是否已初始化（是否已加载过存档）
var _initialized: bool = false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化时自动加载存档（如果存在）
	if has_save():
		load_game()
	else:
		_initialized = true
		data_loaded.emit()

# ============================================================
# 存档操作
# ============================================================

## 保存游戏数据到文件
func save_game() -> bool:
	var config := ConfigFile.new()

	# 存档版本
	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("meta", "last_save_time", Time.get_unix_time_from_system())

	# 关卡进度
	config.set_value("progress", "highest_stage", highest_stage)
	config.set_value("progress", "total_score", total_score)

	# 各关卡最高分
	for stage_key in stage_high_scores:
		config.set_value("stage_scores", stage_key, stage_high_scores[stage_key])

	# 已解锁飞机
	config.set_value("planes", "unlocked", unlocked_planes)

	# 无尽模式数据
	config.set_value("abyss", "best_floor", abyss_best_floor)
	config.set_value("abyss", "best_score", abyss_best_score)

	# 设置
	config.set_value("settings", "master_volume", settings["master_volume"])
	config.set_value("settings", "bgm_volume", settings["bgm_volume"])
	config.set_value("settings", "sfx_volume", settings["sfx_volume"])

	# 隐藏关卡解锁记录
	config.set_value("hidden", "unlocked_stages", unlocked_hidden_stages)

	# 事件进度记录
	config.set_value("events", "progress", event_progress)

	# S评级数量
	config.set_value("progress", "s_rank_count", s_rank_count)

	# 各关卡S评级状态
	for stage_key in stage_s_ranks:
		config.set_value("stage_s_ranks", stage_key, stage_s_ranks[stage_key])

	# 保存到文件
	var err: int = config.save(SAVE_FILE_PATH)
	var success: bool = (err == OK)

	if success:
		_last_save_time = Time.get_unix_time_from_system()
		print("SaveManager: 存档保存成功。（最高关卡：%d，总分：%d）" % [highest_stage, total_score])
	else:
		push_error("SaveManager: 存档保存失败！错误码：%d" % err)

	save_complete.emit(success)
	return success


## 从文件加载游戏数据
func load_game() -> bool:
	if not has_save():
		push_warning("SaveManager: 没有找到存档文件。")
		_initialized = true
		data_loaded.emit()
		return false

	var config := ConfigFile.new()
	var err: int = config.load(SAVE_FILE_PATH)

	if err != OK:
		push_error("SaveManager: 存档加载失败！错误码：%d" % err)
		_initialized = true
		data_loaded.emit()
		return false

	# 读取版本号
	var version: int = config.get_value("meta", "version", 1)

	# 读取关卡进度
	highest_stage = config.get_value("progress", "highest_stage", 0)
	total_score = config.get_value("progress", "total_score", 0)

	# 读取各关卡最高分
	stage_high_scores.clear()
	var stage_section_keys: PackedStringArray = config.get_section_keys("stage_scores")
	for key in stage_section_keys:
		stage_high_scores[key] = config.get_value("stage_scores", key, 0)

	# 读取已解锁飞机
	var planes_variant = config.get_value("planes", "unlocked", DEFAULT_UNLOCKED_PLANES)
	if planes_variant is Array:
		unlocked_planes.clear()
		for plane_id in planes_variant:
			if plane_id is String:
				unlocked_planes.append(plane_id as String)
	else:
		unlocked_planes = DEFAULT_UNLOCKED_PLANES.duplicate()

	# 读取无尽模式数据
	abyss_best_floor = config.get_value("abyss", "best_floor", 0)
	abyss_best_score = config.get_value("abyss", "best_score", 0)

	# 读取设置
	settings["master_volume"] = config.get_value("settings", "master_volume", 1.0)
	settings["bgm_volume"] = config.get_value("settings", "bgm_volume", 0.7)
	settings["sfx_volume"] = config.get_value("settings", "sfx_volume", 0.8)

	# 读取已解锁隐藏关卡
	var hidden_variant = config.get_value("hidden", "unlocked_stages", [])
	if hidden_variant is Array:
		unlocked_hidden_stages.clear()
		for sid in hidden_variant:
			if sid is String:
				unlocked_hidden_stages.append(sid as String)
	else:
		unlocked_hidden_stages.clear()

	# 读取事件进度
	var progress_variant = config.get_value("events", "progress", {})
	if progress_variant is Dictionary:
		event_progress = progress_variant.duplicate()
	else:
		event_progress = {}

	# 读取S评级数量
	s_rank_count = config.get_value("progress", "s_rank_count", 0)

	# 读取各关卡S评级状态
	stage_s_ranks.clear()
	var s_rank_section_keys: PackedStringArray = config.get_section_keys("stage_s_ranks")
	for key in s_rank_section_keys:
		stage_s_ranks[key] = config.get_value("stage_s_ranks", key, false)

	_initialized = true

	print("SaveManager: 存档加载成功。（最高关卡：%d，总分：%d，已解锁飞机：%d架）" % [
		highest_stage, total_score, unlocked_planes.size()
	])

	data_loaded.emit()
	return true

# ============================================================
# 便捷存档方法
# ============================================================

## 更新并保存最高分（用于GameManager调用）
func save_highest_score(score: int) -> void:
	total_score = maxi(total_score, score)


## 更新并保存关卡最高分
func save_stage_high_score(stage_index: int, score: int) -> void:
	var key: String = str(stage_index)
	if not stage_high_scores.has(key) or score > stage_high_scores[key]:
		stage_high_scores[key] = score


## 解锁新关卡（通关后调用）
func unlock_stage(stage_index: int) -> void:
	if stage_index > highest_stage:
		highest_stage = mini(stage_index, 15)


## 解锁飞机
func unlock_plane(plane_id: String) -> bool:
	if plane_id in unlocked_planes:
		return false  # 已经解锁
	unlocked_planes.append(plane_id)
	return true


## 检查飞机是否已解锁
func is_plane_unlocked(plane_id: String) -> bool:
	return plane_id in unlocked_planes


## 更新无尽模式记录
func update_abyss_record(floor_reached: int, score: int) -> void:
	if floor_reached > abyss_best_floor:
		abyss_best_floor = floor_reached
	if score > abyss_best_score:
		abyss_best_score = score


## 获取无尽模式最高层数
func get_abyss_best_floor() -> int:
	return abyss_best_floor


## 获取无尽模式最高分
func get_abyss_best_score() -> int:
	return abyss_best_score


## 保存无尽模式记录（更新内存 + 写盘）
## 供 AbyssManager 在玩家死亡结算时调用
func save_abyss_record(floor: int, score: int) -> void:
	update_abyss_record(floor, score)
	save_game()


## 保存设置（音量等）
func save_settings(master_vol: float, bgm_vol: float, sfx_vol: float) -> void:
	settings["master_volume"] = master_vol
	settings["bgm_volume"] = bgm_vol
	settings["sfx_volume"] = sfx_vol
	save_game()

## 获取设置数据
func get_settings() -> Dictionary:
	return settings.duplicate()


## 获取指定关卡的最高分
func get_stage_high_score(stage_index: int) -> int:
	var key: String = str(stage_index)
	if stage_high_scores.has(key):
		return stage_high_scores[key]
	return 0

# ============================================================
# 隐藏关卡与事件进度（M3-B）
# ============================================================

## 解锁隐藏关卡
## [param stage_id]: 隐藏关卡标识符（如 "H1_hump_extreme"）
func unlock_hidden_stage(stage_id: String) -> void:
	if not stage_id in unlocked_hidden_stages:
		unlocked_hidden_stages.append(stage_id)
		print("SaveManager: 解锁隐藏关卡 '%s'" % stage_id)


## 检查指定关卡是否已解锁
## 含普通关卡（通过索引比较）和隐藏关卡（通过 unlocked_hidden_stages 列表）
## [param stage_id]: 关卡标识符
## [return]: true=已解锁
func is_stage_unlocked(stage_id: String) -> bool:
	# 隐藏关卡：检查 unlocked_hidden_stages 列表
	if stage_id in unlocked_hidden_stages:
		return true
	# 普通关卡：暂时返回 true（普通关卡的解锁由 highest_stage 控制，
	# 此方法主要用于隐藏关卡查询，普通关卡解锁判断由关卡选择界面处理）
	return false


## 记录事件完成状态
## [param event_id]: 事件标识符
## [param completed]: true=已完成, false=已失败
func set_event_completed(event_id: String, completed: bool) -> void:
	event_progress[event_id] = completed


## 检查事件是否已完成
## [param event_id]: 事件标识符
## [return]: true=已完成
func is_event_completed(event_id: String) -> bool:
	if event_progress.has(event_id):
		return event_progress[event_id] == true
	return false

# ============================================================
# 军衔系统接口（M3-F）
# ============================================================

## 获取S评级数量
func get_s_rank_count() -> int:
	return s_rank_count

## 增加S评级计数（结算时调用，去重）
## [param stage_index]: 关卡索引，用于去重判断
func add_s_rank(stage_index: int = -1) -> void:
	var key: String = str(stage_index)
	if stage_index >= 0 and stage_s_ranks.has(key):
		print("SaveManager: 关卡 %d 已获得S评级，跳过重复计数" % stage_index)
		return
	s_rank_count += 1
	if stage_index >= 0:
		stage_s_ranks[key] = true
	print("SaveManager: S评级计数+1，当前：%d" % s_rank_count)

# ============================================================
# 存档检查与管理
# ============================================================

## 检查是否存在存档文件
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


## 删除存档文件
func delete_save() -> bool:
	if not has_save():
		print("SaveManager: 没有存档文件需要删除。")
		return true

	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: 无法访问 user:// 目录。")
		return false

	# ConfigFile的save路径是 "user://save_data.cfg"
	# DirAccess需要去掉 "user://" 前缀
	var file_name: String = SAVE_FILE_PATH.replace("user://", "")
	var err: int = dir.remove(file_name)

	if err == OK:
		print("SaveManager: 存档已删除。")
		return true
	else:
		push_error("SaveManager: 存档删除失败！错误码：%d" % err)
		return false


## 重置所有存档数据到默认值（但不立即保存）
func reset_all_data() -> void:
	highest_stage = 0
	total_score = 0
	unlocked_planes = DEFAULT_UNLOCKED_PLANES.duplicate()
	abyss_best_floor = 0
	abyss_best_score = 0
	stage_high_scores.clear()
	settings = {
		"master_volume": 1.0,
		"bgm_volume": 0.7,
		"sfx_volume": 0.8,
	}
	unlocked_hidden_stages.clear()
	event_progress.clear()
	s_rank_count = 0
	stage_s_ranks.clear()
	_last_save_time = 0

	print("SaveManager: 所有数据已重置为默认值。")


## 重置所有存档数据并保存到文件
func reset_all_data_and_save() -> void:
	reset_all_data()
	save_game()
	print("SaveManager: 所有数据已重置并保存。")

# ============================================================
# 调试
# ============================================================

## 打印当前存档数据摘要（用于调试）
func print_save_summary() -> void:
	print("========== SaveManager 存档摘要 ==========")
	print("  存档版本: %d" % SAVE_VERSION)
	print("  最高关卡: %d" % highest_stage)
	print("  总分: %d" % total_score)
	print("  已解锁飞机: %s" % str(unlocked_planes))
	print("  无尽模式最高层数: %d" % abyss_best_floor)
	print("  无尽模式最高分: %d" % abyss_best_score)
	print("  各关卡最高分: %s" % str(stage_high_scores))
	print("  已解锁隐藏关卡: %s" % str(unlocked_hidden_stages))
	print("  事件进度: %s" % str(event_progress))
	print("  主音量: %.2f" % settings["master_volume"])
	print("  BGM音量: %.2f" % settings["bgm_volume"])
	print("  SFX音量: %.2f" % settings["sfx_volume"])
	print("  上次保存时间: %s" % Time.get_datetime_string_from_unix_time(_last_save_time))
	print("=============================================")
