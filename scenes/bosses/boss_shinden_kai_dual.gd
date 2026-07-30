## 震电改·赤玄双机编队管理器
## 容器节点（Node2D），内含 RedBoss / BlackBoss 两个 CharacterBody2D（各自挂 boss_base.gd）。
## 本脚本只负责双 Boss 的滚筒翻滚动画（三图切换 + scale.x = cos(θ)）。
## 每个 Boss 的入场/移动/攻击/HP 由 boss_base.gd 自行处理。
class_name BossShindenKaiDual extends Node2D

## 滚筒翻滚动画（三图切换）
var _roll_angle: Dictionary = {"red": 0.0, "black": 0.0}

## 侧视切换阈值（|cos| ≤ 此值时显示侧视图）
const SIDE_THRESHOLD: float = 0.15

@onready var _red_boss: CharacterBody2D = $RedBoss
@onready var _black_boss: CharacterBody2D = $BlackBoss


func _process(delta: float) -> void:
	# 赤机翻滚 300°/s，玄机翻滚 280°/s
	_update_roll(_red_boss, delta, "red", 300.0)
	_update_roll(_black_boss, delta, "black", 280.0)


## 更新单个 Boss 的滚筒翻滚动画
func _update_roll(boss: Node, delta: float, key: String, roll_speed: float) -> void:
	_roll_angle[key] += roll_speed * delta
	var c: float = cos(deg_to_rad(_roll_angle[key]))
	var abs_c: float = abs(c)
	var sprite_top: Sprite2D = boss.get_node_or_null("SpriteTop")
	var sprite_side: Sprite2D = boss.get_node_or_null("SpriteSide")
	var sprite_bottom: Sprite2D = boss.get_node_or_null("SpriteBottom")
	if sprite_top == null or sprite_bottom == null or sprite_side == null:
		return
	if abs_c > SIDE_THRESHOLD:
		var is_top: bool = c > 0
		sprite_top.visible = is_top
		sprite_bottom.visible = not is_top
		sprite_side.visible = false
		if is_top:
			sprite_top.scale.x = abs_c
		else:
			sprite_bottom.scale.x = abs_c
	else:
		sprite_top.visible = false
		sprite_bottom.visible = false
		sprite_side.visible = true
