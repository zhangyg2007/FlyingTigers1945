## BOSS基类脚本
## 继承 EnemyBase，复用碰撞层/hit/die/_spawn_explosion/_return_to_pool 等方法
## 实现多阶段HP管理、弹幕模式切换、阶段转换动画、JSON 配置加载、StateMachine 状态管理
## 碰撞层：Layer4=Enemy，检测 Layer2=PlayerBullet（通过动态创建的 Hitbox Area2D）
class_name BossBase
extends EnemyBase

# ============================================================
# 信号
# ============================================================
## 阶段切换时发射，参数为新阶段索引
signal boss_phase_changed(phase: int)
## BOSS被击败时发射
signal boss_defeated()

# ============================================================
# 导出参数 - 多阶段配置
# ============================================================
## 各阶段HP阈值（从后往前检查，phase_hps[0]为第一阶段阈值）
@export var phase_hps: Array[int] = [150, 200]
## 各阶段攻击间隔（秒）
@export var phase_attack_intervals: Array[float] = [1.5, 1.0]
## 各阶段弹幕模式名称列表
@export var phase_bullets: Array[PackedStringArray] = [
	PackedStringArray(["fan_shoot"]),
	PackedStringArray(["turret_fire", "fan_shoot"]),
]
## 最大生命值
@export var max_hp: int = 350
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
## 各阶段 Sprite 路径（用于阶段切换时自动替换纹理）
@export var phase_sprites: Array[String] = []

# ============================================================
# 内部状态
# ============================================================
## 当前阶段索引
var current_phase: int = 0
## 攻击计时器
var attack_timer: float = 0.0
## 当前是否处于无敌状态（阶段转换期间）
var is_invincible: bool = false
## 是否正在执行入场动画
var is_entering: bool = true
## 阶段转换动画是否播放中
var is_transforming: bool = false
## 螺旋弹幕角度累积
var spiral_angle: float = 0.0
## 定点射击当前炮台索引
var turret_index: int = 0
## 玩家引用
var player_ref: Node2D = null
## 是否已激活（入场完成后开始攻击）
var is_active: bool = false

## 状态机实例（内部组合，不 add_child 避免自动 _process 冲突）
var _state_machine: StateMachine = null

## BOSS Sprite 引用（用于阶段切换时替换纹理）
var _boss_sprite: Sprite2D = null

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
const STATE_TRANSFORM := "transform"
const STATE_DYING := "dying"

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

## 攻击状态：执行当前阶段弹幕模式，结束后回到待机
class BossStateAttack extends StateMachine.State:
	var boss: BossBase
	func _init(b: BossBase) -> void:
		boss = b
	func enter(_data: Dictionary = {}) -> void:
		boss._enter_attack()

## 变形状态：处理阶段转换动画，结束后回到待机
class BossStateTransform extends StateMachine.State:
	var boss: BossBase
	func _init(b: BossBase) -> void:
		boss = b
	func enter(_data: Dictionary = {}) -> void:
		boss._enter_transform()

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

	# 初始化 HP（current_hp 继承自 EnemyBase）
	current_hp = max_hp

	# 加载默认弹幕场景（如果未指定）
	if bullet_scene == null:
		bullet_scene = load("res://scenes/bullets/bullet_enemy.tscn")

	# 初始化攻击计时器
	if phase_attack_intervals.size() > 0:
		attack_timer = phase_attack_intervals[0]

	# 查找 BOSS Sprite（用于阶段切换时替换纹理）
	_boss_sprite = _find_sprite(self)

	# 创建 Hitbox Area2D（检测 player bullet 击中 BOSS）
	_create_hitbox()

	# 初始化状态机
	_init_state_machine()

	# 查找玩家
	_find_player()

	# 开始入场
	_enter_stage()

	# 连接阶段切换信号到 Sprite 更新
	if not boss_phase_changed.is_connected(_update_phase_sprite_by_phase):
		boss_phase_changed.connect(_update_phase_sprite_by_phase)


func _process(delta: float) -> void:
	# 完全覆盖 EnemyBase._process（不调用 super._process）
	# EnemyBase._process 做直线下移+弹幕射击+屏幕外归还，BOSS 不需要这些
	# 委托给状态机处理当前状态的 update
	if _state_machine != null and _state_machine.current_state() != null:
		_state_machine.current_state().update(delta)

	# 螺旋角度累积（用于 spiral_shoot 模式，所有状态都累积）
	spiral_angle += delta * 120.0  # 每秒旋转120度


# ============================================================
# 状态机初始化
# ============================================================

func _init_state_machine() -> void:
	_state_machine = StateMachine.new()
	_state_machine.add_state(STATE_ENTER, BossStateEnter.new(self))
	_state_machine.add_state(STATE_IDLE, BossStateIdle.new(self))
	_state_machine.add_state(STATE_ATTACK, BossStateAttack.new(self))
	_state_machine.add_state(STATE_TRANSFORM, BossStateTransform.new(self))
	_state_machine.add_state(STATE_DYING, BossStateDying.new(self))
	_state_machine.initialize(STATE_ENTER)
	print("[BOSS] 状态机初始化完成，当前状态: %s" % _state_machine.current_state_name())


func _process_idle(delta: float) -> void:
	# 攻击计时器更新
	attack_timer -= delta
	if attack_timer <= 0.0:
		_state_machine.transition_to(STATE_ATTACK)


func _enter_attack() -> void:
	# 执行当前阶段的所有弹幕模式
	_execute_phase_attacks()
	# 重置计时器为当前阶段的攻击间隔
	if current_phase < phase_attack_intervals.size():
		attack_timer = phase_attack_intervals[current_phase]
	else:
		attack_timer = phase_attack_intervals[phase_attack_intervals.size() - 1]
	# 攻击完成后回到待机状态
	_state_machine.transition_to(STATE_IDLE)


func _enter_transform() -> void:
	is_transforming = true
	is_invincible = true

	# 发射阶段切换信号
	boss_phase_changed.emit(current_phase)

	# 播放变形动画
	if animation_player and animation_player.has_animation("transform_%d" % current_phase):
		animation_player.play("transform_%d" % current_phase)
	elif animation_player and animation_player.has_animation("transform"):
		animation_player.play("transform")

	# 变形期间闪烁效果
	_start_transform_flash()

	# 切换阶段 Sprite（通过信号触发的 _update_phase_sprite_by_phase 也会调用）
	_update_phase_sprite()

	# 重置攻击计时器
	if current_phase < phase_attack_intervals.size():
		attack_timer = phase_attack_intervals[current_phase]

	print("[BOSS] 进入阶段 %d，HP阈值: %d" % [current_phase, phase_hps[current_phase] if current_phase < phase_hps.size() else 0])

	# 变形动画时长（0.6 秒后结束，回到待机）
	var tween := create_tween()
	tween.tween_callback(_on_transform_complete).set_delay(0.6)


func _on_transform_complete() -> void:
	is_transforming = false
	is_invincible = false
	# 停止闪烁
	if hit_flash:
		hit_flash.visible = false
	# 播放idle动画
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	# 回到待机状态
	_state_machine.transition_to(STATE_IDLE)


func _enter_dying() -> void:
	is_active = false

	# 播放死亡动画/爆炸
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		# 等待动画结束后继续
		await animation_player.animation_finished
	else:
		# 无死亡动画，直接播放爆炸粒子效果
		_spawn_explosion()

	# 发射击败信号
	boss_defeated.emit()

	# 通知GameManager
	if GameManager.has_method("boss_defeated"):
		GameManager.boss_defeated()

	print("[BOSS] 已被击败!")

	# 掉落道具
	_drop_loot()

	# 延迟后移除
	queue_free()

# ============================================================
# Hitbox Area2D（检测 player bullet 击中 BOSS）
# ============================================================

## 动态创建 Hitbox Area2D 子节点
## CharacterBody2D 没有 body_entered/area_entered 信号，需要 Area2D 子节点检测碰撞
func _create_hitbox() -> void:
	if has_node("Hitbox"):
		return  # 已存在

	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 0  # Hitbox 不发送任何层（避免被其他对象检测）
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
	# 检查是否为玩家子弹（Layer2）
	if not area.get_collision_layer_value(2):
		return
	# 获取子弹伤害值
	var damage: int = 1
	if "damage" in area:
		damage = area["damage"]
	take_damage(damage)
	# 子弹命中后销毁
	area.queue_free()

# ============================================================
# JSON 配置加载
# ============================================================

## 从 JSON 文件加载 BOSS 配置（覆盖场景中的导出值）
## [param path]: JSON 文件路径（如 "res://resources/boss_data/boss_bomber.json"）
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

	# 应用配置（JSON 覆盖场景导出值）
	if data.has("max_hp"):
		max_hp = int(data["max_hp"])
	if data.has("phase_hps"):
		phase_hps.clear()
		for v in data["phase_hps"]:
			phase_hps.append(int(v))
	if data.has("phase_attack_intervals"):
		phase_attack_intervals.clear()
		for v in data["phase_attack_intervals"]:
			phase_attack_intervals.append(float(v))
	if data.has("phase_bullets"):
		phase_bullets.clear()
		for phase_arr in data["phase_bullets"]:
			phase_bullets.append(PackedStringArray(phase_arr))
	if data.has("phase_sprites"):
		phase_sprites.clear()
		for v in data["phase_sprites"]:
			phase_sprites.append(String(v))
	if data.has("move_speed"):
		move_speed = float(data["move_speed"])
	if data.has("contact_damage"):
		contact_damage = int(data["contact_damage"])
	if data.has("entry_target_y"):
		entry_target_y = float(data["entry_target_y"])

	print("[BOSS] 已加载配置: %s (HP=%d, 阶段数=%d)" % [path, max_hp, phase_hps.size()])


## 根据当前阶段索引更新 Sprite 纹理（信号回调）
func _update_phase_sprite_by_phase(_phase: int) -> void:
	_update_phase_sprite()


## 更新当前阶段的 Sprite 纹理
func _update_phase_sprite() -> void:
	if _boss_sprite == null:
		return
	if current_phase < phase_sprites.size():
		var sprite_path: String = phase_sprites[current_phase]
		if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			_boss_sprite.texture = load(sprite_path)
			print("[BOSS] 切换阶段 Sprite: %s" % sprite_path)

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

	# 向目标位置移动
	var direction := (target_pos - global_position).normalized()
	var distance := global_position.distance_to(target_pos)

	if distance < 5.0:
		# 到达目标位置，入场完成
		global_position = target_pos
		is_entering = false
		is_active = true
		if animation_player and animation_player.is_playing():
			animation_player.stop()
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")
		# 切换到待机状态
		_state_machine.transition_to(STATE_IDLE)
	else:
		global_position += direction * move_speed * 1.5 * delta

# ============================================================
# 阶段管理
# ============================================================

## 检查是否需要切换阶段
## 阶段转换逻辑：从后往前检查phase_hps
## 当current_hp降到phase_hps中某个阈值以下时，进入对应阶段
func _check_phase_transition() -> void:
	if is_transforming:
		return

	# 从最后一个阶段阈值开始往前检查
	for i in range(phase_hps.size() - 1, current_phase, -1):
		if current_hp <= phase_hps[i] and i > current_phase:
			current_phase = i
			_state_machine.transition_to(STATE_TRANSFORM)
			return


## 执行阶段转换（外部调用接口，内部通过状态机实现）
func transform_to_next_phase() -> void:
	_state_machine.transition_to(STATE_TRANSFORM)


## 变形动画完成回调（保留兼容性，当前由 _on_transform_complete 处理）
func _on_transform_finished(anim_name: String) -> void:
	if anim_name.begins_with("transform"):
		_on_transform_complete()


## 变形闪烁效果
func _start_transform_flash() -> void:
	var tween := create_tween()
	tween.set_loops()
	for i in range(6):
		tween.tween_property(visual_root, "modulate", Color(1, 1, 1, 0.3), 0.1)
		tween.tween_property(visual_root, "modulate", Color(1, 0.5, 0.5, 1.0), 0.1)

# ============================================================
# 受伤与死亡
# ============================================================

## 受到伤害（BOSS专用，含无敌检查和阶段转换）
## 注：EnemyBase.hit() 会调用此方法（通过下面的 override）
func take_damage(amount: int) -> void:
	if is_invincible or is_entering:
		return

	current_hp -= amount

	# 受击闪烁
	_flash_white()

	# 检查阶段转换
	_check_phase_transition()

	# 检查死亡
	if current_hp <= 0:
		current_hp = 0
		_state_machine.transition_to(STATE_DYING)

	print("[BOSS] 受到 %d 伤害，剩余HP: %d/%d，当前阶段: %d" % [amount, current_hp, max_hp, current_phase])


## override EnemyBase.hit()，让 Area2D 碰撞也走 take_damage 流程
func hit(damage: int) -> void:
	take_damage(damage)


## 受击白色闪烁
func _flash_white() -> void:
	if hit_flash:
		hit_flash.visible = true
		var tween := create_tween()
		tween.tween_property(hit_flash, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): hit_flash.visible = false)


## 生成爆炸效果（覆盖 EnemyBase._spawn_explosion，使用对象池）
func _spawn_explosion() -> void:
	var explosion_scene_path: String = "res://scenes/effects/explosion_large.tscn"
	var explosion: Node = null
	if PoolManager.has_method("get_object_by_path"):
		explosion = PoolManager.get_object_by_path(explosion_scene_path)
	if explosion == null:
		# 对象池不可用或池满，回退直接实例化
		var explosion_scene = load(explosion_scene_path)
		if explosion_scene == null:
			return
		explosion = explosion_scene.instantiate()

	if explosion != null:
		explosion.global_position = global_position
		# 若对象池已添加到场景树则 get_parent() 非空，避免重复 add_child
		if explosion.get_parent() == null:
			get_parent().add_child(explosion)


## 掉落战利品
func _drop_loot() -> void:
	# BOSS固定掉落：PowerUp x3，炸弹x1，分数奖励
	var powerup_scene = load("res://scenes/powerups/powerup.tscn")
	if powerup_scene == null:
		return

	var offsets := [Vector2(-30, 0), Vector2(0, 0), Vector2(30, 0)]
	for offset in offsets:
		var item = powerup_scene.instantiate()
		item.global_position = global_position + offset
		get_parent().add_child(item)


## 玩家与BOSS碰撞时的接触伤害处理（保留兼容性）
## 注：当前通过 Hitbox Area2D 的 area_entered 处理子弹碰撞
## 玩家 body 碰撞需要额外添加 Hitbox 的 body_entered 检测，暂未实现
## 参数类型必须与父类 EnemyBase._on_body_entered(body: Node) 一致
func _on_body_entered(body: Node) -> void:
	if body is Node2D and body.has_method("take_damage") and body.collision_layer & (1 << 0):
		body.take_damage(contact_damage)

# ============================================================
# 弹幕攻击系统
# ============================================================

## 执行当前阶段的所有攻击模式
func _execute_phase_attacks() -> void:
	if current_phase >= phase_bullets.size():
		return

	var patterns: PackedStringArray = phase_bullets[current_phase]
	for pattern_name in patterns:
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

	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = pos
	# 设置子弹方向和速度
	if bullet.has_method("setup"):
		bullet.setup(dir.normalized(), speed, damage)
	else:
		bullet.velocity = dir.normalized() * speed
		if "damage" in bullet:
			bullet["damage"] = damage
	# 设置碰撞层为Layer3=EnemyBullet
	bullet.collision_layer = 0
	bullet.collision_layer |= (1 << 2)  # Layer3
	bullet.collision_mask = 0
	bullet.collision_mask |= (1 << 0)  # Layer1 = Player

	get_parent().add_child(bullet)


## 创建一颗导弹
func _spawn_missile(pos: Vector2, dir: Vector2, speed: float) -> void:
	if missile_scene == null:
		missile_scene = load("res://scenes/bullets/missile_enemy.tscn")
	if missile_scene == null:
		return

	var missile: Node2D = missile_scene.instantiate()
	missile.global_position = pos
	if missile.has_method("setup"):
		missile.setup(dir.normalized(), speed, 3)
	else:
		missile.velocity = dir.normalized() * speed

	missile.collision_layer = 0
	missile.collision_layer |= (1 << 2)  # Layer3 = EnemyBullet
	missile.collision_mask = 0
	missile.collision_mask |= (1 << 0)  # Layer1 = Player

	get_parent().add_child(missile)


## 获取朝向玩家的方向
func _get_direction_to_player() -> Vector2:
	_find_player()
	if player_ref and is_instance_valid(player_ref):
		return (player_ref.global_position - global_position).normalized()
	return Vector2.DOWN

# ============================================================
# 弹幕模式实现
# ============================================================

## 扇形散射：从BOSS位置向下方扇形区域发射多颗子弹
func fan_shoot() -> void:
	var bullet_count: int = 5 + current_phase * 2  # 阶段1:5颗, 阶段2:7颗
	var spread_angle: float = 60.0  # 总扇形角度
	var start_angle: float = -spread_angle / 2.0
	var angle_step: float = spread_angle / float(bullet_count - 1)
	var base_direction := Vector2.DOWN
	var bullet_speed: float = 200.0 + current_phase * 30.0

	for i in range(bullet_count):
		var angle_deg := start_angle + angle_step * i
		var angle_rad := deg_to_rad(angle_deg)
		var dir := base_direction.rotated(angle_rad)
		# 子弹生成位置（BOSS下方）
		var spawn_offset := Vector2(
			(i - bullet_count / 2.0) * 12.0,
			40.0
		)
		_spawn_bullet(global_position + spawn_offset, dir, bullet_speed)


## 定点射击：从多个炮台位置依次发射精准子弹
func turret_fire() -> void:
	# 定义炮台位置（相对于BOSS中心）
	var turret_offsets: Array[Vector2] = [
		Vector2(-40, 30),   # 左炮台
		Vector2(40, 30),    # 右炮台
		Vector2(-20, 45),   # 左下炮台
		Vector2(20, 45),    # 右下炮台
		Vector2(0, 55),     # 中央炮台
	]

	# 当前轮到的炮台
	var turret_pos: Vector2 = turret_offsets[turret_index % turret_offsets.size()]
	turret_index += 1

	# 炮台向下方发射高速子弹
	var dir := Vector2.DOWN
	var bullet_speed: float = 280.0 + current_phase * 40.0
	_spawn_bullet(global_position + turret_pos, dir, bullet_speed, 2)

	# 如果是中央炮台，额外发射一颗瞄准子弹
	if turret_index % turret_offsets.size() == 0:
		var aim_dir := _get_direction_to_player()
		_spawn_bullet(global_position + Vector2(0, 55), aim_dir, bullet_speed * 0.9, 2)


## 导弹齐射：发射多枚追踪导弹
func missile_volley() -> void:
	var missile_count: int = 3 + current_phase * 2  # 阶段1:3枚, 阶段2:5枚
	var base_dir := Vector2.DOWN
	var spread: float = 15.0  # 散布角度（度）
	var missile_speed: float = 150.0

	for i in range(missile_count):
		var angle_offset := deg_to_rad((i - missile_count / 2.0) * spread / missile_count)
		var dir := base_dir.rotated(angle_offset)
		var spawn_pos := global_position + Vector2(
			(i - missile_count / 2.0) * 20.0,
			50.0
		)
		_spawn_missile(spawn_pos, dir, missile_speed)


## 螺旋弹幕：沿螺旋轨迹连续发射子弹
func spiral_shoot() -> void:
	var arms: int = 3 + current_phase  # 螺旋臂数量
	var bullets_per_arm: int = 2
	var bullet_speed: float = 180.0 + current_phase * 20.0

	for arm in range(arms):
		var arm_offset := float(arm) * (360.0 / float(arms))
		for b in range(bullets_per_arm):
			var angle := spiral_angle + arm_offset + b * 15.0
			var rad := deg_to_rad(angle)
			var dir := Vector2(cos(rad), sin(rad))
			_spawn_bullet(global_position + Vector2(0, 30), dir, bullet_speed)


## 瞄准玩家射击：计算玩家方向，发射高速精准弹
func aimed_shoot() -> void:
	var aim_dir := _get_direction_to_player()
	var bullet_speed: float = 320.0
	var bullet_count: int = 1 + current_phase  # 阶段1:1颗, 阶段2:2颗

	for i in range(bullet_count):
		# 轻微偏移角度，让弹幕不完全重叠
		var offset_angle := deg_to_rad((i - bullet_count / 2.0) * 5.0)
		var dir := aim_dir.rotated(offset_angle)
		var spawn_pos := global_position + Vector2(
			(i - bullet_count / 2.0) * 15.0,
			40.0
		)
		_spawn_bullet(spawn_pos, dir, bullet_speed, 3)

# ============================================================
# 辅助方法
# ============================================================

## 查找玩家节点
func _find_player() -> void:
	if player_ref and is_instance_valid(player_ref):
		return
	# 通过GameManager或场景树查找玩家
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0] as Node2D


## 获取当前阶段索引
func get_current_phase() -> int:
	return current_phase


## 获取HP百分比
func get_hp_percent() -> float:
	return float(current_hp) / float(max_hp) if max_hp > 0 else 0.0


## 获取当前状态名称（用于调试）
func get_current_state_name() -> String:
	if _state_machine != null:
		return _state_machine.current_state_name()
	return ""


## 重置BOSS状态（用于测试或对象池归还）
## override EnemyBase.reset_state()
func reset_state() -> void:
	super.reset_state()
	current_hp = max_hp
	current_phase = 0
	is_active = false
	is_entering = true
	is_invincible = false
	is_transforming = false
	attack_timer = phase_attack_intervals[0] if phase_attack_intervals.size() > 0 else 1.5
	spiral_angle = 0.0
	turret_index = 0
	_find_player()
	# 重置状态机到入场状态
	if _state_machine != null:
		_state_machine.initialize(STATE_ENTER)
	_enter_stage()


## 重置BOSS（旧接口，保留兼容性）
func reset_boss() -> void:
	reset_state()
