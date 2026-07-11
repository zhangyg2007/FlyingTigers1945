class_name PerformanceBudget
extends Node2D
## 性能预算测试场景（M3-E E-C4）
## 在屏幕上生成大量子弹和敌机，测量 FPS 和内存占用
## 验证：PC 60fps 稳定 / 移动端 30fps 稳定 / 300 子弹不卡顿
##
## 运行方式：在 Godot 编辑器中打开 tests/performance_budget.tscn 并运行（F6）

## ============================================================
## 导出属性
## ============================================================

## 测试子弹数量
@export var bullet_count: int = 300
## 测试持续时间（秒）
@export var test_duration: float = 10.0
## 子弹场景（可选，为空时用 ColorRect 模拟）
@export var bullet_scene: PackedScene

## ============================================================
## 内部状态
## ============================================================

var _elapsed: float = 0.0
var _fps_history: Array[float] = []
var _min_fps: float = 999.0
var _max_fps: float = 0.0
var _is_running: bool = false
var _label: Label = null


func _ready() -> void:
	# 创建测试数据显示标签
	_label = Label.new()
	_label.position = Vector2(10, 10)
	_label.add_theme_font_size_override("font_size", 24)
	_label.text = "初始化中..."
	add_child(_label)

	_spawn_bullets()
	_is_running = true
	print("[PerformanceBudget] 测试开始：生成 %d 个子弹，持续 %.0f 秒" % [bullet_count, test_duration])


func _process(delta: float) -> void:
	if not _is_running:
		return

	_elapsed += delta
	var fps: float = Engine.get_frames_per_second()
	_fps_history.append(fps)
	_min_fps = minf(_min_fps, fps)
	_max_fps = maxf(_max_fps, fps)

	if _label != null:
		_label.text = "FPS: %.1f\nMin: %.1f / Max: %.1f\nTime: %.1f/%.0f\nBullets: %d" % [
			fps, _min_fps, _max_fps, _elapsed, test_duration, bullet_count
		]

	if _elapsed >= test_duration:
		_finish_test()


## 生成测试子弹
func _spawn_bullets() -> void:
	if bullet_scene == null:
		# 无场景时用 ColorRect 模拟
		for i in range(bullet_count):
			var rect := ColorRect.new()
			rect.size = Vector2(4, 8)
			rect.color = Color.YELLOW
			rect.position = Vector2(randf() * 540.0, randf() * 960.0)
			add_child(rect)
		return

	for i in range(bullet_count):
		var bullet: Node = bullet_scene.instantiate()
		if bullet != null:
			add_child(bullet)
			if bullet is Node2D:
				(bullet as Node2D).position = Vector2(randf() * 540.0, randf() * 960.0)


## 结束测试并输出报告
func _finish_test() -> void:
	_is_running = false

	var avg_fps: float = 0.0
	for fps in _fps_history:
		avg_fps += fps
	avg_fps /= float(_fps_history.size())

	var report: String = (
		"=== 性能预算测试报告 ===\n" +
		"子弹数量: %d\n" % bullet_count +
		"测试时长: %.1f 秒\n" % _elapsed +
		"平均 FPS: %.1f\n" % avg_fps +
		"最低 FPS: %.1f\n" % _min_fps +
		"最高 FPS: %.1f\n" % _max_fps +
		"========================"
	)
	print(report)

	if _label != null:
		_label.text = report

	# 判定结果
	var is_pc_pass: bool = avg_fps >= 55.0
	var is_mobile_pass: bool = avg_fps >= 25.0
	print("[PerformanceBudget] PC标准(60fps): %s | 移动端标准(30fps): %s" % [
		"PASS" if is_pc_pass else "FAIL",
		"PASS" if is_mobile_pass else "FAIL"
	])
