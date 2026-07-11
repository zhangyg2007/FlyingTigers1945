class_name TokyoBombing
extends Node
## H2 轰炸东京特殊机制：逆向卷轴（上→下），仅轰炸地面目标
## 反转背景滚动方向，禁用空中敌机生成，仅保留地面目标

@export var reverse_scroll: bool = true  # 逆向滚动
@export var ground_targets_only: bool = true  # 仅地面目标

func _ready() -> void:
	var parent: Node = get_parent()
	if parent != null and "bg_scroll_speed" in parent:
		# 逆向滚动：负速度
		if reverse_scroll:
			parent.bg_scroll_speed = -absf(parent.bg_scroll_speed)
	print("[TokyoBombing] 逆向卷轴+仅轰炸目标模式已激活")
