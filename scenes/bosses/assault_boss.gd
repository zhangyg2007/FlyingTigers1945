## AssaultBoss 脚本（v1.5.0 新增）
## 继承 BossBase，专门用于 naval_assault 类型 BOSS（不可击沉舰艇）
## 核心机制：assault_phase（限时摧毁所有部件）
##
## 与 BossBase 的差异：
## 1. 强制 boss_type = "naval_assault"，indestructible = true
## 2. 提供 assault_phase 专用接口（启动/暂停/获取HUD信息）
## 3. 实现退场动画（所有部件摧毁后冒烟离场）
## 4. 集成胜利/失败提示（通过 GameManager 发射信号）
##
## 使用方式：
## - 在 .tscn 场景中挂载此脚本（替代 boss_base.gd）
## - 通过 boss_config_path 指向 naval_assault 类型 JSON
## - JSON 必须包含 parts[] 和 time_limit 字段
class_name AssaultBoss
extends BossBase

# ============================================================
# 导出参数（assault_phase 专用）
# ============================================================
## 退场动画持续时间（秒）
@export var retreat_duration: float = 3.0
## 退场移动速度（像素/秒）
@export var retreat_speed: float = 80.0
## 退场方向（-1 = 向左，1 = 向右，0 = 向上）
@export var retreat_direction_x: float = 1.0
## 退场垂直方向（-1 = 向上，1 = 向下）
@export var retreat_direction_y: float = 0.0

# ============================================================
# 内部状态
# ============================================================
## 是否正在执行退场动画
var _is_retreating: bool = false
## 退场计时器
var _retreat_timer: float = 0.0
## assault_phase 是否已完成（无论胜利/失败）
var _assault_finished: bool = false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	# 强制设置 naval_assault 类型（防止场景配置错误）
	boss_type = TYPE_NAVAL_ASSAULT
	indestructible = true

	# 调用父类 _ready（会加载 JSON 配置、初始化部件、启动状态机）
	super._ready()

	# 连接 assault_phase 信号到本类的处理方法
	if not assault_victory.is_connected(_on_assault_victory):
		assault_victory.connect(_on_assault_victory)
	if not assault_failed.is_connected(_on_assault_failed):
		assault_failed.connect(_on_assault_failed)

	print("[AssaultBoss] 初始化完成: time_limit=%.1f, parts=%d" % [
		_assault_time_limit, _parts_config.size()
	])


func _process(delta: float) -> void:
	# 调用父类 _process（处理难度曲线、部件计时等）
	super._process(delta)

	# 处理退场动画
	if _is_retreating:
		_process_retreat(delta)


# ============================================================
# assault_phase 专用接口
# ============================================================

## 启动 assault_phase（入场完成后由状态机自动调用）
func start_assault() -> void:
	if _assault_active:
		return
	_assault_active = true
	_assault_remaining_time = _assault_time_limit
	print("[AssaultBoss] assault_phase 启动！时限: %.1f 秒，需摧毁 %d 个部件" % [
		_assault_time_limit, _parts_config.size()
	])


## 暂停 assault_phase（用于玩家死亡/暂停时）
func pause_assault() -> void:
	_assault_active = false


## 恢复 assault_phase
func resume_assault() -> void:
	if not _assault_finished and _assault_remaining_time > 0:
		_assault_active = true


## 获取 assault_phase HUD 信息（供 HUD 显示剩余时间+部件进度）
func get_assault_hud_info() -> Dictionary:
	return {
		"active": _assault_active,
		"finished": _assault_finished,
		"time_remaining": _assault_remaining_time,
		"time_total": _assault_time_limit,
		"time_percent": get_assault_time_percent(),
		"parts_destroyed": _destroyed_parts.size(),
		"parts_total": _parts_config.size(),
		"victory": _assault_finished and _destroyed_parts.size() >= _parts_config.size()
	}


# ============================================================
# 退场动画
# ============================================================

## 开始退场动画（assault_phase 结束后调用）
func _start_retreat() -> void:
	_is_retreating = true
	_retreat_timer = retreat_duration
	is_active = false
	# 停止所有部件的碰撞检测
	for part_id in _parts_instances.keys():
		var part: Node = _parts_instances[part_id]
		if is_instance_valid(part):
			part.set_deferred("monitoring", false)
			part.set_deferred("monitorable", false)
	# 停止主 Hitbox 碰撞
	var hitbox: Area2D = get_node_or_null("Hitbox")
	if hitbox != null:
		hitbox.set_deferred("monitoring", false)
	# 冒烟特效（通过 modulate 模拟）
	if _boss_sprite != null:
		_boss_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)
	print("[AssaultBoss] 开始退场动画，持续 %.1f 秒" % retreat_duration)


## 处理退场移动（每帧调用）
func _process_retreat(delta: float) -> void:
	_retreat_timer -= delta
	# 退场移动
	var move_vec := Vector2(retreat_direction_x, retreat_direction_y).normalized()
	global_position += move_vec * retreat_speed * delta

	# 退场结束
	if _retreat_timer <= 0:
		_is_retreating = false
		# 通知 GameManager BOSS 已退场（视为击败）
		if GameManager.has_method("boss_defeated"):
			GameManager.boss_defeated()
		boss_defeated.emit()
		print("[AssaultBoss] 退场完毕，BOSS 离开战场")
		queue_free()


# ============================================================
# 信号处理
# ============================================================

## assault_phase 胜利（限时内摧毁所有部件）
func _on_assault_victory() -> void:
	_assault_finished = true
	_assault_active = false
	print("[AssaultBoss] assault_phase 胜利！所有部件已摧毁，开始退场")
	# 掉落道具（胜利奖励）
	_drop_loot()
	# 开始退场动画
	_start_retreat()


## assault_phase 失败（超时未摧毁所有部件）
func _on_assault_failed() -> void:
	_assault_finished = true
	_assault_active = false
	print("[AssaultBoss] assault_phase 失败！超时未摧毁所有部件，BOSS 撤离")
	# 失败也触发退场（但不掉落道具）
	_start_retreat()


# ============================================================
# override：入场完成后自动启动 assault_phase
# ============================================================

## 覆盖父类 _process_entry 的入场完成处理
## 父类在入场完成后会设置 _assault_active = true（如果 boss_type 匹配）
## 此处确保 start_assault() 被调用以打印日志和初始化
func _process_entry(delta: float) -> void:
	super._process_entry(delta)
	# 入场刚完成时（is_entering 从 true 变为 false），启动 assault_phase
	if not is_entering and not _assault_finished and not _assault_active:
		start_assault()
