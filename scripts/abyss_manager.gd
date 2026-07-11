## 深渊模式管理器
## 管理无限楼层的程序化生成、楼层切换、死亡结算与记录保存。
## 作为 abyss_mode.tscn 的根节点脚本运行。
##
## 流程：
##   start_abyss() → _start_floor(1) → SpawnManager 生成敌机
##   → all_waves_complete → _on_floor_cleared → 延迟 → _start_floor(next)
##   → GameManager.player_died → _on_player_died → 保存记录 → abyss_ended
class_name AbyssManager
extends Node

# ============================================================
# 信号
# ============================================================

## 楼层开始
signal floor_started(floor_num: int)

## 楼层通关
signal floor_cleared(floor_num: int)

## 深渊模式结束（玩家死亡）
signal abyss_ended(floor_num: int, score: int)

## 创下新纪录（层数或分数突破历史最佳）
signal new_record(floor_num: int, score: int)

# ============================================================
# 常量
# ============================================================

## 楼层切换延迟（秒）
const FLOOR_TRANSITION_DELAY: float = 2.5

## BOSS 层额外超时缓冲（秒）
const BOSS_TIMEOUT_BUFFER: float = 60.0

## 普通层超时缓冲（秒）
const NORMAL_TIMEOUT_BUFFER: float = 20.0

# ============================================================
# 公开变量
# ============================================================

## 当前楼层
var current_floor: int = 0

## 累计分数
var total_score: int = 0

## 是否处于深渊模式
var is_active: bool = false

# ============================================================
# 内部变量
# ============================================================

## 波次生成器
var _generator: AbyssGenerator = null

## 是否正在切换楼层（防止 all_waves_complete 重复触发）
var _transitioning: bool = false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_generator = AbyssGenerator.new()
	_connect_signals()
	# 自动开始（与 LevelBase 行为一致，便于独立运行测试）
	start_abyss()


## 连接全局信号（使用 if not ... is_connected 模式避免重复连接）
func _connect_signals() -> void:
	if SpawnManager.has_signal("all_waves_complete"):
		if not SpawnManager.all_waves_complete.is_connected(_on_floor_cleared):
			SpawnManager.all_waves_complete.connect(_on_floor_cleared)
	if GameManager.has_signal("player_died"):
		if not GameManager.player_died.is_connected(_on_player_died):
			GameManager.player_died.connect(_on_player_died)

# ============================================================
# 深渊流程
# ============================================================

## 开始深渊模式（重置状态，从第 1 层开始）
func start_abyss() -> void:
	if is_active:
		return
	# 重置 GameManager 状态（分数/生命/炸弹归零，开始新一局）
	GameManager.reset_game()
	GameManager.set_state(GameManager.State.PLAYING)

	current_floor = 0
	total_score = 0
	is_active = true
	_transitioning = false

	print("[AbyssManager] 深渊模式开始")
	_start_floor(1)


## 开始指定楼层
func _start_floor(floor_num: int) -> void:
	current_floor = floor_num
	_transitioning = false

	# 生成波次数据
	var waves: Array[Dictionary] = _generator.generate_floor(floor_num)

	# 加载到 SpawnManager（直接写入 wave_data，跳过 CSV 解析）
	SpawnManager.wave_data = waves
	SpawnManager.current_stage_id = "abyss_floor_%d" % floor_num

	# 设置关卡超时：最后一波时间 + 缓冲
	var last_time: float = 0.0
	for w in waves:
		last_time = maxf(last_time, float(w.get("time", 0.0)))
	var buffer: float = BOSS_TIMEOUT_BUFFER if _generator.get_floor_boss(floor_num) != "" else NORMAL_TIMEOUT_BUFFER
	SpawnManager.stage_timeout = last_time + buffer

	# 注入深渊难度参数到 GameManager（供敌人 apply_difficulty 读取）
	_apply_abyss_difficulty(floor_num)

	# 开始生成
	SpawnManager.start_stage()

	floor_started.emit(floor_num)
	print("[AbyssManager] 第 %d 层开始（%d 波，难度倍率 %.2f）" % [
		floor_num, waves.size(), _generator.get_difficulty_multiplier(floor_num)
	])


## 注入深渊难度倍率到 GameManager.current_stage_metadata
## 使得 SpawnManager._spawn_single_enemy → enemy.apply_difficulty 能读取到楼层递增的 HP/弹速倍率
func _apply_abyss_difficulty(floor_num: int) -> void:
	# 通过 AbyssGenerator 实例方法获取倍率（避免对全局 DifficultyCurve 类的静态依赖，
	# 公式与 DifficultyCurve.get_enemy_hp_mult / get_bullet_speed_mult 一致）
	var hp_mult: float = _generator.get_enemy_hp_mult(floor_num)
	var bullet_mult: float = _generator.get_bullet_speed_mult(floor_num)
	var diff_data: Dictionary = {
		"enemy_hp_mult": hp_mult,
		"bullet_speed_mult": bullet_mult,
	}
	GameManager.current_stage_metadata = {
		"easy": diff_data,
		"hard": diff_data,
	}


## 楼层通关回调（SpawnManager.all_waves_complete）
func _on_floor_cleared() -> void:
	if not is_active or _transitioning:
		return
	_transitioning = true
	SpawnManager.stop_stage()

	total_score = GameManager.score
	floor_cleared.emit(current_floor)
	print("[AbyssManager] 第 %d 层通关（累计分数 %d）" % [current_floor, total_score])

	# 延迟后开始下一层
	var next_floor: int = current_floor + 1
	get_tree().create_timer(FLOOR_TRANSITION_DELAY).timeout.connect(
		_on_transition_timeout.bind(next_floor)
	)


## 楼层切换计时器回调
func _on_transition_timeout(next_floor: int) -> void:
	if not is_active:
		return
	_start_floor(next_floor)


## 玩家死亡回调（GameManager.player_died）
func _on_player_died() -> void:
	if not is_active:
		return
	is_active = false
	SpawnManager.stop_stage()

	total_score = GameManager.score

	# 检查新纪录（保存前与历史最佳比较）
	var new_floor_record: bool = current_floor > SaveManager.abyss_best_floor
	var new_score_record: bool = total_score > SaveManager.abyss_best_score

	# 保存记录（更新内存 + 写盘）
	SaveManager.save_abyss_record(current_floor, total_score)

	if new_floor_record or new_score_record:
		new_record.emit(current_floor, total_score)

	abyss_ended.emit(current_floor, total_score)
	print("[AbyssManager] 深渊模式结束：第 %d 层，分数 %d" % [current_floor, total_score])

# ============================================================
# 查询方法
# ============================================================

## 获取当前楼层
func get_current_floor() -> int:
	return current_floor


## 获取累计分数
func get_total_score() -> int:
	return total_score
