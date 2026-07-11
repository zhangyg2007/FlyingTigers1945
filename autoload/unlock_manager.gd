extends Node
## 隐藏关卡解锁条件管理器（Autoload 单例，M3-F 更新）
## 根据 SaveManager 中的事件完成记录和 RankManager 的军衔判定隐藏关卡是否解锁。
##
## 双重解锁条件：隐藏关 = 情报已获取（事件完成）AND 军衔达标

const HIDDEN_STAGES: Array[String] = [
	"H1_hump_extreme",
	"H2_tokyo_bombing",
	"H3_shinden_duel",
	"H4_hiroshima_countdown",
]

const HIDDEN_STAGE_INFO_EVENTS: Dictionary = {
	"H1_hump_extreme": "rangoon_general_car",
	"H2_tokyo_bombing": "guilin_hidden_bunker",
	"H3_shinden_duel": "shanghai_secret_ship",
	"H4_hiroshima_countdown": "nanjing_escort_c47",
}

const HIDDEN_STAGE_NAMES: Dictionary = {
	"H1_hump_extreme": "驼峰绝径",
	"H2_tokyo_bombing": "轰炸东京",
	"H3_shinden_duel": "震电对决",
	"H4_hiroshima_countdown": "广岛之刻",
}

func _ready() -> void:
	pass

func is_hidden_stage_unlocked(stage_id: String) -> bool:
	return has_intel(stage_id) and has_rank(stage_id)

func has_intel(stage_id: String) -> bool:
	var event_id: String = HIDDEN_STAGE_INFO_EVENTS.get(stage_id, "")
	if event_id.is_empty():
		return false
	if SaveManager == null:
		return false
	return SaveManager.is_event_completed(event_id)

func has_rank(stage_id: String) -> bool:
	if RankManager == null:
		return false
	return RankManager.can_unlock_hidden_stage(stage_id)

func get_hidden_stage_unlock_status(stage_id: String) -> String:
	if is_hidden_stage_unlocked(stage_id):
		return "unlocked"
	if has_intel(stage_id):
		return "rank_required"
	return "locked"

func get_hidden_stage_required_rank_name(stage_id: String) -> String:
	if RankManager == null:
		return ""
	var required_rank: String = RankManager.get_hidden_stage_required_rank(stage_id)
	return RankManager.get_rank_name(required_rank)

func get_random_hidden_stage_for_display() -> String:
	var unlocked: Array[String] = []
	for stage_id in HIDDEN_STAGES:
		if is_hidden_stage_unlocked(stage_id):
			unlocked.append(stage_id)
	if unlocked.is_empty():
		return ""
	unlocked.shuffle()
	return unlocked[0]

func get_unlocked_hidden_stages() -> Array[String]:
	var result: Array[String] = []
	for stage_id in HIDDEN_STAGES:
		if is_hidden_stage_unlocked(stage_id):
			result.append(stage_id)
	return result

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
		})
	return result