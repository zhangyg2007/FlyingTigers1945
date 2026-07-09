## 测试关卡脚本
## 用于在Godot编辑器中快速测试核心玩法（移动、射击、敌机生成、碰撞等）
## 不依赖任何外部场景资源，全部使用代码动态创建占位节点
## 可在编辑器中直接运行此场景进行调试
extends Node2D

## ============================================================
## 内部变量
## ============================================================

## 玩家占位节点（CharacterBody2D）
var _player: CharacterBody2D = null

## 玩家占位Sprite（ColorRect）
var _player_visual: ColorRect = null

## 当前分数
var _score: int = 0

## 玩家Power等级（1~4）
var _power_level: int = 1

## 玩家炸弹数量
var _bombs: int = 3

## 玩家生命数
var _lives: int = 3

## 玩家速度（像素/秒）
var _player_speed: float = 250.0

## 射击间隔（秒）
var _shoot_interval: float = 0.12

## 射击计时器
var _shoot_timer: float = 0.0

## 是否正在按住射击键
var _is_shooting: bool = false

## 自动生成敌机计时器
var _enemy_spawn_timer: float = 0.0

## 自动生成敌机间隔（秒）
var _enemy_spawn_interval: float = 2.0

## 测试用敌机列表
var _test_enemies: Array[Node2D] = []

## 测试用子弹列表
var _test_bullets: Array[Node2D] = []

## 炸弹闪光效果节点
var _bomb_flash: ColorRect = null

## 炸弹闪光持续时间
var _bomb_flash_timer: float = 0.0

## 调试信息输出间隔（秒）
var _debug_print_timer: float = 0.0

## 调试信息输出间隔（秒）
const DEBUG_PRINT_INTERVAL: float = 2.0

## 视口尺寸缓存
var _viewport_size: Vector2 = Vector2.ZERO

## 背景节点
var _background: ColorRect = null

## 调试信息Label节点
var _debug_label: Label = null


## ============================================================
## 生命周期
## ============================================================

func _ready() -> void:
	# 缓存视口尺寸
	_viewport_size = get_viewport_rect().size

	# 1. 创建深蓝色背景（模拟天空）
	_create_background()

	# 2. 创建玩家战机占位
	_create_player()

	# 3. 创建调试HUD
	_create_debug_hud()

	# 4. 初始化GameManager状态（便于测试）
	_init_game_state()

	print("========================================")
	print("  [TestStage] 测试关卡已启动")
	print("  操作: WASD/方向键移动, Z/J射击, X/K炸弹")
	print("  数字键: 1=普通敌机 2=快速敌机 3=BOSS 4=全屏炸弹 5=切换Power")
	print("========================================")


func _process(delta: float) -> void:
	# 更新玩家移动
	_update_player_movement(delta)

	# 更新射击
	_update_shooting(delta)

	# 更新子弹移动
	_update_bullets(delta)

	# 更新敌机移动
	_update_enemies(delta)

	# 自动生成敌机
	_update_enemy_spawning(delta)

	# 更新炸弹闪光效果
	_update_bomb_flash(delta)

	# 更新调试信息输出
	_update_debug_info(delta)

	# 处理数字键调试指令
	_handle_debug_keys()


## ============================================================
## 场景搭建
## ============================================================

## 创建深蓝色天空背景
func _create_background() -> void:
	_background = ColorRect.new()
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.color = Color(0.05, 0.08, 0.2, 1.0)  # 深蓝色
	add_child(_background)
	_background.name = "Background"


## 创建玩家战机占位节点
## 使用ColorRect 32x32作为占位Sprite，附带CollisionShape2D
func _create_player() -> void:
	# 创建CharacterBody2D作为玩家
	_player = CharacterBody2D.new()
	_player.name = "PlayerTest"
	_player.position = Vector2(_viewport_size.x / 2.0, _viewport_size.y - 100.0)
	add_child(_player)

	# 玩家碰撞层：Layer1=Player
	_player.collision_layer = 0
	_player.collision_mask = 0
	_player.set_collision_layer_value(1, true)  # Layer1 = Player

	# 创建CollisionShape2D（矩形碰撞框）
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = Vector2(28, 32)
	collision_shape.shape = rect_shape
	_player.add_child(collision_shape)
	collision_shape.name = "CollisionShape2D"

	# 创建ColorRect作为占位Sprite（绿色=玩家）
	_player_visual = ColorRect.new()
	_player_visual.size = Vector2(32, 32)
	_player_visual.position = Vector2(-16, -16)
	_player_visual.color = Color(0.2, 0.9, 0.3, 1.0)  # 绿色
	_player.add_child(_player_visual)
	_player_visual.name = "Visual"

	# 创建判定点可视化（中心小红点）
	var hitbox_dot: ColorRect = ColorRect.new()
	hitbox_dot.size = Vector2(4, 4)
	hitbox_dot.position = Vector2(-2, -2)
	hitbox_dot.color = Color(1.0, 0.0, 0.0, 1.0)
	_player.add_child(hitbox_dot)
	hitbox_dot.name = "HitboxDot"


## 创建调试HUD显示
func _create_debug_hud() -> void:
	# 使用CanvasLayer确保HUD始终在最上层
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "DebugHUD"
	add_child(canvas_layer)

	# 调试信息Label
	_debug_label = Label.new()
	_debug_label.anchor_left = 0.0
	_debug_label.anchor_top = 0.0
	_debug_label.offset_left = 10.0
	_debug_label.offset_top = 10.0
	_debug_label.add_theme_font_size_override("font_size", 16)
	_debug_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0, 1.0))
	canvas_layer.add_child(_debug_label)


## 初始化游戏状态
func _init_game_state() -> void:
	if GameManager:
		GameManager.set_state(GameManager.State.PLAYING)


## ============================================================
## 玩家移动
## ============================================================

## 更新玩家移动（8方向）
func _update_player_movement(_delta: float) -> void:
	if _player == null:
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_player.velocity = input_dir * _player_speed
	_player.move_and_slide()

	# 限制在屏幕范围内
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

		if _shoot_timer >= _shoot_interval:
			_shoot_timer -= _shoot_interval
			_fire_player_bullet()
	else:
		_is_shooting = false
		_shoot_timer = 0.0


## 发射玩家子弹（根据Power等级改变模式）
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
## [param local_offset] 相对玩家的偏移位置
## [param dir] 子弹飞行方向
func _spawn_player_bullet(local_offset: Vector2, dir: Vector2) -> void:
	var bullet: ColorRect = ColorRect.new()
	bullet.size = Vector2(6, 12)
	bullet.color = Color(1.0, 1.0, 0.0, 1.0)  # 黄色=玩家弹
	bullet.position = _player.global_position + local_offset - Vector2(3, 6)
	bullet.name = "PlayerBullet"

	# 存储速度和方向到meta
	bullet.set_meta("speed", 500.0)
	bullet.set_meta("direction", dir)
	bullet.set_meta("is_player_bullet", true)

	add_child(bullet)
	_test_bullets.append(bullet)


## ============================================================
## 敌机系统
## ============================================================

## 更新自动敌机生成
func _update_enemy_spawning(delta: float) -> void:
	_enemy_spawn_timer += delta
	if _enemy_spawn_timer >= _enemy_spawn_interval:
		_enemy_spawn_timer -= _enemy_spawn_interval
		_spawn_test_enemy("normal")


## 生成测试敌机
## [param enemy_type] 敌机类型: "normal", "fast", "boss"
func _spawn_test_enemy(enemy_type: String) -> void:
	var enemy: CharacterBody2D = CharacterBody2D.new()
	enemy.name = "TestEnemy_%s" % enemy_type

	# 根据类型设置不同属性
	match enemy_type:
		"normal":
			enemy.position = Vector2(
				randf_range(50.0, _viewport_size.x - 50.0),
				-30.0
			)
			_create_enemy_visual(enemy, Vector2(28, 28), Color(0.9, 0.2, 0.2, 1.0))
			enemy.set_meta("speed", 100.0)
			enemy.set_meta("hp", 3)
			enemy.set_meta("score_value", 100)
			enemy.set_meta("type", "normal")
		"fast":
			enemy.position = Vector2(
				randf_range(50.0, _viewport_size.x - 50.0),
				-30.0
			)
			_create_enemy_visual(enemy, Vector2(24, 24), Color(0.9, 0.5, 0.0, 1.0))
			enemy.set_meta("speed", 200.0)
			enemy.set_meta("hp", 1)
			enemy.set_meta("score_value", 200)
			enemy.set_meta("type", "fast")
		"boss":
			enemy.position = Vector2(_viewport_size.x / 2.0, -80.0)
			_create_enemy_visual(enemy, Vector2(64, 64), Color(0.8, 0.0, 0.8, 1.0))
			enemy.set_meta("speed", 40.0)
			enemy.set_meta("hp", 50)
			enemy.set_meta("score_value", 5000)
			enemy.set_meta("type", "boss")

	# 设置碰撞层：Layer4=Enemy
	enemy.collision_layer = 0
	enemy.collision_mask = 0
	enemy.set_collision_layer_value(4, true)
	enemy.set_collision_mask_value(2, true)  # 检测玩家弹

	add_child(enemy)
	_test_enemies.append(enemy)

	print("[TestStage] 生成敌机: %s (HP=%d, 速度=%.0f)" % [
		enemy_type,
		enemy.get_meta("hp"),
		enemy.get_meta("speed")
	])


## 创建敌机占位视觉
func _create_enemy_visual(parent: Node2D, size: Vector2, color: Color) -> void:
	var visual: ColorRect = ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = color
	parent.add_child(visual)
	visual.name = "Visual"


## ============================================================
## 更新逻辑
## ============================================================

## 更新所有子弹位置和碰撞
func _update_bullets(delta: float) -> void:
	var bullets_to_remove: Array[Node2D] = []

	for bullet: Node2D in _test_bullets:
		if not is_instance_valid(bullet):
			bullets_to_remove.append(bullet)
			continue

		var speed: float = bullet.get_meta("speed", 500.0)
		var dir: Vector2 = bullet.get_meta("direction", Vector2.UP)
		bullet.position += dir * speed * delta

		# 检测与敌机碰撞
		if bullet.get_meta("is_player_bullet", true):
			for enemy: Node2D in _test_enemies:
				if not is_instance_valid(enemy):
					continue
				var enemy_radius: float = _get_enemy_radius(enemy)
				if bullet.global_position.distance_to(enemy.global_position) < enemy_radius + 6.0:
					# 命中敌机
					var hp: int = enemy.get_meta("hp", 1)
					hp -= 1
					enemy.set_meta("hp", hp)
					bullets_to_remove.append(bullet)

					# 命中闪白效果
					_flash_enemy_hit(enemy)

					if hp <= 0:
						# 敌机被击毁
						_score += enemy.get_meta("score_value", 100)
						_destroy_enemy(enemy)
					break

		# 超出屏幕移除
		if (bullet.position.y < -50.0
			or bullet.position.y > _viewport_size.y + 50.0
			or bullet.position.x < -50.0
			or bullet.position.x > _viewport_size.x + 50.0):
			bullets_to_remove.append(bullet)

	# 移除已标记的子弹
	for bullet: Node2D in bullets_to_remove:
		_test_bullets.erase(bullet)
		if is_instance_valid(bullet):
			bullet.queue_free()


## 更新所有敌机位置
func _update_enemies(delta: float) -> void:
	var enemies_to_remove: Array[Node2D] = []

	for enemy: Node2D in _test_enemies:
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
			continue

		var speed: float = enemy.get_meta("speed", 100.0)
		enemy.position.y += speed * delta

		# Boss特殊行为：到屏幕上方后缓慢左右移动
		if enemy.get_meta("type", "") == "boss" and enemy.position.y >= 100.0:
			enemy.position.x += sin(Time.get_ticks_msec() * 0.001) * 60.0 * delta

		# 检测与玩家碰撞
		if _player != null and is_instance_valid(_player):
			var enemy_radius: float = _get_enemy_radius(enemy)
			if _player.global_position.distance_to(enemy.global_position) < enemy_radius + 16.0:
				# 碰撞处理：扣命或降Power
				if _power_level > 1:
					_power_level -= 1
					print("[TestStage] 碰撞! Power降至 %d" % _power_level)
					_destroy_enemy(enemy)
				else:
					_lives -= 1
					print("[TestStage] 碰撞! 损失一条命 (剩余 %d)" % _lives)
					_destroy_enemy(enemy)
					# 重生位置
					_player.global_position = Vector2(_viewport_size.x / 2.0, _viewport_size.y - 100.0)

		# 超出屏幕下方移除
		if enemy.position.y > _viewport_size.y + 100.0:
			enemies_to_remove.append(enemy)

	for enemy: Node2D in enemies_to_remove:
		_test_enemies.erase(enemy)
		if is_instance_valid(enemy):
			enemy.queue_free()


## 获取敌机的碰撞半径（近似值）
func _get_enemy_radius(enemy: Node2D) -> float:
	match enemy.get_meta("type", ""):
		"boss":
			return 32.0
		"fast":
			return 12.0
		_:
			return 14.0


## 敌机受击闪白效果
func _flash_enemy_hit(enemy: Node2D) -> void:
	var visual: ColorRect = enemy.get_node_or_null("Visual")
	if visual == null:
		return
	var original_color: Color = visual.color
	visual.color = Color(1.0, 1.0, 1.0, 1.0)

	# 使用Timer恢复颜色
	var timer: Timer = Timer.new()
	timer.wait_time = 0.06
	timer.one_shot = true
	enemy.add_child(timer)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(visual):
			visual.color = original_color
		timer.queue_free()
	)
	timer.start()


## 销毁敌机（带爆炸效果）
func _destroy_enemy(enemy: Node2D) -> void:
	# 生成爆炸占位特效（白色方块闪烁）
	var explosion: ColorRect = ColorRect.new()
	explosion.size = Vector2(40, 40)
	explosion.position = enemy.global_position - Vector2(20, 20)
	explosion.color = Color(1.0, 0.8, 0.0, 1.0)
	explosion.name = "Explosion"
	add_child(explosion)

	# 闪白→消失
	var tween: Tween = create_tween()
	tween.tween_property(explosion, "color", Color(1.0, 1.0, 1.0, 0.0), 0.3)
	tween.tween_callback(explosion.queue_free)

	_test_enemies.erase(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()


## ============================================================
## 炸弹效果
## ============================================================

## 触发全屏炸弹效果
func _trigger_bomb() -> void:
	if _bombs <= 0:
		print("[TestStage] 炸弹已用完!")
		return

	_bombs -= 1
	print("[TestStage] 全屏炸弹! (剩余 %d)" % _bombs)

	# 消灭所有敌机
	for enemy: Node2D in _test_enemies.duplicate():
		if is_instance_valid(enemy):
			_score += enemy.get_meta("score_value", 100)
			_destroy_enemy(enemy)

	# 清除所有敌方子弹
	for bullet: Node2D in _test_bullets.duplicate():
		if is_instance_valid(bullet) and not bullet.get_meta("is_player_bullet", true):
			bullet.queue_free()
			_test_bullets.erase(bullet)

	# 创建全屏白色闪光效果
	if _bomb_flash == null:
		_bomb_flash = ColorRect.new()
		_bomb_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_bomb_flash.color = Color(1.0, 1.0, 1.0, 0.8)
		_bomb_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bomb_flash)

	_bomb_flash_timer = 0.5  # 闪光持续0.5秒
	_bomb_flash.visible = true
	_bomb_flash.color.a = 0.8


## 更新炸弹闪光效果
func _update_bomb_flash(delta: float) -> void:
	if _bomb_flash == null or _bomb_flash_timer <= 0.0:
		return

	_bomb_flash_timer -= delta
	var alpha: float = clampf(_bomb_flash_timer / 0.5, 0.0, 0.8)
	_bomb_flash.color.a = alpha

	if _bomb_flash_timer <= 0.0:
		_bomb_flash.visible = false


## ============================================================
## 调试指令处理
## ============================================================

## 处理数字键调试指令（每帧轮询项）
func _handle_debug_keys() -> void:
	# ui_page_up 使用 is_action_just_pressed（边沿检测），可保留每帧轮询
	if Input.is_action_just_pressed("ui_page_up"):
		_spawn_test_enemy("normal")


## 通过 _input 事件处理一次性按键（边沿检测）
## 避免 is_physical_key_pressed 的电平检测导致每帧重复触发
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.physical_keycode:
		KEY_1:
			_spawn_test_enemy("normal")
		KEY_2:
			_spawn_test_enemy("fast")
		KEY_3:
			_spawn_test_enemy("boss")
		KEY_4:
			_trigger_bomb()
		KEY_5:
			_power_level = (_power_level % 4) + 1
			print("[TestStage] Power等级切换为: %d" % _power_level)


## 更新调试信息输出
func _update_debug_info(delta: float) -> void:
	_debug_print_timer += delta
	if _debug_print_timer >= DEBUG_PRINT_INTERVAL:
		_debug_print_timer = 0.0
		_print_debug_info()

	# 更新HUD标签
	if _debug_label != null:
		# 注意：GDScript 4.7 中"圆括号内多行相邻字符串拼接 + % 格式化"会触发
		# "Expected closing ')' after grouping expression" 解析错误。
		# 故先以 + 显式拼接构造格式串，再单独执行 % 格式化。
		var fmt: String = (
			"FPS: %d\n"
			+ "Score: %d\n"
			+ "Lives: %d | Bombs: %d | Power: %d\n"
			+ "Enemies: %d | Bullets: %d\n"
			+ "[1]普通敌机 [2]快速敌机 [3]BOSS [4]炸弹 [5]Power"
		)
		_debug_label.text = fmt % [
			Engine.get_frames_per_second(),
			_score,
			_lives,
			_bombs,
			_power_level,
			_test_enemies.size(),
			_test_bullets.size()
		]


## 打印调试信息到控制台
func _print_debug_info() -> void:
	var pool_stats: String = "无"
	if PoolManager:
		var stats: Dictionary = PoolManager.get_pool_stats()
		if stats.is_empty():
			pool_stats = "空"
		else:
			var stat_strings: PackedStringArray = []
			for key: String in stats:
				var info: Dictionary = stats[key]
				var short_key: String = key.get_file()
				stat_strings.append("%s(%d/%d)" % [short_key, info["active"], info["max_size"]])
			pool_stats = ", ".join(stat_strings)

	print("[TestStage] FPS=%d | Score=%d | Lives=%d | Bombs=%d | Power=%d | Enemies=%d | Bullets=%d | Pool=[%s]" % [
		Engine.get_frames_per_second(),
		_score,
		_lives,
		_bombs,
		_power_level,
		_test_enemies.size(),
		_test_bullets.size(),
		pool_stats
	])
