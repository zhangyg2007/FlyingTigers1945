# Flying Tigers 1945 — 隐藏事件与随机事件系统基础设计

> **版本**: v1.0  
> **日期**: 2026-07-10  
> **状态**: 基础设计文档，待 M3-B 阶段启动实现  
> **关联文档**: `docs/M3_task_breakdown.md`, `docs/design-spec/design-spec.html`

---

## 1. 背景与需求

用户提出关卡中需加入条件触发的隐藏要素，例如：
- **Stage 01 昆明**: 逃跑的高级将军汽车，击毁后掉落高级情报，用于开启隐藏关卡
- **Stage 03 怒江**: 轰炸 4~5 个渡桥，全部摧毁后给出额外奖励
- 以及其他类似的随机事件和隐藏目标

Code 部门反馈：当前关卡敌人生成基于纯时间驱动的 CSV 文件，隐藏要素无法通过 CSV 表达，需要新增一套**事件系统**，与 CSV 解耦。

本文档定义事件系统的数据格式、触发机制、与现有系统的接口，供 Code 部门在 M3-B/C 阶段实现，Design 部门提前准备素材。

---

## 2. 设计原则

1. **与 CSV 解耦**: 事件不写在 `stage_XX.csv` 中，避免 CSV 格式复杂化
2. **数据驱动**: 事件配置使用独立的 `hidden_events.json`，便于关卡设计师调整
3. **非阻塞**: 事件完成与否不影响关卡正常通关，仅影响奖励和解锁
4. **可扩展**: 新事件类型只需添加配置，无需修改核心代码
5. **向后兼容**: 无事件配置的关卡正常运行，不受任何影响

---

## 3. 事件类型定义

### 3.1 事件类型枚举

| 类型 ID | 名称 | 说明 | 示例 |
|---------|------|------|------|
| `kill_target` | 击杀指定目标 | 场景中出现的特殊敌机/载具 | 将军汽车 |
| `destroy_targets` | 摧毁多个目标 | 需要摧毁 N 个指定物体 | 怒江渡桥 x5 |
| `survive_time` | 生存计时 | 在指定区域内生存 N 秒 | 防空火力网中坚持 30 秒 |
| `collect_items` | 收集道具 | 收集场景中散落的 N 个道具 | 情报碎片 x3 |
| `score_reach` | 分数达标 | 在关卡中达到指定分数 | 本关达到 50000 分 |
| `no_miss` | 无伤通过段 | 在指定时间段内不受击 | 穿越峡谷段无伤 |

### 3.2 事件触发时机

| 时机 ID | 说明 |
|---------|------|
| `on_stage_start` | 关卡开始时触发（如收集类事件） |
| `on_time` | 到达指定时间点触发（如将军汽车在 30 秒时出现） |
| `on_enemy_wave` | 某一波敌人出现时伴随触发 |
| `on_boss_appear` | BOSS 出现时触发（如 BOSS 携带额外目标） |
| `on_area_enter` | 玩家进入指定区域时触发（如峡谷段） |

---

## 4. 数据格式设计

### 4.1 单关卡事件配置

每个关卡拥有一个独立的 JSON 文件：`resources/level_data/events_stage_01_kunming.json`

```json
{
  "stage_id": "01_kunming",
  "events": [
    {
      "event_id": "kunming_general_car",
      "event_type": "kill_target",
      "trigger": {
        "timing": "on_time",
        "time": 45.0,
        "probability": 0.7
      },
      "target": {
        "enemy_type": "event_target_car",
        "spawn_x": 300,
        "spawn_y": -100,
        "speed": 180,
        "hp": 50,
        "escape_time": 15.0
      },
      "rewards": {
        "score": 5000,
        "drop_items": ["event_intel_case"],
        "unlock_hidden": "H1_hump_extreme"
      },
      "ui": {
        "alert_text": "发现敌军将领座驾！",
        "complete_text": "情报获取成功！隐藏关卡已解锁"
      }
    }
  ]
}
```

### 4.2 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `event_id` | string | 是 | 唯一标识符，snake_case |
| `event_type` | string | 是 | 见 3.1 事件类型枚举 |
| `trigger.timing` | string | 是 | 见 3.2 触发时机 |
| `trigger.time` | float | 条件 | `on_time` 时必须，关卡开始后的秒数 |
| `trigger.probability` | float | 否 | 触发概率 0.0~1.0，默认 1.0（必定触发） |
| `target.enemy_type` | string | 条件 | `kill_target` 时必须，对应 SpawnManager 注册名 |
| `target.spawn_x/y` | float | 条件 | 生成位置（像素坐标） |
| `target.speed` | float | 否 | 目标移动速度 |
| `target.hp` | int | 否 | 目标生命值 |
| `target.escape_time` | float | 否 | 逃脱倒计时，超时则事件失败 |
| `target.count` | int | 条件 | `destroy_targets` 时必须，需摧毁数量 |
| `target.targets` | array | 条件 | `destroy_targets` 时必须，每个目标的坐标和 ID |
| `rewards.score` | int | 否 | 完成奖励分数 |
| `rewards.drop_items` | array | 否 | 掉落物类型列表 |
| `rewards.unlock_hidden` | string | 否 | 解锁的隐藏关卡 ID |
| `ui.alert_text` | string | 否 | 事件触发时显示的提示文字 |
| `ui.complete_text` | string | 否 | 事件完成时显示的提示文字 |

### 4.3 多目标摧毁示例（怒江渡桥）

```json
{
  "stage_id": "03_salween",
  "events": [
    {
      "event_id": "salween_destroy_bridges",
      "event_type": "destroy_targets",
      "trigger": {
        "timing": "on_stage_start",
        "probability": 1.0
      },
      "target": {
        "count": 5,
        "targets": [
          {"id": "bridge_1", "x": 150, "y": 400, "hp": 30},
          {"id": "bridge_2", "x": 250, "y": 600, "hp": 30},
          {"id": "bridge_3", "x": 350, "y": 800, "hp": 30},
          {"id": "bridge_4", "x": 200, "y": 1000, "hp": 30},
          {"id": "bridge_5", "x": 300, "y": 1200, "hp": 30}
        ]
      },
      "rewards": {
        "score": 10000,
        "drop_items": ["powerup_b", "powerup_p"]
      },
      "ui": {
        "alert_text": "任务：摧毁所有渡桥！",
        "complete_text": "渡桥全部摧毁！获得额外奖励"
      }
    }
  ]
}
```

---

## 5. 与现有系统的接口设计

### 5.1 SpawnManager 扩展

当前 `spawn_manager.gd` 的敌人类型映射需增加事件目标注册：

```gdscript
# 在 _ready() 或配置加载时注册事件目标
var event_enemy_types = {
    "event_target_car": "res://scenes/enemies/event_target_car.tscn",
    "event_target_bridge": "res://scenes/events/event_target_bridge.tscn",
    # ... 其他事件目标
}
```

**兼容性**: 事件目标使用与普通敌机相同的 `EnemyBase` 基类（或继承），因此 `spawn_enemy()` 方法无需修改，只需在映射表中注册新类型。

### 5.2 LevelBase 扩展

`level_base.gd` 在 `_ready()` 中加载对应关卡的 `events_stage_XX.json`：

```gdscript
@onready var event_manager: EventManager = $EventManager

func _ready():
    # ... 现有初始化代码
    event_manager.load_events(level_id)
```

新增 `EventManager` 节点（`scripts/event_manager.gd`），职责：
- 读取 JSON 配置
- 按触发时机监听关卡事件
- 管理事件状态（未触发 / 进行中 / 已完成 / 失败）
- 通知 UI 显示提示
- 发放奖励

### 5.3 GameManager 扩展

`GameManager` 新增信号和状态：

```gdscript
# 新增信号
signal event_triggered(event_id: String, event_type: String)
signal event_completed(event_id: String, rewards: Dictionary)
signal event_failed(event_id: String)

# 新增方法
func unlock_hidden_stage(stage_id: String) -> void
func is_stage_unlocked(stage_id: String) -> bool
```

### 5.4 SaveManager 扩展

存档中需记录事件相关数据：

```ini
[event_progress]
 kunming_general_car=true
 salween_destroy_bridges=false

[unlocked_stages]
 H1_hump_extreme=true
```

---

## 6. 事件目标场景设计

### 6.1 事件目标基类

```gdscript
# scripts/event_target_base.gd
class_name EventTargetBase
extends EnemyBase

@export var event_id: String = ""
@export var escape_timer: float = 0.0  # 0 = 不逃脱

var _escaped: bool = false

func _process(delta: float) -> void:
    if escape_timer > 0:
        escape_timer -= delta
        if escape_timer <= 0:
            _on_escape()

func _on_escape() -> void:
    _escaped = true
    EventManager.report_event_failed(event_id)
    _destroy()

func _on_destroyed() -> void:
    if not _escaped:
        EventManager.report_event_completed(event_id)
    super._on_destroyed()
```

### 6.2 特殊事件目标：可摧毁物体

渡桥等静态目标不继承 `EnemyBase`，而是独立的 `DestructibleObject`：

```gdscript
# scripts/destructible_object.gd
class_name DestructibleObject
extends StaticBody2D

@export var object_id: String = ""
@export var max_hp: int = 30
@export var broken_texture: Texture2D

var _current_hp: int
var _is_destroyed: bool = false

func _ready() -> void:
    _current_hp = max_hp
    # 连接受击信号

func take_damage(damage: int) -> void:
    if _is_destroyed: return
    _current_hp -= damage
    if _current_hp <= 0:
        _destroy()

func _destroy() -> void:
    _is_destroyed = true
    $Sprite2D.texture = broken_texture
    EventManager.report_target_destroyed(object_id)
    # 播放破坏特效
```

---

## 7. UI 提示流程

```
事件触发
  → EventManager 发射 signal "event_triggered"
  → HUD 接收信号，显示 ui_event_alert.png + alert_text（持续 3 秒）
  → 玩家进行游戏，尝试完成事件
      ├─ 成功 → EventManager 发射 "event_completed"
      │         → HUD 显示 ui_event_complete.png + complete_text
      │         → 播放奖励动画（分数 + 掉落物）
      │         → 如 unlock_hidden 不为空，显示解锁提示
      │
      └─ 失败 → EventManager 发射 "event_failed"
                → HUD 显示失败提示（可选，低调处理）
```

---

## 8. 实现优先级

| 优先级 | 内容 | 建议阶段 |
|--------|------|---------|
| P0 | `EventManager` 基类 + `kill_target` 类型 | M3-B |
| P0 | `event_target_car` 场景 + 素材 | M3-B |
| P1 | `destroy_targets` 类型 + `DestructibleObject` | M3-C |
| P1 | `event_target_bridge` 场景 + 素材 | M3-C |
| P2 | 其他事件类型（survive_time, collect_items 等） | M3-D |
| P2 | 概率触发 + 多周目差异化 | M3-D |

---

## 9. Design 部门素材清单（事件相关）

详见 `docs/M3_design_assignment.md` 第 7 节"隐藏事件/随机事件相关设计素材"。

核心素材：
- `event_target_car.png` / `event_target_car_burning.png`
- `event_target_bridge.png` / `event_target_bridge_broken.png`
- `event_intel_case.png`
- `ui_event_alert.png` / `ui_event_complete.png` / `ui_bonus_popup.png`

---

## 10. 向后扩展：随机事件

未来可基于同一系统实现**随机事件**（非隐藏关卡解锁，而是纯奖励）：

```json
{
  "event_id": "random_supply_drop",
  "event_type": "collect_items",
  "trigger": {
    "timing": "on_time",
    "time": 60.0,
    "probability": 0.3
  },
  "target": {
    "count": 3,
    "items": ["powerup_p", "powerup_b", "powerup_coin"]
  },
  "rewards": {
    "score": 2000
  }
}
```

随机事件与隐藏事件使用同一套系统，区别仅在于：
- 隐藏事件有 `unlock_hidden` 字段
- 随机事件 `probability` 通常 < 1.0

---

**本文档为 Code 部门在 M3-B 阶段实现事件系统的设计参考。实现完成后，需在 `Devlog.md` 中记录 EventManager 的 API 接口，供 Design 部门了解事件触发时机。**
