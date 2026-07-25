class_name ComboManager
extends Node
## Combo 系统（v1.5 C15）
## 连续击落计数器：0.5 秒内连续击落累加，每 10 连击奖励 500 分。
## 被击中或超时清零。HUD 通过 combo_changed / combo_broken 信号更新显示。

# ============================================================
# 信号定义
# ============================================================

## Combo 数变化（combo_count, bonus_score_this_tick）
signal combo_changed(combo_count: int, bonus_score: int)

## Combo 中断（final_count）
signal combo_broken(final_count: int)

## Combo 里程碑奖励（milestone, bonus_score）
signal combo_milestone(milestone: int, bonus_score: int)

# ============================================================
# 常量
# ============================================================

## 连击有效时间窗口（秒）
const COMBO_WINDOW: float = 0.5

## 里程碑间隔（每 N 连击奖励一次）
const MILESTONE_INTERVAL: int = 10

## 里程碑奖励分数
const MILESTONE_BONUS: int = 500

# ============================================================
# 内部状态
# ============================================================

## 当前连击数
var _combo_count: int = 0

## 距离上次击落的计时器
var _combo_timer: float = 0.0

## 是否处于连击状态
var _is_active: bool = false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	add_to_group("combo_manager")
	set_process(true)


func _process(delta: float) -> void:
	if not _is_active:
		return
	_combo_timer += delta
	if _combo_timer >= COMBO_WINDOW:
		_break_combo()


# ============================================================
# 公开方法
# ============================================================

## 注册一次击落（由 EnemyBase / MapObject 死亡时调用）
func register_kill() -> void:
	_combo_count += 1
	_combo_timer = 0.0
	_is_active = true

	# 检查里程碑奖励
	var bonus: int = 0
	if _combo_count > 0 and _combo_count % MILESTONE_INTERVAL == 0:
		bonus = MILESTONE_BONUS
		if GameManager:
			GameManager.add_score(bonus)
		combo_milestone.emit(_combo_count, bonus)

	combo_changed.emit(_combo_count, bonus)


## 玩家被击中时调用（强制中断 Combo）
func on_player_hit() -> void:
	if _is_active:
		_break_combo()


## 重置 Combo（关卡切换 / 玩家死亡时调用）
func reset_combo() -> void:
	if _is_active:
		_break_combo()


## 获取当前连击数
func get_combo_count() -> int:
	return _combo_count


## 获取当前 Combo 进度（0.0~1.0，用于 HUD 进度条）
func get_combo_progress() -> float:
	if not _is_active:
		return 0.0
	# v1.5 修复：clamp 防止 _combo_timer 略超 COMBO_WINDOW 时返回负值
	return clampf(1.0 - (_combo_timer / COMBO_WINDOW), 0.0, 1.0)


# ============================================================
# 内部方法
# ============================================================

## 中断 Combo
func _break_combo() -> void:
	var final_count: int = _combo_count
	combo_broken.emit(final_count)
	_combo_count = 0
	_combo_timer = 0.0
	_is_active = false
