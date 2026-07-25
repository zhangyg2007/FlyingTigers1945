class_name MapObject
extends Area2D
## 地图对象基类（M3-G G-C1）
## 所有地图交互对象（坦克、碉堡、车队、平民车辆、防空炮等）的基类。
## 由 MapObjectManager 根据地图 JSON 配置动态生成。
##
## 设计要点：
## - setup(data) 从 JSON 字典初始化属性
## - take_damage(damage) 处理受伤
## - reset_state() 供 PoolManager 复用对象时重置状态
## - 碰撞层：Layer6(GroundTarget) 检测 Layer2(PlayerBullet)

# ============================================================
# 导出属性
# ============================================================

## 对象唯一标识符
@export var object_id: String = ""
## 对象类型（enemy_tank / bunker / convoy / civilian_car / anti_air_gun）
@export var object_type: String = ""
## 是否可交互（不可交互对象如平民车辆不响应攻击）
@export var is_interactive: bool = true
## 分数奖励
@export var score_value: int = 100
## v1.5 C20: 阵营标识（enemy / ally / civilian）
## - enemy: 可被玩家子弹击毁，掉落分数
## - ally: 玩家子弹直接穿过，无碰撞响应（保护目标）
## - civilian: 玩家子弹直接穿过，无碰撞响应（误伤已删除）
@export var faction: String = "enemy"

# ============================================================
# 内部状态
# ============================================================

## 当前 HP
var _hp: int = 1
## 最大 HP
var _max_hp: int = 1
## 是否存活
var _is_alive: bool = true
## 地图 Y 坐标（用于 MapObjectManager 判断是否进入生成窗口）
var map_spawn_y: float = 0.0

## v1.5 C16: 被摧毁时暴露的隐藏对象配置（L05 废墟暴露隐藏高炮）
## 从 properties.reveals_on_destroy 读取，格式同 map JSON 中的 object 配置
## _on_destroyed 时由 MapObjectManager 生成对应场景
var _reveals_on_destroy: Array = []

## v1.5 E12: 背景滚动速度（由 MapObjectManager 设置，_process 中向下移动模拟玩家飞行）
var _scroll_speed: float = 0.0


func _ready() -> void:
	if is_interactive:
		# v1.5 修复：Layer6 = GroundTarget = 2^5 = 32（原误写为 64=Layer7，与玩家子弹 mask=32 不匹配）
		collision_layer = 32
		collision_mask = 2
		area_entered.connect(_on_area_entered)
	else:
		# 不可交互对象：Layer8 = Scenery (256)，不检测任何碰撞
		collision_layer = 256
		collision_mask = 0
	set_process(true)


## v1.5 E12: 每帧跟随背景滚动向下移动（模拟玩家向前飞行，地面对象向后退）
func _process(delta: float) -> void:
	if _scroll_speed > 0.0:
		position.y += _scroll_speed * delta


## v1.5 E12: 设置滚动速度（由 MapObjectManager._spawn_object 调用）
func set_scroll_speed(speed: float) -> void:
	_scroll_speed = speed


## 从 JSON 字典初始化对象属性
func setup(data: Dictionary) -> void:
	object_id = String(data.get("id", ""))
	object_type = String(data.get("type", ""))

	# 安全读取 position 嵌套字典
	var pos_dict: Dictionary = data.get("position", {})
	position = Vector2(
		float(pos_dict.get("x", 0.0)),
		float(pos_dict.get("y", 0.0))
	)
	map_spawn_y = position.y

	# 读取 properties
	var props: Dictionary = data.get("properties", {})
	_hp = int(props.get("hp", 1))
	_max_hp = _hp
	score_value = int(props.get("score", 100))
	is_interactive = bool(props.get("is_interactive", true))
	# v1.5 C20: 读取阵营（默认 enemy）
	faction = String(props.get("faction", "enemy"))
	# v1.5 C16: 读取被摧毁时暴露的隐藏对象配置
	_reveals_on_destroy = props.get("reveals_on_destroy", [])


## 受到伤害
## v1.5 C20: ally / civilian 阵营不接受伤害（玩家子弹穿过）
func take_damage(damage: int) -> void:
	if not _is_alive or not is_interactive:
		return
	if faction != "enemy":
		return
	_hp -= damage
	_on_damaged()
	if _hp <= 0:
		_is_alive = false
		_on_destroyed()


## 受伤回调（子类可重写实现受伤特效）
func _on_damaged() -> void:
	pass


## 被摧毁回调（子类可重写实现爆炸特效 + 分数奖励）
func _on_destroyed() -> void:
	if GameManager:
		GameManager.add_score(score_value)
	# v1.5: 注册 Combo 击落
	if ComboManager:
		ComboManager.register_kill()
	# v1.5 C16: 触发被摧毁时暴露的隐藏对象（L05 废墟暴露隐藏高炮）
	_reveal_hidden_objects()
	queue_free()


## v1.5 C16: 被摧毁时暴露隐藏对象
## 遍历 _reveals_on_destroy 配置，通过 MapObjectManager 生成新对象
func _reveal_hidden_objects() -> void:
	if _reveals_on_destroy.is_empty():
		return
	if MapObjectManager == null:
		return
	for reveal_data in _reveals_on_destroy:
		if not (reveal_data is Dictionary):
			continue
		# 复制配置，位置相对于当前对象偏移（如果配置中没有绝对位置）
		var reveal_config: Dictionary = reveal_data.duplicate()
		# 如果没有 position 字段，使用当前对象位置
		if not reveal_config.has("position"):
			reveal_config["position"] = {"x": int(position.x), "y": int(position.y)}
		# 通过 MapObjectManager 生成（复用对象池）
		MapObjectManager.spawn_object_by_data(reveal_config)
		print("[MapObject] %s (id=%s) 被摧毁，暴露隐藏对象: %s" % [
			object_type, object_id, String(reveal_config.get("type", ""))
		])


## 设置碰撞层（在 setup() 末尾调用，确保 is_interactive 已正确设置）
func _setup_collision() -> void:
	if is_interactive:
		# v1.5 修复：Layer6 = 32（同 _ready）
		collision_layer = 32
		collision_mask = 2
		if not area_entered.is_connected(_on_area_entered):
			area_entered.connect(_on_area_entered)
	else:
		collision_layer = 256
		collision_mask = 0


## v1.5 C16: 查询对象是否存活（供 FuelDepot 连锁爆炸判断使用）
func is_alive() -> bool:
	return _is_alive


## v1.5 C16: 获取当前 HP（供 UI / 调试用）
func get_hp() -> int:
	return _hp


## 碰撞检测：玩家子弹进入时受伤
## v1.5 C20: ally / civilian 阵营直接 return，子弹由 bullet_base 自身判断是否穿透
func _on_area_entered(area: Area2D) -> void:
	if not _is_alive or not is_interactive:
		return
	if faction != "enemy":
		return
	if "damage" in area:
		take_damage(int(area.damage))


## PoolManager 复用时重置状态
func reset_state() -> void:
	_is_alive = true
	_hp = _max_hp
	position = Vector2.ZERO
	map_spawn_y = 0.0
	object_id = ""
	object_type = ""
	is_interactive = true
	score_value = 100
	faction = "enemy"
	# v1.5 修复：重置 reveals_on_destroy，避免对象池复用后携带上一局配置
	_reveals_on_destroy.clear()
	# v1.5 E12: 重置滚动速度
	_scroll_speed = 0.0
