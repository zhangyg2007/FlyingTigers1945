extends CanvasLayer
## 设置界面
## 提供音量滑块（主音量/BGM/SFX）和难度选择（Easy/Hard）。
## 返回时保存设置到 SaveManager.save_settings()，并同步到 AudioManager。
##
## 节点结构要求（在场景编辑器中搭建）：
## - Background (ColorRect)              -- 半透明背景
## - TitleLabel (Label)                  -- "设置" 标题
## - SettingsContainer (VBoxContainer)   -- 设置项容器
##   - MasterVolumeRow (HBoxContainer)   -- 主音量行
##   - BGMVolumeRow (HBoxContainer)      -- BGM音量行
##   - SFXVolumeRow (HBoxContainer)      -- SFX音量行
##   - DifficultyRow (HBoxContainer)     -- 难度选择行
## - BackButton (Button)                 -- 返回按钮

# ============================================================
# 常量
# ============================================================

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

## 设置场景路径（供暂停菜单叠加调用）
const SCENE_SETTINGS: String = "res://scenes/ui/settings_menu.tscn"

# ============================================================
# 导出参数
# ============================================================

## 是否在返回时切换到主菜单场景
## true=独立场景模式（从主菜单进入），返回时切换到主菜单
## false=叠加层模式（从暂停菜单进入），返回时仅移除自身
@export var return_to_main_menu: bool = true

# ============================================================
# 节点引用
# ============================================================

## 主音量滑块 -- 节点路径: %MasterVolumeSlider
@onready var master_volume_slider: HSlider = %MasterVolumeSlider

## BGM音量滑块 -- 节点路径: %BGMVolumeSlider
@onready var bgm_volume_slider: HSlider = %BGMVolumeSlider

## SFX音量滑块 -- 节点路径: %SFXVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider

## 简单难度按钮 -- 节点路径: %EasyButton
@onready var easy_button: Button = %EasyButton

## 困难难度按钮 -- 节点路径: %HardButton
@onready var hard_button: Button = %HardButton

## 返回按钮 -- 节点路径: %BackButton
@onready var back_button: Button = %BackButton

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化：从 SaveManager/GameManager 读取当前设置，连接信号
	_load_current_settings()

	# 连接滑块信号
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	bgm_volume_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	# 连接难度按钮信号
	easy_button.pressed.connect(_on_easy_button_pressed)
	hard_button.pressed.connect(_on_hard_button_pressed)

	# 连接返回按钮信号
	back_button.pressed.connect(_on_back_button_pressed)

	# 设置焦点到返回按钮
	back_button.grab_focus()


func _input(event: InputEvent) -> void:
	## 全局输入处理：ESC 返回
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_back_button_pressed()

# ============================================================
# 初始化
# ============================================================

func _load_current_settings() -> void:
	## 从 SaveManager 和 GameManager 读取当前设置值
	# 读取音量设置
	var settings: Dictionary = {}
	if SaveManager:
		settings = SaveManager.get_settings()

	master_volume_slider.value = settings.get("master_volume", 1.0)
	bgm_volume_slider.value = settings.get("bgm_volume", 0.7)
	sfx_volume_slider.value = settings.get("sfx_volume", 0.8)

	# 读取难度设置
	_update_difficulty_buttons()

# ============================================================
# 信号回调
# ============================================================

func _on_master_volume_changed(value: float) -> void:
	## 主音量滑块变化回调：实时更新 AudioManager
	if AudioManager:
		AudioManager.master_volume = value


func _on_bgm_volume_changed(value: float) -> void:
	## BGM音量滑块变化回调：实时更新 AudioManager
	if AudioManager:
		AudioManager.bgm_volume = value


func _on_sfx_volume_changed(value: float) -> void:
	## SFX音量滑块变化回调：实时更新 AudioManager
	if AudioManager:
		AudioManager.sfx_volume = value


func _on_easy_button_pressed() -> void:
	## 简单难度按钮回调
	GameManager.difficulty = GameManager.Difficulty.EASY
	_update_difficulty_buttons()


func _on_hard_button_pressed() -> void:
	## 困难难度按钮回调
	GameManager.difficulty = GameManager.Difficulty.HARD
	_update_difficulty_buttons()


func _on_back_button_pressed() -> void:
	## 返回按钮回调：保存设置并返回上级菜单
	_save_settings()
	if return_to_main_menu:
		get_tree().change_scene_to_file(SCENE_MAIN_MENU)
	else:
		# 叠加层模式：仅移除自身，返回暂停菜单
		queue_free()

# ============================================================
# 内部方法
# ============================================================

func _update_difficulty_buttons() -> void:
	## 根据当前难度更新按钮视觉状态
	var is_easy: bool = GameManager.difficulty == GameManager.Difficulty.EASY
	easy_button.disabled = is_easy  # 当前选中的禁用（表示已选中）
	hard_button.disabled = not is_easy

	# 视觉区分：选中项高亮
	if is_easy:
		easy_button.modulate = Color(1.0, 0.85, 0.2, 1.0)
		hard_button.modulate = Color.WHITE
	else:
		easy_button.modulate = Color.WHITE
		hard_button.modulate = Color(1.0, 0.4, 0.4, 1.0)


func _save_settings() -> void:
	## 保存音量设置到 SaveManager
	var master_vol: float = master_volume_slider.value
	var bgm_vol: float = bgm_volume_slider.value
	var sfx_vol: float = sfx_volume_slider.value

	if SaveManager:
		SaveManager.save_settings(master_vol, bgm_vol, sfx_vol)
