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
# v1.5: 情报提示 / 友军保护 / Combo 显示（动态创建 UI）
# ============================================================

## 情报拾取提示标签（屏幕中上方，临时显示后淡出）
var _intel_alert_label: Label = null

## 通用事件提示标签（友军损失 / 失败提示等）
var _event_alert_label: Label = null

## 友军保护进度容器（Label + ProgressBar）
var _ally_protect_container: VBoxContainer = null
var _ally_protect_bar: ProgressBar = null
var _ally_protect_label: Label = null

## v1.5 C17: 护送 C-47 运输机 UI（存活计数显示）
var _escort_container: VBoxContainer = null
var _escort_label: Label = null

## Combo 显示容器（Label + ProgressBar）
var _combo_container: VBoxContainer = null
var _combo_label: Label = null
var _combo_bar: ProgressBar = null

## Combo 提示动画引用
var _combo_alert_tween: Tween = null
## v1.5: Combo 中断淡出动画引用（避免与 _on_combo_changed 冲突）
var _combo_break_tween: Tween = null

## v1.5: 各提示标签的 tween 引用（避免重复创建）
var _intel_alert_tween: Tween = null
var _event_alert_tween: Tween = null

## 友军保护事件剩余时间（由 EventManager 信号更新）
var _ally_protect_duration: float = 0.0
var _ally_protect_elapsed: float = 0.0
var _ally_protect_active: bool = false

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

	# v1.5: 创建情报/友军保护/Combo UI 并连接信号
	_create_v15_ui()
	_connect_v15_signals()


func _process(delta: float) -> void:
	## 蓄力条满时的闪烁效果处理
	if _charge_is_full and charge_bar.visible:
		_flash_visible = !_flash_visible
		charge_bar.modulate.a = 1.0 if _flash_visible else 0.4

	# v1.5: 更新 Combo 进度条（倒计时）
	if _combo_container != null and _combo_container.visible and ComboManager != null:
		_combo_bar.value = ComboManager.get_combo_progress()

	# v1.5: 更新友军保护进度条（倒计时）
	if _ally_protect_active and _ally_protect_bar != null:
		_ally_protect_elapsed += delta
		var remaining: float = maxf(0.0, _ally_protect_duration - _ally_protect_elapsed)
		_ally_protect_bar.value = remaining
		if remaining <= 0.0:
			_ally_protect_active = false
			_ally_protect_container.visible = false

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


# ============================================================
# v1.5: 情报 / 友军保护 / Combo UI
# ============================================================

## 动态创建 v1.5 新增 UI 元素（情报提示、事件提示、友军保护进度、Combo 显示）
## 不修改 hud.tscn，全部用代码构建，保持场景文件简洁
func _create_v15_ui() -> void:
	# 情报拾取提示（屏幕中上方，临时显示）
	_intel_alert_label = Label.new()
	_intel_alert_label.name = "IntelAlertLabel"
	_intel_alert_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_intel_alert_label.position = Vector2(-200, 120)
	_intel_alert_label.size = Vector2(400, 50)
	_intel_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intel_alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intel_alert_label.add_theme_font_size_override("font_size", 22)
	_intel_alert_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	_intel_alert_label.modulate.a = 0.0
	_intel_alert_label.text = ""
	add_child(_intel_alert_label)

	# 通用事件提示（屏幕中下方，友军损失/失败提示）
	_event_alert_label = Label.new()
	_event_alert_label.name = "EventAlertLabel"
	_event_alert_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_event_alert_label.position = Vector2(-200, -180)
	_event_alert_label.size = Vector2(400, 40)
	_event_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_event_alert_label.add_theme_font_size_override("font_size", 18)
	_event_alert_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	_event_alert_label.modulate.a = 0.0
	_event_alert_label.text = ""
	add_child(_event_alert_label)

	# 友军保护进度容器（屏幕右下方）
	_ally_protect_container = VBoxContainer.new()
	_ally_protect_container.name = "AllyProtectContainer"
	_ally_protect_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ally_protect_container.position = Vector2(-260, -120)
	_ally_protect_container.size = Vector2(240, 60)
	_ally_protect_container.visible = false
	add_child(_ally_protect_container)

	_ally_protect_label = Label.new()
	_ally_protect_label.name = "AllyProtectLabel"
	_ally_protect_label.text = "友军保护"
	_ally_protect_label.add_theme_font_size_override("font_size", 14)
	_ally_protect_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
	_ally_protect_container.add_child(_ally_protect_label)

	_ally_protect_bar = ProgressBar.new()
	_ally_protect_bar.name = "AllyProtectBar"
	_ally_protect_bar.min_value = 0.0
	_ally_protect_bar.max_value = 100.0
	_ally_protect_bar.value = 100.0
	_ally_protect_bar.custom_minimum_size = Vector2(240, 16)
	_ally_protect_container.add_child(_ally_protect_bar)

	# v1.5 C17: 护送 C-47 运输机存活计数（屏幕右上方）
	_escort_container = VBoxContainer.new()
	_escort_container.name = "EscortContainer"
	_escort_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_escort_container.position = Vector2(-260, 80)
	_escort_container.size = Vector2(240, 40)
	_escort_container.visible = false
	add_child(_escort_container)

	_escort_label = Label.new()
	_escort_label.name = "EscortLabel"
	_escort_label.text = "护送C-47: 0/0"
	_escort_label.add_theme_font_size_override("font_size", 16)
	_escort_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 1))
	_escort_container.add_child(_escort_label)

	# Combo 显示容器（屏幕左下方）
	_combo_container = VBoxContainer.new()
	_combo_container.name = "ComboContainer"
	_combo_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_combo_container.position = Vector2(20, -120)
	_combo_container.size = Vector2(200, 60)
	_combo_container.visible = false
	add_child(_combo_container)

	_combo_label = Label.new()
	_combo_label.name = "ComboLabel"
	_combo_label.text = "COMBO x0"
	_combo_label.add_theme_font_size_override("font_size", 18)
	_combo_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	_combo_container.add_child(_combo_label)

	_combo_bar = ProgressBar.new()
	_combo_bar.name = "ComboBar"
	_combo_bar.min_value = 0.0
	_combo_bar.max_value = 1.0
	_combo_bar.value = 0.0
	_combo_bar.custom_minimum_size = Vector2(200, 12)
	_combo_container.add_child(_combo_bar)


## 连接 v1.5 新增信号（GameManager.intel_collected / event_alert，ComboManager 信号）
func _connect_v15_signals() -> void:
	# GameManager 情报收集信号
	if GameManager.has_signal("intel_collected"):
		GameManager.intel_collected.connect(_on_intel_collected)

	# GameManager 事件提示信号（友军损失/失败等通用提示）
	if GameManager.has_signal("event_alert"):
		GameManager.event_alert.connect(_on_event_alert)

	# ComboManager 信号（通过 autoload 单例访问）
	if ComboManager != null:
		if ComboManager.has_signal("combo_changed"):
			ComboManager.combo_changed.connect(_on_combo_changed)
		if ComboManager.has_signal("combo_broken"):
			ComboManager.combo_broken.connect(_on_combo_broken)
		if ComboManager.has_signal("combo_milestone"):
			ComboManager.combo_milestone.connect(_on_combo_milestone)


# ============================================================
# v1.5 信号回调
# ============================================================

## 情报已收集回调：显示情报名称提示（2 秒后淡出）
func _on_intel_collected(intel_id: String, display_name: String) -> void:
	if _intel_alert_label == null:
		return
	_intel_alert_label.text = "★ 情报获取：%s" % display_name
	_intel_alert_label.modulate.a = 1.0

	# 复用 tween 引用，避免重复创建导致动画异常
	if _intel_alert_tween != null and _intel_alert_tween.is_valid():
		_intel_alert_tween.kill()
	_intel_alert_tween = create_tween()
	_intel_alert_tween.tween_interval(2.0)
	_intel_alert_tween.tween_property(_intel_alert_label, "modulate:a", 0.0, 0.8)
	print("[HUD] 情报提示: %s (%s)" % [display_name, intel_id])


## 通用事件提示回调（友军损失/失败等）
func _on_event_alert(text: String) -> void:
	if _event_alert_label == null:
		return
	_event_alert_label.text = text
	_event_alert_label.modulate.a = 1.0

	if _event_alert_tween != null and _event_alert_tween.is_valid():
		_event_alert_tween.kill()
	_event_alert_tween = create_tween()
	_event_alert_tween.tween_interval(2.5)
	_event_alert_tween.tween_property(_event_alert_label, "modulate:a", 0.0, 0.8)


## Combo 数变化回调：显示 Combo 容器并更新标签
func _on_combo_changed(combo_count: int, _bonus_score: int) -> void:
	if _combo_container == null:
		return
	# v1.5 修复：新 combo 开始时 kill 中断 tween 并重置 modulate.a，避免中断动画进行中新 combo 不可见
	if _combo_break_tween != null and _combo_break_tween.is_valid():
		_combo_break_tween.kill()
		_combo_container.modulate.a = 1.0
	_combo_container.visible = combo_count > 0
	_combo_label.text = "COMBO x%d" % combo_count

	# 数字跳动效果
	if _combo_alert_tween != null and _combo_alert_tween.is_valid():
		_combo_alert_tween.kill()
	_combo_alert_tween = create_tween()
	_combo_alert_tween.tween_property(_combo_label, "scale", Vector2(1.2, 1.2), 0.08)
	_combo_alert_tween.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.12)


## Combo 中断回调：隐藏 Combo 容器
func _on_combo_broken(_final_count: int) -> void:
	if _combo_container == null:
		return
	# v1.5 修复：复用 _combo_break_tween，避免快速中断时多个 tween 冲突
	if _combo_break_tween != null and _combo_break_tween.is_valid():
		_combo_break_tween.kill()
	_combo_break_tween = create_tween()
	_combo_break_tween.tween_interval(0.5)
	_combo_break_tween.tween_property(_combo_container, "modulate:a", 0.0, 0.3)
	_combo_break_tween.tween_callback(func():
		_combo_container.visible = false
		_combo_container.modulate.a = 1.0
	)


## Combo 里程碑奖励回调：显示奖励提示
func _on_combo_milestone(milestone: int, bonus_score: int) -> void:
	if _event_alert_label == null:
		return
	_event_alert_label.text = "%d 连击！+ %d 分" % [milestone, bonus_score]
	_event_alert_label.modulate.a = 1.0

	# v1.5 修复：复用 _event_alert_tween，避免与 _on_event_alert 的 tween 冲突
	if _event_alert_tween != null and _event_alert_tween.is_valid():
		_event_alert_tween.kill()
	_event_alert_tween = create_tween()
	_event_alert_tween.tween_interval(1.5)
	_event_alert_tween.tween_property(_event_alert_label, "modulate:a", 0.0, 0.6)


# ============================================================
# v1.5 公开接口（供 EventManager 调用）
# ============================================================

## 开始显示友军保护进度条
## [param duration]: 保护持续总时间（秒）
## [param label_text]: 显示标签（如 "友军保护: 机枪阵地"）
func show_ally_protect_progress(duration: float, label_text: String = "友军保护") -> void:
	if _ally_protect_container == null:
		return
	_ally_protect_duration = duration
	_ally_protect_elapsed = 0.0
	_ally_protect_active = true
	_ally_protect_bar.max_value = duration
	_ally_protect_bar.value = duration
	_ally_protect_label.text = label_text
	_ally_protect_container.visible = true
	_ally_protect_container.modulate.a = 1.0


## 隐藏友军保护进度条
func hide_ally_protect_progress() -> void:
	_ally_protect_active = false
	if _ally_protect_container != null:
		_ally_protect_container.visible = false


# ============================================================
# v1.5 C17: 护送 C-47 运输机 UI 接口（供 LevelBase 调用）
# ============================================================

## 显示护送进度（初始存活数量）
## [param initial_count]: 编队总数
func show_escort_progress(initial_count: int) -> void:
	if _escort_container == null:
		return
	_escort_label.text = "护送C-47: %d/%d" % [initial_count, initial_count]
	_escort_container.visible = true
	_escort_container.modulate.a = 1.0


## 更新护送存活计数
## [param alive_count]: 当前存活数量
## [param initial_count]: 编队总数
func update_escort_count(alive_count: int, initial_count: int) -> void:
	if _escort_label == null:
		return
	_escort_label.text = "护送C-47: %d/%d" % [alive_count, initial_count]
	# 存活数低时变红警示
	if alive_count <= 1:
		_escort_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	else:
		_escort_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 1))


## 隐藏护送进度
func hide_escort_progress() -> void:
	if _escort_container != null:
		_escort_container.visible = false
