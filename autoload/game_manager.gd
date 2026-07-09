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

## 玩家死亡（生命耗尽）— LevelBase 监听此信号强制结束关卡
signal player_died()

## BOSS被击败 — 触发关卡结算流程
signal boss_defeated_signal()

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

## 当前关卡字符串标识（如 "01_kunming"，与 stage_config.json 的 stage_id 一致）
var current_stage_id: String = ""

## 当前关卡显示名（如 "昆明首战"，从 stage_config.json 读取）
var current_stage_name: String = ""

## 当前关卡元数据（从 stage_config.json 读取，含 bgm/bg_layers/scroll_speed/boss_type/duration/easy/hard）
var current_stage_metadata: Dictionary = {}

## 上一次关卡结算数据（由 LevelBase 调用 set_level_result 写入）
var last_level_result: Dictionary = {}

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
## 优先从当前关卡 metadata 的 easy/hard 字段读取，无 metadata 时回退到全局默认值
func get_bullet_speed_multiplier() -> float:
	var mult := _get_stage_difficulty_field("bullet_speed_mult", -1.0)
	if mult >= 0.0:
		return mult
	# 回退：无关卡 metadata 时用全局默认
	match difficulty:
		Difficulty.HARD:
			return 1.3
		_:
			return 1.0


## 获取难度对应的敌人HP倍率
## 优先从当前关卡 metadata 的 easy/hard 字段读取，无 metadata 时回退到全局默认值
func get_enemy_hp_multiplier() -> float:
	var mult := _get_stage_difficulty_field("enemy_hp_mult", -1.0)
	if mult >= 0.0:
		return mult
	# 回退：无关卡 metadata 时用全局默认
	match difficulty:
		Difficulty.HARD:
			return 1.5
		_:
			return 1.0


## 获取当前关卡 BOSS 攻击间隔倍率（无 metadata 时回退到 1.0）
func get_boss_attack_interval_multiplier() -> float:
	return _get_stage_difficulty_field("boss_attack_interval_mult", 1.0)


## 从 current_stage_metadata 中按当前难度读取指定字段
## [param field]: 字段名（如 "enemy_hp_mult"）
## [param fallback]: 字段缺失时的回退值
func _get_stage_difficulty_field(field: String, fallback: float) -> float:
	if current_stage_metadata.is_empty():
		return fallback
	var diff_key: String = "easy" if difficulty == Difficulty.EASY else "hard"
	var diff_data: Dictionary = current_stage_metadata.get(diff_key, {})
	return diff_data.get(field, fallback)

# ============================================================
# 关卡管理
# ============================================================

## 关卡配置 JSON 文件路径（含全部关卡元数据）
const STAGE_CONFIG_PATH: String = "res://resources/level_data/stage_config.json"

## 关卡场景目录（level_base.gd 挂载的 .tscn）
const LEVEL_SCENE_DIR: String = "res://levels/"

## 进入下一关
func advance_stage() -> void:
	if current_stage < MAX_STAGE:
		current_stage += 1
		# 进入关卡通过状态
		set_state(State.STAGE_CLEAR)


## 设置指定关卡
func set_stage(stage_index: int) -> void:
	current_stage = clampi(stage_index, 0, MAX_STAGE)


## 加载关卡元数据并设置当前关卡
## [param stage_id]: 关卡字符串标识（如 "01_kunming"，与 stage_config.json 的 stage_id 一致）
## [return]: true=加载成功，false=找不到关卡配置
## 注：此方法只加载元数据，不切换场景。场景切换由 next_stage/goto_scene 负责。
func load_stage(stage_id: String) -> bool:
	var metadata: Dictionary = _load_stage_metadata(stage_id)
	if metadata.is_empty():
		push_error("[GameManager] 找不到关卡配置: %s" % stage_id)
		return false

	current_stage_id = stage_id
	current_stage_name = metadata.get("stage_name", stage_id)
	current_stage_metadata = metadata
	print("[GameManager] 已加载关卡 '%s'（%s）" % [stage_id, current_stage_name])
	return true


## 从 stage_config.json 读取指定关卡的元数据
func _load_stage_metadata(stage_id: String) -> Dictionary:
	if not FileAccess.file_exists(STAGE_CONFIG_PATH):
		push_error("[GameManager] stage_config.json 不存在: %s" % STAGE_CONFIG_PATH)
		return {}

	var file: FileAccess = FileAccess.open(STAGE_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("[GameManager] 无法打开 stage_config.json")
		return {}

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("[GameManager] stage_config.json 解析失败: %s" % json.get_error_message())
		return {}

	var data: Dictionary = json.data
	var stages: Array = data.get("stages", [])
	for stage in stages:
		if stage.get("stage_id", "") == stage_id:
			return stage

	return {}


## 获取所有关卡 ID 列表（从 stage_config.json 读取）
func get_all_stage_ids() -> Array[String]:
	var ids: Array[String] = []
	if not FileAccess.file_exists(STAGE_CONFIG_PATH):
		return ids

	var file: FileAccess = FileAccess.open(STAGE_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return ids
	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return ids

	var data: Dictionary = json.data
	for stage in data.get("stages", []):
		ids.append(stage.get("stage_id", ""))
	return ids


## 进入下一关（加载下一关元数据 + 切换场景）
## 注：关卡场景路径约定为 res://levels/stage_<stage_id>.tscn
func next_stage() -> void:
	advance_stage()
	# 查找下一关的 stage_id
	var all_ids: Array[String] = get_all_stage_ids()
	if current_stage < all_ids.size():
		var next_id: String = all_ids[current_stage]
		load_stage(next_id)
		goto_scene(LEVEL_SCENE_DIR + "stage_" + next_id + ".tscn")


## BOSS被击败回调（由 BossBase 调用）
## 触发 boss_defeated_signal 信号，LevelBase 监听后启动结算流程
func boss_defeated() -> void:
	print("[GameManager] BOSS已被击败，触发关卡结算信号")
	boss_defeated_signal.emit()


## 玩家死亡回调（由 PlayerBase 在生命耗尽时调用）
## 触发 player_died 信号，LevelBase 监听后强制结束关卡
func notify_player_died() -> void:
	print("[GameManager] 玩家死亡信号已发射")
	player_died.emit()


## 保存关卡结算数据（由 LevelBase 在关卡结束时调用）
func set_level_result(data: Dictionary) -> void:
	last_level_result = data
	print("[GameManager] 关卡结算数据已保存: %s" % str(data))


## 获取上一次关卡结算数据（由 result_screen 读取展示）
func get_level_result() -> Dictionary:
	return last_level_result


## 切换到指定场景
## [param path]: 场景资源路径（如 "res://scenes/ui/level_result.tscn"）
func goto_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("[GameManager] 场景文件不存在: %s" % path)
		return
	print("[GameManager] 切换场景: %s" % path)
	get_tree().change_scene_to_file(path)

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
	# 关卡元数据也一并重置
	current_stage_id = ""
	current_stage_name = ""
	current_stage_metadata = {}
	last_level_result = {}

	score_changed.emit(score)
	lives_changed.emit(lives)
	bombs_changed.emit(bombs)
	power_changed.emit(power_level)


## 完全重置（包括高分和难度），用于调试或设置重置
func reset_all() -> void:
	reset_game()
	high_score = 0
	difficulty = Difficulty.EASY
