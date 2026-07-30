# Flying Tigers 1945 — 三方协作工作流规范

> 本文档定义 Work Agent(PM) / Code Agent / Design Agent 三个角色的协作规则。
> **所有 Agent 必须在开始工作前阅读本文档。**
> **最后更新**: 2026-07-30（v1.6b 阶段任务分配）

---

## 角色与职责

| 角色 | 部门 | 核心职责 | 日志文件 |
|------|------|---------|---------|
| **Work Agent** | PM / 项目管理 | 需求拆解、任务分配、验收交付物、出具验收报告 | `docs/` 下验收报告 |
| **Code Agent** | 研发部 | Godot 4.7 编码、.gd脚本、.tscn场景、技术调试 | **`devlogv1.5.md`** |
| **Design Agent** | 美工部 | Sprite/UI素材制作、动画帧序列、美术规范、外包素材审核 | **`DesignLogv1.5.md`** |

> **日志文件说明**: v1.5 起，Code Agent 使用 `devlogv1.5.md`，Design Agent 使用 `DesignLogv1.5.md`。
> 旧的 `Devlog.md` / `DesignLog.md` 为 M1~M3 阶段历史记录，不再追加。

---

## 工作目录

三个 Agent 共享同一个 Git 仓库目录（通过 Trae IDE 同步到 GitHub 远程仓库）：

```
FlyingTigers1945_sync/
├── WORKFLOW.md            ← PM 维护（本文件：协作规范+任务分配）
├── devlogv1.5.md          ← Code Agent 维护（代码改动记录）
├── DesignLogv1.5.md       ← Design Agent 维护（美术改动+外包审核记录）
├── docs/                  ← PM 维护（设计文档+归档）
│   ├── v1.6b-level-design-spec/   ← 当前真理源：12关详细设计
│   ├── aircraft-*-spec/           ← 飞机精灵图外包规范
│   ├── ground-*-spec/             ← 地面单位外包规范
│   ├── scene-element-*-spec/      ← 场景元素外包规范
│   ├── v1.6_*.md                  ← v1.6 核心设计文档
│   └── archive/                   ← v1.0~v1.5 归档文档
├── autoload/              ← Code Agent
├── scenes/                ← Code Agent（脚本+场景）
├── scripts/               ← Code Agent
├── assets/sprites/        ← Design Agent（所有PNG素材）
├── resources/             ← 双方共用（Code写配置，Design参考）
└── ...
```

---

## 每次任务的标准流程

```
1. PM 在 WORKFLOW.md 中分配任务 → 给出具体需求 + 验收标准
        ↓
2. Code / Design Agent 拉取最新代码（git pull），在各自日志中记录任务开始
        ↓
3. 执行工作（修改/创建文件）
        ↓
4. 在各自日志中记录：改了什么文件、做了什么、发现什么问题
        ↓
5. git add . && git commit && git push（通过 Trae IDE 同步到 GitHub）
        ↓
6. PM 拉取最新代码，按验收标准审核交付物
        ↓
7. PM 在 WORKFLOW.md 中更新任务状态，出具验收结论
```

---

## 日志格式要求

### devlogv1.5.md（Code Agent）

每次任务追加一个章节，格式：

```markdown
## v1.6b-C[N]：[任务标题]

**日期**: YYYY-MM-DD
**目标**: [一句话描述]
**关联文档**: docs/v1.6b-level-design-spec/ 或 docs/v1.6_*.md

### 改动文件
- `scenes/player/player_p40.tscn` — 新建，玩家P40场景预制件
- `autoload/game_manager.gd` — 修改，修复XX bug

### 做了什么
[描述具体实现内容]

### 遇到的问题与解决
[如有bug或设计冲突，记录原因和解决方案]

### 验证方式
[如何测试：命令行/编辑器运行/单元测试]
```

### DesignLogv1.5.md（Design Agent）

每次任务追加一个章节，格式：

```markdown
## v1.6b-D[N]：[任务标题]

**日期**: YYYY-MM-DD
**目标**: [一句话描述]
**关联文档**: docs/aircraft-sprite-*-spec/ 或 docs/ground-*-spec/

### 产出文件
- `assets/sprites/player/p40/player_p40_body.png` — 新建，128x128 RGBA

### 设计说明
[色彩、风格、尺寸选择的原因]

### 技术规格
- 格式：PNG-32 (RGBA)
- 尺寸：128x128 px
- 背景：透明
- 参考文档：docs/aircraft-sprite-sizing-spec/ 第N章

### 外包审核记录（如涉及外包素材）
[外包交付物的审核结论：通过/退回/需修改]

### 已知问题
[如有不符合规范的地方，主动记录]
```

---

## Git 操作规范

每个 Agent 每次完成工作后必须执行（通过 Trae IDE 或命令行）：

```powershell
git add .
git commit -m "[部门缩写] v1.6b-[N]: [简要描述]"
# 部门缩写：CODE / DESIGN / PM
git push origin main
```

Commit message 示例：
- `CODE v1.6b-1: 实现滚筒翻滚动画三图切换`
- `DESIGN v1.6b-1: 审核外包飞机精灵图P0批次`
- `PM v1.6b-1: 关卡设计文档v1.6b定稿+文档归档`

---

## 文件归属（避免冲突）

| 目录 | 主负责人 | 另一方可以 |
|------|---------|-----------|
| `assets/sprites/**` | **Design** 专属 | Code 只读引用 |
| `scenes/**/*.gd` | **Code** 专属 | Design 只读参考 |
| `scenes/**/*.tscn` | **Code** 专属 | — |
| `autoload/` | **Code** 专属 | — |
| `scripts/` | **Code** 专属 | — |
| `resources/level_data/` | **Code** 专属 | — |
| `docs/` | **PM** 专属 | 双方只读参考 |
| `WORKFLOW.md` | **PM** 专属 | 双方只读 |
| `devlogv1.5.md` | **Code Agent** 专属 | — |
| `DesignLogv1.5.md` | **Design Agent** 专属 | — |
| `project.godot` | **Code** 专属 | — |

如果需要修改对方负责的文件，必须在日志中记录并说明原因。

---

## 验收标准

### Design 验收重点
- PNG 格式：必须是 **PNG-32 RGBA（有透明通道）**
- 尺寸：必须符合对应外包 spec 规定（9px/m 比例体系）
- 命名：必须符合 snake_case 规范
- 数量：必须符合交付清单
- Godot 导入：PM 拉取后用 Godot 打开验证无报错

### Code 验收重点
- .tscn 场景文件：脚本已挂载、节点树正确
- 语法检查：`godot --check-only` 通过
- 运行测试：场景可在 Godot 中运行无崩溃
- devlogv1.5.md：每次任务有完整记录

### 评级标准
- **A级**：100%通过 → 直接进入下一阶段
- **B级**：≥90%通过 → 限期2天整改
- **C级**：≥75%通过 → 限期5天整改
- **D级**：<75%通过 → 退回重做

---

## 文档同步规范

**所有新增/修改的任务文档必须同步到 GitHub 仓库，确保 Code 和 Design Agent 都能读取最新文档。**

1. **PM** 每次更新 WORKFLOW.md / 设计文档后，必须 `git push` 到 GitHub
2. **Code Agent** 每次更新 devlogv1.5.md 后，必须 `git push` 到 GitHub
3. **Design Agent** 每次更新 DesignLogv1.5.md 后，必须 `git push` 到 GitHub
4. **三方在开始新任务前，必须先 `git pull` 拉取最新代码和文档**

---

---

# 第一部分：历史工作总结（M1 ~ v1.5）

## 里程碑进度

| 里程碑 | 状态 | Design | Code | 说明 |
|--------|------|--------|------|------|
| M1 核心原型 | 已通过 | A级 | A级 | 核心角色Sprite + UI基础包 + 玩法原型 |
| M2 关卡+BOSS | 已通过 | A-级 | A级 | 前6关背景 + 前3个BOSS + 关卡系统 |
| M3-A 基础修复 | 已通过 | A级 | A级 | 基础修复 |
| M3-B 关卡扩展P1 | 已通过 | A级 | A级 | 关卡扩展P1 |
| M3-C 关卡扩展P2+隐藏关 | 已通过 | A级 | A级 | 关卡扩展P2+隐藏关 |
| M3-D 系统功能 | 已通过 | — | A-级 | 系统功能 |
| M3-E 平台适配+性能 | 已通过 | — | A-级 | 平台适配+性能 |
| M3-F 军衔+情报系统 | 已通过 | — | A级 | 军衔系统+4隐藏情报（牛皮纸袋） |
| M3-G Phase 1 基础设施 | 已通过 | A级 | A-级 | 地图基础设施 |
| M3-G Phase 2 场景+测试修复 | 已通过 | A级 | A级 | 场景+测试修复 |
| **v1.5.0 升级** | **已通过** | A级 | A级 | 关卡重排+Boss重设计+多战机+隐藏情报+友军保护+单层背景 |
| **v1.5.2 后续** | **已通过** | A级 | A级 | F1-F6 素材补全+Ki-48场景 |

## v1.5 完成状态

游戏框架已完整搭建：
- **16 关**（L01-L12 主线 + H1-H4 隐藏关，v1.6b 精简为 12 关 L01-L10+H1-H2）
- **8 种 Boss 类型**（formation/ace/naval_assault/ground_facility/multi_target/mixed/final/environmental）
- **8 架可玩战机**（P-40/P-40B/P-40E/P-38/P-47/P-51/B-25/B-29，含 roll 变体）
- **隐藏情报系统**（牛皮纸袋图标，intel_event_briefcase 事件类型，4 份情报）
- **友军保护系统**（faction 属性，ally/civilian 免受玩家误伤）
- **军衔等级系统**（PVT→ACE，rank_score 计算，隐藏关双重解锁）
- **存档/排行榜**（SaveManager + LeaderboardManager）

## 文档归档

v1.0~v1.5 阶段的设计与验收文档已归档至 `docs/archive/`：
- `archive/foundation-v1.0/` — 8 项基础规范
- `archive/milestones/` — 18 项 M1/M2/M3 验收报告
- `archive/v1.5/` — 3 项 v1.5 过渡设计

详见 `docs/archive/README.md`。

---

---

# 第二部分：v1.6b 任务分配

> **当前阶段目标**: 在 v1.5 完成的框架基础上，按 v1.6b 关卡设计文档实施新需求与功能调优。
> **真理源文档**: `docs/v1.6b-level-design-spec/v1.6b-level-design-spec.html`
> **任务编号规则**: v1.6b-C[N]（Code）/ v1.6b-D[N]（Design）

## Code Agent 任务清单

### v1.6b-C1: 滚筒翻滚动画系统（杂兵级）

**优先级**: P0
**关联文档**: `docs/v1.6_h2_roll_animation_design.md` §1~2
**目标**: 为 J7W 震电、J8M 秋水实现三图切换滚筒翻滚动画

**详细要求**:
1. 改造 `scenes/enemies/enemy_j7w_shinden.tscn`：场景结构从 1×Sprite2D 改为 3×Sprite2D（SpriteTop + SpriteSide + SpriteBottom）
2. 新建 `scenes/enemies/enemy_j7w_shinden.gd`：实现 `_update_roll(delta)` 方法，roll_speed=540°/s，side_threshold=0.15
3. 改造 `scenes/enemies/enemy_j8m_shusui.tscn`：同样改为 3×Sprite2D 结构
4. 新建/更新 `scenes/enemies/enemy_j8m_shusui.gd`：roll_speed=720°/s，side_threshold=0.12，保留燃料限时冲刺机制
5. 在 `autoload/spawn_manager.gd` 中确认两机型注册无误

**验收标准**:
- [ ] J7W/J8M 场景含 3 个 Sprite2D 子节点（SpriteTop/SpriteSide/SpriteBottom）
- [ ] `godot --check-only` 语法通过
- [ ] 运行时可见连续滚筒翻滚效果（俯视→侧视→仰视循环）
- [ ] J8M 燃料耗尽后冲刺速度倍率正常（2.5x）
- [ ] 对象池归还后状态正确重置（reset_state）

### v1.6b-C2: 倾斜转弯（Banking）动画系统

**优先级**: P1
**关联文档**: `docs/aircraft-bank-turn-spec/aircraft-bank-turn-spec.html`
**目标**: 实现可转弯敌机的 45° 倾斜飞行状态精灵切换

**详细要求**:
1. 在 `scenes/enemies/enemy_base.gd` 中新增 banking 状态机：straight → bank_left / bank_right
2. 根据横向移动方向（velocity.x）自动切换精灵图：`_{n|s}` → `_{n|s}_roll_{l|r}`
3. 状态切换需有过渡时间（约 0.3s），避免高频抖动
4. 适用于 7 种可转弯敌机（Ki-27/Ki-43/Ki-44/Ki-61/Ki-84/J2M/Ki-45）

**验收标准**:
- [ ] 敌机转弯时精灵图正确切换为倾斜姿态
- [ ] 直线飞行时恢复正向精灵图
- [ ] 无精灵图闪烁/抖动
- [ ] 7 种敌机均正常工作

### v1.6b-C3: 地图渲染系统升级（1080×4800）

**优先级**: P1
**关联文档**: `docs/v1.6_map_rendering_design.md`
**目标**: 将地图从 800×2400 升级为 1080×4800 单层长条俯视渲染

**详细要求**:
1. Parallax2D 配置更新：画布尺寸 1080×4800，滚动方向纵向
2. 旧 800px 素材标记 deprecated（不删除，保留兼容）
3. 实现可重复地形纹理 + 非重复地标混合渲染
4. 支持 Shader 水面效果（波纹幅度可配置）

**验收标准**:
- [ ] 12 关均使用 1080×4800 画布
- [ ] 水面 Shader 正常渲染（仰光/湘江/怒江/漓江）
- [ ] 无画面撕裂/错位
- [ ] 性能：60fps 稳定（桌面端）

### v1.6b-C4: 关卡配置更新（v1.6b 12 关）

**优先级**: P0
**关联文档**: `docs/v1.6b-level-design-spec/v1.6b-level-design-spec.html`
**目标**: 按v1.6b设计文档更新全部 12 关的关卡配置

**详细要求**:
1. 更新 `resources/level_data/stage_config.json`：关卡编号 L01-L10 + H1-H2
2. 按设计文档分段设计更新各关 CSV 波次配置（出场敌人/时间/编队/路径）
3. 更新 Boss 配置 JSON（L01 轰炸机 / L02 天龙号 / L06 装甲列车8节 / H2 震电改J7W2 等）
4. 实现隐藏要素事件配置（I-1~I-6 情报事件 + P-1~P-6 保护事件）
5. L06 装甲列车 Boss 实现：8 节车厢独立 HP，20 个炮台，弹药车厢连锁爆炸，指挥车厢顺序触发情报

**验收标准**:
- [ ] 12 关均可正常加载并通关
- [ ] Boss 战机制符合设计文档
- [ ] 隐藏情报事件可触发（牛皮纸袋掉落+拾取）
- [ ] 保护事件时限与失败条件正确
- [ ] L06 装甲列车 8 节车厢顺序击破逻辑正确

### v1.6b-C5: 隐藏情报系统更新（H2 四情报解锁）

**优先级**: P1
**关联文档**: `docs/v1.6b-level-design-spec/v1.6b-level-design-spec.html` 附录14b
**目标**: 更新隐藏关解锁逻辑为 H1=1份情报 / H2=收集4份情报

**详细要求**:
1. 修改 `autoload/unlock_manager.gd`：
   - H1 解锁条件：持有 intel_hump_route（1份情报）+ 军衔中士 + rank_score≥80万
   - H2 解锁条件：持有 L04-L09 中任意 4 份情报 + 军衔上尉 + rank_score≥200万 + ≥2关S级
2. 修改 `scripts/event_manager.gd`：已持有情报重复游玩时，掉落高分积分道具替代情报纸袋
3. 更新 L06 隐藏情报机制：2 节小列车（前弹药+后指挥），必须先摧毁指挥车厢，否则情报损坏

**验收标准**:
- [ ] H1 持有驼峰航线情报后解锁（军衔达标）
- [ ] H2 集齐 4 份情报后解锁（军衔达标）
- [ ] 已持有情报重玩时掉落积分道具而非情报
- [ ] L06 先打弹药车厢→情报永久损坏不掉落

### v1.6b-C6: 武器系统与弹幕模式

**优先级**: P2
**关联文档**: `docs/v1.6_weapon_system_design.md`
**目标**: 实现v1.6武器升级系统与新弹幕模式

**详细要求**:
1. 玩家武器升级路径（Level 1-5，火力递增）
2. 新增弹幕模式：扇形散射 / 追踪弹 / 旋转弹幕 / 三岔火线
3. H2 Boss 震电改 J7W2 四模式循环弹幕（扇形/追踪/旋转/狂暴）

**验收标准**:
- [ ] 武器升级道具拾取后火力正确提升
- [ ] 4 种弹幕模式视觉效果与碰撞正确
- [ ] H2 Boss 四模式循环切换正常

### v1.6b-C7: H1 驼峰关护送机制

**优先级**: P2
**关联文档**: `docs/v1.6b-level-design-spec/v1.6b-level-design-spec.html` H1 章节
**目标**: 实现 H1 驼峰绝径的 C-47 护送+强风+山壁障碍机制

**详细要求**:
1. C-47 运输机×3 友军 AI（从屏幕底部缓慢上移）
2. 零式优先攻击运输机（仇恨值机制）
3. 强风气流扰动（恒定侧风 + 随机阵风）
4. 山壁障碍（碰撞体，碰撞即损失生命）
5. 胜利条件：至少 1 架 C-47 存活到关卡结束

**验收标准**:
- [ ] C-47 运输机正常移动且可被击毁
- [ ] 零式优先攻击运输机
- [ ] 强风扰动玩家飞行轨迹
- [ ] 山壁碰撞造成伤害
- [ ] 胜利/失败条件判定正确

---

## Design Agent 任务清单

> **重要**: Design Agent 除自身制作素材外，还负责**审核外包团队交付的素材**。
> 外包规范文档位于 `docs/` 下各 `*-spec/` 目录。

### v1.6b-D1: 审核外包飞机精灵图（P0 批次）

**优先级**: P0
**关联文档**: `docs/aircraft-sprite-outsourcing-spec/` + `docs/aircraft-sprite-sizing-spec/`
**目标**: 审核外包团队交付的日军机精灵图（含翻滚三图）

**审核要求**:
1. 检查文件命名：snake_case，符合 `enemy_{type}_{top|side|bottom}.png` 规范
2. 检查画布尺寸：128×128（标准战斗机/截击机）
3. 检查实际绘制尺寸：按 9px/m 比例（如 J8M 秋水 54×86px，不能填满画布）
4. 检查格式：PNG-32 RGBA，透明背景
5. 检查风格：90° 纯俯视、低饱和度、写实军事插画风格
6. 检查三图一致性：top/side/bottom 三视角机体比例一致
7. 审核结论写入 DesignLogv1.5.md，退回项注明原因

**涉及机型**（P0 批次）:
- J7W 震电（top/side/bottom 三图）
- J8M 秋水（top/side/bottom 三图）
- A6M 零式（top/side/bottom 三图）

**验收标准**:
- [ ] 审核报告写入 DesignLogv1.5.md
- [ ] 通过的素材放入 `assets/sprites/enemy/`
- [ ] 退回的素材注明修改原因

### v1.6b-D2: 审核外包飞机精灵图（P1 批次）

**优先级**: P1
**关联文档**: 同 D1
**目标**: 审核其余日军机精灵图

**涉及机型**（P1 批次）:
- Ki-27 / Ki-43 / Ki-44 / Ki-61 / Ki-84 / Ki-45 / J2M / Ki-48 / Ki-21 / D3A / Ki-51 / G3M
- 震电改 J7W2（Boss，160×160，含受击态+燃烧态）
- 震电改·赤 / 震电改·玄（双 Boss，含 top/side/bottom 三图）

**验收标准**: 同 D1

### v1.6b-D3: 审核外包地面作战单位

**优先级**: P1
**关联文档**: `docs/ground-combat-unit-outsourcing-spec/`
**目标**: 审核外包团队交付的地面作战单位精灵图（30 项）

**审核要求**:
1. 检查命名与尺寸（坦克 64×64 / 炮台 48×48 / 列车各 75×40 / 卡车 64×48）
2. 检查方向图完整性（坦克 8 方向 / 卡车 4 方向）
3. 检查摧毁变体（暗化+红色偏移）
4. 检查格式与风格
5. **L06 装甲列车 8 节车厢**：G-40a~G-40h，每节独立精灵图，含炮台摧毁变体

**验收标准**:
- [ ] 30 项地面单位全部审核
- [ ] 装甲列车 8 节车厢+20 炮台变体完整
- [ ] 审核报告写入 DesignLogv1.5.md

### v1.6b-D4: 审核外包场景元素

**优先级**: P1
**关联文档**: `docs/scene-element-outsourcing-spec/`
**目标**: 审核外包团队交付的非交互场景元素（33 项）

**审核要求**:
1. 检查地形纹理（红土/雪地/水田/沙漠/城市废墟/喀斯特/雪山/热带）
2. 检查建筑类素材（瓦屋顶/日式城区/碉堡/桥梁/浮桥3态/铁轨/油库/机场）
3. 检查水面 Shader 素材（仰光浑浊/湘江清澈/怒江湍急/漓江翠绿）
4. 检查地标素材（滇池/佛塔/惠通桥遗迹/喀斯特峰林/提尼安机场/广岛城区）

**验收标准**:
- [ ] 33 项场景元素全部审核
- [ ] 审核报告写入 DesignLogv1.5.md

### v1.6b-D5: 审核外包水面/海军单位

**优先级**: P2
**关联文档**: `docs/ground-naval-asset-manifest/`
**目标**: 审核外包团队交付的水面舰艇素材

**审核要求**:
1. 检查舰艇精灵图（天龙号/妙高号/最上号巡洋舰 + 驱逐舰/运输船/巡逻艇/民船）
2. 检查 Boss 部件精灵图（炮塔/防空炮/舰桥/雷达/烟囱，含摧毁变体）
3. 检查尺寸比例（9px/m 体系）

**验收标准**:
- [ ] 水面单位全部审核
- [ ] Boss 部件 60 张（正常+摧毁）完整
- [ ] 审核报告写入 DesignLogv1.5.md

### v1.6b-D6: 任务简报背景图（AI 生图审核）

**优先级**: P2
**关联文档**: `docs/v1.6b-level-design-spec/v1.6b-level-design-spec.html` 附录（AI生图提示词汇总）
**目标**: 审核 12 张 AI 生成的任务简报背景图（1940年代军用侦察照片风格）

**审核要求**:
1. 检查风格：sepia/黑白色调、grainy film grain、aged paper texture
2. 检查内容：地形特征准确、军事目标标注（红圈）、情报印章、手写战术标注
3. 检查历史准确性（无时代错误元素）
4. 尺寸：1920×1080

**验收标准**:
- [ ] 12 张任务简报图（L01-L10, H1, H2）全部审核
- [ ] 历史准确性人工检查通过
- [ ] 审核报告写入 DesignLogv1.5.md

### v1.6b-D7: 补充缺失素材（自研）

**优先级**: P2
**关联文档**: `docs/v1.6b-level-design-spec/v1.6b-level-design-spec.html` 附录（素材需求补充清单）
**目标**: 制作外包范围外的补充素材

**涉及素材**:
- 浮桥（半搭建态，3 种进度：30%/50%/70%）
- 惠通桥遗迹（断桥地标）
- 油库（6 连排，可连锁爆炸）
- 铁路桥
- 塔台
- 跑道（停机版，可摧毁）
- 装甲列车 Boss 完整素材（如外包未覆盖）

**验收标准**:
- [ ] 补充素材按清单全部制作
- [ ] 格式/尺寸/风格符合规范
- [ ] 产出记录写入 DesignLogv1.5.md

---

## 任务状态总览

### Code Agent

| 任务编号 | 任务标题 | 优先级 | 状态 | 备注 |
|---------|---------|--------|------|------|
| v1.6b-C1 | 滚筒翻滚动画系统 | P0 | 待开始 | J7W/J8M 三图切换 |
| v1.6b-C2 | 倾斜转弯动画系统 | P1 | 待开始 | 7 种可转弯敌机 |
| v1.6b-C3 | 地图渲染系统升级 | P1 | 待开始 | 1080×4800 |
| v1.6b-C4 | 关卡配置更新 | P0 | 待开始 | 12 关 CSV+Boss JSON |
| v1.6b-C5 | 隐藏情报系统更新 | P1 | 待开始 | H2 四情报解锁 |
| v1.6b-C6 | 武器系统与弹幕 | P2 | 待开始 | 升级路径+4模式 |
| v1.6b-C7 | H1 护送机制 | P2 | 待开始 | C-47+强风+山壁 |

### Design Agent

| 任务编号 | 任务标题 | 优先级 | 状态 | 备注 |
|---------|---------|--------|------|------|
| v1.6b-D1 | 审核外包飞机 P0 | P0 | 待开始 | J7W/J8M/A6M 三图 |
| v1.6b-D2 | 审核外包飞机 P1 | P1 | 待开始 | 其余敌机+Boss |
| v1.6b-D3 | 审核外包地面单位 | P1 | 待开始 | 30 项含装甲列车 |
| v1.6b-D4 | 审核外包场景元素 | P1 | 待开始 | 33 项 |
| v1.6b-D5 | 审核外包海军单位 | P2 | 待开始 | 舰艇+部件 |
| v1.6b-D6 | 任务简报背景图审核 | P2 | 待开始 | 12 张 AI 生图 |
| v1.6b-D7 | 补充缺失素材 | P2 | 待开始 | 浮桥/油库/塔台等 |

---

## 执行顺序建议

**第一批（P0，立即开始）**:
1. Code: C1（滚筒翻滚）→ C4（关卡配置）
2. Design: D1（审核飞机 P0）

**第二批（P1，P0 完成后）**:
3. Code: C2（倾斜转弯）→ C3（地图渲染）→ C5（情报系统）
4. Design: D2（审核飞机 P1）→ D3（审核地面）→ D4（审核场景）

**第三批（P2，P1 完成后）**:
5. Code: C6（武器系统）→ C7（H1 护送）
6. Design: D5（审核海军）→ D6（简报图）→ D7（补充素材）

> **协作要点**: Code C1 依赖 Design D1 审核通过的 J7W/J8M 三视图素材；
> Code C4 依赖 Design D3 审核通过的装甲列车素材。
> 请 Design 优先推进外包审核，确保 Code 有素材可用。
