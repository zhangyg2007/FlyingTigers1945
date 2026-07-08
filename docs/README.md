# Flying Tigers 1945 — 项目文档索引

## 文档列表

| 文档 | 面向部门 | 说明 | 必读 |
|------|---------|------|------|
| **master-interface-spec** | Design + Code 双方 | 唯一真理源：术语表、职责边界、文件命名规范、数据接口 | **双方必须先读** |
| **design-spec** | Design 部门 | 美术设计规范：色彩系统、角色/场景/UI规格、特效分级、交付清单 | Design 必读 |
| **tech-spec** | Code 部门 | 技术设计文档：Godot 4.7架构、类设计、性能预算、测试策略 | Code 必读 |
| **acceptance-checklist** | PM 验收 | 交付物验收标准：检查项、评分标准、手感评分、争议裁决 | PM 使用 |
| **flying-tigers-gdd** | 全员参考 | 完整游戏设计文档(GDD)：历史背景、12+4关设计、数值体系 | 可选参考 |

## 阅读顺序

### Design Agent
1. master-interface-spec → 了解术语和职责边界
2. design-spec → 执行美术任务
3. flying-tigers-gdd → 需要了解关卡/BOSS具体内容时查阅

### Code Agent
1. master-interface-spec → 了解术语和职责边界
2. tech-spec → 执行开发任务
3. flying-tigers-gdd → 需要了解关卡设计细节时查阅

## 里程碑交付时间线

- **M1（第1~2周）**：Design → 核心角色Sprite + UI基础包 / Code → 核心玩法原型
- **M2（第3~4周）**：Design → 前6关背景 + 前3个BOSS / Code → 关卡系统 + BOSS战
- **M3（第5~6周）**：Design → 全部内容包 / Code → 完整系统 + 平台集成
