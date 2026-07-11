extends Node
## 军衔等级系统管理器（Autoload 单例，M3-F F-C1）
## 基于累计表现计算军衔等级，作为隐藏关卡的解锁门槛条件之一。
##
## 军衔等级：PVT(列兵) → CPL(下士) → SGT(中士) → CPT(上尉) → MAJ(少校) → COL(上校) → ACE(王牌)
## 军衔分数 = 通关数量×10万 + 累计总分×50% + S评级数量×20万

# ============================================================
# 常量
# ============================================================

const RANK_THRESHOLDS: Dictionary = {
	"CPL": 200000,
	"SGT": 800000,
	"CPT": 2000000,
	"MAJ": 5000000,
	"COL": 10000000,
	"ACE": -1,
}

const RANK_STAGES_REQUIRED: Dictionary = {
	"CPL": 3,
	"SGT": 6,
	"CPT": 8,
	"MAJ": 10,
	"COL": 12,
	"ACE": 12,
}

const RANK_S_REQUIRED: Dictionary = {
	"CPT": 2,
	"MAJ": 4,
	"COL": 6,
	"ACE": 12,
}

const RANK_NAMES: Dictionary = {
	"PVT": "列兵",
	"CPL": "下士",
	"SGT": "中士",
	"CPT": "上尉",
	"MAJ": "少校",
	"COL": "上校",
	"ACE": "王牌",
}

const RANK_COLORS: Dictionary = {
	"PVT": Color(0.5, 0.5, 0.5, 1.0),
	"CPL": Color(0.7, 0.5, 0.3, 1.0),
	"SGT": Color(0.85, 0.65, 0.13, 1.0),
	"CPT": Color(0.75, 0.75, 0.75, 1.0),
	"MAJ": Color(1.0, 0.84, 0.0, 1.0),
	"COL": Color(0.6, 0.8, 1.0, 1.0),
	"ACE": Color(1.0, 0.9, 0.5, 1.0),
}

const HIDDEN_STAGE_RANK_REQUIRED: Dictionary = {
	"H1_hump_extreme": "SGT",
	"H2_tokyo_bombing": "CPT",
	"H3_shinden_duel": "MAJ",
	"H4_hiroshima_countdown": "COL",
}

const RANK_ORDER: Array[String] = ["PVT", "CPL", "SGT", "CPT", "MAJ", "COL", "ACE"]

# ============================================================
# 公开方法
# ============================================================

func calculate_rank_score() -> int:
	var stages_cleared: int = SaveManager.highest_stage
	var total_score: int = SaveManager.total_score
	var s_rank_count: int = SaveManager.get_s_rank_count()
	
	return (
		stages_cleared * 100000
		+ int(total_score * 0.5)
		+ s_rank_count * 200000
	)

func get_current_rank() -> String:
	var score: int = calculate_rank_score()
	var stages: int = SaveManager.highest_stage
	var s_count: int = SaveManager.get_s_rank_count()
	
	if s_count >= 12 and stages >= 12:
		return "ACE"
	
	for rank in ["COL", "MAJ", "CPT", "SGT", "CPL"]:
		if score >= RANK_THRESHOLDS[rank] \
		   and stages >= RANK_STAGES_REQUIRED[rank]:
			if rank in RANK_S_REQUIRED:
				if s_count >= RANK_S_REQUIRED[rank]:
					return rank
			else:
				return rank
	
	return "PVT"

func get_rank_name(rank_code: String) -> String:
	return RANK_NAMES.get(rank_code, "未知")

func get_rank_color(rank_code: String) -> Color:
	return RANK_COLORS.get(rank_code, Color.WHITE)

func get_rank_progress() -> float:
	var current_rank: String = get_current_rank()
	if current_rank == "ACE":
		return 1.0
	
	var current_index: int = RANK_ORDER.find(current_rank)
	if current_index < 0 or current_index >= RANK_ORDER.size() - 1:
		return 0.0
	
	var next_rank: String = RANK_ORDER[current_index + 1]
	if next_rank == "ACE":
		return 1.0
	
	var current_score: int = calculate_rank_score()
	var min_threshold: int = RANK_THRESHOLDS.get(current_rank, 0)
	var max_threshold: int = RANK_THRESHOLDS.get(next_rank, 0)
	
	if max_threshold <= min_threshold:
		return 0.0
	
	return float(current_score - min_threshold) / float(max_threshold - min_threshold)

func get_next_rank_info() -> Dictionary:
	var current_rank: String = get_current_rank()
	if current_rank == "ACE":
		return {
			"rank": "",
			"name": "已满级",
			"score_needed": 0,
			"stages_needed": 0,
			"s_needed": 0,
		}
	
	var current_index: int = RANK_ORDER.find(current_rank)
	if current_index < 0 or current_index >= RANK_ORDER.size() - 1:
		return {}
	
	var next_rank: String = RANK_ORDER[current_index + 1]
	var current_score: int = calculate_rank_score()
	var stages_cleared: int = SaveManager.highest_stage
	var s_count: int = SaveManager.get_s_rank_count()
	
	return {
		"rank": next_rank,
		"name": RANK_NAMES.get(next_rank, ""),
		"score_needed": maxi(RANK_THRESHOLDS.get(next_rank, 0) - current_score, 0),
		"stages_needed": maxi(RANK_STAGES_REQUIRED.get(next_rank, 0) - stages_cleared, 0),
		"s_needed": maxi(RANK_S_REQUIRED.get(next_rank, 0) - s_count, 0),
	}

func is_rank_reached(target_rank: String) -> bool:
	var current_rank: String = get_current_rank()
	var current_index: int = RANK_ORDER.find(current_rank)
	var target_index: int = RANK_ORDER.find(target_rank)
	return current_index >= target_index

func get_hidden_stage_required_rank(stage_id: String) -> String:
	return HIDDEN_STAGE_RANK_REQUIRED.get(stage_id, "PVT")

func can_unlock_hidden_stage(stage_id: String) -> bool:
	var required_rank: String = get_hidden_stage_required_rank(stage_id)
	return is_rank_reached(required_rank)