extends Node
## 隐藏关卡解锁条件管理器（Autoload 单例，v1.5 更新）
## 根据 SaveManager 中的情报收集记录和 RankManager 的军衔判定隐藏关卡是否解锁。
##
## 双重解锁条件：隐藏关 = 情报已获取 AND 军衔达标
##
## v1.5 隐藏关卡（仅 2 个）：
##   - H1_hump_extreme（驼峰绝径）：需获取 intel_hump_route（L02 仰光情报事件）
##   - H2_hiroshima（轰炸广岛）：需获取以下情报任一：
##       * intel_tokyo_bombing（L04 新竹情报事件）
##       * intel_hengyang_status（L05 衡阳情报事件）
##       * intel_hiroshima_target（L07 湘江情报事件）

# ============================================================
# 常量
# ============================================================

## v1.5 所有隐藏关卡列表（仅 2 个）
const HIDDEN_STAGES: Array[String] = [
	"H1_hump_extreme",
	"H2_hiroshima",
]

## 隐藏关卡所需情报（stage_id -> intel_id 或 intel_id 数组）
## 数组表示任一情报即可解锁（H2 有 3 个情报来源：L04/L05/L07）
const HIDDEN_STAGE_REQUIRED_INTEL: Dictionary = {
	"H1_hump_extreme": "intel_hump_route",
	"H2_hiroshima": [
		"intel_tokyo_bombing",
		"intel_hengyang_status",
		"intel_hiroshima_target",
	],
}

## 隐藏关卡显示名
const HIDDEN_STAGE_NAMES: Dictionary = {
	"H1_hump_extreme": "驼峰绝径",
	"H2_hiroshima": "轰炸广岛",
}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	pass

# ============================================================
# 解锁判定
# ============================================================

## 判断隐藏关卡是否已解锁（情报 AND 军衔 双重条件）
func is_hidden_stage_unlocked(stage_id: String) -> bool:
	return has_intel(stage_id) and has_rank(stage_id)


## 判断玩家是否已获取该隐藏关卡所需的情报
## 支持单个 intel_id（字符串）或多个 intel_id（数组，任一满足即可）
func has_intel(stage_id: String) -> bool:
	var required = HIDDEN_STAGE_REQUIRED_INTEL.get(stage_id, "")
	if required is String:
		if required.is_empty():
			return false
		if SaveManager == null:
			return false
		return SaveManager.has_intel(required)
	elif required is Array:
		if required.is_empty():
			return false
		if SaveManager == null:
			return false
		# 任一情报即可解锁
		for intel_id in required:
			if SaveManager.has_intel(intel_id):
				return true
		return false
	return false


## 判断玩家军衔是否达到该隐藏关卡的要求
func has_rank(stage_id: String) -> bool:
	if RankManager == null:
		return false
	return RankManager.can_unlock_hidden_stage(stage_id)


## 获取隐藏关卡的解锁状态描述
func get_hidden_stage_unlock_status(stage_id: String) -> String:
	if is_hidden_stage_unlocked(stage_id):
		return "unlocked"
	if has_intel(stage_id):
		return "rank_required"
	return "locked"


## 获取隐藏关卡所需军衔名称（用于 UI 显示）
func get_hidden_stage_required_rank_name(stage_id: String) -> String:
	if RankManager == null:
		return ""
	var required_rank: String = RankManager.get_hidden_stage_required_rank(stage_id)
	return RankManager.get_rank_name(required_rank)


## 获取隐藏关卡所需的情报描述（用于 UI 显示）
func get_hidden_stage_required_intel_text(stage_id: String) -> String:
	var required = HIDDEN_STAGE_REQUIRED_INTEL.get(stage_id, "")
	if required is String:
		return required
	elif required is Array:
		return " / ".join(required)
	return ""


# ============================================================
# 查询接口
# ============================================================

## 随机获取一个已解锁的隐藏关卡（用于 UI 展示）
func get_random_hidden_stage_for_display() -> String:
	var unlocked: Array[String] = []
	for stage_id in HIDDEN_STAGES:
		if is_hidden_stage_unlocked(stage_id):
			unlocked.append(stage_id)
	if unlocked.is_empty():
		return ""
	unlocked.shuffle()
	return unlocked[0]


## 获取所有已解锁的隐藏关卡列表
func get_unlocked_hidden_stages() -> Array[String]:
	var result: Array[String] = []
	for stage_id in HIDDEN_STAGES:
		if is_hidden_stage_unlocked(stage_id):
			result.append(stage_id)
	return result


## 获取所有隐藏关卡的详细状态信息（用于关卡选择 UI 展示）
func get_all_hidden_stages_status() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stage_id in HIDDEN_STAGES:
		result.append({
			"stage_id": stage_id,
			"name": HIDDEN_STAGE_NAMES.get(stage_id, ""),
			"unlocked": is_hidden_stage_unlocked(stage_id),
			"has_intel": has_intel(stage_id),
			"has_rank": has_rank(stage_id),
			"required_rank": RankManager.get_hidden_stage_required_rank(stage_id) if RankManager else "PVT",
			"required_rank_name": get_hidden_stage_required_rank_name(stage_id),
			"required_intel": get_hidden_stage_required_intel_text(stage_id),
		})
	return result
