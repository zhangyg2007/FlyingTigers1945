extends CanvasLayer
## 结算界面
## 关卡通关或游戏结束后的成绩展示，包含关卡名、用时、分数、击坠数、命中率、评级等信息。
## 根据分数自动判定等级（S/A/B/C），支持跳转下一关、重试和返回主菜单。
##
## 节点结构要求（在场景编辑器中搭建）：
## - StageNameLabel (Label)            -- 关卡名
## - TimeLabel (Label)                 -- 用时
## - ScoreLabel (Label)                -- 最终分数
## - KillCountLabel (Label)            -- 击坠数
## - AccuracyLabel (Label)             -- 命中率
## - RankSprite (TextureRect)          -- 评级奖章图片
##   - RankLabel (Label)               -- 评级文字（S/A/B/C）
## - UnlockHintLabel (Label)           -- 解锁提示（默认隐藏）
## - NextButton (Button)               -- 下一关按钮
## - RetryButton (Button)              -- 重试按钮
## - MenuButton (Button)               -- 返回主菜单按钮

# ============================================================
# 常量
# ============================================================

## 评级分数阈值
const RANK_S_THRESHOLD: int = 1000000  ## 100万: S评级
const RANK_A_THRESHOLD: int = 500000   ## 50万: A评级
const RANK_B_THRESHOLD: int = 200000   ## 20万: B评级
## 其余: C评级

## 评级对应的颜色
const RANK_COLORS: Dictionary = {
	"S": Color(1.0, 0.84, 0.0, 1.0),       # 金色
	"A": Color(0.85, 0.65, 0.13, 1.0),     # 金黄
	"B": Color(0.75, 0.75, 0.75, 1.0),     # 银色
	"C": Color(0.72, 0.45, 0.20, 1.0),     # 铜色
}

## 评级对应的奖章纹理
const MEDAL_TEXTURES: Dictionary = {
	"S": preload("res://assets/sprites/ui/ui_medal_s.png"),
	"A": preload("res://assets/sprites/ui/ui_medal_a.png"),
	"B": preload("res://assets/sprites/ui/ui_medal_b.png"),
	"C": preload("res://assets/sprites/ui/ui_medal_c.png"),
}

## 评级动画出现的延迟时间（秒）
const RANK_APPEAR_DELAY: float = 1.5

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

## 关卡场景目录
const LEVEL_SCENE_DIR: String = "res://levels/"

# ============================================================
# 节点引用
# ============================================================

## 关卡名标签 -- 节点路径: $StageNameLabel
@onready var stage_name_label: Label = %StageNameLabel

## 用时标签 -- 节点路径: $TimeLabel
@onready var time_label: Label = %TimeLabel

## 最终分数标签 -- 节点路径: $ScoreLabel
@onready var score_label: Label = %ScoreLabel

## 击坠数标签 -- 节点路径: $KillCountLabel
@onready var kill_count_label: Label = %KillCountLabel

## 命中率标签 -- 节点路径: $AccuracyLabel
@onready var accuracy_label: Label = %AccuracyLabel

## 评级奖章图片 -- 节点路径: $RankSprite
@onready var rank_sprite: TextureRect = %RankSprite

## 评级文字标签 -- 节点路径: $RankLabel
@onready var rank_label: Label = %RankLabel

## 解锁提示标签 -- 节点路径: $UnlockHintLabel
@onready var unlock_hint_label: Label = %UnlockHintLabel

## 下一关按钮 -- 节点路径: $NextButton
@onready var next_button: Button = %NextButton

## 重试按钮 -- 节点路径: $RetryButton
@onready var retry_button: Button = %RetryButton

## 返回主菜单按钮 -- 节点路径: $MenuButton
@onready var menu_button: Button = %MenuButton

# ============================================================
# 内部变量
# ============================================================

## 本次结算数据
var _result_data: Dictionary = {}

## 评级动画Tween引用
var _rank_tween: Tween = null

## 分数滚动动画Tween引用
var _score_tween: Tween = null

## 最终评级（S/A/B/C）
var _final_rank: String = "C"

## 本次结算对应的关卡场景路径（用于重试）
var _level_scene_path: String = ""

## 保存前的最高关卡（用于检测解锁）
var _prev_highest_stage: int = 0

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化：收集结算数据，连接按钮信号，播放结算动画
	# 收集结算数据
	_collect_result_data()

	# 连接按钮信号
	next_button.pressed.connect(_on_next_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	# 初始隐藏评级和解锁提示，等动画播放
	_set_rank_visible(false)
	next_button.visible = false
	if unlock_hint_label != null:
		unlock_hint_label.visible = false

	# 显示基础数据
	_display_base_data()

	# 延迟播放评级出现动画
	_play_rank_appear_animation()

	# 设置焦点到重试按钮
	retry_button.grab_focus()


func _input(event: InputEvent) -> void:
	## 全局输入处理
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_menu_button_pressed()

# ============================================================
# 数据收集
# ============================================================

func _collect_result_data() -> void:
	## 从GameManager收集本次结算所需的所有数据
	_result_data = {
		"score": GameManager.score,
		"high_score": GameManager.high_score,
		"current_stage": GameManager.current_stage,
		"game_state": GameManager.game_state,
	}

	# 从GameManager扩展数据中获取击坠数和命中率
	if "kill_count" in GameManager:
		_result_data["kill_count"] = GameManager.kill_count
	else:
		_result_data["kill_count"] = 0

	if "shots_fired" in GameManager:
		_result_data["shots_fired"] = GameManager.shots_fired
		_result_data["shots_hit"] = GameManager.shots_hit
	else:
		_result_data["shots_fired"] = 0
		_result_data["shots_hit"] = 0

	# 从GameManager的关卡结果中获取额外数据（关卡名、用时等）
	var level_name: String = ""
	var time_used: float = 0.0
	var level_id: String = ""

	if GameManager.has_method("get_level_result"):
		var level_result: Dictionary = GameManager.get_level_result()
		_result_data.merge(level_result)
		level_name = level_result.get("level_name", "")
		time_used = level_result.get("time", 0.0)
		level_id = level_result.get("level_id", "")

	# 如果没有关卡名，尝试从 GameManager 获取
	if level_name.is_empty():
		level_name = GameManager.current_stage_name

	_result_data["level_name"] = level_name
	_result_data["time"] = time_used
	_result_data["level_id"] = level_id

	# 构建关卡场景路径（用于重试）
	if not level_id.is_empty():
		_level_scene_path = LEVEL_SCENE_DIR + "stage_" + level_id + ".tscn"
	elif not GameManager.current_stage_id.is_empty():
		_level_scene_path = LEVEL_SCENE_DIR + "stage_" + GameManager.current_stage_id + ".tscn"
	else:
		# 后备：根据关卡索引构建路径
		var stage_index: int = GameManager.current_stage
		var all_ids: Array[String] = GameManager.get_all_stage_ids()
		if stage_index < all_ids.size():
			_level_scene_path = LEVEL_SCENE_DIR + "stage_" + all_ids[stage_index] + ".tscn"

	# 记录保存前的最高关卡（用于检测解锁）
	_prev_highest_stage = SaveManager.highest_stage

# ============================================================
# 评级判定
# ============================================================

func _calculate_rank(score: int) -> String:
	## 根据分数计算评级
	## S: 100万分以上
	## A: 50万分以上
	## B: 20万分以上
	## C: 其余
	if score >= RANK_S_THRESHOLD:
		return "S"
	elif score >= RANK_A_THRESHOLD:
		return "A"
	elif score >= RANK_B_THRESHOLD:
		return "B"
	else:
		return "C"

# ============================================================
# 数据显示
# ============================================================

func _display_base_data() -> void:
	## 显示基础结算数据
	var score: int = _result_data["score"]
	var kill_count: int = _result_data["kill_count"]
	var accuracy: float = _calculate_accuracy()
	var level_name: String = _result_data.get("level_name", "")
	var time_used: float = _result_data.get("time", 0.0)

	# 评级判定
	_final_rank = _calculate_rank(score)

	# 关卡名
	if stage_name_label != null:
		stage_name_label.text = level_name

	# 用时
	if time_label != null:
		var minutes: int = int(time_used) / 60
		var seconds: int = int(time_used) % 60
		time_label.text = "用时: %02d:%02d" % [minutes, seconds]

	# 分数显示（初始为0，后面滚动动画会更新）
	score_label.text = "%08d" % 0
	kill_count_label.text = "击坠: %d" % kill_count
	accuracy_label.text = "命中率: %.1f%%" % accuracy

	# 分数滚动动画
	_play_score_roll_animation(score)

	# 根据游戏状态决定"下一关"按钮是否可见
	if GameManager.game_state == GameManager.State.GAME_OVER:
		next_button.visible = false
	elif GameManager.current_stage >= GameManager.MAX_STAGE:
		next_button.visible = false  # 已是最后一关


func _calculate_accuracy() -> float:
	## 计算命中率
	var shots_fired: int = _result_data.get("shots_fired", 0)
	var shots_hit: int = _result_data.get("shots_hit", 0)

	if shots_fired <= 0:
		return 0.0

	return (float(shots_hit) / float(shots_fired)) * 100.0


func _update_rank_display() -> void:
	## 更新评级显示内容（文字、颜色、奖章纹理）
	rank_label.text = _final_rank

	# 设置评级颜色
	if RANK_COLORS.has(_final_rank):
		rank_label.modulate = RANK_COLORS[_final_rank]

	# 设置奖章纹理
	_set_medal_texture(_final_rank)


func _set_medal_texture(rank: String) -> void:
	## 根据评级设置奖章纹理
	if rank_sprite == null:
		return
	if MEDAL_TEXTURES.has(rank):
		rank_sprite.texture = MEDAL_TEXTURES[rank]

# ============================================================
# 动画
# ============================================================

func _play_score_roll_animation(target_score: int) -> void:
	## 分数滚动动画：从0快速递增到目标分数
	var duration: float = 1.0  # 滚动动画持续时间

	_score_tween = create_tween()
	_score_tween.set_parallel(false)

	# 使用tween_method实现分数递增效果
	# Godot 4.7: tween_method(method, from, to, duration) 四参数形式
	_score_tween.tween_method(
		_set_roll_score_text, 0.0, float(target_score), duration
	).set_trans(Tween.TRANS_LINEAR)


## 分数滚动回调（tween_method 调用）
## [param current_value] 当前分数值（0~target_score）
func _set_roll_score_text(current_value: float) -> void:
	if score_label != null:
		score_label.text = "%08d" % int(current_value)


func _play_rank_appear_animation() -> void:
	## 评级出现动画：延迟后缩放弹出
	var tween := create_tween()
	tween.set_parallel(false)

	# 等待分数滚动完毕
	tween.tween_callback(_on_score_roll_complete).set_delay(RANK_APPEAR_DELAY)


func _on_score_roll_complete() -> void:
	## 分数滚动完成回调：显示评级并保存结果
	# 先保存结果（含解锁检查）
	_save_stage_result()

	# 更新评级显示
	_update_rank_display()
	_set_rank_visible(true)

	# 评级弹出动画
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 从大到正常大小
	rank_sprite.scale = Vector2(3.0, 3.0)
	rank_sprite.modulate.a = 0.0
	tween.tween_property(rank_sprite, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_property(rank_sprite, "modulate:a", 1.0, 0.3)

	# 评级颜色闪烁效果（S评级特殊金色闪烁）
	if _final_rank == "S":
		_play_s_rank_glow_effect()

	# 显示下一关按钮（如果可见性条件满足）
	next_button.visible = true
	if next_button.visible:
		next_button.grab_focus()

	# 显示军衔信息
	_display_rank_info()

	# 显示解锁提示（如果有）
	_check_and_show_unlock_hint()


func _play_s_rank_glow_effect() -> void:
	## S评级专属光效动画
	var tween := create_tween()
	tween.set_loops(2)
	tween.tween_property(rank_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(rank_label, "modulate:a", 0.5, 0.2)
	tween.set_parallel(false)
	tween.tween_property(rank_label, "modulate:a", 1.0, 0.1)


func _set_rank_visible(is_visible: bool) -> void:
	## 设置评级区域的可见性
	rank_sprite.visible = is_visible

# ============================================================
# 解锁提示
# ============================================================

func _check_and_show_unlock_hint() -> void:
	## 检查是否有新解锁的关卡，并显示提示
	if unlock_hint_label == null:
		return

	var hint_text: String = ""

	# 检查是否解锁了新关卡
	var new_highest: int = SaveManager.highest_stage
	if new_highest > _prev_highest_stage:
		# 获取新解锁的关卡名
		var all_ids: Array[String] = GameManager.get_all_stage_ids()
		if new_highest < all_ids.size():
			var new_stage_id: String = all_ids[new_highest]
			# 尝试获取关卡名
			var stage_name: String = new_stage_id
			# 简单显示
			hint_text = "🎉 解锁新关卡: 第%d关" % (new_highest + 1)

	# 如果有提示文字，显示标签
	if not hint_text.is_empty():
		unlock_hint_label.text = hint_text
		unlock_hint_label.visible = true
		# 淡入动画
		unlock_hint_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(unlock_hint_label, "modulate:a", 1.0, 0.5)

# ============================================================
# 军衔显示（M3-F）
# ============================================================

func _display_rank_info() -> void:
	if RankManager == null:
		return
	var current_rank: String = RankManager.get_current_rank()
	var rank_name: String = RankManager.get_rank_name(current_rank)
	var rank_color: Color = RankManager.get_rank_color(current_rank)
	var progress: float = RankManager.get_rank_progress()
	var next_info: Dictionary = RankManager.get_next_rank_info()
	var info_text: String = "军衔: %s" % rank_name
	if next_info.size() > 0 and not next_info["rank"].is_empty():
		if next_info["score_needed"] > 0:
			info_text += " → %s (还需 %d 分)" % [next_info["name"], next_info["score_needed"]]
		else:
			info_text += " → %s" % next_info["name"]
	if unlock_hint_label != null:
		var hint_visible: bool = unlock_hint_label.visible
		unlock_hint_label.text = info_text
		unlock_hint_label.visible = true
		unlock_hint_label.modulate = Color(rank_color.r, rank_color.g, rank_color.b, 1.0)

# ============================================================
# 按钮回调
# ============================================================

func _on_next_button_pressed() -> void:
	## 下一关按钮回调：调用 GameManager.next_stage() 进入下一关
	_play_button_click_effect(next_button)

	# 进入下一关（GameManager.next_stage 会自动切换场景）
	GameManager.next_stage()


func _on_retry_button_pressed() -> void:
	## 重试按钮回调：重新加载关卡场景（不是结算场景）
	_play_button_click_effect(retry_button)

	# 重置游戏但保留当前关卡
	GameManager.score = 0
	GameManager.lives = GameManager.MAX_LIVES
	GameManager.bombs = GameManager.MAX_BOMBS
	GameManager.power_level = GameManager.MIN_POWER
	GameManager.set_state(GameManager.State.PLAYING)

	# 重新加载关卡场景
	if not _level_scene_path.is_empty():
		get_tree().change_scene_to_file(_level_scene_path)
	else:
		# 后退方案：重新加载当前场景
		get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	## 返回主菜单按钮回调
	_play_button_click_effect(menu_button)

	# 返回主菜单
	GameManager.reset_game()
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

# ============================================================
# 存档保存
# ============================================================

func _save_stage_result() -> void:
	var stage_index: int = GameManager.current_stage
	var score: int = _result_data["score"]

	SaveManager.save_stage_high_score(stage_index, score)

	var is_stage_clear: bool = GameManager.game_state == GameManager.State.STAGE_CLEAR
	var is_boss_defeated: bool = _result_data.get("boss_defeated", false)

	if is_stage_clear or is_boss_defeated:
		if stage_index < GameManager.MAX_STAGE:
			SaveManager.unlock_stage(stage_index + 1)

	if _final_rank == "S" and SaveManager.has_method("add_s_rank"):
		var stage_index: int = GameManager.current_stage
		SaveManager.add_s_rank(stage_index)

	SaveManager.save_game()

# ============================================================
# 动画效果
# ============================================================

func _play_button_click_effect(button: Button) -> void:
	## 按钮点击缩放效果
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
