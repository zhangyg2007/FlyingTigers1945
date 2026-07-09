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

### 待 PM 重验

修复后的文件已写入本地 `assets/sprites/` 目录，等待 Trae IDE 执行 git push 到远程仓库后，由 PM Agent 进行第二轮验收。

---

## 备注

- 所有文件命名严格遵循 `snake_case` 规范，符合 Master Interface Spec 4.1
- 目录结构严格遵循 Master Interface Spec 4.2
- Git pull/push 操作由 Trae IDE 统一管理，Design Agent 仅负责本地文件修改
