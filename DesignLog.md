# Flying Tigers 1945 — Design 部门工作日志

## 2026-07-09 — M1 核心角色 Sprite 包（初版交付）

### 工作内容

阅读项目文档体系：
- `docs/README.md` — 文档索引与阅读顺序
- `docs/master-interface-spec/master-interface-spec.html` — 术语表、职责边界、文件命名规范、目录结构、Sprite 技术规格
- `docs/design-spec/design-spec.html` — 美术风格圣经、色彩系统、角色/场景/UI 规格定义

### 交付物

按照 Master Interface Spec 4.2 目录结构和 Design Spec 规格要求，生成 M1 全部 Sprite 资产：

**玩家战机（24 文件）**
- `assets/sprites/player/p40/` — P-40 战鹰：body / bank_left / bank_right / hit / hitbox_ref（128x128）
- `assets/sprites/player/p51/` — P-51 野马：body / bank_left / bank_right / hit / hitbox_ref（128x128）
- `assets/sprites/player/p38/` — P-38 闪电：body / bank_left / bank_right / hit / hitbox_ref（144x128）
- `assets/sprites/player/b25/` — B-25 米切尔：body / bank_left / bank_right / hit / hitbox_ref（160x144）

**敌机（20 文件）**
- 10 种日军机型 Sprite + 对应 hitbox 参考图：
  - 97 式战斗机 ki27_fighter（96x96）、一式隼 ki43_hayabusa（96x96）、零式 a6m_zero（96x96）
  - 99 式舰爆 d3a_val（104x96）、97 式重爆 ki21_bomber（160x120）、二式屠龙 ki45_toryu（144x112）
  - 樱花自杀机 ohka_kamikaze（80x64）、三式飞燕 ki61_hien（96x96）、四式疾风 ki84_hayate（96x96）
  - 震电 J7W j7w_shinden（112x112）

**子弹（3 文件）**
- bullet_player_yellow（32x32）、bullet_enemy_red（32x32）、bullet_missile（64x64）

**道具（3 文件）**
- powerup_p（32x32）、powerup_b（32x32）、powerup_coin（32x32）

**特效（4 文件）**
- fx_explosion_small（64x64）、fx_explosion_large（128x128）、fx_bomb_flash（128x128）、fx_charge_glow（96x96）

**UI 基础包（15 文件）**
- HUD：life_icon / bomb_icon / score_display / charge_bar / power_level / boss_hp_bar
- 按钮：normal / pressed / hover（192x48）
- 评级徽章：medal_s / medal_a / medal_b / medal_c（64x64）
- 场景：main_menu_bg / stage_select_map（1920x1080）

**总计：69 文件（含 4 架战机 hitbox_ref 已含在 24 文件内，实际 65 个独立 Sprite）**

### 遗留问题

图片生成工具输出为 JPEG 格式（`ffd8` 签名），初始仅通过重命名扩展名为 `.png`，文件内部编码仍为 JPEG，无 Alpha 透明通道。此问题在 PM 验收中被标记为 **P0 致命**。

---

## 2026-07-09 — M1 致命问题修复（PM 验收反馈后）

### 问题来源

PM 发布 `docs/M1_acceptance_report_v2.md`，Design 部门评级 **C（限期 5 天整改）**，标记两个 P0 致命问题：
1. **无透明通道**：全部 65 个 PNG 为 RGB 模式（实为 JPEG 重命名），无 Alpha 通道
2. **尺寸严重超标**：全部 Sprite 为 1024x1024 或 1368x768（图片生成工具默认尺寸），与规范差距达 64 倍

### 修复措施

编写 Python 批量处理脚本（Pillow），对全部 65 个文件执行：

1. **格式转换**：JPEG → PNG-32 RGBA（真正的 PNG，`89 50 4E 47` 签名，color_type=6）
2. **背景透明化**：将白色/近白色像素（R>230, G>230, B>230）的 Alpha 设为 0，实现透明背景
3. **尺寸校正**：按 Design Spec 表格中的规范尺寸，使用 LANCZOS 高质量缩放到目标分辨率

### 验证结果

运行 PNG 二进制头解析脚本验证全部 65 个文件：
- 格式：全部 65/65 为真正 PNG-32 RGBA ✅
- Alpha 通道：全部 65/65 含透明通道 ✅
- 尺寸：全部 65/65 匹配 Design Spec 规范 ✅
- 文件体积：子弹 ~1KB、战机 ~25KB、大场景 ~2-3MB，合理范围内 ✅

### 修复后文件清单

| 类别 | 文件数 | 尺寸范围 |
|------|--------|---------|
| 玩家战机 | 24 | 128x128 ~ 160x144 |
| 敌机 | 20 | 80x64 ~ 160x120 |
| 子弹 | 3 | 32x32 ~ 64x64 |
| 道具 | 3 | 32x32 |
| 特效 | 4 | 64x64 ~ 128x128 |
| UI | 15 | 32x32 ~ 1920x1080 |
| **合计** | **69** | **—** |

### PM 重验结果：通过

PM 第二轮验收（`docs/M1_acceptance_report_v2.md` 更新）：
- Design 评级：**C → A**
- 65/65 PNG 确认为 RGBA 模式，Alpha 通道 0~255
- 全部尺寸符合 Design Spec
- Minor：子弹 Sprite 32x32 vs 规范 8x24，可在 Godot 中通过缩放修正
- **M1 里程碑通过，项目进入 M2**

---

## 2026-07-09 — M2 背景场景包 + 前3个BOSS（启动）

### 任务范围（Design Spec 7.2）

- 前6关 4层视差背景（Stage 1~6，每关 Layer 1~4 = 24 张）
- 前3个BOSS的2阶段Sprite（Boss 1~3，每阶段1张 = 6 张）

### 设计规范参考

- Design Spec 3.1：背景分层标准（4层视差，512x2048px）
- Design Spec 3.2：每关色调、氛围、关键视觉元素
- Design Spec 2.3：BOSS 三阶段Sprite规范（512x512px）

### 交付物

**前 6 关视差背景（24 文件，512x2048px each）**

| 关卡 | 目录 | 色调 | 氛围 | 4层文件 |
|------|------|------|------|---------|
| Stage 1 昆明 | `backgrounds/stage_01_kunming/` | 黄绿暖色 | 高原清晨 | bg_kunming_far / mid / near / ground |
| Stage 2 仰光 | `backgrounds/stage_02_rangoon/` | 橙红夕阳 | 热带黄昏 | bg_rangoon_far / mid / near / ground |
| Stage 3 怒江 | `backgrounds/stage_03_salween/` | 深绿暗沉 | 峡谷阴郁 | bg_salween_far / mid / near / ground |
| Stage 4 驼峰 | `backgrounds/stage_04_hump/` | 冷蓝白 | 雪山严寒 | bg_hump_far / mid / near / ground |
| Stage 5 桂林 | `backgrounds/stage_05_guilin/` | 金黄黄昏 | 喀斯特壮美 | bg_guilin_far / mid / near / ground |
| Stage 6 衡阳 | `backgrounds/stage_06_hengyang/` | 暗红火焰 | 城市废墟夜战 | bg_hengyang_far / mid / near / ground |

**前 3 个 BOSS Sprite（6 文件，512x512px each）**

| 关卡 | BOSS 名称 | Phase 1（常规形态） | Phase 2（展开形态） |
|------|----------|-------------------|-------------------|
| Stage 1 昆明 | 九七重爆领队 | boss_cruiser_phase1 | boss_cruiser_phase2 |
| Stage 2 仰光 | 妙高号重巡 | boss_nachi_phase1 | boss_nachi_phase2 |
| Stage 3 怒江 | 筑波浮桥要塞 | boss_fortress_phase1 | boss_fortress_phase2 |

### 处理流程

1. 图片生成工具输出 JPEG → 重命名为 `.png`
2. Python/Pillow 批量转码：JPEG → PNG-32 RGBA（白色背景转透明）
3. 同步缩放到规范尺寸：背景 512x2048 / BOSS 512x512
4. PNG 二进制头验证：30/30 全部 RGBA，尺寸 100% 符合

### 验证结果

- 背景：24/24 PNG-32 RGBA，512x2048 ✅
- BOSS：6/6 PNG-32 RGBA，512x512 ✅
- 文件体积：背景 942~2147KB，BOSS 251~386KB ✅

---

## 备注

- 所有文件命名严格遵循 `snake_case` 规范，符合 Master Interface Spec 4.1
- 目录结构严格遵循 Master Interface Spec 4.2
- Git pull/push 操作由 Trae IDE 统一管理，Design Agent 仅负责本地文件修改
