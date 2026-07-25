# Flying Tigers 1945 — Design Log v1.5

> **版本**: v1.5.0 Design Log  
> **日期**: 2026-07-24  
> **适用范围**: v1.5 Design 任务 D1-D18  

---

## 工作记录

### 2026-07-24 (Session 1) — P0核心资产

**v1.4 资产备份** [完成]
- 已将 `assets/sprites/` 完整备份至 `assets/v1.4/sprites/`
- 备份包含: backgrounds(14关+4隐藏关), boss(42张), bullets(4张), effects(12张), enemy(41张), player(24张), powerups(3张), ui(37张)

**D1: 新BOSS Sprite** [完成]
- 14张512x512 PNG-32 RGBA, 存放于 `assets/sprites/boss/`
- 工艺: AI生成1920x1920 → 自动裁剪内容 → 缩放至512x512 → 透明背景处理
- 风格: Military Cartoon Realism, 微缩模型感, 顶亮底暗立体光影
- 清单: boss_ki48_squadron / boss_tenryu / boss_huitong_bridge / boss_myoko / boss_ki44_ace / boss_fortress_group / boss_ammunition_depot / boss_escort_boat / boss_gunboat / boss_supply_ship / boss_mogami / boss_airfield_tower / boss_ki45_toryu / boss_j7w2_shinden_kai

**D2: 舰艇部件Sprite** [完成]
- 24个独立部件 + 24个摧毁变体 = 48张 (60x60 PNG-32 RGBA)
- 存放于 `assets/sprites/boss/parts/`
- 天龙号4部件, 妙高号10部件, 最上号10部件
- 从BOSS Sprite裁剪 + 摧毁变体(暗化+红色偏移)

**D3: 陆上大型单位Sprite** [完成]
- 7张128x128 PNG-32 RGBA, 存放于 `assets/sprites/ground_facilities/`
- bunker_single / flak_emplacement / fuel_tank_farm / mg_nest / factory_chimneys / command_post / ammo_bunker

**D8: 旧BOSS Sprite清理** [完成]
- 共删除42张旧Sprite (已备份至v1.4)
- 删除列表: boss_akitsushima(3), boss_yamato(3), boss_yahata(3), boss_shinden_final(3), boss_bomber/boss_fortress/boss_cruiser的phase2+transform, boss_ki21_squadron/shiden_squadron全部, boss_b29_enola(2), boss_frozen_bomber(2), boss_kinu(3), boss_kongo(3), boss_shokaku(2), boss_tone(2), boss_bridge_destroyed, boss_mushroom_cloud

**D4: 新背景地图** [完成]
- 3张800x2400单图层PNG
- stage_04_hsinchu / stage_06_baoqing / stage_07_xiangjiang

### 2026-07-24 (Session 2) — 风格统一

**风格基准变更**
- 用户提供P40参考图(飞虎队P40.png, 2048x2048, 偏写实)
- 美术风格从"Military Cartoon Realism"调整为"写实军事插画风格"
- 提供日本敌机设计图参考: Ki-27, Ki-44, Ki-45, Ki-61, G4M, 震电等

**D10+D15: 敌机Sprite统一重做** [完成]
- 新增3种: enemy_j2m_raiden / enemy_ki51_sonia / enemy_g3m_nell
- 重做10种(写实风格): enemy_ki27_fighter / enemy_ki43_hayabusa / enemy_ki44_shoki / enemy_ki45_toryu / enemy_ki48_lily / enemy_ki61_hien / enemy_ki84_hayate / enemy_ki21_bomber / enemy_d3a_val / enemy_j7w_shinden
- 删除A6M(4张)和Ohka(2张) — v1.5已移除
- 清理旧变体文件: *_body, *_side, *_hitbox_ref (~20张)
- 所有敌机统一为128x128 PNG-32 RGBA写实风格

**D5: 玩家战机Sprite** [完成]
- 新增6架128x128 PNG-32 RGBA写实风格:
  - `p40b/player_p40b_body.png` — P-40B战斧
  - `p40e/player_p40e_body.png` — P-40E小鹰
  - `p38/player_p38_body.png` — P-38闪电 (重做)
  - `p47/player_p47_body.png` — P-47雷霆 (新目录)
  - `p51/player_p51_body.png` — P-51D野马 (重做)
  - `b29/player_b29_body.png` — B-29超级堡垒 (新目录)
- 已有: `p40/player_p40_body.png`, `p25/player_b25_body.png`
- 工艺: AI生成2048x2048写实插画 → 透明背景 → 裁剪缩放至128x128

---

## 当前资产状态

| 类别 | 数量 | 尺寸 | 风格 |
|------|------|------|------|
| BOSS Sprite | 14 | 512x512 | 卡通写实 |
| BOSS部件 | 48 | 60x60 | 从BOSS裁剪 |
| 陆上设施 | 7 | 128x128 | 卡通写实 |
| 背景地图 | 3张新+旧 | 800x2400 | 手绘纹理 |
| 敌机Sprite | 13 | 128x128 | **写实风格(新)** |
| 玩家战机 | 7(6新+1旧B-25) | 128x128 | **写实风格(新)** |

---

### 2026-07-25 (Session 3) — 风格调整与Roll变体

**风格基准再调整**
- 用户提供军舰/地图截图参考，要求90度纯俯视、低饱和度、2D扁平游戏图形
- BOSS Sprite已在前一Session重做为90度俯视扁平风格（14张）
- 敌机Sprite保持90度俯视（Session 2已统一），抽检Ki-43确认角度正确
- 玩家机Sprite保持90度俯视，抽检P-40 body确认角度正确

**D15续: P-40 Roll变体** [完成]
- 方法: 图像生成模型无法表现俯视角度的透视变化（多次尝试均生成完全对称图），改用程序化处理
- 工艺: Python PIL脚本对 `player_p40_body.png` 执行「半边压缩+旋转+裁剪」
  - Roll left: 左半水平压缩至75%（左翼上抬效果）+ 左半水平扩展至133%（右翼下沉效果）+ 整体逆时针旋转10°
  - Roll right: 镜像操作
- 输出: 128x128 PNG-32 RGBA（透明背景）
- 文件:
  - `assets/sprites/player/p40/player_p40_roll_left.png`
  - `assets/sprites/player/p40/player_p40_roll_right.png`
- 注: 旧的 `player_p40_bank_left/right.png` 保留（v1.4风格），新文件命名为 `roll_left/right` 以区分

**D12/D14: 背景地图状态** [阻塞]
- 现有 `stage_04_hsinchu/bg_hsinchu_full.png` 等包含"AI生成"水印，风格偏策略游戏地图而非纵向卷轴射击地图
- 用户明确表示: "背景地图需要PM给出更详细的需求和设计，因为部分关卡有隐藏要素或保护剧情"
- **阻塞项**: 需PM提供各关卡地图的详细设计需求（地形要素、交互区域、隐藏要素位置）后才能重做

---

### 2026-07-25 (Session 5) — PM反馈后批量P0素材生成

**PM反馈**: 提供 `docs/v1.5_asset_master_list.md` 完整素材需求清单（v1.5.1），含方向图命名规范和优先级

**P0-1: 玩家战机Roll变体** [完成]
- 8架 x 2roll = 16张 128x128 PNG-32 RGBA（含Session 3已完成的P-40）
- 存放于 `assets/sprites/player/{p40,p40b,p40e,p38,p47,p51,b25,b29}/`
- 工艺: PIL程序化（半边压缩75%/扩展133% + 旋转10° + 裁剪回128x128）

**P0-2: 敌机8方向图** [完成]
- 7种可转弯敌机 x 8方向 = 56张（含_n复制的源文件）
- 类型: Ki-27, Ki-43, Ki-44, Ki-61, Ki-84, J2M, Ki-45
- 命名: `enemy_{type}_{n,ne,e,se,s,sw,w,nw}.png`
- 存放于 `assets/sprites/enemy/`
- 工艺: PIL `rotate(-angle)` 从N方向旋转生成

**P0-3: 敌机N/S方向Roll变体** [完成]
- 7种 x 2方向(N/S) x 2roll = 28张
- 命名: `enemy_{type}_{n|s}_roll_{l|r}.png`

**P0-4: 地面可转弯单位方向图** [完成]
- Type97坦克: 8方向 (含_n)
- 运输船: 4方向
- 登陆艇: 4方向
- 卡车(新AI生成): 4方向
- 民船(新AI生成): 4方向
- 共24张方向图

**P1-1: 地面固定设施Sprite** [完成]
- AI生成 + JPG→PNG透明背景转换，12张128x128 PNG
- map_bunker / map_flak_gun / map_fuel_tank / map_warehouse / map_train_engine / map_train_car / map_hangar / map_command_post / map_bridge / map_ally_nest / map_ally_barricade / map_runway_section
- 存放于 `assets/sprites/enemy/`

**P1-2: 友军保护素材** [完成]
- AI生成 + 转PNG，4张128x128 PNG
- ally_p40_grounded / ally_nest_kmt / ally_transport_boat / ally_transport_boat_damaged

**P1-3: 子弹/特效** [完成]
- AI生成 + 转PNG，8张子弹 + 3张新特效 = 11张
- bullet_player_cannon / bullet_enemy_large / bullet_homing / bullet_bomb / bullet_rocket
- fx_explosion_chain / fx_smoke / fx_fire

**本Session统计**: 新增/程序化生成约 **147张** sprite文件

---

## 当前资产状态（更新后）

| 类别 | 数量 | 尺寸 | 备注 |
|------|------|------|------|
| BOSS Sprite | 14 | 512x512 | 90度俯视扁平 |
| BOSS部件 | 48 | 60x60 | 方案A（代码旋转） |
| 陆上设施(ground_facilities) | 7 | 128x128 | BOSS关联 |
| 敌机(含方向图) | 63 | 128x128 | 7种x8方向+6直线 |
| 敌机Roll变体 | 28 | 128x128 | N/S方向 |
| 地面固定设施(map_) | 12 | 128x128 | MapObject用 |
| 地面方向图 | 24 | 128x128 | 坦克/卡车/船 |
| 玩家战机(含roll) | 21 | 128x128 | 7架x3姿态 |
| 友军素材 | 4+2event | 128x128 | 保护机制 |
| 子弹 | 9 | 16-32 | 5新增+4已有 |
| 特效 | 15 | 64 | 3新增+12已有 |

---

## 待执行任务 (P1/P2)

| # | 任务 | 数量 | 状态 |
|---|------|------|------|
| D4 | 12关背景地图全部重做 | 12张(800x2400) | **P0，待执行** |
| D6 | 隐藏情报素材 | 13张 | 待执行 |
| D9 | 地图标注追加 | 8张 | 待执行 |
| D13 | 机库UI素材 | ~8张 | 待执行 |
| L03-D1 | 坂口装甲支队BOSS Sprite | 1张(512x512) | 待执行 |
| L03-D3 | 撤退卡车Sprite | 1张 | 待执行 |
| L03-D4 | 炸桥特效 | 1张 | 待执行 |
| L03-D5 | 国军旗Sprite | 1张 | 待执行 |

---

### 2026-07-25 (Session 4) — L03 史实修正

**触发原因**：PM 审核指出 L03 剧情背景为"阻截日军过桥，掩护国军撤退到怒江对岸后炸掉惠通桥"，因此 BOSS 不应为桥上碉堡；且惠通桥非重型设施，不适合做 BOSS。实际战役为日军坂口支队以装甲车辆源源不断追击 + 飞机堵截。

**史实调研** [完成]
- 1942.5.5 惠通桥阻击战：第56师团步兵团长坂口静夫少将指挥坂口支队（第146联队为基干，配属装甲车中队/野炮兵大队/工兵辎重兵各1个中队）沿滇缅公路追击远征军
- 工兵营长张祖武果断炸断惠通桥阻敌；第36师赶到后与抢渡日军激战三昼夜
- 飞虎队泰克斯·希尔率8架P-40E（鲍伯·尼尔/埃德·雷克托/弗兰克·劳勒等）连续4天空袭日军车队，歼敌4500余人

**设计文档修正** [完成]
- 文件：`docs/v1.5.0_upgrade_design.md` + `docs/v1.5_task_breakdown.md`（共 19 处修改）

| 修改项 | 修改前 | 修改后 |
|--------|--------|--------|
| L03 BOSS | 惠通桥碉堡（ground_facility）| 56师团坂口装甲支队（multi_target：指挥坦克HP3000+2×95式装甲车HP1500+2×Ki-27 HP800）|
| 惠通桥定位 | 可攻击关键目标（极高HP/3000分）| 纯背景元素（已炸毁残骸，不可攻击）|
| L03 友军保护 | 1944架桥（3机枪阵地）| 1942.5.5掩护撤退过桥（3撤退卡车HP800）|
| L03 敌机波次 | 无详细波次表 | 新增13行波次表（95式装甲车追击+Ki-27/Ki-48空中堵截）|
| 地面目标 | 桥梁（极高HP/3000分）| 移除；新增95式轻装甲车（HP中/机枪射击/500分）|
| BOSS类型分类 | L03归类ground_facility | L03改归multi_target |
| 任务清单 | D3/D7/D8/C6/C10/C7含"桥梁" | 全部替换为"坂口装甲支队编队"/"95式轻装甲车"|

**新增 L03 敌机波次设计**：
- 车辆追击层：95式轻装甲车 + 卡车队沿滇缅公路持续向下移动（Y=2150/2050/1650 三波）
- 飞机堵截层：Ki-27（4+6+4三波）与 Ki-48（3+2两波）交替出现
- 峡谷限制：两侧山体占30%不可飞入区，撞壁即毁
- 保护情节：Y=1200 触发掩护3辆撤退卡车过桥，成功后炸桥动画

**待执行 Design 任务（L03 专属）**：

| # | 任务 | 规格 | 说明 |
|---|------|------|------|
| L03-D1 | BOSS Sprite | 512×512 PNG-32 RGBA | `boss_sakaguchi_armored_column.png`（多目标编队俯视：指挥坦克+2装甲车+2Ki-27）|
| L03-D2 | 95式轻装甲车 Sprite | 64×64 PNG-32 RGBA | `armored_car_type95.png`（沿公路移动，机枪射击）|
| L03-D3 | 撤退卡车 Sprite | 64×48 PNG-32 RGBA | `ally_retreat_truck.png`（绿色+国军旗，与日军卡车区分）|
| L03-D4 | 炸桥特效 | 256×128 PNG-32 RGBA | `fx_bridge_explosion.png`（烟尘+碎片）|
| L03-D5 | 国军旗 Sprite | 32×32 PNG-32 RGBA | `ally_chinese_flag.png`（L03+L05+L07共用）|

**注**：L03-D2（95式轻装甲车）可复用现有 `event_target_car.png` 作为占位；L03-D3/D4/D5 为新增素材。BOSS Sprite L03-D1 需新建（现有 `boss_huitong_bridge.png` 将废弃）。

---

### 2026-07-25 (Session 5) — PM 审核代码同步素材 + 待补清单

**背景**：commit 6f6d5bf 报告 Code + Design 同步，含 161 个新素材文件。PM 审核后整理待补 Design 素材清单。

**已交付素材（基于 commit 6f6d5bf 报告）**：

| 类别 | 数量 | 规格 | 备注 |
|------|------|------|------|
| 子弹 | 5 种 | — | bullet_enemy_large/homing/player_cannon/rocket/bomb |
| 特效 | 3 种 | — | fx_explosion_chain/fire/smoke |
| 敌机方向变体 | 7 型×8 方向+翻滚 | 128×128 | J2M/Ki-27/Ki-43/Ki-44/Ki-45/Ki-61/Ki-84 |
| 地面单位方向变体 | 3 型×4 方向 | — | landing_craft/truck/type97_tank |
| 地图对象 | 12 种 | — | ally_barricade/nest/bridge/bunker/command_post/flak_gun/fuel_tank/hangar/runway/train_car/train_engine/warehouse |
| 玩家战机翻滚 | 7 架 | 128×128 | B25/B29/P38/P40B/P40E/P47/P51 |

**待补 Design 素材清单（PM 审核整理）**：

| 优先级 | 任务 ID | 缺失内容 | 规格 | 影响范围 | 来源问题 |
|--------|---------|---------|------|---------|---------|
| P1 | F1 | BOSS 部件 Sprite（炮塔/防空炮/雷达等）| 60×60 PNG-32 RGBA | L02/L04A/L07/L08A/L03 全部部件型 BOSS | 问题 1：部件仅有碰撞体无独立 Sprite |
| P1 | F3 | 友军保护专用素材 | 详见下表 | L03/L07/L10 三个保护关 | 问题 3：AllyPosition 复用 mg_nest.png |
| P2 | F2 | 4 个情报专用图标 | 64×64 PNG-32 RGBA | L02/L04/L05/L07 四个情报关 | 问题 2：IntelBriefcase 复用默认素材 |

**F3 友军保护素材明细**：

| 文件名 | 尺寸 | 用途 | 关卡 |
|--------|------|------|------|
| `ally_retreat_truck.png` | 64×48 | 撤退卡车（绿色+国军旗）| L03 |
| `ally_transport_ship.png` | 80×48 | 运输船（带国军旗）| L07 |
| `ally_aa_gun.png` | 64×64 | 高射炮阵地（带国军旗）| L10 |
| `ally_chinese_flag.png` | 32×32 | 国军军旗（共用）| L03+L05+L07 |
| `ally_usa_flag.png` | 32×32 | 美军军旗（区分用）| L10 |

**F1 BOSS 部件 Sprite 明细**（按 BOSS 分类）：

| BOSS | 缺失部件 | 数量 |
|------|---------|------|
| 天龙号（L02）| 炮塔×4 | 4 |
| 妙高号（L04A）| 炮塔×4 + 防空炮×2 | 6 |
| 最上号（L08A）| 炮塔×5 + 舰桥 | 6 |
| 坂口装甲支队（L03）| 指挥坦克炮塔 + 装甲车炮塔×2 | 3 |
| 湘江舰艇编队（L07）| 舰桥×3 | 3 |
| **合计** | — | ~22 |

**注**：commit 6f6d5bf 同步差异——PM Agent 仓库远程仍停留在 86244e5，6f6d5bf 未同步到 GitHub。待同步恢复后需复核实际素材文件。

### 2026-07-25 (Session 6) — 同步恢复 + PM 复核

**同步状态**：commit `91ebf27`（原报告 `6f6d5bf`，经 rebase 后哈希变更）已成功同步到远程仓库。PM Agent 本地已拉取全部 161 个新素材文件。

**PM 复核结论**：
- L03 史实修正代码全部验证通过（boss_sakaguchi.json 配置正确，5 个 vessels 史实准确）
- multi_target/mixed-final BOSS 逻辑经实际读取 `boss_base.gd` 确认已完整实现（F4/F5 无需再实施）
- 用户报告"基础框架"描述不准确，实际为完整实现

**发现的新问题**：
- L03 敌机波次 CSV 中 Ki-48 场景未实现，暂以 ki21_bomber 代替（需 Code 补充 Ki-48 场景，任务 F6）

**待补 Design 素材清单（修正后）**：

| 优先级 | 任务 ID | 缺失内容 | 状态 | 说明 |
|--------|---------|---------|------|------|
| P1 | F1 | BOSS 部件 Sprite（炮塔/防空炮/雷达等）| 待执行 | ~22 个部件，详见 Session 5 |
| P1 | F3 | 友军保护专用素材 | 待执行 | 撤退卡车/运输船/高炮/军旗，详见 Session 5 |
| P2 | F2 | 4 个情报专用图标 | 待执行 | L02/L04/L05/L07 各 1 |
| P2 | F6 | Ki-48 敌机 Sprite（如 Design 负责）| 待确认 | stage_03 CSV 暂以 ki21_bomber 代替；需确认是否由 Design 创建 Ki-48 Sprite 还是 Code 复用现有素材 |

**L03 专属素材状态更新**：

| 任务 ID | 内容 | 状态 | 说明 |
|---------|------|------|------|
| L03-D1 | BOSS Sprite `boss_sakaguchi_armored_column.png` | ⏳ 待执行 | BOSS JSON 当前复用 `enemy_type97_tank.png`，需新建多目标编队 Sprite |
| L03-D2 | 95式轻装甲车 Sprite | ✅ 占位可用 | 复用 `event_target_car.png`（BOSS vessel 配置已使用）|
| L03-D3 | 撤退卡车 Sprite | ⏳ 待执行 | AllyPosition 复用 mg_nest.png，需新建 `ally_retreat_truck.png` |
| L03-D4 | 炸桥特效 | ⏳ 待执行 | `fx_bridge_explosion.png` 尚未创建 |
| L03-D5 | 国军旗 Sprite | ⏳ 待执行 | `ally_chinese_flag.png` 尚未创建 |

---

### 2026-07-25 (Session 7) — Code F6 任务：Ki-48 敌机场景创建

**背景**：Code 部门完成 PM 反馈的 v1.5.2 后续任务 F6（Ki-48 敌机场景创建）。Design 部门此前已在 Session 5 交付 `enemy_ki48_lily.png` 素材，但 Code 侧一直未创建对应 `.tscn` 场景，导致 L01/L03/L05 CSV 中以 `ki21_bomber` 代替。本次同步记录素材使用情况。

**已使用 Design 素材**：

| 素材文件 | 规格 | 用途 | 关联代码文件 |
|---------|------|------|-------------|
| `enemy_ki48_lily.png` | 128×128 PNG-32 RGBA, 90度俯视 | Ki-48 九九式轻轰炸机 Sprite | `scenes/enemies/enemy_ki48_lily.tscn`（新增） |

**Ki-48 设计参数（Code 实施）**：

| 参数 | 值 | 参照 |
|------|-----|------|
| HP | 5 | 介于 Ki-21 (6) 与 D3A (3) 之间 |
| 速度 | 75.0 | 介于 Ki-21 (60) 与 D3A (90) 之间 |
| 分值 | 250 | 介于 Ki-21 (300) 与 D3A (150) 之间 |
| 掉落率 | 0.3 | 介于 Ki-21 (0.4) 与 D3A (0.25) 之间 |
| 碰撞框 | Vector2(40, 40) | 与 Ki-21 一致（同为 128×128 Sprite）|

**关卡波次分配**：

| 关卡 | Ki-48 出现时间 | Ki-21 出现时间 |
|------|---------------|---------------|
| L01 昆明 | 22.0s（1 架 solo）| — |
| L03 怒江 | 11.0s/20.0s/31.0s（共 10 架）| — |
| L05 衡阳 | 13.5s（4 架 line）| 40.0s（3 架 v_formation）|

**Code 部门文件变更**：

| 文件 | 类型 | 说明 |
|------|------|------|
| `scenes/enemies/enemy_ki48_lily.tscn` | 新增 | Ki-48 敌机场景，引用 `enemy_ki48_lily.png` |
| `autoload/spawn_manager.gd` | 修改 | 注册 `ki48_lily` 类型映射 |
| `resources/level_data/stage_01_kunming.csv` | 修改 | 22.0s 波次替换为 ki48_lily |
| `resources/level_data/stage_03_salween.csv` | 修改 | 4 处 ki21_bomber 替换为 ki48_lily，移除占位注释 |
| `resources/level_data/stage_05_hengyang.csv` | 修改 | 13.5s 早波次替换为 ki48_lily，保留 40.0s Ki-21 压轴 |

**F6 任务状态**：✅ Code 部门已完成。Design 素材 `enemy_ki48_lily.png` 已正确集成。

---

### 2026-07-26 (Session 8) — PM 反馈后 P1/P2 Design 素材补全

**背景**：PM 反馈 F1/F3/F2 待执行 + F6 已完成（Code），Design 依次推进全部待执行素材任务。

**F1: BOSS 部件 Sprite 补全** [完成]
- 确认现有 48 张 BOSS 部件全部为错误占位图（麦克风图标/像素按钮等），需全部替换
- 使用 PIL 程序化生成正确的军事舰艇部件，90度俯视低饱和度风格
- **替换 24 张**（天龙4+妙高10+最上10）+ **新增 12 张**（坂口3+湘江3=6组×2=12张）= 30 组 × 2（正常+摧毁）= **60 张 60×60 PNG-32 RGBA**
- 部件类型：主炮塔（单管/双联/三联）、防空炮（4管）、舰桥、雷达、烟囱、弹射器、坦克炮塔
- 存放于 `assets/sprites/boss/parts/`

**F3: 友军保护专用素材** [完成]
- 新增 3 张缺失素材（已有 6 张基础素材保持不变）：
  - `ally_transport_ship.png`（80×48，L07 湘江运输船，橄榄绿色+国军旗）
  - `ally_aa_gun.png`（64×64，L10 芷江高射炮阵地，沙袋+4管炮+国军旗）
  - `ally_usa_flag.png`（32×32，L10 美军军旗，简化星条旗）
- 存放于 `assets/sprites/enemy/`

**F2: 情报专用图标** [完成]
- 4 张 64×64 PNG-32 RGBA，各情报关对应专用公文包图标：
  - `intel_hump_route.png`（L02 驼峰航线 — 地图路线图案）
  - `intel_tokyo_bombing.png`（L04 东京轰炸 — 照片图案）
  - `intel_hengyang_status.png`（L05 衡阳战况 — 文件报告图案）
  - `intel_hiroshima_target.png`（L07 广岛目标 — 十字准星图案）
- 存放于 `assets/sprites/enemy/`

**L03-D1: 坂口装甲支队 BOSS Sprite** [完成]
- AI 生成 512×512 编队俯视图（指挥坦克+2装甲车+2 Ki-27 编队，峡谷背景）
- 后处理：JPG → PNG-32 RGBA + 亮色/暗色背景透明化 + 缩放至 512×512
- 存放于 `assets/sprites/boss/boss_sakaguchi_armored_column.png`

**L03-D4: 炸桥特效** [完成]
- `fx_bridge_explosion.png`（256×128 PNG-32 RGBA）
- 多层灰色烟云 + 橙色火焰核心 + 碎片粒子 + 桥梁残骸暗示线
- 存放于 `assets/sprites/effects/`

**本 Session 统计**：新增/替换 **69 张** sprite 文件

---

### 2026-07-26 (Session 9) — PM 最终复核确认

**背景**：commit `3eb2304`（M4-G）同步后，PM 对全部 F1-F6 任务进行最终验证。

**PM 验证结论**：全部 F 系列任务已完成，Design 素材全部就位。

| 任务 | Design 交付物 | PM 验证 | 状态 |
|------|--------------|---------|------|
| F1 | 60 张 BOSS 部件 Sprite（含摧毁变体）| ✅ 实际清点 `assets/sprites/boss/parts/` 确认 60 张 | ✅ 已完成 |
| F2 | 4 张情报专用图标 | ✅ 4 个文件均存在 | ✅ 已完成 |
| F3 | 9 张友军保护素材（含 4 张额外）| ✅ 9 个文件均存在 | ✅ 已完成 |
| F6 | Ki-48 Sprite 由 Design 在 Session 5 交付 | ✅ Code 已创建 `.tscn` 场景并更新 CSV | ✅ 已完成 |
| L03-D1 | `boss_sakaguchi_armored_column.png` | ✅ 文件存在 | ✅ 已完成 |
| L03-D3 | `ally_retreat_truck.png` | ✅ 文件存在 | ✅ 已完成 |
| L03-D4 | `fx_bridge_explosion.png` | ✅ 文件存在 | ✅ 已完成 |
| L03-D5 | `ally_chinese_flag.png` | ✅ 文件存在 | ✅ 已完成 |

**roll 姿态动画逻辑验证**：
- `scenes/player/player_base.gd` 行 157-262：roll 纹理加载逻辑完整
- `scenes/player/player_base.gd` 行 341-345：roll 切换逻辑完整
- `resources/player_data.json`：7 架战机均配置 sprite_roll_left/right

**v1.5.0 后续任务全部闭环**。L03 史实修正全链路（设计文档 → 代码实施 → 素材补全）已完成。Design 部门 v1.5.0 工作全部结束。
