## 大型爆炸特效（BOSS死亡用）
## 基于 Sprite2D + Tween 实现缩放/淡出动画，0.8秒后自动销毁
## 兼容 EnemyBase._spawn_explosion() 的 start() 调用约定
extends Sprite2D

## 初始缩放
@export var start_scale: float = 0.2

## 峰值缩放
@export var peak_scale: float = 2.5

## 生存时间（秒）
@export var lifetime: float = 0.8


func _ready() -> void:
	# 加法混合模式（亮光效果）
	material = CanvasItemMaterial.new()
	(material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# 启动动画
	start()


## 启动爆炸动画（兼容 EnemyBase._spawn_explosion 的 start() 调用）
func start() -> void:
	scale = Vector2(start_scale, start_scale)
	modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	# 0~0.3秒：从 start_scale 放大到 peak_scale
	tween.tween_property(self, "scale", Vector2(peak_scale, peak_scale), lifetime * 0.3)
	# 0.3~lifetime 秒：从 peak_scale 缩小到 0
	tween.tween_property(self, "scale", Vector2.ZERO, lifetime * 0.7).set_delay(lifetime * 0.3)
	# 同步淡出
	tween.tween_property(self, "modulate:a", 0.0, lifetime * 0.7).set_delay(lifetime * 0.3)

	# 动画结束后自动销毁
	tween.chain().tween_callback(queue_free)
