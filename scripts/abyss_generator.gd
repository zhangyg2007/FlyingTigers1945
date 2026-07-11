## 深渊模式关卡生成器
## 根据楼层程序化生成无限波次，难度随楼层递增。
## 生成结果与 SpawnManager.wave_data 格式一致：
##   {time, enemy_type, count, formation, spawn_x, spawn_y, speed_mult, path_id}
##
## 难度分层：
##   floor 1-5:   基础（ki27_fighter, ki43_hayabusa, 1.0~1.2 倍速）
##   floor 6-10:  中等（+ a6m_zero, d3a_val, 1.2~1.5 倍速）
##   floor 11-15: 高（+ ki61_hien, ki84_hayate, 1.5~1.8 倍速）
##   floor 16-20: 极高（+ j7w_shinden, ki45_toryu, 1.8~2.2 倍速）
##   floor 21+:   地狱（全部敌机, 2.0+ 倍速）
##   每 5 层一个 BOSS 波次（floor 5/10/15/20... 循环）
class_name AbyssGenerator
extends RefCounted

# ============================================================
# 常量
# ============================================================

## 视口宽度（与 CSV 关卡坐标体系一致）
const VIEWPORT_WIDTH: float = 540.0

## 生成 X 坐标范围
const SPAWN_X_MIN: float = 100.0
const SPAWN_X_MAX: float = 440.0

## 普通敌机生成 Y 坐标（屏幕上方外侧）
const SPAWN_Y: float = -50.0

## BOSS 生成 Y 坐标
const BOSS_SPAWN_Y: float = -150.0

## 每层最小/最大波次数
const WAVES_MIN: int = 8
const WAVES_MAX: int = 12

## 每层持续时长范围（秒）
const FLOOR_DURATION_MIN: float = 40.0
const FLOOR_DURATION_MAX: float = 60.0

## 首波延迟（秒）
const FIRST_WAVE_DELAY: float = 3.0

## BOSS 层间隔
const BOSS_FLOOR_INTERVAL: int = 5

## BOSS 类型循环表（floor 5/10/15/20...）
const BOSS_CYCLE: Array[String] = ["BOSS_bomber", "BOSS_nachi", "BOSS_fortress", "BOSS_kongo"]

## 编队类型池
const FORMATIONS: Array[String] = ["line", "v_formation", "diamond", "swarm"]

# ============================================================
# 敌机池定义（按难度分层解锁，权重越大出现概率越高）
# ============================================================

## tier 1 (floor 1-5): 基础
const TIER1_ENEMIES: Dictionary = {
	"ki27_fighter": 10,
	"ki43_hayabusa": 6,
}

## tier 2 (floor 6-10): 中等
const TIER2_ENEMIES: Dictionary = {
	"ki27_fighter": 8,
	"ki43_hayabusa": 6,
	"a6m_zero": 5,
	"d3a_val": 4,
}

## tier 3 (floor 11-15): 高
const TIER3_ENEMIES: Dictionary = {
	"ki27_fighter": 6,
	"ki43_hayabusa": 5,
	"a6m_zero": 5,
	"d3a_val": 4,
	"ki61_hien": 4,
	"ki84_hayate": 3,
}

## tier 4 (floor 16-20): 极高
const TIER4_ENEMIES: Dictionary = {
	"ki27_fighter": 4,
	"ki43_hayabusa": 4,
	"a6m_zero": 5,
	"d3a_val": 4,
	"ki61_hien": 5,
	"ki84_hayate": 4,
	"j7w_shinden": 3,
	"ki45_toryu": 3,
}

## tier 5 (floor 21+): 地狱（全部敌机）
const TIER5_ENEMIES: Dictionary = {
	"ki27_fighter": 3,
	"ki43_hayabusa": 3,
	"a6m_zero": 4,
	"d3a_val": 3,
	"ki61_hien": 4,
	"ki84_hayate": 4,
	"j7w_shinden": 4,
	"ki45_toryu": 4,
	"ki21_bomber": 2,
	"ohka_kamikaze": 2,
}

## 各层级速度倍率范围（Vector2(min, max)）
const TIER_SPEED_RANGES: Array[Vector2] = [
	Vector2(1.0, 1.2),  # tier 1
	Vector2(1.2, 1.5),  # tier 2
	Vector2(1.5, 1.8),  # tier 3
	Vector2(1.8, 2.2),  # tier 4
	Vector2(2.0, 2.5),  # tier 5（会随楼层继续增长）
]

# ============================================================
# 内部变量
# ============================================================

## 随机数生成器
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ============================================================
# 生命周期
# ============================================================

func _init() -> void:
	_rng.randomize()

# ============================================================
# 公开方法
# ============================================================

## 生成指定楼层的波次数据
## [param floor_num]: 楼层（从 1 开始）
## [return]: 波次字典数组，格式与 SpawnManager.wave_data 一致
func generate_floor(floor_num: int) -> Array[Dictionary]:
	var waves: Array[Dictionary] = []
	var tier: int = _get_tier(floor_num)
	var enemy_pool: Dictionary = _get_enemy_pool(tier)
	var speed_range: Vector2 = TIER_SPEED_RANGES[tier - 1]

	# 决定波次数
	var wave_count: int = _rng.randi_range(WAVES_MIN, WAVES_MAX)

	# BOSS 层：最后一波为 BOSS
	var is_boss_floor: bool = (floor_num % BOSS_FLOOR_INTERVAL == 0)
	var normal_wave_count: int = wave_count
	if is_boss_floor:
		normal_wave_count = wave_count - 1

	# 决定本层总时长
	var duration: float = _rng.randf_range(FLOOR_DURATION_MIN, FLOOR_DURATION_MAX)

	# 生成普通波次（均匀分布 + 抖动）
	var interval: float = duration / float(wave_count)
	for i in range(normal_wave_count):
		var t: float = FIRST_WAVE_DELAY + interval * float(i) + _rng.randf_range(-1.0, 1.0)
		t = maxf(t, 1.0)
		var enemy_type: String = _pick_weighted(enemy_pool)
		var formation: String = FORMATIONS[_rng.randi_range(0, FORMATIONS.size() - 1)]
		var count: int = _pick_count(formation, tier)
		var spawn_x: float = _rng.randf_range(SPAWN_X_MIN, SPAWN_X_MAX)
		var speed_mult: float = _rng.randf_range(speed_range.x, speed_range.y)
		waves.append({
			"time": t,
			"enemy_type": enemy_type,
			"count": count,
			"formation": formation,
			"spawn_x": spawn_x,
			"spawn_y": SPAWN_Y,
			"speed_mult": speed_mult,
			"path_id": "straight",
		})

	# BOSS 波次（最后一波）
	if is_boss_floor:
		var boss_time: float = FIRST_WAVE_DELAY + duration
		waves.append({
			"time": boss_time,
			"enemy_type": get_floor_boss(floor_num),
			"count": 1,
			"formation": "boss",
			"spawn_x": VIEWPORT_WIDTH / 2.0,
			"spawn_y": BOSS_SPAWN_Y,
			"speed_mult": 0.5,
			"path_id": "boss_enter",
		})

	# 按时间升序排序
	waves.sort_custom(_compare_wave_time)

	return waves


## 获取指定楼层的 BOSS 类型
## [param floor_num]: 楼层
## [return]: BOSS 类型字符串；非 BOSS 层返回空字符串
func get_floor_boss(floor_num: int) -> String:
	if floor_num % BOSS_FLOOR_INTERVAL != 0:
		return ""
	var idx: int = ((floor_num / BOSS_FLOOR_INTERVAL) - 1) % BOSS_CYCLE.size()
	return BOSS_CYCLE[idx]


## 获取指定楼层的难度倍率（以速度倍率中值作为综合难度代表）
## [param floor_num]: 楼层
## [return]: 难度倍率
func get_difficulty_multiplier(floor_num: int) -> float:
	var tier: int = _get_tier(floor_num)
	var speed_range: Vector2 = TIER_SPEED_RANGES[tier - 1]
	var mult: float = (speed_range.x + speed_range.y) / 2.0
	# tier 5 在中值基础上随楼层继续递增
	if tier == 5:
		mult += float(floor_num - 21) * 0.05
	return mult


## 获取敌人 HP 倍率（供 AbyssManager 注入到 SpawnManager 的难度参数）
## 与 DifficultyCurve.get_enemy_hp_mult 公式一致：每层 +2%，上限 5.0
## [param floor_num]: 楼层
## [return]: HP 倍率
func get_enemy_hp_mult(floor_num: int) -> float:
	var mult: float = 1.0 + float(floor_num) * 0.02
	return minf(mult, 5.0)


## 获取弹幕速度倍率（供 AbyssManager 注入到 SpawnManager 的难度参数）
## 与 DifficultyCurve.get_bullet_speed_mult 公式一致：每层 +1.5%，上限 3.0
## [param floor_num]: 楼层
## [return]: 弹速倍率
func get_bullet_speed_mult(floor_num: int) -> float:
	var mult: float = 1.0 + float(floor_num) * 0.015
	return minf(mult, 3.0)

# ============================================================
# 内部方法
# ============================================================

## 获取楼层对应的难度层级（1~5）
func _get_tier(floor_num: int) -> int:
	if floor_num <= 5:
		return 1
	elif floor_num <= 10:
		return 2
	elif floor_num <= 15:
		return 3
	elif floor_num <= 20:
		return 4
	else:
		return 5


## 获取指定层级的敌机池
func _get_enemy_pool(tier: int) -> Dictionary:
	match tier:
		1:
			return TIER1_ENEMIES
		2:
			return TIER2_ENEMIES
		3:
			return TIER3_ENEMIES
		4:
			return TIER4_ENEMIES
		_:
			return TIER5_ENEMIES


## 权重随机选择敌机类型
func _pick_weighted(pool: Dictionary) -> String:
	var total: int = 0
	for key in pool:
		total += int(pool[key])
	if total <= 0:
		var keys: Array = pool.keys()
		return String(keys[0])
	var roll: int = _rng.randi_range(1, total)
	var acc: int = 0
	for key in pool:
		acc += int(pool[key])
		if roll <= acc:
			return key
	var fallback_keys: Array = pool.keys()
	return String(fallback_keys[0])


## 根据编队与层级决定单波敌机数量
func _pick_count(formation: String, tier: int) -> int:
	var base: int = 3
	match formation:
		"line":
			base = _rng.randi_range(3, 5)
		"v_formation":
			base = _rng.randi_range(3, 5)
		"diamond":
			base = _rng.randi_range(4, 6)
		"swarm":
			base = _rng.randi_range(4, 7)
		_:
			base = 3
	# 高层级数量略增
	base += (tier - 1) / 2
	return base


## 波次时间比较（用于升序排序）
func _compare_wave_time(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
