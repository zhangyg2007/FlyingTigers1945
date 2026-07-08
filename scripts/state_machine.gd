## 有限状态机
## 管理游戏对象的各种状态切换，支持 enter/update/exit 生命周期
## 通过 signal state_changed 通知外部状态变化
class_name StateMachine extends Node

## 状态切换信号，参数为新状态名
signal state_changed(new_state: String)

## 内部状态基类
## 所有具体状态都应继承此类并覆盖 enter / update / exit
class State:
	## 进入状态时调用
	## [param data] 切换状态时传递的附加数据
	func enter(_data: Dictionary = {}) -> void:
		pass

	## 每帧更新
	## [param delta] 帧间隔时间
	func update(_delta: float) -> void:
		pass

	## 退出状态时调用
	func exit() -> void:
		pass

## 所有已注册的状态 { state_name: State }
var _states: Dictionary = {}

## 当前状态引用
var _current_state: State = null

## 当前状态名称
var _current_state_name: String = ""


## 当前状态名称的 getter
func current_state() -> State:
	return _current_state


## 当前状态名称的 getter
func current_state_name() -> String:
	return _current_state_name


## 注册一个新状态
## [param name] 状态名称（唯一标识）
## [param state] State 实例
func add_state(name: String, state: State) -> void:
	if _states.has(name):
		push_warning("状态机: 状态 [%s] 已存在，将被覆盖" % name)
	_states[name] = state


## 移除一个已注册的状态（不会移除当前状态）
## [param name] 状态名称
func remove_state(name: String) -> void:
	if name == _current_state_name:
		push_warning("状态机: 不能移除当前活动状态 [%s]" % name)
		return
	if _states.has(name):
		_states.erase(name)


## 切换到指定状态
## [param state_name] 目标状态名称
## [param data] 传递给新状态 enter() 的数据字典
func transition_to(state_name: String, data: Dictionary = {}) -> void:
	# 检查目标状态是否存在
	if not _states.has(state_name):
		push_error("状态机: 未注册的状态 [%s]" % state_name)
		return

	# 如果目标状态与当前状态相同，忽略切换
	if state_name == _current_state_name:
		return

	# 退出当前状态
	if _current_state != null:
		_current_state.exit()

	# 切换到新状态
	_current_state_name = state_name
	_current_state = _states[state_name]
	_current_state.enter(data)

	# 发送状态切换信号
	state_changed.emit(state_name)


## 初始化状态机并设置初始状态
## [param initial_state] 初始状态名称
## [param data] 传递给初始状态的数据
func initialize(initial_state: String, data: Dictionary = {}) -> void:
	if not _states.has(initial_state):
		push_error("状态机: 初始状态 [%s] 未注册" % initial_state)
		return

	_current_state_name = initial_state
	_current_state = _states[initial_state]
	_current_state.enter(data)
	state_changed.emit(initial_state)


## 每帧调用当前状态的 update
func _process(delta: float) -> void:
	if _current_state != null:
		_current_state.update(delta)


## 获取已注册状态名称列表
## [returns] 所有状态名称的数组
func get_state_names() -> Array:
	return _states.keys()


## 检查当前是否处于指定状态
## [param state_name] 要检查的状态名称
## [returns] 是否处于该状态
func is_in_state(state_name: String) -> bool:
	return _current_state_name == state_name
