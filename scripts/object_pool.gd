## 泛型对象池类
## 用于管理游戏中频繁创建和销毁的对象（子弹、敌机、特效等）
## 内部通过 Dictionary 按 scene_path 管理各类型的对象池
## 被使用的对象需实现 reset_state() 方法
class_name ObjectPool extends Node

## 池结构：{ scene_path: { available: Array[Node], max: int } }
var _pools: Dictionary = {}

## 注册一个场景到对象池
## [param scene] 预加载的场景资源 (PackedScene)
## [param max_size] 该类型对象的最大缓存数量
func register(scene: PackedScene, max_size: int) -> void:
	var scene_path: String = scene.resource_path
	if _pools.has(scene_path):
		push_warning("对象池: 场景已注册 [%s]" % scene_path)
		return
	_pools[scene_path] = {
		"available": [],
		"max": max_size,
		"scene": scene,
	}


## 从池中获取一个对象实例
## 优先从可用列表中取，否则实例化新对象
## [param scene] 预加载的场景资源
## [returns] 可用的节点实例，调用方需手动 add_child
func get_object(scene: PackedScene) -> Node:
	var scene_path: String = scene.resource_path

	# 如果该场景未注册，自动注册（默认上限50）
	if not _pools.has(scene_path):
		register(scene, 50)

	var pool: Dictionary = _pools[scene_path]

	# 优先从可用池中取出
	if pool["available"].size() > 0:
		var obj: Node = pool["available"].pop_back()
		obj.set_process(true)
		obj.set_physics_process(true)
		if obj is CanvasItem:
			obj.visible = true
		return obj

	# 池中没有可用对象，实例化新的
	var new_obj: Node = scene.instantiate()
	return new_obj


## 将对象归还到池中
## 归还时会调用 reset_state() 重置状态
## [param obj] 要归还的节点实例
func return_object(obj: Node) -> void:
	if obj == null:
		return

	# 确定该对象对应的场景路径
	var scene_path: String = obj.scene_file_path

	if not _pools.has(scene_path):
		# 未注册的场景直接释放
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		obj.queue_free()
		return

	var pool: Dictionary = _pools[scene_path]

	# 从场景树中移除
	if obj.get_parent():
		obj.get_parent().remove_child(obj)

	# 超出上限则直接释放
	if pool["available"].size() >= pool["max"]:
		obj.queue_free()
		return

	# 重置状态并停用处理
	obj.set_process(false)
	obj.set_physics_process(false)
	if obj is CanvasItem:
		obj.visible = false

	# 调用对象的 reset_state 方法（如果存在）
	if obj.has_method("reset_state"):
		obj.reset_state()

	# 放入可用池
	pool["available"].push_back(obj)


## 清空指定场景的所有池化对象
## [param scene] 预加载的场景资源
func clear_pool(scene: PackedScene) -> void:
	var scene_path: String = scene.resource_path
	if not _pools.has(scene_path):
		return

	var pool: Dictionary = _pools[scene_path]
	for obj: Node in pool["available"]:
		obj.queue_free()
	pool["available"].clear()


## 清空所有对象池
func clear_all() -> void:
	for scene_path: String in _pools:
		var pool: Dictionary = _pools[scene_path]
		for obj: Node in pool["available"]:
			obj.queue_free()
	_pools.clear()


## 获取指定场景当前池中可用对象数量
## [param scene] 预加载的场景资源
## [returns] 可用对象数量
func get_available_count(scene: PackedScene) -> int:
	var scene_path: String = scene.resource_path
	if not _pools.has(scene_path):
		return 0
	return _pools[scene_path]["available"].size()


## 获取所有已注册的场景路径
## [returns] 场景路径数组
func get_registered_scenes() -> Array:
	return _pools.keys()
