## 玩家战机基类
## 参考彩京《1945突击者》的核心机制
## 支持：8方向移动、连发射击、蓄力攻击、炸弹全屏清弹、无敌闪烁、倾斜动画
## 碰撞层：Layer1=Player, 检测 Layer3=EnemyBullet, Layer4=Enemy, Layer5=PowerUp
class_name PlayerBase extends CharacterBody2D

## ============================================================
## 信号
## ============================================================

## 玩家死亡信号
signal died()

## 蓄力满信号
signal charge_full()

## 使用炸弹信号
signal bomb_used()

## 得分变化信号
signal score_changed(new_score: int)

## 生命变化信号
signal lives_changed(new_lives: int)

## 炸弹数量变化信号
signal bombs_changed(new_bombs: int)

## 火力等级变化信号
signal power_changed(new_level: int)


## ============================================================
## 导出属性
## ============================================================

## 移动速度（像素/秒）
@export var speed: float = 200.0

## 射击间隔（秒）
@export var shoot_interval: float = 0.12

## 蓄力阈值（秒），按住射击键超过此时间松开后触发蓄力攻击
@export var charge_threshold: float = 1.5

## 最大生命数
@export var max_lives: int = 3

## 最大炸弹数
@export var max_bombs: int = 6

## 无敌时间（秒）
@export var invincible_duration: float = 2.0

## 闪烁间隔（秒）
@export var blink_interval: float = 0.08

## 倾斜最大角度（度）
@export var tilt_max_angle: float = 15.0

## 倾斜插值速度
@export var tilt_lerp_speed: float = 10.0

## 判定点大小半径（像素），用于缩小碰撞判定
@export var hitbox_radius: float = 4.0

## 玩家子弹场景（用于射击）
@export var bullet_scene: PackedScene = null

## 炸弹特效场景
@export var bomb_effect_scene: PackedScene = null

## 蓄力特效场景
@export var charge_effect_scene: PackedScene = null


## ============================================================
## 运行时状态
## ============================================================

## 当前生命数
var lives: int = 3

## 当前炸弹数
var bombs: int = 3

## 火力等级（1~4）
var power_level: int = 1

## 蓄力时间累计
var charge_time: float = 0.0

## 是否处于无敌状态
var is_invincible: bool = false

## 射击计时器
var shoot_timer: float = 0.0

## 当前分数
var score: int = 0

## 是否正在按住射击键
var _is_shooting: bool = false

## 是否已经触发蓄力（防止重复）
var _charge_fired: bool = false

## 无敌闪烁计时器
var _blink_timer: float = 0.0

## 无敌持续时间计时器
var _invincible_timer: float = 0.0

## 当前倾斜角度
var _current_tilt: float = 0.0

## 目标倾斜角度
var _target_tilt: float = 0.0

## 对象池引用
var object_pool: ObjectPool = null

## 是否已死亡（防止重复死亡处理）
var _is_dead: bool = false

## Sprite2D节点引用
@onready var _sprite: Sprite2D = _find_sprite_node()

## 判定点可视化节点（调试用）
@onready var _hitbox: Area2D = $Hitbox if has_node("Hitbox") else null

## 无敌闪烁Timer
var _invincible_blink_timer: Timer = null


func _ready() -> void:
	# 加入 "player" 组，便于 BOSS/敌机/道具等通过 get_nodes_in_group("player") 查找
	if not is_in_group("player"):
		add_to_group("player")

	# 初始化运行时状态（与GameManager同步）
	if GameManager:
		lives = GameManager.lives
		bombs = GameManager.bombs
		power_level = GameManager.power_level
		is_invincible = GameManager.is_invincible
	else:
		lives = max_lives
		bombs = 3
		power_level = 1
		is_invincible = false
	score = 0
	_is_dead = false
	charge_time = 0.0
	shoot_timer = 0.0
	_is_shooting = false
	_charge_fired = false

	# 设置碰撞层：Layer1 = Player
	# 检测 Layer3=EnemyBullet, Layer4=Enemy, Layer5=PowerUp
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(1, true)  # Layer1 = Player
	# 物理body的mask：检测Enemy(Layer4)
	set_collision_mask_value(4, true)   # 碰撞 Layer4 = Enemy

	# 判定点区域（Area2D）单独检测敌弹和道具
	if _hitbox != null:
		_hitbox.collision_layer = 0
		_hitbox.collision_mask = 0
		_hitbox.set_collision_mask_value(3, true)  # 检测 Layer3 = EnemyBullet
		_hitbox.set_collision_mask_value(5, true)  # 检测 Layer5 = PowerUp
		_hitbox.body_entered.connect(_on_hitbox_body_entered)
		_hitbox.area_entered.connect(_on_hitbox_area_entered)

	# 注：CharacterBody2D 没有 body_entered 信号（该信号属于 Area2D）。
	# 玩家与敌机的碰撞由 Hitbox(Area2D) 的信号处理，无需在主 body 上连接。

	# 初始化倾斜角度
	_current_tilt = 0.0
	_target_tilt = 0.0


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# 处理移动
	_handle_movement(delta)

	# 处理射击（含蓄力累计，见 _handle_shooting 内部逻辑）
	_handle_shooting(delta)

	# 处理炸弹输入
	_handle_bomb_input()

	# 更新无敌状态
	_update_invincibility(delta)

	# 更新倾斜动画
	_update_tilt_animation(delta)


## ============================================================
## 移动系统
## ============================================================

## 处理8方向移动输入
func _handle_movement(_delta: float) -> void:
	# 获取输入向量（8方向）
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# 设置速度
	velocity = input_dir * speed

	# 计算倾斜目标角度（根据水平速度）
	_target_tilt = -input_dir.x * tilt_max_angle

	# 移动
	move_and_slide()

	# 限制在屏幕范围内
	clamp_to_screen()


## 将玩家位置限制在屏幕内
func clamp_to_screen() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	# 留出边距防止贴边
	var margin: float = 16.0

	global_position.x = clampf(global_position.x, margin, viewport_size.x - margin)
	global_position.y = clampf(global_position.y, margin, viewport_size.y - margin)


## 更新倾斜动画
func _update_tilt_animation(delta: float) -> void:
	if _sprite == null:
		return

	# 平滑插值到目标角度
	_current_tilt = lerpf(_current_tilt, _target_tilt, tilt_lerp_speed * delta)

	# 应用旋转
	_sprite.rotation_degrees = _current_tilt


## ============================================================
## 射击系统
## ============================================================

## 处理射击输入
func _handle_shooting(delta: float) -> void:
	# 检测射击键（按住连发）
	var shoot_pressed: bool = Input.is_action_pressed("shoot")

	if shoot_pressed:
		_is_shooting = true
		shoot_timer += delta

		# 达到射击间隔就发射
		if shoot_timer >= shoot_interval:
			shoot_timer -= shoot_interval
			fire_bullet()

		# 蓄力时间累计
		if not _charge_fired:
			charge_time += delta

			# 蓄力满时发出信号
			if charge_time >= charge_threshold:
				charge_full.emit()
	else:
		# 松开射击键
		if _is_shooting:
			_is_shooting = false

			# 检查是否触发蓄力攻击
			if charge_time >= charge_threshold and not _charge_fired:
				fire_charge_attack()
				_charge_fired = true

		# 重置
		charge_time = 0.0
		_charge_fired = false
		shoot_timer = 0.0


## 发射普通子弹
## 根据当前 power_level 改变弹幕模式
func fire_bullet() -> void:
	if bullet_scene == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	match power_level:
		1:
			# 等级1：单发直线弹
			_spawn_bullet(Vector2(0, -20), Vector2.UP)
		2:
			# 等级2：双发平行弹
			_spawn_bullet(Vector2(-8, -18), Vector2.UP)
			_spawn_bullet(Vector2(8, -18), Vector2.UP)
		3:
			# 等级3：三发（中间直线 + 两侧微微展开）
			_spawn_bullet(Vector2(0, -20), Vector2.UP)
			_spawn_bullet(Vector2(-12, -16), Vector2(-0.15, -1).normalized())
			_spawn_bullet(Vector2(12, -16), Vector2(0.15, -1).normalized())
		4:
			# 等级4：四发扇形弹
			_spawn_bullet(Vector2(-10, -18), Vector2(-0.1, -1).normalized())
			_spawn_bullet(Vector2(-5, -20), Vector2(-0.05, -1).normalized())
			_spawn_bullet(Vector2(5, -20), Vector2(0.05, -1).normalized())
			_spawn_bullet(Vector2(10, -18), Vector2(0.1, -1).normalized())
		_:
			# 超过4级按等级4处理
			_spawn_bullet(Vector2(-10, -18), Vector2(-0.1, -1).normalized())
			_spawn_bullet(Vector2(-5, -20), Vector2(-0.05, -1).normalized())
			_spawn_bullet(Vector2(5, -20), Vector2(0.05, -1).normalized())
			_spawn_bullet(Vector2(10, -18), Vector2(0.1, -1).normalized())


## 生成一发子弹
## [param local_offset] 相对玩家的本地偏移位置
## [param dir] 子弹方向
func _spawn_bullet(local_offset: Vector2, dir: Vector2) -> void:
	var bullet: Node
	if object_pool != null:
		bullet = object_pool.get_object(bullet_scene)
	else:
		bullet = bullet_scene.instantiate()

	if bullet == null:
		return

	var bullet_node: BulletBase = bullet as BulletBase
	if bullet_node != null:
		bullet_node.global_position = global_position + local_offset
		bullet_node.direction = dir
		bullet_node.is_player_bullet = true
		bullet_node.speed = 500.0
		bullet_node.damage = 1

	var parent_node: Node = get_parent()
	if parent_node != null:
		parent_node.add_child(bullet)


## ============================================================
## 蓄力攻击系统
## ============================================================

## 蓄力攻击（虚拟方法，子类覆盖实现不同的蓄力弹幕）
func fire_charge_attack() -> void:
	if bullet_scene == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	# 默认蓄力攻击：发射一排强力大弹幕（根据power_level增强）
	var num_bullets: int = 8 + power_level * 4
	var spread_angle: float = deg_to_rad(30.0)

	for i: int in range(num_bullets):
		var t: float = float(i) / float(num_bullets - 1) if num_bullets > 1 else 0.5
		var angle: float = -spread_angle / 2.0 + t * spread_angle
		var dir: Vector2 = Vector2.from_angle(angle - PI / 2.0)  # 向上扇形

		var bullet: Node
		if object_pool != null:
			bullet = object_pool.get_object(bullet_scene)
		else:
			bullet = bullet_scene.instantiate()

		if bullet == null:
			continue

		var bullet_node: BulletBase = bullet as BulletBase
		if bullet_node != null:
			bullet_node.global_position = global_position
			bullet_node.direction = dir
			bullet_node.is_player_bullet = true
			bullet_node.speed = 600.0
			bullet_node.damage = 3  # 蓄力弹伤害更高
			parent_node.add_child(bullet)

	# 播放蓄力特效
	_spawn_charge_effect()


## 生成蓄力释放特效
func _spawn_charge_effect() -> void:
	if charge_effect_scene == null:
		return
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var effect: Node2D = charge_effect_scene.instantiate()
	effect.global_position = global_position
	parent_node.add_child(effect)

	# 自动销毁
	if not effect is CPUParticles2D and not effect is GPUParticles2D:
		var timer: Timer = Timer.new()
		timer.wait_time = 0.5
		timer.one_shot = true
		effect.add_child(timer)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(effect):
				effect.queue_free()
		)
		timer.start()


## ============================================================
## 炸弹系统
## ============================================================

## 处理炸弹输入
func _handle_bomb_input() -> void:
	if Input.is_action_just_pressed("bomb"):
		use_bomb()


## 使用炸弹
## 全屏清弹效果 + 屏幕闪烁 + 敌机伤害 + 2秒无敌
func use_bomb() -> void:
	if bombs <= 0:
		return
	if _is_dead:
		return

	bombs -= 1
	bombs_changed.emit(bombs)
	bomb_used.emit()

	# 全屏白色闪烁效果（经典STG炸弹视觉反馈）
	_create_bomb_flash()

	# 清除屏幕上所有敌方子弹
	_clear_enemy_bullets()

	# 对所有敌机造成伤害
	_damage_all_enemies()

	# 播放炸弹特效
	_spawn_bomb_effect()

	# 触发2秒无敌
	_start_invincibility(invincible_duration)


## 清除所有敌方子弹
func _clear_enemy_bullets() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	for child: Node in parent_node.get_children():
		if child is BulletBase:
			var bullet: BulletBase = child as BulletBase
			if not bullet.is_player_bullet:
				bullet._destroy()


## 对屏幕上所有敌机造成伤害
func _damage_all_enemies() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	for child: Node in parent_node.get_children():
		if child is EnemyBase:
			var enemy: EnemyBase = child as EnemyBase
			enemy.hit(5)  # 炸弹造成5点伤害


## 生成炸弹全屏特效
func _spawn_bomb_effect() -> void:
	if bomb_effect_scene == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var effect: Node2D = bomb_effect_scene.instantiate()
	# 特效放在屏幕中央
	var viewport_size: Vector2 = get_viewport_rect().size
	effect.global_position = viewport_size / 2.0
	parent_node.add_child(effect)

	# 自动销毁
	var timer: Timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	effect.add_child(timer)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(effect):
			effect.queue_free()
	)
	timer.start()


## 创建炸弹全屏白色闪烁效果
func _create_bomb_flash() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var flash := ColorRect.new()
	flash.name = "BombFlash"
	flash.rect_size = viewport_size
	flash.color = Color(1, 1, 1, 0.8)
	flash.z_index = 100

	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)


## ============================================================
## 碰撞处理系统
## ============================================================

## Body碰撞（与敌机碰撞）
func _on_body_entered(body: Node) -> void:
	if _is_dead or is_invincible:
		return

	if body is EnemyBase:
		on_enemy_collision(body)


## 判定点区域碰撞（与敌弹/道具碰撞）
func _on_hitbox_body_entered(body: Node) -> void:
	if _is_dead or is_invincible:
		return

	# 被敌弹命中
	if body is BulletBase:
		var bullet: BulletBase = body as BulletBase
		if not bullet.is_player_bullet:
			lose_life()
			bullet._destroy()


## 判定点区域碰撞（Area2D版本）
func _on_hitbox_area_entered(area: Node) -> void:
	if _is_dead:
		return

	# 拾取道具
	if area is PowerupBase:
		var powerup: PowerupBase = area as PowerupBase
		_collect_powerup(powerup)

	# 被敌弹命中（如果敌弹是Area2D）
	elif area is BulletBase:
		if is_invincible or _is_dead:
			return
		var bullet: BulletBase = area as BulletBase
		if not bullet.is_player_bullet:
			lose_life()
			bullet._destroy()


## 与敌机碰撞处理（彩京式机制）
## [param enemy] 碰到的敌机
func on_enemy_collision(enemy: EnemyBase) -> void:
	if _is_dead or is_invincible:
		return

	if power_level > 1:
		# Power > 1 时降低Power等级，不死亡
		power_level -= 1
		power_changed.emit(power_level)

		# 对碰撞的敌机造成伤害
		enemy.hit(2)

		# 短暂无敌
		_start_invincibility(0.5)
	else:
		# Power = 1 时直接死亡
		lose_life()


## 被敌弹命中，损失一条命
func lose_life() -> void:
	if _is_dead or is_invincible:
		return

	lives -= 1
	lives_changed.emit(lives)

	# 同步到GameManager
	if GameManager:
		GameManager.lives = lives
		GameManager.lives_changed.emit(lives)

	if lives <= 0:
		# 没有生命了，游戏结束
		_player_die()
	else:
		# 还有生命，进入复活流程
		# 降低火力
		power_level = maxi(power_level - 1, 1)
		power_changed.emit(power_level)

		# 同步Power到GameManager
		if GameManager:
			GameManager.power_level = power_level
			GameManager.power_changed.emit(power_level)

		# 复活无敌时间
		_start_invincibility(invincible_duration)

		# 通知GameManager（如果存在）
		if GameManager:
			GameManager.start_invincible(invincible_duration)


## 玩家死亡处理
func _player_die() -> void:
	_is_dead = true
	is_invincible = true

	# 播放死亡特效（爆炸）
	_spawn_player_explosion()

	# 发出死亡信号
	died.emit()

	# 通知GameManager
	_notify_game_manager_game_over()

	# 释放玩家
	queue_free()


## 播放玩家爆炸特效
func _spawn_player_explosion() -> void:
	if bomb_effect_scene != null:
		var parent_node: Node = get_parent()
		if parent_node != null:
			var effect: Node2D = bomb_effect_scene.instantiate()
			effect.global_position = global_position
			effect.scale = Vector2(1.5, 1.5)
			parent_node.add_child(effect)


## ============================================================
## 道具拾取系统
## ============================================================

## 收集道具
func _collect_powerup(powerup: PowerupBase) -> void:
	match powerup.powerup_type:
		PowerupBase.PowerupType.POWER:
			add_power(powerup.effect_value)
		PowerupBase.PowerupType.BOMB:
			add_bombs(powerup.effect_value)
		PowerupBase.PowerupType.SCORE:
			add_score(powerup.effect_value * 1000)
		PowerupBase.PowerupType.MEDKIT:
			heal(powerup.effect_value)


## 增加火力等级
func add_power(amount: int) -> void:
	power_level = mini(power_level + amount, 4)
	power_changed.emit(power_level)
	if GameManager:
		GameManager.power_level = power_level
		GameManager.power_changed.emit(power_level)


## 增加炸弹数量
func add_bombs(amount: int) -> void:
	bombs = mini(bombs + amount, max_bombs)
	bombs_changed.emit(bombs)
	if GameManager:
		GameManager.bombs = bombs
		GameManager.bombs_changed.emit(bombs)


## 增加分数
func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)
	if GameManager:
		GameManager.add_score(amount)


## 回复生命
func heal(amount: int) -> void:
	lives = mini(lives + amount, max_lives)
	lives_changed.emit(lives)
	if GameManager:
		GameManager.lives = lives
		GameManager.lives_changed.emit(lives)


## ============================================================
## 无敌系统
## ============================================================

## 开始无敌状态
## [param duration] 无敌持续时间（秒）
func _start_invincibility(duration: float) -> void:
	is_invincible = true
	_invincible_timer = duration
	_blink_timer = 0.0

	# 设置无敌期间的碰撞层：Player不检测敌弹
	if _hitbox != null:
		_hitbox.set_collision_mask_value(3, false)  # 暂时不检测敌弹
		_hitbox.set_collision_mask_value(5, true)   # 仍然可以拾取道具


## 更新无敌状态
func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return

	_invincible_timer -= delta

	# 闪烁动画
	_blink_timer += delta
	var visible_state: bool = fmod(_blink_timer, blink_interval * 2.0) < blink_interval
	visible = visible_state

	# 无敌时间结束
	if _invincible_timer <= 0.0:
		_end_invincibility()


## 结束无敌状态
func _end_invincibility() -> void:
	is_invincible = false
	_invincible_timer = 0.0
	_blink_timer = 0.0

	visible = true

	# 恢复碰撞检测
	if _hitbox != null:
		_hitbox.set_collision_mask_value(3, true)   # 恢复检测敌弹
		_hitbox.set_collision_mask_value(5, true)   # 检测道具


## ============================================================
## GameManager 通知
## ============================================================

## 通知GameManager损失生命
func _notify_game_manager_life_lost() -> void:
	var game_manager: Node = get_node_or_null("/root/GameManager")
	if game_manager != null and game_manager.has_method("on_player_life_lost"):
		game_manager.on_player_life_lost(self)


## 通知GameManager游戏结束
func _notify_game_manager_game_over() -> void:
	var game_manager: Node = get_node_or_null("/root/GameManager")
	if game_manager != null and game_manager.has_method("on_game_over"):
		game_manager.on_game_over(self)


## ============================================================
## 辅助方法
## ============================================================

## 递归查找Sprite2D节点
func _find_sprite_node() -> Sprite2D:
	return _find_sprite_recursive(self)


## 递归查找Sprite2D
func _find_sprite_recursive(node: Node) -> Sprite2D:
	if node is Sprite2D:
		return node
	for child: Node in node.get_children():
		var result: Sprite2D = _find_sprite_recursive(child)
		if result != null:
			return result
	return null


## 重置玩家状态（用于重新开始等场景）
func reset_player() -> void:
	lives = max_lives
	bombs = 3
	power_level = 1
	score = 0
	is_invincible = false
	_is_dead = false
	charge_time = 0.0
	shoot_timer = 0.0
	_is_shooting = false
	_charge_fired = false
	_current_tilt = 0.0
	_target_tilt = 0.0
	visible = true
	velocity = Vector2.ZERO
	set_process(true)
	set_physics_process(true)
