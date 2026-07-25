class_name EscortManager
extends Node2D
## 护送管理器（v1.5 C17 H1 驼峰绝径专用）
## 生成并管理 C-47 运输机编队，跟踪存活数量，关卡结束时给予奖励。
##
## 使用方式：
## 1. 在关卡 .tscn 中添加 EscortManager 节点（或由 level_base 代码实例化）
## 2. 调用 spawn_escort_formation(count, start_y) 生成编队
## 3. 关卡结束时调用 get_survivor_count() 判定奖励
##
## 默认配置：3 架 C-47 水平排列，跟随背景滚动向下移动

# ============================================================
# 信号
# ============================================================

## 护送编队全部被摧毁（任务失败）
signal escort_failed()

## 护送编队至少 1 架存活通过关卡（任务成功）
signal escort_success(survivor_count: int)

## 单架 C-47 被摧毁
signal escort_lost(escort_id: String, remaining_count: int)

# ============================================================
# 导出属性
# ============================================================

## C-47 场景
const C47_SCENE_PATH: String = "res://scenes/escort/c47_transport.tscn"

## 编队水平间距（像素）
@export var formation_spacing: float = 160.0

## 编队起始 Y 坐标（屏幕上方）
@export var formation_start_y: float = -100.0

## 编队存活奖励分数（每架）
@export var survivor_bonus_per_escort: int = 3000

## 全员存活额外奖励
@export var all_survivor_bonus: int = 5000

# ============================================================
# 内部状态
# ============================================================

## 所有 C-47 实例引用（包括已摧毁的，用于计数）
var _escorts: Array = []

## 存活的 C-47 数量
var _alive_count: int = 0

## 初始编队数量
var _initial_count: int = 0

## 是否已结算（防止重复发放奖励）
var _is_settled: bool = false


# ============================================================
# 公开方法
# ============================================================

## 生成 C-47 编队
## [param count]: 编队数量（默认 3 架）
## [param center_x]: 编队中心 X 坐标（默认 540，屏幕中央）
func spawn_escort_formation(count: int = 3, center_x: float = 540.0) -> void:
	_initial_count = count
	_alive_count = count

	var c47_scene: PackedScene = load(C47_SCENE_PATH)
	if c47_scene == null:
		push_error("[EscortManager] 无法加载 C-47 场景: %s" % C47_SCENE_PATH)
		return

	# 水平排列生成编队
	for i in range(count):
		var c47: C47Transport = c47_scene.instantiate()
		var offset_x: float = (i - (count - 1) / 2.0) * formation_spacing
		c47.escort_id = "c47_%02d" % (i + 1)
		c47.position = Vector2(center_x + offset_x, formation_start_y)
		c47.scroll_speed = _get_level_scroll_speed()
		c47.destroyed.connect(_on_escort_destroyed)
		add_child(c47)
		_escorts.append(c47)

	print("[EscortManager] 生成 C-47 编队: %d 架, 中心 X=%.0f" % [count, center_x])


## 获取存活数量
func get_survivor_count() -> int:
	return _alive_count


## 获取初始编队数量
func get_initial_count() -> int:
	return _initial_count


## 关卡结束时结算奖励
## [return] 总奖励分数
func settle_rewards() -> int:
	if _is_settled:
		return 0
	_is_settled = true

	var total_bonus: int = 0
	if _alive_count > 0:
		# 每架存活奖励
		total_bonus = _alive_count * survivor_bonus_per_escort
		# 全员存活额外奖励
		if _alive_count == _initial_count:
			total_bonus += all_survivor_bonus
		escort_success.emit(_alive_count)
		print("[EscortManager] 护送成功! 存活 %d/%d, 奖励 %d 分" % [
			_alive_count, _initial_count, total_bonus
		])
	else:
		escort_failed.emit()
		print("[EscortManager] 护送失败! 全部 C-47 被摧毁")

	# 发放分数
	if GameManager and total_bonus > 0:
		GameManager.add_score(total_bonus)

	return total_bonus


## 清理所有 C-47（关卡结束时调用）
func clear() -> void:
	for c47 in _escorts:
		if is_instance_valid(c47):
			c47.queue_free()
	_escorts.clear()
	_alive_count = 0
	# v1.5 修复：重置 _is_settled 和 _initial_count，避免对象池/关卡复用时 settle_rewards 永久失效
	_is_settled = false
	_initial_count = 0


# ============================================================
# 内部方法
# ============================================================

## C-47 被摧毁回调
func _on_escort_destroyed(escort_id: String) -> void:
	_alive_count = maxi(0, _alive_count - 1)
	escort_lost.emit(escort_id, _alive_count)
	print("[EscortManager] %s 被摧毁, 剩余 %d/%d" % [
		escort_id, _alive_count, _initial_count
	])

	# 全部被摧毁时通知失败（但不立即结算，等关卡结束）
	if _alive_count <= 0 and not _is_settled:
		# 不立即结算，等关卡结束统一结算
		pass


## 获取关卡背景滚动速度（从父节点 LevelBase 读取）
func _get_level_scroll_speed() -> float:
	var parent: Node = get_parent()
	if parent != null and "bg_scroll_speed" in parent:
		return float(parent.bg_scroll_speed)
	return 130.0  # 默认值（H1 驼峰）
