extends CanvasLayer
## 排行榜界面
## 显示深渊模式本地排行榜（前20名记录）。
## 每条记录包含：排名、层数、得分、战机类型、日期。
## 数据来源：SaveManager.abyss_history
##
## 节点结构要求（在场景编辑器中搭建）：
## - TitleLabel (Label)                -- "排行榜" 标题
## - HeaderContainer (HBoxContainer)  -- 表头（排名/层数/得分/战机/日期）
## - RecordContainer (VBoxContainer)   -- 记录列表容器
##   - RecordEntry_01 ~ RecordEntry_20 (HBoxContainer) -- 单条记录
##     - RankLabel (Label)              -- 排名
##     - FloorLabel (Label)            -- 层数
##     - ScoreLabel (Label)             -- 得分
##     - PlaneLabel (Label)             -- 战机类型
##     - DateLabel (Label)              -- 日期
## - EmptyLabel (Label)                -- 无记录时显示的提示文字
## - BackButton (Button)               -- 返回按钮
## - ScrollContainer (ScrollContainer) -- 可选：用于滚动显示记录

# ============================================================
# 常量
# ============================================================

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

## 最大排行榜记录数
const MAX_RECORDS: int = 20

## 排名颜色（前3名特殊显示）
const RANK_COLORS: Dictionary = {
	1: Color.GOLD,                                          # 第1名：金色
	2: Color.SILVER,                                        # 第2名：银色
	3: Color(0.8, 0.52, 0.25, 1.0),                        # 第3名：铜色
}

## 记录条目节点命名前缀
const RECORD_PREFIX: String = "RecordEntry_"

## 战机类型名称映射
const PLANE_NAMES: Dictionary = {
	"p40_warhawk": "P-40 战鹰",
	"p51_mustang": "P-51 野马",
	"p38_lightning": "P-38 闪电",
	"b25_mitchell": "B-25 米切尔",
	"spitfire": "喷火",
	"zero": "零式",
}

# ============================================================
# 节点引用
# ============================================================

## 记录列表容器 -- 节点路径: $RecordContainer
@onready var record_container: VBoxContainer = %RecordContainer

## 无记录提示标签 -- 节点路径: $EmptyLabel
@onready var empty_label: Label = %EmptyLabel

## 返回按钮 -- 节点路径: $BackButton
@onready var back_button: Button = %BackButton

## 表头容器 -- 节点路径: $HeaderContainer
@onready var header_container: HBoxContainer = %HeaderContainer

## 可选：滚动容器 -- 节点路径: $ScrollContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer

# ============================================================
# 内部变量
# ============================================================

## 排行榜数据数组（排序后的前20条记录）
## 每条记录: { "floor": int, "score": int, "plane_type": String, "date": String }
var _records: Array[Dictionary] = []

## 缓存的记录条目节点引用数组
var _record_entries: Array[HBoxContainer] = []

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化：加载排行榜数据，连接按钮信号
	# 连接返回按钮
	back_button.pressed.connect(_on_back_button_pressed)

	# 加载并显示排行榜数据
	load_leaderboard_data()

	# 设置焦点到返回按钮
	back_button.grab_focus()


func _input(event: InputEvent) -> void:
	## 全局输入处理
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()

# ============================================================
# 数据加载
# ============================================================

func load_leaderboard_data() -> void:
	## 从SaveManager加载深渊模式历史记录并排序显示
	_records.clear()

	# 从SaveManager获取深渊模式历史记录
	# 需要SaveManager扩展: var abyss_history: Array[Dictionary] = []
	# 每条记录格式: { "floor": int, "score": int, "plane_type": String, "date": String }
	if SaveManager.has_method("get_abyss_history"):
		_records = SaveManager.get_abyss_history()
	elif "abyss_history" in SaveManager:
		var history = SaveManager.abyss_history
		if history is Array:
			for record in history:
				if record is Dictionary:
					_records.append(record)
	else:
		# 如果SaveManager没有abyss_history，尝试从旧格式数据构建
		_build_records_from_legacy_data()

	# 按分数降序排序
	_sort_records_by_score()

	# 只保留前MAX_RECORDS条
	_trim_records()

	# 刷新UI显示
	_refresh_display()


func _build_records_from_legacy_data() -> void:
	## 从SaveManager的旧版数据（abyss_best_floor, abyss_best_score）构建单条记录
	if SaveManager.abyss_best_score > 0:
		_records.append({
			"floor": SaveManager.abyss_best_floor,
			"score": SaveManager.abyss_best_score,
			"plane_type": "p40_warhawk",  # 默认战机
			"date": Time.get_date_string_from_system(),
		})


func _sort_records_by_score() -> void:
	## 按分数降序排序
	_records.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a.get("score", 0) > b.get("score", 0)
	)


func _trim_records() -> void:
	## 裁剪到最大记录数
	if _records.size() > MAX_RECORDS:
		_records.resize(MAX_RECORDS)

# ============================================================
# UI显示
# ============================================================

func _refresh_display() -> void:
	## 刷新排行榜UI显示
	# 先清除旧的记录条目引用
	_record_entries.clear()

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
	## 逐条显示排行榜记录
	# 清空现有记录显示
	for child in record_container.get_children():
		child.visible = false

	# 查找并缓存记录条目节点
	for i in range(_records.size()):
		var record: Dictionary = _records[i]
		var entry_name: String = "%s%02d" % [RECORD_PREFIX, i + 1]

		var entry: HBoxContainer = record_container.get_node_or_null(entry_name) as HBoxContainer
		if entry == null:
			# 尝试使用 UniqueName
			entry = get_node_or_null("%s" % entry_name) as HBoxContainer
			if entry == null:
				push_warning("[Leaderboard] 未找到记录条目节点: %s" % entry_name)
				continue

		_record_entries.append(entry)
		entry.visible = true

		# 填充数据到对应标签
		_fill_record_entry(entry, record, i + 1)


func _fill_record_entry(entry: HBoxContainer, record: Dictionary, rank: int) -> void:
	## 填充单条记录的数据
	var floor_val: int = record.get("floor", 0)
	var score_val: int = record.get("score", 0)
	var plane_type: String = record.get("plane_type", "")
	var date_val: String = record.get("date", "")

	# 获取标签节点
	var rank_label: Label = entry.get_node_or_null("RankLabel") as Label
	var floor_label: Label = entry.get_node_or_null("FloorLabel") as Label
	var score_label: Label = entry.get_node_or_null("ScoreLabel") as Label
	var plane_label: Label = entry.get_node_or_null("PlaneLabel") as Label
	var date_label: Label = entry.get_node_or_null("DateLabel") as Label

	# 排名
	if rank_label != null:
		rank_label.text = "%d" % rank
		# 前3名特殊颜色
		if RANK_COLORS.has(rank):
			rank_label.modulate = RANK_COLORS[rank]
		else:
			rank_label.modulate = Color.WHITE

	# 层数
	if floor_label != null:
		floor_label.text = "%dF" % floor_val

	# 得分
	if score_label != null:
		score_label.text = "%08d" % score_val

	# 战机类型（使用中文名称映射）
	if plane_label != null:
		if PLANE_NAMES.has(plane_type):
			plane_label.text = PLANE_NAMES[plane_type]
		else:
			plane_label.text = plane_type

	# 日期
	if date_label != null:
		# 如果日期数据完整则直接显示，否则显示 "N/A"
		if not date_val.is_empty():
			date_label.text = date_val
		else:
			date_label.text = "N/A"

# ============================================================
# 按钮回调
# ============================================================

func _on_back_button_pressed() -> void:
	## 返回按钮回调：返回主菜单
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)
