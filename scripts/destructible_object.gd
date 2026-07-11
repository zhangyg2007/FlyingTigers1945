class_name DestructibleObject
extends Area2D
## 可摧毁物体（M3-C P1）
## 用于 destroy_targets 事件：渡桥、碉堡等静态可摧毁目标。
## 被玩家子弹击中时扣 HP，HP 归零时摧毁并通知 EventManager。
##
## 碰撞层：Layer4 = Enemy（被 Layer2 = PlayerBullet 击中）
## EventManager 通过 get_tree().get_first_node_in_group("event_manager") 查找。

## 目标唯一标识符（由 EventManager 实例化时设置，对应 JSON 中的 target.targets[].id）
@export var object_id: String = ""

## 最大生命值
@export var max_hp: int = 30

## 摧毁后切换的纹理（可选，如 bridge_broken.png）
@export var broken_texture: Texture2D = null

## 当前生命值
var current_hp: int = 0

## 是否已被摧毁（防止重复触发）
var _is_destroyed: bool = false

## Sprite 节点引用
@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null


func _ready() -> void:
	# 初始化 HP（若未由 EventManager 设置，则使用 max_hp）
	if current_hp <= 0:
		current_hp = max_hp

	# 碰撞层：Layer4 = Enemy，检测 Layer2 = PlayerBullet
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)  # 位于 Layer4 = Enemy
	set_collision_mask_value(2, true)   # 检测 Layer2 = PlayerBullet

	# 连接碰撞信号
	area_entered.connect(_on_area_entered)


## 受到伤害
## [param damage]: 伤害值（由玩家子弹传入）
func take_damage(damage: int) -> void:
	if _is_destroyed:
		return
	current_hp -= damage
	if current_hp <= 0:
		_destroy()


## 摧毁处理：切换破碎纹理、通知 EventManager、延迟移除
func _destroy() -> void:
	if _is_destroyed:
		return
	_is_destroyed = true

	# 切换为破碎纹理（如果配置了）
	if broken_texture != null and _sprite != null:
		_sprite.texture = broken_texture

	# 通知 EventManager 目标被摧毁
	var em: Node = _get_event_manager()
	if em != null and em.has_method("report_target_destroyed"):
		em.report_target_destroyed(object_id)

	# 禁用碰撞（防止继续受击）
	collision_layer = 0
	collision_mask = 0

	# 延迟移除节点（让破碎纹理短暂显示 2 秒）
	get_tree().create_timer(2.0).timeout.connect(_remove_self)


## 延迟移除自身
func _remove_self() -> void:
	queue_free()


## 碰撞回调：检测玩家子弹（有 damage 属性的 Area2D）
func _on_area_entered(area: Node) -> void:
	if _is_destroyed:
		return
	# 检测玩家子弹（BulletBase 有 damage 属性）
	if "damage" in area:
		take_damage(int(area["damage"]))


## 获取场景中的 EventManager 节点
## 通过 "event_manager" 组查找，使用 duck-typing 避免循环依赖
func _get_event_manager() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var node: Node = tree.get_first_node_in_group("event_manager")
	if node != null and node.has_method("report_target_destroyed"):
		return node
	return null
