class_name MobileJoystick
extends Control
## 移动端虚拟摇杆（M3-E E-C1）
## 左侧摇杆控制移动，右侧射击/炸弹按钮
## 仅在触摸设备上显示，PC端自动隐藏
## 纯代码创建视觉元素（ColorRect），不依赖外部纹理资源

## ============================================================
## 导出属性
## ============================================================

## 摇杆激活半径（杆头可移动的最大距离，超出则归一化）
@export var max_distance: float = 80.0
## 摇杆底座大小（像素）
@export var base_size: float = 160.0
## 摇杆杆头大小（像素）
@export var stick_size: float = 80.0
## 射击/炸弹按钮大小（像素）
@export var button_size: float = 120.0
## 按钮距屏幕右下角的边距
@export var button_margin: float = 40.0
## 射击按钮与炸弹按钮之间的间距
@export var button_spacing: float = 20.0

## ============================================================
## 公开状态（供 PlayerBase 读取）
## ============================================================

## 摇杆输出向量（-1.0 ~ 1.0）
var output_vector: Vector2 = Vector2.ZERO
## 射击按钮是否按下（hold）
var is_shooting: bool = false

## ============================================================
## 内部状态
## ============================================================

var _touch_index: int = -1  # 当前控制摇杆的触摸ID
var _touch_center: Vector2 = Vector2.ZERO  # 摇杆触摸起始位置
var _shoot_touch_index: int = -1  # 射击按钮占用的触摸ID
var _bomb_touch_index: int = -1  # 炸弹按钮占用的触摸ID

var _base: ColorRect = null
var _stick: ColorRect = null
var _shoot_btn: ColorRect = null
var _bomb_btn: ColorRect = null

## 按钮正常/按下颜色
const _SHOOT_COLOR_NORMAL := Color(0.8, 0.2, 0.2, 0.5)
const _SHOOT_COLOR_PRESSED := Color(0.9, 0.3, 0.3, 0.8)
const _BOMB_COLOR_NORMAL := Color(0.9, 0.8, 0.2, 0.5)
const _BOMB_COLOR_PRESSED := Color(1.0, 0.9, 0.3, 0.8)


func _ready() -> void:
	# 全屏覆盖，接收触摸事件
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_visuals()
	_layout_buttons()
	# 默认隐藏，仅在触摸设备显示
	visible = false
	if DisplayServer.is_touchscreen_available():
		visible = true
	# 监听窗口大小变化以重新布局按钮
	get_tree().get_root().size_changed.connect(_layout_buttons)


## 创建所有视觉元素（纯代码，ColorRect 占位）
func _create_visuals() -> void:
	# 摇杆底座（蓝色半透明）
	_base = ColorRect.new()
	_base.color = Color(0.2, 0.4, 0.8, 0.4)
	_base.size = Vector2(base_size, base_size)
	_base.visible = false
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_base)

	# 摇杆杆头（白色半透明）
	_stick = ColorRect.new()
	_stick.color = Color(1.0, 1.0, 1.0, 0.6)
	_stick.size = Vector2(stick_size, stick_size)
	_stick.visible = false
	_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stick)

	# 射击按钮（红色半透明）
	_shoot_btn = ColorRect.new()
	_shoot_btn.color = _SHOOT_COLOR_NORMAL
	_shoot_btn.size = Vector2(button_size, button_size)
	_shoot_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shoot_btn)
	_add_button_label(_shoot_btn, "射击")

	# 炸弹按钮（黄色半透明）
	_bomb_btn = ColorRect.new()
	_bomb_btn.color = _BOMB_COLOR_NORMAL
	_bomb_btn.size = Vector2(button_size, button_size)
	_bomb_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bomb_btn)
	_add_button_label(_bomb_btn, "炸弹")


## 给按钮添加居中文字标签
func _add_button_label(parent: ColorRect, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)


## 根据视口大小布局射击/炸弹按钮到右下角
func _layout_buttons() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	# 射击按钮在右下角
	var shoot_pos := Vector2(
		viewport_size.x - button_size - button_margin,
		viewport_size.y - button_size - button_margin
	)
	# 炸弹按钮在射击按钮正上方
	var bomb_pos := Vector2(
		viewport_size.x - button_size - button_margin,
		viewport_size.y - button_size * 2.0 - button_margin - button_spacing
	)
	if _shoot_btn != null:
		_shoot_btn.position = shoot_pos
	if _bomb_btn != null:
		_bomb_btn.position = bomb_pos


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


## 处理触摸按下/释放
func _handle_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		# 新触摸按下
		if _touch_index == -1 and _is_in_left_half(touch.position):
			# 左半屏触摸 -> 激活摇杆
			_touch_index = touch.index
			_touch_center = touch.position
			_show_joystick(true)
			_update_joystick_visual(_touch_center)
		elif _shoot_touch_index == -1 and _is_in_rect(touch.position, _shoot_btn):
			# 射击按钮按下（hold）
			_shoot_touch_index = touch.index
			is_shooting = true
			_shoot_btn.color = _SHOOT_COLOR_PRESSED
		elif _bomb_touch_index == -1 and _is_in_rect(touch.position, _bomb_btn):
			# 炸弹按钮按下（tap 即触发）
			_bomb_touch_index = touch.index
			_bomb_btn.color = _BOMB_COLOR_PRESSED
			_on_bomb_pressed()
	else:
		# 触摸释放
		if touch.index == _touch_index:
			_touch_index = -1
			output_vector = Vector2.ZERO
			_show_joystick(false)
		elif touch.index == _shoot_touch_index:
			_shoot_touch_index = -1
			is_shooting = false
			if _shoot_btn != null:
				_shoot_btn.color = _SHOOT_COLOR_NORMAL
		elif touch.index == _bomb_touch_index:
			_bomb_touch_index = -1
			if _bomb_btn != null:
				_bomb_btn.color = _BOMB_COLOR_NORMAL


## 处理拖动（更新摇杆输出）
func _handle_drag(drag: InputEventScreenDrag) -> void:
	if drag.index == _touch_index:
		var delta: Vector2 = drag.position - _touch_center
		var distance: float = delta.length()
		if distance > max_distance:
			delta = delta.normalized() * max_distance
		output_vector = delta / max_distance
		_update_joystick_visual(_touch_center + delta)


func _is_in_left_half(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x / 2.0


## 判断触摸点是否落在指定 ColorRect 范围内
func _is_in_rect(pos: Vector2, rect: ColorRect) -> bool:
	if rect == null or not rect.visible:
		return false
	var rp: Vector2 = rect.global_position
	var rs: Vector2 = rect.size
	return pos.x >= rp.x and pos.x <= rp.x + rs.x \
		and pos.y >= rp.y and pos.y <= rp.y + rs.y


func _show_joystick(show: bool) -> void:
	if _base != null:
		_base.visible = show
	if _stick != null:
		_stick.visible = show


## 更新摇杆视觉位置（底座固定在触摸起始点，杆头跟随移动）
func _update_joystick_visual(stick_pos: Vector2) -> void:
	if _base != null:
		_base.global_position = _touch_center - _base.size / 2.0
	if _stick != null:
		_stick.global_position = stick_pos - _stick.size / 2.0


## 炸弹按钮触发：调用玩家 use_bomb()
func _on_bomb_pressed() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("use_bomb"):
		player.use_bomb()


## ============================================================
## 公开 API（供 PlayerBase._process 调用）
## ============================================================

## 获取摇杆输出向量（-1.0 ~ 1.0）
func get_movement_vector() -> Vector2:
	return output_vector


## 获取射击状态（hold）
func get_shooting() -> bool:
	return is_shooting
