class_name C47Transport
extends Area2D
## C-47 运输机（v1.5 C17 H1 驼峰绝径护送系统）
## 跟随背景滚动向下移动，被敌弹击中受伤，HP 归零爆炸消失。
## 玩家需保护 C-47 编队通过 H1 关卡。
##
## 碰撞层：Layer7 (Ally = 64)，检测 Layer3 (EnemyBullet = 4) + Layer4 (Enemy = 8)
## v1.5 修复：原 collision_layer=128 实为 Layer8 (Scenery)，与 project.godot 中
## layer_7="Ally" 不符；且原 mask=4 仅检测敌弹，不检测敌机撞击。
## 与 ally_position.gd:45-47 范式对齐。

# ============================================================
# 信号
# ============================================================

## C-47 被摧毁时发出
signal destroyed(escort_id: String)

# ============================================================
# 导出属性
# ============================================================

## 运输机唯一 ID
@export var escort_id: String = ""

## 最大 HP
@export var max_hp: int = 30

## 跟随背景滚动的速度（像素/秒，与关卡 bg_scroll_speed 一致）
@export var scroll_speed: float = 130.0

# ============================================================
# 内部状态
# ============================================================

## 当前 HP
var _current_hp: int = 30
## 是否存活
var _is_alive: bool = true

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	# v1.5 修复：Layer7 = Ally = 2^(7-1) = 64（原误写为 128=Layer8 Scenery）
	# 同时检测 Layer3=EnemyBullet(4) 和 Layer4=Enemy(8)，让敌机撞击也能伤害 C-47
	collision_layer = 64
	collision_mask = 4 | 8
	_current_hp = max_hp
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if not _is_alive:
		return
	# 跟随背景滚动向下移动
	position.y += scroll_speed * delta
	# v1.5 修复：C-47 起始 y=-100 + 滚动 130px/s → 15.5s 飞出 1920 视口底部，
	# 而 H1 BOSS 在 44s 才出场，导致护送对象在 BOSS 战时早已不可见。
	# 改为：C-47 进入屏幕中部后停留，不再随背景继续下滚（背景仍在滚，但 C-47 驻留等待玩家保护）。
	var viewport_y: float = get_viewport_rect().size.y
	var loiter_y: float = viewport_y * 0.4  # 屏幕上 40% 位置驻留
	if position.y > loiter_y:
		position.y = loiter_y


# ============================================================
# 公开方法
# ============================================================

## 受到伤害
func take_damage(damage: int) -> void:
	if not _is_alive:
		return
	_current_hp -= damage
	print("[C47Transport] %s 受击! HP=%d/%d" % [escort_id, _current_hp, max_hp])
	if _current_hp <= 0:
		_die()


## 是否存活
func is_alive() -> bool:
	return _is_alive


## 获取当前 HP 比例（0.0~1.0，供 HUD 显示）
func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(_current_hp) / float(max_hp)


# ============================================================
# 内部方法
# ============================================================

## 被摧毁
func _die() -> void:
	_is_alive = false
	destroyed.emit(escort_id)
	print("[C47Transport] %s 被摧毁！" % escort_id)
	# v1.5 修复：补充爆炸特效（原 TODO 占位），复用 ally_position.gd 的 ColorRect 扩散模式
	_spawn_explosion()
	queue_free()


## v1.5 新增：爆炸特效（C-47 被摧毁时的大型橙色扩散）
func _spawn_explosion() -> void:
	var explosion := ColorRect.new()
	explosion.color = Color(1.0, 0.5, 0.1, 0.9)
	explosion.size = Vector2(80, 80)
	explosion.position = global_position - Vector2(40, 40)
	explosion.z_index = 50
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	parent_node.add_child(explosion)
	var tween: SceneTreeTween = parent_node.create_tween()
	tween.tween_property(explosion, "scale", Vector2(3.0, 3.0), 0.4)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		if is_instance_valid(explosion):
			explosion.queue_free()
	)


## 敌弹/敌机进入时受伤
## v1.5 修复：
## - 用 BulletBase 类型判断替代 duck-type "damage" in area（更安全，与 ally_position.gd 一致）
## - 敌弹销毁改为调用 _destroy() 归还对象池（原 queue_free 破坏对象池计数）
## - 新增敌机撞击伤害处理（原 mask=4 漏检 Layer4=Enemy）
func _on_area_entered(area: Area2D) -> void:
	if not _is_alive:
		return
	# 敌方子弹：造成子弹伤害并归还对象池
	if area is BulletBase:
		var bullet: BulletBase = area as BulletBase
		if bullet.is_player_bullet:
			return  # 玩家子弹不伤害友军（防御性双保险）
		take_damage(bullet.damage)
		bullet._destroy()
		return
	# 敌机撞击：造成等于敌机 HP 的一次性伤害（与 ally_position.gd 一致）
	if area is EnemyBase:
		var enemy: EnemyBase = area as EnemyBase
		take_damage(enemy.current_hp)
		return
