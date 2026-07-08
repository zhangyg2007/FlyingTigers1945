## 玩家战机测试场景脚本
## 用于单独测试玩家的核心功能：移动、射击、蓄力、碰撞判定、无敌闪烁
## 不依赖外部场景资源，使用代码动态创建所有占位节点
## 运行方式：在Godot编辑器中运行此场景（需作为主场景或独立场景）
extends Node2D

## ============================================================
## 内部变量
## ============================================================

## 玩家占位节点（CharacterBody2D）
var _player: CharacterBody2D = null

## 玩家占位Sprite（ColorRect）
var _player_visual: ColorRect = null

## 判定点可视化节点（Area2D）
var _hitbox_area: Area2D = null

## 测试用敌弹列表
var _enemy_bullets: Array[Node2D] = []

## 测试用玩家子弹列表
var _player_bullets: Array[Node2D] = []

## 玩家移动速度
var _player_speed: float = 250.0

## 射击间隔（秒）
var _shoot_interval: float = 0.12

## 射击计时器
var _shoot_timer: float = 0.0

## 是否正在按住射击键
var _is_shooting: bool = false

## 蓄力累计时间
var _charge_time: float = 0.0

## 蓄力阈值（秒）
var _charge_threshold: float = 1.5

## 是否已触发蓄力
var _charge_fired: bool = false

## 无敌状态
var _is_invincible: bool = false

## 无敌计时器
var _invincible_timer: float = 0.0

## 无敌持续时间
var _invincible_duration: float = 2.0

## 闪烁计时器
var _blink_timer: float = 0.0

## 闪烁间隔
var _blink_interval: float = 0.08

## Power等级（1~4）
var _power_level: int = 1

## 生命值
var _lives: int = 3

## 炸弹数量
var _bombs: int = 3

## 分数
var _score: int = 0

## 敌弹生成计时器
var _enemy_bullet_timer: float = 0.0

## 敌弹生成间隔（秒）
var _enemy_bullet_interval: float = 1.0

## 视口尺寸缓存
var _viewport_size: Vector2 = Vector2.ZERO

## 调试HUD Label
var _debug_label: Label = null

## 测试模式：是否启用无敌（用于测试移动时不被击中）
var _god_mode: bool = false


## ============================================================
## 生命周期
## ============================================================

func _ready() -> void:
	_viewport_size = get_viewport_rect().size

	# 1. 创建背景
	_create_background()

	# 2. 创建玩家战机（含碰撞框）
	_create_player()

	# 3. 创建子弹占位样本（用于验证颜色区分）
	_create_bullet_samples()

	# 4. 创建调试HUD
	_create_debug_hud()

	print("========================================")
	print("  [TestPlayer] 玩家测试场景已启动")
	print("  测试项目: 移动、射击、蓄力、碰撞判定、无敌闪烁")
	print("  WASD/方向键=移动  Z/J=射击  X/K=炸弹")
	print("  G键=切换上帝模式  R键=重置状态")
	print("========================================")


func _process(delta: float) -> void:
	# 处理额外调试键
	_handle_extra_keys()

	# 更新移动
	_update_movement(delta)

	# 更新射击
	_update_shooting(delta)

	# 更新子弹
	_update_bullets(delta)

	# 更新无敌状态
	_update_invincibility(delta)

	# 生成测试敌弹
	_update_enemy_bullet_spawning(delta)

	# 更新HUD
	_update_hud()


## ============================================================
## 场景搭建
## ============================================================

## 创建深色背景
func _create_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.06, 0.12, 1.0)  # 深紫色（区别于关卡测试的深蓝）
	add_child(bg)
	bg.name = "Background"

	# 添加网格线帮助判断移动
	var grid_container: Node2D = Node2D.new()
	grid_container.name = "GridLines"
	add_child(grid_container)

	var grid_color: Color = Color(0.15, 0.12, 0.2, 0.5)
	for x: int in range(0, int(_viewport_size.x), 64):
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(x, 0))
		line.add_point(Vector2(x, _viewport_size.y))
		line.default_color = grid_color
		line.width = 1
		grid_container.add_child(line)

	for y: int in range(0, int(_viewport_size.y), 64):
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(0, y))
		line.add_point(Vector2(_viewport_size.x, y))
		line.default_color = grid_color
		line.width = 1
		grid_container.add_child(line)


## 创建玩家战机占位节点
func _create_player() -> void:
	_player = CharacterBody2D.new()
	_player.name = "PlayerTest"
	_player.position = Vector2(_viewport_size.x / 2.0, _viewport_size.y - 150.0)
	add_child(_player)

	# 碰撞层：Layer1=Player
	_player.collision_layer = 0
	_player.collision_mask = 0
	_player.set_collision_layer_value(1, true)
	_player.set_collision_mask_value(4, true)  # 检测Layer4=Enemy

	# 机身碰撞框（矩形）
	var body_collision: CollisionShape2D = CollisionShape2D.new()
	var body_shape: RectangleShape2D = RectangleShape2D.new()
	body_shape.size = Vector2(28, 32)
	body_collision.shape = body_shape
	_player.add_child(body_collision)
	body_collision.name = "BodyCollision"

	# 占位Sprite（绿色方块=玩家）
	_player_visual = ColorRect.new()
	_player_visual.size = Vector2(32, 32)
	_player_visual.position = Vector2(-16, -16)
	_player_visual.color = Color(0.2, 0.9, 0.3, 1.0)
	_player.add_child(_player_visual)
	_player_visual.name = "Visual"

	# 判定点Area2D（小碰撞区域，模拟彩京式精确判定）
	_hitbox_area = Area2D.new()
	_hitbox_area.position = Vector2.ZERO
	_player.add_child(_hitbox_area)
	_hitbox_area.name = "Hitbox"

	var hitbox_shape: CollisionShape2D = CollisionShape2D.new()
	var hitbox_circle: CircleShape2D = CircleShape2D.new()
	hitbox_circle.radius = 4.0  # 极小判定点
	hitbox_shape.shape = hitbox_circle
	_hitbox_area.add_child(hitbox_shape)
	hitbox_shape.name = "HitboxShape"

	# 判定点遮罩：检测Layer3=EnemyBullet, Layer5=PowerUp
	_hitbox_area.collision_layer = 0
	_hitbox_area.collision_mask = 0
	_hitbox_area.set_collision_mask_value(3, true)  # 检测敌弹
	_hitbox_area.set_collision_mask_value(5, true)  # 检测道具

	# 判定点可视化（红色小圆点）
	var hitbox_visual: ColorRect = ColorRect.new()
	hitbox_visual.size = Vector2(8, 8)
	hitbox_visual.position = Vector2(-4, -4)
	hitbox_visual.color = Color(1.0, 0.0, 0.0, 0.8)
	_hitbox_area.add_child(hitbox_visual)
	hitbox_visual.name = "HitboxVisual"

	# 注：测试敌弹使用 ColorRect（非 Area2D/PhysicsBody2D），
	# hitbox Area2D 的 area_entered/body_entered 信号不会被触发，
	# 命中检测改由 _update_bullets() 中的距离检测完成。
	# 此处保留 hitbox 节点仅用于可视化判定点（红色小点），便于手感调试。


## 创建子弹占位样本（展示在HUD区域，用于确认颜色区分）
func _create_bullet_samples() -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "BulletSamples"
	add_child(canvas_layer)

	# 玩家弹样本
	var player_sample: ColorRect = ColorRect.new()
	player_sample.size = Vector2(8, 16)
	player_sample.position = Vector2(10, _viewport_size.y - 80)
	player_sample.color = Color(1.0, 1.0, 0.0, 1.0)  # 黄色
	canvas_layer.add_child(player_sample)

	var player_label: Label = Label.new()
	player_label.position = Vector2(24, _viewport_size.y - 82)
	player_label.text = "玩家弹"
	player_label.add_theme_font_size_override("font_size", 14)
	player_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0, 1.0))
	canvas_layer.add_child(player_label)

	# 敌弹样本
	var enemy_sample: ColorRect = ColorRect.new()
	enemy_sample.size = Vector2(8, 16)
	enemy_sample.position = Vector2(10, _viewport_size.y - 50)
	enemy_sample.color = Color(1.0, 0.2, 0.2, 1.0)  # 红色
	canvas_layer.add_child(enemy_sample)

	var enemy_label: Label = Label.new()
	enemy_label.position = Vector2(24, _viewport_size.y - 52)
	enemy_label.text = "敌弹"
	enemy_label.add_theme_font_size_override("font_size", 14)
	enemy_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	canvas_layer.add_child(enemy_label)


## 创建调试HUD
func _create_debug_hud() -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "DebugHUD"
	add_child(canvas_layer)

	_debug_label = Label.new()
	_debug_label.anchor_left = 0.0
	_debug_label.anchor_top = 0.0
	_debug_label.offset_left = 10.0
	_debug_label.offset_top = 10.0
	_debug_label.add_theme_font_size_override("font_size", 16)
	_debug_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1.0))
	canvas_layer.add_child(_debug_label)


## ============================================================
## 移动系统
## ============================================================

## 更新玩家8方向移动
func _update_movement(_delta: float) -> void:
	if _player == null:
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_player.velocity = input_dir * _player_speed
	_player.move_and_slide()

	# 限制在屏幕内
	var margin: float = 16.0
	_player.global_position.x = clampf(_player.global_position.x, margin, _viewport_size.x - margin)
	_player.global_position.y = clampf(_player.global_position.y, margin, _viewport_size.y - margin)


## ============================================================
## 射击系统
## ============================================================

## 更新射击逻辑
func _update_shooting(delta: float) -> void:
	if _player == null:
		return

	var shoot_pressed: bool = Input.is_action_pressed("shoot")

	if shoot_pressed:
		_is_shooting = true
		_shoot_timer += delta

		# 连发射击
		if _shoot_timer >= _shoot_interval:
			_shoot_timer -= _shoot_interval
			_fire_player_bullet()

		# 蓄力累计
		if not _charge_fired:
			_charge_time += delta

			# 蓄力满提示
			if _charge_time >= _charge_threshold:
				print("[TestPlayer] 蓄力已满! 松开射击键释放蓄力攻击")
	else:
		if _is_shooting:
			_is_shooting = false

			# 检查蓄力释放
			if _charge_time >= _charge_threshold and not _charge_fired:
				_fire_charge_attack()
				_charge_fired = true

		_charge_time = 0.0
		_charge_fired = false
		_shoot_timer = 0.0


## 发射普通子弹（根据Power等级）
func _fire_player_bullet() -> void:
	if _player == null:
		return

	match _power_level:
		1:
			_spawn_player_bullet(Vector2(0, -20), Vector2.UP)
		2:
			_spawn_player_bullet(Vector2(-8, -18), Vector2.UP)
			_spawn_player_bullet(Vector2(8, -18), Vector2.UP)
		3:
			_spawn_player_bullet(Vector2(0, -20), Vector2.UP)
			_spawn_player_bullet(Vector2(-12, -16), Vector2(-0.15, -1).normalized())
			_spawn_player_bullet(Vector2(12, -16), Vector2(0.15, -1).normalized())
		_:
			_spawn_player_bullet(Vector2(-10, -18), Vector2(-0.1, -1).normalized())
			_spawn_player_bullet(Vector2(-5, -20), Vector2(-0.05, -1).normalized())
			_spawn_player_bullet(Vector2(5, -20), Vector2(0.05, -1).normalized())
			_spawn_player_bullet(Vector2(10, -18), Vector2(0.1, -1).normalized())


## 生成一发玩家子弹
func _spawn_player_bullet(local_offset: Vector2, dir: Vector2) -> void:
	var bullet: ColorRect = ColorRect.new()
	bullet.size = Vector2(6, 12)
	bullet.color = Color(1.0, 1.0, 0.0, 1.0)  # 黄色
	bullet.position = _player.global_position + local_offset - Vector2(3, 6)
	bullet.name = "PlayerBullet"
	bullet.set_meta("speed", 500.0)
	bullet.set_meta("direction", dir)
	bullet.set_meta("is_player_bullet", true)
	add_child(bullet)
	_player_bullets.append(bullet)


## 蓄力攻击（扇形弹幕）
func _fire_charge_attack() -> void:
	if _player == null:
		return

	print("[TestPlayer] 释放蓄力攻击! Power=%d" % _power_level)

	# 根据Power等级发射不同数量的扇形弹
	var num_bullets: int = 8 + _power_level * 4
	var spread_angle: float = deg_to_rad(30.0)

	for i: int in range(num_bullets):
		var t: float = float(i) / float(num_bullets - 1) if num_bullets > 1 else 0.5
		var angle: float = -spread_angle / 2.0 + t * spread_angle
		var dir: Vector2 = Vector2.from_angle(angle - PI / 2.0)  # 向上扇形

		var bullet: ColorRect = ColorRect.new()
		bullet.size = Vector2(8, 16)
		bullet.color = Color(0.3, 0.6, 1.0, 1.0)  # 蓝色=蓄力弹
		bullet.position = _player.global_position - Vector2(4, 8)
		bullet.name = "ChargeBullet"
		bullet.set_meta("speed", 600.0)
		bullet.set_meta("direction", dir)
		bullet.set_meta("is_player_bullet", true)
		bullet.set_meta("is_charge", true)
		add_child(bullet)
		_player_bullets.append(bullet)


## ============================================================
## 敌弹系统
## ============================================================

## 定时生成测试敌弹（从顶部随机位置射红弹向下）
func _update_enemy_bullet_spawning(delta: float) -> void:
	_enemy_bullet_timer += delta
	if _enemy_bullet_timer >= _enemy_bullet_interval:
		_enemy_bullet_timer -= _enemy_bullet_interval
		_spawn_enemy_bullet()


## 生成一发测试敌弹
func _spawn_enemy_bullet() -> void:
	if _player == null:
		return

	var bullet: ColorRect = ColorRect.new()
	bullet.size = Vector2(6, 12)
	bullet.color = Color(1.0, 0.2, 0.2, 1.0)  # 红色=敌弹

	# 从顶部随机位置生成，朝向玩家
	var spawn_x: float = randf_range(50.0, _viewport_size.x - 50.0)
	var spawn_pos: Vector2 = Vector2(spawn_x, -20.0)
	bullet.position = spawn_pos

	# 计算朝向玩家的方向
	var dir: Vector2 = (_player.global_position - spawn_pos).normalized()
	# 稍加随机偏移，避免所有弹都精确瞄准
	dir += Vector2(randf_range(-0.1, 0.1), randf_range(-0.05, 0.05))
	dir = dir.normalized()

	bullet.set_meta("speed", 200.0)
	bullet.set_meta("direction", dir)
	bullet.set_meta("is_player_bullet", false)
	add_child(bullet)
	_enemy_bullets.append(bullet)


## ============================================================
## 子弹更新
## ============================================================

## 更新所有子弹位置
func _update_bullets(delta: float) -> void:
	# 更新玩家子弹
	var player_bullets_to_remove: Array[Node2D] = []
	for bullet: Node2D in _player_bullets:
		if not is_instance_valid(bullet):
			player_bullets_to_remove.append(bullet)
			continue

		var speed: float = bullet.get_meta("speed", 500.0)
		var dir: Vector2 = bullet.get_meta("direction", Vector2.UP)
		bullet.position += dir * speed * delta

		# 超出屏幕移除
		if _is_out_of_screen(bullet.position):
			player_bullets_to_remove.append(bullet)

	for bullet: Node2D in player_bullets_to_remove:
		_player_bullets.erase(bullet)
		if is_instance_valid(bullet):
			bullet.queue_free()

	# 更新敌弹
	var enemy_bullets_to_remove: Array[Node2D] = []
	for bullet: Node2D in _enemy_bullets:
		if not is_instance_valid(bullet):
			enemy_bullets_to_remove.append(bullet)
			continue

		var speed: float = bullet.get_meta("speed", 200.0)
		var dir: Vector2 = bullet.get_meta("direction", Vector2.DOWN)
		bullet.position += dir * speed * delta

		# 检测与玩家碰撞（距离检测模拟）
		if _player != null and is_instance_valid(_player):
			var dist: float = bullet.global_position.distance_to(_player.global_position)
			if dist < 6.0:  # 判定点半径4 + 子弹半径2
				if not _is_invincible and not _god_mode:
					_on_player_hit(bullet)
					enemy_bullets_to_remove.append(bullet)
				elif _god_mode:
					enemy_bullets_to_remove.append(bullet)

		# 超出屏幕移除
		if _is_out_of_screen(bullet.position):
			enemy_bullets_to_remove.append(bullet)

	for bullet: Node2D in enemy_bullets_to_remove:
		_enemy_bullets.erase(bullet)
		if is_instance_valid(bullet):
			bullet.queue_free()


## 检测是否超出屏幕
func _is_out_of_screen(pos: Vector2) -> bool:
	return (pos.y < -50.0
		or pos.y > _viewport_size.y + 50.0
		or pos.x < -50.0
		or pos.x > _viewport_size.x + 50.0)


## ============================================================
## 碰撞处理
## ============================================================

## 玩家被敌弹命中（由 _update_bullets 距离检测调用）
func _on_player_hit(bullet: Node2D) -> void:
	print("[TestPlayer] 被敌弹命中!")

	if _power_level > 1:
		# 彩京式机制：Power>1时降级，不扣命
		_power_level -= 1
		print("[TestPlayer] Power降至 %d" % _power_level)
		_start_invincibility(0.5)
	else:
		# Power=1时扣命
		_lives -= 1
		print("[TestPlayer] 损失一条命! 剩余 %d" % _lives)
		if _lives <= 0:
			print("[TestPlayer] 游戏结束!")
			_player.visible = false
			_player.set_process(false)
		else:
			_power_level = 1
			_start_invincibility(_invincible_duration)
			# 重生位置
			if _player != null:
				_player.global_position = Vector2(_viewport_size.x / 2.0, _viewport_size.y - 150.0)

	# 移除命中的敌弹
	_enemy_bullets.erase(bullet)
	if is_instance_valid(bullet):
		bullet.queue_free()


## ============================================================
## 无敌与闪烁系统
## ============================================================

## 开始无敌状态
func _start_invincibility(duration: float) -> void:
	_is_invincible = true
	_invincible_timer = duration
	_blink_timer = 0.0
	print("[TestPlayer] 进入无敌状态 (%.1f秒)" % duration)


## 更新无敌状态和闪烁动画
func _update_invincibility(delta: float) -> void:
	if not _is_invincible:
		return

	_invincible_timer -= delta
	_blink_timer += delta

	# 闪烁：通过切换可见性实现
	if _player_visual != null:
		_player_visual.visible = fmod(_blink_timer, _blink_interval * 2.0) < _blink_interval

	# 无敌时间结束
	if _invincible_timer <= 0.0:
		_is_invincible = false
		_invincible_timer = 0.0
		_blink_timer = 0.0
		if _player_visual != null:
			_player_visual.visible = true
		print("[TestPlayer] 无敌状态结束")


## ============================================================
## 炸弹
## ============================================================

## 处理炸弹输入
func _handle_bomb_input() -> void:
	if Input.is_action_just_pressed("bomb"):
		use_bomb()


## 使用炸弹（清除所有敌弹 + 无敌）
func use_bomb() -> void:
	if _bombs <= 0:
		print("[TestPlayer] 炸弹已用完!")
		return

	_bombs -= 1
	print("[TestPlayer] 使用炸弹! (剩余 %d)" % _bombs)

	# 清除所有敌弹
	for bullet: Node2D in _enemy_bullets.duplicate():
		if is_instance_valid(bullet):
			bullet.queue_free()
	_enemy_bullets.clear()

	# 进入无敌
	_start_invincibility(_invincible_duration)

	# 全屏白色闪光
	var flash: ColorRect = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 1.0, 1.0, 0.6)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.name = "BombFlash"
	add_child(flash)

	var tween: Tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)


## ============================================================
## 额外调试键
## ============================================================

## 处理额外调试快捷键（每帧轮询项）
func _handle_extra_keys() -> void:
	_handle_bomb_input()


## 通过 _input 事件处理一次性按键（边沿检测）
## 避免 is_physical_key_pressed 的电平检测导致每帧重复触发
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	# 仅在按下边沿触发（排除重复 echo）
	if not key_event.pressed or key_event.echo:
		return

	match key_event.physical_keycode:
		KEY_G:
			_god_mode = not _god_mode
			print("[TestPlayer] 上帝模式: %s" % ("开启" if _god_mode else "关闭"))
		KEY_R:
			_reset_player_state()


## 重置玩家状态
func _reset_player_state() -> void:
	_lives = 3
	_bombs = 3
	_power_level = 1
	_score = 0
	_is_invincible = false
	_invincible_timer = 0.0
	_blink_timer = 0.0
	_charge_time = 0.0
	_shoot_timer = 0.0
	_is_shooting = false
	_charge_fired = false

	if _player != null:
		_player.global_position = Vector2(_viewport_size.x / 2.0, _viewport_size.y - 150.0)
		_player.visible = true
		_player.set_process(true)
	if _player_visual != null:
		_player_visual.visible = true

	# 清除所有子弹
	for bullet: Node2D in _player_bullets + _enemy_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	_player_bullets.clear()
	_enemy_bullets.clear()

	print("[TestPlayer] 玩家状态已重置")


## ============================================================
## HUD更新
## ============================================================

## 更新调试HUD
func _update_hud() -> void:
	if _debug_label == null:
		return

	# 注意：GDScript 4.7 中"圆括号内多行相邻字符串拼接 + % 格式化"会触发
	# "Expected closing ')' after grouping expression" 解析错误。
	# 故先以 + 显式拼接构造格式串，再单独执行 % 格式化。
	var fmt: String = (
		"[PlayerTest]\n"
		+ "FPS: %d\n"
		+ "Lives: %d | Bombs: %d | Power: %d\n"
		+ "Score: %d\n"
		+ "Charge: %.2f / %.1f\n"
		+ "Invincible: %s | GodMode: %s\n"
		+ "PlayerBullets: %d | EnemyBullets: %d\n"
		+ "[G]上帝模式 [R]重置 [Z/J]射击 [X/K]炸弹"
	)
	_debug_label.text = fmt % [
		Engine.get_frames_per_second(),
		_lives,
		_bombs,
		_power_level,
		_score,
		_charge_time,
		_charge_threshold,
		"ON" if _is_invincible else "OFF",
		"ON" if _god_mode else "OFF",
		_player_bullets.size(),
		_enemy_bullets.size()
	]
