## 情报牛皮纸袋道具（v1.5 C12）
## 由隐藏情报事件的目标被击毁后掉落，玩家碰触即得。
## 拾取后写入 SaveManager.intel_collected，并触发对应隐藏关解锁条件检查。
##
## 设计要点：
## - 继承 PowerupBase，复用下落 + 浮动 + 拾取碰撞逻辑
## - 不复用 PowerupType 枚举，使用专属 intel_id 字段标识情报
## - 拾取后通过 EventManager 通知事件系统完成（联动 intel_event_briefcase 事件）
class_name IntelBriefcase
extends PowerupBase

# ============================================================
# 导出属性
# ============================================================

## 情报 ID（对应 SaveManager.intel_collected 列表中的元素）
## 例：intel_hump_route / intel_tokyo_bombing / intel_hengyang_status / intel_hiroshima_target
@export var intel_id: String = ""

## 关联的事件 ID（用于通知 EventManager 该情报事件已通过拾取完成）
@export var event_id: String = ""

## 隐藏关卡解锁标识（拾取后写入 SaveManager，由 UnlockManager 二次判定军衔条件）
@export var unlock_hidden: String = ""

## 情报显示名（用于 HUD 提示）
@export var intel_display_name: String = "机密情报"


# ============================================================
# 生命周期重写
# ============================================================

func _ready() -> void:
	# 复用父类的碰撞层设置（Layer5 = PowerUp，检测 Layer1 = Player）
	super._ready()
	# 情报纸袋下落速度比普通道具慢，便于玩家追上
	if fall_speed > 40.0:
		fall_speed = 40.0


# ============================================================
# 拾取效果重写
# ============================================================

## 玩家拾取后应用情报效果
## 不调用父类 _apply_effect（父类是 PowerupType 枚举分发，不适用于情报）
func _apply_effect(_player: Node) -> void:
	if intel_id.is_empty():
		push_warning("[IntelBriefcase] intel_id 为空，无法记录情报")
		return

	# 写入存档
	if SaveManager:
		SaveManager.add_intel(intel_id)

	# 通知 EventManager 该情报事件已完成（触发奖励发放 + 隐藏关解锁检查）
	# v1.5 修复：EventManager 不是 autoload（由 LevelBase 动态实例化），
	# Engine.has_singleton("EventManager") 永远返回 false，导致 report_intel_collected 从不调用，
	# 进而 3 个关卡的情报分数奖励（L02/L04/L07）无法发放。
	# 改为直接通过 group 查找（与 event_target_base.gd:84-91 范式一致）。
	if event_id != "":
		var em: Node = get_tree().get_first_node_in_group("event_manager")
		if em != null and em.has_method("report_intel_collected"):
			em.report_intel_collected(event_id, intel_id)

	# HUD 提示
	print("[IntelBriefcase] 已拾取情报: %s (%s)" % [intel_display_name, intel_id])

	# 触发全局信号（HUD 可监听显示提示）
	if GameManager and GameManager.has_signal("intel_collected"):
		GameManager.intel_collected.emit(intel_id, intel_display_name)
