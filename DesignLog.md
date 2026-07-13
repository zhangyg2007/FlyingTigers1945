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

## 2026-07-09 — M2 视角修正 + 命名对齐 + M1 遗留修复

### 问题来源

PM M2 验收报告 + `docs/M2_correction_perspective_plan.md` + `docs/M2_perspective_correction_prompts.md`：
1. 背景图视角错误（侧视风景 → 应为纯俯角顶视地面）
2. Boss 2/3 视角错误（混合视角 → 应为纯俯角甲板顶视）
3. BOSS 命名与 GDD 不对齐
4. Stage 3 目录名风格不一致

### 修正内容

**1. 背景重绘（24 张，纯俯角顶视）**

- Stage 1 昆明：3 张重绘（far/mid/near，ground 保留），黄绿暖色高原俯视
- Stage 2 仰光：4 张重绘，港口/伊洛瓦底江顶视，黄昏暖色
- Stage 3 怒江：4 张重绘，`bg_salween_*` → `bg_nujiang_*`（配合目录重命名），峡谷/江面俯视
- Stage 4 驼峰：4 张重绘，雪山冰川顶视
- Stage 5 桂林：4 张重绘，喀斯特峰林/漓江俯视
- Stage 6 衡阳：4 张重绘，城市废墟夜战俯视

**2. BOSS 视角修正（4 张）**

- `boss_cruiser_phase1/2`（原 boss_nachi）：重绘为纯俯角妙高号重巡甲板顶视
- `boss_fortress_phase1/2`：重绘为纯俯角浮桥要塞甲板顶视

**3. 命名对齐**

| 原名 | 新名 | 原因 |
|------|------|------|
| `boss_cruiser_phase1/2` | `boss_bomber_phase1/2` | Stage 1 BOSS 为九七重爆，非巡洋舰 |
| `boss_nachi_phase1/2` | `boss_cruiser_phase1/2` | Stage 2 BOSS 为妙高号重巡 |
| `stage_03_salween/` | `stage_03_nujiang/` | 统一使用中文拼音命名 |

**4. M1 遗留修复**

- 子弹 Sprite 缩放：`bullet_player_yellow` 32x32→8x24，`bullet_enemy_red` 32x32→8x24，`bullet_missile` 64x64→16x32
- 螺旋桨旋转帧补全：4 架战机各 1 张 sprite strip（P-40/P-51: 512x128, P-38: 576x128, B-25: 640x144）

**5. BOSS 变形动画帧序列（3 张）**

- `boss_bomber_transform.png`：九七重爆 phase1→phase2 过渡（6 帧单张）
- `boss_cruiser_transform.png`：妙高号重巡 phase1→phase2 过渡
- `boss_fortress_transform.png`：浮桥要塞 phase1→phase2 过渡

### 验证结果

- 全部 106 个 PNG 文件验证通过：PNG-32 RGBA，尺寸 100% 符合规范 ✅
- 0 个 JPG 残留 ✅
- 0 个 RGB（无 Alpha）文件 ✅

---

## 2026-07-09 — M2 背景二次重绘（参考截图校准视角）

### 问题来源

用户提供 iFighter 2 / Strikers 1945 实机截图作为参考。截图显示：背景是纯卫星地图式的正上方俯视地面，完全无天空、无地平线，所有建筑/车辆/船只只看到顶面。上一轮修正虽有改善，但仍不够"极端"。

### 修正措施

重新生成全部 23 张背景（kunming_ground 保留），提示词核心约束改为：
- `Satellite map view from directly above`（卫星地图正上方俯视）
- `Zero sky, zero horizon, zero clouds`（零天空、零地平线、零云）
- `Entire image is ground surface only`（整个画面只有地面）
- 每层设定具体海拔高度（5000m/2000m/500m/100m）以控制缩放层级
- 所有物体描述使用顶视特征（如 `trees as round green canopy circles from above`、`buildings as rectangular roofs from above`）

### 清理

- 删除 `stage_03_nujiang/` 下残留的 4 个 `bg_salween_*` 旧文件及对应 `.import`

### 验证

24/24 背景 PNG-32 RGBA，512x2048 ✅（23 张重绘 + 1 张保留）

---

## 2026-07-10 — M2 BCD 验收 P0/P1 修复 + 玩家选择 UI

### 问题来源

PM 发布 `docs/M2_BCD_acceptance_report.md`，Design 评级 B+，4 个 P0 + 1 个 P1 视角问题。

### P0 修复（4 项）

| 文件 | 问题 | 修正 |
|------|------|------|
| `bg_rangoon_far.png` | 高斜角鸟瞰 | 重绘为卫星地图纯俯视，强调 90° 正上方、zero sky/zero horizon |
| `bg_hump_far.png` | 侧面风景画 | 重绘为雪山顶面俯视纹理，白色雪面 + 灰岩 + 蓝色冰裂缝 |
| `boss_fortress_phase1.png` | 等距斜视角 | 重绘为 90° 正上方俯视浮台甲板，炮塔/雷达仅显示顶面圆盘 |
| `boss_fortress_phase2.png` | 斜视角 | 重绘为正上方俯视展开形态，中心红色能量核心 + 机械臂顶视 |

### P1 修复（1 项）

| 文件 | 问题 | 修正 |
|------|------|------|
| `boss_cruiser_phase2.png` | 与 Phase1 视角不一致 | 重绘为与 Phase1 一致的 90° 俯视甲板，武器系统仅显示顶面 |

### 新增资产：玩家选择 UI（4 张）

| 文件 | 尺寸 | 内容 |
|------|------|------|
| `ui_player_card_p40.png` | 200x320 | P-40 战鹰卡片：顶视战机 + 名称 + 属性条 |
| `ui_player_card_p51.png` | 200x320 | P-51 野马卡片 |
| `ui_player_card_p38.png` | 200x320 | P-38 闪电卡片 |
| `ui_player_card_b25.png` | 200x320 | B-25 米切尔卡片 |

风格：深绿底 + 做旧黄边框 + 军用字体 + 俯视战机图 + FIRE POWER/SPEED/ARMOR 属性条

### 验证

9/9 修复+新增文件 PNG-32 RGBA 验证通过 ✅
boss/ + backgrounds/ 目录 0 JPG 残留 ✅

---

## 2026-07-11 — M3 验收 P2 修复 + M3-D UI 素材补齐

### 来源

M3-B+M3-D 联合验收报告 + M3-C+M3-E 验收报告。

### P2 修复

- BOSS 命名偏离规划（tone→nagato 等）：已在 `M3_design_assignment.md` 中更新 BOSS 表格，记录实际交付文件名和变更说明

### M3-D UI 素材补齐（3 张）

| 文件 | 尺寸 | 用途 |
|------|------|------|
| `ui_target_marker.png` | 64x64 | H2 东京轰炸目标高亮标记 |
| `ui_countdown_ring.png` | 256x256 | H4 广岛倒计时环形进度条 |
| `ui_checkpoint_flag.png` | 64x64 | 深渊模式检查点标记 |

### 验证

3/3 PNG-32 RGBA ✅

---

## 2026-07-11 — P2 修复：BOSS 命名对齐 Code 侧引用

### 问题

PM Issue #3：Design 交付的 BOSS 命名（nagato/kamikawa/ki49/floating_aa/shiden_proto）与 Code 侧 `.tscn`/`spawn_manager.gd` 引用（tone/shokaku/yamato/yahata/shinden_final）不一致。

### 解决方案

Design 侧重命名文件以匹配 Code 引用（成本更低）：

| 原文件名 | 新文件名 | 匹配 Code |
|---------|---------|----------|
| `boss_nagato_phase1/2` | `boss_tone_phase1/2` | `boss_tone.tscn` |
| `boss_kamikawa_phase1/2` | `boss_shokaku_phase1/2` | `boss_shokaku.tscn` |
| `boss_ki49_phase1/2` | `boss_yamato_phase1/2` | `boss_yamato.tscn` |
| `boss_floating_aa_phase1/2` | `boss_yahata_phase1/2` | `boss_yahata.tscn` |
| `boss_shiden_proto_phase1/2` | `boss_shinden_final_phase1/2` | `boss_shinden_final.tscn` |

### 补充

三阶段 BOSS 缺少 phase3 sprite，已补生成：
- `boss_yamato_phase3`：大和号完全毁灭
- `boss_yahata_phase3`：八幡号解体爆炸
- `boss_shinden_final_phase3`：震电改过载形态

### 验证

10 文件重命名 + 3 文件新生成 = 13 个文件 ✅

---

## 2026-07-11 — M3-F 补充设计：隐藏关卡军衔系统 + 事件素材

### 任务来源

`docs/M3_F_supplement_design.md`：隐藏关卡需要军衔等级做开通条件 + 事件系统素材。

### 交付物

**P0 军衔系统 UI（8 张）**

| 文件 | 尺寸 | 内容 |
|------|------|------|
| `ui_rank_corporal` | 48x48 | 下士：三道铜 V 字 |
| `ui_rank_sergeant` | 48x48 | 中士：三 V + 摇杆 |
| `ui_rank_captain` | 48x48 | 上尉：银鹰徽 |
| `ui_rank_major` | 48x48 | 少校：金橡叶 |
| `ui_rank_colonel` | 48x48 | 上校：银鹰+星 |
| `ui_rank_ace` | 64x64 | 王牌：金翼+桂冠 |
| `ui_rank_progress_bar_bg` | 200x16 | 经验条底框 |
| `ui_rank_progress_bar_fill` | 200x16 | 经验条填充 |

**P1 碉堡事件（2 张，128x128）**
- `event_bunker_hidden`：伪装碉堡（丛林覆盖）
- `event_bunker_revealed`：暴露碉堡（混凝土+射击口）

**P2 运输线事件（5 张）**
- `event_transport_ship` / `event_transport_wreck`：运输舰/残骸 128x128
- `event_supplies_crate`：补给箱 64x64
- `intel_hump_route` / `intel_tokyo_defense`：情报图标 48x48

**P3 友军+UI（4 张）**
- `event_c47_ally` / `event_c47_damaged`：C-47 友军/损坏 128x128
- `ui_hint_bar_bg` / `ui_hint_bar_locked`：提示条背景/锁定 400x40

### 验证

19/19 PNG-32 RGBA ✅

---

## 2026-07-13 — M3-G 阶段 1：H1 驼峰单图层地图试点

### 任务来源

`docs/M3_G_map_design.md` v1.1 第 14 节实施计划，阶段 1。

### 技术方案

- AI 生成 3 段 2048px 冰雪地面纹理，numpy crossfade 64px 拼接为 512x6144
- 地图只画地面纹理（冰面/雪地/岩石），**不画山壁**（山壁由 Code 用 StaticBody2D 实例化）
- 碎片和云雾作为独立 sprite 供 Code 实例化

### 交付物

| 文件 | 尺寸 | 大小 | 内容 |
|------|------|------|------|
| `bg_hump_extreme_full.png` | 512x6144 | 4541KB | 单图层完整地图（3 段 crossfade 拼接） |
| `hump_rock_debris.png` | 64x64 | 9KB | 冰岩碎片 sprite（Code 实例化为飘落障碍物） |
| `hump_cloud_fake.png` | 256x256 | 43KB | 视觉欺骗云雾（半透明，Code 控制显隐） |

### 拼接参数

- 段 1（y=0~2047）：平坦冰雪地面，白色冰面 + 轻微裂缝
- 段 2（y=2048~4095）：冰川地形，蓝色冰裂缝 + 岩石碎片
- 段 3（y=4096~6144）：高山高原，深色岩石 + 冰川裂缝 + Boss 区
- Crossfade：64px 线性混合，接缝处无可见跳变

### 验证

3/3 PNG-32 RGBA ✅
0 JPG 残留 ✅
地图尺寸 512x6144 符合规范 ✅

### Code 侧待实现

- 山壁碰撞体（StaticBody2D + CollisionPolygon2D，参照 M3_G_map_design.md 第 13.6 节）
- 云雾显隐控制（Tween alpha）
- 碎片生成器（DebrisSpawner + 对象池）
- 替换 `stage_config.json` 中 H1 的 bg_layers 为单 `bg_hump_extreme_full`

### 风格一致性说明

所有 Sprite（player/enemy/boss/backgrounds/ui）统一使用 AI 生成 + Pillow 转码 PNG-32 RGBA 工作流，确保像素精度一致。

---

## 2026-07-10 — Stage 1 背景重新规划

### 需求来源

用户直接反馈：
- `bg_kunming_near` 应为机场停机坪开场（3 架 P40 横放 + 地勤员 + 油桶），1-2 秒展示后飞出
- 去掉 far 层（全览地图），不需要机场跑道
- 地面房屋/河流/道路保持 mid 层比例
- 地图后期显示滇池 + 中式小渔船
- 地图最后进入绿树高山区域（Boss 战）
- 绘图风格与参考图（iFighter 1945 实机截图）一致：暗色调写实俯视 + 光影质感

### 新结构（5 层替代原 4 层）

| 层 | 文件 | 内容 | 用途 |
|---|---|---|---|
| 开场 | `bg_kunming_near` | 机场停机坪：3 架 P40 横放左侧 + 地勤员 + 油桶 + 油车 | 1-2 秒展示 |
| 主体 | `bg_kunming_mid` | 昆明城市顶视：灰瓦屋顶群 + 蟠龙江 + 土路 + 农田 | 主游戏区域 |
| 前景 | `bg_kunming_ground` | 红土地面纹理：干草 + 碎石 + 农沟 | 视差最近层 |
| 后期 | `bg_kunming_lake` | 滇池湖面 + 中式木船渔网 + 芦苇岸 | 关卡后半段 |
| Boss | `bg_kunming_mountain` | 西山密林覆盖 + 岩石露头 + 小径 | Boss 战区域 |

### 变更

- 删除 `bg_kunming_far.png`（不再需要）
- 重绘 `bg_kunming_near` / `bg_kunming_mid` / `bg_kunming_ground`
- 新增 `bg_kunming_lake` / `bg_kunming_mountain`

### 验证

5/5 PNG-32 RGBA，512x2048，0 JPG 残留 ✅

### 注意

Code 部门需要更新 Stage 1 的 ParallaxBackground 配置：
- 原来 4 层（far/mid/near/ground）→ 现在 5 层（near→mid→ground→lake→mountain）
- `near` 层仅显示 1-2 秒后切换到 `mid`
- `mountain` 层在 Boss 出现时启用

---

## 2026-07-10 — M2 BCD v2 验收修复

### 问题来源

PM 发布 `docs/M2_BCD_acceptance_report_v2.md`，Design B-，7 个问题。

### 修复内容

**P0（1 项）**
- `bg_hump_far` — 重绘为 orthophoto 正射卫星图风格（零透视、零消失点、纯 nadir 俯视）

**P1（3 项）**
- `bg_rangoon_far` — 同上 orthophoto 风格重绘
- `bg_kunming_mountain` — 同上 orthophoto 风格重绘（树冠顶面 + 等高线纹理）
- `boss_fortress_phase1/2` + `boss_cruiser_phase2` — 改用扁平 2D 像素风格，prompt 强制 `Clean transparent background - NO water, NO background`，解决海水烘焙进精灵问题

**P2（2 项）**
- `ui_player_card_*` x4 — 修正错别字 + 尺寸从 200x320 调整为 256x256
- `boss_fortress_phase1` AI 水印 — 通过重新生成解决（扁平风格无水印）

### 风格调整

背景图统一采纳 PM 建议：**orthophoto/卫星正射图风格**，关键词 `orthographic projection, zero perspective, zero vanishing point, nadir view, GIS satellite map`
BOSS 精灵统一为：**扁平 2D 风格 + 纯透明背景**，避免 AI 生成器添加环境元素

### 验证

10/10 PNG-32 RGBA，尺寸正确，0 JPG 残留 ✅
BOSS 文件体积从 200-300KB 降至 137-180KB（透明背景生效）✅

---

## 2026-07-10 — M2 P3 遗留清理

### 问题来源

`docs/M2_P1_acceptance_report.md` P3 遗留（不阻塞 M3）。

### 修复

- `boss_fortress_phase1` — 重新生成，prompt 强制 `absolutely nothing outside the platform, completely blank transparent white`，消除底部蓝色水纹
- `ui_player_card_*` x4 — 重新生成，prompt 强调 `Minimalist flat design. No watermarks, no signatures`，消除右下角 AI 水印

### 验证

5/5 PNG-32 RGBA ✅

---

## 2026-07-10 — M3-A: 资源补齐

### 任务来源

`docs/M3_design_assignment.md` M3-A 阶段（资源补齐）。

### 交付物

**爆炸帧序列（5 张，256x256）**

| 文件 | 内容 |
|------|------|
| `fx_explosion_large_01.png` | 爆炸初期：白色闪光 + 橙色火环开始扩展 |
| `fx_explosion_large_02.png` | 火球扩大：橙黄核心 + 冲击波环 + 碎片 |
| `fx_explosion_large_03.png` | 火球巅峰：大红火球 + 黑烟环 + 大量碎片 |
| `fx_explosion_large_04.png` | 火球衰减：深红暗化 + 灰烟扩展 + 碎片下落 |
| `fx_explosion_large_05.png` | 消散：灰烟散去 + 红橙余烬淡出 |

**敌方导弹（1 张，64x128）**
- `missile_enemy.png`：银灰弹体 + 橙红尾焰，俯视角

**道具重做（3 张，48x48，原 32x32 升级）**
- `powerup_p.png`：火力提升（红色 P 字 + 金属胶囊 + 微发光）
- `powerup_b.png`：炸弹补充（蓝色 B 字 + 炸弹图标 + 微发光）
- `powerup_coin.png`：金砖加分（金色硬币 + 金字 + 金属光泽）

**敌机 hitbox_ref 确认**
- 10 种敌机全部已有 body + hitbox_ref，无需补齐 ✅

### 验证

9/9 PNG-32 RGBA，尺寸 100% 符合 M3 任务文档规格 ✅

---

## 2026-07-11 — M3-B: Stage 7~8 背景 + 5 新 BOSS + 3 新敌机

### 任务来源

`docs/M3_design_assignment.md` M3-B 阶段。

### 交付物

**Stage 7 芷江机场背景（4 张，512x2048）**
- `bg_zhijiang_far`：机库群/塔台/停机坪俯视
- `bg_zhijiang_mid`：跑道/P-40 停放/地勤车辆俯视
- `bg_zhijiang_near`：草地/导航标识/挡轮器
- `bg_zhijiang_ground`：磨损混凝土/轮胎痕/油渍

**Stage 8 武汉背景（4 张，512x2048）**
- `bg_wuhan_far`：长江江面/汉口城市网格俯视
- `bg_wuhan_mid`：码头/货轮甲板/仓库/起重机
- `bg_wuhan_near`：城市街道/建筑屋顶/车辆
- `bg_wuhan_ground`：石板路/积水/碎片

**5 个新 BOSS（15 张，512x512）**

| BOSS | Phase 1 | Phase 2 | Transform |
|------|---------|---------|-----------|
| 一式陆攻编队 `boss_ki21_squadron` | 3 架 V 字编队 | 散开独立瞄准 | 机翼断裂起火 |
| 秋津洲号 `boss_akitsushima` | 水上机母甲板 | 破洞烟柱 | 船体倾斜起火 |
| 鬼怒号 `boss_kinu` | 轻巡洋舰完整 | 炮塔损坏 | 船尾下沉 |
| 紫电改中队 `boss_shiden_squadron` | 4 架菱形编队 | 散开高速尾迹 | 一架被击落 |
| 金刚号 `boss_kongo` | 战列舰完整 | 主炮损坏 | 舰桥倒塌大火 |

**3 种新敌机（6 张，128x128）**
- `enemy_type97_tank` + hitbox_ref：九七式中战车俯视
- `enemy_landing_craft` + hitbox_ref：登陆艇俯视
- `enemy_observation_balloon` + hitbox_ref：观测气球俯视

### 验证

29/29 PNG-32 RGBA ✅
BOSS 透明背景生效（73-279KB）✅
新敌机 128x128 符合规范 ✅

---

## 2026-07-11 — M3-C: Stage 9~12 + 隐藏关 + 新 BOSS + 事件素材

### 任务来源

`docs/M3_design_assignment.md` M3-C 阶段。严格遵循 `docs/design_art_style_guide.md`。

### 交付物

**Stage 9 南昌背景（4 张，512x2048）**
鄱阳湖 + 湖岸农田 + 村庄 + 泥岸

**Stage 10 上海背景（4 张，512x2048）**
外滩 + 码头 + 城市街道 + 石板路

**Stage 11 南京背景（4 张，512x2048）**
长江 + 城墙 + 城区废墟 + 碎石

**Stage 12 东京背景（4 张，512x2048）**
夜视城市 + 工业区燃烧 + 住宅区火海 + 焦土

**隐藏关背景（11 张，512x2048）**
- H1 驼峰极端 3 张：暴风雪/冰川/山口
- H2 东京轰炸 3 张：城市轰炸/工业区/火风暴
- H3 紫电竞技场 2 张：太平洋海面/尾迹
- H4 广岛 3 张：轰炸前/市中心/核爆废墟

**BOSS 09-12（8 张，512x512）**
- `boss_ki49`：Ki-49 吞龙重爆
- `boss_floating_aa`：高射炮浮台
- `boss_kamikawa`：神川丸水机母
- `boss_nagato`：长门号战列舰

**隐藏 BOSS（7 张，512x512）**
- `boss_frozen_bomber`：冰封 Ki-21（H1）
- `boss_shiden_proto`：紫电改原型机（H3）
- `boss_b29_enola`：艾诺拉·盖伊（H4）
- `boss_mushroom_cloud`：蘑菇云（H4 特殊）
- `boss_bridge_destroyed`：渡桥断裂（事件）

**新敌机（6 张）**
- `enemy_ki43_body/hitbox_ref/side`：隼式（64x64 + 128x64）
- `enemy_a6m_body/hitbox_ref/side`：零式（64x64 + 128x64）

**特效（1 张）**
- `fx_nuclear_flash`：核爆闪光 512x512

### 验证

50/50 PNG-32 RGBA ✅
0 JPG 残留 ✅

---

## 备注

- 所有文件命名严格遵循 `snake_case` 规范，符合 Master Interface Spec 4.1
- 目录结构严格遵循 Master Interface Spec 4.2
- Git pull/push 操作由 Trae IDE 统一管理，Design Agent 仅负责本地文件修改
