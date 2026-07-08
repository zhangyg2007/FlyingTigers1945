## 深渊模式难度曲线计算
## 根据当前层数(floor)动态调整敌人属性、弹幕速度、生成密度等参数
## 用于无尽深渊模式的渐进式难度提升
class_name DifficultyCurve
extends RefCounted

## 基础生成密度（每波敌机数）
const BASE_SPAWN_DENSITY: int = 4
## 最大HP倍率上限
const MAX_HP_MULT: float = 5.0
## 最大弹速倍率上限
const MAX_SPEED_MULT: float = 3.0
## 最大生成密度上限
const MAX_SPAWN_DENSITY: int = 20
## 背景主题总数
const BG_THEME_COUNT: int = 12
## 背景切换间隔层数
const BG_THEME_INTERVAL: int = 3

# ============================================================
# 静态计算方法
# ============================================================

## 获取敌人HP倍率
## 随层数线性增长，每层+2%上限
## [param floor]: 当前层数
## [return]: HP倍率（如第10层 = 1.0 + 10 * 0.02 = 1.2）
static func get_enemy_hp_mult(floor: int) -> float:
	var mult := 1.0 + floor * 0.02
	return minf(mult, MAX_HP_MULT)


## 获取弹幕速度倍率
## 随层数线性增长，每层+1.5%
## [param floor]: 当前层数
## [return]: 弹速倍率（如第10层 = 1.0 + 10 * 0.015 = 1.15）
static func get_bullet_speed_mult(floor: int) -> float:
	var mult := 1.0 + floor * 0.015
	return minf(mult, MAX_SPEED_MULT)


## 获取生成密度（每波敌机数量）
## 基础密度 + 每层增加0.5（取整）
## [param floor]: 当前层数
## [return]: 本层每波应生成的敌机数量
static func get_spawn_density(floor: int) -> int:
	var density := BASE_SPAWN_DENSITY + floor * 0.5
	return mini(int(density), MAX_SPAWN_DENSITY)


## 获取BOSS HP倍率
## 比普通敌人增长更快，每层+5%
## [param floor]: 当前层数
## [return]: BOSS HP倍率（如第10层 = 1.0 + 10 * 0.05 = 1.5）
static func get_boss_hp_mult(floor: int) -> float:
	var mult := 1.0 + floor * 0.05
	return minf(mult, MAX_HP_MULT)


## 判断当前层是否应出现BOSS
## 每5层出现一个BOSS（第5、10、15...层）
## [param floor]: 当前层数
## [return]: 是否生成BOSS
static func should_spawn_boss(floor: int) -> bool:
	return floor % 5 == 0


## 获取当前层背景主题索引
## 每3层切换一次背景，循环使用12个主题
## [param floor]: 当前层数（从1开始）
## [return]: 背景主题索引（0~11）
static func get_bg_theme(floor: int) -> int:
	var adjusted_floor := maxi(floor - 1, 0)
	return int(adjusted_floor / BG_THEME_INTERVAL) % BG_THEME_COUNT


## 获取当前层的综合难度评级
## 根据各项参数计算综合评分，用于UI显示
## [param floor]: 当前层数
## [return]: 难度评级字符串（S/A/B/C/D）
static func get_difficulty_rating(floor: int) -> String:
	var score := _calculate_difficulty_score(floor)

	if score >= 80:
		return "S"
	elif score >= 60:
		return "A"
	elif score >= 40:
		return "B"
	elif score >= 20:
		return "C"
	else:
		return "D"


## 获取BOSS攻击间隔倍率
## 层数越高，BOSS攻击越频繁
## [param floor]: 当前层数
## [return]: 攻击间隔倍率（<1.0表示更频繁）
static func get_boss_attack_interval_mult(floor: int) -> float:
	var mult := 1.0 - floor * 0.01
	return maxf(mult, 0.3)  # 最低不能低于30%间隔


## 获取敌人射击频率倍率
## [param floor]: 当前层数
## [return]: 射击频率倍率
static func get_enemy_fire_rate_mult(floor: int) -> float:
	var mult := 1.0 + floor * 0.025
	return minf(mult, 3.0)


## 获取敌人移动速度倍率
## [param floor]: 当前层数
## [return]: 移动速度倍率
static func get_enemy_speed_mult(floor: int) -> float:
	var mult := 1.0 + floor * 0.01
	return minf(mult, 2.0)


## 获取掉落率倍率
## 层数越高掉落越好，给予玩家更多资源以应对更高难度
## [param floor]: 当前层数
## [return]: 掉落率倍率
static func get_drop_rate_mult(floor: int) -> float:
	var mult := 1.0 + floor * 0.005
	return minf(mult, 2.0)


# ============================================================
# 内部方法
# ============================================================

## 计算综合难度评分（0~100）
func _calculate_difficulty_score(floor: int) -> float:
	var hp_score := get_enemy_hp_mult(floor) / MAX_HP_MULT * 25.0
	var speed_score := get_bullet_speed_mult(floor) / MAX_SPEED_MULT * 25.0
	var density_score := float(get_spawn_density(floor)) / float(MAX_SPAWN_DENSITY) * 25.0
	var boss_score := get_boss_hp_mult(floor) / MAX_HP_MULT * 25.0

	return clampf(hp_score + speed_score + density_score + boss_score, 0.0, 100.0)


## 获取难度曲线描述文本（用于调试）
static func get_difficulty_summary(floor: int) -> String:
	var summary := (
		"=== 深渊模式 第%d层 难度参数 ===\n" % floor +
		"敌人HP倍率:    %.2f\n" % get_enemy_hp_mult(floor) +
		"弹速倍率:      %.2f\n" % get_bullet_speed_mult(floor) +
		"生成密度:      %d\n" % get_spawn_density(floor) +
		"BOSS HP倍率:   %.2f\n" % get_boss_hp_mult(floor) +
		"是否BOSS层:    %s\n" % str(should_spawn_boss(floor)) +
		"背景主题:      %d\n" % get_bg_theme(floor) +
		"难度评级:      %s\n" % get_difficulty_rating(floor) +
		"============================="
	)
	return summary
