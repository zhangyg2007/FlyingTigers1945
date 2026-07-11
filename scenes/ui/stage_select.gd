extends CanvasLayer
## 关卡选择界面
## 从 stage_config.json 读取 8 个主线关卡，根据 SaveManager.highest_stage 判断解锁状态。
## 每个关卡按钮显示：关卡名、锁定状态、最高分。
##
## 节点结构要求（在场景编辑器中搭建）：
## - Background (TextureRect)         -- 背景图 ui_stage_select_map.png
## - TitleLabel (Label)               -- "关卡选择" 标题
## - StageGrid (GridContainer)         -- 关卡按钮网格容器（2列）
## - BackButton (Button)               -- 返回按钮（左上角）

# ============================================================
# 常量
# ============================================================

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

## 关卡配置文件路径
const STAGE_CONFIG_PATH: String = "res://resources/level_data/stage_config.json"

## 关卡场景目录
const LEVEL_SCENE_DIR: String = "res://levels/"

## 锁定状态下按钮的调制颜色
const LOCKED_MODULATE: Color = Color(0.4, 0.4, 0.4, 1.0)

## 锁定状态下显示的文字
const LOCKED_TEXT: String = "???"

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

## 关卡数据数组（从 stage_config.json 读取）
## 每条: { "stage_id": String, "stage_name": String, ... }
var _stage_data: Array[Dictionary] = []

## 所有关卡按钮的引用缓存，key: stage_index(int), value: Button
var _stage_buttons: Dictionary = {}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化：加载关卡配置，生成按钮，连接信号
	# 连接返回按钮信号
	back_button.pressed.connect(_on_back_button_pressed)

	# 加载关卡配置
	_load_stage_config()

	# 动态生成关卡按钮
	_build_stage_buttons()

	# 根据存档刷新按钮状态
	_refresh_all_button_states()


func _input(event: InputEvent) -> void:
	## 全局输入处理：ESC 返回主菜单
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()

# ============================================================
# 配置加载
# ============================================================

func _load_stage_config() -> void:
	## 从 stage_config.json 读取关卡数据
	_stage_data.clear()

	if not FileAccess.file_exists(STAGE_CONFIG_PATH):
		push_error("[StageSelect] stage_config.json 不存在: %s" % STAGE_CONFIG_PATH)
		return

	var file: FileAccess = FileAccess.open(STAGE_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("[StageSelect] 无法打开 stage_config.json")
		return

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("[StageSelect] stage_config.json 解析失败: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	var stages: Array = data.get("stages", [])
	for stage in stages:
		if stage is Dictionary:
			_stage_data.append(stage)

# ============================================================
# 按钮生成
# ============================================================

func _build_stage_buttons() -> void:
	## 根据关卡数据动态生成关卡按钮
	# 清除可能存在的旧按钮
	for child in stage_grid.get_children():
		child.queue_free()
	_stage_buttons.clear()

	for i in range(_stage_data.size()):
		var stage_info: Dictionary = _stage_data[i]
		var button: Button = _create_stage_button(i, stage_info)
		stage_grid.add_child(button)
		_stage_buttons[i] = button

		# 连接按钮点击信号
		button.pressed.connect(_on_stage_button_pressed.bind(i))


func _create_stage_button(stage_index: int, stage_info: Dictionary) -> Button:
	## 创建单个关卡按钮
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(240, 120)
	button.text = ""
	button.name = "StageButton_%02d" % (stage_index + 1)

	# 创建 VBoxContainer 容纳关卡信息
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(vbox)

	# 关卡编号 + 名称标签
	var name_label: Label = Label.new()
	name_label.name = "StageNameLabel"
	name_label.text = "%d. %s" % [stage_index + 1, stage_info.get("stage_name", "未知")]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	# 最高分标签
	var score_label: Label = Label.new()
	score_label.name = "HighScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(score_label)

	# 锁定状态标签
	var lock_label: Label = Label.new()
	lock_label.name = "LockLabel"
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lock_label)

	return button

# ============================================================
# 按钮状态刷新
# ============================================================

func _refresh_all_button_states() -> void:
	## 根据存档数据刷新所有按钮状态
	for i in range(_stage_data.size()):
		_refresh_button_state(i)


func _refresh_button_state(stage_index: int) -> void:
	## 刷新单个按钮的解锁状态和显示内容
	var button: Button = _stage_buttons.get(stage_index) as Button
	if button == null:
		return

	var is_locked: bool = _is_stage_locked(stage_index)
	var high_score: int = SaveManager.get_stage_high_score(stage_index)

	# 获取子标签
	var vbox: VBoxContainer = button.get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return

	var name_label: Label = vbox.get_node_or_null("StageNameLabel") as Label
	var score_label: Label = vbox.get_node_or_null("HighScoreLabel") as Label
	var lock_label: Label = vbox.get_node_or_null("LockLabel") as Label

	var stage_info: Dictionary = _stage_data[stage_index]
	var stage_name: String = stage_info.get("stage_name", "未知")

	if is_locked:
		# 锁定状态：灰色、不可点击、名称隐藏
		button.disabled = true
		button.modulate = LOCKED_MODULATE
		if name_label != null:
			name_label.text = LOCKED_TEXT
		if score_label != null:
			score_label.text = ""
		if lock_label != null:
			lock_label.text = "🔒 锁定"
	else:
		# 解锁状态
		button.disabled = false
		button.modulate = Color.WHITE
		if name_label != null:
			name_label.text = "%d. %s" % [stage_index + 1, stage_name]
		if score_label != null:
			if high_score > 0:
				score_label.text = "最高分: %08d" % high_score
			else:
				score_label.text = "未通关"
		if lock_label != null:
			lock_label.text = ""


func _is_stage_locked(stage_index: int) -> bool:
	## 判断关卡是否锁定
	## 第一关始终解锁，后续关卡需要前一关通关（highest_stage 判断）
	var highest: int = 0
	if SaveManager:
		highest = SaveManager.highest_stage
	# stage_index <= highest 即已解锁（highest_stage 表示最高解锁的关卡索引）
	return stage_index > highest

# ============================================================
# 按钮回调
# ============================================================

func _on_stage_button_pressed(stage_index: int) -> void:
	## 关卡按钮点击回调：加载对应关卡
	if not _stage_buttons.has(stage_index):
		return

	var button: Button = _stage_buttons[stage_index] as Button
	if button.disabled:
		return

	_play_button_click_effect(button)

	# 获取关卡信息
	var stage_info: Dictionary = _stage_data[stage_index]
	var stage_id: String = stage_info.get("stage_id", "")

	# 重置游戏状态并加载关卡元数据
	GameManager.reset_game()
	GameManager.set_stage(stage_index)
	GameManager.load_stage(stage_id)

	# 切换到关卡场景
	var stage_path: String = LEVEL_SCENE_DIR + "stage_" + stage_id + ".tscn"
	get_tree().change_scene_to_file(stage_path)


func _on_back_button_pressed() -> void:
	## 返回按钮回调：返回主菜单
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

# ============================================================
# 动画效果
# ============================================================

func _play_button_click_effect(button: Button) -> void:
	## 按钮点击缩放效果
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
