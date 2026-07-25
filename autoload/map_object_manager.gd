extends Node
## 地图对象管理器（Autoload 单例，M3-G G-C2）
## 负责从地图 JSON 配置加载地面对象，并根据背景滚动位置动态生成。
##
## 工作原理：
## 1. LevelBase 调用 load_map_config(path) 加载 stage_XX_map.json
## 2. 每帧 LevelBase 调用 update(scroll_offset_y) 传入当前背景滚动偏移
## 3. 当对象的 map_spawn_y 进入生成窗口（scroll_y + 下方阈值）时实例化对象
##
## 对象池复用：通过 PoolManager 管理对象，减少创建/销毁开销

# ============================================================
# 常量
# ============================================================

## 地图对象场景路径映射
const SCENE_PATHS: Dictionary = {
	"enemy_tank": "res://scenes/map_objects/enemy_tank.tscn",
	"bunker": "res://scenes/map_objects/bunker.tscn",
	"convoy": "res://scenes/map_objects/convoy.tscn",
	"civilian_car": "res://scenes/map_objects/civilian_car.tscn",
	"anti_air_gun": "res://scenes/map_objects/anti_air_gun.tscn",
	# v1.5 新增地面目标
	"train_car": "res://scenes/map_objects/train_car.tscn",
	"fuel_depot": "res://scenes/map_objects/fuel_depot.tscn",
	"bridge": "res://scenes/map_objects/bridge_target.tscn",
	"airfield_runway": "res://scenes/map_objects/airfield_runway.tscn",
	# v1.5 C16 新增环境障碍
	"canyon_wall": "res://scenes/obstacles/canyon_wall.tscn",
	"karst_peak": "res://scenes/obstacles/karst_peak.tscn",
}

## 生成窗口提前量（像素）：对象在进入屏幕上方此距离时生成
const SPAWN_AHEAD: float = 200.0

## 默认对象池容量
const DEFAULT_POOL_SIZE: int = 15

# ============================================================
# 内部状态
# ============================================================

## 待生成的对象队列（按 y 坐标排序）
var _pending_objects: Array[Dictionary] = []

## 已生成的活跃对象引用（v1.5 C16: 同时存储 MapObject 和 ObstacleBase）
var _active_objects: Array = []

## 当前关卡的父节点（用于 add_child）
var _level_parent: Node = null

## 地图配置是否已加载
var _is_loaded: bool = false

## v1.5 E12: 当前关卡的背景滚动速度（从 map JSON 读取，供 MapObject 滚动使用）
var _scroll_speed: float = 0.0

## v1.5 E12: 当前滚动偏移量（供 _spawn_object 计算屏幕位置）
var _current_scroll_offset_y: float = 0.0


# ============================================================
# 公开方法
# ============================================================

## 加载地图配置 JSON
## [param json_path]: 地图配置文件路径（如 res://resources/level_data/stage_01_kunming_map.json）
## [param level_parent]: 关卡根节点，用于将生成的对象添加到场景树
func load_map_config(json_path: String, level_parent: Node) -> void:
	clear()
	_level_parent = level_parent

	if json_path.is_empty():
		return

	if not FileAccess.file_exists(json_path):
		# 静默跳过：无地图配置的关卡正常运行（向后兼容）
		return

	var text: String = FileAccess.get_file_as_string(json_path)
	if text.is_empty():
		push_warning("[MapObjectManager] 地图配置文件为空: %s" % json_path)
		return

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("[MapObjectManager] 地图配置解析失败: %s (行 %d: %s)" % [
			json_path, json.get_error_line(), json.get_error_message()
		])
		return

	var data: Dictionary = json.data
	var map: Dictionary = data.get("map", {})
	var objects: Array = map.get("objects", [])

	# v1.5 E12: 读取背景滚动速度，供 MapObject/ObstacleBase 滚动使用
	_scroll_speed = float(map.get("scroll_speed", 0.0))

	_pending_objects.clear()
	for obj_data in objects:
		if obj_data is Dictionary:
			_pending_objects.append(obj_data)

	# 按 y 坐标升序排序（确保从上到下依次生成）
	_pending_objects.sort_custom(func(a, b):
		var ya: float = float((a as Dictionary).get("position", {}).get("y", 0.0))
		var yb: float = float((b as Dictionary).get("position", {}).get("y", 0.0))
		return ya < yb
	)

	_is_loaded = true
	print("[MapObjectManager] 地图配置已加载: %s（待生成对象 %d 个）" % [json_path, _pending_objects.size()])


## 每帧更新：根据背景滚动偏移生成进入窗口的对象
## [param scroll_offset_y]: 当前背景向下滚动的累计偏移量（像素）
func update(scroll_offset_y: float) -> void:
	if not _is_loaded or _pending_objects.is_empty():
		return

	# v1.5 E12: 存储当前滚动偏移，供 _spawn_object 计算屏幕位置
	_current_scroll_offset_y = scroll_offset_y

	# 生成窗口：当对象的 map_spawn_y - scroll_offset_y <= 屏幕高度 + SPAWN_AHEAD 时生成
	# 屏幕高度默认 1920，加上提前量
	var spawn_threshold: float = scroll_offset_y + 1920.0 + SPAWN_AHEAD

	var remaining: Array[Dictionary] = []
	for obj_data in _pending_objects:
		var obj_y: float = float(obj_data.get("position", {}).get("y", 0.0))
		if obj_y <= spawn_threshold:
			_spawn_object(obj_data)
		else:
			remaining.append(obj_data)
	_pending_objects = remaining


## 清理所有对象和状态（关卡结束时调用）
func clear() -> void:
	# v1.5 修复：归还活跃对象到对象池（原用 queue_free 导致对象池失效，每次关卡结束丢失池中对象）
	# PoolManager.return_object 会自动处理不在池中的对象（兜底 queue_free）
	for obj in _active_objects:
		if is_instance_valid(obj):
			PoolManager.return_object(obj)
	_active_objects.clear()
	_pending_objects.clear()
	_level_parent = null
	_is_loaded = false
	# v1.5 E12: 重置滚动状态
	_scroll_speed = 0.0
	_current_scroll_offset_y = 0.0


## 获取当前活跃对象数量
func get_active_count() -> int:
	return _active_objects.size()


## 获取待生成对象数量
func get_pending_count() -> int:
	return _pending_objects.size()


## v1.5 C16: 获取活跃对象列表（供 FuelDepot 连锁爆炸遍历使用）
## 返回 Array，包含 MapObject 和 ObstacleBase 实例
func get_active_objects_list() -> Array:
	return _active_objects.duplicate()


## v1.5 C16: 按数据立即生成单个对象（供 MapObject.reveals_on_destroy 调用）
## 与 _pending_objects 队列无关，立即实例化并加入活跃列表
## [param obj_data]: map JSON 中的对象配置字典
func spawn_object_by_data(obj_data: Dictionary) -> void:
	if _level_parent == null:
		return
	_spawn_object(obj_data)


# ============================================================
# 内部方法
# ============================================================

## 生成单个地图对象
func _spawn_object(obj_data: Dictionary) -> void:
	var type_name: String = String(obj_data.get("type", ""))
	var scene_path: String = SCENE_PATHS.get(type_name, "")

	if scene_path.is_empty():
		push_warning("[MapObjectManager] 未知对象类型: %s" % type_name)
		return

	# 通过 PoolManager 获取对象（自动注册池）
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_warning("[MapObjectManager] 无法加载场景: %s" % scene_path)
		return

	var obj: Node = PoolManager.get_object(scene, _level_parent)
	if obj == null:
		push_warning("[MapObjectManager] 无法获取对象实例: %s" % scene_path)
		return

	# 初始化对象
	# v1.5 C16: 支持 MapObject 和 ObstacleBase 两种类型
	if obj is MapObject:
		(obj as MapObject).setup(obj_data)
		# v1.5 E12: 设置滚动速度，让地面对象跟随背景滚动
		(obj as MapObject).set_scroll_speed(_scroll_speed)
	elif obj is ObstacleBase:
		(obj as ObstacleBase).setup(obj_data)
		# v1.5 E12: 障碍物也跟随背景滚动
		(obj as ObstacleBase).set_scroll_speed(_scroll_speed)

	# v1.5 E12: 将对象放置在屏幕上方（y = -SPAWN_AHEAD），使其从屏幕顶部进入并向下滚动
	# map JSON 中的 y 值仅控制生成时机（何时进入屏幕），不影响屏幕位置
	# 对象通过 _process 中的 position.y += scroll_speed * delta 向下滚动
	if obj is Node2D:
		(obj as Node2D).position.y = -SPAWN_AHEAD

	_active_objects.append(obj)

	# 对象被摧毁时从活跃列表移除
	if obj.has_signal("tree_exited"):
		obj.tree_exited.connect(_on_object_freed.bind(obj))

	print("[MapObjectManager] 生成对象: type=%s, id=%s" % [type_name, String(obj_data.get("id", ""))])


## 对象被释放时从活跃列表移除
func _on_object_freed(obj: Node) -> void:
	_active_objects.erase(obj)
