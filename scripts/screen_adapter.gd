class_name ScreenAdapter
extends Node
## 分辨率适配器（M3-E E-C3）
## 自动检测屏幕方向（横屏/竖屏），调整视口缩放
## 确保 UI 在不同分辨率下不裁剪
##
## 设计基准分辨率：540x960（竖屏），横屏时以高度为基准缩放

## ============================================================
## 常量
## ============================================================

## 设计基准分辨率（竖屏）
const DESIGN_WIDTH: float = 540.0
const DESIGN_HEIGHT: float = 960.0

## 屏幕方向
enum Orientation { PORTRAIT, LANDSCAPE }

## ============================================================
## 公开状态
## ============================================================

## 当前屏幕方向
var current_orientation: Orientation = Orientation.PORTRAIT


func _ready() -> void:
	_adapt_to_screen()
	# 监听窗口大小变化
	get_tree().get_root().size_changed.connect(_adapt_to_screen)


## 根据当前窗口大小适配屏幕缩放
func _adapt_to_screen() -> void:
	var window_size: Vector2i = DisplayServer.window_get_size()
	var is_landscape: bool = window_size.x > window_size.y
	current_orientation = Orientation.LANDSCAPE if is_landscape else Orientation.PORTRAIT

	# 计算缩放因子（保持设计比例，确保 UI 不裁剪）
	var scale_factor: float = 1.0
	if is_landscape:
		# 横屏：以高度为基准
		scale_factor = float(window_size.y) / DESIGN_HEIGHT
	else:
		# 竖屏：以宽度为基准
		scale_factor = float(window_size.x) / DESIGN_WIDTH

	# 应用 2D 缩放
	var root: Window = get_tree().get_root()
	root.content_scale_factor = scale_factor
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	print("[ScreenAdapter] 屏幕: %dx%d, 方向: %s, 缩放: %.2f" % [
		window_size.x, window_size.y,
		"横屏" if is_landscape else "竖屏",
		scale_factor
	])


## ============================================================
## 公开查询 API
## ============================================================

## 获取当前屏幕方向
func get_orientation() -> Orientation:
	return current_orientation


## 是否横屏
func is_landscape() -> bool:
	return current_orientation == Orientation.LANDSCAPE


## 是否竖屏
func is_portrait() -> bool:
	return current_orientation == Orientation.PORTRAIT
