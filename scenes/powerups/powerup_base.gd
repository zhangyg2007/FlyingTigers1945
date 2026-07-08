## 道具基类
## 所有可拾取道具的通用基类
## 缓慢下移，屏幕外自动销毁
## 被玩家拾取时根据 type 触发效果（加Power/加炸弹/加分/回血）
## 带有浮动动画效果
class_name PowerupBase extends Area2D

## 道具类型枚举
enum PowerupType {
	POWER,   ## 增加火力等级
	BOMB,    ## 增加炸弹数量
	SCORE,   ## 加分
	MEDKIT,  ## 回复生命
}

## 道具类型
@export var powerup_type: PowerupType = PowerupType.POWER

## 下落速度（像素/秒）
@export var fall_speed: float = 60.0

## 浮动动画幅度（像素）
@export var float_amplitude: float = 4.0

## 浮动动画频率
@export var float_frequency: float = 3.0

## 道具效果值（Power加成等级、炸弹+1、分数值、回血量）
@export var effect_value: int = 1

## 屏幕边界余量
@export var screen_margin: float = 50.0

## 对象池引用（可选）
var object_pool: ObjectPool = null

## 内部计时器（用于浮动动画）
var _float_timer: float = 0.0

## 初始Y位置（用于浮动动画基准）
var _base_y: float = 0.0

## 是否已被标记为待销毁
var _is_pending_destroy: bool = false

## Sprite节点引用（用于浮动动画）
@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null


func _ready() -> void:
	# 设置碰撞层：Layer5 = PowerUp，检测 Layer1 = Player
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)  # Layer5 = PowerUp
	set_collision_mask_value(1, true)   # 检测 Layer1 = Player

	_base_y = global_position.y

	# 连接拾取信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _is_pending_destroy:
		return

	# 缓慢下移
	global_position.y += fall_speed * delta

	# 浮动动画
	_float_timer += delta * float_frequency
	var float_offset: float = sin(_float_timer * TAU) * float_amplitude
	if _sprite != null:
		_sprite.position.y = float_offset
	else:
		position.y = _base_y + float_offset
		_base_y = global_position.y - float_offset

	# 屏幕外销毁
	if _is_out_of_screen():
		_destroy()


## 检测是否超出屏幕边界
func _is_out_of_screen() -> bool:
	var viewport_rect: Rect2 = get_viewport_rect()
	var screen_pos: Vector2 = get_global_transform_with_canvas().origin

	return (
		screen_pos.y > viewport_rect.size.y + screen_margin
		or screen_pos.x < -screen_margin
		or screen_pos.x > viewport_rect.size.x + screen_margin
	)


## 拾取区域碰撞（Area2D）
func _on_area_entered(area: Node) -> void:
	if _is_pending_destroy:
		return
	# 检测玩家
	if area.collision_layer & 0b1:  # Layer1 = Player
		_apply_effect(area)
		_destroy()


## 拾取物理体碰撞（CharacterBody2D）
func _on_body_entered(body: Node) -> void:
	if _is_pending_destroy:
		return
	if body is PlayerBase:
		_apply_effect(body)
		_destroy()


## 根据道具类型应用效果
## [param player] 拾取该道具的玩家节点
func _apply_effect(player: Node) -> void:
	match powerup_type:
		PowerupType.POWER:
			player.add_power(effect_value)
		PowerupType.BOMB:
			player.add_bombs(effect_value)
		PowerupType.SCORE:
			player.add_score(effect_value * 1000)
		PowerupType.MEDKIT:
			player.heal(effect_value)


## 销毁/归还道具
func _destroy() -> void:
	if _is_pending_destroy:
		return
	_is_pending_destroy = true

	if object_pool != null:
		object_pool.return_object(self)
	else:
		queue_free()


## 重置道具状态（对象池归还时调用）
func reset_state() -> void:
	_is_pending_destroy = false
	_float_timer = 0.0
	_base_y = 0.0
	set_process(true)
	set_physics_process(true)
	visible = true
	if _sprite != null:
		_sprite.position = Vector2.ZERO
