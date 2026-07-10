## 敌机基类
## 所有敌机的通用基类，支持直线下移和路径移动
## HP系统、掉落道具、爆炸特效、对象池归还
## 碰撞层：Layer4=Enemy, 检测 Layer2=PlayerBullet, Layer1=Player
class_name EnemyBase extends CharacterBody2D

## 敌机死亡信号，参数为该敌机的分值
signal enemy_died(score_value: int)

## 敌机被击中信号
signal enemy_hit()

## 最大生命值
@export var hp: int = 3

## 移动速度（像素/秒）
@export var speed: float = 80.0

## 击毁得分
@export var score_value: int = 100

## 道具掉落概率（0.0 ~ 1.0）
@export var drop_chance: float = 0.3

## 可选的移动路径资源 (Resource extending Resource with get_point(position))
@export var move_path: Resource = null

## 是否循环路径
@export var loop_path: bool = false

## 当前生命值（运行时）
var current_hp: int = 0

## 道具场景数组（从中随机选取掉落）
var _powerup_scenes: Array[PackedScene] = []

## 路径跟随进度
var _path_progress: float = 0.0

## 是否正在沿路径移动
var _has_path: bool = false

## 爆炸特效场景（子类或场景设置器中赋值）
var _explosion_scene: PackedScene = null

## 子弹场景数组（用于弹幕射击）
var _bullet_scenes: Array[PackedScene] = []

## 射击计时器
var _shoot_timer: float = 0.0

## 射击间隔（秒），子类覆盖
var _shoot_interval: float = 2.0

## 敌机类型标识（由 SpawnManager.setup 传入，如 "ki27_fighter"）
var _enemy_type_id: String = ""

## 编队内索引（由 SpawnManager.setup 传入）
var _index_in_wave: int = 0

## 编队总数（由 SpawnManager.setup 传入）
var _total_in_wave: int = 1


func _ready() -> void:
	# 设置碰撞层：Layer4 = Enemy
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)   # Layer4 = Enemy
	set_collision_mask_value(2, true)   # 检测 Layer2 = PlayerBullet
	set_collision_mask_value(1, true)   # 检测 Layer1 = Player（用于碰撞敌机）

	current_hp = hp
	_has_path = move_path != null

	# 连接 Hitbox Area2D 信号（如果场景中存在 Hitbox 子节点）
	# CharacterBody2D 没有 body_entered/area_entered 信号，需要 Area2D 子节点检测碰撞
	if has_node("Hitbox"):
		var hitbox: Area2D = $Hitbox
		if not hitbox.area_entered.is_connected(_on_area_entered):
			hitbox.area_entered.connect(_on_area_entered)
		if not hitbox.body_entered.is_connected(_on_body_entered):
			hitbox.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# 按路径或直线移动
	if _has_path:
		_move_along_path(delta)
	else:
		_move_straight(delta)

	# 弹幕射击计时
	_update_shooting(delta)

	# 屏幕外检测（超出下方很远则归还）
	if global_position.y > get_viewport_rect().size.y + 200:
		_return_to_pool()


## 直线下移
func _move_straight(delta: float) -> void:
	position.y += speed * delta


## 沿路径移动（使用 PathFollow2D 的逻辑）
func _move_along_path(delta: float) -> void:
	# 如果配置了路径资源，沿路径推进
	if move_path == null:
		return

	_path_progress += speed * delta

	# 尝试获取路径点位置
	if move_path.has_method("get_point_position"):
		var path_pos: Vector2 = move_path.get_point_position(_path_progress)
		global_position = path_pos
	elif move_path.has_method("sample"):
		var path_pos: Vector2 = move_path.sample(_path_progress)
		global_position = path_pos

	# 循环路径处理
	if loop_path and move_path.has_method("get_total_length"):
		var total_length: float = move_path.get_total_length()
		if total_length > 0 and _path_progress >= total_length:
			_path_progress -= total_length


## 更新弹幕射击计时
func _update_shooting(delta: float) -> void:
	if _shoot_interval <= 0 or _bullet_scenes.is_empty():
		return

	_shoot_timer += delta
	if _shoot_timer >= _shoot_interval:
		_shoot_timer = 0.0
		shoot_pattern()


## 受击处理
## [param damage] 受到的伤害值
func hit(damage: int) -> void:
	current_hp -= damage
	enemy_hit.emit()

	# 受击闪白效果
	_flash_white()

	if current_hp <= 0:
		die()


## 死亡处理
func die() -> void:
	# 播放爆炸特效
	_spawn_explosion()

	# 发送死亡信号（加分等）
	enemy_died.emit(score_value)

	# 随机掉落道具
	_try_drop_powerup()

	# 归还对象池或销毁
	_return_to_pool()


## 生成爆炸特效
func _spawn_explosion() -> void:
	if _explosion_scene == null:
		return

	var viewport: Node = get_viewport()
	if viewport == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var explosion: Node2D = _explosion_scene.instantiate()
	explosion.global_position = global_position
	parent_node.add_child(explosion)

	# 如果特效有生存时间则自动销毁
	if explosion.has_method("start"):
		explosion.start()
	elif explosion is GPUParticles2D or explosion is CPUParticles2D:
		# 粒子特效播放完毕后自动销毁
		var timer: Timer = Timer.new()
		timer.wait_time = 1.0
		timer.one_shot = true
		explosion.add_child(timer)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(explosion):
				explosion.queue_free()
		)
		timer.start()


## 尝试掉落道具
func _try_drop_powerup() -> void:
	if _powerup_scenes.is_empty():
		return

	if randf() > drop_chance:
		return

	# 随机选择一个道具
	var powerup_scene: PackedScene = _powerup_scenes[randi() % _powerup_scenes.size()]
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var powerup: Node = powerup_scene.instantiate()
	powerup.global_position = global_position
	parent_node.add_child(powerup)


## 虚方法：弹幕射击模式，子类覆盖实现不同弹幕
func shoot_pattern() -> void:
	# 默认实现：向下发射一发直线弹
	if _bullet_scenes.is_empty():
		return

	var bullet_scene: PackedScene = _bullet_scenes[0]
	var bullet: BulletBase = bullet_scene.instantiate() as BulletBase
	if bullet == null:
		return

	bullet.global_position = global_position
	bullet.is_player_bullet = false
	bullet.direction = Vector2.DOWN
	bullet.speed = 200.0

	var parent_node: Node = get_parent()
	if parent_node != null:
		parent_node.add_child(bullet)


## 被玩家子弹击中（Area2D碰撞）
func _on_area_entered(area: Node) -> void:
	if area is BulletBase and area.is_player_bullet:
		hit(area.damage)
		# 子弹命中后由子弹自身管理销毁


## 与玩家碰撞（Body碰撞）
func _on_body_entered(body: Node) -> void:
	if body is PlayerBase:
		# 敌机碰撞到玩家，降低玩家Power或击杀
		body.on_enemy_collision(self)


## 受击闪白效果
func _flash_white() -> void:
	# 查找Sprite2D子节点
	var sprite: Sprite2D = _find_sprite(self)
	if sprite == null or sprite.material == null:
		return

	# 使用ShaderMaterial闪白
	if sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("flash", 1.0)
		# 用一个极短Timer恢复
		var tree: SceneTree = get_tree()
		if tree != null:
			var timer: Timer = Timer.new()
			add_child(timer)
			timer.wait_time = 0.05
			timer.one_shot = true
			timer.timeout.connect(func() -> void:
				if is_instance_valid(sprite) and sprite.material is ShaderMaterial:
					sprite.material.set_shader_parameter("flash", 0.0)
				timer.queue_free()
			)
			timer.start()


## 递归查找Sprite2D节点
func _find_sprite(node: Node) -> Sprite2D:
	if node is Sprite2D:
		return node
	for child: Node in node.get_children():
		var result: Sprite2D = _find_sprite(child)
		if result != null:
			return result
	return null


## 归还到对象池
## 优先通过 PoolManager 归还（如果对象由 PoolManager 创建），否则直接释放
func _return_to_pool() -> void:
	set_process(false)
	set_physics_process(false)
	# 通过 PoolManager 归还（内部会判断是否属于已注册池，不属于则直接 queue_free）
	if PoolManager.has_method("return_object"):
		PoolManager.return_object(self)
	else:
		queue_free()


## 重置状态（对象池归还时调用）
func reset_state() -> void:
	current_hp = hp
	_path_progress = 0.0
	_shoot_timer = 0.0
	_has_path = move_path != null
	_enemy_type_id = ""
	_index_in_wave = 0
	_total_in_wave = 1
	position = Vector2.ZERO
	velocity = Vector2.ZERO
	set_process(true)
	set_physics_process(true)
	visible = true


## 设置道具场景数组
func set_powerup_scenes(scenes: Array[PackedScene]) -> void:
	_powerup_scenes = scenes


## 设置子弹场景数组
func set_bullet_scenes(scenes: Array[PackedScene]) -> void:
	_bullet_scenes = scenes


## 设置爆炸特效场景
func set_explosion_scene(scene: PackedScene) -> void:
	_explosion_scene = scene


## ============================================================
## SpawnManager 集成接口
## ============================================================

## 由 SpawnManager 在生成敌人时调用，传入波次配置参数
## [param config]: 字典，可含字段：
##   - enemy_type (String): 敌机类型标识（如 "ki27_fighter"）
##   - speed_mult (float): 速度倍率
##   - path_id (String): 路径标识（如 "straight"/"dive"/"boss_enter"）
##   - index_in_wave (int): 编队内索引
##   - total_in_wave (int): 编队总数
func setup(config: Dictionary) -> void:
	# 应用速度倍率
	var speed_mult: float = config.get("speed_mult", 1.0)
	speed *= speed_mult

	# 存储类型与编队信息（子类可读取用于行为差异化）
	_enemy_type_id = config.get("enemy_type", "")
	_index_in_wave = config.get("index_in_wave", 0)
	_total_in_wave = config.get("total_in_wave", 1)

	# 路径处理：path_id 为字符串标识，"straight" 表示直线下移
	# 非 straight 路径需要加载 res://resources/paths/ 下的 Curve2D 资源
	# 当前路径资源尚未创建，非 straight 路径暂时回退为直线
	var path_id: String = config.get("path_id", "straight")
	if path_id != "straight" and path_id != "":
		var path_res: Resource = _try_load_path_resource(path_id)
		if path_res != null:
			move_path = path_res
			_has_path = true
		else:
			# 路径资源不存在，保持直线下移（已在 _ready 中设置 _has_path）
			pass

	# 重新初始化 HP（应用 setup 前的基础值，apply_difficulty 会再乘倍率）
	current_hp = hp


## 应用难度倍率到 HP（由 SpawnManager 在 setup 后调用）
## [param hp_mult]: HP 倍率（如 Easy=1.0, Hard=1.3~1.5）
func apply_difficulty(hp_mult: float) -> void:
	hp = maxi(1, int(round(float(hp) * hp_mult)))
	current_hp = hp


## 尝试加载路径资源
## [param path_id]: 路径标识字符串（如 "dive"/"sine"/"boss_enter"）
## [return]: Curve2D 资源，加载失败返回 null
func _try_load_path_resource(path_id: String) -> Resource:
	var path: String = "res://resources/paths/path_" + path_id + ".tres"
	if ResourceLoader.exists(path):
		return load(path)
	return null


## 获取敌机类型标识（供子类或调试读取）
func get_enemy_type_id() -> String:
	return _enemy_type_id


## 编队内索引（供子类实现编队差异化行为，如领头机 vs 翼机）
func get_index_in_wave() -> int:
	return _index_in_wave


## 编队总数
func get_total_in_wave() -> int:
	return _total_in_wave
