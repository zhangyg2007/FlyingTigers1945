## J8M 秋水火箭截击机 — 滚筒翻滚 + 火箭尾迹 + 燃料限时
## 继承 EnemyBase。全游戏最快敌机（speed=280），尾部蓝色火焰尾迹由 CPUParticles2D 实现。
## 翻滚速度 720°/s（2 圈/秒），侧视阈值更窄（0.12），匹配火箭高速冲刺。
## 燃料限时 2.5 秒，耗尽后进入加速冲刺模式（speed *= boost_speed_mult）。
## 碰撞层：Layer4=Enemy，检测 Layer2=PlayerBullet, Layer1=Player（由 EnemyBase._ready 设置）
class_name EnemyJ8mShusui extends EnemyBase

## 滚筒翻滚速度（度/秒），720°/s = 2 圈/秒
@export var roll_speed: float = 720.0

## 侧视切换阈值（|cos| ≤ 此值时显示侧视图），高速飞行侧视一闪而过
@export var side_threshold: float = 0.12

## 燃料耗尽后的冲刺速度倍率
@export var boost_speed_mult: float = 2.5

## 当前滚筒角度（度，持续累积）
var _roll_angle: float = 0.0

## 是否已进入燃料耗尽冲刺
var _boosted: bool = false

## 尾焰原始参数（用于 reset_state 还原）
const _TRAIL_AMOUNT: int = 15
const _TRAIL_VEL_MIN: float = 30.0
const _TRAIL_VEL_MAX: float = 60.0

@onready var sprite_top: Sprite2D = $SpriteTop
@onready var sprite_side: Sprite2D = $SpriteSide
@onready var sprite_bottom: Sprite2D = $SpriteBottom
@onready var rocket_trail: CPUParticles2D = $RocketTrail
@onready var fuel_timer: Timer = $FuelTimer


func _ready() -> void:
	super._ready()
	# 启动燃料计时器（one_shot，2.5s 后触发冲刺）
	if fuel_timer != null:
		if not fuel_timer.timeout.is_connected(_on_fuel_out):
			fuel_timer.timeout.connect(_on_fuel_out)
		if not fuel_timer.is_stopped():
			fuel_timer.stop()
		fuel_timer.start()


func _process(delta: float) -> void:
	# 先调用父类：处理移动/弹幕射击/屏幕外归还
	super._process(delta)
	_update_roll(delta)


## 滚筒翻滚：三图切换 + scale.x = cos(θ)
func _update_roll(delta: float) -> void:
	_roll_angle += roll_speed * delta
	var c: float = cos(deg_to_rad(_roll_angle))
	var abs_c: float = abs(c)

	if abs_c > side_threshold:
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


## 燃料耗尽：进入加速冲刺模式，增强尾焰
func _on_fuel_out() -> void:
	if _boosted:
		return
	_boosted = true
	speed *= boost_speed_mult
	# 冲刺时增强尾焰（更多粒子、更快喷射）
	if rocket_trail != null:
		rocket_trail.amount = 30
		rocket_trail.initial_velocity_min = 60.0
		rocket_trail.initial_velocity_max = 100.0


## 重置状态（对象池归还时调用）：还原冲刺速度、尾焰参数并重启燃料计时器
func reset_state() -> void:
	super.reset_state()
	# 精确撤销冲刺倍率，避免跨池复用速度漂移
	if _boosted:
		speed /= boost_speed_mult
		_boosted = false
	# 还原尾焰参数
	if rocket_trail != null:
		rocket_trail.amount = _TRAIL_AMOUNT
		rocket_trail.initial_velocity_min = _TRAIL_VEL_MIN
		rocket_trail.initial_velocity_max = _TRAIL_VEL_MAX
	# 重启燃料计时器
	if fuel_timer != null:
		if not fuel_timer.is_stopped():
			fuel_timer.stop()
		fuel_timer.start()
