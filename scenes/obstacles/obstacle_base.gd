class_name ObstacleBase
extends Area2D
## 环境障碍基类（v1.5 C16）
## 不可飞入的环境障碍：峡谷山壁、喀斯特峰林等。
## 由 LevelBase 根据 map JSON 配置动态生成，撞击玩家即造成伤害。
##
## v1.5 修复：碰撞层改为 Layer7 (Obstacle = 64)，避免与 PowerupBase 的 Layer5 (16) 冲突
## 原 Layer5 会被玩家 hitbox (mask=Layer5) 误检测为道具触发拾取逻辑
## 检测 Layer1 (Player = 1)
## 子类只需配置 damage 和 sprite，无需重写逻辑

# ============================================================
# 导出属性
# ============================================================

## 障碍物唯一标识符
@export var obstacle_id: String = ""

## 障碍物类型（canyon_wall / karst_peak / mountain_ridge 等）
@export var obstacle_type: String = ""

## 撞击伤害（默认 9999 = 秒杀，canyon_wall 用；karst_peak 可设为 25 中等伤害）
@export var contact_damage: int = 9999

## 是否一次性（撞击后消失，false = 持续存在可多次撞击）
@export var one_shot: bool = false

# ============================================================
# 内部状态
# ============================================================

## 是否已触发过撞击（one_shot = false 时无效）
var _has_triggered: bool = false

## 地图 Y 坐标（供 MapObjectManager 判断生成窗口）
var map_spawn_y: float = 0.0

## v1.5 E12: 背景滚动速度（由 MapObjectManager 设置）
var _scroll_speed: float = 0.0


func _ready() -> void:
	# v1.5 修复：Layer7 = Obstacle (64)，检测 Layer1 = Player (1)
	# 原用 Layer5(16) 与 PowerupBase 冲突，会被玩家 hitbox 误检测为道具
	collision_layer = 64
	collision_mask = 1
	# 使用 body_entered 检测玩家进入（玩家是 CharacterBody2D）
	body_entered.connect(_on_body_entered)
	set_process(true)


## v1.5 E12: 每帧跟随背景滚动向下移动
func _process(delta: float) -> void:
	if _scroll_speed > 0.0:
		position.y += _scroll_speed * delta


## v1.5 E12: 设置滚动速度（由 MapObjectManager._spawn_object 调用）
func set_scroll_speed(speed: float) -> void:
	_scroll_speed = speed


## 从 JSON 字典初始化障碍物属性
## [param data]: map JSON 中的障碍物配置字典
func setup(data: Dictionary) -> void:
	obstacle_id = String(data.get("id", ""))
	obstacle_type = String(data.get("type", ""))

	# 安全读取 position 嵌套字典
	var pos_dict: Dictionary = data.get("position", {})
	position = Vector2(
		float(pos_dict.get("x", 0.0)),
		float(pos_dict.get("y", 0.0))
	)
	map_spawn_y = position.y

	# 读取 properties
	var props: Dictionary = data.get("properties", {})
	contact_damage = int(props.get("contact_damage", 9999))
	one_shot = bool(props.get("one_shot", false))


## 玩家撞击回调
func _on_body_entered(body: Node) -> void:
	# 仅处理玩家撞击
	if not (body is PlayerBase):
		return

	# one_shot 障碍物：触发一次后不再触发
	if one_shot and _has_triggered:
		return

	_has_triggered = true

	# v1.5 修复：原代码无视 contact_damage 字段恒调用 lose_life()，
	# 导致 JSON 配置的 karst_peak 中等伤害完全失效。
	# 现按 contact_damage 值分级处理：
	# - >= 9999：秒杀（canyon_wall / karst_peak 默认），调用 lose_life()
	# - 1~9998：中等伤害（与敌机碰撞一致），power_level > 1 时降级，否则 lose_life()
	var player: PlayerBase = body
	if contact_damage >= 9999:
		player.lose_life()
	elif player.power_level > 1:
		# 中等伤害：降一级火力 + 短暂无敌（与 on_enemy_collision 一致）
		player.power_level -= 1
		if player.has_signal("power_changed"):
			player.power_changed.emit(player.power_level)
		if player.has_method("_start_invincibility"):
			player._start_invincibility(0.5)
	else:
		# power_level 已是 1，无火力可降，直接扣命
		player.lose_life()

	print("[ObstacleBase] 玩家撞击 %s (id=%s), 伤害=%d" % [obstacle_type, obstacle_id, contact_damage])

	# one_shot 障碍物撞击后消失（如可摧毁的山体碎石）
	if one_shot:
		queue_free()


## PoolManager 复用时重置状态
func reset_state() -> void:
	_has_triggered = false
	position = Vector2.ZERO
	map_spawn_y = 0.0
	obstacle_id = ""
	obstacle_type = ""
	contact_damage = 9999
	one_shot = false
	# v1.5 E12: 重置滚动速度
	_scroll_speed = 0.0
