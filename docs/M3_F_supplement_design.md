# Flying Tigers 1945 — M3-F 补充功能设计：军衔系统 + 隐藏情报分布

> **版本**: v1.0  
> **日期**: 2026-07-11  
> **状态**: 设计文档，待 Code / Design 确认后实施  
> **关联文档**: `docs/M3_task_breakdown.md`（总体）、`docs/M3_event_system_design.md`（事件系统基础）、`docs/M3_design_assignment.md`（Design 素材规范）

---

## 1. 概述

M3 全部 5 个子里程碑已完成，游戏具备完整 16 关 + 深渊模式 + 存档/排行榜。本补充功能在 M3 基础上新增：

1. **飞行员军衔等级系统** — 基于累计表现的成长线，作为隐藏关的门槛条件
2. **隐藏情报分布** — 4 个隐藏关各对应 1 个情报，散布在主线关卡中
3. **双重解锁条件** — 隐藏关 = 情报已获取 AND 军衔达标
4. **随机隐藏关显示** — 已解锁的隐藏关在关卡选择界面随机展示

---

## 2. 飞行员军衔等级系统

### 2.1 军衔定义

| 军衔 | 英文缩写 | 解锁条件 | 对应隐藏关 | 颜色标识 |
|------|---------|---------|-----------|---------|
| 列兵 | PVT | 初始等级 | 无 | 灰色 |
| 下士 | CPL | 通关 ≥ 3 关 + rank_score ≥ 20 万 | 无 | 铜色 |
| 中士 | SGT | 通关 ≥ 6 关 + rank_score ≥ 80 万 | **H1 驼峰绝径** | 铜色+V |
| 上尉 | CPT | 通关 ≥ 8 关 + rank_score ≥ 200 万 + S 评级 ≥ 2 | **H2 轰炸东京** | 银色鹰徽 |
| 少校 | MAJ | 通关 ≥ 10 关 + rank_score ≥ 500 万 + S 评级 ≥ 4 | **H3 震电对决** | 金色橡叶 |
| 上校 | COL | 通关 = 12 关 + rank_score ≥ 1000 万 + S 评级 ≥ 6 | **H4 广岛之刻** | 银色鹰+星 |
| 王牌 | ACE | 全部 12 关 S 评级 | 纯荣誉 | 金色翼标+光环 |

### 2.2 rank_score 计算公式

```gdscript
# autoload/rank_manager.gd

const RANK_THRESHOLDS = {
    "CPL": 200000,     # 20 万
    "SGT": 800000,     # 80 万
    "CPT": 2000000,    # 200 万
    "MAJ": 5000000,    # 500 万
    "COL": 10000000,   # 1000 万
    "ACE": -1,         # 特殊条件（全 S）
}

const RANK_STAGES_REQUIRED = {
    "CPL": 3,
    "SGT": 6,
    "CPT": 8,
    "MAJ": 10,
    "COL": 12,
    "ACE": 12,
}

const RANK_S_REQUIRED = {
    "CPT": 2,
    "MAJ": 4,
    "COL": 6,
    "ACE": 12,
}

func calculate_rank_score() -> int:
    var stages_cleared: int = SaveManager.highest_stage
    var total_score: int = SaveManager.total_score
    var s_rank_count: int = SaveManager.get_s_rank_count()
    
    return (
        stages_cleared * 100000     # 通关数量：每关 10 万
        + int(total_score * 0.5)    # 累计总分：50% 折算
        + s_rank_count * 200000      # S 评级数量：每个 20 万
    )

func get_current_rank() -> String:
    var score: int = calculate_rank_score()
    var stages: int = SaveManager.highest_stage
    var s_count: int = SaveManager.get_s_rank_count()
    
    # ACE 特殊判定：全部 12 关 S 评级
    if s_count >= 12 and stages >= 12:
        return "ACE"
    
    # 从高到低逐级检查
    for rank in ["COL", "MAJ", "CPT", "SGT", "CPL"]:
        if score >= RANK_THRESHOLDS[rank] \
           and stages >= RANK_STAGES_REQUIRED[rank]:
            if rank in RANK_S_REQUIRED:
                if s_count >= RANK_S_REQUIRED[rank]:
                    return rank
            else:
                return rank
    
    return "PVT"
```

### 2.3 分数门槛合理性验证

当前单关评级：S = 100 万, A = 50 万, B = 20 万

| 玩家类型 | 单关均分 | 12 关总分 | S 数 | rank_score | 军衔 |
|---------|---------|---------|------|-----------|------|
| 新手（均 B） | 20 万 | 240 万 | 0 | 120+120+0 = 240 万 | 上尉 |
| 熟练（均 A） | 50 万 | 600 万 | 0 | 120+300+0 = 420 万 | 少校附近 |
| 精通（6S+6A） | 80 万 | 960 万 | 6 | 120+480+120 = 720 万 | 接近上校 |
| 全 S | 120 万 | 1440 万 | 12 | 120+720+240 = 1080 万 | **上校 → ACE** |

**关键节点**：
- 正常通关 6 关均 B：rank_score = 60+60+0 = **120 万 ≥ 80 万** → **中士**（H1 可进）
- 全 12 关 A 评级无 S：rank_score = 120+300+0 = 420 万 < 500 万 → **少校差一点**
- 12 关中 4 个 S 其余 A：rank_score = 120+300+80 = 500 万 → **少校**（H3 可进）
- 全 S：1080 万 ≥ 1000 万 + 12 个 S → **ACE**

### 2.4 Code 实现清单

| 序号 | 任务 | 文件 | 工作量 |
|------|------|------|--------|
| F-C1 | 新建 RankManager | `autoload/rank_manager.gd`（~120 行） | 中 |
| F-C2 | SaveManager 新增字段 | `s_rank_count: int`，save/load | 小 |
| F-C3 | UnlockManager 修改解锁逻辑 | 情报 AND 军衔双重判定 | 中 |
| F-C4 | ResultScreen 显示军衔 | 结算界面显示当前军衔 + 进度 | 小 |
| F-C5 | StageSelect 隐藏关显示逻辑 | 三种状态（未知/预告/解锁） | 中 |
| F-C6 | project.godot 注册 RankManager | autoload 追加 | 极小 |

### 2.5 Design 素材清单

| 素材 | 尺寸 | 说明 |
|------|------|------|
| `ui_rank_corporal.png` | 48x48 | 下士臂章（铜色条纹） |
| `ui_rank_sergeant.png` | 48x48 | 中士臂章（铜色 V 字） |
| `ui_rank_captain.png` | 48x48 | 上尉臂章（银色鹰徽） |
| `ui_rank_major.png` | 48x48 | 少校臂章（金色橡叶） |
| `ui_rank_colonel.png` | 48x48 | 上校臂章（银色鹰+星） |
| `ui_rank_ace.png` | 64x64 | 王牌臂章（金色翼标+发光） |
| `ui_rank_progress_bar_bg.png` | 200x16 | 进度条底板 |
| `ui_rank_progress_bar_fill.png` | 动态宽度 | 进度条填充（渐变） |

8 张素材，风格与已有 UI 按钮统一（深绿/金/银军旅风）。

---

## 3. 隐藏情报分布方案

### 3.1 情报总览

| 情报 | 解锁隐藏关 | 放置关卡 | 获取机制 | 事件类型 |
|------|-----------|---------|---------|---------|
| 驼峰路线图 | H1 驼峰绝径 | Stage 02 仰光 | 击杀高速逃逸的将官座车 | `kill_target`（已有） |
| 东京防空图 | H2 轰炸东京 | Stage 05 桂林 | 区域停留 3 秒发现密林碉堡 | `area_stay`（需新增） |
| 震电试飞数据 | H3 震电对决 | Stage 10 上海 | 击沉标记运输舰 + 触碰残骸打捞 | `kill_target` + 打捞 |
| 绝密军令 | H4 广岛之刻 | Stage 11 南京 | 护送 C-47 运输机存活 20 秒 | `escort_survive`（需新增） |

### 3.2 情报 1：将官座车（Stage 02 → H1）

**复用已有系统**，仅需配置事件 JSON：

```json
// resources/level_data/events_stage_02_rangoon.json
{
  "stage_id": "02_rangoon",
  "events": [{
    "event_id": "rangoon_general_car",
    "event_type": "kill_target",
    "trigger": {
      "timing": "on_time",
      "time": 35.0,
      "probability": 0.8
    },
    "target": {
      "enemy_type": "event_target_car",
      "spawn_x": 50,
      "spawn_y": -100,
      "speed": 180,
      "hp": 30,
      "escape_time": 12.0
    },
    "rewards": {
      "score": 5000,
      "drop_items": ["intel_hump_route"],
      "unlock_hidden": "H1_hump_extreme"
    },
    "ui": {
      "alert_text": "截获情报：敌军将领座驾正在撤离！",
      "complete_text": "获取驼峰路线情报！隐藏关卡已解锁（需军衔：中士）"
    }
  }]
}
```

**Code 工作量**：极小（仅 JSON 配置，event_target_car.tscn 已有）

### 3.3 情报 2：密林碉堡（Stage 05 → H2）

**需新增 `area_stay` 事件类型**：

```json
// resources/level_data/events_stage_05_guilin.json
{
  "stage_id": "05_guilin",
  "events": [{
    "event_id": "guilin_hidden_bunker",
    "event_type": "area_stay",
    "trigger": {
      "timing": "on_time",
      "time": 25.0,
      "probability": 1.0
    },
    "target": {
      "enemy_type": "event_target_bunker",
      "area_x": 380,
      "area_y": 600,
      "area_radius": 500,
      "stay_duration": 3.0,
      "hp": 20,
      "escape_timer": 5.0
    },
    "rewards": {
      "score": 8000,
      "drop_items": ["intel_tokyo_defense"],
      "unlock_hidden": "H2_tokyo_bombing"
    },
    "ui": {
      "alert_text": "探测到隐藏信号...",
      "complete_text": "获取东京防空部署情报！隐藏关卡已解锁（需军衔：上尉）"
    }
  }]
}
```

**Code 工作量**：中（EventManager 新增 area_stay 逻辑 ~50 行 + event_target_bunker.tscn）

### 3.4 情报 3：沉船密码箱（Stage 10 → H3）

**复用 kill_target + 新增打捞交互**：

```json
// resources/level_data/events_stage_10_shanghai.json
{
  "stage_id": "10_shanghai",
  "events": [{
    "event_id": "shanghai_secret_ship",
    "event_type": "kill_and_loot",
    "trigger": {
      "timing": "on_enemy_wave",
      "wave_index": 12,
      "probability": 1.0
    },
    "target": {
      "enemy_type": "event_transport_ship",
      "spawn_x": 300,
      "spawn_y": -150,
      "speed": 60,
      "hp": 80,
      "loot_item": "intel_shinden_data",
      "loot_duration": 2.0
    },
    "rewards": {
      "score": 10000,
      "drop_items": ["intel_shinden_data"],
      "unlock_hidden": "H3_shinden_duel"
    },
    "ui": {
      "alert_text": "发现标记运输舰！击沉后打捞密码箱！",
      "complete_text": "获取震电试飞数据！隐藏关卡已解锁（需军衔：少校）"
    }
  }]
}
```

**Code 工作量**：中（新增 kill_and_loot 类型 ~30 行 + event_transport_ship.tscn）

### 3.5 情报 4：绝密军令（Stage 11 → H4）

**需新增 `escort_survive` 事件类型 + 友军 AI**：

```json
// resources/level_data/events_stage_11_nanjing.json
{
  "stage_id": "11_nanjing",
  "events": [{
    "event_id": "nanjing_escort_c47",
    "event_type": "escort_survive",
    "trigger": {
      "timing": "on_time",
      "time": 40.0,
      "probability": 1.0
    },
    "target": {
      "ally_type": "event_c47_transport",
      "spawn_x": 300,
      "spawn_y": 800,
      "speed": 40,
      "hp": 50,
      "survive_duration": 20.0
    },
    "rewards": {
      "score": 15000,
      "unlock_hidden": "H4_hiroshima_countdown"
    },
    "ui": {
      "alert_text": "友军运输机携带绝密军令！护送其安全撤离！",
      "complete_text": "军令送达！最高机密已解锁（需军衔：上校）"
    }
  }]
}
```

**Code 工作量**：高（escort_survive ~80 行 + 友军 AI + 敌机仇恨值优先攻击机制）

### 3.6 隐藏关随机显示机制

```gdscript
# autoload/unlock_manager.gd 新增

## 每次进入关卡选择时，从已解锁隐藏关中随机选 1 个显示
func get_random_hidden_stage_for_display() -> String:
    var unlocked: Array[String] = []
    for stage_id in HIDDEN_STAGES:
        if is_hidden_stage_unlocked(stage_id) and has_intel(stage_id):
            unlocked.append(stage_id)
    if unlocked.is_empty():
        return ""
    unlocked.shuffle()
    return unlocked[0]
```

关卡选择界面逻辑：
- **未获取情报 + 军衔不够** → 显示锁图标 + "???"
- **已获取情报 + 军衔不够** → 显示缩略图 + "军衔不足：需要 [上尉]"
- **已获取情报 + 军衔达标** → 随机决定是否显示（50% 概率显示，每次进入关卡选择重新随机）

---

## 4. 新增事件类型汇总

| 类型 | 方法名 | 说明 | Code 量 |
|------|--------|------|--------|
| `area_stay` | `_process_area_stay()` | 每帧检测玩家与目标区域距离，累计停留时间 | ~50 行 |
| `kill_and_loot` | `_on_target_killed_loot()` | 击杀目标后生成可触碰残骸，玩家触碰拾取 | ~30 行 |
| `escort_survive` | `_process_escort()` | 管理友军 AI + 敌机仇恨值 + 存活倒计时 | ~80 行 |

---

## 5. Design 素材完整清单

### 5.1 情报相关

| 素材 | 尺寸 | 用途 |
|------|------|------|
| `event_bunker_hidden.png` | 128x128 | 碉堡伪装状态（植被覆盖） |
| `event_bunker_revealed.png` | 128x128 | 碉堡暴露状态（混凝土） |
| `event_transport_ship.png` | 128x128 | 标记运输舰（带红色标记） |
| `event_transport_wreck.png` | 128x128 | 运输舰残骸（漂浮可触碰） |
| `event_c47_transport.png` | 128x128 | 友军 C-47（美军涂装） |
| `intel_hump_route.png` | 48x48 | 驼峰路线情报 |
| `intel_tokyo_defense.png` | 48x48 | 东京防空情报 |
| `intel_shinden_data.png` | 48x48 | 震电数据情报 |

### 5.2 军衔相关

| 素材 | 尺寸 | 用途 |
|------|------|------|
| `ui_rank_corporal.png` | 48x48 | 下士臂章 |
| `ui_rank_sergeant.png` | 48x48 | 中士臂章 |
| `ui_rank_captain.png` | 48x48 | 上尉臂章 |
| `ui_rank_major.png` | 48x48 | 少校臂章 |
| `ui_rank_colonel.png` | 48x48 | 上校臂章 |
| `ui_rank_ace.png` | 64x64 | 王牌臂章（发光） |
| `ui_rank_progress_bar_bg.png` | 200x16 | 进度条底板 |
| `ui_rank_progress_bar_fill.png` | 动态 | 进度条填充 |

### 5.3 UI 提示

| 素材 | 尺寸 | 用途 |
|------|------|------|
| `ui_discovery_alert.png` | 400x80 | "发现隐藏信号"提示条 |
| `ui_escort_alert.png` | 400x80 | "护送友军"提示条 |
| `ui_rank_up.png` | 400x80 | 军衔晋升提示条 |

**总计: 19 张新增素材**

---

## 6. 隐藏关完整解锁矩阵

| 隐藏关 | 情报来源 | 情报机制 | 军衔要求 | 通关数 | rank_score | S 评级数 |
|--------|---------|---------|---------|--------|-----------|---------|
| H1 驼峰绝径 | Stage 02 仰光 | 击杀将官座车 | 中士 | ≥ 6 | ≥ 80 万 | — |
| H2 轰炸东京 | Stage 05 桂林 | 发现密林碉堡 | 上尉 | ≥ 8 | ≥ 200 万 | ≥ 2 |
| H3 震电对决 | Stage 10 上海 | 击沉运输舰+打捞 | 少校 | ≥ 10 | ≥ 500 万 | ≥ 4 |
| H4 广岛之刻 | Stage 11 南京 | 护送 C-47 存活 | 上校 | = 12 | ≥ 1000 万 | ≥ 6 |

---

## 7. 实施优先级

| 优先级 | 内容 | 阶段 | Code 量 | Design 量 |
|--------|------|------|--------|----------|
| P0 | 军衔系统 RankManager + SaveManager 扩展 | 先行 | ~150 行 | 8 张臂章 |
| P0 | 情报 1（仰光将官座车）— 仅 JSON 配置 | 先行 | ~30 行 | 0（已有） |
| P1 | 情报 2（桂林密林碉堡）— area_stay + 碉堡 | 第二批 | ~80 行 | 2 张碉堡 |
| P1 | UnlockManager 双重解锁逻辑 | 第二批 | ~60 行 | 0 |
| P2 | 情报 3（上海沉船密码箱）— kill_and_loot | 第三批 | ~60 行 | 3 张 |
| P2 | 随机隐藏关显示 | 第三批 | ~30 行 | 0 |
| P3 | 情报 4（南京绝密军令）— escort_survive | 第四批 | ~100 行 | 2 张 |
| P3 | 结算界面军衔显示 | 第四批 | ~40 行 | 2 张 UI |

**总 Code 量**: ~550 行新代码
**总 Design 量**: 19 张新素材

---

**本文档作为 M3 补充功能设计文档，Code 和 Design Agent 确认后按优先级分批实施。**
