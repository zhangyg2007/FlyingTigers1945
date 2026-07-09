## BOSS基类脚本
## 继承CharacterBody2D，实现多阶段HP管理、弹幕模式切换、阶段转换动画
## 碰撞层：Layer4=Enemy，检测Layer2=PlayerBullet
class_name BossBase
extends CharacterBody2D

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

# ============================================================
# 内部状态
# ============================================================
## 当前生命值
var current_hp: int = 350
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

# ============================================================
# 节点引用（软引用：节点不存在时为 null，避免 _ready 中断）
# ============================================================
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hit_flash: Sprite2D = $HitFlash if has_node("HitFlash") else null
## 视觉根节点（用于受击闪烁等效果）
@onready var visual_root: Node2D = $VisualRoot if has_node("VisualRoot") else self

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	# 初始化HP
	current_hp = max_hp

	# 设置碰撞层：Layer4 = Enemy (值为8，即1<<3)
	collision_layer = 0
	collision_layer |= (1 << 3)  # Layer4 = Enemy
	# 检测Layer2 = PlayerBullet (值为4，即1<<1)
	collision_mask = 0
	collision_mask |= (1 << 1)  # Layer2 = PlayerBullet

	# 加载默认弹幕场景（如果未指定）
	if bullet_scene == null:
		bullet_scene = load("res://scenes/bullets/bullet_enemy.tscn")

	# 初始化攻击计时器
	if phase_attack_intervals.size() > 0:
		attack_timer = phase_attack_intervals[0]

	# 注：CharacterBody2D 没有 body_entered 信号（该信号属于 Area2D）。
	# BOSS与玩家的碰撞检测应通过 Area2D 子节点（Hitbox）实现，
	# 当前未添加 Hitbox 子节点，_on_body_entered 暂为空调用。
	# 待 M2-D 重构时添加 Hitbox Area2D 并连接信号。

	# 查找玩家
	_find_player()

	# 开始入场
	_enter_stage()


func _process(delta: float) -> void:
	if not is_active:
		return

	# 入场动画阶段
	if is_entering:
		_process_entry(delta)
		return

	# 阶段转换动画期间，不执行其他逻辑
	if is_transforming:
		return

	# 攻击计时器更新
	attack_timer -= delta
	if attack_timer <= 0.0:
		_execute_phase_attacks()
		# 重置计时器为当前阶段的攻击间隔
		if current_phase < phase_attack_intervals.size():
			attack_timer = phase_attack_intervals[current_phase]
		else:
			attack_timer = phase_attack_intervals[phase_attack_intervals.size() - 1]

	# 螺旋角度累积（用于spiral_shoot模式）
	spiral_angle += delta * 120.0  # 每秒旋转120度


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
	else:
		# 无入场动画时直接开始移动入场
		pass


## 处理入场移动
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
			transform_to_next_phase()
			return


## 执行阶段转换
func transform_to_next_phase() -> void:
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

	# 重置攻击计时器
	if current_phase < phase_attack_intervals.size():
		attack_timer = phase_attack_intervals[current_phase]

	print("[BOSS] 进入阶段 %d，HP阈值: %d" % [current_phase, phase_hps[current_phase] if current_phase < phase_hps.size() else 0])


## 变形动画完成回调（由AnimationPlayer的animation_finished信号连接调用）
func _on_transform_finished(anim_name: String) -> void:
	if anim_name.begins_with("transform"):
		is_transforming = false
		is_invincible = false
		# 停止闪烁
		if hit_flash:
			hit_flash.visible = false
		# 播放idle动画
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")


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

## 受到伤害
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
		_die()

	print("[BOSS] 受到 %d 伤害，剩余HP: %d/%d，当前阶段: %d" % [amount, current_hp, max_hp, current_phase])


## 受击白色闪烁
func _flash_white() -> void:
	if hit_flash:
		hit_flash.visible = true
		var tween := create_tween()
		tween.tween_property(hit_flash, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): hit_flash.visible = false)


## BOSS死亡处理
func _die() -> void:
	is_active = false

	# 播放死亡动画/爆炸
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		# 等待动画结束后移除
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


## 生成爆炸效果
func _spawn_explosion() -> void:
	# 尝试从对象池获取爆炸效果（get_object_by_path 接受 String 路径）
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


# ============================================================
# 碰撞处理
# ============================================================

## 玩家与BOSS碰撞时的接触伤害处理
## 注：当前未连接信号（CharacterBody2D 无 body_entered 信号）。
## 待 M2-D 添加 Hitbox Area2D 子节点后，由其 area_entered/body_entered 信号触发。
func _on_body_entered(body: Node2D) -> void:
	# 碰撞到玩家时造成接触伤害
	if body.has_method("take_damage") and body.collision_layer & (1 << 0):
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
			bullet.damage = damage
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
## 扇形角度范围60度，子弹数量根据阶段增加
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
## 模拟炮塔轮流开火效果
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
## 导弹数量随阶段增加，发射方向略带散布
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
## 在_process中累积角度，每次调用生成若干颗沿螺旋分布的子弹
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
## 可能发射多颗带微小偏移的子弹形成弹幕线
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


## 重置BOSS状态（用于测试）
func reset_boss() -> void:
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
	_enter_stage()
