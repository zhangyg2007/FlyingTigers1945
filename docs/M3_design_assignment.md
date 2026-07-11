# Flying Tigers 1945 — Design 部门 M3 专属任务安排

> **版本**: v1.1  
> **日期**: 2026-07-11  
> **接收人**: Design Agent  
> **关联文档**: `docs/M3_task_breakdown.md`（总体分解）、`docs/design-spec/design-spec.html`（美术规范）
> **必读**: `docs/design_art_style_guide.md`（**美术风格规范 v1.0 — 基于用户参考图提炼，立即生效**）

---

## 1. 任务总览

M3 期间 Design 部门需交付 **约 170+ 张 PNG 素材**，分为 5 个子里程碑依次推进。本文档给出每一批次任务的：
- 具体文件清单（含命名、尺寸、格式）
- AI 生成提示词建议（保持风格统一）
- 与 Code 部门的对接要点
- 验收标准

---

## 2. M3-A: 资源补齐（3 天）

### 2.1 补齐缺失 Sprite（A-D1）

| 文件名 | 尺寸 | 格式 | 说明 |
|--------|------|------|------|
| `fx_explosion_large_01.png` ~ `fx_explosion_large_05.png` | 256x256 | PNG-32 RGBA | BOSS 被击破时的全屏爆炸，5 帧动画序列 |
| `missile_enemy.png` | 64x128 | PNG-32 RGBA | 敌机发射的导弹，俯视角度，带尾焰 |
| `powerup_p.png` | 48x48 | PNG-32 RGBA | 火力提升道具（如已有则确认清晰度） |
| `powerup_b.png` | 48x48 | PNG-32 RGBA | 炸弹补充道具（如已有则确认清晰度） |
| `powerup_coin.png` | 48x48 | PNG-32 RGBA | 金砖/加分道具（如已有则确认清晰度） |

**风格要求**: 与 `fx_explosion_small.png` 统一为 iFighter 1945 风格的矢量写实爆炸。导弹为银灰色弹体 + 橙红色尾焰。道具外框带微发光效果。

### 2.2 敌机 Sprite 细化（A-D2）

确认以下 10 种敌机均有 `body.png` + `hitbox_ref.png`（如缺失则补齐）：

| 敌机类型 | body 文件 | hitbox_ref 文件 |
|---------|----------|----------------|
| 九七式战斗机 | `enemy_ki27_fighter.png` | `enemy_ki27_hitbox_ref.png` |
| 一式战斗机隼 | `enemy_ki43_hayabusa.png` | `enemy_ki43_hitbox_ref.png` |
| 零式舰战 | `enemy_a6m_zero.png` | `enemy_a6m_hitbox_ref.png` |
| 三式战斗机飞燕 | `enemy_ki61_hien.png` | `enemy_ki61_hitbox_ref.png` |
| 四式战斗机疾风 | `enemy_ki84_hayate.png` | `enemy_ki84_hitbox_ref.png` |
| 九七式重爆 | `enemy_ki21_bomber.png` | `enemy_ki21_hitbox_ref.png` |
| 九九式舰爆 | `enemy_d3a_val.png` | `enemy_d3a_hitbox_ref.png` |
| 二式复战屠龙 | `enemy_ki45_toryu.png` | `enemy_ki45_hitbox_ref.png` |
| 震电局地战 | `enemy_j7w_shinden.png` | `enemy_j7w_hitbox_ref.png` |
| 樱花自杀机 | `enemy_ohka_kamikaze.png` | `enemy_ohka_hitbox_ref.png` |

**注意**: hitbox_ref 为红色半透明覆盖层，用于 Code 部门配置碰撞框时参考。body 图为纯俯视角，背景透明。

### 2.3 M3-A 验收标准

- [ ] 全部文件为 PNG-32 RGBA，无 JPG 残留
- [ ] 爆炸序列 5 帧之间视觉连贯
- [ ] 敌机 hitbox_ref 红色覆盖层完整覆盖机体
- [ ] 命名符合 snake_case，无空格无中文

---

## 3. M3-B: 关卡扩展 Phase 1 — Stage 04~08（5 天）

### 3.1 背景图交付清单（B-D1~D5）

每关 4 层 = 20 张背景图。命名规则：`bg_[关卡名]_[layer].png`

| 关卡 | 主题 | far 层（远景） | mid 层（中景） | near 层（近景） | ground 层（地面） |
|------|------|--------------|--------------|---------------|-----------------|
| Stage 04 驼峰航线 | 雪山峡谷 + 云雾 | 连绵雪山天际线，云层缝隙 | 峡谷岩壁，冰挂 | 云雾流动效果 | 碎石坡 + 坠机残骸 |
| Stage 05 桂林 | 喀斯特地貌 + 漓江 | 层叠峰林，薄雾 | 漓江河道，竹筏 | 近岸植被，芦苇 |  limestone 地面纹理 |
| Stage 06 衡阳 | 城市废墟 + 稻田 | 燃烧的城市轮廓，黑烟 | 倒塌建筑，弹坑 | 稻田水渠，农舍 | 泥土路 + 散落的武器 |
| Stage 07 芷江机场 | 机场跑道 + 机库 | 机库群，塔台 | 跑道，停放的战机 | 草地，导航标识 | 水泥地面，轮胎痕 |
| Stage 08 武汉 | 长江 + 城市天际线 | 长江江面，对岸建筑 | 码头，船只，租界建筑 | 街道，车辆，行人（小） | 石板路 + 积水 |

**统一规格**: 512x2048 像素，PNG-32 RGBA，透明背景。

**风格**: orthophoto/正射卫星图风格（M2 已确定）。零透视，90° 正上方俯视。色调偏暗写实，带轻微光影质感（参考 `bg_kunming_mid.png`）。

**禁止**: 天空区域、地平线、侧视角度、水面烘焙到 PNG 中。

### 3.2 BOSS Sprite 交付清单（B-D6）

每 BOSS 3 张 = 15 张。命名：`boss_[id]_phase1.png`, `boss_[id]_phase2.png`, `boss_[id]_transform.png`

| BOSS ID | 名称 | 类型 | phase1 描述 | phase2 描述 | transform 描述 |
|---------|------|------|------------|------------|---------------|
| `ki21_squadron` | 一式陆攻编队 | 飞行编队 | 3 架轰炸机 V 字编队 | 散开，各自独立瞄准 | 机翼断裂，引擎起火 |
| `akitsushima` | 秋津洲号 | 大型舰 | 水上机母舰俯视图，甲板整齐 | 甲板破洞，烟柱 | 船体倾斜，起火 |
| `kinu` | 鬼怒号 | 中型舰 | 轻巡洋舰俯视图，炮塔清晰 | 炮塔损坏，侧舷火光 | 船尾下沉 |
| `shiden_squadron` | 紫电改中队 | 战机群 | 4 架紫电改编队 | 散开高速机动，尾迹 | 一架被击落，其余散开 |
| `kongo` | 金刚号 | 超大型舰 | 战列舰俯视图，主炮塔完整 | 主炮塔损坏，甲板火 | 舰桥倒塌，大火 |

**统一规格**: 512x512 像素，PNG-32 RGBA，透明背景。

**风格**: 扁平 2D 俯视角，金属质感，无水面/无背景烘焙。与已有 BOSS（bomber/nachi/fortress）风格一致。

### 3.3 新增敌机 Sprite（B-D7）

Stage 04~08 可能需要的新敌机类型（Code 确认后执行）：

| 敌机 ID | 名称 | 说明 |
|---------|------|------|
| `enemy_type97_tank` | 九七式中战车 | 地面载具，俯视坦克顶面 |
| `enemy_landing_craft` | 登陆艇 | 水面载具，俯视船顶 |
| `enemy_observation_balloon` | 观测气球 | 慢速空中目标，圆形 |

### 3.4 M3-B 验收标准

- [ ] 20 张背景图全部 orthophoto 风格，无天空/地平线
- [ ] 15 张 BOSS Sprite 全部透明背景，无水面烘焙
- [ ] 全部 512x2048（背景）或 512x512（BOSS）
- [ ] 命名与 Code 部门 CSV 配置一致（见 `spawn_manager.gd` 映射表）

---

## 4. M3-C: 关卡扩展 Phase 2 + 隐藏关（5 天）

### 4.1 Stage 09~12 背景图（C-D1）

每关 4 层 = 16 张。

| 关卡 | 主题 | 风格要点 |
|------|------|---------|
| Stage 09 南昌 | 湖泊 + 丘陵 | 鄱阳湖水面，丘陵茶园，村庄 |
| Stage 10 上海 | 城市港口 + 黄浦江 | 外滩建筑，码头起重机，货轮 |
| Stage 11 南京 | 城墙 + 紫金山 | 明城墙，中山陵，玄武湖 |
| Stage 12 东京 | 夜间城市 + 火光 | 燃烧的建筑，探照灯，防空炮火光（夜间色调） |

**注意 Stage 12**: 这是唯一夜间关卡，背景色调应为深蓝/暗红，建筑窗口有灯光，火焰效果更明显。

### 4.2 隐藏关背景图（C-D2）

4 个隐藏关，每关 3~4 层 = 约 14 张。

| 隐藏关 | 主题 | 特殊要求 |
|--------|------|---------|
| H1 驼峰绝径 | 狭窄云雾峡谷 | 两侧岩壁极近，中央通道仅 1/3 屏宽，浓雾效果 |
| H2 轰炸东京 | 夜间东京逆向 | 与 Stage 12 类似但色调更暗，目标建筑高亮标记 |
| H3 震电对决 | 高空云层之上 | 纯云海背景，无地面，高空光线（蓝白色调） |
| H4 广岛之刻 | 蘑菇云 + 废墟 | 中央巨大蘑菇云，地面环形废墟，辐射光效（橙红色调） |

### 4.3 BOSS 09~12 + 隐藏 BOSS Sprite（C-D3）

| BOSS ID | 名称 | 类型 | 描述 | 实际交付文件名 |
|---------|------|------|------|----------------|
| ~~tone~~ | 利根号 | 大型舰 | 重巡洋舰，航空甲板 | `boss_nagato_phase1/2` |
| ~~shokaku~~ | 翔鹤号 | 航母 | 大型航母，飞行甲板，岛式舰桥 | `boss_kamikawa_phase1/2` |
| ~~yamato~~ | 大和号 | 超大型舰 | 史上最大战列舰，3 联装主炮 | `boss_ki49_phase1/2` |
| ~~yahata~~ | 八幡号 | 飞行要塞 | 虚构巨型飞行战舰，多层甲板 | `boss_floating_aa_phase1/2` |
| `shinden_final` | 震电·改 | 隐藏 BOSS | 高速局地战斗机，黑色涂装，发光引擎 | `boss_shinden_proto_phase1/2` |

> **命名变更说明（P2 已确认）**: M3-C 实际交付时 BOSS 命名与规划偏离，Code 侧已同步使用实际命名。上表记录最终统一命名。

每个 3 张 = 15 张，规格同 M3-B。

### 4.4 隐藏关特殊素材（C-D4）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_target_marker.png` | 64x64 | H2 轰炸目标高亮标记（红色圆圈 + 十字） |
| `ui_countdown_ring.png` | 256x256 | H4 倒计时环形进度条 |
| `ui_checkpoint_flag.png` | 64x64 | 深渊模式检查点标记 |

---

## 5. M3-D: UI 与菜单素材（5 天，与 B/C 并行）

### 5.1 主菜单与 Logo（D-D1）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_main_menu_bg.png` | 1920x1080 + 1080x1920 两套 | 主菜单背景：飞虎队 P-40 编队飞过云层，深绿/土黄复古色调 |
| `ui_logo.png` | 800x300 | 游戏 Logo："Flying Tigers 1945"，做旧金属质感字体，翼形装饰 |
| `ui_logo_small.png` | 400x150 | 小尺寸 Logo，用于标题栏和结算界面 |

### 5.2 关卡选择缩略图（D-D2）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_stage_thumb_01.png` ~ `ui_stage_thumb_12.png` | 256x256 | 12 主线关卡缩略图，每关代表性场景微缩 |
| `ui_stage_thumb_H1.png` ~ `ui_stage_thumb_H4.png` | 256x256 | 4 隐藏关卡缩略图，带暗角/锁链效果表示未解锁 |
| `ui_stage_lock_overlay.png` | 256x256 | 锁定状态覆盖层（半透明灰 + 锁图标） |

**缩略图画法**: 非完整背景，而是每关最具代表性的微缩景观（如昆明 = 滇池 + 西山，驼峰 = 雪山峡谷）。

### 5.3 按钮与控件素材（D-D3~D4）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_button_normal.png` | 200x60 | 按钮正常状态，深绿底 + 黄边框 |
| `ui_button_hover.png` | 200x60 | 按钮悬停状态，亮绿底 + 发光边框 |
| `ui_button_pressed.png` | 200x60 | 按钮按下状态，暗绿底 + 内阴影 |
| `ui_button_disabled.png` | 200x60 | 按钮禁用状态，灰色 + 无边框 |
| `ui_slider_track.png` | 200x12 | 滑块轨道 |
| `ui_slider_handle.png` | 24x24 | 滑块手柄 |
| `ui_toggle_on.png` | 64x32 | 开关开启状态 |
| `ui_toggle_off.png` | 64x32 | 开关关闭状态 |
| `ui_dropdown_bg.png` | 200x40 | 下拉框背景 |
| `ui_dropdown_arrow.png` | 24x24 | 下拉箭头 |

### 5.4 排行榜素材（D-D5）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_rank_1st.png` | 64x64 | 第一名金牌 |
| `ui_rank_2nd.png` | 64x64 | 第二名银牌 |
| `ui_rank_3rd.png` | 64x64 | 第三名铜牌 |
| `ui_avatar_frame.png` | 128x128 | 玩家头像框（军用徽章风格） |
| `ui_rank_divider.png` | 800x4 | 排行榜行分隔线 |

### 5.5 深渊模式 UI（D-D6）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_abyss_floor_indicator.png` | 256x64 | 当前层数指示器（"Layer 47" 样式） |
| `ui_abyss_checkpoint.png` | 64x64 | 检查点旗帜图标 |
| `ui_abyss_difficulty_bar.png` | 200x16 | 难度等级进度条（红→紫渐变） |

---

## 6. M3-E: 平台适配素材（4 天）

### 6.1 移动端 UI 布局（E-D1）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_vjoystick_base.png` | 160x160 | 虚拟摇杆底座（半透明圆环） |
| `ui_vjoystick_handle.png` | 80x80 | 虚拟摇杆手柄（实心圆） |
| `ui_btn_shoot.png` | 100x100 | 射击按钮（大按钮，适合手指） |
| `ui_btn_bomb.png` | 100x100 | 炸弹按钮 |
| `ui_hud_mobile.png` | 1080x200 | 移动端 HUD 底板（竖屏顶部） |

### 6.2 低画质模式素材（E-D2）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `bg_kunming_low_01.png` ~ `bg_kunming_low_02.png` | 512x1024 | 昆明关低画质背景（仅 2 层，简化细节） |
| （其他关卡类似） | 512x1024 | 每关 2 张低画质背景，Code 自动切换 |

### 6.3 图标与启动图（E-D3）

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `app_icon_16.png` | 16x16 | Steam/Windows 小图标 |
| `app_icon_32.png` | 32x32 | 中图标 |
| `app_icon_48.png` | 48x48 | 大图标 |
| `app_icon_128.png` | 128x128 | Steam 商店图标 |
| `app_icon_256.png` | 256x256 | macOS/iOS 高分辨率图标 |
| `app_icon_512.png` | 512x512 | Android 启动图标 |
| `splash_screen.png` | 1920x1080 | 游戏启动画面，P-40 从机库滑出 |
| `splash_screen_portrait.png` | 1080x1920 | 竖版启动画面（移动端） |

---

## 7. 隐藏事件/随机事件相关设计素材（新增）

根据用户和 Code 部门的讨论，后续关卡会加入条件触发的隐藏要素。Design 部门需提前准备以下素材，供事件系统调用：

### 7.1 通用隐藏目标素材

| 文件名 | 尺寸 | 用途 | 描述 |
|--------|------|------|------|
| `event_target_car.png` | 128x64 | 逃跑的高级将军汽车 | 黑色轿车，俯视角，带扬尘效果 |
| `event_target_bridge.png` | 256x128 | 怒江渡桥 | 木桥/浮桥，俯视角，可显示破损状态 |
| `event_intel_case.png` | 48x48 | 高级情报箱 | 棕色皮箱，金色锁扣，掉落物 |
| `event_medal_special.png` | 64x64 | 特殊勋章 | 隐藏任务完成奖励图标 |

### 7.2 事件触发提示 UI

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `ui_event_alert.png` | 400x80 | 隐藏目标出现提示条（"发现敌军将领！"） |
| `ui_event_complete.png` | 400x80 | 隐藏任务完成提示条（"情报获取成功！"） |
| `ui_bonus_popup.png` | 300x200 | 额外奖励弹窗底板 |

### 7.3 设计建议

- **将军汽车**: 速度比普通敌机快 1.5 倍，体积较小，颜色偏深（黑色/深绿）以区别于普通敌机
- **渡桥**: 可被玩家子弹击中，击中 3~5 次后显示 `event_target_bridge_broken.png`（破损状态）
- **情报箱**: 汽车被击毁后掉落，缓慢下落，玩家触碰后消失并播放 `ui_event_complete` 提示

---

## 8. 命名规范速查表

所有文件必须严格使用以下命名格式：

```
# 背景
bg_[stage_id]_[layer].png
# 示例: bg_kunming_mid.png, bg_hump_far.png

# BOSS
boss_[boss_id]_phase1.png
boss_[boss_id]_phase2.png
boss_[boss_id]_transform.png
# 示例: boss_ki21_squadron_phase1.png

# 敌机
enemy_[model]_[name].png
enemy_[model]_hitbox_ref.png
# 示例: enemy_ki27_fighter.png

# UI
ui_[功能]_[状态].png
# 示例: ui_button_hover.png, ui_stage_thumb_05.png

# 事件
event_[类型]_[名称].png
# 示例: event_target_car.png, event_intel_case.png

# 特效
fx_[名称]_[序号].png
# 示例: fx_explosion_large_03.png
```

**严禁**: 中文命名、空格、大写字母（除文件扩展名外）、特殊符号。

---

## 9. 与 Code 部门的对接要点

1. **背景图层顺序**: Code 使用 `stage_config.json` 的 `bg_layers` 数组定义图层顺序。Design 交付背景后，需在 `DesignLog.md` 中注明每关的图层顺序建议（从远到近）。

2. **BOSS 尺寸与碰撞框**: BOSS Sprite 为 512x512，但实际碰撞框由 Code 在 `.tscn` 中配置。Design 需确保 BOSS 主体在 Sprite 中居中，四周留出至少 20px 透明边距。

3. **事件素材动态替换**: `event_target_bridge.png` 和 `event_target_bridge_broken.png` 需保持完全相同的画布尺寸和中心点，以便 Code 直接替换纹理而不调整节点位置。

4. **每日同步**: 每完成一批素材，立即 `git add && git commit && git push`，并在 `DesignLog.md` 中记录产出文件清单。

---

## 10. 验收标准汇总

| 检查项 | 标准 |
|--------|------|
| 格式 | PNG-32 RGBA，无 JPG/PNG-24 残留 |
| 尺寸 | 背景 512x2048，BOSS 512x512，UI 按文档规定，敌机 128x128 |
| 视角 | 全部 90° 正上方俯视（orthophoto 风格） |
| 背景 | 无天空、无地平线、无水面烘焙 |
| BOSS | 透明背景，无额外场景元素 |
| 命名 | 全小写 snake_case，无空格无中文 |
| 数量 | 每子里程碑按清单 100% 交付 |
| 风格 | 与 M1/M2 已有素材统一（iFighter 1945 矢量写实） |

---

**Design Agent 确认后，从 M3-A 开始执行。每完成一个子任务，更新 DesignLog.md 并推送。**
