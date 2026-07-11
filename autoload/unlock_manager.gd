extends Node
## 隐藏关卡解锁条件管理器（Autoload 单例，M3-C P1）
## 根据 SaveManager 中的通关数据判定隐藏关卡是否解锁。
## 注意：本脚本需要注册到 project.godot 的 autoload 列表中（后续整合时统一添加）。
##
## 解锁条件：
##   H1 驼峰绝径: 通关 Stage 04 无伤
##   H2 轰炸东京: 二周目 Easy 通关
##   H3 震电对决: 二周目 Hard 第 6 关前无伤
##   H4 广岛之刻: 通关 H3 后触发

## 隐藏关卡解锁条件定义
const UNLOCK_CONDITIONS: Dictionary = {
	"H1_hump_extreme": "stage_04_no_miss",
	"H2_tokyo_bombing": "second_loop_easy_clear",
	"H3_shinden_duel": "hard_stage_06_no_miss",
	"H4_hiroshima_countdown": "H3_cleared",
}

## 隐藏关卡列表
const HIDDEN_STAGES: Array[String] = [
	"H1_hump_extreme",
	"H2_tokyo_bombing",
	"H3_shinden_duel",
	"H4_hiroshima_countdown",
]

func _ready() -> void:
	pass

## 检查指定隐藏关卡是否已解锁
func is_hidden_stage_unlocked(stage_id: String) -> bool:
	# 先查 SaveManager（可能已被事件解锁）
	if SaveManager != null:
		if SaveManager.has_method("is_stage_unlocked"):
			if SaveManager.is_stage_unlocked(stage_id):
				return true
	# 再查条件
	var condition: String = UNLOCK_CONDITIONS.get(stage_id, "")
	if condition.is_empty():
		return false
	return _check_condition(condition)

## 检查解锁条件
## 对每个 SaveManager 方法调用前先检查 has_method，方法不存在则返回 false
func _check_condition(condition: String) -> bool:
	if SaveManager == null:
		return false
	match condition:
		"stage_04_no_miss":
			# 通关 Stage 04 且无伤
			if not SaveManager.has_method("is_stage_cleared"):
				return false
			if not SaveManager.has_method("get_stage_no_miss"):
				return false
			return SaveManager.is_stage_cleared("04_hump") and SaveManager.get_stage_no_miss("04_hump")
		"second_loop_easy_clear":
			# 二周目 Easy 通关（任意主线关卡）
			if not SaveManager.has_method("get_second_loop_count"):
				return false
			if not SaveManager.has_method("get_last_difficulty"):
				return false
			return SaveManager.get_second_loop_count() >= 1 and SaveManager.get_last_difficulty() == "easy"
		"hard_stage_06_no_miss":
			# Hard 模式第 6 关前无伤
			if not SaveManager.has_method("get_last_difficulty"):
				return false
			if not SaveManager.has_method("get_stage_no_miss"):
				return false
			return SaveManager.get_last_difficulty() == "hard" and SaveManager.get_stage_no_miss("06_hengyang")
		"H3_cleared":
			# 通关 H3
			if not SaveManager.has_method("is_stage_cleared"):
				return false
			return SaveManager.is_stage_cleared("H3_shinden_duel")
		_:
			return false

## 获取所有已解锁的隐藏关卡
func get_unlocked_hidden_stages() -> Array[String]:
	var result: Array[String] = []
	for stage_id in HIDDEN_STAGES:
		if is_hidden_stage_unlocked(stage_id):
			result.append(stage_id)
	return result

## 获取所有隐藏关卡列表（含锁定/解锁状态）
func get_all_hidden_stages_status() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stage_id in HIDDEN_STAGES:
		result.append({
			"stage_id": stage_id,
			"unlocked": is_hidden_stage_unlocked(stage_id),
			"condition": UNLOCK_CONDITIONS.get(stage_id, ""),
		})
	return result
