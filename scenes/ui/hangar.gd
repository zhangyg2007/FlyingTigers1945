class_name HangarUI
extends Control
## 机库 UI（v1.5 C10）
## 展示 7 架可选战机，玩家选择后写入 SaveManager.selected_aircraft。
## 数据来源：PlayerBase.get_all_aircrafts()（读取 resources/player_data.json）

# ============================================================
# 信号
# ============================================================

## 战机已选中（aircraft_id）
signal aircraft_selected(aircraft_id: String)

## 返回按钮按下
signal back_pressed()

# ============================================================
# 节点引用
# ============================================================

@onready var _aircraft_list: VBoxContainer = $Panel/AircraftList
@onready var _detail_name: Label = $Panel/DetailPanel/DetailName
@onready var _detail_desc: Label = $Panel/DetailPanel/DetailDesc
@onready var _detail_stats: Label = $Panel/DetailPanel/DetailStats
@onready var _confirm_button: Button = $Panel/ConfirmButton
@onready var _back_button: Button = $Panel/BackButton

# ============================================================
# 内部状态
# ============================================================

## 所有战机配置
var _aircrafts: Array = []

## 当前选中的战机索引
var _selected_index: int = 0

## 战机场景路径映射（aircraft_id -> scene path）
const AIRCRAFT_SCENES: Dictionary = {
	"p40b_tomahawk": "res://scenes/player/player_p40.tscn",
	"p40e_kittyhawk": "res://scenes/player/player_p40e.tscn",
	"p38_lightning": "res://scenes/player/player_p38.tscn",
	"p47_thunderbolt": "res://scenes/player/player_p47.tscn",
	"p51_mustang": "res://scenes/player/player_p51.tscn",
	"b25_mitchell": "res://scenes/player/player_b25.tscn",
	"b29_superfortress": "res://scenes/player/player_b29.tscn",
}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_aircrafts = PlayerBase.get_all_aircrafts()
	_populate_aircraft_list()
	# 选中当前已保存的战机
	var current: String = SaveManager.get_selected_aircraft() if SaveManager else "p40b_tomahawk"
	_select_by_id(current)
	_confirm_button.pressed.connect(_on_confirm)
	_back_button.pressed.connect(_on_back)


# ============================================================
# UI 构建
# ============================================================

## 填充战机列表
func _populate_aircraft_list() -> void:
	for child in _aircraft_list.get_children():
		child.queue_free()
	for i in range(_aircrafts.size()):
		var ac: Dictionary = _aircrafts[i]
		var btn: Button = Button.new()
		btn.text = String(ac.get("display_name", ac.get("aircraft_id", "")))
		btn.custom_minimum_size = Vector2(280, 48)
		var idx: int = i
		btn.pressed.connect(func(): _select_by_index(idx))
		# 标记锁定状态
		if not _is_unlocked(ac):
			btn.text += " [锁定]"
			btn.disabled = true
		_aircraft_list.add_child(btn)


## 检查战机是否已解锁
func _is_unlocked(ac: Dictionary) -> bool:
	var cond: String = String(ac.get("unlock_condition", "default"))
	if cond == "default":
		return true
	# 简化解锁判断：基于最高关卡进度
	if SaveManager:
		match cond:
			"clear_L01":
				return SaveManager.highest_stage >= 1
			"clear_L03":
				return SaveManager.highest_stage >= 3
			"clear_L05":
				return SaveManager.highest_stage >= 5
			"clear_L06":
				return SaveManager.highest_stage >= 6
			"clear_L07":
				return SaveManager.highest_stage >= 7
			"H2_only":
				return "H2_hiroshima" in SaveManager.unlocked_hidden_stages
	return false


## 按索引选中战机
func _select_by_index(index: int) -> void:
	if index < 0 or index >= _aircrafts.size():
		return
	_selected_index = index
	_update_detail_panel()


## 按 ID 选中战机
func _select_by_id(aircraft_id: String) -> void:
	for i in range(_aircrafts.size()):
		if String(_aircrafts[i].get("aircraft_id", "")) == aircraft_id:
			_select_by_index(i)
			return
	# v1.5 修复：未找到时回退到默认（第 0 个），避免详情面板保持 placeholder
	_select_by_index(0)


## 更新详情面板
func _update_detail_panel() -> void:
	if _aircrafts.is_empty():
		return
	var ac: Dictionary = _aircrafts[_selected_index]
	_detail_name.text = String(ac.get("display_name", ""))
	_detail_desc.text = String(ac.get("description", ""))
	_detail_stats.text = "HP: %d | 速度: %.0f | 射速: %.2fs | 子弹: %d | 炸弹: %d" % [
		int(ac.get("max_hp", 0)),
		float(ac.get("speed", 0)),
		float(ac.get("shoot_interval", 0)),
		int(ac.get("bullet_count", 0)),
		int(ac.get("max_bombs", 0)),
	]


# ============================================================
# 按钮回调
# ============================================================

## 主菜单场景路径（确认/返回后跳转）
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

func _on_confirm() -> void:
	if _aircrafts.is_empty():
		return
	var ac: Dictionary = _aircrafts[_selected_index]
	# v1.5 修复：确认前验证战机解锁状态，防止使用未解锁战机（如存档数据损坏）
	if not _is_unlocked(ac):
		print("[Hangar] 警告：战机 %s 未解锁，无法确认" % String(ac.get("aircraft_id", "")))
		return
	var aircraft_id: String = String(ac.get("aircraft_id", ""))
	if SaveManager:
		SaveManager.set_selected_aircraft(aircraft_id)
		SaveManager.save_game()
	aircraft_selected.emit(aircraft_id)
	print("[Hangar] 已确认选择战机: %s" % aircraft_id)
	# 返回主菜单
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)


func _on_back() -> void:
	back_pressed.emit()
	# 返回主菜单
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)


# ============================================================
# 公开接口
# ============================================================

## 根据战机 ID 获取对应的玩家场景路径
static func get_player_scene_path(aircraft_id: String) -> String:
	return AIRCRAFT_SCENES.get(aircraft_id, "res://scenes/player/player_p40.tscn")
