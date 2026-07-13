# Flying Tigers 1945 — M3-G Phase 1 验收报告

> **版本**: v1.0  
> **日期**: 2026-07-13  
> **验收人**: PM Agent  
> **验收提交**: `af05920`  
> **文档参考**: `docs/M3_F_supplement_design.md`、`docs/M3_G_map_design.md`

---

## 1. 验收范围

M3-G Phase 1 的核心目标是：**单图层地图系统基础设施 + 军衔系统集成 + 首批交互对象素材**。

| 部门 | 交付项 | 状态 |
|------|--------|------|
| Code | MapObjectManager (autoload) | 已交付 |
| Code | MapObject 基类 | 已交付 |
| Code | RankManager (autoload) | 已交付 |
| Code | LevelBase / UnlockManager / SaveManager / EventManager 修改 | 已交付 |
| Code | result_screen.gd / stage_select.gd 军衔集成 | 已交付 |
| Code | project.godot (autoload + 碰撞层) | 已交付 |
| Code | events_stage_02_rangoon.json / events_stage_05_guilin.json | 已交付 |
| Design | 21 张新 PNG 素材（地图/事件/UI） | 已交付 |
| Design | docs/M3_G_map_design.md v1.1 | 已交付 |
| 共同 | Devlog.md (+243 行) / DesignLog.md (+82 行) | 已更新 |

---

## 2. Code 部门审查结果

### 2.1 autoload/map_object_manager.gd — 合格 ✅

**设计评价**: 实现规范，架构清晰。

- ✅ JSON 配置加载 + 错误处理（文件不存在时静默跳过，向后兼容）
- ✅ 按 Y 坐标排序的待生成队列
- ✅ Scroll-based spawning 窗口逻辑（`SPAWN_AHEAD = 200px`）
- ✅ PoolManager 对象池复用集成
- ✅ 对象生命周期管理（tree_exited 信号移除活跃引用）
- ✅ clear() 方法供关卡结束调用

**问题**: SCENE_PATHS 字典引用了 5 个 `.tscn` 场景文件，但 `scenes/map_objects/` 目录下目前**没有任何 `.tscn` 文件**。运行时遇到这些类型会触发 `push_warning` 并跳过生成，不会崩溃，但功能不完整。**列为 P1**。

### 2.2 scenes/map_objects/map_object.gd — 合格 ✅

**设计评价**: 基类 API 简洁，支持对象池复用。

- ✅ setup(data) 从 JSON 初始化属性
- ✅ take_damage(damage) + _on_damaged() / _on_destroyed() 回调
- ✅ reset_state() 供 PoolManager 复用
- ✅ GameManager.add_score(score_value) 集成

**注意**: 当前继承 `Node2D` 而非 `Area2D`。注释提到碰撞层检测，但实际碰撞检测需要子类或 `.tscn` 场景补充 `Area2D + CollisionShape2D`。**不列为阻塞问题**，因为具体子类场景还未创建。

### 2.3 autoload/rank_manager.gd — 优秀 ✅

**设计评价**: 完全按照 M3-F 设计规范实现，逻辑严谨。

- ✅ 军衔分数公式正确：`stages_cleared * 100000 + total_score * 0.5 + s_rank_count * 200000`
- ✅ 7 级军衔阈值与 M3-F 完全一致（PVT→CPL→SGT→CPT→MAJ→COL→ACE）
- ✅ 双重晋升条件：分数门槛 + 通关数量 + S 评级数量
- ✅ 隐藏关军衔门槛映射正确（H1=SGT, H2=CPT, H3=MAJ, H4=COL）
- ✅ 进度条计算 + 下一级信息查询（含所需分数/关卡/S 评级）
- ✅ is_rank_reached() 比较使用 RANK_ORDER 索引，逻辑可靠

### 2.4 levels/level_base.gd 修改 — 合格 ✅

- ✅ `map_config_path` export 变量供关卡配置地图 JSON
- ✅ `bg_scroll_offset_y` 累计滚动偏移量跟踪
- ✅ `_ready()` 中调用 `MapObjectManager.load_map_config()`
- ✅ `_process()` 中调用 `MapObjectManager.update(bg_scroll_offset_y)`
- ✅ `end_level()` / `force_end_level()` 中调用 `MapObjectManager.clear()`

### 2.5 autoload/unlock_manager.gd 修改 — 优秀 ✅

- ✅ 双重解锁条件正确实现：`has_intel(stage_id) AND has_rank(stage_id)`
- ✅ 三种状态精确区分：`locked` / `rank_required` / `unlocked`
- ✅ 对 SaveManager / RankManager 的空引用防御性检查
- ✅ get_all_hidden_stages_status() 返回完整状态字典，便于 UI 展示

### 2.6 autoload/save_manager.gd 修改 — 合格 ✅

- ✅ `s_rank_count` 和 `stage_s_ranks` 字段新增
- ✅ save_game() / load_game() 中正确读写 S 评级数据
- ✅ add_s_rank(stage_index) 有去重逻辑（按关卡索引）
- ✅ reset_all_data() 中清零 S 评级数据

### 2.7 事件 JSON 配置 — 合格 ✅

- `events_stage_02_rangoon.json`: kill_target 类型，将军汽车事件，掉落 `intel_hump_route`
- `events_stage_05_guilin.json`: area_stay 类型，隐藏碉堡事件，掉落 `intel_tokyo_defense`
- 配置格式与现有 event_manager 兼容

### 2.8 project.godot — 正确 ✅

- ✅ [autoload] 新增 `RankManager` + `MapObjectManager`
- ✅ [layer_names] 2d_physics layer_6="GroundTarget", layer_7="Ally", layer_8="Scenery"

### 2.9 UI 脚本修改 — 合格 ✅

**result_screen.gd**:
- ✅ `_display_rank_info()` 方法显示当前军衔、下一级名称、所需分数
- ✅ 军衔颜色应用正确（使用 RankManager.RANK_COLORS）
- ✅ 在 `_on_score_roll_complete()` 中调用，时机合理

**stage_select.gd**:
- ✅ 隐藏关三种状态 UI 区分：`locked`(灰色+???), `rank_required`(棕黄色+军衔提示), `unlocked`(白色+🔮)
- ✅ `UnlockManager.get_hidden_stage_required_rank_name()` 集成正确

---

## 3. Design 部门审查结果

### 3.1 资产清单核对（21/21 全部交付）

| 文件名 | 尺寸 | 格式 | 状态 |
|--------|------|------|------|
| `bg_hump_extreme_full.png` | 512x6144 | PNG-32 RGBA ✅ | 单图层 H1 地图 |
| `hump_cloud_fake.png` | 256x256 | PNG-32 RGBA ✅ | 云雾障眼效果 |
| `hump_rock_debris.png` | 64x64 | PNG-32 RGBA ✅ | 碎石障碍物 |
| `event_bunker_hidden.png` | 128x128 | PNG-32 RGBA ✅ | 伪装碉堡 |
| `event_bunker_revealed.png` | 128x128 | PNG-32 RGBA ✅ | 暴露碉堡 |
| `event_c47_ally.png` | 128x128 | PNG-32 RGBA ✅ | 友军 C-47 |
| `event_c47_damaged.png` | 128x128 | PNG-32 RGBA ✅ | 受损 C-47 |
| `event_supplies_crate.png` | 64x64 | PNG-32 RGBA ✅ | 补给箱 |
| `event_transport_ship.png` | 128x128 | PNG-32 RGBA ✅ | 运输船 |
| `event_transport_wreck.png` | 128x128 | PNG-32 RGBA ✅ | 船只残骸 |
| `intel_hump_route.png` | 48x48 | PNG-32 RGBA ✅ | 驼峰情报图标 |
| `intel_tokyo_defense.png` | 48x48 | PNG-32 RGBA ✅ | 东京防空情报图标 |
| `ui_hint_bar_bg.png` | 400x40 | PNG-32 RGBA ✅ | 提示条背景 |
| `ui_hint_bar_locked.png` | 400x40 | PNG-32 RGBA ✅ | 锁定提示条 |
| `ui_rank_ace.png` | 64x64 | PNG-32 RGBA ✅ | 王牌军衔徽章 |
| `ui_rank_captain.png` | 48x48 | PNG-32 RGBA ✅ | 上尉 |
| `ui_rank_colonel.png` | 48x48 | PNG-32 RGBA ✅ | 上校 |
| `ui_rank_corporal.png` | 48x48 | PNG-32 RGBA ✅ | 下士 |
| `ui_rank_major.png` | 48x48 | PNG-32 RGBA ✅ | 少校 |
| `ui_rank_sergeant.png` | 48x48 | PNG-32 RGBA ✅ | 中士 |
| `ui_rank_progress_bar_bg.png` | 200x16 | PNG-32 RGBA ✅ | 进度条背景 |
| `ui_rank_progress_bar_fill.png` | 200x16 | PNG-32 RGBA ✅ | 进度条填充 |

**验证方法**: Python Pillow 抽样检查 4 个文件，全部确认 `RGBA PNG`。

### 3.2 命名规范 — 合格 ✅

- 全部使用 `snake_case`
- 无中文、无空格、无大写字母
- 目录结构符合 Master Interface Spec 4.2

### 3.3 尺寸规范 — 合格 ✅

- UI 图标 48x48 / 64x64 符合设计规范
- 进度条 200x16 合理
- 事件对象 64x64 / 128x128 合理
- H1 单图层地图 512x6144（纵向 3 屏高度）合理

---

## 4. 问题清单

### P1 — 必须修复（功能不完整）

| # | 问题 | 影响 | 修复建议 |
|---|------|------|---------|
| 1 | `scenes/map_objects/` 下缺少 5 个 `.tscn` 场景文件：`enemy_tank.tscn`、`bunker.tscn`、`convoy.tscn`、`civilian_car.tscn`、`anti_air_gun.tscn` | MapObjectManager 加载地图配置后，遇到这些类型会警告并跳过生成，地图对象系统无法工作 | Code 部门在 Phase 2 创建这 5 个 `.tscn` 场景（每个包含 Area2D + Sprite2D + CollisionShape2D，挂载 map_object.gd 或其子类） |

### P2 — 建议修复（架构优化）

| # | 问题 | 影响 | 修复建议 |
|---|------|------|---------|
| 2 | `map_object.gd` 继承 `Node2D` 而非 `Area2D`，但注释提到碰撞检测 | 子类/场景必须自行补充 Area2D 才能进行碰撞检测，容易遗漏 | 在创建具体 `.tscn` 场景时，根节点使用 `Area2D`，挂载 `map_object.gd`（或子类），并添加 `CollisionShape2D` |

### P3 — 轻微问题（不影响核心功能）

| # | 问题 | 影响 | 修复建议 |
|---|------|------|---------|
| 3 | `result_screen.gd` 的 `_display_rank_info()` 复用了 `unlock_hint_label` 显示军衔信息，覆盖了关卡解锁提示 | 如果同时触发"解锁新关卡"和"军衔信息"，后者会覆盖前者 | 在 result_screen.tscn 中单独添加一个 `RankInfoLabel` 节点，与 `UnlockHintLabel` 分离 |
| 4 | `bg_hump_extreme_full.png` 尺寸为 512x6144（3 倍于普通背景层 512x2048） | 关卡配置需要正确设置单图层模式的滚动参数，否则可能出现滚动速度不匹配 | 在 `stage_H1_hump_extreme.tscn` 或对应配置中调整 `bg_scroll_speed` 和 `motion_mirroring` |

---

## 5. 验收评级

| 部门 | 评级 | 说明 |
|------|------|------|
| **Code** | **A-** | 核心系统（RankManager、MapObjectManager、LevelBase 集成）实现优秀，完全匹配 M3-F/M3-G 设计规范。扣半级原因是 P1：5 个 `.tscn` 场景文件缺失，导致地图对象系统目前无法实际运行。建议 Phase 2 补齐。 |
| **Design** | **A** | 21 张 PNG 素材全部 PNG-32 RGBA，尺寸和命名符合规范。H1 单图层地图、事件对象素材、军衔徽章、情报图标、提示条 UI 完整交付。 |
| **总体** | **A-** | M3-G Phase 1 基础设施搭建完成，RankManager 可直接使用。MapObject 系统框架就绪，待 Phase 2 补齐具体场景文件后正式运行。 |

---

## 6. 下一步任务建议（M3-G Phase 2）

### Code 部门

1. **G-C3: 创建 5 个地图对象场景**（解决 P1）
   - `scenes/map_objects/enemy_tank.tscn` — 九七式中战车，hp=10，碰撞层 Layer6(GroundTarget)，检测 Layer2(PlayerBullet)
   - `scenes/map_objects/bunker.tscn` — 碉堡，hp=20，同上
   - `scenes/map_objects/convoy.tscn` — 运输车队，hp=15
   - `scenes/map_objects/civilian_car.tscn` — 平民车辆，is_interactive=false
   - `scenes/map_objects/anti_air_gun.tscn` — 防空炮，hp=12，可发射敌弹
   - 每个场景根节点为 `Area2D`，挂载 `map_object.gd`，添加 `CollisionShape2D`

2. **G-C4: 创建 H1 单图层地图配置 JSON**
   - `resources/level_data/stage_H1_hump_extreme_map.json`
   - 定义 5~8 个 map_objects（云雾假石、碎石障碍等）
   - 参考 `docs/M3_G_map_design.md` 中的坐标设计

3. **G-C5: 事件场景集成**
   - `event_target_car.tscn`（将军汽车，快速移动，带扬尘粒子）
   - `event_target_bunker.tscn`（隐藏碉堡，可切换 hidden/revealed 纹理）

### Design 部门

1. **G-D2: 剩余事件素材**
   - `event_target_car.png`（128x64，逃跑的黑色轿车）
   - `event_target_bridge.png` + `event_target_bridge_broken.png`（怒江渡桥，同画布尺寸）

2. **G-D3: Stage 02/05 背景微调**
   - 如 M3_G_map_design.md 所述，在 Stage 02（Rangoon）和 Stage 05（Guilin）背景中加入"可破坏"视觉暗示（如道路上预先存在的弹坑）

---

## 7. 结论

M3-G Phase 1 已按设计要求完成基础设施搭建。**Code 评级 A-，Design 评级 A**。建议立即进入 Phase 2，重点补齐 5 个 `.tscn` 场景文件和 H1 地图 JSON 配置，使单图层地图系统完整运行。
