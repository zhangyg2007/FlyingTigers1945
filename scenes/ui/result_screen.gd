extends CanvasLayer
## 结算界面
## 关卡通关或游戏结束后的成绩展示，包含分数、击坠数、命中率、评级等信息。
## 根据分数自动判定等级（S/A/B/C），支持跳转下一关、重试和返回主菜单。
##
## 节点结构要求（在场景编辑器中搭建）：
## - ScoreLabel (Label)               -- 最终分数
## - KillCountLabel (Label)           -- 击坠数
## - AccuracyLabel (Label)            -- 命中率
## - RankSprite (TextureRect/Panel)   -- 评级图片
##   - Label (Label)                  -- 评级文字（S/A/B/C）
## - NextButton (Button)              -- 下一关按钮
## - RetryButton (Button)             -- 重试按钮
## - MenuButton (Button)              -- 返回主菜单按钮

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
	"S": Color.GOLD,
	"A": Color(0.85, 0.65, 0.13, 1.0),  # 金黄
	"B": Color.SILVER,
	"C": Color(0.72, 0.45, 0.20, 1.0),  # 铜色
}

## 评级动画出现的延迟时间（秒）
const RANK_APPEAR_DELAY: float = 1.5

## 场景路径
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"

# ============================================================
# 节点引用
# ============================================================

## 最终分数标签 -- 节点路径: $ScoreLabel
@onready var score_label: Label = %ScoreLabel

## 击坠数标签 -- 节点路径: $KillCountLabel
@onready var kill_count_label: Label = %KillCountLabel

## 命中率标签 -- 节点路径: $AccuracyLabel
@onready var accuracy_label: Label = %AccuracyLabel

## 评级图片 -- 节点路径: $RankSprite
@onready var rank_sprite: TextureRect = %RankSprite

## 评级文字标签 -- 节点路径: $RankSprite/Label
@onready var rank_label: Label = %RankLabel

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

	# 初始隐藏评级，等动画播放
	_set_rank_visible(false)
	next_button.visible = false

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
	# 需要GameManager扩展以下属性:
	#   var kill_count: int = 0
	#   var shots_fired: int = 0
	#   var shots_hit: int = 0
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

	# 尝试从GameManager的关卡结果中获取额外数据
	if GameManager.has_method("get_level_result"):
		var level_result: Dictionary = GameManager.get_level_result()
		_result_data.merge(level_result)

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

	# 评级判定
	_final_rank = _calculate_rank(score)

	# 分数显示（初始为0，后面滚动动画会更新）
	score_label.text = "%08d" % 0
	kill_count_label.text = "%d" % kill_count
	accuracy_label.text = "%.1f%%" % accuracy

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
	## 更新评级显示内容
	rank_label.text = _final_rank

	# 设置评级颜色
	if RANK_COLORS.has(_final_rank):
		rank_label.modulate = RANK_COLORS[_final_rank]

# ============================================================
# 动画
# ============================================================

func _play_score_roll_animation(target_score: int) -> void:
	## 分数滚动动画：从0快速递增到目标分数
	var duration: float = 1.0  # 滚动动画持续时间
	var roll_score: int = 0

	_score_tween = create_tween()
	_score_tween.set_parallel(false)

	# 使用tween_method实现分数递增效果
	_score_tween.tween_method(
		func(current_value: float) -> void:
			score_label.text = "%08d" % int(current_value)
	).from(0.0).to(float(target_score)).set_duration(duration).set_trans(Tween.TRANS_LINEAR)


func _play_rank_appear_animation() -> void:
	## 评级出现动画：延迟后缩放弹出
	var tween := create_tween()
	tween.set_parallel(false)

	# 等待分数滚动完毕
	tween.tween_callback(_on_score_roll_complete).set_delay(RANK_APPEAR_DELAY)


func _on_score_roll_complete() -> void:
	## 分数滚动完成回调：显示评级
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
	next_button.grab_focus()


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
# 按钮回调
# ============================================================

func _on_next_button_pressed() -> void:
	## 下一关按钮回调：加载下一关
	_play_button_click_effect(next_button)

	# 保存当前关卡结果
	_save_stage_result()

	# 进入下一关
	var next_stage: int = GameManager.current_stage + 1
	GameManager.set_stage(next_stage)

	var stage_path: String = "res://scenes/levels/stage_%02d.tscn" % (next_stage + 1)
	get_tree().change_scene_to_file(stage_path)


func _on_retry_button_pressed() -> void:
	## 重试按钮回调：重新开始当前关卡
	_play_button_click_effect(retry_button)

	# 重置游戏但保留当前关卡
	GameManager.score = 0
	GameManager.lives = GameManager.MAX_LIVES
	GameManager.bombs = GameManager.MAX_BOMBS
	GameManager.power_level = GameManager.MIN_POWER

	# 重新加载当前场景
	get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	## 返回主菜单按钮回调
	_play_button_click_effect(menu_button)

	# 保存当前关卡结果
	_save_stage_result()

	# 返回主菜单
	GameManager.reset_game()
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

# ============================================================
# 存档保存
# ============================================================

func _save_stage_result() -> void:
	## 保存当前关卡的结果到SaveManager
	var stage_index: int = GameManager.current_stage
	var score: int = _result_data["score"]

	# 更新最高分
	SaveManager.save_stage_high_score(stage_index, score)

	# 保存评级（需要SaveManager扩展: save_stage_rank(stage_index, rank)）
	if SaveManager.has_method("save_stage_rank"):
		SaveManager.save_stage_rank(stage_index, _final_rank)

	# 解锁下一关（如果是主线关且已通关）
	if stage_index < 12 and GameManager.game_state == GameManager.State.STAGE_CLEAR:
		SaveManager.unlock_stage(stage_index + 1)

	# 保存存档
	SaveManager.save_game()

# ============================================================
# 动画效果
# ============================================================

func _play_button_click_effect(button: Button) -> void:
	## 按钮点击缩放效果
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
