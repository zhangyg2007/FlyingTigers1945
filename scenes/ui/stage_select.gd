extends CanvasLayer
## 关卡选择界面
## 从 stage_config.json 读取关卡，根据 SaveManager.highest_stage 和 UnlockManager 判断解锁状态。
## 隐藏关三种状态：locked(???) / rank_required(军衔不足) / unlocked(可玩)

const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"
const STAGE_CONFIG_PATH: String = "res://resources/level_data/stage_config.json"
const LEVEL_SCENE_DIR: String = "res://levels/"
const LOCKED_MODULATE: Color = Color(0.4, 0.4, 0.4, 1.0)
const RANK_REQUIRED_MODULATE: Color = Color(0.6, 0.5, 0.3, 1.0)
const LOCKED_TEXT: String = "???"

@onready var stage_grid: GridContainer = %StageGrid
@onready var back_button: Button = %BackButton

var _stage_data: Array[Dictionary] = []
var _stage_buttons: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_load_stage_config()
	_build_stage_buttons()
	_refresh_all_button_states()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()

func _load_stage_config() -> void:
	_stage_data.clear()
	if not FileAccess.file_exists(STAGE_CONFIG_PATH):
		push_error("[StageSelect] stage_config.json 不存在")
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
		push_error("[StageSelect] stage_config.json 解析失败")
		return
	var data: Dictionary = json.data
	var stages: Array = data.get("stages", [])
	for stage in stages:
		if stage is Dictionary:
			_stage_data.append(stage)

func _build_stage_buttons() -> void:
	for child in stage_grid.get_children():
		child.queue_free()
	_stage_buttons.clear()
	for i in range(_stage_data.size()):
		var stage_info: Dictionary = _stage_data[i]
		var button: Button = _create_stage_button(i, stage_info)
		stage_grid.add_child(button)
		_stage_buttons[i] = button
		button.pressed.connect(_on_stage_button_pressed.bind(i))

func _create_stage_button(stage_index: int, stage_info: Dictionary) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(240, 120)
	button.text = ""
	button.name = "StageButton_%02d" % (stage_index + 1)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(vbox)
	var name_label: Label = Label.new()
	name_label.name = "StageNameLabel"
	name_label.text = "%d. %s" % [stage_index + 1, stage_info.get("stage_name", "未知")]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)
	var score_label: Label = Label.new()
	score_label.name = "HighScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(score_label)
	var lock_label: Label = Label.new()
	lock_label.name = "LockLabel"
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lock_label)
	return button

func _refresh_all_button_states() -> void:
	for i in range(_stage_data.size()):
		_refresh_button_state(i)

func _refresh_button_state(stage_index: int) -> void:
	var button: Button = _stage_buttons.get(stage_index) as Button
	if button == null:
		return
	var stage_info: Dictionary = _stage_data[stage_index]
	var stage_id: String = stage_info.get("stage_id", "")
	var is_hidden: bool = stage_info.get("hidden", false)
	var high_score: int = SaveManager.get_stage_high_score(stage_index)
	var vbox: VBoxContainer = button.get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	var name_label: Label = vbox.get_node_or_null("StageNameLabel") as Label
	var score_label: Label = vbox.get_node_or_null("HighScoreLabel") as Label
	var lock_label: Label = vbox.get_node_or_null("LockLabel") as Label
	var stage_name: String = stage_info.get("stage_name", "未知")
	if is_hidden:
		_refresh_hidden_stage_button(button, stage_id, stage_name, high_score, name_label, score_label, lock_label)
	else:
		_refresh_normal_stage_button(button, stage_index, stage_name, high_score, name_label, score_label, lock_label)

func _refresh_normal_stage_button(button: Button, stage_index: int, stage_name: String, high_score: int, name_label: Label, score_label: Label, lock_label: Label) -> void:
	var is_locked: bool = _is_stage_locked(stage_index)
	if is_locked:
		button.disabled = true
		button.modulate = LOCKED_MODULATE
		if name_label != null:
			name_label.text = LOCKED_TEXT
		if score_label != null:
			score_label.text = ""
		if lock_label != null:
			lock_label.text = "🔒 锁定"
	else:
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

func _refresh_hidden_stage_button(button: Button, stage_id: String, stage_name: String, high_score: int, name_label: Label, score_label: Label, lock_label: Label) -> void:
	var status: String = "locked"
	if UnlockManager != null:
		status = UnlockManager.get_hidden_stage_unlock_status(stage_id)
	match status:
		"unlocked":
			button.disabled = false
			button.modulate = Color.WHITE
			if name_label != null:
				name_label.text = "🔮 %s" % stage_name
			if score_label != null:
				if high_score > 0:
					score_label.text = "最高分: %08d" % high_score
				else:
					score_label.text = "未通关"
			if lock_label != null:
				lock_label.text = ""
		"rank_required":
			button.disabled = true
			button.modulate = RANK_REQUIRED_MODULATE
			if name_label != null:
				name_label.text = "✨ %s" % stage_name
			if score_label != null:
				score_label.text = ""
			if lock_label != null and UnlockManager != null:
				var required_rank: String = UnlockManager.get_hidden_stage_required_rank_name(stage_id)
				lock_label.text = "军衔不足：需要%s" % required_rank
		_:
			button.disabled = true
			button.modulate = LOCKED_MODULATE
			if name_label != null:
				name_label.text = "??? 隐藏"
			if score_label != null:
				score_label.text = ""
			if lock_label != null:
				lock_label.text = "🔒 未发现"

func _is_stage_locked(stage_index: int) -> bool:
	var highest: int = 0
	if SaveManager:
		highest = SaveManager.highest_stage
	return stage_index > highest

func _on_stage_button_pressed(stage_index: int) -> void:
	if not _stage_buttons.has(stage_index):
		return
	var button: Button = _stage_buttons[stage_index] as Button
	if button.disabled:
		return
	_play_button_click_effect(button)
	var stage_info: Dictionary = _stage_data[stage_index]
	var stage_id: String = stage_info.get("stage_id", "")
	GameManager.reset_game()
	GameManager.set_stage(stage_index)
	GameManager.load_stage(stage_id)
	var stage_path: String = LEVEL_SCENE_DIR + "stage_" + stage_id + ".tscn"
	get_tree().change_scene_to_file(stage_path)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func _play_button_click_effect(button: Button) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)