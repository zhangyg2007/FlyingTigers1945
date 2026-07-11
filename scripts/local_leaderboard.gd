## 本地排行榜
## 管理主线关卡（stage_mode）与深渊模式（abyss_mode）两类排行榜，
## 使用 ConfigFile 持久化到 user://leaderboard.cfg，每分类保留前 MAX_ENTRIES 名。
##
## 条目结构：{rank, name, score, stage_id, floor, date}
##   - rank:     排名（1-based，由 get_entries 计算填充，不落盘）
##   - name:     玩家名（默认 "ACE"）
##   - score:    得分
##   - stage_id: 关卡标识（主线为 stage_id，深渊为 "abyss"）
##   - floor:    楼层（主线填 0）
##   - date:     日期 "YYYY-MM-DD"
##
## 说明：不作为 autoload（避免与 SaveManager 重复存档管理），作为普通 Node 类使用。
class_name LocalLeaderboard
extends Node

# ============================================================
# 信号
# ============================================================

## 排行榜更新（某分类数据发生变化）
signal leaderboard_updated(category: String)

# ============================================================
# 常量
# ============================================================

## 存档文件路径
const SAVE_FILE_PATH: String = "user://leaderboard.cfg"

## 存档版本号
const SAVE_VERSION: int = 1

## 每分类最大条目数
const MAX_ENTRIES: int = 10

## 分类：主线关卡
const CATEGORY_STAGE: String = "stage_mode"

## 分类：深渊模式
const CATEGORY_ABYSS: String = "abyss_mode"

## 默认玩家名
const DEFAULT_NAME: String = "ACE"

## 所有合法分类
const _CATEGORIES: Array[String] = [CATEGORY_STAGE, CATEGORY_ABYSS]

# ============================================================
# 内部变量
# ============================================================

## 排行榜数据 {category: Array}，每条为 {name, score, stage_id, floor, date}
## 不变量：每个 Array 始终按 score 降序排列
var _entries: Dictionary = {
	CATEGORY_STAGE: [],
	CATEGORY_ABYSS: [],
}

## 是否已加载
var _loaded: bool = false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	load_leaderboard()

# ============================================================
# 加载 / 保存
# ============================================================

## 从文件加载排行榜
## [return]: true=加载成功，false=文件不存在或加载失败（视为空排行榜）
func load_leaderboard() -> bool:
	_init_empty_entries()

	var config := ConfigFile.new()
	var err: int = config.load(SAVE_FILE_PATH)
	if err != OK:
		# 文件不存在视为空排行榜（合法初始状态）
		_loaded = true
		return false

	# 读取各分类
	for category in _CATEGORIES:
		var count: int = int(config.get_value(category, "count", 0))
		var arr: Array = []
		for i in range(count):
			var entry: Dictionary = config.get_value(category, str(i), {})
			if not entry.is_empty():
				arr.append(entry)
		# 保证降序不变量（防止存档被手动篡改）
		arr.sort_custom(_compare_score_desc)
		_entries[category] = arr

	_loaded = true
	return true


## 保存排行榜到文件
## [return]: true=保存成功
func save_leaderboard() -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)

	for category in _CATEGORIES:
		var arr: Array = _entries.get(category, [])
		config.set_value(category, "count", arr.size())
		for i in range(arr.size()):
			config.set_value(category, str(i), arr[i])

	var err: int = config.save(SAVE_FILE_PATH)
	if err != OK:
		push_error("[LocalLeaderboard] 保存失败，错误码: %d" % err)
		return false
	return true

# ============================================================
# 条目管理
# ============================================================

## 添加一条记录
## [param category]: 分类（CATEGORY_STAGE / CATEGORY_ABYSS）
## [param name]: 玩家名（为空则使用 DEFAULT_NAME）
## [param score]: 得分
## [param stage_id]: 关卡标识
## [param floor]: 楼层（主线填 0）
## [return]: 排名（1-based），0 表示未上榜
func add_entry(category: String, name: String, score: int, stage_id: String, floor: int) -> int:
	if not _entries.has(category):
		push_warning("[LocalLeaderboard] 未知分类: %s" % category)
		return 0

	var entry: Dictionary = {
		"name": name if not name.is_empty() else DEFAULT_NAME,
		"score": score,
		"stage_id": stage_id,
		"floor": floor,
		"date": Time.get_date_string_from_system(),
	}

	var arr: Array = _entries[category]
	arr.append(entry)
	arr.sort_custom(_compare_score_desc)
	if arr.size() > MAX_ENTRIES:
		# 截断最后一名（降序后末位 = 最低分）。若新条目被截断，数组恢复原状
		arr.resize(MAX_ENTRIES)

	# 用 is_same 按引用查找实际排名，避免同分条目误判
	var rank: int = 0
	for i in range(arr.size()):
		if is_same(arr[i], entry):
			rank = i + 1
			break

	if rank == 0:
		# 新条目未进前 MAX_ENTRIES（已被截断），数组已恢复，无需保存
		return 0

	save_leaderboard()
	leaderboard_updated.emit(category)
	return rank


## 获取指定分类的条目（含 rank 字段）
## [return]: 条目字典数组副本，按排名升序
func get_entries(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _entries.has(category):
		return result
	var arr: Array = _entries[category]
	for i in range(arr.size()):
		var src: Dictionary = arr[i]
		var e: Dictionary = src.duplicate()
		e["rank"] = i + 1
		result.append(e)
	return result


## 预查询：给定分数能排第几
## [param category]: 分类
## [param score]: 待查询分数
## [return]: 排名（1-based），0 表示无法上榜
func get_rank(category: String, score: int) -> int:
	if not _entries.has(category):
		return 0
	var arr: Array = _entries[category]
	var rank: int = 1
	for e in arr:
		if score >= int(e.get("score", 0)):
			break
		rank += 1
	if rank > MAX_ENTRIES:
		return 0
	return rank


## 清空指定分类
func clear_category(category: String) -> void:
	if not _entries.has(category):
		return
	_entries[category] = []
	save_leaderboard()
	leaderboard_updated.emit(category)


## 清空所有分类
func clear_all() -> void:
	for category in _CATEGORIES:
		_entries[category] = []
	save_leaderboard()
	for category in _CATEGORIES:
		leaderboard_updated.emit(category)

# ============================================================
# 内部方法
# ============================================================

## 初始化空排行榜
func _init_empty_entries() -> void:
	_entries[CATEGORY_STAGE] = []
	_entries[CATEGORY_ABYSS] = []


## 分数降序比较（sort_custom 用）
func _compare_score_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("score", 0)) > int(b.get("score", 0))
