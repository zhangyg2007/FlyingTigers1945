## BOSS基类脚本（v1.5.0 重构版）
## 继承 EnemyBase，复用碰撞层/hit/die/_spawn_explosion/_return_to_pool 等方法
## 实现 8 种 BOSS 类型：formation / ace / naval_assault / ground_facility
## / multi_target / mixed / final / environmental
## 碰撞层：Layer4=Enemy，检测 Layer2=PlayerBullet（通过动态创建的 Hitbox Area2D）
## v1.5 核心变更：取消 phase 变身机制，改为 difficulty_curve 时间线性难度曲线 + weak_points 弱点系统
class_name BossBase
extends EnemyBase

# ============================================================
# 信号
# ============================================================
## BOSS被击败时发射
signal boss_defeated()
## BOSS部件被摧毁时发射（参数：part_id）
signal part_destroyed(part_id: String)
## assault_phase 胜利（限时内摧毁所有部件）
signal assault_victory()
## assault_phase 失败（超时未摧毁所有部件）
signal assault_failed()

# ============================================================
# 导出参数 - v1.5 通用配置
# ============================================================
## BOSS 类型（formation/ace/naval_assault/ground_facility/multi_target/mixed/final/environmental）
@export var boss_type: String = "ace"
## 最大生命值（不可击沉时为 -1 或 indestructible=true）
@export var max_hp: int = 350
## 是否不可击沉（naval_assault 类型默认 true）
@export var indestructible: bool = false
## 移动速度
@export var move_speed: float = 60.0
## 敌人弹幕场景路径
@export var bullet_scene: PackedScene = null
## 导弹弹幕场景路径（用于missile_volley模式）
@export var missile_scene: PackedScene = null
## 碰撞伤害值
@export var contact_damage: int = 10
## 入场路径（BOSS从屏幕上方飞入后的目标Y坐标）
@export var entry_target_y: float = 200.0
## BOSS JSON 配置文件路径（可选，加载后会覆盖默认导出值）
@export var boss_config_path: String = ""

# ============================================================
# 内部状态
# ============================================================
## 当前 HP（继承自 EnemyBase）
## 当前时间（用于 difficulty_curve 时间线性插值，秒）
var current_time: float = 0.0
## 当前攻击间隔（由 difficulty_curve 计算）
var current_attack_interval: float = 1.5
## 当前子弹速度倍率（由 difficulty_curve 计算）
var current_bullet_speed_mult: float = 1.0
## 攻击计时器
var attack_timer: float = 0.0
## 是否正在执行入场动画
var is_entering: bool = true
## 是否已激活（入场完成后开始攻击）
var is_active: bool = false
## 螺旋弹幕角度累积
var spiral_angle: float = 0.0
## 定点射击当前炮台索引
var turret_index: int = 0
## 玩家引用
var player_ref: Node2D = null

## 状态机实例（作为子节点加入场景树，由其 _process 自动驱动状态更新）
var _state_machine: StateMachine = null

## BOSS Sprite 引用
var _boss_sprite: Sprite2D = null

## 弹幕参数表（从 JSON bullet_params 字段加载）
var _bullet_params: Dictionary = {}

## 弹幕模式列表（从 JSON bullet_patterns 字段加载）
var _bullet_patterns: Array[String] = []

## 弱点列表（从 JSON weak_points 字段加载）
var _weak_points: Array = []

## 难度曲线配置（从 JSON difficulty_curve 字段加载）
var _difficulty_curve: Dictionary = {}

## 部件配置（从 JSON parts 字段加载，naval_assault/ground_facility 用）
var _parts_config: Array = []

## 部件运行时实例（part_id → Node2D）
var _parts_instances: Dictionary = {}

## 已摧毁部件集合
var _destroyed_parts: Array[String] = []

## assault_phase 时限（naval_assault 类型，秒）
var _assault_time_limit: float = 60.0
## assault_phase 当前剩余时间
var _assault_remaining_time: float = 0.0
## assault_phase 是否已激活
var _assault_active: bool = false

## 召唤配置（从 JSON summon 字段加载）
var _summon_config: Dictionary = {}
## 召唤计时器
var _summon_timer: float = 0.0

## multi_target vessels 配置（从 JSON vessels 字段加载）
var _vessels_config: Array = []
## multi_target 当前激活的 vessel 索引
var _current_vessel_index: int = 0

## mixed/final segments 配置（从 JSON segments 字段加载）
var _segments_config: Array = []
## mixed/final 当前激活的 segment 索引
var _current_segment_index: int = -1
## v1.5 M4-E: mixed/final 当前 segment 的 boss_type（用于 assault_phase 判断）
## 空字符串表示非 mixed/final 类型，使用 boss_type 本身
var _current_segment_boss_type: String = ""

## v1.5 M4-E: multi_target 当前激活的 vessel 配置
var _current_vessel: Dictionary = {}
## v1.5 M4-E: multi_target 已击败的 vessel 数量
var _vessels_defeated_count: int = 0

## 链式爆炸配置（L06 弹药库专用）
var _chain_explosion_config: Dictionary = {}

## 环境效果配置（H1 精英 Ki-44 专用）
var _environment_effects_config: Dictionary = {}

# ============================================================
# 节点引用（软引用：节点不存在时为 null，避免 _ready 中断）
# ============================================================
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hit_flash: Sprite2D = $HitFlash if has_node("HitFlash") else null
## 视觉根节点（用于受击闪烁等效果）
@onready var visual_root: Node2D = $VisualRoot if has_node("VisualRoot") else self

# ============================================================
# 状态名称常量
# ============================================================
const STATE_ENTER := "enter"
const STATE_IDLE := "idle"
const STATE_ATTACK := "attack"
const STATE_DYING := "dying"

# ============================================================
# BOSS 类型常量
# ============================================================
const TYPE_FORMATION := "formation"
const TYPE_ACE := "ace"
const TYPE_NAVAL_ASSAULT := "naval_assault"
const TYPE_GROUND_FACILITY := "ground_facility"
const TYPE_MULTI_TARGET := "multi_target"
const TYPE_MIXED := "mixed"
const TYPE_FINAL := "final"
const TYPE_ENVIRONMENTAL := "environmental"

# ============================================================
# 内部 State 类（StateMachine 接入）
# ============================================================

## 入场状态：处理 BOSS 从屏幕外飞入
class BossStateEnter extends StateMachine.State:
	var boss: BossBase
	func _init(b: BossBase) -> void:
		boss = b
	func update(delta: float) -> void:
		boss._process_entry(delta)

## 待机状态：累积攻击计时器，到时间切换到攻击
class BossStateIdle extends StateMachine.State:
	var boss: BossBase
	func _init(b: BossBase) -> void:
		boss = b
	func update(delta: float) -> void:
		boss._process_idle(delta)

## 攻击状态：执行当前弹幕模式，结束后回到待机
class BossStateAttack extends StateMachine.State:
	var boss: BossBase
	func _init(b: BossBase) -> void:
		boss = b
	func enter(_data: Dictionary = {}) -> void:
		boss._enter_attack()

## 死亡状态：播放死亡动画，发射击败信号，掉落道具，销毁
class BossStateDying extends StateMachine.State:
	var boss: BossBase
	func _init(b: BossBase) -> void:
		boss = b
	func enter(_data: Dictionary = {}) -> void:
		boss._enter_dying()

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	# 加入 "bosses" 组，便于关卡/测试通过 get_nodes_in_group("bosses") 查找
	if not is_in_group("bosses"):
		add_to_group("bosses")

	# 调用父类 _ready：设置碰撞层 Layer4 + mask Layer2+Layer1
	super._ready()

	# 重新设置 mask：BOSS 只检测 Layer2 PlayerBullet（不直接 body 碰撞玩家）
	# 玩家与 BOSS 的接触伤害通过 Hitbox Area2D 处理
	collision_mask = 0
	collision_mask |= (1 << 1)  # Layer2 = PlayerBullet

	# 从 JSON 加载配置（如果指定，会覆盖场景中的导出值）
	if not boss_config_path.is_empty():
		_load_boss_config(boss_config_path)

	# 按 boss_type 初始化（v1.5 核心逻辑）
	_init_by_boss_type()

	# 初始化 HP（current_hp 继承自 EnemyBase；不可击沉时设为 -1）
	if indestructible:
		current_hp = -1
	else:
		current_hp = max_hp

	# 加载默认弹幕场景（如果未指定）
	if bullet_scene == null:
		bullet_scene = load("res://scenes/bullets/bullet_enemy.tscn")

	# 初始化攻击计时器（由 difficulty_curve 计算）
	_update_difficulty_curve(0.0)
	attack_timer = current_attack_interval

	# 查找 BOSS Sprite
	_boss_sprite = _find_sprite(self)

	# 创建 Hitbox Area2D（检测 player bullet 击中 BOSS）
	_create_hitbox()

	# 初始化状态机
	_init_state_machine()

	# 查找玩家
	_find_player()

	# 开始入场
	_enter_stage()


func _process(delta: float) -> void:
	# 完全覆盖 EnemyBase._process（不调用 super._process）
	# EnemyBase._process 做直线下移+弹幕射击+屏幕外归还，BOSS 不需要这些
	# StateMachine 已作为子节点加入场景树，其 _process 会自动调用当前状态的 update
	# 此处只处理 BOSS 自身的每帧逻辑

	# 螺旋角度累积（用于 spiral_shoot 模式，所有状态都累积）
	spiral_angle += delta * 120.0  # 每秒旋转120度

	# 屏幕外保护：防止 BOSS 意外飞出屏幕（正常情况下不会触发，作为安全网）
	var viewport_y: float = get_viewport_rect().size.y
	if global_position.y > viewport_y + 400.0:
		global_position.y = viewport_y - 100.0

	# v1.5: 时间累积 + 难度曲线更新（仅在 BOSS 激活后）
	if is_active:
		current_time += delta
		_update_difficulty_curve(delta)
		# 处理召唤（formation/ace 类型）
		if not _summon_config.is_empty():
			_process_summon(delta)
		# v1.5 M4-E: 处理 assault_phase 计时（使用 effective_boss_type 兼容 mixed/final 的 segment）
		# naval_assault 类型 + 不可击沉 ground_facility 类型
		var effective_type: String = _get_effective_boss_type()
		if _assault_active and (effective_type == TYPE_NAVAL_ASSAULT or (effective_type == TYPE_GROUND_FACILITY and indestructible)):
			_process_assault_phase(delta)


## v1.5 M4-E: 获取当前有效的 boss_type
## mixed/final 类型返回当前 segment 的 boss_type，其他类型返回 boss_type 本身
func _get_effective_boss_type() -> String:
	if not _current_segment_boss_type.is_empty():
		return _current_segment_boss_type
	return boss_type


# ============================================================
# v1.5: 按 boss_type 初始化
# ============================================================

## 按 boss_type 分发到对应的初始化逻辑
func _init_by_boss_type() -> void:
	match boss_type:
		TYPE_FORMATION, TYPE_ACE, TYPE_ENVIRONMENTAL:
			# 可击毁类型：使用 difficulty_curve + weak_points + bullet_patterns
			_init_destructible_boss()
		TYPE_NAVAL_ASSAULT:
			# 不可击沉舰艇：使用 parts + time_limit
			_init_assault_boss()
		TYPE_GROUND_FACILITY:
			# 地面设施：可能可击毁也可能不可击毁，按 indestructible 判断
			if indestructible:
				_init_assault_boss()
			else:
				_init_destructible_boss()
				if not _parts_config.is_empty():
					_init_parts()
		TYPE_MULTI_TARGET:
			# 多目标群：依次激活 vessels
			_init_multi_target_boss()
		TYPE_MIXED, TYPE_FINAL:
			# 多阶段：根据 trigger_y 触发对应 segment（基础框架，详细实现在子类）
			_init_mixed_boss()
		_:
			push_warning("[BOSS] 未知 boss_type: %s，回退到 ace 类型" % boss_type)
			boss_type = TYPE_ACE
			_init_destructible_boss()


## 初始化可击毁 BOSS（formation/ace/ground_facility/final/environmental）
func _init_destructible_boss() -> void:
	# 弹幕模式已从 JSON 加载到 _bullet_patterns
	# weak_points 已从 JSON 加载到 _weak_points
	# difficulty_curve 已从 JSON 加载到 _difficulty_curve
	# summon 已从 JSON 加载到 _summon_config
	if _summon_config.size() > 0:
		_summon_timer = float(_summon_config.get("interval", 15.0))
	print("[BOSS] 初始化可击毁 BOSS: type=%s, HP=%d, patterns=%d, weak_points=%d" % [
		boss_type, max_hp, _bullet_patterns.size(), _weak_points.size()
	])


## 初始化 assault_phase BOSS（naval_assault/不可击沉 ground_facility）
func _init_assault_boss() -> void:
	# parts 配置已从 JSON 加载到 _parts_config
	# 创建部件实例
	_init_parts()
	# 初始化 assault_phase 计时
	if _parts_config.size() > 0:
		# time_limit 从 JSON 加载到 _assault_time_limit
		_assault_remaining_time = _assault_time_limit
	print("[BOSS] 初始化 assault_phase BOSS: type=%s, parts=%d, time_limit=%.1f" % [
		boss_type, _parts_config.size(), _assault_time_limit
	])


## 初始化 multi_target BOSS
func _init_multi_target_boss() -> void:
	# vessels 配置已从 JSON 加载到 _vessels_config
	_current_vessel_index = 0
	_vessels_defeated_count = 0
	# v1.5 M4-E: 应用第一个 vessel 配置（HP/sprite/bullet_pattern）
	if _vessels_config.size() > 0:
		_apply_vessel(_vessels_config[0])
	print("[BOSS] 初始化 multi_target BOSS: vessels=%d" % _vessels_config.size())


## 初始化 mixed/final BOSS（多阶段）
func _init_mixed_boss() -> void:
	# segments 配置已从 JSON 加载到 _segments_config
	_current_segment_index = 0
	if _segments_config.size() > 0:
		# v1.5 M4-E: 应用第一个 segment（包含 boss_type 和 config）
		_apply_segment(_segments_config[0])
	print("[BOSS] 初始化 mixed/final BOSS: segments=%d, current=%d" % [
		_segments_config.size(), _current_segment_index
	])


## v1.5 M4-E: 应用 segment 到当前 BOSS（mixed/final 类型用）
## 设置 _current_segment_boss_type 并调用 _apply_segment_config 应用 config
func _apply_segment(segment: Dictionary) -> void:
	_current_segment_boss_type = String(segment.get("boss_type", boss_type))
	var segment_config: Dictionary = segment.get("config", {})
	_apply_segment_config(segment_config)


## 应用 segment 配置到当前 BOSS（用于 mixed/final 类型切换阶段）
func _apply_segment_config(segment_config: Dictionary) -> void:
	if segment_config.has("max_hp"):
		max_hp = int(segment_config["max_hp"])
	if segment_config.has("indestructible"):
		indestructible = bool(segment_config["indestructible"])
	if segment_config.has("move_speed"):
		move_speed = float(segment_config["move_speed"])
	if segment_config.has("entry_target_y"):
		entry_target_y = float(segment_config["entry_target_y"])
	if segment_config.has("contact_damage"):
		contact_damage = int(segment_config["contact_damage"])
	if segment_config.has("sprite"):
		var sprite_path: String = segment_config["sprite"]
		if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			if _boss_sprite != null:
				_boss_sprite.texture = load(sprite_path)
			else:
				# _boss_sprite 尚未初始化（_ready 早期），存入 metadata 供 _finish_entry 应用
				set_meta("sprite_path", sprite_path)
	if segment_config.has("weak_points"):
		_weak_points = segment_config["weak_points"]
	else:
		_weak_points = []
	if segment_config.has("difficulty_curve"):
		var dc = segment_config["difficulty_curve"] as Dictionary
		_difficulty_curve = dc if dc != null else {}
	else:
		_difficulty_curve = {}
	if segment_config.has("bullet_patterns"):
		_bullet_patterns.clear()
		for p in segment_config["bullet_patterns"]:
			_bullet_patterns.append(String(p))
	else:
		_bullet_patterns.clear()
	if segment_config.has("summon"):
		var sc = segment_config["summon"] as Dictionary
		_summon_config = sc if sc != null else {}
	else:
		_summon_config = {}
	if segment_config.has("parts"):
		_parts_config = segment_config["parts"]
		_init_parts()
	else:
		# v1.5 M4-E: 清理上一个 segment 的部件配置和实例
		_parts_config = []
		for part_id in _parts_instances.keys():
			var part: Node = _parts_instances[part_id]
			if is_instance_valid(part):
				part.queue_free()
		_parts_instances.clear()
		_destroyed_parts.clear()
	# v1.5 M4-E: 加载 segment 级别的 time_limit（naval_assault segment 用）
	if segment_config.has("time_limit"):
		_assault_time_limit = float(segment_config["time_limit"])
		_assault_remaining_time = _assault_time_limit


## v1.5 M4-E: 应用 vessel 配置到当前 BOSS（multi_target 类型用）
## 每个 vessel 有独立的 HP/sprite/bullet_pattern
func _apply_vessel(vessel: Dictionary) -> void:
	_current_vessel = vessel
	var vessel_hp: int = int(vessel.get("hp", 3000))
	max_hp = vessel_hp
	# multi_target 的 vessel 是可击毁的（覆盖 JSON 顶层的 indestructible=true）
	indestructible = false
	# 更新 sprite（_boss_sprite 在 _ready 后才可用，切换 vessel 时已可用）
	var sprite_path: String = String(vessel.get("sprite", ""))
	if not sprite_path.is_empty() and _boss_sprite != null and ResourceLoader.exists(sprite_path):
		_boss_sprite.texture = load(sprite_path)
	elif not sprite_path.is_empty() and _boss_sprite == null:
		# 早期初始化：存入 metadata 供 _finish_entry 应用
		set_meta("sprite_path", sprite_path)
	# 设置该 vessel 的弹幕模式
	_bullet_patterns.clear()
	var pattern: String = String(vessel.get("bullet_pattern", ""))
	if not pattern.is_empty():
		_bullet_patterns.append(pattern)
	print("[BOSS] 应用 vessel: %s (HP=%d, pattern=%s)" % [
		vessel.get("name", "未知"), vessel_hp, pattern
	])


# ============================================================
# v1.5: 难度曲线系统
# ============================================================

## 根据时间更新 difficulty_curve 参数
## 计算 current_attack_interval 和 current_bullet_speed_mult
func _update_difficulty_curve(delta: float) -> void:
	if _difficulty_curve.is_empty():
		# 未配置 difficulty_curve，使用默认值
		current_attack_interval = 1.5
		current_bullet_speed_mult = 1.0
		return

	var ramp_duration: float = float(_difficulty_curve.get("ramp_duration", 60.0))
	var progress: float = clamp(current_time / ramp_duration, 0.0, 1.0) if ramp_duration > 0.0 else 1.0

	var interval_start: float = float(_difficulty_curve.get("attack_interval_start", 1.5))
	var interval_end: float = float(_difficulty_curve.get("attack_interval_end", 0.6))
	current_attack_interval = lerpf(interval_start, interval_end, progress)

	var speed_start: float = float(_difficulty_curve.get("bullet_speed_mult_start", 1.0))
	var speed_end: float = float(_difficulty_curve.get("bullet_speed_mult_end", 1.8))
	current_bullet_speed_mult = lerpf(speed_start, speed_end, progress)


# ============================================================
# v1.5: 弱点系统
# ============================================================

## 检查子弹击中位置是否在弱点区域
## 返回伤害倍率（1.0 表示无弱点加成）
func _get_weak_point_damage_mult(hit_position: Vector2) -> float:
	if _weak_points.is_empty():
		return 1.0

	# 将世界坐标转换为 BOSS 本地坐标
	var local_pos: Vector2 = to_local(hit_position)
	for wp in _weak_points:
		var region: Dictionary = wp.get("region", {})
		var rx: float = float(region.get("x", 0))
		var ry: float = float(region.get("y", 0))
		var rw: float = float(region.get("w", 0))
		var rh: float = float(region.get("h", 0))
		# 矩形区域检测
		if local_pos.x >= rx and local_pos.x <= rx + rw \
			and local_pos.y >= ry and local_pos.y <= ry + rh:
			return float(wp.get("damage_mult", 1.0))
	return 1.0


# ============================================================
# v1.5: 部件系统（naval_assault / ground_facility 用）
# ============================================================

## 初始化部件实例（创建子 Area2D 节点作为部件）
func _init_parts() -> void:
	# 清理已有部件
	for part_id in _parts_instances.keys():
		var part: Node = _parts_instances[part_id]
		if is_instance_valid(part):
			part.queue_free()
	_parts_instances.clear()
	_destroyed_parts.clear()

	# 按 _parts_config 创建部件
	for part_config in _parts_config:
		var part_id: String = String(part_config.get("part_id", ""))
		if part_id.is_empty():
			continue
		var part_node: Area2D = _create_part_node(part_config)
		if part_node != null:
			_parts_instances[part_id] = part_node
			add_child(part_node)


## 创建单个部件节点（Area2D + Sprite + CollisionShape）
func _create_part_node(part_config: Dictionary) -> Area2D:
	var part_node := Area2D.new()
	part_node.name = "Part_" + String(part_config.get("part_id", "unknown"))

	# 部件位置
	var pos: Dictionary = part_config.get("position", {})
	part_node.position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))

	# 部件 HP（通过 metadata 存储）
	var part_hp: int = int(part_config.get("hp", 100))
	part_node.set_meta("part_hp", part_hp)
	part_node.set_meta("part_max_hp", part_hp)
	part_node.set_meta("part_id", String(part_config.get("part_id", "")))
	part_node.set_meta("part_name", String(part_config.get("name", "")))
	part_node.set_meta("is_weak_point", bool(part_config.get("is_weak_point", false)))

	# 部件 Sprite
	var sprite_path: String = String(part_config.get("sprite", ""))
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var sprite := Sprite2D.new()
		sprite.texture = load(sprite_path)
		part_node.add_child(sprite)

	# 部件 CollisionShape2D（默认 60x60 矩形）
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	part_node.add_child(collision)

	# 部件碰撞层：Layer4 = Enemy，mask Layer2 = PlayerBullet
	part_node.collision_layer = 1 << 3  # Layer4
	part_node.collision_mask = 1 << 1    # Layer2 = PlayerBullet

	# 连接 area_entered 信号到部件受伤处理
	part_node.area_entered.connect(_on_part_area_entered.bind(part_node))

	return part_node


## 部件被子弹击中时的处理
func _on_part_area_entered(area: Area2D, part_node: Area2D) -> void:
	# 检查是否为玩家子弹（Layer2）
	if not area.get_collision_layer_value(2):
		return
	# 获取子弹伤害值
	var damage: int = 1
	if "damage" in area:
		damage = int(area["damage"])
	# 检查部件是否为弱点（额外伤害倍率）
	var is_weak_point: bool = part_node.get_meta("is_weak_point", false)
	if is_weak_point:
		damage = int(damage * 2.0)
	# 应用伤害到部件
	_damage_part(part_node, damage)
	# 子弹命中后销毁
	if area.has_method("_destroy"):
		area._destroy()
	else:
		area.queue_free()


## 对部件造成伤害
func _damage_part(part_node: Area2D, damage: int) -> void:
	if not is_instance_valid(part_node):
		return
	var part_id: String = part_node.get_meta("part_id", "")
	if part_id in _destroyed_parts:
		return  # 已摧毁

	var current_part_hp: int = int(part_node.get_meta("part_hp", 0))
	current_part_hp -= damage
	part_node.set_meta("part_hp", current_part_hp)

	print("[BOSS] 部件 %s 受到 %d 伤害，剩余HP: %d/%d" % [
		part_id, damage, current_part_hp, int(part_node.get_meta("part_max_hp", 0))
	])

	if current_part_hp <= 0:
		_destroy_part(part_node, part_id)


## 摧毁部件
func _destroy_part(part_node: Area2D, part_id: String) -> void:
	if part_id in _destroyed_parts:
		return
	_destroyed_parts.append(part_id)
	part_destroyed.emit(part_id)
	print("[BOSS] 部件 %s 已摧毁" % part_id)

	# 部件爆炸特效
	var part_pos: Vector2 = part_node.global_position
	_spawn_explosion_at(part_pos)

	# 隐藏部件节点
	part_node.visible = false
	part_node.set_deferred("monitoring", false)

	# 检查是否所有部件都摧毁（assault_phase 胜利条件）
	_check_assault_victory()


## 检查 assault_phase 胜利条件
func _check_assault_victory() -> void:
	if _parts_config.is_empty():
		return
	# v1.5 M4-E: 仅对不可击沉 BOSS（assault_phase）检查部件摧毁胜利条件
	# 可击沉的 ground_facility（如 mixed BOSS 的 airport_tower segment）通过主体 HP 归零结束
	if not indestructible:
		return
	if _destroyed_parts.size() >= _parts_config.size():
		# 所有部件已摧毁
		_assault_active = false
		assault_victory.emit()
		print("[BOSS] assault_phase 胜利！所有部件已摧毁")
		# v1.5 M4-E: mixed/final BOSS 检查是否有下一个 segment
		if (boss_type == TYPE_MIXED or boss_type == TYPE_FINAL) and \
			_current_segment_index + 1 < _segments_config.size():
			_switch_to_next_segment()
			return
		# v1.5 修复：naval_assault 类型由 _on_assault_victory -> _start_retreat 处理退场+queue_free
		# 不走 STATE_DYING 路径，避免 boss_defeated/_drop_loot 重复触发和 queue_free 抢先
		# 非 naval_assault 的 indestructible ground_facility（如 boss_kinu）仍走 STATE_DYING
		if boss_type != TYPE_NAVAL_ASSAULT:
			_state_machine.transition_to(STATE_DYING)


## v1.5 M4-E: 切换到下一个 segment（mixed/final 类型用）
## 清理当前部件、应用下一个 segment 配置、重置 HP 和状态
func _switch_to_next_segment() -> void:
	_current_segment_index += 1
	if _current_segment_index >= _segments_config.size():
		# 没有更多 segment，BOSS 死亡
		print("[BOSS] 所有 segment 已完成，BOSS 死亡")
		_state_machine.transition_to(STATE_DYING)
		return

	var next_segment: Dictionary = _segments_config[_current_segment_index]
	var segment_name: String = String(next_segment.get("segment_name", "未知"))
	print("[BOSS] 切换到下一个 segment: %s (index=%d)" % [segment_name, _current_segment_index])

	# 清理当前部件实例
	for part_id in _parts_instances.keys():
		var part: Node = _parts_instances[part_id]
		if is_instance_valid(part):
			part.queue_free()
	_parts_instances.clear()
	_destroyed_parts.clear()

	# 应用下一个 segment 的配置（会设置 _current_segment_boss_type、indestructible、parts 等）
	_apply_segment(next_segment)

	# 重置 HP（基于新 segment 的配置）
	if indestructible:
		current_hp = -1
	else:
		current_hp = max_hp

	# 重置难度曲线时间和攻击计时器
	current_time = 0.0
	_update_difficulty_curve(0.0)
	attack_timer = current_attack_interval

	# 重置 assault_phase 状态
	_assault_active = false
	# 如果新 segment 是 naval_assault 或不可击沉 ground_facility，激活 assault_phase
	var effective_type: String = _get_effective_boss_type()
	if effective_type == TYPE_NAVAL_ASSAULT or \
		(effective_type == TYPE_GROUND_FACILITY and indestructible):
		_assault_active = true
		print("[BOSS] 新 segment 激活 assault_phase: 时限=%.1f, 部件=%d" % [
			_assault_time_limit, _parts_config.size()
		])

	# 通知 HUD segment 切换（通过 GameManager 信号）
	if GameManager and GameManager.has_signal("event_alert"):
		GameManager.event_alert.emit("进入: %s" % segment_name)

	# 状态机回到 IDLE（继续攻击新 segment）
	if _state_machine != null and not _state_machine.is_in_state(STATE_IDLE):
		_state_machine.transition_to(STATE_IDLE)

	# 短暂受击闪烁，给玩家视觉反馈
	_flash_white()


## v1.5 M4-E: 切换到下一个 vessel（multi_target 类型用）
## 给予分数奖励、应用下一个 vessel 配置
func _switch_to_next_vessel() -> void:
	_vessels_defeated_count += 1

	# 给予当前 vessel 的分数奖励
	var vessel_score: int = int(_current_vessel.get("score", 0))
	if vessel_score > 0 and GameManager and GameManager.has_method("add_score"):
		GameManager.add_score(vessel_score)
		print("[BOSS] vessel 被击沉: %s，奖励 %d 分" % [
			_current_vessel.get("name", "未知"), vessel_score
		])

	_current_vessel_index += 1
	if _current_vessel_index >= _vessels_config.size():
		# 所有 vessel 已击败，BOSS 死亡
		print("[BOSS] 所有 vessel 已被击沉，BOSS 死亡")
		_state_machine.transition_to(STATE_DYING)
		return

	var next_vessel: Dictionary = _vessels_config[_current_vessel_index]
	print("[BOSS] 切换到下一个 vessel: %d/%d" % [_current_vessel_index + 1, _vessels_config.size()])
	_apply_vessel(next_vessel)

	# 重置 HP（_apply_vessel 已设置 max_hp）
	current_hp = max_hp

	# 重置难度曲线时间
	current_time = 0.0
	_update_difficulty_curve(0.0)
	attack_timer = current_attack_interval

	# 通知 HUD
	if GameManager and GameManager.has_signal("event_alert"):
		var vessel_name: String = String(_current_vessel.get("name", ""))
		if not vessel_name.is_empty():
			GameManager.event_alert.emit("遭遇: %s" % vessel_name)

	# 状态机回到 IDLE
	if _state_machine != null and not _state_machine.is_in_state(STATE_IDLE):
		_state_machine.transition_to(STATE_IDLE)

	# 短暂受击闪烁
	_flash_white()


## 处理 assault_phase 计时（每帧调用）
func _process_assault_phase(delta: float) -> void:
	if not _assault_active:
		return
	_assault_remaining_time -= delta
	if _assault_remaining_time <= 0:
		_assault_remaining_time = 0
		_assault_active = false
		assault_failed.emit()
		print("[BOSS] assault_phase 失败！超时未摧毁所有部件")
		# v1.5 修复：同 _check_assault_victory，naval_assault 类型由 _on_assault_failed 处理退场
		if boss_type != TYPE_NAVAL_ASSAULT:
			_state_machine.transition_to(STATE_DYING)


## 获取 assault_phase 剩余时间百分比（用于 HUD 显示）
func get_assault_time_percent() -> float:
	if _assault_time_limit <= 0:
		return 0.0
	return _assault_remaining_time / _assault_time_limit


## 获取已摧毁部件数 / 总部件数
func get_parts_progress() -> Dictionary:
	return {
		"destroyed": _destroyed_parts.size(),
		"total": _parts_config.size()
	}


# ============================================================
# v1.5: 召唤系统（formation / ace 类型）
# ============================================================

## 处理召唤逻辑（每帧调用）
func _process_summon(delta: float) -> void:
	if _summon_config.is_empty():
		return
	_summon_timer -= delta
	if _summon_timer <= 0:
		_summon_timer = float(_summon_config.get("interval", 15.0))
		_do_summon()


## 执行召唤
func _do_summon() -> void:
	var enemy_type: String = String(_summon_config.get("type", ""))
	var count: int = int(_summon_config.get("count", 2))
	if enemy_type.is_empty() or count <= 0:
		return
	# 通过 SpawnManager 召唤敌机（如果可用）
	if GameManager.has_method("get_spawn_manager"):
		var spawn_manager = GameManager.get_spawn_manager()
		if spawn_manager and spawn_manager.has_method("spawn_enemy_at_position"):
			for i in range(count):
				var offset_x: float = (i - count / 2.0) * 60.0
				var spawn_pos: Vector2 = global_position + Vector2(offset_x, -80)
				spawn_manager.spawn_enemy_at_position(enemy_type, spawn_pos)
			print("[BOSS] 召唤 %d 架 %s" % [count, enemy_type])
			return
	# 回退：直接通过场景树查找敌人场景并实例化
	print("[BOSS] SpawnManager 不可用，跳过召唤 %s x%d" % [enemy_type, count])


# ============================================================
# 状态机初始化
# ============================================================

func _init_state_machine() -> void:
	_state_machine = StateMachine.new()
	add_child(_state_machine)
	_state_machine.add_state(STATE_ENTER, BossStateEnter.new(self))
	_state_machine.add_state(STATE_IDLE, BossStateIdle.new(self))
	_state_machine.add_state(STATE_ATTACK, BossStateAttack.new(self))
	_state_machine.add_state(STATE_DYING, BossStateDying.new(self))
	_state_machine.initialize(STATE_ENTER)
	print("[BOSS] 状态机初始化完成，boss_type=%s，当前状态: %s" % [boss_type, _state_machine.current_state_name()])


func _process_idle(delta: float) -> void:
	# 攻击计时器更新（使用 difficulty_curve 计算的 current_attack_interval）
	attack_timer -= delta
	if attack_timer <= 0.0:
		_state_machine.transition_to(STATE_ATTACK)


func _enter_attack() -> void:
	# 执行当前弹幕模式
	_execute_bullet_patterns()
	# 重置计时器为当前攻击间隔（由 difficulty_curve 计算）
	attack_timer = current_attack_interval
	# 攻击完成后回到待机状态
	_state_machine.transition_to(STATE_IDLE)


func _enter_dying() -> void:
	is_active = false

	# 播放死亡动画/爆炸
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	else:
		_spawn_explosion()

	# 发射击败信号
	boss_defeated.emit()

	# 通知GameManager
	if GameManager.has_method("boss_defeated"):
		GameManager.boss_defeated()

	print("[BOSS] 已被击败! type=%s" % boss_type)

	# 掉落道具
	_drop_loot()

	# v1.5 C18: 通用退场动画（淡出 + 缩放，让死亡更有视觉反馈）
	# naval_assault 类型由 AssaultBoss._start_retreat 处理，不在此处重复
	if boss_type != TYPE_NAVAL_ASSAULT:
		_play_death_retreat_animation()
		await get_tree().create_timer(0.6).timeout

	# 延迟后移除
	queue_free()


## v1.5 C18: 通用死亡退场动画
## 淡出 + 轻微缩放 + 短暂旋转，给玩家"BOSS 已被消灭"的视觉反馈
func _play_death_retreat_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	# 淡出
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	# 轻微放大后收缩
	tween.tween_property(self, "scale", scale * 1.2, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", scale * 0.8, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 关闭碰撞检测（防止退场期间继续受伤）
	var hitbox: Area2D = get_node_or_null("Hitbox")
	if hitbox != null:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

# ============================================================
# Hitbox Area2D（检测 player bullet 击中 BOSS）
# ============================================================

## 动态创建 Hitbox Area2D 子节点
func _create_hitbox() -> void:
	if has_node("Hitbox"):
		return  # 已存在

	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2   # 检测 Layer2 = PlayerBullet

	# 创建碰撞形状（与主 CollisionShape2D 相同大小）
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		var main_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
		var shape := RectangleShape2D.new()
		shape.size = main_shape.size
		var hitbox_shape := CollisionShape2D.new()
		hitbox_shape.shape = shape
		hitbox.add_child(hitbox_shape)
	elif collision_shape != null and collision_shape.shape is CircleShape2D:
		var main_shape: CircleShape2D = collision_shape.shape as CircleShape2D
		var shape := CircleShape2D.new()
		shape.radius = main_shape.radius
		var hitbox_shape := CollisionShape2D.new()
		hitbox_shape.shape = shape
		hitbox.add_child(hitbox_shape)

	# 连接 area_entered 信号到受伤处理
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	add_child(hitbox)


## Hitbox 检测到 player bullet 时调用
func _on_hitbox_area_entered(area: Area2D) -> void:
	# 不可击沉 BOSS 不响应主体伤害（部件受伤由 _on_part_area_entered 处理）
	if indestructible:
		return
	# 检查是否为玩家子弹（Layer2）
	if not area.get_collision_layer_value(2):
		return
	# 获取子弹伤害值
	var damage: int = 1
	if "damage" in area:
		damage = int(area["damage"])
	# v1.5: 检查弱点倍率（使用子弹位置）
	var weak_point_mult: float = _get_weak_point_damage_mult(area.global_position)
	damage = int(damage * weak_point_mult)
	# 应用伤害
	take_damage(damage)
	# 子弹命中后销毁
	if area.has_method("_destroy"):
		area._destroy()
	else:
		area.queue_free()

# ============================================================
# JSON 配置加载（v1.5 新格式）
# ============================================================

## 从 JSON 文件加载 BOSS 配置（v1.5 新格式）
func _load_boss_config(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[BOSS] 配置文件不存在: %s" % path)
		return
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_warning("[BOSS] 配置文件为空: %s" % path)
		return
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("[BOSS] 配置文件解析失败: %s (行 %d: %s)" % [path, json.get_error_line(), json.get_error_message()])
		return
	var data: Dictionary = json.data

	# 加载通用字段
	if data.has("boss_id"):
		# boss_id 仅用于日志，不覆盖类名
		pass
	if data.has("boss_type"):
		boss_type = String(data["boss_type"])
	if data.has("max_hp"):
		max_hp = int(data["max_hp"])
	if data.has("indestructible"):
		indestructible = bool(data["indestructible"])
	if data.has("move_speed"):
		move_speed = float(data["move_speed"])
	if data.has("contact_damage"):
		contact_damage = int(data["contact_damage"])
	if data.has("entry_target_y"):
		entry_target_y = float(data["entry_target_y"])
	if data.has("drop_count"):
		# drop_count 不作为导出变量，存储到 metadata
		set_meta("drop_count", int(data["drop_count"]))

	# 加载 sprite（如果有 BOSS Sprite 节点则替换纹理）
	if data.has("sprite"):
		var sprite_path: String = String(data["sprite"])
		if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			# 延迟加载（_boss_sprite 在 _ready 中查找）
			set_meta("sprite_path", sprite_path)

	# v1.5: 加载弹幕参数表
	if data.has("bullet_params"):
		# v1.5 修复：as Dictionary 类型不匹配时返回 null，后续 .is_empty() 崩溃；增加 null 兜底
		var bp = data["bullet_params"] as Dictionary
		_bullet_params = bp if bp != null else {}

	# v1.5: 加载弹幕模式列表
	if data.has("bullet_patterns"):
		_bullet_patterns.clear()
		for p in data["bullet_patterns"]:
			_bullet_patterns.append(String(p))

	# v1.5: 加载弱点列表
	if data.has("weak_points"):
		_weak_points = data["weak_points"]

	# v1.5: 加载难度曲线
	if data.has("difficulty_curve"):
		var dc = data["difficulty_curve"] as Dictionary
		_difficulty_curve = dc if dc != null else {}

	# v1.5: 加载部件配置（naval_assault/ground_facility）
	if data.has("parts"):
		_parts_config = data["parts"]

	# v1.5: 加载 assault_phase 时限
	if data.has("time_limit"):
		_assault_time_limit = float(data["time_limit"])

	# v1.5: 加载召唤配置
	if data.has("summon"):
		var sc = data["summon"] as Dictionary
		_summon_config = sc if sc != null else {}

	# v1.5: 加载 multi_target vessels 配置
	if data.has("vessels"):
		_vessels_config = data["vessels"]

	# v1.5: 加载 mixed/final segments 配置
	if data.has("segments"):
		_segments_config = data["segments"]

	# v1.5: 加载 chain_explosion 配置
	if data.has("chain_explosion"):
		var ce = data["chain_explosion"] as Dictionary
		_chain_explosion_config = ce if ce != null else {}

	# v1.5: 加载 environment_effects 配置
	if data.has("environment_effects"):
		var ee = data["environment_effects"] as Dictionary
		_environment_effects_config = ee if ee != null else {}

	print("[BOSS] 已加载 v1.5 配置: %s (type=%s, HP=%d, patterns=%d, parts=%d)" % [
		path, boss_type, max_hp, _bullet_patterns.size(), _parts_config.size()
	])


## 获取弹幕参数（带默认值回退）
func _get_bullet_param(pattern: String, key: String, default_value: Variant) -> Variant:
	if _bullet_params.has(pattern):
		var params: Dictionary = _bullet_params[pattern]
		if params.has(key):
			return params[key]
	return default_value


# ============================================================
# 入场逻辑
# ============================================================

## BOSS入场：从屏幕外飞入到目标位置
func _enter_stage() -> void:
	is_entering = true
	# 设置初始位置在屏幕上方
	global_position = Vector2(
		get_viewport_rect().size.x / 2.0,
		-entry_target_y
	)
	# 播放入场动画（如果有）
	if animation_player and animation_player.has_animation("enter"):
		animation_player.play("enter")


## 处理入场移动（由 BossStateEnter.update 调用）
func _process_entry(delta: float) -> void:
	var target_pos := Vector2(
		get_viewport_rect().size.x / 2.0,
		entry_target_y
	)

	# v1.5 修复：静态 BOSS（move_speed=0）直接传送到目标位置，避免卡死在屏幕外
	if move_speed <= 0.1:
		global_position = target_pos
		_finish_entry(target_pos)
		return

	# 向目标位置移动
	var direction := (target_pos - global_position).normalized()
	var distance := global_position.distance_to(target_pos)

	if distance < 5.0:
		_finish_entry(target_pos)
	else:
		global_position += direction * move_speed * 1.5 * delta


## 入场完成处理（抽取为独立方法，供 move_speed=0 和正常入场共用）
func _finish_entry(target_pos: Vector2) -> void:
	global_position = target_pos
	is_entering = false
	is_active = true
	# 应用 sprite（如果在 JSON 中配置）
	var sprite_path: String = get_meta("sprite_path", "")
	if not sprite_path.is_empty() and _boss_sprite != null:
		_boss_sprite.texture = load(sprite_path)
	if animation_player and animation_player.is_playing():
		animation_player.stop()
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	# 激活 assault_phase（如果是 naval_assault 类型）
	# v1.5 M4-E: 使用 effective_boss_type 兼容 mixed/final 的 naval_assault segment
	var effective_type: String = _get_effective_boss_type()
	if effective_type == TYPE_NAVAL_ASSAULT or \
		(effective_type == TYPE_GROUND_FACILITY and indestructible):
		_assault_active = true
	# 切换到待机状态
	_state_machine.transition_to(STATE_IDLE)

# ============================================================
# 受伤与死亡
# ============================================================

## 受到伤害（v1.5 重构：移除 phase 转换逻辑）
func take_damage(amount: int) -> void:
	if is_entering:
		return
	if indestructible:
		return  # 不可击沉 BOSS 不响应主体伤害
	# v1.5 修复：STATE_DYING 期间不再受伤害，防止死亡动画期间 HP 被推到负值和重复闪烁
	if _state_machine != null and _state_machine.is_in_state(STATE_DYING):
		return

	current_hp -= amount

	# 受击闪烁
	_flash_white()

	# 检查死亡
	if current_hp <= 0:
		current_hp = 0
		# v1.5 M4-E: multi_target BOSS 检查是否有下一个 vessel
		if boss_type == TYPE_MULTI_TARGET and _current_vessel_index + 1 < _vessels_config.size():
			_switch_to_next_vessel()
			return
		# v1.5 M4-E: mixed/final BOSS 检查是否有下一个 segment
		# （非 assault_phase 死亡情况，如 ace segment HP 归零）
		if (boss_type == TYPE_MIXED or boss_type == TYPE_FINAL) and \
			_current_segment_index + 1 < _segments_config.size():
			_switch_to_next_segment()
			return
		_state_machine.transition_to(STATE_DYING)
		return

	print("[BOSS] 受到 %d 伤害，剩余HP: %d/%d" % [amount, current_hp, max_hp])


## override EnemyBase.hit()，让 Area2D 碰撞也走 take_damage 流程
func hit(damage: int) -> void:
	take_damage(damage)


## 受击红色闪烁
func _flash_white() -> void:
	if hit_flash:
		hit_flash.visible = true
		hit_flash.modulate = Color(1, 0.2, 0.2, 0.8)
		var tween := create_tween()
		tween.tween_property(hit_flash, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): hit_flash.visible = false)
	else:
		if _boss_sprite != null:
			var original_color = _boss_sprite.modulate
			_boss_sprite.modulate = Color(1, 0.3, 0.3, 1)
			var tween := create_tween()
			tween.tween_property(_boss_sprite, "modulate", original_color, 0.12)


## 生成爆炸效果（覆盖 EnemyBase._spawn_explosion，使用对象池）
func _spawn_explosion() -> void:
	var explosion_scene_path: String = "res://scenes/effects/explosion_large.tscn"
	var explosion: Node = null
	if PoolManager.has_method("get_object_by_path"):
		explosion = PoolManager.get_object_by_path(explosion_scene_path)
	if explosion == null:
		var explosion_scene = load(explosion_scene_path)
		if explosion_scene == null:
			return
		explosion = explosion_scene.instantiate()

	if explosion != null:
		explosion.global_position = global_position
		if explosion.get_parent() == null:
			get_parent().add_child(explosion)


## 在指定位置生成爆炸（用于部件摧毁）
func _spawn_explosion_at(pos: Vector2) -> void:
	var explosion_scene_path: String = "res://scenes/effects/explosion_large.tscn"
	var explosion: Node = null
	if PoolManager.has_method("get_object_by_path"):
		explosion = PoolManager.get_object_by_path(explosion_scene_path)
	if explosion == null:
		var explosion_scene = load(explosion_scene_path)
		if explosion_scene == null:
			return
		explosion = explosion_scene.instantiate()

	if explosion != null:
		explosion.global_position = pos
		if explosion.get_parent() == null:
			get_parent().add_child(explosion)


## 掉落战利品
func _drop_loot() -> void:
	# 从 metadata 读取 drop_count（由 JSON 配置）
	var drop_count: int = int(get_meta("drop_count", 3))
	var powerup_scene = load("res://scenes/powerups/powerup.tscn")
	if powerup_scene == null:
		return

	for i in range(drop_count):
		var offset := Vector2((i - drop_count / 2.0) * 30.0, 0)
		var item = powerup_scene.instantiate()
		item.global_position = global_position + offset
		get_parent().add_child(item)


## 玩家与BOSS碰撞时的接触伤害处理
func _on_body_entered(body: Node) -> void:
	if body is Node2D and body.has_method("take_damage") and body.collision_layer & (1 << 0):
		body.take_damage(contact_damage)

# ============================================================
# 弹幕攻击系统（v1.5 重构：使用 bullet_patterns 而非 phase_bullets）
# ============================================================

## 执行当前所有弹幕模式
func _execute_bullet_patterns() -> void:
	if _bullet_patterns.is_empty():
		# 回退默认：fan_shoot
		fan_shoot()
		return
	for pattern_name in _bullet_patterns:
		_match_attack_pattern(pattern_name)


## 根据模式名称匹配执行对应的弹幕函数
func _match_attack_pattern(pattern_name: String) -> void:
	match pattern_name:
		"fan_shoot":
			fan_shoot()
		"turret_fire":
			turret_fire()
		"missile_volley":
			missile_volley()
		"spiral_shoot":
			spiral_shoot()
		"aimed_shoot":
			aimed_shoot()
		_:
			push_warning("[BOSS] 未知弹幕模式: %s" % pattern_name)


## 创建一颗敌方子弹
func _spawn_bullet(pos: Vector2, dir: Vector2, speed: float, damage: int = 1) -> void:
	if bullet_scene == null:
		return

	# v1.5: 应用 difficulty_curve 的子弹速度倍率
	speed *= current_bullet_speed_mult

	var bullet: Node2D = null
	# 优先通过对象池获取
	if PoolManager.has_method("get_object"):
		bullet = PoolManager.get_object(bullet_scene) as Node2D
	# 对象池不可用或池满，回退直接实例化
	if bullet == null:
		bullet = bullet_scene.instantiate()
		if bullet.get_parent() == null:
			get_parent().add_child(bullet)

	bullet.global_position = pos
	if "direction" in bullet:
		bullet["direction"] = dir.normalized()
	if "speed" in bullet:
		bullet["speed"] = speed
	if "damage" in bullet:
		bullet["damage"] = damage
	# 设置碰撞层为Layer3=EnemyBullet
	bullet.collision_layer = 0
	bullet.collision_layer |= (1 << 2)  # Layer3
	bullet.collision_mask = 0
	bullet.collision_mask |= (1 << 0)  # Layer1 = Player


## 创建一颗导弹
func _spawn_missile(pos: Vector2, dir: Vector2, speed: float) -> void:
	if missile_scene == null:
		missile_scene = load("res://scenes/bullets/missile_enemy.tscn")
	if missile_scene == null:
		return

	# v1.5: 应用 difficulty_curve 的子弹速度倍率
	speed *= current_bullet_speed_mult

	var missile: Node2D = null
	if PoolManager.has_method("get_object"):
		missile = PoolManager.get_object(missile_scene) as Node2D
	if missile == null:
		missile = missile_scene.instantiate()
		if missile.get_parent() == null:
			get_parent().add_child(missile)

	missile.global_position = pos
	if "direction" in missile:
		missile["direction"] = dir.normalized()
	if "speed" in missile:
		missile["speed"] = speed
	if "damage" in missile:
		missile["damage"] = 3

	missile.collision_layer = 0
	missile.collision_layer |= (1 << 2)  # Layer3 = EnemyBullet
	missile.collision_mask = 0
	missile.collision_mask |= (1 << 0)  # Layer1 = Player


## 获取朝向玩家的方向
func _get_direction_to_player() -> Vector2:
	_find_player()
	if player_ref and is_instance_valid(player_ref):
		return (player_ref.global_position - global_position).normalized()
	return Vector2.DOWN

# ============================================================
# 弹幕模式实现（v1.5：移除 phase 相关参数，使用 difficulty_curve 速度倍率）
# ============================================================

## 扇形散射
func fan_shoot() -> void:
	var bullet_count: int = int(_get_bullet_param("fan_shoot", "count_base", 5))
	var spread_angle: float = float(_get_bullet_param("fan_shoot", "spread_angle", 60.0))
	var start_angle: float = -spread_angle / 2.0
	var angle_step: float = spread_angle / float(bullet_count - 1) if bullet_count > 1 else 0.0
	var base_direction := Vector2.DOWN
	var bullet_speed: float = float(_get_bullet_param("fan_shoot", "speed_base", 200.0))
	var damage: int = int(_get_bullet_param("fan_shoot", "damage", 1))

	for i in range(bullet_count):
		var angle_deg := start_angle + angle_step * i
		var angle_rad := deg_to_rad(angle_deg)
		var dir := base_direction.rotated(angle_rad)
		var spawn_offset := Vector2(
			(i - bullet_count / 2.0) * 12.0,
			40.0
		)
		_spawn_bullet(global_position + spawn_offset, dir, bullet_speed, damage)


## 定点射击：从多个炮台位置依次发射精准子弹
func turret_fire() -> void:
	var turret_offsets: Array[Vector2] = [
		Vector2(-40, 30),
		Vector2(40, 30),
		Vector2(-20, 45),
		Vector2(20, 45),
		Vector2(0, 55),
	]

	var turret_pos: Vector2 = turret_offsets[turret_index % turret_offsets.size()]
	turret_index += 1

	var bullet_speed: float = float(_get_bullet_param("turret_fire", "speed_base", 280.0))
	var damage: int = int(_get_bullet_param("turret_fire", "damage", 2))
	var aim_on_center: bool = bool(_get_bullet_param("turret_fire", "aim_on_center", true))

	var dir := Vector2.DOWN
	_spawn_bullet(global_position + turret_pos, dir, bullet_speed, damage)

	if aim_on_center and turret_index % turret_offsets.size() == 0:
		var aim_dir := _get_direction_to_player()
		_spawn_bullet(global_position + Vector2(0, 55), aim_dir, bullet_speed * 0.9, damage)


## 导弹齐射
func missile_volley() -> void:
	var missile_count: int = int(_get_bullet_param("missile_volley", "count_base", 3))
	var base_dir := Vector2.DOWN
	var spread: float = float(_get_bullet_param("missile_volley", "spread_deg", 15.0))
	var missile_speed: float = float(_get_bullet_param("missile_volley", "speed_base", 150.0))

	for i in range(missile_count):
		var angle_offset := deg_to_rad((i - missile_count / 2.0) * spread / missile_count)
		var dir := base_dir.rotated(angle_offset)
		var spawn_pos := global_position + Vector2(
			(i - missile_count / 2.0) * 20.0,
			50.0
		)
		_spawn_missile(spawn_pos, dir, missile_speed)


## 螺旋弹幕
func spiral_shoot() -> void:
	var arms: int = int(_get_bullet_param("spiral_shoot", "arms_base", 3))
	var bullets_per_arm: int = int(_get_bullet_param("spiral_shoot", "bullets_per_arm", 2))
	var bullet_speed: float = float(_get_bullet_param("spiral_shoot", "speed_base", 180.0))
	var damage: int = int(_get_bullet_param("spiral_shoot", "damage", 1))

	for arm in range(arms):
		var arm_offset := float(arm) * (360.0 / float(arms))
		for b in range(bullets_per_arm):
			var angle := spiral_angle + arm_offset + b * 15.0
			var rad := deg_to_rad(angle)
			var dir := Vector2(cos(rad), sin(rad))
			_spawn_bullet(global_position + Vector2(0, 30), dir, bullet_speed, damage)


## 瞄准玩家射击
func aimed_shoot() -> void:
	var aim_dir := _get_direction_to_player()
	var bullet_speed: float = float(_get_bullet_param("aimed_shoot", "speed_base", 320.0))
	var bullet_count: int = int(_get_bullet_param("aimed_shoot", "count_base", 1))
	var spread_offset_deg: float = float(_get_bullet_param("aimed_shoot", "spread_offset_deg", 5.0))
	var damage: int = int(_get_bullet_param("aimed_shoot", "damage", 2))

	for i in range(bullet_count):
		var offset_angle := deg_to_rad((i - bullet_count / 2.0) * spread_offset_deg)
		var dir := aim_dir.rotated(offset_angle)
		var spawn_pos := global_position + Vector2(
			(i - bullet_count / 2.0) * 15.0,
			40.0
		)
		_spawn_bullet(spawn_pos, dir, bullet_speed, damage)

# ============================================================
# 辅助方法
# ============================================================

## 查找玩家节点
func _find_player() -> void:
	if player_ref and is_instance_valid(player_ref):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0] as Node2D


## 递归查找 Sprite2D 节点（用于 BOSS Sprite 引用）
func _find_sprite(node: Node) -> Sprite2D:
	if node is Sprite2D:
		return node as Sprite2D
	for child in node.get_children():
		var found := _find_sprite(child)
		if found != null:
			return found
	return null


## 获取HP百分比
func get_hp_percent() -> float:
	if indestructible or max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)


## 获取当前 BOSS 类型
func get_boss_type() -> String:
	return boss_type


## 获取当前状态名称（用于调试）
func get_current_state_name() -> String:
	if _state_machine != null:
		return _state_machine.current_state_name()
	return ""


## 重置BOSS状态（用于测试或对象池归还）
## override EnemyBase.reset_state()
func reset_state() -> void:
	super.reset_state()
	if indestructible:
		current_hp = -1
	else:
		current_hp = max_hp
	is_active = false
	is_entering = true
	current_time = 0.0
	attack_timer = 1.5
	spiral_angle = 0.0
	turret_index = 0
	_destroyed_parts.clear()
	_assault_active = false
	_assault_remaining_time = _assault_time_limit
	_summon_timer = float(_summon_config.get("interval", 15.0))
	_find_player()
	# 重新初始化部件
	if not _parts_config.is_empty():
		_init_parts()
	# 重置状态机到入场状态
	if _state_machine != null:
		_state_machine.initialize(STATE_ENTER)
	_enter_stage()


## 重置BOSS（旧接口，保留兼容性）
func reset_boss() -> void:
	reset_state()
