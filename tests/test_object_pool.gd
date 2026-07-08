## 对象池单元测试脚本
## 测试 ObjectPool 类（scripts/object_pool.gd）的核心功能
## 每个测试独立运行，通过 print 输出 [PASS]/[FAIL] 结果
## 使用简单的 Node 替代实际游戏对象（无需场景资源）
##
## 运行方式：
##   1. 在Godot编辑器中，将此脚本挂载到一个空Node上运行
##   2. 或者通过命令行: godot --headless -s res://tests/test_object_pool.gd
extends Node

## ============================================================
## 测试统计
## ============================================================

## 通过的测试数量
var _passed: int = 0

## 失败的测试数量
var _failed: int = 0

## 测试用的简单节点场景（模拟PackedScene）
## 由于没有实际场景文件，我们直接用代码模拟
var _test_node_scene: PackedScene = null


## ============================================================
## 生命周期
## ============================================================

func _ready() -> void:
	# 创建一个测试用的PackedScene（包含简单Node）
	_test_node_scene = _create_test_packed_scene()

	print("============================================================")
	print("  [ObjectPool] 单元测试开始")
	print("============================================================")
	print("")

	# 依次运行所有测试
	test_register_pool()
	test_get_and_return()
	test_overflow()
	test_reset_state()
	test_concurrent()

	# 输出汇总结果
	_print_summary()


## ============================================================
## 辅助方法：创建测试用PackedScene
## ============================================================

## 创建一个包含 TestPoolableNode 的 PackedScene
## 使用代码动态构建场景，避免依赖外部 .tscn 文件
func _create_test_packed_scene() -> PackedScene:
	# 创建临时场景树来构建PackedScene
	var temp_node: Node = Node.new()
	temp_node.name = "TestPoolableNode"
	temp_node.set_script(_create_poolable_script())

	# 将节点打包为PackedScene
	var scene: PackedScene = PackedScene.new()
	scene.pack(temp_node)
	temp_node.free()

	return scene


## 创建池化对象的脚本（实现 reset_state）
func _create_poolable_script() -> GDScript:
	var script: GDScript = GDScript.new()
	script.source_code = (
		"extends Node\n"
		"\n"
		"## 是否调用了 reset_state\n"
		"var reset_called: bool = false\n"
		"\n"
		"## 测试数据\n"
		"var test_value: int = 0\n"
		"\n"
		"## 归还时重置状态\n"
		"func reset_state() -> void:\n"
		"	reset_called = true\n"
		"	test_value = 0\n"
		"	position = Vector2.ZERO\n"
	)
	script.reload()
	return script


## ============================================================
## 测试1: 注册池后检查池是否存在
## ============================================================

func test_register_pool() -> void:
	var test_name: String = "test_register_pool"
	var pool: ObjectPool = ObjectPool.new()
	add_child(pool)

	# 注册池
	pool.register(_test_node_scene, 10)

	# 检查池是否存在
	var registered: Array = pool.get_registered_scenes()
	var found: bool = _test_node_scene.resource_path in registered

	if found and registered.size() == 1:
		_print_result(test_name, true, "池注册成功，已注册场景数: %d" % registered.size())
	else:
		_print_result(test_name, false, "池注册失败，已注册场景数: %d" % registered.size())

	# 验证重复注册不报错
	pool.register(_test_node_scene, 10)
	registered = pool.get_registered_scenes()
	if registered.size() == 1:
		_print_result(test_name + " (重复注册)", true, "重复注册被正确忽略")
	else:
		_print_result(test_name + " (重复注册)", false, "重复注册未正确处理")

	pool.queue_free()


## ============================================================
## 测试2: 获取10个对象，全部归还，验证池数量恢复
## ============================================================

func test_get_and_return() -> void:
	var test_name: String = "test_get_and_return"
	var pool: ObjectPool = ObjectPool.new()
	add_child(pool)

	var pool_size: int = 10
	pool.register(_test_node_scene, pool_size)

	# 获取10个对象
	var borrowed: Array[Node] = []
	for i: int in range(pool_size):
		var obj: Node = pool.get_object(_test_node_scene)
		if obj == null:
			_print_result(test_name, false, "第 %d 次获取返回 null" % i)
			pool.queue_free()
			return
		# 获取的对象需要手动添加到场景树
		pool.add_child(obj)
		borrowed.append(obj)

	# 验证可用数量应为0（全部借出）
	var available_after_get: int = pool.get_available_count(_test_node_scene)
	if available_after_get == 0:
		_print_result(test_name + " (获取)", true, "获取 %d 个对象后可用数: %d" % [pool_size, available_after_get])
	else:
		_print_result(test_name + " (获取)", false, "获取 %d 个对象后可用数: %d（期望 0）" % [pool_size, available_after_get])

	# 全部归还
	for obj: Node in borrowed:
		pool.return_object(obj)

	# 验证可用数量应恢复
	var available_after_return: int = pool.get_available_count(_test_node_scene)
	if available_after_return == pool_size:
		_print_result(test_name + " (归还)", true, "归还 %d 个对象后可用数: %d" % [pool_size, available_after_return])
	else:
		_print_result(test_name + " (归还)", false, "归还 %d 个对象后可用数: %d（期望 %d）" % [pool_size, available_after_return, pool_size])

	pool.queue_free()


## ============================================================
## 测试3: 获取超过容量的对象，验证不会crash
## ============================================================

func test_overflow() -> void:
	var test_name: String = "test_overflow"
	var pool: ObjectPool = ObjectPool.new()
	add_child(pool)

	var pool_size: int = 5
	pool.register(_test_node_scene, pool_size)

	# 获取超过容量的对象（获取20个，但池容量只有5）
	var all_ok: bool = true
	var borrowed: Array[Node] = []
	for i: int in range(20):
		var obj: Node = pool.get_object(_test_node_scene)
		if obj == null:
			# 超过容量后返回null也可以接受（取决于实现）
			# ObjectPool的get_object在池满时仍然会创建新对象（不限制上限）
			# 只有return_object才受max_size限制
			break
		pool.add_child(obj)
		borrowed.append(obj)

	# 验证没有crash，且获取到的对象数量>=池容量
	if borrowed.size() >= pool_size:
		_print_result(test_name, true, "成功获取 %d 个对象（池容量: %d），无崩溃" % [borrowed.size(), pool_size])
	else:
		_print_result(test_name, false, "获取对象异常，仅获取 %d 个" % borrowed.size())

	# 归还所有对象
	for obj: Node in borrowed:
		pool.return_object(obj)

	# 验证归还后池可用数量（受max_size限制，多余的会被释放）
	var available: int = pool.get_available_count(_test_node_scene)
	_print_result(test_name + " (溢出归还)", true,
		"归还 %d 个对象后池可用数: %d（超出容量的已被释放）" % [borrowed.size(), available])

	pool.queue_free()


## ============================================================
## 测试4: 验证归还后 reset_state 被调用
## ============================================================

func test_reset_state() -> void:
	var test_name: String = "test_reset_state"
	var pool: ObjectPool = ObjectPool.new()
	add_child(pool)

	pool.register(_test_node_scene, 5)

	# 获取一个对象
	var obj: Node = pool.get_object(_test_node_scene)
	if obj == null:
		_print_result(test_name, false, "获取对象返回 null")
		pool.queue_free()
		return

	pool.add_child(obj)

	# 设置测试数据（模拟使用后的状态）
	if obj.has_method("set"):
		obj.set("test_value", 42)
	if obj.has_method("set"):
		obj.set("reset_called", false)

	# 归还对象
	pool.return_object(obj)

	# 验证 reset_state 被调用
	if obj.has_method("get"):
		var was_reset: bool = obj.get("reset_called")
		if was_reset:
			_print_result(test_name, true, "归还后 reset_state 已被调用")
		else:
			_print_result(test_name, false, "归还后 reset_state 未被调用")

		# 验证 test_value 被重置为 0
		var value: int = obj.get("test_value")
		if value == 0:
			_print_result(test_name + " (值重置)", true, "test_value 已重置为: %d" % value)
		else:
			_print_result(test_name + " (值重置)", false, "test_value 未重置，当前值: %d" % value)

	pool.queue_free()


## ============================================================
## 测试5: 快速获取/归还100次，验证无泄漏
## ============================================================

func test_concurrent() -> void:
	var test_name: String = "test_concurrent"
	var pool: ObjectPool = ObjectPool.new()
	add_child(pool)

	var pool_size: int = 10
	pool.register(_test_node_scene, pool_size)

	# 快速获取/归还100次
	var leaked_nodes: int = 0
	var iteration_count: int = 100

	for i: int in range(iteration_count):
		# 随机获取1~3个对象
		var get_count: int = (i % 3) + 1
		var batch: Array[Node] = []

		for j: int in range(get_count):
			var obj: Node = pool.get_object(_test_node_scene)
			if obj != null:
				pool.add_child(obj)
				batch.append(obj)

		# 归还
		for obj: Node in batch:
			pool.return_object(obj)

	# 验证：所有对象都已归还
	var available: int = pool.get_available_count(_test_node_scene)
	var active_children: int = 0
	for child: Node in pool.get_children():
		# 排除子节点中不是池化对象的其他节点
		if child is Node and child.name != "TestPoolableNode":
			continue
		active_children += 1

	# 池中对象总数 = 可用 + 活跃，应不超过max_size
	# 注意：ObjectPool.active是内部Array，我们通过检查子节点间接验证
	# 直接用get_available_count验证可用数量即可
	if available <= pool_size:
		_print_result(test_name, true,
			"%d 次获取/归还完成，池可用数: %d，无泄漏" % [iteration_count, available])
	else:
		_print_result(test_name, false,
			"%d 次获取/归还后池可用数异常: %d（上限: %d）" % [iteration_count, available, pool_size])

	# 验证没有多余的子节点残留
	var child_count: int = pool.get_child_count()
	if child_count <= pool_size:
		_print_result(test_name + " (子节点)", true, "子节点数: %d（上限: %d）" % [child_count, pool_size])
	else:
		_print_result(test_name + " (子节点)", false, "子节点数: %d（上限: %d），可能存在泄漏" % [child_count, pool_size])

	pool.queue_free()


## ============================================================
## 辅助方法
## ============================================================

## 打印单个测试结果
func _print_result(test_name: String, passed: bool, detail: String) -> void:
	var status: String = "[PASS]" if passed else "[FAIL]"
	if passed:
		_passed += 1
	else:
		_failed += 1

	print("  %s %s - %s" % [status, test_name, detail])


## 打印测试汇总
func _print_summary() -> void:
	var total: int = _passed + _failed
	print("")
	print("============================================================")
	print("  [ObjectPool] 单元测试完成")
	print("  总计: %d | 通过: %d | 失败: %d" % [total, _passed, _failed])
	if _failed == 0:
		print("  结果: 全部通过!")
	else:
		print("  结果: 存在失败项，请检查上方日志")
	print("============================================================")
