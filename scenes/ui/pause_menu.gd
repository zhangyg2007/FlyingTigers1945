extends CanvasLayer
## 暂停菜单
## 游戏进行中按Esc/P键弹出的暂停菜单，提供继续游戏、重新开始、返回主菜单选项。
## 使用 PROCESS_MODE_ALWAYS 确保暂停状态下仍可交互。
##
## 节点结构要求（在场景编辑器中搭建）：
## - PausePanel (Panel/PanelContainer)  -- 暂停面板背景
##   - TitleLabel (Label)               -- "暂停" 标题
##   - VBoxContainer
##     - ResumeButton (Button)          -- 继续游戏
##     - RestartButton (Button)         -- 重新开始
##     - MenuButton (Button)            -- 返回主菜单
## - BackgroundOverlay (ColorRect)     -- 半透明黑色背景遮罩

# ============================================================
# 常量
# ============================================================

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

## 暂停切换输入动作名称（需与project.godot中的input map一致）
const PAUSE_INPUT_ACTION: String = "pause"

# ============================================================
# 节点引用
# ============================================================

## 继续游戏按钮 -- 节点路径: $PausePanel/VBoxContainer/ResumeButton
@onready var resume_button: Button = %ResumeButton

## 重新开始按钮 -- 节点路径: $PausePanel/VBoxContainer/RestartButton
@onready var restart_button: Button = %RestartButton

## 返回主菜单按钮 -- 节点路径: $PausePanel/VBoxContainer/MenuButton
@onready var menu_button: Button = %MenuButton

## 半透明背景遮罩 -- 节点路径: $BackgroundOverlay
@onready var background_overlay: ColorRect = %BackgroundOverlay

## 暂停面板 -- 节点路径: $PausePanel
@onready var pause_panel: PanelContainer = %PausePanel

# ============================================================
# 内部变量
# ============================================================

## 菜单是否正在显示
var _is_showing: bool = false

## 面板动画是否正在播放
var _is_animating: bool = false

## 背景遮罩目标透明度
const OVERLAY_ALPHA_HIDDEN: float = 0.0
const OVERLAY_ALPHA_SHOWN: float = 0.5

## 动画持续时间
const ANIM_DURATION: float = 0.2

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化：默认隐藏，设置处理模式，连接信号
	# 设置处理模式为ALWAYS，确保暂停时仍可交互
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 默认隐藏
	visible = false
	_set_overlay_alpha(OVERLAY_ALPHA_HIDDEN)
	pause_panel.modulate.a = 0.0

	# 连接按钮信号
	resume_button.pressed.connect(_on_resume_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	# 连接悬停效果信号
	_connect_hover_effects()

	# 尝试连接GameManager的状态变化信号（安全检查）
	# 需要GameManager扩展: signal state_changed(new_state)
	if GameManager.has_signal("state_changed"):
		GameManager.state_changed.connect(_on_game_state_changed)


func _input(event: InputEvent) -> void:
	## 全局输入处理：Esc/P键切换暂停菜单
	if _is_animating:
		return

	# 检查是否按下了暂停键（Esc或P键）
	var is_pause_action: bool = false

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			# Esc键或P键
			if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
				is_pause_action = true
	elif event is InputEventAction:
		var action_event: InputEventAction = event as InputEventAction
		if action_event.action == PAUSE_INPUT_ACTION and action_event.pressed:
			is_pause_action = true

	if is_pause_action:
		# 仅在PLAYING状态下才响应暂停键
		if GameManager.game_state == GameManager.State.PLAYING:
			if _is_showing:
				_hide_pause_menu()
			else:
				_show_pause_menu()
		elif GameManager.game_state == GameManager.State.PAUSED and _is_showing:
			_hide_pause_menu()

# ============================================================
# 游戏状态回调
# ============================================================

func _on_game_state_changed(new_state: int) -> void:
	## 游戏状态变化回调
	## 当外部强制恢复游戏时，自动隐藏暂停菜单
	match new_state:
		GameManager.State.PLAYING:
			if _is_showing:
				_hide_pause_menu()
		GameManager.State.MENU, GameManager.State.GAME_OVER:
			if _is_showing:
				# 不播放动画，直接隐藏
				visible = false
				_is_showing = false

# ============================================================
# 显示/隐藏
# ============================================================

func _show_pause_menu() -> void:
	## 显示暂停菜单（带动画）
	_is_animating = true
	_is_showing = true
	visible = true

	# 暂停游戏
	GameManager.set_state(GameManager.State.PAUSED)

	# 动画：背景遮罩渐入
	var tween := create_tween()
	tween.set_parallel(true)

	# 遮罩渐入
	tween.tween_method(_set_overlay_alpha, OVERLAY_ALPHA_HIDDEN, OVERLAY_ALPHA_SHOWN, ANIM_DURATION)

	# 面板从上方滑入 + 渐入
	pause_panel.position = Vector2(pause_panel.position.x, -50.0)
	pause_panel.modulate.a = 0.0
	tween.tween_property(pause_panel, "position:y", 0.0, ANIM_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_panel, "modulate:a", 1.0, ANIM_DURATION)

	tween.set_parallel(false)
	tween.tween_callback(func():
		_is_animating = false
		resume_button.grab_focus()
	)


func _hide_pause_menu() -> void:
	## 隐藏暂停菜单（带动画）
	_is_animating = true

	# 动画：背景遮罩渐出
	var tween := create_tween()
	tween.set_parallel(true)

	# 遮罩渐出
	tween.tween_method(_set_overlay_alpha, OVERLAY_ALPHA_SHOWN, OVERLAY_ALPHA_HIDDEN, ANIM_DURATION)

	# 面板向上滑出 + 渐出
	tween.tween_property(pause_panel, "position:y", -50.0, ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(pause_panel, "modulate:a", 0.0, ANIM_DURATION)

	tween.set_parallel(false)
	tween.tween_callback(func():
		_is_showing = false
		_is_animating = false
		visible = false
	)

	# 恢复游戏
	GameManager.set_state(GameManager.State.PLAYING)


func _set_overlay_alpha(alpha: float) -> void:
	## 设置背景遮罩透明度
	var color: Color = background_overlay.color
	color.a = alpha
	background_overlay.color = color

# ============================================================
# 按钮回调
# ============================================================

func _on_resume_button_pressed() -> void:
	## 继续游戏按钮回调
	if _is_animating:
		return
	_play_button_click_effect(resume_button)
	_hide_pause_menu()


func _on_restart_button_pressed() -> void:
	## 重新开始按钮回调
	if _is_animating:
		return
	_play_button_click_effect(restart_button)

	# 直接重新加载当前场景（不经过恢复流程）
	_is_showing = false
	_is_animating = false
	get_tree().paused = false  # 先取消暂停才能重新加载
	get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	## 返回主菜单按钮回调
	if _is_animating:
		return
	_play_button_click_effect(menu_button)

	# 重置游戏状态
	_is_showing = false
	_is_animating = false
	get_tree().paused = false  # 先取消暂停才能切换场景
	GameManager.reset_game()
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

# ============================================================
# 悬停效果
# ============================================================

func _connect_hover_effects() -> void:
	## 为所有按钮连接悬停效果
	var buttons: Array[Button] = [resume_button, restart_button, menu_button]
	for button in buttons:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.focus_entered.connect(_on_button_hovered.bind(button))
		button.focus_exited.connect(_on_button_unhovered.bind(button))


func _on_button_hovered(button: Button) -> void:
	## 按钮悬停效果
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)


func _on_button_unhovered(button: Button) -> void:
	## 按钮离开效果
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)

# ============================================================
# 动画效果
# ============================================================

func _play_button_click_effect(button: Button) -> void:
	## 按钮点击缩放效果
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
