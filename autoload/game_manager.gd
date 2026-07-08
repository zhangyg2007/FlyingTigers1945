extends Node
## 全局游戏状态管理器（Autoload单例）
## 负责管理分数、生命、炸弹、Power等级、关卡进度和游戏状态。
## 通过信号与UI、玩家等模块解耦通信。

# ============================================================
# 信号定义
# ============================================================

## 分数发生变化时发出
signal score_changed(new_score: int)

## 生命发生变化时发出
signal lives_changed(new_lives: int)

## 炸弹数量发生变化时发出
signal bombs_changed(new_bombs: int)

## Power等级发生变化时发出
signal power_changed(new_power: int)

## 游戏结束（生命耗尽）
signal game_over()

## 当前关卡通过
signal stage_complete(stage_index: int)

# ============================================================
# 枚举：游戏状态
# ============================================================

## 游戏状态枚举
enum State {
	MENU,        ## 主菜单
	PLAYING,     ## 游戏进行中
	PAUSED,      ## 暂停
	STAGE_CLEAR, ## 关卡通过
	GAME_OVER    ## 游戏结束
}

## 难度模式枚举
enum Difficulty {
	EASY, ## 简单模式
	HARD  ## 困难模式
}

# ============================================================
# 导出 / 配置常量
# ============================================================

## 最大生命数
const MAX_LIVES: int = 3

## 最大炸弹数
const MAX_BOMBS: int = 6

## Power等级上限
const MAX_POWER: int = 4

## Power等级下限
const MIN_POWER: int = 1

## 关卡总数（索引 0~15，共16关）
const MAX_STAGE: int = 15

## 无敌持续时间（秒）
const INVINCIBLE_DURATION: float = 2.0

## 炸弹无敌持续时间（秒）
const BOMB_INVINCIBLE_DURATION: float = 2.0

# ============================================================
# 公开变量
# ============================================================

## 当前分数
var score: int = 0

## 历史最高分
var high_score: int = 0

## 当前生命数
var lives: int = MAX_LIVES

## 当前炸弹数
var bombs: int = MAX_BOMBS

## Power等级（1~4）
var power_level: int = MIN_POWER

## 当前关卡索引（0~15）
var current_stage: int = 0

## 当前游戏状态
var game_state: State = State.MENU

## 当前难度模式
var difficulty: Difficulty = Difficulty.EASY

## 是否处于无敌状态
var is_invincible: bool = false

# ============================================================
# 内部变量
# ============================================================

## 无敌计时器
var _invincible_timer: float = 0.0

## 无敌计时器引用（使用SceneTree的create_timer）
var _invincible_countdown: SceneTreeTimer = null

## 每个Power等级对应的分数阈值（累计分数提升Power）
## Power 1: 0, Power 2: 10000, Power 3: 30000, Power 4: 60000
const POWER_THRESHOLDS: Array[int] = [0, 10000, 30000, 60000]

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 初始化时暂停处理（非PLAYING状态时暂停_process）
	set_process(false)
	set_physics_process(false)


func _process(delta: float) -> void:
	## 每帧更新无敌计时
	if is_invincible:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			is_invincible = false
			_invincible_timer = 0.0

# ============================================================
# 游戏状态切换
# ============================================================

## 切换游戏状态
func set_state(new_state: State) -> void:
	game_state = new_state

	match new_state:
		State.PLAYING:
			set_process(true)
			set_physics_process(true)
			get_tree().paused = false
		State.PAUSED:
			get_tree().paused = true
		State.GAME_OVER:
			set_process(false)
			set_physics_process(false)
			game_over.emit()
		State.STAGE_CLEAR:
			stage_complete.emit(current_stage)
		State.MENU:
			set_process(false)
			set_physics_process(false)
			get_tree().paused = false

# ============================================================
# 分数管理
# ============================================================

## 增加分数，并自动检查Power升级
func add_score(amount: int) -> void:
	score += amount

	# 更新最高分
	if score > high_score:
		high_score = score

	score_changed.emit(score)

	# 根据累计分数自动提升Power等级
	_check_power_from_score()

	# 同步保存最高分到SaveManager
	if SaveManager:
		SaveManager.save_highest_score(high_score)


## 获取难度对应的分数倍率
func get_score_multiplier() -> float:
	match difficulty:
		Difficulty.HARD:
			return 1.5
		_:
			return 1.0

# ============================================================
# 生命管理
# ============================================================

## 失去一条生命，并进入无敌状态
func lose_life() -> void:
	if is_invincible:
		return

	if lives <= 0:
		return

	lives -= 1
	lives_changed.emit(lives)

	# 降低一级Power
	decrease_power()

	if lives <= 0:
		# 生命耗尽，游戏结束
		set_state(State.GAME_OVER)
	else:
		# 进入无敌状态
		start_invincible(INVINCIBLE_DURATION)


## 增加一条生命（拾取生命道具时调用）
func add_life() -> void:
	if lives < MAX_LIVES:
		lives += 1
		lives_changed.emit(lives)

# ============================================================
# 炸弹管理
# ============================================================

## 使用炸弹：清屏效果 + 进入无敌状态
func use_bomb() -> void:
	if bombs <= 0:
		return

	bombs -= 1
	bombs_changed.emit(bombs)

	# 进入无敌状态（比普通无敌时间稍长）
	start_invincible(BOMB_INVINCIBLE_DURATION)

	# 发出炸弹信号，由外部（如BulletManager）负责实际清屏逻辑
	# 这里只管理状态，具体效果在其他系统处理


## 增加炸弹（拾取炸弹道具时调用）
func add_bomb() -> void:
	if bombs < MAX_BOMBS:
		bombs += 1
		bombs_changed.emit(bombs)

# ============================================================
# Power等级管理
# ============================================================

## 提升Power等级（上限 MAX_POWER）
func increase_power() -> void:
	if power_level < MAX_POWER:
		power_level += 1
		power_changed.emit(power_level)


## 降低Power等级（下限 MIN_POWER）
func decrease_power() -> void:
	if power_level > MIN_POWER:
		power_level -= 1
		power_changed.emit(power_level)


## 根据累计分数自动检查并提升Power
func _check_power_from_score() -> void:
	# 从高到低检查阈值
	for i in range(POWER_THRESHOLDS.size() - 1, 0, -1):
		if score >= POWER_THRESHOLDS[i]:
			var target_power: int = i + 1
			if power_level < target_power:
				power_level = target_power
				power_changed.emit(power_level)
			break

# ============================================================
# 无敌状态
# ============================================================

## 开始无敌状态
func start_invincible(duration: float) -> void:
	is_invincible = true
	_invincible_timer = duration


## 获取难度对应的敌弹速度倍率
func get_bullet_speed_multiplier() -> float:
	match difficulty:
		Difficulty.HARD:
			return 1.3
		_:
			return 1.0


## 获取难度对应的敌人HP倍率
func get_enemy_hp_multiplier() -> float:
	match difficulty:
		Difficulty.HARD:
			return 1.5
		_:
			return 1.0

# ============================================================
# 关卡管理
# ============================================================

## 进入下一关
func advance_stage() -> void:
	if current_stage < MAX_STAGE:
		current_stage += 1
		# 进入关卡通过状态
		set_state(State.STAGE_CLEAR)


## 设置指定关卡
func set_stage(stage_index: int) -> void:
	current_stage = clampi(stage_index, 0, MAX_STAGE)

# ============================================================
# 重置
# ============================================================

## 重置所有游戏状态到初始值（不重置 high_score 和 difficulty）
func reset_game() -> void:
	score = 0
	lives = MAX_LIVES
	bombs = MAX_BOMBS
	power_level = MIN_POWER
	current_stage = 0
	is_invincible = false
	_invincible_timer = 0.0
	game_state = State.MENU

	score_changed.emit(score)
	lives_changed.emit(lives)
	bombs_changed.emit(bombs)
	power_changed.emit(power_level)


## 完全重置（包括高分和难度），用于调试或设置重置
func reset_all() -> void:
	reset_game()
	high_score = 0
	difficulty = Difficulty.EASY
