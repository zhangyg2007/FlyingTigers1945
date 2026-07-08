extends Node
## 全局对象池管理器（Autoload单例）
## 管理子弹、敌机、特效等频繁创建/销毁的对象池，
## 避免运行时频繁实例化和释放造成的性能开销。
##
## 使用方式：
##   1. 先通过 register_pool() 注册场景及其池容量
##   2. 需要对象时通过 get_object() 从池中获取
##   3. 不再使用时通过 return_object() 归还到池中
##
## 池中对象需要实现 reset_state() 方法，归还时会自动调用。

# ============================================================
# 内部数据结构
# ============================================================

## 单个对象池的数据
class ObjectPool:
	## 对应的 PackedScene 资源
	var scene: PackedScene

	## 池的最大容量
	var max_size: int

	## 当前可用对象队列（未激活的）
	var available: Array[Node] = []

	## 当前活跃（借出）对象集合
	var active: Array[Node] = []

	func _init(p_scene: PackedScene, p_max_size: int) -> void:
		scene = p_scene
		max_size = p_max_size

# ============================================================
# 公开变量
# ============================================================

## 所有已注册的对象池，键为场景资源路径字符串
var _pools: Dictionary = {}  # String -> ObjectPool

# ============================================================
# 默认池容量配置
# ============================================================

## 玩家子弹池容量
const PLAYER_BULLET_POOL_SIZE: int = 50

## 敌人子弹池容量
const ENEMY_BULLET_POOL_SIZE: int = 300

## 敌机池容量
const ENEMY_POOL_SIZE: int = 30

## 特效池容量
const EFFECT_POOL_SIZE: int = 20

## 道具池容量
const POWERUP_POOL_SIZE: int = 15

# ============================================================
# 公开方法：池注册
# ============================================================

## 注册一个对象池
## [param scene]: 要池化的 PackedScene
## [param max_size]: 池的最大容量
func register_pool(scene: PackedScene, max_size: int) -> void:
	var key: String = scene.resource_path
	if _pools.has(key):
		push_warning("PoolManager: 场景 '%s' 已注册，跳过重复注册。" % key)
		return

	var pool := ObjectPool.new(scene, max_size)
	_pools[key] = pool


## 通过场景路径字符串注册对象池（便捷方法）
func register_pool_by_path(scene_path: String, max_size: int) -> bool:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("PoolManager: 无法加载场景 '%s'" % scene_path)
		return false
	register_pool(scene, max_size)
	return true

# ============================================================
# 公开方法：对象获取与归还
# ============================================================

## 从池中获取一个对象。
## 如果池中有空闲对象则复用，否则新建一个（不超过max_size）。
## 获取的对象会被添加到场景树中。
## [param scene]: 要获取的 PackedScene
## [param parent]: 获取后要添加到的父节点，默认为当前场景根节点
## [returns]: 可用的节点实例，若已达上限且无空闲对象则返回 null
func get_object(scene: PackedScene, parent: Node = null) -> Node:
	var key: String = scene.resource_path
	if not _pools.has(key):
		push_warning("PoolManager: 场景 '%s' 未注册，自动注册（容量20）。" % key)
		register_pool(scene, 20)

	var pool: ObjectPool = _pools[key]
	var obj: Node = null

	# 优先从可用队列中取
	if pool.available.size() > 0:
		obj = pool.available.pop_back()
	else:
		# 检查是否超过最大容量
		var total_count: int = pool.available.size() + pool.active.size()
		if total_count < pool.max_size:
			obj = scene.instantiate()
		else:
			push_warning("PoolManager: 场景 '%s' 池已满（%d/%d），无法创建新对象。" % [key, total_count, pool.max_size])
			return null

	if obj == null:
		return null

	# 确保对象已从之前的父节点中移除
	if obj.get_parent() != null:
		obj.get_parent().remove_child(obj)

	# 添加到场景树
	if parent == null:
		parent = get_tree().current_scene
		if parent == null:
			parent = self  # 兜底：添加到PoolManager自身

	parent.add_child(obj)

	# 调用重置方法
	if obj.has_method("reset_state"):
		obj.reset_state()

	# 记录到活跃集合
	pool.active.append(obj)

	return obj


## 通过场景路径获取对象（便捷方法）
func get_object_by_path(scene_path: String, parent: Node = null) -> Node:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("PoolManager: 无法加载场景 '%s'" % scene_path)
		return null
	return get_object(scene, parent)


## 将对象归还到池中
## 对象会从场景树中移除并调用 reset_state()
## [param obj]: 要归还的节点实例
func return_object(obj: Node) -> void:
	if obj == null:
		return

	var key: String = ""

	# 尝试通过对象的场景文件路径查找对应的池
	if obj.scene_file_path != "":
		key = obj.scene_file_path
	elif obj is Node:
		# 兜底：遍历所有活跃池查找
		for pool_key in _pools:
			var pool: ObjectPool = _pools[pool_key]
			if obj in pool.active:
				key = pool_key
				break

	if key == "" or not _pools.has(key):
		# 不在池管理范围内，直接释放
		push_warning("PoolManager: 对象 '%s' 不属于任何已注册的池，直接释放。" % obj.name)
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		obj.queue_free()
		return

	var pool: ObjectPool = _pools[key]

	# 从活跃集合中移除
	var idx: int = pool.active.find(obj)
	if idx != -1:
		pool.active.remove_at(idx)

	# 从场景树中移除
	if obj.get_parent():
		obj.get_parent().remove_child(obj)

	# 调用重置方法
	if obj.has_method("reset_state"):
		obj.reset_state()

	# 放回可用队列
	pool.available.append(obj)

# ============================================================
# 查询方法
# ============================================================

## 获取指定场景的池中活跃对象数量
func get_active_count(scene: PackedScene) -> int:
	var key: String = scene.resource_path
	if not _pools.has(key):
		return 0
	return _pools[key].active.size()


## 获取指定场景的池中可用对象数量
func get_available_count(scene: PackedScene) -> int:
	var key: String = scene.resource_path
	if not _pools.has(key):
		return 0
	return _pools[key].available.size()


## 获取指定场景的池总大小
func get_pool_size(scene: PackedScene) -> int:
	var key: String = scene.resource_path
	if not _pools.has(key):
		return 0
	var pool: ObjectPool = _pools[key]
	return pool.available.size() + pool.active.size()


## 获取所有池的统计信息（用于调试）
func get_pool_stats() -> Dictionary:
	var stats := {}
	for key in _pools:
		var pool: ObjectPool = _pools[key]
		stats[key] = {
			"available": pool.available.size(),
			"active": pool.active.size(),
			"max_size": pool.max_size,
			"total": pool.available.size() + pool.active.size()
		}
	return stats

# ============================================================
# 清理
# ============================================================

## 释放指定场景的所有池中对象（包括可用和活跃的）
func clear_pool(scene: PackedScene) -> void:
	var key: String = scene.resource_path
	if not _pools.has(key):
		return

	var pool: ObjectPool = _pools[key]

	# 释放所有可用对象
	for obj in pool.available:
		if is_instance_valid(obj):
			obj.queue_free()
	pool.available.clear()

	# 释放所有活跃对象
	for obj in pool.active:
		if is_instance_valid(obj):
			obj.queue_free()
	pool.active.clear()

	# 移除池注册
	_pools.erase(key)


## 清理所有池，释放全部对象
func cleanup() -> void:
	for key in _pools:
		var pool: ObjectPool = _pools[key]
		for obj in pool.available:
			if is_instance_valid(obj):
				obj.queue_free()
		pool.available.clear()
		for obj in pool.active:
			if is_instance_valid(obj):
				obj.queue_free()
		pool.active.clear()

	_pools.clear()
	print("PoolManager: 所有对象池已清理。")


## 安全归还所有活跃对象（不释放，只是归还）
## 适用于关卡切换时批量回收
func return_all_active() -> void:
	for key in _pools:
		var pool: ObjectPool = _pools[key]
		# 复制一份活跃列表，因为return_object会修改原列表
		var active_copy := pool.active.duplicate()
		for obj in active_copy:
			if is_instance_valid(obj):
				return_object(obj)
	print("PoolManager: 所有活跃对象已归还。")
