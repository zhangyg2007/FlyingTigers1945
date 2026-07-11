extends CanvasLayer
## 排行榜界面
## 显示两个分类的排行榜：主线关卡、深渊模式。
## 每个分类显示前 10 名记录，每条记录包含：排名、玩家名、分数、关卡/层数、日期。
## 数据来源：LocalLeaderboard 类（res://scripts/local_leaderboard.gd）
##
## 节点结构要求（在场景编辑器中搭建）：
## - Background (ColorRect)                    -- 背景
## - TitleLabel (Label)                        -- "排行榜" 标题
## - CategoryContainer (HBoxContainer)         -- 分类切换按钮容器
##   - MainStageButton (Button)                -- 主线关卡
##   - AbyssButton (Button)                    -- 深渊模式
## - HeaderContainer (HBoxContainer)           -- 表头
## - RecordContainer (VBoxContainer)           -- 记录列表容器
## - EmptyLabel (Label)                        -- 无记录提示
## - ClearButton (Button)                      -- 清除按钮
## - BackButton (Button)                       -- 返回按钮

# ============================================================
# 常量
# ============================================================

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

## 最大显示记录数
const MAX_DISPLAY_RECORDS: int = 10

## 排名颜色（前3名特殊显示）
const RANK_COLORS: Dictionary = {
	1: Color(1.0, 0.84, 0.0, 1.0),       # 第1名：金色
	2: Color(0.75, 0.75, 0.75, 1.0),     # 第2名：银色
	3: Color(0.8, 0.52, 0.25, 1.0),      # 第3名：铜色
}

# ============================================================
# 节点引用
# ============================================================

## 主线关卡分类按钮 -- 节点路径: %MainStageButton
@onready var main_stage_button: Button = %MainStageButton

## 深渊模式分类按钮 -- 节点路径: %AbyssButton
@onready var abyss_button: Button = %AbyssButton

## 记录列表容器 -- 节点路径: %RecordContainer
@onready var record_container: VBoxContainer = %RecordContainer

## 无记录提示标签 -- 节点路径: %EmptyLabel
@onready var empty_label: Label = %EmptyLabel

## 表头容器 -- 节点路径: %HeaderContainer
@onready var header_container: HBoxContainer = %HeaderContainer

## 清除按钮 -- 节点路径: %ClearButton
@onready var clear_button: Button = %ClearButton

## 返回按钮 -- 节点路径: %BackButton
@onready var back_button: Button = %BackButton

## 确认对话框 -- 节点路径: %ConfirmDialog
@onready var confirm_dialog: ConfirmationDialog = %ConfirmDialog

# ============================================================
# 内部变量
# ============================================================

## LocalLeaderboard 实例（在 _ready 中 new 并 add_child）
var _leaderboard: LocalLeaderboard = null

## 当前选中的分类
var _current_category: String = LocalLeaderboard.CATEGORY_STAGE

## 当前显示的记录列表
var _records: Array[Dictionary] = []

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化：创建 LocalLeaderboard 实例，连接信号，加载数据
	# 创建 LocalLeaderboard 实例并添加为子节点
	_leaderboard = LocalLeaderboard.new()
	add_child(_leaderboard)

	# 连接分类切换按钮信号
	main_stage_button.pressed.connect(_on_main_stage_button_pressed)
	abyss_button.pressed.connect(_on_abyss_button_pressed)

	# 连接清除和返回按钮信号
	clear_button.pressed.connect(_on_clear_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	# 连接确认对话框信号
	if confirm_dialog != null:
		confirm_dialog.confirmed.connect(_on_clear_confirmed)

	# 默认选中主线关卡分类
	_update_category_buttons()
	_load_and_display_records()

	# 设置焦点到返回按钮
	back_button.grab_focus()


func _input(event: InputEvent) -> void:
	## 全局输入处理：ESC 返回主菜单
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()

# ============================================================
# 分类切换
# ============================================================

func _on_main_stage_button_pressed() -> void:
	## 主线关卡分类按钮回调
	_current_category = LocalLeaderboard.CATEGORY_STAGE
	_update_category_buttons()
	_load_and_display_records()


func _on_abyss_button_pressed() -> void:
	## 深渊模式分类按钮回调
	_current_category = LocalLeaderboard.CATEGORY_ABYSS
	_update_category_buttons()
	_load_and_display_records()


func _update_category_buttons() -> void:
	## 根据当前分类更新按钮视觉状态
	var is_main: bool = _current_category == LocalLeaderboard.CATEGORY_STAGE
	main_stage_button.disabled = is_main
	abyss_button.disabled = not is_main

	# 视觉区分：选中项高亮
	if is_main:
		main_stage_button.modulate = Color(1.0, 0.85, 0.2, 1.0)
		abyss_button.modulate = Color.WHITE
	else:
		main_stage_button.modulate = Color.WHITE
		abyss_button.modulate = Color(1.0, 0.85, 0.2, 1.0)

# ============================================================
# 数据加载与显示
# ============================================================

func _load_and_display_records() -> void:
	## 加载当前分类的记录并刷新显示
	_records = _leaderboard.get_entries(_current_category)
	_refresh_display()


func _refresh_display() -> void:
	## 刷新排行榜 UI 显示
	# 清空现有记录条目
	for child in record_container.get_children():
		child.queue_free()

	# 根据是否有记录决定显示内容
	if _records.is_empty():
		_show_empty_state()
		return

	_hide_empty_state()
	_display_records()


func _show_empty_state() -> void:
	## 显示无记录提示
	if empty_label != null:
		empty_label.visible = true
	if header_container != null:
		header_container.visible = false
	if record_container != null:
		record_container.visible = false


func _hide_empty_state() -> void:
	## 隐藏无记录提示
	if empty_label != null:
		empty_label.visible = false
	if header_container != null:
		header_container.visible = true
	if record_container != null:
		record_container.visible = true


func _display_records() -> void:
	## 逐条显示排行榜记录（动态创建条目）
	for i in range(_records.size()):
		var record: Dictionary = _records[i]
		var entry: HBoxContainer = _create_record_entry(record, i + 1)
		record_container.add_child(entry)


func _create_record_entry(record: Dictionary, rank: int) -> HBoxContainer:
	## 创建单条记录的显示条目
	var entry: HBoxContainer = HBoxContainer.new()
	entry.custom_minimum_size = Vector2(0, 40)
	entry.add_theme_constant_override("separation", 10)

	# 排名标签
	var rank_label: Label = Label.new()
	rank_label.text = "%d." % rank
	rank_label.custom_minimum_size = Vector2(60, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 22)
	if RANK_COLORS.has(rank):
		rank_label.modulate = RANK_COLORS[rank]
	entry.add_child(rank_label)

	# 玩家名标签
	var name_label: Label = Label.new()
	name_label.text = record.get("name", "???")
	name_label.custom_minimum_size = Vector2(140, 0)
	name_label.add_theme_font_size_override("font_size", 20)
	entry.add_child(name_label)

	# 分数标签
	var score_label: Label = Label.new()
	score_label.text = "%08d" % record.get("score", 0)
	score_label.custom_minimum_size = Vector2(180, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 20)
	entry.add_child(score_label)

	# 关卡/层数标签
	var stage_label: Label = Label.new()
	var stage_val: String = str(record.get("stage_id", ""))
	# 深渊模式显示层数，主线显示关卡名
	if _current_category == LocalLeaderboard.CATEGORY_ABYSS:
		stage_label.text = "%sF" % stage_val
	else:
		stage_label.text = stage_val
	stage_label.custom_minimum_size = Vector2(160, 0)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 18)
	entry.add_child(stage_label)

	# 日期标签
	var date_label: Label = Label.new()
	date_label.text = record.get("date", "N/A")
	date_label.custom_minimum_size = Vector2(140, 0)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 16)
	date_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
	entry.add_child(date_label)

	return entry

# ============================================================
# 按钮回调
# ============================================================

func _on_clear_button_pressed() -> void:
	## 清除按钮回调：弹出确认对话框
	if confirm_dialog != null:
		var category_name: String = "主线关卡" if _current_category == LocalLeaderboard.CATEGORY_STAGE else "深渊模式"
		confirm_dialog.title = "确认清除"
		confirm_dialog.dialog_text = "确定要清除「%s」分类的所有排行榜记录吗？\n此操作不可撤销。" % category_name
		confirm_dialog.popup_centered()
	else:
		# 没有对话框，直接清除
		_on_clear_confirmed()


func _on_clear_confirmed() -> void:
	## 确认清除后执行
	_leaderboard.clear_category(_current_category)
	_load_and_display_records()


func _on_back_button_pressed() -> void:
	## 返回按钮回调：返回主菜单
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)
