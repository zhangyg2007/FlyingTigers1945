class_name HiroshimaCountdown
extends Node
## H4 广岛之刻特殊机制：倒计时生存，不可攻击，仅躲避
## 60秒倒计时，禁用玩家射击，全弹幕躲避生存

@export var countdown_time: float = 60.0  # 倒计时秒数
@export var disable_shooting: bool = true  # 禁用射击

var _time_remaining: float = 0.0
var _is_active: bool = false

func _ready() -> void:
	_time_remaining = countdown_time
	_is_active = true

	# 禁用玩家射击
	if disable_shooting:
		var player: Node = get_tree().get_first_node_in_group("player")
		if player != null and "can_shoot" in player:
			player.can_shoot = false

	print("[HiroshimaCountdown] 倒计时生存模式已激活：%.0f 秒，射击已禁用" % countdown_time)

func _process(delta: float) -> void:
	if not _is_active:
		return

	_time_remaining -= delta
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		_is_active = false
		_on_countdown_end()

func _on_countdown_end() -> void:
	# 倒计时结束，恢复射击并通知关卡完成
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and "can_shoot" in player:
		player.can_shoot = true

	print("[HiroshimaCountdown] 生存成功！倒计时结束")
	# 通知 LevelBase 关卡完成
	var parent: Node = get_parent()
	if parent != null and parent.has_method("end_level"):
		parent.end_level()

func get_time_remaining() -> float:
	return _time_remaining
