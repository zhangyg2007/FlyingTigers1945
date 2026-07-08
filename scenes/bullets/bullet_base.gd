## 子弹基类
## 所有子弹（玩家子弹和敌弹）的通用基类
## 玩家子弹：Layer2, 碰撞检测 Layer4(Enemy)
## 敌方子弹：Layer3, 碰撞检测 Layer1(Player)
## 屏幕外自动归还对象池/销毁
class_name BulletBase extends Area2D

## 命中目标信号
signal hit_target(target: Node2D)

## 移动速度（像素/秒）
@export var speed: float = 400.0

## 移动方向（单位向量）
@export var direction: Vector2 = Vector2.UP

## 伤害值
@export var damage: int = 1

## 是否为玩家子弹（决定碰撞层设置）
@export var is_player_bullet: bool = true

## 屏幕边界余量，超出此范围后销毁
@export var screen_margin: float = 50.0

## 对象池引用（可选，设置后超出屏幕归还池而非销毁）
var object_pool: ObjectPool = null

## 是否已被标记为待销毁（防止重复触发）
var _is_pending_destroy: bool = false


func _ready() -> void:
	# 根据子弹类型设置碰撞层和碰撞遮罩
	# Layer1=Player, Layer2=PlayerBullet, Layer3=EnemyBullet, Layer4=Enemy
	setup_collision_layers()
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## 根据子弹类型设置碰撞层
func setup_collision_layers() -> void:
	if is_player_bullet:
		# 玩家子弹：在 Layer2，检测 Layer4(Enemy)
		collision_layer = 0  # 先清空
		collision_mask = 0
		set_collision_layer_value(2, true)  # Layer2 = PlayerBullet
		set_collision_mask_value(4, true)   # 检测 Layer4 = Enemy
	else:
		# 敌弹：在 Layer3，检测 Layer1(Player)
		collision_layer = 0
		collision_mask = 0
		set_collision_layer_value(3, true)  # Layer3 = EnemyBullet
		set_collision_mask_value(1, true)   # 检测 Layer1 = Player


func _process(delta: float) -> void:
	if _is_pending_destroy:
		return

	# 沿方向移动
	position += direction.normalized() * speed * delta

	# 检测屏幕边界，超出则销毁/归还
	if _is_out_of_screen():
		_destroy()


## 检测是否超出屏幕边界
func _is_out_of_screen() -> bool:
	var viewport_rect: Rect2 = get_viewport_rect()
	var screen_pos: Vector2 = get_global_transform_with_canvas().origin

	return (
		screen_pos.x < -screen_margin
		or screen_pos.x > viewport_rect.size.x + screen_margin
		or screen_pos.y < -screen_margin
		or screen_pos.y > viewport_rect.size.y + screen_margin
	)


## 碰撞到物理体（CharacterBody2D等）
func _on_body_entered(body: Node) -> void:
	if _is_pending_destroy:
		return
	hit_target.emit(body)
	_on_hit(body)


## 碰撞到区域（Area2D）
func _on_area_entered(area: Node) -> void:
	if _is_pending_destroy:
		return
	# 只有玩家子弹需要检测敌机的Area2D碰撞
	if is_player_bullet and area is EnemyBase:
		hit_target.emit(area)
		_on_hit(area)


## 命中处理（可被子类覆盖）
## [param target] 被命中的目标
func _on_hit(target: Node) -> void:
	_destroy()


## 销毁/归还子弹
func _destroy() -> void:
	if _is_pending_destroy:
		return
	_is_pending_destroy = true

	if object_pool != null:
		object_pool.return_object(self)
	else:
		queue_free()


## 重置子弹状态（对象池归还时调用）
func reset_state() -> void:
	_is_pending_destroy = false
	position = Vector2.ZERO
	direction = Vector2.UP if is_player_bullet else Vector2.DOWN
	speed = 400.0
	damage = 1
	set_process(true)
	set_physics_process(true)
	visible = true


## 设置子弹方向（角度制）
## [param angle_deg] 角度（0=右，90=下，-90=上）
func set_direction_angle(angle_deg: float) -> void:
	direction = Vector2.from_angle(deg_to_rad(angle_deg))


## 设置子弹方向（弧度制）
## [param angle_rad] 弧度
func set_direction_angle_rad(angle_rad: float) -> void:
	direction = Vector2.from_angle(angle_rad)


## 设置子弹朝向目标位置
## [param target_pos] 目标位置（全局坐标）
func aim_at(target_pos: Vector2) -> void:
	direction = (target_pos - global_position).normalized()
