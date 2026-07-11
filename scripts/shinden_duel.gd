class_name ShindenDuel
extends Node
## H3 震电对决特殊机制：1v1 BOSS Rush，仅对单一高速目标
## 跳过普通波次，直接生成 BOSS，BOSS 移动速度和攻击频率提升

@export var boss_speed_mult: float = 1.5  # BOSS速度倍率
@export var boss_attack_interval_mult: float = 0.5  # BOSS攻击间隔倍率（更频繁）

func _ready() -> void:
	# 监听 BOSS 生成，应用强化参数
	if SpawnManager.has_signal("enemy_spawned"):
		if not SpawnManager.enemy_spawned.is_connected(_on_enemy_spawned):
			SpawnManager.enemy_spawned.connect(_on_enemy_spawned)
	print("[ShindenDuel] 震电对决模式已激活：BOSS 强化 1.5x 速度 / 0.5x 攻击间隔")

func _on_enemy_spawned(enemy: Node) -> void:
	# 对 BOSS 应用强化参数
	if enemy is BossBase:
		var boss: BossBase = enemy as BossBase
		boss.move_speed *= boss_speed_mult
		# 攻击间隔缩短
		for i in range(boss.phase_attack_intervals.size()):
			boss.phase_attack_intervals[i] *= boss_attack_interval_mult
		print("[ShindenDuel] BOSS 已强化: move_speed=%.0f, attack_interval_mult=%.1f" % [boss.move_speed, boss_attack_interval_mult])
