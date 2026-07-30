# Flying Tigers 1945 — M3-G 地图设计方案：经典STG风格单图层地图 + 交互对象系统

> **版本**: v1.0  
> **日期**: 2026-07-13  
> **状态**: 设计文档，待 Code / Design 确认后实施  
> **关联文档**: `docs/M3_task_breakdown.md`（总体）、`docs/M3_event_system_design.md`（事件系统基础）、`docs/design_art_style_guide.md`（美术风格规范）

---

## 1. 概述

本方案针对用户反馈，重新设计关卡地图系统，使其完全符合《Strikers 1945》《iFighter 2》等经典STG的设计风格：

- **单图层长条地图**：替代原有的近景/远景分层设计
- **纯俯视视角**：无天空、无侧面建筑，所有物体均为俯视图
- **地面对象系统**：支持可交互敌人（坦克、碉堡）和不可交互物体（平民车辆）
- **隐藏要素**：补给点、秘密通道、友军支援等

---

## 2. 经典STG地图设计分析

### 2.1 《Strikers 1945》地图特点

通过对《Strikers 1945》系列游戏的深入分析，其地图设计具有以下核心特征：

| 特征 | 具体表现 |
|------|---------|
| **视角** | 纯90°垂直俯视，零透视变形 |
| **背景** | 单一地面/海面地图，无天空、无地平线 |
| **物体呈现** | 所有建筑、车辆、碉堡均为俯视图，无侧面 |
| **地图类型** | 陆地（土黄/棕褐/灰绿）、海洋（深蓝绿）、混合（海陆交界） |
| **交互对象** | 地面目标（坦克、碉堡、高射炮）可被击毁，提供额外分数 |
| **地图尺寸** | 单张长条地图，长度对应关卡时长（约60~120秒） |

### 2.2 《iFighter 2》地图特点

《iFighter 2：太平洋战争》作为移动端经典STG，其地图设计更注重细节：

| 特征 | 具体表现 |
|------|---------|
| **地面对象** | 移动的坦克、固定的碉堡、车队、防空炮等 |
| **不可交互对象** | 平民汽车、动物、漂浮物等，仅作为视觉元素 |
| **地形变化** | 山丘、河流、道路、海岸线等自然地形 |
| **地图长度** | 较长（2分钟以上关卡），通过长条图片实现 |

### 2.3 经典STG地图设计总结

```
经典STG地图架构：
┌─────────────────────────────────────────────────────────────────┐
│                         游戏屏幕                                 │
├─────────────────────────────────────────────────────────────────┤
│  背景层（单一长条地图，向下滚动）                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  地面纹理 + 地形轮廓 + 固定物体（碉堡、桥梁等）                ││
│  │  尺寸：宽度固定 × 长度 = scroll_speed × duration             ││
│  └─────────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────┤
│  交互层（动态生成的游戏对象）                                      │
│  ├── 可交互敌人：坦克、碉堡、车队、防空炮                          │
│  ├── 不可交互对象：平民汽车、动物、漂浮物                          │
│  └── 隐藏要素：补给点、秘密通道、友军支援                          │
├─────────────────────────────────────────────────────────────────┤
│  游戏层（飞机、子弹、特效）                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 设计修改意见：从近景/远景分层到单图层

### 3.1 原有设计分析

原设计采用4层视差背景（far/mid/near/ground），旨在营造视觉深度感，但存在以下问题：

| 问题 | 具体表现 |
|------|---------|
| **不符合经典STG风格** | 《Strikers 1945》《iFighter 2》均采用单图层地图 |
| **制作复杂度高** | 需要制作4张不同速度的背景图，增加Design工作量 |
| **内存占用大** | 4张512×2048的图片占用约160MB内存 |
| **艺术风格不一致** | 多层拼接容易出现接缝和风格差异 |
| **交互对象难以定位** | 对象需要在4层中选择合适的层级，增加代码复杂度 |

### 3.2 修改方案

**将4层视差背景改为1层单长条地图**：

| 修改项 | 原设计 | 新设计 |
|--------|--------|--------|
| 背景图层数 | 4层（far/mid/near/ground） | 1层（完整长条地图） |
| 滚动方式 | 视差滚动（每层不同速度） | 匀速滚动 |
| 视觉效果 | 多层深度感 | 简洁统一的地面视图 |
| 制作工作量 | 4张背景图 | 1张背景图 |
| 内存占用 | ~160MB | ~40MB |

### 3.3 修改原因

1. **经典STG设计标准**：《Strikers 1945》《iFighter 2》《1942》等经典STG均采用单图层地图，这是该类型游戏的标准设计模式
2. **艺术风格统一**：单图层地图更容易保持整体风格一致，避免多层拼接带来的视觉断裂
3. **开发效率提升**：减少Design部门的背景制作工作量，集中精力于交互对象设计
4. **性能优化**：减少内存占用和渲染开销
5. **交互对象简化**：所有地面对象都在同一层级，便于定位和管理

### 3.4 经典STG的视差处理方式

虽然经典STG采用单图层地图，但部分游戏会通过其他方式营造深度感：

| 游戏 | 深度感实现方式 |
|------|--------------|
| Strikers 1945 | 地面纹理渐变（近深远浅） |
| iFighter 2 | 地形元素大小变化（近大远小） |
| 1942 | 颜色饱和度变化（近饱和远暗淡） |

**结论**：深度感可以通过地面纹理本身的渐变实现，无需多层视差。

---

## 4. 地图数据结构设计

### 4.1 地图配置文件格式

```json
{
  "stage_id": "stage_01_kunming",
  "stage_name": "昆明首战",
  "duration": 120,
  "scroll_speed": 80,
  
  "map": {
    "width": 512,
    "height": 9600,
    "background_image": "bg_kunming_full.png",
    
    "objects": [
      {
        "id": "obj_001",
        "type": "enemy_tank",
        "name": "97式坦克",
        "position": {"x": 128, "y": 1024},
        "properties": {
          "hp": 10,
          "score": 200,
          "shoot_interval": 2.0
        }
      },
      {
        "id": "obj_002",
        "type": "bunker",
        "name": "日军碉堡",
        "position": {"x": 384, "y": 1536},
        "properties": {
          "hp": 20,
          "score": 500,
          "is_hidden": true
        }
      },
      {
        "id": "obj_003",
        "type": "convoy",
        "name": "补给车队",
        "position": {"x": 256, "y": 2048},
        "properties": {
          "count": 3,
          "speed": 30,
          "direction": "right",
          "protect_reward": "powerup_b"
        }
      },
      {
        "id": "obj_004",
        "type": "civilian_car",
        "name": "平民车辆",
        "position": {"x": 100, "y": 2560},
        "properties": {
          "speed": 20,
          "direction": "left",
          "is_interactive": false
        }
      }
    ],
    
    "hidden_elements": [
      {
        "id": "hidden_001",
        "type": "supply_drop",
        "position": {"x": 256, "y": 3072},
        "trigger": "shoot_area",
        "reward": {"type": "powerup_p", "count": 1}
      }
    ],
    
    "boss_zone": {
      "start_y": 8000,
      "end_y": 9600,
      "boss_type": "boss_bomber"
    }
  }
}
```

### 4.2 对象类型定义

| 对象类型 | 交互性 | 行为描述 | 生成方式 |
|---------|-------|---------|---------|
| `enemy_tank` | 可攻击 | 向下移动，周期性射击 | 地图配置 |
| `bunker` | 可攻击 | 固定位置，持续射击 | 地图配置 |
| `convoy` | 保护目标 | 横向移动，被击毁则失败 | 地图配置 |
| `civilian_car` | 不可攻击 | 横向移动，仅视觉效果 | 地图配置 |
| `supply_drop` | 触发 | 隐藏，射击触发后掉落道具 | 地图配置 |
| `anti_air_gun` | 可攻击 | 固定位置，高射速射击 | 地图配置 |

### 4.3 地图尺寸计算

| 关卡时长 | 滚动速度 | 地图高度 | 备注 |
|---------|---------|---------|------|
| 60秒 | 80px/s | 4800px | 简单关卡 |
| 90秒 | 80px/s | 7200px | 标准关卡 |
| 120秒 | 80px/s | 9600px | 长关卡 |
| 150秒 | 80px/s | 12000px | 隐藏关卡 |

---

## 5. 交互对象系统设计

### 5.1 对象基类设计

```gdscript
# scenes/map_objects/map_object.gd
class_name MapObject
extends Node2D

@export var object_id: String = ""
@export var object_type: String = ""
@export var is_interactive: bool = true
@export var score_value: int = 100

var _hp: int = 1
var _max_hp: int = 1
var _is_alive: bool = true

func setup(data: Dictionary) -> void:
    object_id = data.get("id", "")
    object_type = data.get("type", "")
    position = Vector2(data["position"]["x"], data["position"]["y"])
    
    var props = data.get("properties", {})
    _hp = props.get("hp", 1)
    _max_hp = _hp
    score_value = props.get("score", 100)
    is_interactive = props.get("is_interactive", true)

func take_damage(damage: int) -> void:
    if not _is_alive or not is_interactive:
        return
    
    _hp -= damage
    _on_damaged()
    
    if _hp <= 0:
        _is_alive = false
        _on_destroyed()

func _on_damaged() -> void:
    pass

func _on_destroyed() -> void:
    queue_free()
```

### 5.2 派生对象类型

```
MapObject
├── EnemyTank（坦克）
│   ├── 移动：向下移动，可左右闪避
│   ├── 攻击：周期性发射炮弹
│   └── 特效：被击毁时爆炸
│
├── Bunker（碉堡）
│   ├── 移动：固定位置
│   ├── 攻击：持续射击，扇形弹幕
│   └── 状态：可隐藏（射击后暴露）
│
├── Convoy（车队）
│   ├── 移动：横向移动
│   ├── 攻击：无（保护目标）
│   └── 奖励：保护成功获得道具
│
├── CivilianCar（平民车辆）
│   ├── 移动：横向移动
│   ├── 攻击：无
│   └── 特性：不可攻击，仅视觉效果
│
└── AntiAirGun（防空炮）
    ├── 移动：固定位置
    ├── 攻击：高射速，追踪射击
    └── 特性：优先攻击玩家
```

### 5.3 对象管理器

```gdscript
# autoload/map_object_manager.gd
class_name MapObjectManager
extends Node

var _objects: Array[MapObject] = []
var _objects_to_spawn: Array[Dictionary] = []
var _scroll_speed: float = 80.0

func load_objects(map_data: Dictionary) -> void:
    _objects_to_spawn = map_data.get("objects", [])

func update(delta: float, current_scroll_y: float) -> void:
    var spawn_threshold: float = current_scroll_y + 200
    
    var remaining_objects: Array[Dictionary] = []
    for obj_data in _objects_to_spawn:
        if obj_data["position"]["y"] <= spawn_threshold:
            _spawn_object(obj_data)
        else:
            remaining_objects.append(obj_data)
    
    _objects_to_spawn = remaining_objects

func _spawn_object(obj_data: Dictionary) -> void:
    var scene_path: String = _get_scene_path(obj_data["type"])
    var scene: PackedScene = load(scene_path)
    
    if scene == null:
        push_warning("无法加载对象场景: %s" % scene_path)
        return
    
    var obj: MapObject = scene.instantiate()
    obj.setup(obj_data)
    add_child(obj)
    _objects.append(obj)

func _get_scene_path(type_name: String) -> String:
    match type_name:
        "enemy_tank":
            return "res://scenes/map_objects/enemy_tank.tscn"
        "bunker":
            return "res://scenes/map_objects/bunker.tscn"
        "convoy":
            return "res://scenes/map_objects/convoy.tscn"
        "civilian_car":
            return "res://scenes/map_objects/civilian_car.tscn"
        "anti_air_gun":
            return "res://scenes/map_objects/anti_air_gun.tscn"
        _:
            return "res://scenes/map_objects/default_object.tscn"
```

---

## 6. 隐藏要素系统

### 6.1 隐藏要素类型

| 类型 | 触发方式 | 奖励 |
|------|---------|------|
| `supply_drop` | 射击特定区域 | 道具（Power/Bomb/Life） |
| `secret_passage` | 穿过特定位置 | 额外分数或隐藏关卡 |
| `ally_support` | 保护友军单位 | 友军协助攻击 |
| `bonus_area` | 在限定时间内通过 | 额外分数 |

### 6.2 隐藏要素触发机制

```gdscript
# scenes/map_objects/hidden_element.gd
class_name HiddenElement
extends Node2D

enum State {
    HIDDEN,
    REVEALED,
    CLAIMED
}

@export var element_type: String = ""
@export var trigger_area: Rect2 = Rect2.ZERO

var _state: State = State.HIDDEN
var _reward: Dictionary = {}

func setup(data: Dictionary) -> void:
    element_type = data.get("type", "")
    var pos = data["position"]
    trigger_area = Rect2(pos["x"] - 50, pos["y"] - 50, 100, 100)
    _reward = data.get("reward", {})

func check_trigger(player_pos: Vector2, bullets: Array) -> void:
    if _state == State.CLAIMED:
        return
    
    match element_type:
        "shoot_area":
            for bullet in bullets:
                if trigger_area.has_point(bullet.global_position):
                    _reveal()
                    _give_reward()
                    break
        
        "pass_through":
            if trigger_area.has_point(player_pos):
                _reveal()
                _give_reward()
```

---

## 7. 地图制作工作流

### 7.1 地图制作工具链

```
1. 概念设计（Photoshop/Procreate）
   └── 绘制关卡地形草图

2. 素材制作（Photoshop/GIMP）
   ├── 地面纹理模板（512×512，可平铺）
   ├── 地形元素（山丘、河流、道路）
   └── 固定物体（碉堡、桥梁、建筑）

3. 地图拼接（自定义工具/脚本）
   ├── 纵向拼接多个地面纹理
   ├── 添加地形变化节点
   └── 导出完整长条地图

4. 对象配置（JSON/Excel）
   ├── 定义对象位置和属性
   ├── 设置触发条件
   └── 配置奖励系统

5. 测试验证（Godot编辑器）
   ├── 运行关卡测试场景
   ├── 验证对象生成和交互
   └── 调整难度平衡
```

### 7.2 地形变化节点规划

```
关卡时间轴示例（120秒）：

0~20秒：入口区域
  ├── 平坦地形，少量树木
  └── 难度：低

20~50秒：核心战斗区域
  ├── 河流/山丘地形变化
  ├── 碉堡群、坦克编队
  └── 难度：中

50~80秒：高潮区域
  ├── 密集敌机 + 地面防空
  ├── 补给车队（隐藏要素）
  └── 难度：高

80~100秒：BOSS准备区域
  ├── 地形开阔，预示BOSS战
  └── 难度：中

100~120秒：BOSS战
  ├── BOSS专属地形背景
  └── 难度：极高
```

---

## 8. 实施步骤

### 8.1 第一步：地图素材制作

- 创建地面纹理模板（512×512，可平铺）
- 制作地形元素（山丘、河流、道路）
- 绘制固定物体（碉堡、桥梁、建筑）
- 导出完整长条地图（512×9600）

### 8.2 第二步：对象场景创建

- 创建 `MapObject` 基类脚本
- 创建各类对象场景（坦克、碉堡、车队等）
- 实现各自的行为逻辑和攻击模式

### 8.3 第三步：对象管理器实现

- 实现 `MapObjectManager` 脚本
- 集成到关卡基类 `LevelBase`
- 实现基于地图数据的对象生成

### 8.4 第四步：隐藏要素系统

- 实现 `HiddenElement` 脚本
- 创建隐藏要素场景
- 集成到事件管理器

### 8.5 第五步：测试与优化

- 创建测试关卡验证系统
- 调整对象难度和平衡
- 优化性能和内存使用

---

## 9. 文件结构规划

```
assets/
└── sprites/
    └── backgrounds/
        └── stage_01_kunming/
            └── bg_kunming_full.png  # 完整长条地图

resources/
└── level_data/
    └── stage_01_kunming_map.json    # 地图对象配置

scenes/
└── map_objects/
    ├── map_object.gd                # 对象基类
    ├── enemy_tank.tscn
    ├── bunker.tscn
    ├── convoy.tscn
    ├── civilian_car.tscn
    ├── anti_air_gun.tscn
    └── hidden_element.tscn

autoload/
└── map_object_manager.gd            # 对象管理器
```

---

## 10. 性能优化建议

1. **对象池化**：使用 `PoolManager` 复用对象，减少创建/销毁开销
2. **视锥剔除**：只更新和渲染屏幕视野内的对象
3. **纹理压缩**：使用合适的纹理格式（如 ETC2）减少内存占用
4. **对象数量限制**：同时存在的地面对象不超过10个
5. **地图分块加载**：将长地图分成多个小块，按需加载

---

## 11. 与现有系统的兼容性

### 11.1 关卡基类修改

`level_base.gd` 需要修改背景系统：

| 修改项 | 原逻辑 | 新逻辑 |
|--------|--------|--------|
| 背景创建 | 创建4层视差背景 | 创建1层单长条背景 |
| 滚动更新 | 每层不同速度滚动 | 统一速度滚动 |
| 对象生成 | 从CSV加载波次 | 从地图JSON加载对象 |

### 11.2 事件系统集成

地图对象系统与现有 `EventManager` 完全兼容：

- 可交互对象（坦克、碉堡）触发 `destroy_targets` 事件
- 保护目标（车队）触发 `escort_survive` 事件
- 隐藏要素触发 `area_stay` 或 `shoot_area` 事件

---

---

## 12. Design 评审意见（2026-07-13）

### 12.1 认同项

- **单图层替代 4 层视差**：符合 Strikers 1945 / iFighter 2 标准做法，Design 完全支持
- **交互对象架构**：Design 已有 `event_bunker_hidden/revealed`、`enemy_type97_tank` 等素材，可直接复用
- **深度感通过纹理渐变**：Design 在生成地图时可控制近深远浅

### 12.2 需要调整的问题

**（1）地图尺寸建议缩减**

| 原方案 | 问题 | 建议调整 |
|--------|------|---------|
| 标准关 512x9600 | AI 生成最大可用高度约 2048px，9600 需拼接 5 段，接缝处理困难 | 标准关 **512x4096**（约 50 秒 @ 80px/s），长关分段循环或区域切换 |
| 隐藏关 512x12000 | 同上 | 隐藏关 **512x6144**（约 77 秒）或分段设计 |

**（2）已交付 4 层背景的迁移策略**

当前 12 常规关 + 4 隐藏关已交付 4 层背景约 60 张。不建议全量重做：

| 策略 | 说明 |
|------|------|
| **M4 试点先行** | 先选 1-2 个关（建议 Stage 1 昆明 + H1 驼峰）做单图层试点 |
| **验证后推广** | Code 端验证单图层 + 碰撞系统后，再逐步迁移其他关卡 |
| **旧素材不删除** | 4 层背景保留在 `backgrounds/` 目录，迁移完成后再清理 |

**（3）碰撞体分离原则**

- 地图图片只画地面纹理 + 不可交互装饰物（房屋、树木、道路）
- 所有可交互对象（坦克、碉堡、山峰）不烘焙进地图图片，作为独立 sprite 由 Code 用 `StaticBody2D` / `Area2D` 实例化
- 这样地图图片可复用，碰撞体可独立调整

---

## 13. 隐藏关 H1 驼峰航线：山峰/云雾可撞机设计

### 13.1 设计目标

- **核心玩法**：几乎无敌方飞机，考验玩家飞行技术和反应能力
- **主要威胁**：两侧山壁碰撞 + 云雾视觉欺骗 + 飘落碎片
- **参考关卡**：1942 岩石关、Gradius 火山关、R-Type 地形关

### 13.2 地图结构

采用单图层设计，地图宽度 512px，安全飞行通道宽度在 200px ~ 350px 之间动态变化。

```
纵向剖面示意（→ 为地图宽度方向）：

段1 (0~20%): 入口段 — 宽通道热身
  ████████|←──────── 350px 安全通道 ────────→|████████
  ████████|      冰雪地面 + 轻微风雪         |████████

段2 (20~40%): 收窄段 — 通道逐渐变窄
  ████████████|←── 280px ──→|████████████
  ████████████|   S形弯道开始  |████████████

段3 (40~55%): 最窄段 — 高难度核心
  ██████████████████|← 200px →|███████████████████
  ██████████████████|  碎片掉落  |███████████████████

段4 (55~70%): 云雾欺骗段 — 视觉遮挡
  ██████████████ ☁️☁️☁️ ██████████████
  ██████████████ ☁️[山壁]☁️ ██████████████  ← 云雾后有隐藏山壁

段5 (70~85%): S形弯道 — 连续转向
  ████████████████████████
       ████████████████████████  ← 通道左右偏移
  ████████████████████████

段6 (85~100%): 出口段 — 展宽 + Boss 区
  ████████|←──────── 350px ────────→|████████
  ████████|    冰川裂缝 + Boss 区域   |████████
```

### 13.3 可撞机元素定义

| 元素 | 视觉描述 | 碰撞类型 | Code 实现 |
|------|---------|---------|----------|
| **山壁** | 深褐/灰白色岩石俯视，带冰覆盖和阴影投射 | **StaticBody2D** 多边形碰撞体，沿通道边缘 | 碰撞体数据随地图 JSON 配置，或用 TileMap 碰撞层 |
| **云雾（真实）** | 半透明白色团，边缘渐隐，纯装饰 | **无碰撞** | `TextureRect` 或 sprite，alpha 淡入淡出 |
| **云雾（欺骗）** | 外观与真实云雾相同，但背后藏着山壁突起 | **云雾无碰撞 + 隐藏山壁有碰撞** | 玩家接近时云雾淡出，露出山壁 |
| **冰碎片** | 小型白色冰块从山壁脱落 | **Area2D** 独立 sprite，向下飘移 + 轻微横向漂移 | 从配置的 y 坐标点生成，对象池复用 |

### 13.4 Design 交付物（H1 重做）

采用 M3-G 单图层方案，替代原有 3 张 4 层背景。

| 文件 | 尺寸 | 内容 | 用途 |
|------|------|------|------|
| `bg_hump_extreme_full.png` | 512x6144 | 单图层完整地图：山壁通道 + 冰面纹理 + 云雾装饰 | 替代原 far/mid/near 3 张 |
| `hump_rock_debris.png` | 64x64 | 冰岩碎片 sprite | Code 实例化为飘落障碍物 |
| `hump_cloud_fake.png` | 256x256 | 视觉欺骗云雾（半透明白色团） | Code 控制显隐，遮挡隐藏山壁 |

### 13.5 H1 地图 JSON 配置示例

```json
{
  "stage_id": "stage_H1_hump_extreme",
  "stage_name": "驼峰极端航线",
  "duration": 77,
  "scroll_speed": 80,

  "map": {
    "width": 512,
    "height": 6144,
    "background_image": "bg_hump_extreme_full.png",

    "wall_colliders": [
      {"segment": "0-20%",  "left_x": 0,   "right_x": 81,  "points": "..."},
      {"segment": "0-20%",  "left_x": 431, "right_x": 512, "points": "..."},
      {"segment": "20-40%", "left_x": 0,   "right_x": 116, "points": "..."},
      {"segment": "20-40%", "left_x": 396, "right_x": 512, "points": "..."},
      {"segment": "40-55%", "left_x": 0,   "right_x": 156, "points": "..."},
      {"segment": "40-55%", "left_x": 356, "right_x": 512, "points": "..."}
    ],

    "clouds": [
      {"y": 3000, "x": 320, "is_deceptive": true, "hidden_wall": {"x": 300, "width": 40, "height": 80}},
      {"y": 3400, "x": 150, "is_deceptive": false},
      {"y": 3800, "x": 400, "is_deceptive": true, "hidden_wall": {"x": 380, "width": 50, "height": 100}}
    ],

    "debris_spawners": [
      {"y": 2200, "x": "left_wall",  "rate": 0.5, "speed": 60},
      {"y": 2800, "x": "right_wall", "rate": 0.8, "speed": 80},
      {"y": 3200, "x": "both_walls", "rate": 1.0, "speed": 100}
    ],

    "objects": [],

    "boss_zone": {
      "start_y": 5600,
      "end_y": 6144,
      "boss_type": "boss_frozen_bomber"
    }
  }
}
```

### 13.6 Code 侧实施要点

1. **山壁碰撞体**：使用 `StaticBody2D` + `CollisionPolygon2D`，沿地图通道边缘放置。碰撞体坐标可从 `wall_colliders` 配置加载，或用单独的碰撞层 TileMap
2. **云雾显隐**：玩家 y 坐标接近欺骗云雾时，`Tween` 淡出云雾 sprite（alpha 0.7 → 0.0），露出后面山壁
3. **碎片生成**：`DebrisSpawner` 从配置点按 `rate` 频率生成 `hump_rock_debris` sprite，带轻微横向随机漂移，使用对象池复用
4. **无敌人**：H1 的 `objects` 数组为空，`SpawnManager` 对 H1 跳过空中敌机生成

---

## 14. 实施优先级与迁移计划

### 14.1 M4 试点阶段

| 步骤 | 内容 | 负责 |
|------|------|------|
| 1 | H1 驼峰单图层地图生成（`bg_hump_extreme_full.png` + 碎片 + 云雾） | Design |
| 2 | H1 山壁碰撞体 + 云雾显隐 + 碎片生成器 | Code |
| 3 | Stage 1 昆明单图层地图生成（`bg_kunming_full.png`） | Design |
| 4 | Stage 1 交互对象 JSON 配置 + `MapObjectManager` 集成 | Code |
| 5 | 试点验证：两个关卡跑通单图层 + 碰撞 + 对象系统 | Code + Design |

### 14.2 M5 全面迁移

试点验证后，按关卡顺序逐步迁移剩余 10 个常规关 + 3 个隐藏关到单图层方案。

---

## 15. 文件结构规划（更新版）

```
assets/sprites/backgrounds/
  stage_H1_hump_extreme/
    bg_hump_extreme_full.png      # 新：单图层完整地图
    bg_hump_extreme_far.png       # 旧：保留，迁移完成后清理
    bg_hump_extreme_mid.png       # 旧：保留
    bg_hump_extreme_near.png      # 旧：保留
  stage_01_kunming/
    bg_kunming_full.png           # 新：M4 试点生成
    bg_kunming_near.png           # 旧：保留
    bg_kunming_mid.png            # 旧：保留
    bg_kunming_ground.png         # 旧：保留
    bg_kunming_lake.png           # 旧：保留
    bg_kunming_mountain.png       # 旧：保留

assets/sprites/effects/
  hump_rock_debris.png            # 新：冰岩碎片
  hump_cloud_fake.png             # 新：欺骗云雾

resources/level_data/
  stage_H1_hump_extreme_map.json  # 新：H1 地图配置（含碰撞体、云雾、碎片）
  stage_01_kunming_map.json       # 新：Stage 1 地图配置

scenes/map_objects/
  map_object.gd                   # 新：对象基类
  enemy_tank.tscn                 # 新：坦克
  bunker.tscn                     # 新：碉堡
  convoy.tscn                     # 新：车队
  civilian_car.tscn               # 新：平民车辆
  anti_air_gun.tscn               # 新：防空炮
  hidden_element.tscn             # 新：隐藏要素

autoload/
  map_object_manager.gd           # 新：对象管理器
```

---

**本文档作为 M3-G 地图设计方案 v1.1，已整合 Design 评审意见 + H1 驼峰可撞机设计。Code 和 Design Agent 按第 14 节优先级分批实施。**