## J7W 震电杂兵 — 滚筒翻滚版
## 继承 EnemyBase，复用直线下移/路径移动/HP/掉落/爆炸/对象池等基类逻辑。
## 通过三图切换（俯视→侧视→仰视）+ scale.x = cos(θ) 实现绕机身长轴的滚筒翻滚动画。
## 碰撞层：Layer4=Enemy，检测 Layer2=PlayerBullet, Layer1=Player（由 EnemyBase._ready 设置）
class_name EnemyJ7wShinden extends EnemyBase

## 滚筒翻滚速度（度/秒），540°/s ≈ 1.5 秒翻一圈
@export var roll_speed: float = 540.0

## 侧视切换阈值（|cos| ≤ 此值时显示侧视图，约 9° 宽的侧视区间）
@export var side_threshold: float = 0.15

## 当前滚筒角度（度，持续累积）
var _roll_angle: float = 0.0

@onready var sprite_top: Sprite2D = $SpriteTop
@onready var sprite_side: Sprite2D = $SpriteSide
@onready var sprite_bottom: Sprite2D = $SpriteBottom


func _process(delta: float) -> void:
	# 先调用父类：处理移动/弹幕射击/屏幕外归还
	super._process(delta)

	# 持续滚筒旋转
	_roll_angle += roll_speed * delta
	var c: float = cos(deg_to_rad(_roll_angle))
	var abs_c: float = abs(c)

	if abs_c > side_threshold:
		# 俯视或仰视区间：按 cos 正负切换，宽度跟随余弦缩放
		var is_top: bool = c > 0
		sprite_top.visible = is_top
		sprite_bottom.visible = not is_top
		sprite_side.visible = false
		if is_top:
			sprite_top.scale.x = abs_c
		else:
			sprite_bottom.scale.x = abs_c
	else:
		# 侧视区间：机翼朝向镜头，显示机身侧面轮廓
		sprite_top.visible = false
		sprite_bottom.visible = false
		sprite_side.visible = true
