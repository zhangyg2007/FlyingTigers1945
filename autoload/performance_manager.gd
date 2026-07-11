extends Node
## 性能降级管理器（M3-E E-C2，Autoload 单例）
## 根据 FPS 自动调整画质，保持游戏流畅运行
## 3档：HIGH (FPS>55) / MEDIUM (FPS 30~55) / LOW (FPS<30)
##
## 降级策略：
##   HIGH   - 全部背景层、满粒子、满弹幕密度
##   MEDIUM - 减少粒子数、降低弹幕密度
##   LOW    - 最少背景层、最少粒子、最低弹幕密度、限帧30
##
## 其他系统可通过 quality_changed 信号或 get_* 查询方法响应降级。

## 画质等级
enum QualityLevel { HIGH, MEDIUM, LOW }

## ============================================================
## 导出属性
## ============================================================

## FPS 检测间隔（秒）
@export var check_interval: float = 5.0
## HIGH 阈值（平均 FPS >= 此值则升档）
@export var high_threshold: float = 55.0
## LOW 阈值（平均 FPS < 此值则降为 LOW）
@export var low_threshold: float = 30.0

## ============================================================
## 公开状态
## ============================================================

## 当前画质等级
var current_quality: QualityLevel = QualityLevel.HIGH

## 画质变化信号
signal quality_changed(level: QualityLevel)

## ============================================================
## 内部状态
## ============================================================

var _timer: float = 0.0
var _fps_samples: Array[float] = []
var _max_samples: int = 60


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_fps_samples.append(Engine.get_frames_per_second())
	if _fps_samples.size() > _max_samples:
		_fps_samples.pop_front()

	_timer += delta
	if _timer >= check_interval:
		_timer = 0.0
		_check_and_adjust()


## 检测平均 FPS 并调整画质
func _check_and_adjust() -> void:
	if _fps_samples.is_empty():
		return

	var avg_fps: float = 0.0
	for fps in _fps_samples:
		avg_fps += fps
	avg_fps /= float(_fps_samples.size())

	var new_quality: QualityLevel = current_quality
	if avg_fps >= high_threshold:
		new_quality = QualityLevel.HIGH
	elif avg_fps >= low_threshold:
		new_quality = QualityLevel.MEDIUM
	else:
		new_quality = QualityLevel.LOW

	if new_quality != current_quality:
		current_quality = new_quality
		_apply_quality(new_quality)
		quality_changed.emit(new_quality)
		print("[PerformanceManager] 画质调整为: %s (平均FPS: %.1f)" % [_quality_name(new_quality), avg_fps])


## 应用画质等级到引擎设置
func _apply_quality(level: QualityLevel) -> void:
	match level:
		QualityLevel.HIGH:
			Engine.max_fps = 60
			# 恢复全部背景层、粒子、弹幕密度
		QualityLevel.MEDIUM:
			Engine.max_fps = 60
			# 减少粒子数、降低弹幕密度
		QualityLevel.LOW:
			Engine.max_fps = 30
			# 最少背景层、最少粒子、最低弹幕密度


func _quality_name(level: QualityLevel) -> String:
	match level:
		QualityLevel.HIGH:
			return "HIGH"
		QualityLevel.MEDIUM:
			return "MEDIUM"
		QualityLevel.LOW:
			return "LOW"
	return "UNKNOWN"


## ============================================================
## 公开查询 API（供粒子系统、背景、弹幕生成器等调用）
## ============================================================

## 获取当前画质等级
func get_current_quality() -> QualityLevel:
	return current_quality


## 获取画质名称
func get_quality_name() -> String:
	return _quality_name(current_quality)


## 获取最大粒子数倍率（HIGH=1.0, MEDIUM=0.6, LOW=0.3）
func get_particle_factor() -> float:
	match current_quality:
		QualityLevel.HIGH:
			return 1.0
		QualityLevel.MEDIUM:
			return 0.6
		QualityLevel.LOW:
			return 0.3
	return 1.0


## 获取弹幕密度倍率（HIGH=1.0, MEDIUM=0.6, LOW=0.3）
func get_bullet_density_factor() -> float:
	match current_quality:
		QualityLevel.HIGH:
			return 1.0
		QualityLevel.MEDIUM:
			return 0.6
		QualityLevel.LOW:
			return 0.3
	return 1.0


## 获取背景层显示数量（HIGH=4, MEDIUM=3, LOW=2）
func get_background_layer_count() -> int:
	match current_quality:
		QualityLevel.HIGH:
			return 4
		QualityLevel.MEDIUM:
			return 3
		QualityLevel.LOW:
			return 2
	return 4
