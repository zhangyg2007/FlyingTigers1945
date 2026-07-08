extends CanvasLayer
## 主菜单控制器
## 管理主菜单的按钮交互、悬停效果和场景跳转。
##
## 节点结构要求（在场景编辑器中搭建）：
## - VBoxContainer
##   - StartButton (Button)          -- 开始游戏
##   - StageSelectButton (Button)    -- 关卡选择
##   - AbyssButton (Button)          -- 深渊模式
##   - SettingsButton (Button)       -- 设置
##   - QuitButton (Button)           -- 退出游戏
## - VersionLabel (Label)            -- 版本号显示

# ============================================================
# 常量
# ============================================================

## 游戏版本号
const GAME_VERSION: String = "v1.0.0"

## 场景路径常量
const SCENE_STAGE_SELECT: String = "res://scenes/ui/stage_select.tscn"
const SCENE_ABYSS: String = "res://scenes/levels/abyss.tscn"
const SCENE_SETTINGS: String = "res://scenes/ui/settings.tscn"
const SCENE_FIRST_STAGE: String = "res://scenes/levels/stage_01_kunming.tscn"

# ============================================================
# 节点引用
# ============================================================

## 开始游戏按钮 -- 节点路径: $VBoxContainer/StartButton
@onready var start_button: Button = %StartButton

## 关卡选择按钮 -- 节点路径: $VBoxContainer/StageSelectButton
@onready var stage_select_button: Button = %StageSelectButton

## 深渊模式按钮 -- 节点路径: $VBoxContainer/AbyssButton
@onready var abyss_button: Button = %AbyssButton

## 设置按钮 -- 节点路径: $VBoxContainer/SettingsButton
@onready var settings_button: Button = %SettingsButton

## 退出游戏按钮 -- 节点路径: $VBoxContainer/QuitButton
@onready var quit_button: Button = %QuitButton

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
	## 初始化版本号，连接所有按钮信号
	version_label.text = GAME_VERSION

	# 连接按钮信号
	start_button.pressed.connect(_on_start_button_pressed)
	stage_select_button.pressed.connect(_on_stage_select_button_pressed)
	abyss_button.pressed.connect(_on_abyss_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	# 连接按钮悬停效果信号
	_connect_hover_effects()

	# 设置游戏状态为主菜单
	GameManager.set_state(GameManager.State.MENU)

	# 设置焦点到开始按钮
	start_button.grab_focus()


func _input(event: InputEvent) -> void:
	## 全局输入处理（主菜单层级）
	# 在主菜单状态下按Esc退出确认（可选功能）
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			# 如果焦点不在退出按钮上，给退出按钮焦点
			if not quit_button.has_focus():
				quit_button.grab_focus()

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


func _on_abyss_button_pressed() -> void:
	## 深渊模式按钮回调：加载深渊模式场景
	_play_button_click_effect(abyss_button)
	_start_abyss_mode()


func _on_settings_button_pressed() -> void:
	## 设置按钮回调：加载设置场景
	_play_button_click_effect(settings_button)
	get_tree().change_scene_to_file(SCENE_SETTINGS)


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
		abyss_button,
		settings_button,
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


func _start_abyss_mode() -> void:
	## 启动深渊模式
	GameManager.reset_game()
	get_tree().change_scene_to_file(SCENE_ABYSS)


func _get_stage_scene_path(stage_index: int) -> String:
	## 根据关卡索引返回场景路径
	## 默认使用第一关路径，实际项目中应根据关卡索引映射
	# TODO: 根据SaveManager中的关卡配置动态获取路径
	match stage_index:
		0:
			return "res://scenes/levels/stage_01_kunming.tscn"
		_:
			# 通用路径格式
			return "res://scenes/levels/stage_%02d.tscn" % (stage_index + 1)

# ============================================================
# 动画效果
# ============================================================

func _play_scale_tween(button: Button, target_scale: Vector2) -> void:
	## 播放按钮缩放Tween动画
	# 停止之前可能存在的动画
	var tween: Tween = button.get_tree().create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, HOVER_TWEEN_DURATION)


func _play_button_click_effect(button: Button) -> void:
	## 播放按钮点击缩放效果（先缩小再恢复）
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", NORMAL_SCALE, 0.1)
