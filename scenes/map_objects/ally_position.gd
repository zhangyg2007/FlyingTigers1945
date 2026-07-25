## 友军阵地（v1.5 C13）
## 友军保护系统的核心目标节点。继承 MapObject 但 faction = "ally"。
## 玩家子弹穿透不造成伤害，敌方单位/敌弹可摧毁（保护失败）。
## 被摧毁时通知 EventManager 触发 protect_ally_event 失败回调。
##
## 设计要点：
## - faction = "ally"，由 MapObject.take_damage 过滤玩家子弹伤害
## - 敌方子弹（Layer3）通过 mask 检测：本节点 Layer7 = AllyTarget，检测 Layer3 = EnemyBullet
## - 被摧毁时不加分（友军损失），仅通知 EventManager 该事件失败
## - HP 归零 / 超时未保护均触发失败
class_name AllyPosition
extends MapObject

# ============================================================
# 导出属性
# ============================================================

## 关联的保护事件 ID（被摧毁时通知 EventManager）
@export var protect_event_id: String = ""

## 是否为关键保护目标（关键目标被摧毁即触发事件失败）
@export var is_critical: bool = true

## 友军阵地类型（mg_nest 机枪阵地 / aa_gun 高炮阵地 / transport_ship 运输船）
@export var ally_type: String = "mg_nest"


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	# 强制 faction = ally，无论 setup 中读到什么
	faction = "ally"
	is_interactive = true
	# 友军阵地碰撞层设置：
	# - Layer6 = GroundTarget（玩家子弹可检测但被 take_damage 过滤穿透）
	# - Layer7 = AllyTarget（敌方子弹/敌机可命中摧毁）
	# 检测：
	# - Layer3 = EnemyBullet（敌方子弹会摧毁友军）
	# - Layer4 = Enemy（敌机撞击友军阵地）
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true)  # Layer6 = GroundTarget
	set_collision_layer_value(7, true)  # Layer7 = AllyTarget
	set_collision_mask_value(3, true)   # 检测 Layer3 = EnemyBullet
	set_collision_mask_value(4, true)   # 检测 Layer4 = Enemy
	area_entered.connect(_on_area_entered)


# ============================================================
# 受击与摧毁
# ============================================================

## 友军阵地受击重写：忽略玩家子弹（faction != enemy 已过滤）
## 但敌方子弹需要造成伤害 —— 通过子弹 is_player_bullet 字段判断来源
func take_damage(damage: int) -> void:
	if not _is_alive:
		return
	_hp -= damage
	_on_damaged()
	if _hp <= 0:
		_is_alive = false
		_on_destroyed()


## 友军阵地被摧毁：触发事件失败，不加分
func _on_destroyed() -> void:
	# 友军损失：不加分（v1.5 删除误伤扣分，但友军被毁也不奖励）
	print("[AllyPosition] 友军阵地 '%s' 被摧毁（事件: %s）" % [object_id, protect_event_id])

	# 通知 EventManager 触发事件失败
	if not protect_event_id.is_empty():
		var em: Node = get_tree().get_first_node_in_group("event_manager")
		if em != null and em.has_method("report_ally_lost"):
			em.report_ally_lost(protect_event_id, object_id)

	# 生成爆炸特效（复用 MapObject 的爆炸逻辑，但不加分）
	_spawn_ally_explosion()
	queue_free()


## 受伤闪烁（红色）
func _on_damaged() -> void:
	var sprite: Sprite2D = _find_sprite(self)
	if sprite == null:
		return
	var original_color: Color = sprite.modulate
	sprite.modulate = Color(1, 0.5, 0.5, 1)
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", original_color, 0.15)


## 递归查找 Sprite2D
func _find_sprite(node: Node) -> Sprite2D:
	if node is Sprite2D:
		return node
	for child: Node in node.get_children():
		var result: Sprite2D = _find_sprite(child)
		if result != null:
			return result
	return null


## 简易爆炸特效（红色圆点扩散）
func _spawn_ally_explosion() -> void:
	var viewport: Node = get_viewport()
	if viewport == null:
		return
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	# 创建一个临时 ColorRect 作为爆炸视觉
	var explosion: ColorRect = ColorRect.new()
	explosion.color = Color(1, 0.3, 0.2, 0.7)
	explosion.size = Vector2(40, 40)
	explosion.position = global_position - Vector2(20, 20)
	parent_node.add_child(explosion)
	var tween: Tween = create_tween()
	tween.tween_property(explosion, "scale", Vector2(2.5, 2.5), 0.3)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		if is_instance_valid(explosion):
			explosion.queue_free()
	)


# ============================================================
# 碰撞检测重写
# ============================================================

## 友军阵地被敌方子弹/敌机撞击时受伤
## 玩家子弹（is_player_bullet = true）的碰撞已被 take_damage 内的 faction 过滤
## 这里直接处理：非玩家子弹/敌机撞击 → 造成伤害
func _on_area_entered(area: Area2D) -> void:
	if not _is_alive:
		return
	# 玩家子弹不伤害友军（faction 过滤已生效，但双保险）
	if area is BulletBase:
		var bullet: BulletBase = area as BulletBase
		if bullet.is_player_bullet:
			return
		# 敌方子弹伤害友军
		take_damage(bullet.damage)
		return
	# 敌机撞击友军阵地：造成较大伤害
	# 敌机的碰撞通过 Hitbox(Area2D) 子节点实现，需要获取父节点检查是否是 EnemyBase
	var check_node: Node = area
	if check_node.get_parent() != null:
		check_node = check_node.get_parent()
	if check_node.has_method("take_damage") and "current_hp" in check_node:
		take_damage(check_node.current_hp)
		return


## PoolManager 复用时重置状态
func reset_state() -> void:
	super.reset_state()
	faction = "ally"
	protect_event_id = ""
	is_critical = true
	ally_type = "mg_nest"
