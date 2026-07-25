class_name FuelDepot
extends MapObject
## 油库（v1.5 C16 L06 宝庆战略轰炸专用）
## 被摧毁时触发 AOE 连锁爆炸，对范围内的其他 MapObject 造成伤害。
## 用于 L06 弹药库综合体 + 油库群连锁爆炸机制。
##
## 配置（map JSON properties）：
## - chain_explosion_radius: 连锁爆炸半径（像素，默认 200）
## - chain_damage: 连锁伤害值（默认 9999 = 秒杀相邻油库）
## - chain_delay: 连锁延迟（秒，默认 0.1，避免单帧爆炸卡顿）

# ============================================================
# 导出属性
# ============================================================

## 连锁爆炸半径（像素）
@export var chain_explosion_radius: float = 200.0

## 连锁伤害值（对相邻 MapObject 造成）
@export var chain_damage: int = 9999

## 连锁延迟（秒，避免单帧内所有油库同时爆炸）
@export var chain_delay: float = 0.1

## 是否已触发连锁（防止递归死循环）
var _chain_triggered: bool = false


func _ready() -> void:
	super._ready()


## v1.5 修复：对象池复用时重置 _chain_triggered，避免复用油库无法触发连锁爆炸
func reset_state() -> void:
	super.reset_state()
	_chain_triggered = false


## 从 JSON 字典初始化（扩展父类 setup）
func setup(data: Dictionary) -> void:
	super.setup(data)
	var props: Dictionary = data.get("properties", {})
	chain_explosion_radius = float(props.get("chain_explosion_radius", 200.0))
	chain_damage = int(props.get("chain_damage", 9999))
	chain_delay = float(props.get("chain_delay", 0.1))


## 被摧毁回调：触发连锁爆炸
func _on_destroyed() -> void:
	# 先触发连锁爆炸（在 queue_free 之前，确保 position 仍有效）
	if not _chain_triggered:
		_chain_triggered = true
		_trigger_chain_explosion()

	# 调用父类 _on_destroyed（加分数 + Combo + queue_free）
	super._on_destroyed()


## 触发 AOE 连锁爆炸
## 遍历场景中所有 MapObject，对在 radius 内的 enemy 阵营对象造成 chain_damage
func _trigger_chain_explosion() -> void:
	print("[FuelDepot] 连锁爆炸触发！位置=%s, 半径=%.0f, 伤害=%d" % [
		global_position, chain_explosion_radius, chain_damage
	])

	# 通过 MapObjectManager 获取所有活跃的 MapObject
	if MapObjectManager == null:
		return

	var active_objects: Array = MapObjectManager.get_active_objects_list()
	var chain_count: int = 0

	for obj in active_objects:
		if not is_instance_valid(obj):
			continue
		if obj == self:
			continue
		if not (obj is MapObject):
			continue

		var map_obj: MapObject = obj
		# 仅连锁 enemy 阵营（友军/平民不受波及）
		if map_obj.faction != "enemy":
			continue
		# 跳过已死亡对象
		if not map_obj.is_alive():
			continue

		# 距离检查
		var distance: float = global_position.distance_to(map_obj.global_position)
		if distance <= chain_explosion_radius:
			# 延迟触发连锁（用 Timer 或 call_deferred 避免单帧爆炸）
			_delayed_chain_damage(map_obj, chain_damage)
			chain_count += 1

	print("[FuelDepot] 连锁波及 %d 个相邻目标" % chain_count)


## 延迟施加连锁伤害（避免单帧内递归爆炸导致栈溢出）
func _delayed_chain_damage(target: MapObject, damage: int) -> void:
	# 使用 SceneTreeTimer 延迟施加伤害，让连锁爆炸有视觉延迟感
	var tree: SceneTree = get_tree()
	if tree == null:
		target.take_damage(damage)
		return
	tree.create_timer(chain_delay).timeout.connect(
		func():
			if is_instance_valid(target):
				target.take_damage(damage)
	)
