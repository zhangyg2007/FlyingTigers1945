# Flying Tigers 1945 — M3 任务分解与分配方案

> **版本**: v1.0  
> **日期**: 2026-07-10  
> **PM**: Work Agent  
> **状态**: 待 Code / Design 部门确认后启动

---

## 1. 背景与目标

M3 是项目从「可玩原型」迈向「完整游戏」的关键阶段。Code 部门反馈 M3 原始范围过大，一次性交付风险高。本方案将 M3 拆分为 **5 个子里程碑（M3-A ~ M3-E）**，每个子里程碑有独立的交付物、验收标准和截止期限，允许并行开发和逐层验收。

**M3 总目标**:
- 完成全部 16 个关卡配置（12 主线 + 4 隐藏）
- 完成全部 12 个 BOSS 实现
- 完成深渊模式（程序化生成 + 排行榜）
- 完成存档系统 + Steam/TapTap SDK 集成
- 完成移动端虚拟摇杆 + 性能降级
- 完成全部菜单界面（主菜单、关卡选择、设置、排行榜）
- 通过性能预算测试
- 修复 M2 遗留 P3 问题

---

## 2. M3 子里程碑总览

| 子里程碑 | 主题 | 预估工期 | 依赖 | 前置条件 |
|---------|------|---------|------|---------|
| **M3-A** | 基础修复 + 资源补齐 | 3 天 | 无 | M2 正式通过 |
| **M3-B** | 关卡扩展 Phase 1（Stage 04~08） | 5 天 | M3-A | Design 资产到位 |
| **M3-C** | 关卡扩展 Phase 2（Stage 09~12 + 4 隐藏关） | 5 天 | M3-B | M3-B Code 验收通过 |
| **M3-D** | 系统功能（存档 + 深渊 + 排行榜 + 菜单） | 5 天 | M3-A | 无（可与 B/C 并行） |
| **M3-E** | 平台适配 + 性能优化 + 最终验收 | 4 天 | M3-B + M3-C + M3-D | 全部功能完成 |

**总工期**: ~22 天（允许部分并行，实际约 15~18 天）

---

## 3. 各子里程碑详细任务清单

### M3-A: 基础修复 + 资源补齐（3 天）

**目标**: 消除 M2 遗留债务，为后续大规模开发扫清障碍。

#### Code 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| A-C1 | 补齐缺失 .tscn 场景 | `explosion_large.tscn`, `powerup.tscn` (3 种), `missile_enemy.tscn` | 场景可运行，节点树正确，脚本已挂载 |
| A-C2 | 敌机拆分 | `enemy_ki27_fighter.tscn`, `enemy_ki43_hayabusa.tscn`, `enemy_a6m_zero.tscn`, `enemy_ki61_hien.tscn`, `enemy_ki84_hayate.tscn`, `enemy_ki21_bomber.tscn`, `enemy_d3a_val.tscn`, `enemy_ki45_toryu.tscn`, `enemy_j7w_shinden.tscn`, `enemy_ohka_kamikaze.tscn` | 每个敌机有独立碰撞框、速度参数、掉落配置 |
| A-C3 | BOSS 弹幕参数调优 | 修改 `boss_bomber.json`, `boss_nachi.json`, `boss_fortress.json` | 弹幕密度、速度、角度在测试场景中可玩且不失衡 |
| A-C4 | 语法检查 + 冒烟测试 | 运行 `godot --check-only` 和 `test_boss_flow` | 零报错，test_boss_flow 5/5 PASS |

#### Design 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| A-D1 | 补齐缺失 Sprite | `fx_explosion_large_*.png` (3~5 帧), `powerup_p.png`, `powerup_b.png`, `powerup_coin.png` (如需要高清版), `missile_enemy.png` | RGBA, 尺寸符合 Design Spec |
| A-D2 | 敌机 Sprite 细化 | 确保全部 10 种敌机有独立 body + hitbox_ref | 俯视角，风格统一，透明背景 |

**M3-A 验收**: Code A- / Design A- 即通过，允许最多 1 项 P2 问题遗留。

---

### M3-B: 关卡扩展 Phase 1 — Stage 04~08（5 天）

**目标**: 完成第 4~8 关的关卡配置、场景、BOSS 和背景资产。

根据 GDD 设计，Stage 04~08 为：

| 关卡 | 名称 | 场景 | BOSS | BOSS 类型 |
|------|------|------|------|----------|
| 04 | 驼峰航线 | 雪山峡谷 + 云雾 | 一式陆攻编队 | 飞行编队 |
| 05 | 桂林保卫战 | 喀斯特地貌 + 漓江 | 秋津洲号水上机母舰 | 大型舰 |
| 06 | 衡阳会战 | 城市废墟 + 稻田 | 鬼怒号轻巡 | 中型舰 |
| 07 | 芷江机场 | 机场跑道 + 机库 | 紫电改中队 | 高速战机群 |
| 08 | 武汉空战 | 长江 + 城市天际线 | 金刚号战列舰 | 超大型舰 |

#### Code 任务（与 Design 并行启动，但需等待 Design 资产）

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| B-C1 | Stage 04 CSV + .tscn | `stage_04_hump.csv`, `stage_04_hump.tscn` | 至少 8 波敌人 + BOSS 行，格式正确 |
| B-C2 | Stage 05 CSV + .tscn | `stage_05_guilin.csv`, `stage_05_guilin.tscn` | 同上 |
| B-C3 | Stage 06 CSV + .tscn | `stage_06_hengyang.csv`, `stage_06_hengyang.tscn` | 同上 |
| B-C4 | Stage 07 CSV + .tscn | `stage_07_zhijiang.csv`, `stage_07_zhijiang.tscn` | 同上 |
| B-C5 | Stage 08 CSV + .tscn | `stage_08_wuhan.csv`, `stage_08_wuhan.tscn` | 同上 |
| B-C6 | BOSS 04~08 .tscn + JSON | `boss_ki21_squadron.tscn/json`, `boss_akitsushima.tscn/json`, `boss_kinu.tscn/json`, `boss_shiden_squadron.tscn/json`, `boss_kongo.tscn/json` | 每个 BOSS 含 2~3 阶段，phase_hps 合理 |
| B-C7 | stage_config.json 更新 | 追加 stage_04~08 配置 | bg_layers 与实际资源名一致 |
| B-C8 | SpawnManager BOSS 映射更新 | `spawn_manager.gd` BOSS 映射表 | 新 BOSS 可被 CSV 正确引用 |

#### Design 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| B-D1 | Stage 04 背景（4 层） | `bg_hump_far/mid/near/ground.png` | 512x2048, RGBA, 雪山俯视角 |
| B-D2 | Stage 05 背景（4 层） | `bg_guilin_far/mid/near/ground.png` | 同上，喀斯特地貌 |
| B-D3 | Stage 06 背景（4 层） | `bg_hengyang_far/mid/near/ground.png` | 同上，城市废墟 |
| B-D4 | Stage 07 背景（4 层） | `bg_zhijiang_far/mid/near/ground.png` | 同上，机场跑道 |
| B-D5 | Stage 08 背景（4 层） | `bg_wuhan_far/mid/near/ground.png` | 同上，长江城市 |
| B-D6 | BOSS 04~08 Sprite | 每个 BOSS 3 张（phase1/phase2/transform） | 512x512, RGBA, 俯视角 |
| B-D7 | 敌机 Sprite（如需要新类型） | 根据 Code 需求补充 | 128x128, RGBA |

**并行策略**: Design 先启动背景图（B-D1~D5），Code 同步编写 CSV 和 BOSS JSON（无需等 Sprite）。Design 交付 Sprite 后 Code 完成 .tscn 组装。

---

### M3-C: 关卡扩展 Phase 2 — Stage 09~12 + 4 隐藏关（5 天）

**目标**: 完成剩余主线关卡 + 4 个隐藏关卡。

Stage 09~12：

| 关卡 | 名称 | 场景 | BOSS | BOSS 类型 |
|------|------|------|------|----------|
| 09 | 南昌会战 | 湖泊 + 丘陵 | 利根号重巡 | 大型舰 |
| 10 | 上海防空 | 城市港口 + 黄浦江 | 翔鹤号航母 | 航母 |
| 11 | 南京保卫战 | 城墙 + 紫金山 | 大和号战列舰 | 超大型舰 |
| 12 | 东京突袭 | 夜间城市 + 火光 | 八幡号飞行要塞 | 飞行要塞 |

隐藏关卡（解锁条件见 GDD）：

| 关卡 | 名称 | 解锁条件 | 特殊机制 |
|------|------|---------|---------|
| H1 | 驼峰绝径 | 通关 Stage 04 无伤 | 狭窄峡谷，碰撞即死 |
| H2 | 轰炸东京 | 二周目 Easy 通关 | 逆向卷轴（上→下），仅轰炸目标 |
| H3 | 震电对决 | 二周目 Hard 第 6 关前无伤 | 1v1 BOSS Rush，仅对单一高速目标 |
| H4 | 广岛之刻 | 通关 H3 后触发 | 倒计时生存，不可攻击，仅躲避 |

#### Code 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| C-C1 | Stage 09~12 CSV + .tscn | 各关 csv + tscn | 至少 8 波敌人 + BOSS |
| C-C2 | 隐藏关 CSV + .tscn | `stage_H1_hump_extreme.tscn` 等 4 个 | 特殊机制脚本正确实现 |
| C-C3 | BOSS 09~12 + 隐藏 BOSS .tscn + JSON | `boss_tone.tscn/json`, `boss_shokaku.tscn/json`, `boss_yamato.tscn/json`, `boss_yahata.tscn/json`, `boss_shinden_final.tscn/json` | 含特殊弹幕模式 |
| C-C4 | 隐藏关机制脚本 | `hump_narrow_passage.gd`, `tokyo_bombing.gd`, `shinden_duel.gd`, `hiroshima_countdown.gd` | 机制可在测试场景验证 |
| C-C5 | 解锁条件系统 | `unlock_manager.gd`（或集成到 SaveManager） | 通关数据驱动解锁 |
| C-C6 | stage_config.json 完整版 | 包含全部 16 关配置 | 无命名不一致问题 |

#### Design 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| C-D1 | Stage 09~12 背景（各 4 层） | 16 张 PNG | 512x2048, RGBA |
| C-D2 | 隐藏关背景 | H1 云雾峡谷, H2 夜间东京, H3 高空云层, H4 蘑菇云 | 特殊氛围，风格统一 |
| C-D3 | BOSS 09~12 + 隐藏 BOSS Sprite | 每个 3 张（phase1/phase2/transform） | 512x512, RGBA |
| C-D4 | 隐藏关特殊素材 | H2 轰炸目标标记, H4 倒计时 UI 元素 | 按需求补充 |

---

### M3-D: 系统功能 — 存档 + 深渊 + 排行榜 + 菜单（5 天）

**目标**: 完成游戏核心系统功能，可与 M3-B/C 并行开发。

#### Code 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| D-C1 | SaveManager 完整实现 | `save_manager.gd` 存档/读档/删档 | 支持多存档槽，ConfigFile 格式，加密可选 |
| D-C2 | 深渊模式生成器 | `abyss_manager.gd` + `abyss_generator.gd` | 难度曲线公式正确，波次递增，无限关卡 |
| D-C3 | 深渊模式场景 | `abyss_mode.tscn` | 可运行，每 5 层一个检查点 |
| D-C4 | 本地排行榜 | `local_leaderboard.gd` | 按分数/关卡/深渊层数排序，持久化 |
| D-C5 | Steam 排行榜集成 | `steam_leaderboard.gd`（使用 GodotSteam） | 上传分数，读取全球排行 |
| D-C6 | TapTap 排行榜集成 | `taptap_leaderboard.gd` | SDK 接口封装，上传/读取 |
| D-C7 | 主菜单完善 | `main_menu.tscn` 完整功能 | 开始游戏、关卡选择、设置、排行榜、退出 |
| D-C8 | 关卡选择界面 | `stage_select.tscn` | 显示 12 主线 + 4 隐藏（锁定/解锁状态），缩略图 |
| D-C9 | 设置界面 | `settings_menu.tscn` | 音量、难度、语言、操作方式、画面质量 |
| D-C10 | 排行榜界面 | `leaderboard.tscn` 完善 | 本地/全球切换，分类（关卡/深渊） |
| D-C11 | 暂停菜单完善 | `pause_menu.tscn` | 继续、重新开始、返回菜单、设置 |
| D-C12 | 结算界面完善 | `result_screen.tscn` | 分数统计、评价等级、解锁提示、下一关/返回 |

#### Design 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| D-D1 | 主菜单背景 + Logo | `ui_main_menu_bg.png`, `ui_logo.png` | 1920x1080 / 1080x1920 适配 |
| D-D2 | 关卡选择地图/缩略图 | `ui_stage_thumb_01~12.png`, `ui_stage_thumb_H1~H4.png` | 256x256, 风格统一 |
| D-D3 | 按钮素材（全套） | `ui_button_normal/hover/pressed/disabled.png` | 9-patch 或固定尺寸 |
| D-D4 | 设置界面素材 | 滑块、开关、下拉框 | 风格统一 |
| D-D5 | 排行榜头像框/奖牌 | `ui_rank_1st/2nd/3rd.png`, `ui_avatar_frame.png` | 与已有 medal 素材统一 |
| D-D6 | 深渊模式专属 UI | 层数指示器、检查点标记 | 按 Code 需求补充 |

---

### M3-E: 平台适配 + 性能优化 + 最终验收（4 天）

**目标**: 游戏在 PC 和移动端均可流畅运行，通过性能预算测试。

#### Code 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| E-C1 | 移动端虚拟摇杆 | `virtual_joystick.gd` + `.tscn` | 左摇杆移动，右侧射击/炸弹按钮，触摸响应灵敏 |
| E-C2 | 性能降级系统 | `performance_manager.gd` | 根据 FPS 自动降粒子数、弹幕密度、背景层数 |
| E-C3 | 分辨率适配 | `screen_adapter.gd` | 16:9 和 9:16 自动适配，UI 不裁剪 |
| E-C4 | 性能预算测试 | `tests/performance_budget.gd` | PC 60fps 稳定，移动端 30fps 稳定，同屏 300 子弹不卡顿 |
| E-C5 | 对象池最终调优 | `pool_manager.gd` 容量调优 | 无内存泄漏，峰值占用 < 128MB |
| E-C6 | 最终集成测试 | `tests/full_game_flow.gd` | 从主菜单→关卡选择→游戏→结算→排行榜完整链路 |
| E-C7 | 构建导出配置 | `export_presets.cfg` | Windows / Android / iOS 导出模板配置 |

#### Design 任务

| 序号 | 任务 | 交付物 | 验收标准 |
|------|------|--------|---------|
| E-D1 | 移动端 UI 布局适配 | 竖屏版 HUD 素材 | 按钮尺寸 >= 80x80px，适应手指触摸 |
| E-D2 | 低画质模式素材 | 简化版背景（2 层而非 4 层） | 512x1024，减少显存占用 |
| E-D3 | 图标 + 启动图 | `app_icon_*.png`, `splash_screen.png` | Steam/TapTap 商店要求尺寸 |

---

## 4. 部门并行协作策略

### 4.1 时间线（甘特图逻辑）

```
Day:  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18
      |----M3-A----|
                   |-------M3-B-------|
                                     |-------M3-C-------|
      |--------------M3-D（与 B/C 并行）------------------|
                                                       |--M3-E--|
```

### 4.2 依赖关系图

```
M3-A（基础修复）
    ├──→ M3-B（Stage 04~08）
    │       └──→ M3-C（Stage 09~12 + 隐藏关）
    │
    └──→ M3-D（系统功能）
            └──→ M3-E（平台适配 + 性能优化）
```

**关键路径**: M3-A → M3-B → M3-C → M3-E（约 17 天）

**可并行**: M3-D 与 M3-B/C 完全并行，节省约 5 天。

### 4.3 每日同步机制

- **每日 21:00**（或每任务完成后）：Code / Design Agent 提交当日工作到 GitHub
- **次日 09:00**：Work Agent 拉取代码，检查合并冲突，更新任务看板
- **每子里程碑结束时**：Work Agent 出具验收报告，确认通过后才允许进入下一阶段

---

## 5. 验收标准与评级

延续 M1/M2 的 A/B/C/D 评级体系：

| 评级 | 条件 | 处理方式 |
|------|------|---------|
| **A** | 100% 通过，无 P0/P1 问题 | 直接进入下一阶段 |
| **A-** | 通过，最多 1 个 P2 问题 | 限期 1 天整改 |
| **B** | ≥90% 通过，无 P0 问题 | 限期 2 天整改 |
| **C** | ≥75% 通过 | 限期 5 天整改 |
| **D** | <75% 通过 | 退回重做，重新评估工期 |

### M3 整体通过标准

- M3-A/B/C/D 均达到 B 级以上
- M3-E 达到 A- 级以上（性能测试必须 PASS）
- 全部 P0 问题清零
- P1 问题 ≤ 3 个（可遗留到发布后修复）

---

## 6. 风险与应对

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|---------|
| Design 资产交付延迟 | 中 | M3-B/C 阻塞 | Code 先用占位 Sprite 开发，资产到位后替换 |
| Steam SDK 集成复杂度超预期 | 中 | M3-D 延期 | 先完成本地排行榜，Steam 作为可选扩展 |
| 性能测试不达标 | 中 | M3-E 阻塞 | M3-A 即开始性能基线测试，早发现早优化 |
| 隐藏关特殊机制设计冲突 | 低 | M3-C 返工 | 先在 M3-A 完成 H1 原型验证 |
| 移动端触控体验差 | 中 | M3-E 延期 | M3-D 阶段即开始虚拟摇杆原型测试 |

---

## 7. 下一步行动

1. **Work Agent（PM）**: 将本文档推送至 GitHub `docs/M3_task_breakdown.md`
2. **Code Agent**: 阅读本文档，确认 M3-A 任务清单，开始开发
3. **Design Agent**: 阅读本文档，确认 M3-A + M3-B 设计任务，开始资产制作
4. **三方同步**: 每日按 WORKFLOW.md 规范提交日志和代码

---

**文档结束**。如有任务范围调整需求，请在各自日志中记录并由 PM 统一更新本文档。
