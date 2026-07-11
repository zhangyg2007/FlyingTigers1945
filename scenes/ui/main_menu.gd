extends CanvasLayer
## 主菜单控制器
## 管理主菜单的按钮交互、悬停效果和场景跳转。
##
## 节点结构要求（在场景编辑器中搭建）：
## - TitleLabel (Label)               -- 游戏标题
## - VBoxContainer
##   - StartButton (Button)          -- 开始游戏
##   - StageSelectButton (Button)    -- 关卡选择
##   - SettingsButton (Button)       -- 设置
##   - LeaderboardButton (Button)    -- 排行榜
##   - QuitButton (Button)           -- 退出游戏
## - HighScoreLabel (Label)          -- 最高分显示
## - VersionLabel (Label)            -- 版本号显示

# ============================================================
# 常量
# ============================================================

## 游戏版本号
const GAME_VERSION: String = "v1.0.0"

## 游戏标题
const GAME_TITLE: String = "FLYING TIGERS 1945"

## 场景路径常量
const SCENE_STAGE_SELECT: String = "res://scenes/ui/stage_select.tscn"
const SCENE_LEADERBOARD: String = "res://scenes/ui/leaderboard.tscn"
const SCENE_SETTINGS: String = "res://scenes/ui/settings_menu.tscn"
const SCENE_FIRST_STAGE: String = "res://levels/stage_01_kunming.tscn"

# ============================================================
# 节点引用
# ============================================================

## 游戏标题标签 -- 节点路径: $TitleLabel
@onready var title_label: Label = %TitleLabel

## 开始游戏按钮 -- 节点路径: $VBoxContainer/StartButton
@onready var start_button: Button = %StartButton

## 关卡选择按钮 -- 节点路径: $VBoxContainer/StageSelectButton
@onready var stage_select_button: Button = %StageSelectButton

## 设置按钮 -- 节点路径: $VBoxContainer/SettingsButton
@onready var settings_button: Button = %SettingsButton

## 排行榜按钮 -- 节点路径: $VBoxContainer/LeaderboardButton
@onready var leaderboard_button: Button = %LeaderboardButton

## 退出游戏按钮 -- 节点路径: $VBoxContainer/QuitButton
@onready var quit_button: Button = %QuitButton

## 最高分标签 -- 节点路径: $HighScoreLabel
@onready var high_score_label: Label = %HighScoreLabel

## 版本号标签 -- 节点路径: $VersionLabel
@onready var version_label: Label = %VersionLabel

# ============================================================
# 内部变量
# ============================================================

## 按钮悬停效果动画持续时间（秒）
const HOVER_TWEEN_DURATION: float = 0.15

## 按钮正常缩放
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)

## 按钮悬停缩放
const HOVER_SCALE: Vector2 = Vector2(1.05, 1.05)

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化标题、版本号、最高分，连接所有按钮信号
	title_label.text = GAME_TITLE
	version_label.text = GAME_VERSION
	_update_high_score_display()

	# 连接按钮信号
	start_button.pressed.connect(_on_start_button_pressed)
	stage_select_button.pressed.connect(_on_stage_select_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	# 连接按钮悬停效果信号
	_connect_hover_effects()

	# 设置游戏状态为主菜单
	GameManager.set_state(GameManager.State.MENU)

	# 设置焦点到开始按钮
	start_button.grab_focus()


func _input(event: InputEvent) -> void:
	## 全局输入处理（主菜单层级）
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			# 如果焦点不在退出按钮上，给退出按钮焦点
			if not quit_button.has_focus():
				quit_button.grab_focus()

# ============================================================
# 数据显示
# ============================================================

func _update_high_score_display() -> void:
	## 从 SaveManager 读取最高分并更新显示
	var high_score: int = 0
	if SaveManager:
		high_score = SaveManager.total_score
	if high_score_label != null:
		high_score_label.text = "最高分: %08d" % high_score

# ============================================================
# 按钮回调
# ============================================================

func _on_start_button_pressed() -> void:
	## 开始游戏按钮回调：重置游戏状态并加载第1关场景
	_play_button_click_effect(start_button)
	_start_game_stage(0)


func _on_stage_select_button_pressed() -> void:
	## 关卡选择按钮回调：加载关卡选择场景
	_play_button_click_effect(stage_select_button)
	get_tree().change_scene_to_file(SCENE_STAGE_SELECT)


func _on_settings_button_pressed() -> void:
	## 设置按钮回调：加载设置场景
	_play_button_click_effect(settings_button)
	get_tree().change_scene_to_file(SCENE_SETTINGS)


func _on_leaderboard_button_pressed() -> void:
	## 排行榜按钮回调：加载排行榜场景
	_play_button_click_effect(leaderboard_button)
	get_tree().change_scene_to_file(SCENE_LEADERBOARD)


func _on_quit_button_pressed() -> void:
	## 退出游戏按钮回调
	_play_button_click_effect(quit_button)

	# 使用延迟退出，让点击效果播放完
	var tween := create_tween()
	tween.tween_callback(get_tree().quit).set_delay(0.2)

# ============================================================
# 悬停效果
# ============================================================

func _connect_hover_effects() -> void:
	## 为所有按钮连接悬停/离开效果的信号
	var buttons: Array[Button] = [
		start_button,
		stage_select_button,
		settings_button,
		leaderboard_button,
		quit_button,
	]

	for button in buttons:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.focus_entered.connect(_on_button_hovered.bind(button))
		button.focus_exited.connect(_on_button_unhovered.bind(button))


func _on_button_hovered(button: Button) -> void:
	## 按钮悬停/获取焦点时放大效果
	_play_scale_tween(button, HOVER_SCALE)


func _on_button_unhovered(button: Button) -> void:
	## 按钮离开/失去焦点时恢复正常
	_play_scale_tween(button, NORMAL_SCALE)

# ============================================================
# 场景跳转
# ============================================================

func _start_game_stage(stage_index: int) -> void:
	## 重置游戏状态并加载指定关卡
	GameManager.reset_game()
	GameManager.set_stage(stage_index)

	# 根据关卡索引构建场景路径
	var stage_path: String = _get_stage_scene_path(stage_index)
	get_tree().change_scene_to_file(stage_path)


func _get_stage_scene_path(stage_index: int) -> String:
	## 根据关卡索引返回场景路径
	## 关卡场景位于 res://levels/ 目录下
	match stage_index:
		0:
			return "res://levels/stage_01_kunming.tscn"
		_:
			# 通用路径格式（按关卡索引映射 stage_config.json 中的 stage_id）
			var all_ids: Array[String] = GameManager.get_all_stage_ids()
			if stage_index < all_ids.size():
				return "res://levels/stage_%s.tscn" % all_ids[stage_index]
			return "res://levels/stage_01_kunming.tscn"

# ============================================================
# 动画效果
# ============================================================

func _play_scale_tween(button: Button, target_scale: Vector2) -> void:
	## 播放按钮缩放Tween动画
	var tween: Tween = button.get_tree().create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, HOVER_TWEEN_DURATION)


func _play_button_click_effect(button: Button) -> void:
	## 播放按钮点击缩放效果（先缩小再恢复）
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", NORMAL_SCALE, 0.1)
