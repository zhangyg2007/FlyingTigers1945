class_name HumpNarrowPassage
extends Node
## H1 驼峰绝径特殊机制：狭窄峡谷，碰撞峡谷壁即死
## 挂载到 LevelBase 下，通过信号监听玩家碰撞
## 玩家碰到峡谷壁（通过 collision_layer 检测）直接调用 player.take_damage(999)

@export var wall_damage: int = 999  # 碰撞伤害（一击必杀）

func _ready() -> void:
	# 监听玩家碰撞信号
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null:
		if player.has_signal("body_entered"):
			player.body_entered.connect(_on_player_body_entered)
		if player.has_signal("area_entered"):
			player.area_entered.connect(_on_player_area_entered)

func _on_player_body_entered(body: Node) -> void:
	_check_wall_collision(body)

func _on_player_area_entered(area: Node) -> void:
	_check_wall_collision(area)

func _check_wall_collision(node: Node) -> void:
	# 检测碰撞层是否为峡谷壁（Layer6 = Terrain/Wall）
	if node is CollisionObject2D:
		var col_obj: CollisionObject2D = node as CollisionObject2D
		if col_obj.get_collision_layer_value(6):  # Layer6 = Wall
			var player: Node = get_tree().get_first_node_in_group("player")
			if player != null and player.has_method("take_damage"):
				player.take_damage(wall_damage)
				print("[HumpNarrowPassage] 玩家撞击峡谷壁，一击必杀！")
