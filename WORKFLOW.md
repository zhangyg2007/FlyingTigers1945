# Flying Tigers 1945 — 三方协作工作流规范

> 本文档定义 Work Agent(PM) / Code Agent / Design Agent 三个角色的协作规则。
> **所有 Agent 必须在开始工作前阅读本文档。**

---

## 角色与职责

| 角色 | 部门 | 核心职责 | 日志文件 |
|------|------|---------|---------|
| **Work Agent** | PM / 项目管理 | 需求拆解、任务分配、验收交付物、出具验收报告 | `docs/M*_acceptance_report.md` |
| **Code Agent** | 研发部 | Godot 4.7 编码、.gd脚本、.tscn场景、技术调试 | **`Devlog.md`** |
| **Design Agent** | 美工部 | Sprite/UI素材制作、动画帧序列、美术规范 | **`DesignLog.md`** |

---

## 工作目录

三个 Agent 共享同一个 Git 仓库目录：

```
D:\WORKSPACE\Godot\MYgame\FlyingTigers1945\
├── Devlog.md          ← Code Agent 维护（代码改动记录）
├── DesignLog.md       ← Design Agent 维护（美术改动记录）
├── docs/              ← Work Agent 维护（验收报告、设计文档）
├── autoload/          ← Code Agent
├── scenes/            ← Code Agent（脚本+场景）
├── scripts/           ← Code Agent
├── assets/sprites/    ← Design Agent（所有PNG素材）
├── resources/         ← 双方共用（Code写配置，Design参考）
└── ...
```

---

## 每次任务的标准流程

```
1. Work Agent 分配任务 → 给出具体需求 + 验收标准
        ↓
2. Code / Design Agent 领取任务，在各自日志中记录任务开始
        ↓
3. 执行工作（修改/创建文件）
        ↓
4. 在各自日志中记录：改了什么文件、做了什么、发现什么问题
        ↓
5. git add . && git commit && git push
        ↓
6. Work Agent 拉取最新代码，按 Acceptance Checklist 验收
        ↓
7. Work Agent 出具验收报告到 docs/ 目录，推送至 GitHub
```

---

## 日志格式要求

### Devlog.md（Code Agent）

每次任务追加一个章节，格式：

```markdown
## 任务 N：[任务标题]

**日期**: YYYY-MM-DD
**目标**: [一句话描述]

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

### DesignLog.md（Design Agent）

每次任务追加一个章节，格式：

```markdown
## 任务 N：[任务标题]

**日期**: YYYY-MM-DD
**目标**: [一句话描述]

### 产出文件
- `assets/sprites/player/p40/player_p40_body.png` — 新建，1024x1024 RGBA
- `assets/sprites/enemy/enemy_ki27_fighter.png` — 新建，96x96 RGBA

### 设计说明
[色彩、风格、尺寸选择的原因]

### 技术规格
- 格式：PNG-24 (RGBA)
- 尺寸：128x128 px
- 背景：透明
- 参考文档：docs/design-spec/design-spec.html 第2章

### 已知问题
[如有不符合规范的地方，主动记录]
```

---

## Git 操作规范

每个 Agent 每次完成工作后必须执行：

```powershell
git add .
git commit -m "[部门缩写] M[N]: [简要描述]"
# 部门缩写：CODE / DESIGN / PM
git push origin main
```

Commit message 示例：
- `CODE M1: 创建玩家战机P40场景预制件`
- `DESIGN M1: 重新导出全部Sprite为RGBA + 正确尺寸`
- `PM M1: 验收报告v2 - Design C级 / Code B级`

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
| `docs/` | **Work Agent** 专属 | 双方只读参考 |
| `Devlog.md` | **Code Agent** 专属 | — |
| `DesignLog.md` | **Design Agent** 专属 | — |
| `project.godot` | **Code** 专属 | — |

如果需要修改对方负责的文件，必须在日志中记录并说明原因。

---

## 验收标准

Work Agent 按 `docs/acceptance-checklist/acceptance-checklist.html` 逐项验收。

### Design 验收重点
- PNG 格式：必须是 **RGBA（有透明通道）**
- 尺寸：必须符合 Design Spec 规定
- 命名：必须符合 Master Interface Spec（snake_case）
- 数量：必须符合交付清单
- Godot 导入：Work Agent 拉取后用 Godot 打开验证无报错

### Code 验收重点
- .tscn 场景文件：脚本已挂载、节点树正确
- 语法检查：`godot --check-only` 通过
- 运行测试：场景可在 Godot 中运行无崩溃
- Devlog.md：每次任务有完整记录

### 评级标准
- **A级**：100%通过 → 直接进入下一阶段
- **B级**：≥90%通过 → 限期2天整改
- **C级**：≥75%通过 → 限期5天整改
- **D级**：<75%通过 → 退回重做

---

## 文档同步规范（重要）

**所有新增/修改的任务文档必须同步到 GitHub 仓库，确保 Code 和 Design Agent 都能读取最新文档。**

### 文档同步规则

1. **Work Agent (PM)** 每次出具验收报告、修正方案、任务分配文档后，必须 `git push` 到 GitHub
2. **Code Agent** 每次更新 Devlog.md 后，必须 `git push` 到 GitHub
3. **Design Agent** 每次更新 DesignLog.md 后，必须 `git push` 到 GitHub
4. **三方在开始新任务前，必须先 `git pull` 拉取最新代码和文档**

### 不可提交的临时文件

以下文件类型**禁止提交到 GitHub**（应在 `.gitignore` 中排除）：
- `*.log` — 运行日志、测试日志
- `*_result.txt` — 测试输出
- `.godot/` — Godot 编辑器缓存
- `*.import` — Godot 导入缓存
- `__pycache__/` — Python 缓存

### .gitignore 必须包含

```
*.log
*_result.txt
.godot/
*.import
__pycache__/
```

| 里程碑 | 状态 | Design | Code |
|--------|------|--------|------|
| M1 核心原型 | **已通过** | A级 ✅ | A级 ✅ |
| M2 关卡+BOSS | **已通过** | A-级 ✅ | A级 ✅ |
| M3 完整系统 | 🚀 建议启动 | — | — |
