# Flying Tigers 1945 — 项目文档索引

> **更新日期**: 2026-07-30
> **当前阶段**: v1.6b（初版框架已完成，进入关卡细化与外包素材阶段）
> **归档说明**: v1.0~v1.5 阶段的设计与验收文档已移至 `archive/`，详见 [归档索引](archive/README.md)

---

## 当前活跃文档

### 核心设计文档（v1.6b 系列）

| 文档 | 面向部门 | 说明 |
|------|---------|------|
| **v1.6b-level-design-spec/** | Design + Code | **当前真理源**：12 关详细设计（L01-L10, H1-H2），含分段设计/Boss/隐藏要素/任务简报/历史评价 |
| **v1.6_h1_h2_aircraft_design.md** | Design + Code | H1/H2 机型补充设计：震电/秋水/零式等实验机型 |
| **v1.6_h2_roll_animation_design.md** | Code | 滚筒翻滚动画技术方案（三图切换+scale.x）+ 双 Boss 编队 |
| **v1.6_weapon_system_design.md** | Code | 武器系统与弹幕模式设计 |
| **v1.6_map_rendering_design.md** | Code | 地图渲染设计（1080×4800 单层长条俯视，待实施） |
| **v1.6_ground_units_and_effects_design.md** | Code + Design | 地面单位与水域/气流特效设计 |

### 外包规范文档（v1.6 系列）

| 文档 | 面向部门 | 说明 |
|------|---------|------|
| **aircraft-sprite-outsourcing-spec/** | 外包团队 | 日军机精灵图外包需求（含三视图/受击态/翻滚三图） |
| **aircraft-sprite-sizing-spec/** | 外包团队 | 敌机精灵图比例尺寸规范（9px/m 体系，含 echarts 图表） |
| **aircraft-bank-turn-spec/** | 外包团队 | 倾斜转弯精灵图规范（banking 动画） |
| **ground-combat-unit-outsourcing-spec/** | 外包团队 | 地面作战单位外包规范（坦克/炮台/列车/卡车，30 项） |
| **ground-naval-asset-manifest/** | 外包团队 | 地面/水面单位+剧情场景素材清单（94 项） |
| **scene-element-outsourcing-spec/** | 外包团队 | 非交互场景元素外包规范（地形/建筑/基础设施，33 项） |

---

## 阅读顺序

### Design Agent
1. `v1.6b-level-design-spec` → 了解所有关卡的详细设计
2. 各外包 spec → 执行美术外包任务
3. `v1.6_h1_h2_aircraft_design.md` → 了解 H1/H2 特殊机型

### Code Agent
1. `v1.6b-level-design-spec` → 了解关卡分段/Boss/隐藏要素需求
2. `v1.6_weapon_system_design.md` → 武器与弹幕实现
3. `v1.6_map_rendering_design.md` → 地图渲染实现
4. `v1.6_h2_roll_animation_design.md` → 翻滚动画实现

---

## 归档文档

v1.0~v1.5 阶段的设计与验收文档已归档至 `archive/`，保留作历史参考：

| 归档目录 | 内容 | 归档原因 |
|---------|------|---------|
| `archive/foundation-v1.0/` | master-interface-spec / design-spec / tech-spec / GDD / acceptance-checklist 等 8 项 | v1.0 框架规范，框架已落地为代码 |
| `archive/milestones/` | M1/M2/M3 全部验收报告与设计任务文档 18 项 | 里程碑已全部交付完成 |
| `archive/v1.5/` | v1.5.0 升级设计 / 素材清单 / 任务分解 3 项 | 被 v1.6b 系列吸收取代 |

详见 [归档索引](archive/README.md)。
