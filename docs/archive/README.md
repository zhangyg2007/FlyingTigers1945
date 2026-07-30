# 归档文档索引（ARCHIVED）

> **归档日期**: 2026-07-30
> **归档原因**: 游戏主要框架和规则已搭建成型（v1.5 完成全部 16 关 + 深渊模式 + 存档/排行榜），
> 初版设计基本完成。以下文档为 v1.0~v1.5 阶段的设计与验收记录，已被 v1.6b 系列文档取代或吸收，
> 保留作历史参考，不再作为开发依据。
> **当前活跃文档**: 见上级目录 `docs/README.md`

---

## 目录结构

```
docs/archive/
├── foundation-v1.0/     # v1.0 基础规范（框架搭建阶段）
├── milestones/          # M1/M2/M3 里程碑验收报告（已完成）
└── v1.5/                # v1.5 过渡设计（已被 v1.6b 取代）
```

---

## 1. foundation-v1.0/ — v1.0 基础规范

游戏立项初期的框架性规范文档，确立了术语表、职责边界、美术风格、技术架构和关卡数值体系。
这些规范在 M1~M3 开发期间作为"唯一真理源"指导了框架搭建，现已完成历史使命。

| 文档 | 版本 | 原用途 | 取代关系 |
|------|------|--------|---------|
| `master-interface-spec/` | v1.0 | Design+Code 双方术语表/职责边界/文件命名/数据接口 | 框架已落地为代码，命名规范沿用至今 |
| `design-spec/` | v1.0 | Design 部门美术规范：色彩/角色/场景/UI/特效/交付清单 | 美术风格圣经，核心规范被外包 spec 继承 |
| `tech-spec/` | v1.0 | Code 部门技术文档：Godot 4.7 架构/类设计/性能预算 | 架构已实现，技术细节见代码与 v1.6 设计文档 |
| `flying-tigers-gdd/` | v1.0 | 完整 GDD：历史背景/12+4关/数值体系 | 关卡设计被 `v1.6b-level-design-spec` 取代 |
| `acceptance-checklist/` | v1.0 | PM 验收标准：检查项/评分/手感/争议裁决 | M1~M3 验收已完成 |
| `claude_GDD_reference_v1.0.md` | v1.0 | Claude 生成的 GDD 参考稿 | 被 `flying-tigers-gdd.html` 整合 |
| `design_art_style_guide.md` | v1.0 | 美术风格指南（基于参考图提炼） | 风格定位被 `design-spec.html` §1 Art Bible 承载 |
| `SD_asset_checklist.md` | v1.0 | 旧版 221 素材检查清单 | 被 `v1.5_asset_master_list` 及 v1.6 尺寸规范取代 |

---

## 2. milestones/ — M1/M2/M3 里程碑验收报告

M1~M3 全部子里程碑已交付验收，以下为各阶段的验收报告与设计任务文档。
这些文档记录了开发过程中的决策与问题修复，保留作开发历史追溯。

### M1 阶段（第1~2周：核心原型）
| 文档 | 说明 |
|------|------|
| `M1_acceptance_report.md` | M1 验收报告 v1 |
| `M1_acceptance_report_v2.md` | M1 验收报告 v2 |

### M2 阶段（第3~4周：关卡系统 + BOSS 战）
| 文档 | 说明 |
|------|------|
| `M2_acceptance_report.md` | M2 总体验收报告 |
| `M2_BCD_acceptance_report.md` | M2-BCD 验收报告 |
| `M2_BCD_acceptance_report_v2.md` | M2-BCD 验收报告 v2 |
| `M2_P1_acceptance_report.md` | M2-P1 验收报告 |
| `M2 任务代码整体评审报告.md` | M2 代码整体评审 |
| `M2_correction_perspective_plan.md` | 透视修正计划 |
| `M2_perspective_correction_prompts.md` | 透视修正提示词 |

### M3 阶段（第5~6周：完整系统 + 平台集成）
| 文档 | 说明 |
|------|------|
| `M3_task_breakdown.md` | M3 任务分解 |
| `M3_design_assignment.md` | M3 Design 任务分配 |
| `M3_event_system_design.md` | 事件系统设计（已实现为 EventManager） |
| `M3_A_acceptance_report.md` | M3-A 验收报告 |
| `M3_BD_acceptance_report.md` | M3-BD 验收报告 |
| `M3_CE_acceptance_report.md` | M3-CE 验收报告 |
| `M3_G_map_design.md` | M3-G 地图设计（渲染方案被 v1.6 取代） |
| `M3_G_Phase1_acceptance_report.md` | M3-G Phase1 验收报告 |
| `M3_F_supplement_design.md` | M3-F 补充设计：军衔系统+4隐藏情报（被 v1.6b 演进取代） |

> **注**: `M3_F_supplement_design.md` 和 `M3_event_system_design.md` 仍被 `v1.6b-level-design-spec`
> 作为"演进来源"引用，但当前生效的设计以 v1.6b 附录为准。

---

## 3. v1.5/ — v1.5 过渡设计

v1.5 阶段的设计升级文档，将游戏从"M3 完成状态"升级为"16关+深渊+存档+排行榜"的完整形态。
核心设计内容（隐藏情报牛皮纸袋系统、Boss 重设计、友军保护等）已被 v1.6b 系列吸收和演进。

| 文档 | 版本 | 原用途 | 取代关系 |
|------|------|--------|---------|
| `v1.5.0_upgrade_design.md` | v1.5 | 关卡重排+Boss重设计+隐藏情报系统+友军保护 | 情报系统被 `v1.6b-level-design-spec` 附录14b 定稿取代；Boss 设计被 v1.6b 各关卡章节取代 |
| `v1.5_asset_master_list.md` | v1.5.1 | v1.5 素材总清单（800x2400 规格） | 地图尺寸被 `v1.6_map_rendering_design.md` 改为 1080x4800，旧规格 deprecated |
| `v1.5_task_breakdown.md` | v1.5 | v1.5 任务分解（C11~C20/D6~D9） | v1.5 全部任务已交付完成 |

> **注**: `v1.5.0_upgrade_design.md` §18（牛皮纸袋情报系统）仍被 `v1.6b-level-design-spec` 附录14b
> 引用为"设计源"，但当前生效的情报机制以 v1.6b 附录14b 定稿为准。

---

## 归档规则

1. **不再更新**: 归档文档不再维护，如有设计变更请在对应 v1.6b 活跃文档中更新
2. **保留引用**: 活跃文档中对归档文档的"演进来源"引用保持不变，指向此归档目录
3. **历史追溯**: 如需了解设计演进历史（如 4 隐藏关 → 2 隐藏关的合并过程），可查阅本目录
4. **复活机制**: 如某归档文档的设计需要重新启用，将其复制回 `docs/` 并更新版本号
