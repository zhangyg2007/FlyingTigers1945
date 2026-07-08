extends CanvasLayer
## HUD控制器
## 显示分数、生命、炸弹、Power等级、蓄力条、BOSS血条等游戏状态信息。
## 通过信号与GameManager解耦通信，实时更新所有HUD元素。
##
## 节点结构要求（在场景编辑器中搭建）：
## - ScoreLabel (Label)             -- 分数显示
## - LivesContainer (HBoxContainer) -- 生命图标容器，内含多个TextureRect
## - BombsContainer (HBoxContainer) -- 炸弹图标容器，内含多个TextureRect
## - PowerBar (ProgressBar)        -- Power等级条
## - ChargeBar (TextureProgressBar)-- 蓄力条
## - BossHPBar (TextureProgressBar) -- BOSS血条（默认隐藏）
## - BossHPLabel (Label)            -- BOSS名称标签

# ============================================================
# 节点引用
# ============================================================

## 分数标签 -- 节点路径: $ScoreLabel
@onready var score_label: Label = %ScoreLabel

## 生命图标容器 -- 节点路径: $LivesContainer
@onready var lives_container: HBoxContainer = %LivesContainer

## 炸弹图标容器 -- 节点路径: $BombsContainer
@onready var bombs_container: HBoxContainer = %BombsContainer

## Power等级条 -- 节点路径: $PowerBar
@onready var power_bar: ProgressBar = %PowerBar

## 蓄力条 -- 节点路径: $ChargeBar
@onready var charge_bar: TextureProgressBar = %ChargeBar

## BOSS血条 -- 节点路径: $BossHPBar
@onready var boss_hp_bar: TextureProgressBar = %BossHPBar

## BOSS名称标签 -- 节点路径: $BossHPLabel
@onready var boss_hp_label: Label = %BossHPLabel

# ============================================================
# 内部变量
# ============================================================

## 蓄力条闪烁动画引用
var _charge_flash_tween: Tween = null

## 蓄力条是否已满
var _charge_is_full: bool = false

## 蓄力条闪烁状态
var _flash_visible: bool = true

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化：隐藏BOSS血条，设置初始值，连接GameManager信号
	_hide_boss_hp_ui()

	# 设置Power条初始范围（1~4格）
	power_bar.min_value = 0
	power_bar.max_value = GameManager.MAX_POWER
	power_bar.step = 1

	# 设置蓄力条初始范围
	charge_bar.min_value = 0.0
	charge_bar.max_value = 1.0
	charge_bar.value = 0.0

	# 显示初始数据
	update_score(GameManager.score)
	update_lives(GameManager.lives)
	update_bombs(GameManager.bombs)
	update_power(GameManager.power_level)
	update_charge(0.0)

	# 连接GameManager的已有信号
	GameManager.score_changed.connect(update_score)
	GameManager.lives_changed.connect(update_lives)
	GameManager.bombs_changed.connect(update_bombs)
	GameManager.power_changed.connect(update_power)

	# 连接GameManager可能扩展的信号（安全检查）
	_connect_optional_signals()


func _process(delta: float) -> void:
	## 蓄力条满时的闪烁效果处理
	if _charge_is_full and charge_bar.visible:
		_flash_visible = !_flash_visible
		charge_bar.modulate.a = 1.0 if _flash_visible else 0.4

# ============================================================
# 信号连接（兼容GameManager未来扩展）
# ============================================================

func _connect_optional_signals() -> void:
	## 安全连接GameManager中尚未定义的信号
	## 当GameManager添加这些信号后，无需修改此脚本即可自动工作

	# 蓄力变化信号（需要GameManager扩展: signal charge_changed(progress: float)）
	if GameManager.has_signal("charge_changed"):
		GameManager.charge_changed.connect(update_charge)

	# 游戏状态变化信号（需要GameManager扩展: signal state_changed(new_state)）
	if GameManager.has_signal("state_changed"):
		GameManager.state_changed.connect(_on_game_state_changed)

	# BOSS出场信号（需要GameManager扩展: signal boss_appeared(boss_name, max_hp)）
	if GameManager.has_signal("boss_appeared"):
		GameManager.boss_appeared.connect(show_boss_hp)

	# BOSS血量变化信号（需要GameManager扩展: signal boss_hp_changed(current_hp, max_hp)）
	if GameManager.has_signal("boss_hp_changed"):
		GameManager.boss_hp_changed.connect(update_boss_hp)

	# BOSS被击败信号（需要GameManager扩展: signal boss_defeated()）
	if GameManager.has_signal("boss_defeated"):
		GameManager.boss_defeated.connect(hide_boss_hp)


func _on_game_state_changed(new_state: int) -> void:
	## 游戏状态变化回调，隐藏/显示HUD
	match new_state:
		GameManager.State.PLAYING:
			visible = true
		GameManager.State.PAUSED:
			# 暂停时不隐藏HUD，保持显示
			pass
		_:
			visible = false

# ============================================================
# 公开方法：更新HUD数据
# ============================================================

func update_score(score: int) -> void:
	## 更新分数显示，格式化为8位数字（如 00123450）
	## [param score]: 当前分数
	var formatted: String = "%08d" % score
	score_label.text = formatted


func update_lives(lives: int) -> void:
	## 更新生命图标显示数量
	## [param lives]: 当前生命数
	# 根据生命数显示/隐藏容器中的图标子节点
	for i in range(lives_container.get_child_count()):
		var child: Control = lives_container.get_child(i) as Control
		if child != null:
			child.visible = (i < lives)


func update_bombs(bombs: int) -> void:
	## 更新炸弹图标数量
	## [param bombs]: 当前炸弹数
	for i in range(bombs_container.get_child_count()):
		var child: Control = bombs_container.get_child(i) as Control
		if child != null:
			child.visible = (i < bombs)


func update_power(level: int) -> void:
	## 更新Power等级条，4格逐格点亮
	## [param level]: Power等级（1~4）
	power_bar.value = clampi(level, 0, GameManager.MAX_POWER)


func update_charge(progress: float) -> void:
	## 更新蓄力条填充（0.0~1.0），满时闪烁
	## [param progress]: 蓄力进度（0.0~1.0）
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	charge_bar.value = clamped_progress

	# 检查蓄力条是否已满
	var was_full: bool = _charge_is_full
	_charge_is_full = clamped_progress >= 1.0

	# 刚充满时播放提示效果
	if _charge_is_full and not was_full:
		_play_charge_full_effect()


func show_boss_hp(boss_name: String, max_hp: int) -> void:
	## 显示BOSS血条
	## [param boss_name]: BOSS名称
	## [param max_hp]: BOSS最大血量
	boss_hp_label.text = boss_name
	boss_hp_bar.min_value = 0
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = max_hp
	boss_hp_bar.visible = true
	boss_hp_label.visible = true

	# 血条出场动画
	var tween := create_tween()
	tween.tween_property(boss_hp_bar, "modulate:a", 1.0, 0.3)


func hide_boss_hp() -> void:
	## 隐藏BOSS血条
	_hide_boss_hp_ui()


func update_boss_hp(current_hp: int, max_hp: int) -> void:
	## 更新BOSS血条进度
	## [param current_hp]: BOSS当前血量
	## [param max_hp]: BOSS最大血量
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = current_hp


func pause_game() -> void:
	## 暂停游戏（由PauseMenu调用）
	GameManager.set_state(GameManager.State.PAUSED)


func resume_game() -> void:
	## 恢复游戏（由PauseMenu调用）
	GameManager.set_state(GameManager.State.PLAYING)

# ============================================================
# 内部方法
# ============================================================

func _hide_boss_hp_ui() -> void:
	## 隐藏BOSS血条UI元素
	if boss_hp_bar != null:
		boss_hp_bar.visible = false
	if boss_hp_label != null:
		boss_hp_label.visible = false


func _play_charge_full_effect() -> void:
	## 蓄力条充满时的视觉反馈效果
	# 闪烁动画
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(charge_bar, "modulate:a", 1.0, 0.15)
	tween.tween_property(charge_bar, "modulate:a", 0.3, 0.15)
	# 动画结束后恢复正常
	tween.set_parallel(false)
	tween.tween_property(charge_bar, "modulate:a", 1.0, 0.1)
