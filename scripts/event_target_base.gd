class_name EventTargetBase
extends EnemyBase
## 事件目标基类（M3-B P0）
## 继承 EnemyBase，增加 event_id 和 escape_timer 机制。
##
## - 被击毁时（die）：通知 EventManager 事件完成，然后调用父类 die 流程
## - 超时逃脱时（_on_escape）：通知 EventManager 事件失败，然后归还对象池
## - 飞出屏幕底部时：同样视为逃脱失败
##
## EventManager 通过 get_tree().get_first_node_in_group("event_manager") 查找。

## 事件 ID（由 EventManager 实例化时设置）
@export var event_id: String = ""

## 逃脱倒计时（秒），0 = 不逃脱
@export var escape_timer: float = 0.0

## 是否已逃脱
var _escaped: bool = false

## 事件是否已结算（防止 die 和 escape 同时触发导致重复报告）
var _resolved: bool = false


func _process(delta: float) -> void:
	# 逃脱倒计时
	if escape_timer > 0.0 and not _escaped and not _resolved:
		escape_timer -= delta
		if escape_timer <= 0.0:
			escape_timer = 0.0
			_on_escape()
			return

	# 移动：事件目标直线下移（不使用路径，行为简单可控）
	position.y += speed * delta

	# 屏幕外检测：超出下方视为逃脱失败
	if global_position.y > get_viewport_rect().size.y + 200:
		_on_escape()
		return


## 逃脱处理：通知 EventManager 事件失败，然后归还对象池
func _on_escape() -> void:
	if _resolved:
		return
	_resolved = true
	_escaped = true

	# 通知 EventManager 事件失败
	var em: Node = _get_event_manager()
	if em != null:
		em.report_event_failed(event_id)

	# 归还对象池（不触发 die 流程，避免重复加分/掉落）
	_return_to_pool()


## 死亡处理（重写 EnemyBase.die）
## 先通知 EventManager 事件完成，再调用父类 die（爆炸/加分/掉落/归还）
func die() -> void:
	if _resolved:
		return
	_resolved = true

	# 如果未逃脱，通知 EventManager 事件完成
	if not _escaped:
		var em: Node = _get_event_manager()
		if em != null:
			em.report_event_completed(event_id)

	# 调用父类 die（播放爆炸、加分、掉落道具、归还对象池）
	super.die()


## 获取场景中的 EventManager 节点
## 通过 "event_manager" 组查找，使用 duck-typing 避免循环依赖
func _get_event_manager() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var node: Node = tree.get_first_node_in_group("event_manager")
	if node != null and node.has_method("report_event_completed"):
		return node
	return null


## 重置状态（对象池归还时调用）
func reset_state() -> void:
	super.reset_state()
	_escaped = false
	_resolved = false
	event_id = ""
	escape_timer = 0.0
