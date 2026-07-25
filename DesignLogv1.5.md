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

## 待执行任务 (P1)

| # | 任务 | 数量 | 状态 |
|---|------|------|------|
| D6 | 隐藏情报素材 | 13张 | 待执行 |
| D7 | 友军保护素材 | 5张 | 待执行 |
| D9 | 地图标注追加 | 8张 | 待执行 |
| D11 | 地面目标Sprite | 5张 | 待执行 |
| D12 | 新隐藏关背景 | 2张 | 待执行 |
| D13 | 机库UI素材 | ~8张 | 待执行 |
| D14 | 旧背景清理/重命名 | 6张 | 待执行 |

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
