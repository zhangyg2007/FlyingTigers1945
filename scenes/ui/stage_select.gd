extends CanvasLayer
## 关卡选择界面
## 管理12个主线关 + 4个隐藏关的显示、解锁状态和选择交互。
## 根据SaveManager中的存档数据决定哪些关卡已解锁。
##
## 节点结构要求（在场景编辑器中搭建）：
## - StageGrid (GridContainer / GridBox)  -- 关卡按钮网格容器
##   - StageButton_01 ~ StageButton_16 (Button) -- 16个关卡按钮
##     - 每个按钮内含：StageNumberLabel (Label), StageNameLabel (Label), StarIcon (TextureRect)
## - BackButton (Button)              -- 返回按钮
## - HiddenSection (VBoxContainer)    -- 隐藏关卡区域（可选，也可放在同一网格中）

# ============================================================
# 常量：关卡数据
# ============================================================

## 关卡信息数据结构：[编号, 名称, 场景路径]
## 12个主线关 + 4个隐藏关 = 16关（索引0~15）
## 隐藏关索引: H1=12, H2=13, H3=14, H4=15
const STAGE_DATA: Array[Dictionary] = [
	# ---- 主线关卡（索引0~11）----
	{"id": 0,  "number": "01", "name": "昆明",    "name_en": "Kunming",     "scene": "res://scenes/levels/stage_01_kunming.tscn",    "hidden": false},
	{"id": 1,  "number": "02", "name": "缅甸",    "name_en": "Burma",       "scene": "res://scenes/levels/stage_02_burma.tscn",      "hidden": false},
	{"id": 2,  "number": "03", "name": "仰光",    "name_en": "Rangoon",     "scene": "res://scenes/levels/stage_03_rangoon.tscn",    "hidden": false},
	{"id": 3,  "number": "04", "name": "驼峰",    "name_en": "Hump",        "scene": "res://scenes/levels/stage_04_hump.tscn",       "hidden": false},
	{"id": 4,  "number": "05", "name": "桂林",    "name_en": "Guilin",      "scene": "res://scenes/levels/stage_05_guilin.tscn",     "hidden": false},
	{"id": 5,  "number": "06", "name": "衡阳",    "name_en": "Hengyang",    "scene": "res://scenes/levels/stage_06_hengyang.tscn",   "hidden": false},
	{"id": 6,  "number": "07", "name": "武汉",    "name_en": "Wuhan",       "scene": "res://scenes/levels/stage_07_wuhan.tscn",      "hidden": false},
	{"id": 7,  "number": "08", "name": "南京",    "name_en": "Nanjing",     "scene": "res://scenes/levels/stage_08_nanjing.tscn",    "hidden": false},
	{"id": 8,  "number": "09", "name": "上海",    "name_en": "Shanghai",    "scene": "res://scenes/levels/stage_09_shanghai.tscn",   "hidden": false},
	{"id": 9,  "number": "10", "name": "东京",    "name_en": "Tokyo",       "scene": "res://scenes/levels/stage_10_tokyo.tscn",     "hidden": false},
	{"id": 10, "number": "11", "name": "硫磺岛",  "name_en": "Iwo Jima",    "scene": "res://scenes/levels/stage_11_iwojima.tscn",   "hidden": false},
	{"id": 11, "number": "12", "name": "冲绳",    "name_en": "Okinawa",     "scene": "res://scenes/levels/stage_12_okinawa.tscn",   "hidden": false},
	# ---- 隐藏关卡（索引12~15）----
	{"id": 12, "number": "H1", "name": "驼峰（隐藏）", "name_en": "Hidden Hump",  "scene": "res://scenes/levels/stage_h1_hump.tscn",      "hidden": true},
	{"id": 13, "number": "H2", "name": "东京（隐藏）", "name_en": "Hidden Tokyo",  "scene": "res://scenes/levels/stage_h2_tokyo.tscn",     "hidden": true},
	{"id": 14, "number": "H3", "name": "震电（隐藏）", "name_en": "Shinden",       "scene": "res://scenes/levels/stage_h3_shinden.tscn",   "hidden": true},
	{"id": 15, "number": "H4", "name": "广岛（隐藏）", "name_en": "Hidden Hiroshima","scene": "res://scenes/levels/stage_h4_hiroshima.tscn", "hidden": true},
]

## 总主线关数
const MAIN_STAGE_COUNT: int = 12

## 按钮状态枚举
enum ButtonState {
	LOCKED,     ## 锁定（灰色，不可点击）
	UNLOCKED,   ## 已解锁（可点击）
	CLEARED,    ## 已通关（显示星章）
}

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

## 锁定状态下按钮的透明度
const LOCKED_OPACITY: float = 0.4

## 锁定状态下按钮的自定义调制颜色
const LOCKED_MODULATE: Color = Color(0.5, 0.5, 0.5, 1.0)

# ============================================================
# 节点引用
# ============================================================

## 关卡按钮网格容器 -- 节点路径: $StageGrid
@onready var stage_grid: GridContainer = %StageGrid

## 返回按钮 -- 节点路径: $BackButton
@onready var back_button: Button = %BackButton

# ============================================================
# 内部变量
# ============================================================

## 所有关卡按钮的引用缓存，key: stage_id, value: Button
var _stage_buttons: Dictionary = {}

## 所有星章图标的引用缓存，key: stage_id, value: TextureRect/Control
var _star_icons: Dictionary = {}

## 所有关卡编号标签的引用缓存，key: stage_id, value: Label
var _stage_number_labels: Dictionary = {}

## 所有关卡名称标签的引用缓存，key: stage_id, value: Label
var _stage_name_labels: Dictionary = {}

## 每关获得的评级记录（需要SaveManager扩展: stage_ranks）
## key: 关卡索引字符串, value: 评级字符串("S"/"A"/"B"/"C")
var _stage_ranks: Dictionary = {}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化关卡按钮，加载存档数据，更新解锁状态
	# 连接返回按钮信号
	back_button.pressed.connect(_on_back_button_pressed)

	# 初始化所有关卡按钮
	_init_stage_buttons()

	# 从SaveManager加载评级数据
	_load_stage_ranks()

	# 根据存档更新按钮状态
	_refresh_all_button_states()

	# 设置焦点到第一个解锁的按钮
	_grab_focus_to_first_unlocked()

	# 悬停效果
	_connect_button_hover_effects()


func _input(event: InputEvent) -> void:
	## 全局输入处理
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()

# ============================================================
# 初始化
# ============================================================

func _init_stage_buttons() -> void:
	## 初始化所有关卡按钮的引用和显示内容
	for i in range(STAGE_DATA.size()):
		var stage_info: Dictionary = STAGE_DATA[i]
		var stage_id: int = stage_info["id"]

		# 在网格容器中查找按钮（命名规则: StageButton_XX）
		var button_name: String = "StageButton_%s" % stage_info["number"]
		var button: Button = stage_grid.get_node_or_null(button_name) as Button

		if button == null:
			# 尝试使用 UniqueName (%StageButton_XX)
			button = get_node_or_null("%s" % button_name) as Button
			if button == null:
				push_warning("[StageSelect] 未找到按钮节点: %s" % button_name)
				continue

		# 缓存按钮引用
		_stage_buttons[stage_id] = button

		# 查找按钮内的子节点
		_cache_button_children(stage_id, button, stage_info)

		# 连接按钮点击信号
		button.pressed.connect(_on_stage_button_pressed.bind(stage_id))

		# 初始状态为锁定（后面会根据存档更新）
		button.disabled = true
		button.modulate = LOCKED_MODULATE


func _cache_button_children(stage_id: int, button: Button, stage_info: Dictionary) -> void:
	## 缓存按钮内部子节点引用
	# 编号标签
	var number_label: Label = button.get_node_or_null("StageNumberLabel") as Label
	if number_label == null:
		number_label = button.get_node_or_null("NumberLabel") as Label
	if number_label != null:
		number_label.text = stage_info["number"]
		_stage_number_labels[stage_id] = number_label

	# 名称标签
	var name_label: Label = button.get_node_or_null("StageNameLabel") as Label
	if name_label == null:
		name_label = button.get_node_or_null("NameLabel") as Label
	if name_label != null:
		name_label.text = stage_info["name"]
		_stage_name_labels[stage_id] = name_label

	# 星章图标
	var star_icon: Control = button.get_node_or_null("StarIcon") as Control
	if star_icon == null:
		star_icon = button.get_node_or_null("ClearedIcon") as Control
	if star_icon != null:
		star_icon.visible = false
		_star_icons[stage_id] = star_icon


func _load_stage_ranks() -> void:
	## 从SaveManager加载每关的评级记录
	# SaveManager需要扩展: var stage_ranks: Dictionary = {}
	if SaveManager.has_method("get_stage_ranks"):
		_stage_ranks = SaveManager.get_stage_ranks()
	elif "stage_ranks" in SaveManager:
		_stage_ranks = SaveManager.stage_ranks
	else:
		_stage_ranks = {}

# ============================================================
# 解锁逻辑
# ============================================================

func _refresh_all_button_states() -> void:
	## 根据SaveManager中的存档数据刷新所有按钮状态
	for i in range(STAGE_DATA.size()):
		var stage_info: Dictionary = STAGE_DATA[i]
		var stage_id: int = stage_info["id"]

		if stage_info["hidden"]:
			_update_hidden_stage_state(stage_id)
		else:
			_update_main_stage_state(stage_id)


func _update_main_stage_state(stage_id: int) -> void:
	## 更新主线关卡按钮状态
	var button: Button = _stage_buttons.get(stage_id) as Button
	if button == null:
		return

	var state: ButtonState = _get_main_stage_state(stage_id)
	_apply_button_state(button, stage_id, state)


func _update_hidden_stage_state(stage_id: int) -> void:
	## 更新隐藏关卡按钮状态（含条件检查）
	var button: Button = _stage_buttons.get(stage_id) as Button
	if button == null:
		return

	var unlocked: bool = _check_hidden_stage_unlock_condition(stage_id)

	if unlocked:
		var is_cleared: bool = _is_stage_cleared(stage_id)
		_apply_button_state(button, stage_id, ButtonState.CLEARED if is_cleared else ButtonState.UNLOCKED)
	else:
		# 隐藏关未解锁：显示为锁定状态，名称显示为 "???"
		_apply_button_state(button, stage_id, ButtonState.LOCKED)
		var name_label: Label = _stage_name_labels.get(stage_id) as Label
		if name_label != null:
			name_label.text = "???"


func _get_main_stage_state(stage_id: int) -> ButtonState:
	## 获取主线关卡的状态
	var highest: int = SaveManager.highest_stage

	# 第一关始终解锁（highest_stage初始值为0，对应索引0）
	if stage_id <= highest:
		if _is_stage_cleared(stage_id):
			return ButtonState.CLEARED
		return ButtonState.UNLOCKED
	elif stage_id == highest + 1:
		# 下一关解锁（最高通关关卡的下一关）
		return ButtonState.UNLOCKED
	else:
		return ButtonState.LOCKED


func _check_hidden_stage_unlock_condition(stage_id: int) -> bool:
	## 检查隐藏关卡解锁条件
	##
	## H1 驼峰（索引12）: 通关第4关（驼峰主线，索引3）后S评级
	## H2 东京（索引13）: 通关第10关后S评级
	## H3 震电（索引14）: 通关第7关后A评级以上
	## H4 广岛（索引15）: 通关全部12关后解锁

	match stage_id:
		12:  # H1 驼峰隐藏关
			return _is_stage_cleared_with_rank(3, "S")

		13:  # H2 东京隐藏关
			return _is_stage_cleared_with_rank(9, "S")

		14:  # H3 震电隐藏关
			return _is_stage_cleared_with_min_rank(6, "A")

		15:  # H4 广岛隐藏关
			# 通关全部12个主线关（索引0~11）
			return _are_all_main_stages_cleared()

		_:
			return false


func _is_stage_cleared(stage_id: int) -> bool:
	## 检查指定关卡是否已通关
	# 如果该关有最高分记录，视为已通关
	var key: String = str(stage_id)
	if "stage_high_scores" in SaveManager:
		return SaveManager.stage_high_scores.has(key) and SaveManager.stage_high_scores[key] > 0

	# 也检查评级记录
	return _stage_ranks.has(key)


func _is_stage_cleared_with_rank(stage_id: int, required_rank: String) -> bool:
	## 检查指定关卡是否已通关且达到指定评级
	if not _is_stage_cleared(stage_id):
		return false

	var key: String = str(stage_id)
	var rank: String = _stage_ranks.get(key, "")
	return rank == required_rank


func _is_stage_cleared_with_min_rank(stage_id: int, min_rank: String) -> bool:
	## 检查指定关卡是否已通关且评级不低于指定等级
	## 评级排序: S > A > B > C
	if not _is_stage_cleared(stage_id):
		return false

	var key: String = str(stage_id)
	var rank: String = _stage_ranks.get(key, "C")
	var rank_order: Dictionary = {"S": 4, "A": 3, "B": 2, "C": 1}

	var current_level: int = rank_order.get(rank, 1)
	var min_level: int = rank_order.get(min_rank, 1)

	return current_level >= min_level


func _are_all_main_stages_cleared() -> bool:
	## 检查是否已通关全部12个主线关
	for i in range(MAIN_STAGE_COUNT):
		if not _is_stage_cleared(i):
			return false
	return true

# ============================================================
# 按钮状态视觉
# ============================================================

func _apply_button_state(button: Button, stage_id: int, state: ButtonState) -> void:
	## 根据状态设置按钮的视觉表现
	var star_icon: Control = _star_icons.get(stage_id) as Control

	match state:
		ButtonState.LOCKED:
			button.disabled = true
			button.modulate = LOCKED_MODULATE
			if star_icon != null:
				star_icon.visible = false

		ButtonState.UNLOCKED:
			button.disabled = false
			button.modulate = Color.WHITE
			if star_icon != null:
				star_icon.visible = false

		ButtonState.CLEARED:
			button.disabled = false
			button.modulate = Color.WHITE
			if star_icon != null:
				star_icon.visible = true

# ============================================================
# 按钮回调
# ============================================================

func _on_stage_button_pressed(stage_id: int) -> void:
	## 关卡按钮点击回调：加载对应关卡
	if not _stage_buttons.has(stage_id):
		return

	var button: Button = _stage_buttons[stage_id] as Button
	if button.disabled:
		return

	_play_button_click_effect(button)

	# 重置游戏状态并加载关卡
	GameManager.reset_game()
	GameManager.set_stage(stage_id)

	var stage_info: Dictionary = STAGE_DATA[stage_id]
	get_tree().change_scene_to_file(stage_info["scene"])


func _on_back_button_pressed() -> void:
	## 返回按钮回调：返回主菜单
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

# ============================================================
# 悬停效果
# ============================================================

func _connect_button_hover_effects() -> void:
	## 为所有关卡按钮连接悬停效果
	for stage_id in _stage_buttons:
		var button: Button = _stage_buttons[stage_id] as Button
		if button != null and not button.disabled:
			button.mouse_entered.connect(_on_stage_button_hovered.bind(button))
			button.mouse_exited.connect(_on_stage_button_unhovered.bind(button))


func _on_stage_button_hovered(button: Button) -> void:
	## 关卡按钮悬停效果
	if button.disabled:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)


func _on_stage_button_unhovered(button: Button) -> void:
	## 关卡按钮离开效果
	if button.disabled:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)


func _play_button_click_effect(button: Button) -> void:
	## 按钮点击缩放效果
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

# ============================================================
# 焦点管理
# ============================================================

func _grab_focus_to_first_unlocked() -> void:
	## 将焦点设置到第一个已解锁的关卡按钮
	for i in range(STAGE_DATA.size()):
		var button: Button = _stage_buttons.get(i) as Button
		if button != null and not button.disabled:
			button.grab_focus()
			return
