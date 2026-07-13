class_name MapObject
extends Node2D
## 地图对象基类（M3-G G-C1）
## 所有地图交互对象（坦克、碉堡、车队、平民车辆、防空炮等）的基类。
## 由 MapObjectManager 根据地图 JSON 配置动态生成。
##
## 设计要点：
## - setup(data) 从 JSON 字典初始化属性
## - take_damage(damage) 处理受伤
## - reset_state() 供 PoolManager 复用对象时重置状态
## - 碰撞层：Layer4(Enemy) + Layer2(PlayerBullet) 检测

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


## 受到伤害
func take_damage(damage: int) -> void:
	if not _is_alive or not is_interactive:
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
	# 默认行为：加分数 + 释放节点
	if GameManager:
		GameManager.add_score(score_value)
	queue_free()


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
