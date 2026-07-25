# Flying Tigers 1945 — Stable Diffusion 素材绘制清单

> **版本**: v1.0
> **日期**: 2026-07-14
> **数据来源**: sprite_list.txt (221 PNG) + DesignLog.md + design_art_style_guide.md
> **用途**: 指导 Stable Diffusion (或类似 AI 生图工具) 重新生成全部项目素材

---

## 总表统计

| 类别 | 目录内文件数 | 跳过 (hitbox_ref) | 跳过 (拼接文件) | 需 SD 生成 | 尺寸范围 |
|------|-------------|-------------------|-----------------|------------|---------|
| **backgrounds** | 61 | 0 | 1 (bg_hump_extreme_full) | 60 | 512x2048 / 512x6144 |
| **player** | 24 | 4 | 0 | 20 | 128x128 ~ 160x144 / 螺旋桨长条 |
| **enemy** | 40 | 13 | 0 | 27 | 80x64 ~ 160x128 |
| **boss** | 43 | 0 | 0 | 43 | 512x512 / 256x256(爆炸帧) / 512x512(蘑菇云) |
| **effects** | 12 | 0 | 0 | 12 | 64x64 ~ 512x512 |
| **bullets** | 4 | 0 | 0 | 4 | 8x24 ~ 64x128 |
| **powerups** | 3 | 0 | 0 | 3 | 48x48 |
| **ui** | 34 | 0 | 0 | 34 | 32x32 ~ 1920x1080 |
| **合计** | **221** | **17** | **1** | **203** | — |

> **说明**:
> - 17 个 `hitbox_ref` 文件（玩家 4 个 + 敌机 13 个）为手动叠加红色半透明到 body 上的参考图，不需要 SD 生成。
> - `bg_hump_extreme_full.png` 为 3 段拼接文件，需分段生成后拼接。
> - enemy/ 目录下 5 个 `event_*` 文件（event_target_bridge, event_target_bridge_broken, event_target_car, event_transport_ship, event_transport_wreck）因游戏关联性归入 Boss 章节文档记录，目录归属仍为 enemy/。

---

## 通用风格前缀（Style Prefix）

所有素材共享以下基础风格约束，在各类别模板中已内置：

```
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945),
hand-painted with 3D volumetric shading, military cartoon realism
```

---

## 1. Backgrounds（背景）— 52 文件

### 通用提示词模板（陆地关卡）

```
Top-down orthographic view of {SUBJECT}, WWII era,
hand-painted game texture style with visible brush strokes and material textures,
low saturation earth tones (olive/brown/tan), no sky, no horizon line,
90 degree vertical overhead camera, no perspective distortion,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945),
small military buildings with shadow casting (top-lit, bottom-dark),
clustered dark green bush/tree canopies, dirt roads,
muted color palette serving as gameplay background, seamless vertical scrolling tile,
top-down orthographic, 90 degree overhead, no sky no horizon, hand-painted game texture style
```

### 通用提示词模板（海洋关卡）

```
Top-down orthographic view of {SUBJECT}, deep blue-green water (#0a3a5a),
subtle wave ripple texture, hand-painted game art style,
low saturation cool tones, no sky, no horizon line,
90 degree vertical overhead camera, game art style like classic arcade STG,
small white foam/wake trails suggesting ship movement,
muted color palette for gameplay background, seamless vertical scrolling tile,
top-down orthographic, 90 degree overhead, no sky no horizon, hand-painted game texture style
```

**技术参数**: 512x2048, transparent background (PNG), seamless vertical scrolling tile

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) |
|---|--------|------|------|----------------------|
| | **Stage 01 昆明 (5张)** | | | |
| 1 | `bg_kunming_ground.png` | 512x2048 | 红土地面纹理，干草碎石农沟 | Yunnan red earth ground texture, dry yellow grass patches, small pebbles, shallow irrigation ditches, farmland soil |
| 2 | `bg_kunming_lake.png` | 512x2048 | 滇池湖面，中式木船渔网，芦苇岸 | Dianchi lake surface with calm water ripples, small Chinese wooden fishing boats with nets from above, reed-covered shoreline |
| 3 | `bg_kunming_mid.png` | 512x2048 | 昆明城市顶视，灰瓦屋顶群，蟠龙江，土路农田 | Kunming city rooftops from above, gray tiled Chinese houses, Panlong river winding through, dirt roads, rice paddy fields |
| 4 | `bg_kunming_mountain.png` | 512x2048 | 西山密林，岩石露头，小径，Boss战区域 | Xishan mountain dense forest canopy from above, dark green tree clusters, exposed gray rock, narrow footpaths, boss arena clearing |
| 5 | `bg_kunming_near.png` | 512x2048 | 机场停机坪，3架P40横放，地勤员油桶油车 | Kunming airbase tarmac from above, 3 P-40 Warhawk fighters parked sideways, ground crew, fuel barrels, fuel truck |
| | **Stage 02 仰光 (4张)** | | | |
| 6 | `bg_rangoon_far.png` | 512x2048 | 港口远景轮廓，伊洛瓦底江岸线 | Rangoon harbor distant skyline, Irrawaddy river delta coastline, faint warehouse silhouettes |
| 7 | `bg_rangoon_ground.png` | 512x2048 | 港口地面，碎石，木质栈桥，油污 | Harbor ground surface, crushed stone, wooden pier planks, oil stains, rope coils |
| 8 | `bg_rangoon_mid.png` | 512x2048 | 港口设施，仓库，起重机，货车，弹坑 | Rangoon port facilities from above, warehouses, cargo cranes, military trucks, bomb craters on road |
| 9 | `bg_rangoon_near.png` | 512x2048 | 近景码头细节，集装箱，缆绳，积水 | Dock close-up details, cargo containers, mooring ropes, rain puddles, wooden dock planks |
| | **Stage 03 怒江 (4张)** | | | |
| 10 | `bg_nujiang_far.png` | 512x2048 | 怒江峡谷远山轮廓，云雾 | Nu River (Salween) canyon distant mountain ridges, thin cloud wisps, deep valley edges |
| 11 | `bg_nujiang_ground.png` | 512x2048 | 河岸碎石，沙地，水边湿泥 | Riverbank gravel and sand, wet mud at water edge, scattered rocks |
| 12 | `bg_nujiang_mid.png` | 512x2048 | 怒江峡谷地形，江面，山路，浮桥 | Nu River canyon terrain, fast-flowing river, winding mountain road, pontoon bridge crossing |
| 13 | `bg_nujiang_near.png` | 512x2048 | 近景河岸植被，灌木丛，岩石 | Riverbank vegetation close-up, dense bush clusters, wet rocks, hanging vines |
| | **Stage 04 驼峰 (4张)** | | | |
| 14 | `bg_hump_far.png` | 512x2048 | 雪山山顶俯视，白色雪面，灰岩冰裂缝 | Himalaya snow mountain peak from directly above, white snow surface, gray rock ridges, blue ice crevasses |
| 15 | `bg_hump_ground.png` | 512x2048 | 冰雪地面纹理，冰面裂缝，岩石碎片 | Ice and snow ground texture, white ice surface, thin cracks, small dark rock fragments |
| 16 | `bg_hump_mid.png` | 512x2048 | 冰川地形，蓝色冰裂缝，岩石区域 | Glacier terrain from above, deep blue ice crevasse patterns, exposed dark rock areas, snow patches |
| 17 | `bg_hump_near.png` | 512x2048 | 近景冰面细节，雪堆，冰晶 | Ice surface close-up details, snow drifts, ice crystal formations, frozen puddles |
| | **Stage 05 桂林 (4张)** | | | |
| 18 | `bg_guilin_far.png` | 512x2048 | 喀斯特峰林远景轮廓，漓江蜿蜒 | Karst peak forest distant silhouettes, Li River meandering, misty mountain outlines |
| 19 | `bg_guilin_ground.png` | 512x2048 | 地面纹理，碎石路，农田田埂，弹坑 | Guilin ground surface, gravel paths, rice paddy field ridges, bomb craters from battle |
| 20 | `bg_guilin_mid.png` | 512x2048 | 喀斯特峰林俯视，漓江，竹林，村落 | Guilin karst limestone peaks from above, Li River with small boats, bamboo groves, village rooftops, bomb craters |
| 21 | `bg_guilin_near.png` | 512x2048 | 近景竹林，芭蕉叶，石板路 | Bamboo grove close-up, banana leaves from above, stone pathway, small stream |
| | **Stage 06 衡阳 (4张)** | | | |
| 22 | `bg_hengyang_far.png` | 512x2048 | 城市废墟远景，烟柱，暗红天空反光 | Hengyang city ruins distant view, smoke columns rising, dark red glow from fires, destroyed building outlines |
| 23 | `bg_hengyang_ground.png` | 512x2048 | 废墟地面，碎石砖块，焦土，弹坑 | Ruined city ground, broken bricks and rubble, scorched earth, multiple bomb craters, debris |
| 24 | `bg_hengyang_mid.png` | 512x2048 | 城市废墟顶视，倒塌建筑，街道，火焰 | Hengyang destroyed city from above, collapsed buildings, cratered streets, scattered fires and smoke |
| 25 | `bg_hengyang_near.png` | 512x2048 | 近景废墟细节，瓦砾堆，燃烧残骸 | Urban ruin close-up, brick rubble piles, smoldering wreckage, broken wooden beams |
| | **Stage 07 芷江 (4张)** | | | |
| 26 | `bg_zhijiang_far.png` | 512x2048 | 机场远景，机库群，塔台轮廓 | Zhijiang airbase distant view, hangar clusters, control tower silhouette, runway outline |
| 27 | `bg_zhijiang_ground.png` | 512x2048 | 停机坪磨损混凝土，轮胎痕，油渍 | Worn concrete tarmac, tire marks, oil stains, small maintenance tools, expansion joints |
| 28 | `bg_zhijiang_mid.png` | 512x2048 | 跑道，P-40停放区，地勤车辆，机库 | Zhijiang airbase from above, main runway, P-40 fighters parked, ground support vehicles, hangars |
| 29 | `bg_zhijiang_near.png` | 512x2048 | 草地，导航标识，挡轮器，标线 | Grass infield, runway navigation markers, wheel chocks, painted taxiway lines |
| | **Stage 08 武汉 (4张)** | | | |
| 30 | `bg_wuhan_far.png` | 512x2048 | 长江江面，汉口城市网格远景 | Yangtze River water surface, Hankou city grid distant view, bridge outline |
| 31 | `bg_wuhan_ground.png` | 512x2048 | 石板路，积水，碎片，路面破损 | Stone paved road, rain puddles, street debris, damaged road surface |
| 32 | `bg_wuhan_mid.png` | 512x2048 | 码头，货轮甲板，仓库，起重机 | Wuhan dockyard from above, cargo ship deck, warehouses, loading cranes, river port facilities |
| 33 | `bg_wuhan_near.png` | 512x2048 | 城市街道，建筑屋顶，车辆，小巷 | City street close-up, building rooftops, military vehicles, narrow alleyways |
| | **Stage 09 南昌 (4张)** | | | |
| 34 | `bg_nanchang_far.png` | 512x2048 | 鄱阳湖水面，湖岸线远景 | Poyang Lake water surface, distant shoreline, faint wetland patterns |
| 35 | `bg_nanchang_ground.png` | 512x2048 | 湖岸泥地，芦苇根，贝壳碎 | Lake mudflat, reed roots, shell fragments, wet earth |
| 36 | `bg_nanchang_mid.png` | 512x2048 | 鄱阳湖湖岸，农田，村庄，渔船 | Poyang Lake shoreline, rice paddies, small village, fishing boats anchored at shore |
| 37 | `bg_nanchang_near.png` | 512x2048 | 近景湖岸，泥岸，水草，碎石 | Lake shore close-up, muddy bank, water grass patches, scattered pebbles |
| | **Stage 10 上海 (4张)** | | | |
| 38 | `bg_shanghai_far.png` | 512x2048 | 黄浦江，外滩建筑群远景 | Huangpu River, Bund colonial building skyline distant view, ship wakes |
| 39 | `bg_shanghai_ground.png` | 512x2048 | 石板路，电车轨道，路面铺设 | Shanghai street surface, cobblestone, tram tracks, asphalt patches |
| 40 | `bg_shanghai_mid.png` | 512x2048 | 外滩码头，殖民建筑屋顶，街道 | Shanghai Bund waterfront from above, colonial building rooftops, busy docks, streets with vehicles |
| 41 | `bg_shanghai_near.png` | 512x2048 | 近景街道细节，铺路石，商店招牌 | Street close-up, paving stones, shop sign shadows, street lamps, manhole covers |
| | **Stage 11 南京 (4张)** | | | |
| 42 | `bg_nanjing_far.png` | 512x2048 | 长江，城墙远景，紫金山轮廓 | Yangtze River, Nanjing city wall distant outline, Zijin Mountain silhouette |
| 43 | `bg_nanjing_ground.png` | 512x2048 | 城区碎石，瓦砾，弹坑，焦土 | City rubble ground, broken tiles, bomb craters, scorched earth |
| 44 | `bg_nanjing_mid.png` | 512x2048 | 南京城墙，城区废墟，秦淮河 | Nanjing city wall from above, ruined city blocks, Qinhuai River, destroyed buildings |
| 45 | `bg_nanjing_near.png` | 512x2048 | 近景城墙砖块，碎石堆，杂草 | City wall brickwork close-up, rubble piles, weeds growing in cracks |
| | **Stage 12 东京 (4张)** | | | |
| 46 | `bg_tokyo_far.png` | 512x2048 | 夜视城市远景，微光轮廓，暗红天空 | Tokyo night cityscape distant view, dim building outlines, dark red sky glow from fires |
| 47 | `bg_tokyo_ground.png` | 512x2048 | 焦土，灰烬，瓦砾，燃烧痕迹 | Scorched earth, ash and cinders, rubble, burn marks, ember traces |
| 48 | `bg_tokyo_mid.png` | 512x2048 | 东京工业区燃烧，建筑废墟，火焰 | Tokyo industrial district burning from above, factory ruins, active flames, smoke columns |
| 49 | `bg_tokyo_near.png` | 512x2048 | 近景住宅区火海，燃烧残骸 | Residential area firestorm close-up, burning house frames, scattered debris |
| | **H1 驼峰极端 (3张 + 1拼接)** | | | |
| 50 | `bg_hump_extreme_far.png` | 512x2048 | 极端暴风雪天空层，能见度极低 | Extreme blizzard mountain far layer, near-zero visibility, whiteout conditions, faint rock outlines |
| 51 | `bg_hump_extreme_mid.png` | 512x2048 | 冰川地形，蓝色冰裂缝，岩石，Boss区 | Extreme glacier terrain, deep blue ice crevasses, dark rock outcrops, boss arena plateau |
| 52 | `bg_hump_extreme_near.png` | 512x2048 | 近景暴风雪，冰岩碎片，雪堆 | Blizzard near layer, ice rock debris, snow drifts, low visibility, frozen puddles |
| — | `bg_hump_extreme_full.png` | 512x6144 | **需分段生成后拼接**（段1平坦冰雪，段2冰川地形，段3高山高原），crossfade 64px | **SKIP — composite file, generate 3 segments separately then stitch** |
| | **H2 东京轰炸 (3张)** | | | |
| 53 | `bg_tokyo_raid_far.png` | 512x2048 | 轰炸城市远景，大面积火海，烟柱 | Tokyo firebombing distant view, massive fire zones, towering smoke columns, burning city grid |
| 54 | `bg_tokyo_raid_mid.png` | 512x2048 | 工业区轰炸，燃烧工厂，倒塌建筑 | Industrial district firebombing, burning factories, collapsed warehouses, fire spread patterns |
| 55 | `bg_tokyo_raid_near.png` | 512x2048 | 近景火风暴，燃烧碎片，热浪 | Firestorm close-up, burning debris, heat distortion, smoldering structures |
| | **H3 紫电竞技场 (2张)** | | | |
| 56 | `bg_shiden_arena_far.png` | 512x2048 | 太平洋海面远景，无陆地 | Open Pacific Ocean far view, vast empty water surface, no land visible |
| 57 | `bg_shinden_arena_mid.png` | 512x2048 | 太平洋海面中景，尾迹，波纹 | Pacific Ocean mid layer, wake trails from aircraft, wave ripple patterns, deep blue-green water |
| | **H4 广岛 (3张)** | | | |
| 58 | `bg_hiroshima_far.png` | 512x2048 | 广岛轰炸前景象，城市完整 | Hiroshima city before bombing, intact city grid, rivers, bridges, green areas |
| 59 | `bg_hiroshima_ground.png` | 512x2048 | 核爆废墟地面，灰白焦土，阴影 | Nuclear aftermath ground, gray-white scorched earth, permanent shadows burned into surface |
| 60 | `bg_hiroshima_mid.png` | 512x2048 | 核爆废墟中心，建筑轮廓消融 | Hiroshima nuclear devastation from above, building outlines melted away, flattened rubble, ash-covered surface |

---

## 2. Player（玩家战机）— 20 文件

### 通用提示词模板

```
Flat 2D, top-down view of {SUBJECT},
WWII American {AIRCRAFT_TYPE}, olive drab/silver camouflage,
hand-painted game sprite with 3D volumetric shading (top-lit, sides darker),
metallic skin with panel lines and canopy glass reflection,
[bank_left: "banking left 20 degrees" / bank_right: "banking right 20 degrees" / body: "level flight, wings horizontal" / hit: "on fire with smoke and damage marks" / propeller: "propeller blur motion, 3-frame sprite strip"],
clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 见下表, PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) |
|---|--------|------|------|----------------------|
| | **P-40 战鹰 Warhawk (5张)** | | | |
| 1 | `player_p40_body.png` | 128x128 | P-40 正面俯视，平飞姿态 | Curtiss P-40 Warhawk fighter, shark mouth nose art, olive drab camo, level flight, wings horizontal |
| 2 | `player_p40_bank_left.png` | 128x128 | P-40 左倾 20° | Curtiss P-40 Warhawk, banking left 20 degrees, olive drab camo |
| 3 | `player_p40_bank_right.png` | 128x128 | P-40 右倾 20° | Curtiss P-40 Warhawk, banking right 20 degrees, olive drab camo |
| 4 | `player_p40_hit.png` | 128x128 | P-40 受伤冒烟 | Curtiss P-40 Warhawk, on fire with black smoke trails, bullet holes, wing damage |
| 5 | `player_p40_propeller.png` | 512x128 | P-40 螺旋桨旋转帧(3帧strip) | Curtiss P-40 Warhawk propeller blur motion, 3-frame horizontal sprite strip, spinning propeller disc |
| | **P-51 野马 Mustang (5张)** | | | |
| 6 | `player_p51_body.png` | 128x128 | P-51 正面俯视，平飞姿态 | North American P-51 Mustang fighter, silver aluminum finish, level flight, wings horizontal |
| 7 | `player_p51_bank_left.png` | 128x128 | P-51 左倾 20° | North American P-51 Mustang, banking left 20 degrees, silver finish |
| 8 | `player_p51_bank_right.png` | 128x128 | P-51 右倾 20° | North American P-51 Mustang, banking right 20 degrees, silver finish |
| 9 | `player_p51_hit.png` | 128x128 | P-51 受伤冒烟 | North American P-51 Mustang, on fire with smoke trails, battle damage |
| 10 | `player_p51_propeller.png` | 512x128 | P-51 螺旋桨旋转帧(3帧strip) | North American P-51 Mustang propeller blur, 3-frame horizontal sprite strip |
| | **P-38 闪电 Lightning (5张)** | | | |
| 11 | `player_p38_body.png` | 144x128 | P-38 正面俯视，双发机身 | Lockheed P-38 Lightning twin-boom fighter, olive drab camo, level flight, twin tail booms |
| 12 | `player_p38_bank_left.png` | 144x128 | P-38 左倾 20° | Lockheed P-38 Lightning, banking left 20 degrees, twin-boom |
| 13 | `player_p38_bank_right.png` | 144x128 | P-38 右倾 20° | Lockheed P-38 Lightning, banking right 20 degrees, twin-boom |
| 14 | `player_p38_hit.png` | 144x128 | P-38 受伤冒烟 | Lockheed P-38 Lightning, on fire, one boom damaged, smoke trailing |
| 15 | `player_p38_propeller.png` | 576x128 | P-38 双螺旋桨旋转帧(3帧strip) | Lockheed P-38 Lightning twin propeller blur, 3-frame horizontal sprite strip, two spinning discs |
| | **B-25 米切尔 Mitchell (5张)** | | | |
| 16 | `player_b25_body.png` | 160x144 | B-25 正面俯视，中型轰炸机 | North American B-25 Mitchell medium bomber, olive drab, level flight, wide wingspan |
| 17 | `player_b25_bank_left.png` | 160x144 | B-25 左倾 20° | North American B-25 Mitchell, banking left 20 degrees |
| 18 | `player_b25_bank_right.png` | 160x144 | B-25 右倾 20° | North American B-25 Mitchell, banking right 20 degrees |
| 19 | `player_b25_hit.png` | 160x144 | B-25 受伤冒烟 | North American B-25 Mitchell, on fire, engine smoking, fuselage damage |
| 20 | `player_b25_propeller.png` | 640x144 | B-25 双螺旋桨旋转帧(3帧strip) | North American B-25 Mitchell twin propeller blur, 3-frame horizontal sprite strip |

> **注意**: 4 个 `player_*_hitbox_ref.png` 文件已跳过（手动叠加红色半透明）。

---

## 3. Enemy（敌机）— 27 文件

### 通用提示词模板

```
Flat 2D, top-down view of WWII Japanese {AIRCRAFT_TYPE},
green/olive camouflage with red hinomaru roundel markings,
hand-painted game sprite with 3D volumetric shading,
metallic skin with panel lines and canopy glass reflection,
{POSTURE},
clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 见下表, PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) | 姿态 (POSTURE) |
|---|--------|------|------|----------------------|-----------------|
| | **战斗机/攻击机 (14张)** | | | | |
| 1 | `enemy_a6m_zero.png` | 96x96 | 零式舰战，俯视平飞 | Mitsubishi A6M Zero fighter, gray-green camo, red hinomaru | level flight, wings horizontal |
| 2 | `enemy_a6m_body.png` | 64x64 | 零式机身（无翼细节版） | Mitsubishi A6M Zero body only, compact | level flight |
| 3 | `enemy_a6m_side.png` | 128x64 | 零式侧面视图 | Mitsubishi A6M Zero side profile view | side view, horizontal flight |
| 4 | `enemy_d3a_val.png` | 104x96 | 九九式舰爆 | Aichi D3A Val dive bomber, green camo, fixed landing gear | level flight |
| 5 | `enemy_j7w_shinden.png` | 112x112 | 震电，前置鸭翼 | Kyushu J7W Shinden canard fighter, green camo, pusher propeller | level flight |
| 6 | `enemy_ki21_bomber.png` | 160x120 | 九七式重爆 | Mitsubishi Ki-21 Sally heavy bomber, green camo, large wingspan | level flight |
| 7 | `enemy_ki27_fighter.png` | 96x96 | 九七式战斗机 | Nakajima Ki-27 Nate fighter, olive green, fixed landing gear | level flight |
| 8 | `enemy_ki43_hayabusa.png` | 96x96 | 一式隼战斗机 | Nakajima Ki-43 Hayabusa Oscar fighter, green-brown camo | level flight |
| 9 | `enemy_ki43_body.png` | 64x64 | 隼机身（无翼细节版） | Nakajima Ki-43 Hayabusa body only, compact | level flight |
| 10 | `enemy_ki43_side.png` | 128x64 | 隼侧面视图 | Nakajima Ki-43 Hayabusa side profile view | side view, horizontal flight |
| 11 | `enemy_ki45_toryu.png` | 144x112 | 二式屠龙双发战斗机 | Kawasaki Ki-45 Toryu Nick twin-engine fighter, green camo | level flight |
| 12 | `enemy_ki61_hien.png` | 96x96 | 三式飞燕战斗机 | Kawasaki Ki-61 Hien Tony fighter, dark green camo, inline engine | level flight |
| 13 | `enemy_ki84_hayate.png` | 96x96 | 四式疾风战斗机 | Nakajima Ki-84 Hayate Frank fighter, dark green camo | level flight |
| 14 | `enemy_ohka_kamikaze.png` | 80x64 | 樱花自杀机 | Yokosuka MXY-7 Ohka cherry blossom kamikaze rocket plane, small | level flight |
| | **地面/特殊单位 (8张)** | | | | |
| 15 | `enemy_type97_tank.png` | 128x128 | 九七式中型坦克俯视 | Type 97 Chi-Ha medium tank from above, olive drab, turret and track treads visible |
| 16 | `enemy_landing_craft.png` | 128x128 | 登陆艇俯视 | Japanese landing craft from above, brown-gray, bow ramp, troop compartment |
| 17 | `enemy_observation_balloon.png` | 128x128 | 观测气球俯视 | Japanese observation barrage balloon from above, dark gray, gondola and cables visible |
| 18 | `event_bunker_hidden.png` | 128x128 | 伪装碉堡（丛林覆盖） | Hidden bunker disguised as jungle vegetation, green canopy cover, concealed gun ports |
| 19 | `event_bunker_revealed.png` | 128x128 | 暴露碉堡（混凝土射击口） | Revealed concrete military bunker, gun ports, camouflage net partially torn |
| 20 | `event_c47_ally.png` | 128x128 | C-47 友军运输机 | C-47 Skytrain Allied transport plane, olive drab, US markings, level flight |
| 21 | `event_c47_damaged.png` | 128x128 | C-47 损坏状态 | C-47 Skytrain damaged, one engine smoking, wing holes, trailing smoke |
| 22 | `event_supplies_crate.png` | 64x64 | 补给箱 | Military supply airdrop crate, wooden box with parachute straps, stencil markings |

> **注意**: 10 个 `enemy_*_hitbox_ref.png` 文件已跳过。

---

## 4. Boss（BOSS）— 44 文件

### 通用提示词模板（海上战舰）

```
Flat 2D, top-down view of WWII Japanese {SHIP_TYPE},
detailed micro-model style, dark gray metal hull with brown wooden deck planking,
multiple gun turrets with barrels pointing downward (toward viewer),
superstructure with windows and radar, funnels,
3D volumetric shading (top-lit, sides darker, bottom shadows),
hand-painted game sprite, no ocean/sea background baked in,
{PHASE_DESCRIPTION},
clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

### 通用提示词模板（飞行器 BOSS）

```
Flat 2D, top-down view of {AIRCRAFT_TYPE},
detailed micro-model style, metallic skin with panel lines and rivets,
canopy glass reflection, visible engine intakes/exhausts, wing thickness,
3D volumetric shading (top-lit, sides darker, bottom shadows),
{PHASE_DESCRIPTION},
clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

### 通用提示词模板（特殊 BOSS）

```
Flat 2D, top-down view of {SUBJECT},
{PHASE_DESCRIPTION},
clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 512x512 (标准BOSS), 256x256 (爆炸帧), 512x512 (蘑菇云), PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 | 阶段描述 (PHASE_DESCRIPTION) |
|---|--------|------|------|-------------|------------------------------|
| | **Stage 1 BOSS — 九七重爆 (3张)** | | | | |
| 1 | `boss_bomber_phase1.png` | 512x512 | 九七重爆常规编队 | Ki-21 Sally heavy bomber squadron, 3 aircraft in V formation | Intact formation, no damage |
| 2 | `boss_bomber_phase2.png` | 512x512 | 九七重爆散开独立瞄准 | Ki-21 Sally heavy bombers, scattered formation, engines smoking | Scattered formation, wing damage, fire |
| 3 | `boss_bomber_transform.png` | 512x512 | Phase1→2 过渡变形帧 | Ki-21 Sally bomber mid-breakup, wings cracking, fire spreading | Transformation: formation breaking apart, wing fractures, fire |
| | **Stage 2 BOSS — 妙高号重巡 (3张)** | | | | |
| 4 | `boss_cruiser_phase1.png` | 512x512 | 妙高号重巡洋舰完整形态 | Myoko-class heavy cruiser, 4 main gun turrets, torpedo tubes, aircraft catapult | Intact warship, no damage, full armament |
| 5 | `boss_cruiser_phase2.png` | 512x512 | 妙高号重巡受损展开 | Myoko-class heavy cruiser, deck fires, gun turrets destroyed, hull listing | Heavily damaged, deck fires, destroyed turrets |
| 6 | `boss_cruiser_transform.png` | 512x512 | Phase1→2 过渡变形帧 | Myoko-class cruiser mid-destruction, explosions on deck | Transformation: explosions erupting, structure collapsing |
| | **Stage 3 BOSS — 筑波浮桥要塞 (3张)** | | | | |
| 7 | `boss_fortress_phase1.png` | 512x512 | 浮桥要塞甲板俯视 | Floating river fortress platform, gun turrets, radar, anti-aircraft guns | Intact platform, all weapons active |
| 8 | `boss_fortress_phase2.png` | 512x512 | 浮桥要塞展开能量核心 | Floating fortress expanded, red energy core exposed, mechanical arms deployed | Expanded form, red energy core, mechanical arms |
| 9 | `boss_fortress_transform.png` | 512x512 | Phase1→2 过渡变形帧 | Floating fortress transforming, platform splitting, energy core emerging | Transformation: platform splitting, red core emerging |
| | **Stage 7 BOSS — 一式陆攻编队 (3张)** | | | | |
| 10 | `boss_ki21_squadron_phase1.png` | 512x512 | Ki-21 V字编队 | Ki-21 Sally heavy bomber squadron, 3 bombers in tight V formation | Intact V formation, clean aircraft |
| 11 | `boss_ki21_squadron_phase2.png` | 512x512 | 编队散开独立瞄准 | Ki-21 bombers scattered, independent attack runs, some on fire | Scattered, independent movement, fire damage |
| 12 | `boss_ki21_squadron_transform.png` | 512x512 | Phase1→2 机翼断裂起火 | Ki-21 bombers breaking formation, wings snapping off, fire | Formation breaking, wing fractures, trailing fire |
| | **Stage 7 BOSS — 秋津洲号水上机母 (3张)** | | | | |
| 13 | `boss_akitsushima_phase1.png` | 512x512 | 秋津洲号完整形态 | Akitsushima seaplane tender, flight deck, crane, hangar | Intact seaplane tender, aircraft on deck |
| 14 | `boss_akitsushima_phase2.png` | 512x512 | 秋津洲号破损烟柱 | Akitsushima damaged, deck holes, smoke columns, fire | Heavily damaged, hull breaches, smoke columns |
| 15 | `boss_akitsushima_transform.png` | 512x512 | Phase1→2 船体倾斜起火 | Akitsushima listing and catching fire, structure buckling | Ship listing, fire spreading, structural failure |
| | **Stage 7 BOSS — 鬼怒号轻巡 (3张)** | | | | |
| 16 | `boss_kinu_phase1.png` | 512x512 | 鬼怒号轻巡洋舰完整 | Kinu-class light cruiser, 3 gun turrets, torpedo tubes | Intact light cruiser, full armament |
| 17 | `boss_kinu_phase2.png` | 512x512 | 鬼怒号炮塔损坏 | Kinu light cruiser, turrets destroyed, deck fires | Damaged, destroyed gun turrets, deck fire |
| 18 | `boss_kinu_transform.png` | 512x512 | Phase1→2 船尾下沉 | Kinu cruiser stern sinking, bow rising, water flooding | Stern submerging, bow lifting, flooding |
| | **Stage 7 BOSS — 金刚号战列舰 (3张)** | | | | |
| 19 | `boss_kongo_phase1.png` | 512x512 | 金刚号战列舰完整 | Kongo-class battleship, 8 main guns in 4 turrets, massive superstructure | Intact battleship, all guns intact |
| 20 | `boss_kongo_phase2.png` | 512x512 | 金刚号主炮损坏 | Kongo battleship, main turrets destroyed, superstructure fire | Heavily damaged, main guns destroyed |
| 21 | `boss_kongo_transform.png` | 512x512 | Phase1→2 舰桥倒塌大火 | Kongo battleship bridge collapsing, massive fire | Bridge collapsing, inferno, structure failure |
| | **Stage 8 BOSS — 利根号重巡 (2张)** | | | | |
| 22 | `boss_tone_phase1.png` | 512x512 | 利根号重巡洋舰完整 | Tone-class heavy cruiser, rear-mounted seaplane catapult, 4 turrets | Intact cruiser, seaplanes on deck |
| 23 | `boss_tone_phase2.png` | 512x512 | 利根号重巡受损 | Tone cruiser damaged, fires, turret damage | Damaged, deck fires, turret destruction |
| | **Stage 9 BOSS — 吞龙重爆 (3张)** | | | | |
| 24 | `boss_shokaku_phase1.png` | 512x512 | 翔鹤号航空母舰完整 | Shokaku-class aircraft carrier, flight deck, island, aircraft parked | Intact carrier, full flight deck |
| 25 | `boss_shokaku_phase2.png` | 512x512 | 翔鹤号航母受损 | Shokaku carrier, deck fires, flight deck cratered | Heavily damaged, deck fires, craters |
| | **Stage 10 BOSS — 大和号战列舰 (3张)** | | | | |
| 26 | `boss_yamato_phase1.png` | 512x512 | 大和号战列舰完整 | Yamato-class superbattleship, 9 x 46cm guns in 3 turrets, massive | Intact superbattleship, full firepower |
| 27 | `boss_yamato_phase2.png` | 512x512 | 大和号受损 | Yamato battleship, secondary explosion, turret damage | Damaged, fires, secondary explosions |
| 28 | `boss_yamato_phase3.png` | 512x512 | 大和号完全毁灭 | Yamato battleship, massive explosion, breaking in half | Total destruction, magazine explosion, breaking apart |
| | **Stage 11 BOSS — 八幡制铁所 (3张)** | | | | |
| 29 | `boss_yahata_phase1.png` | 512x512 | 八幡制铁所完整 | Yahata Steel Works industrial complex, blast furnaces, factories | Intact industrial complex |
| 30 | `boss_yahata_phase2.png` | 512x512 | 八幡制铁所燃烧 | Yahata Steel Works on fire, furnace explosions | Burning, furnace explosions, structural damage |
| 31 | `boss_yahata_phase3.png` | 512x512 | 八幡制铁所解体 | Yahata Steel Works collapsing, total destruction | Complete structural collapse, debris |
| | **Stage 12 BOSS — 震电改最终 (3张)** | | | | |
| 32 | `boss_shinden_final_phase1.png` | 512x512 | 震电改原型机完整 | J7W Shinden-kai final prototype, canard pusher fighter, enlarged | Intact advanced fighter prototype |
| 33 | `boss_shinden_final_phase2.png` | 512x512 | 震电改高速尾迹 | Shinden-kai afterburner, speed trails, weapon pods deployed | Afterburner active, weapon pods open |
| 34 | `boss_shinden_final_phase3.png` | 512x512 | 震电改过载形态 | Shinden-kai overload, energy wings, structural stress cracks | Overload form, glowing energy wings, stress damage |
| | **H1 BOSS — 冰封Ki-21 (2张)** | | | | |
| 35 | `boss_frozen_bomber_phase1.png` | 512x512 | 冰封Ki-21轰炸机 | Ki-21 bomber encased in thick ice, frozen propellers, frost crystals | Frozen solid, ice armor coating |
| 36 | `boss_frozen_bomber_phase2.png` | 512x512 | 冰封Ki-21冰壳碎裂 | Frozen Ki-21 ice shell cracking, exposing aircraft inside | Ice breaking, frozen fragments flying off |
| | **H2 BOSS — 紫电改中队 (3张)** | | | | |
| 37 | `boss_shiden_squadron_phase1.png` | 512x512 | 紫电改4架菱形编队 | J7W Shinden squadron, 4 aircraft in diamond formation | Intact diamond formation |
| 38 | `boss_shiden_squadron_phase2.png` | 512x512 | 紫电改散开高速尾迹 | Shinden squadron scattered, high-speed trails, afterburners | Scattered, speed trails, afterburners |
| 39 | `boss_shiden_squadron_transform.png` | 512x512 | Phase1→2 一架被击落 | Shinden squadron mid-breakup, one aircraft falling | One aircraft hit, falling with smoke trail |
| | **H4 BOSS — B-29艾诺拉盖伊 (2张)** | | | | |
| 40 | `boss_b29_enola_phase1.png` | 512x512 | B-29艾诺拉盖伊完整 | B-29 Superfortress Enola Gay, silver finish, 4 engines, bomb bay | Intact B-29, bomb bay doors closed |
| 41 | `boss_b29_enola_phase2.png` | 512x512 | B-29投弹后加速逃离 | B-29 Enola Gay bomb bay open, ascending, shockwave behind | Bomb bay open, ascending away, shockwave |
| | **H4 特殊 — 蘑菇云 (1张)** | | | | |
| 42 | `boss_mushroom_cloud.png` | 512x512 | 核爆蘑菇云 | Nuclear mushroom cloud, towering column, fiery core, dark ring, debris | — |
| | **事件 — 断桥 (1张)** | | | | |
| 43 | `boss_bridge_destroyed.png` | 512x512 | 怒江浮桥断裂 | Destroyed pontoon bridge, broken planks floating in river, steel cables snapped | — |
| | **事件 — 目标桥梁 (2张)** | | | | |
| 44 | `event_target_bridge.png` | 512x256 | 怒江浮桥完整 | Intact pontoon bridge, wooden planks, steel cables, river flowing beneath | — |
| 45 | `event_target_bridge_broken.png` | 512x256 | 怒江浮桥断裂 | Broken pontoon bridge, planks scattered in water, cables severed | — |
| | **其他事件素材 (4张)** | | | | |
| 46 | `event_target_car.png` | 128x64 | 黑色军用轿车（带扬尘） | Black military staff car from above, dust trail behind, escaping | — |
| 47 | `event_transport_ship.png` | 128x128 | 运输舰俯视 | Japanese military transport ship from above, gray hull, cargo holds | — |
| 48 | `event_transport_wreck.png` | 128x128 | 运输舰残骸 | Sunken transport ship wreck, partially submerged, rusted hull | — |

---

## 5. Effects（特效）— 11 文件

### 通用提示词模板

```
Flat 2D game effect, {SUBJECT},
hand-painted game sprite style, cartoon energy release with self-illumination,
clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 见下表, PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) |
|---|--------|------|------|----------------------|
| 1 | `fx_explosion_small.png` | 64x64 | 小型爆炸，橙黄→红→暗红渐变 | Small circular explosion, orange-yellow core expanding to red-dark red, 0.3s duration |
| 2 | `fx_explosion_large.png` | 128x128 | 大型BOSS爆炸，多层洋葱式 | Large boss explosion, multi-layer onion ring: white core → orange glow → smoke fragments → fade, 0.8s |
| 3 | `fx_explosion_large_01.png` | 256x256 | 爆炸帧1：初期白色闪光+橙色火环 | Explosion frame 1: initial white flash center, orange fire ring beginning to expand |
| 4 | `fx_explosion_large_02.png` | 256x256 | 爆炸帧2：火球扩大+冲击波环 | Explosion frame 2: fireball expanding, orange-yellow core, shockwave ring, debris fragments |
| 5 | `fx_explosion_large_03.png` | 256x256 | 爆炸帧3：火球巅峰+黑烟环 | Explosion frame 3: fireball peak, large red-orange fireball, dark smoke ring, many debris |
| 6 | `fx_explosion_large_04.png` | 256x256 | 爆炸帧4：火球衰减灰烟 | Explosion frame 4: fireball fading, deep red darkening, gray smoke expanding, debris falling |
| 7 | `fx_explosion_large_05.png` | 256x256 | 爆炸帧5：消散灰烟+余烬 | Explosion frame 5: dissipating, gray smoke fading, red-orange embers fading out |
| 8 | `fx_bomb_flash.png` | 128x128 | 炸弹投下闪光 | Bomb impact flash, bright white-yellow radial burst, screen-filling flash effect |
| 9 | `fx_charge_glow.png` | 96x96 | 蓄力发光效果 | Blue-white energy charge glow, pulsing aura, circular energy accumulation effect |
| 10 | `fx_nuclear_flash.png` | 512x512 | 核爆闪光，白色→橙→红 | Nuclear explosion flash, intense white center expanding to orange then red, massive radial burst |
| 11 | `hump_cloud_fake.png` | 256x256 | 驼峰云雾遮挡（半透明） | Semi-transparent white-gray mountain cloud layer, soft edges, for visual deception |
| 12 | `hump_rock_debris.png` | 64x64 | 冰岩碎片 sprite | Small ice rock debris, angular dark gray ice fragments, for falling obstacle |

---

## 6. Bullets（弹幕）— 4 文件

### 通用提示词模板

```
Flat 2D game bullet sprite, {SUBJECT},
clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 见下表, PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) |
|---|--------|------|------|----------------------|
| 1 | `bullet_player_yellow.png` | 8x24 | 玩家子弹，细长条蓝白发亮 | Player bullet, long thin streak, blue-white glow, bright core |
| 2 | `bullet_enemy_red.png` | 8x24 | 敌方普通子弹，橙红圆形+短尾焰 | Enemy bullet, small orange-red circle with short orange flame tail |
| 3 | `bullet_missile.png` | 16x32 | 玩家导弹，银灰弹体+橙红尾焰 | Player missile, pointed silver-gray body with bright orange-red exhaust flame trail |
| 4 | `missile_enemy.png` | 64x128 | 敌方导弹，银灰弹体+橙红尾焰 | Enemy missile, large silver-gray body with long orange-red exhaust flame, top-down view |

---

## 7. Powerups（道具）— 3 文件

### 通用提示词模板

```
Flat 2D game pickup item, {SUBJECT},
slight golden glow effect, clean transparent background, game sprite,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 48x48, PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) |
|---|--------|------|------|----------------------|
| 1 | `powerup_p.png` | 48x48 | 火力提升道具，红色P字+金属胶囊 | Red metallic capsule with bold white P letter, fire icon, subtle golden glow |
| 2 | `powerup_b.png` | 48x48 | 炸弹补充道具，蓝色B字+炸弹图标 | Blue metallic capsule with bold white B letter, bomb icon, subtle golden glow |
| 3 | `powerup_coin.png` | 48x48 | 金币加分道具 | Golden coin with embossed dollar/yen symbol, metallic shine, subtle glow |

---

## 8. UI（用户界面）— 34 文件

### 通用提示词模板

```
flat 2D game UI element, {SUBJECT},
clean transparent background, game UI asset,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 见下表, PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) |
|---|--------|------|------|----------------------|
| | **HUD 元素 (7张)** | | | |
| 1 | `ui_hud_life_icon.png` | 32x32 | 生命值图标（小飞机） | Small fighter plane silhouette icon, olive drab, for HUD life counter |
| 2 | `ui_hud_bomb_icon.png` | 32x32 | 炸弹数量图标 | Bomb icon for HUD, dark gray bomb shape with lit fuse |
| 3 | `ui_hud_score_display.png` | 256x64 | 分数显示区域 | Score display panel background, dark semi-transparent bar with gold border, military stencil style |
| 4 | `ui_hud_charge_bar.png` | 256x32 | 蓄力条 | Charge energy bar frame, dark metal frame, empty interior for fill |
| 5 | `ui_hud_power_level.png` | 64x64 | 火力等级显示 | Power level indicator, 3 to 5 dots or bars showing weapon upgrade level |
| 6 | `ui_hud_boss_hp_bar.png` | 512x32 | BOSS血条 | Boss health bar frame, wide horizontal bar with riveted metal frame, red fill zone |
| 7 | `ui_hint_bar_bg.png` | 400x40 | 提示条背景 | Hint bar background, dark semi-transparent strip, military style border |
| 8 | `ui_hint_bar_locked.png` | 400x40 | 提示条锁定（未解锁） | Locked hint bar, dark gray with lock icon overlay, dimmed appearance |
| | **按钮 (3张)** | | | |
| 9 | `ui_button_normal.png` | 192x48 | 按钮默认状态 | Military style button, olive green background, light border, centered text area |
| 10 | `ui_button_hover.png` | 192x48 | 按钮悬停状态 | Military style button hover, lighter olive green, bright border glow |
| 11 | `ui_button_pressed.png` | 192x48 | 按钮按下状态 | Military style button pressed, darker olive, inset shadow, compact |
| | **评级徽章 (4张)** | | | |
| 12 | `ui_medal_s.png` | 64x64 | S级评价徽章（金翼+星） | S-rank medal, gold wings with star, shiny gold metal, highest rank |
| 13 | `ui_medal_a.png` | 64x64 | A级评价徽章（银翼） | A-rank medal, silver wings, polished silver metal |
| 14 | `ui_medal_b.png` | 64x64 | B级评价徽章（铜翼） | B-rank medal, bronze wings, brushed bronze metal |
| 15 | `ui_medal_c.png` | 64x64 | C级评价徽章（铁质） | C-rank medal, iron cross, dark gray metal, basic rank |
| | **军衔系统 (7张)** | | | |
| 16 | `ui_rank_corporal.png` | 48x48 | 下士：三道铜V字 | Corporal rank insignia, three copper chevrons (V shapes), on dark background |
| 17 | `ui_rank_sergeant.png` | 48x48 | 中士：三V+摇杆 | Sergeant rank insignia, three chevrons with rocker bar below, on dark background |
| 18 | `ui_rank_captain.png` | 48x48 | 上尉：银鹰徽 | Captain rank insignia, silver eagle emblem, on dark background |
| 19 | `ui_rank_major.png` | 48x48 | 少校：金橡叶 | Major rank insignia, gold oak leaf, on dark background |
| 20 | `ui_rank_colonel.png` | 48x48 | 上校：银鹰+星 | Colonel rank insignia, silver eagle with star, on dark background |
| 21 | `ui_rank_ace.png` | 64x64 | 王牌：金翼+桂冠 | Ace rank badge, golden wings with laurel wreath, premium gold finish |
| 22 | `ui_rank_progress_bar_bg.png` | 200x16 | 经验条底框 | Rank progress bar background frame, dark metal border, empty interior |
| 23 | `ui_rank_progress_bar_fill.png` | 200x16 | 经验条填充 | Rank progress bar fill, golden-yellow gradient fill bar |
| | **玩家选择卡片 (4张)** | | | |
| 24 | `ui_player_card_p40.png` | 256x256 | P-40 战鹰选择卡片 | Player select card for P-40 Warhawk, top-down aircraft silhouette, name, FIRE/SPD/ARM stats bars, dark green background, aged yellow border, military stencil font |
| 25 | `ui_player_card_p51.png` | 256x256 | P-51 野马选择卡片 | Player select card for P-51 Mustang, top-down aircraft silhouette, name, stats bars, dark green background, aged yellow border, military stencil font |
| 26 | `ui_player_card_p38.png` | 256x256 | P-38 闪电选择卡片 | Player select card for P-38 Lightning, top-down aircraft silhouette, name, stats bars, dark green background, aged yellow border, military stencil font |
| 27 | `ui_player_card_b25.png` | 256x256 | B-25 米切尔选择卡片 | Player select card for B-25 Mitchell, top-down aircraft silhouette, name, stats bars, dark green background, aged yellow border, military stencil font |
| | **大场景 (2张)** | | | |
| 28 | `ui_main_menu_bg.png` | 1920x1080 | 主菜单背景 | Main menu background, WWII Pacific theater themed, military maps, aircraft silhouettes, vintage parchment style, dramatic lighting |
| 29 | `ui_stage_select_map.png` | 1920x1080 | 关卡选择地图 | Stage select map, hand-drawn WWII China-Burma-India theater map, route lines from Kunming to Tokyo, city markers, military cartography style |
| | **其他 UI (4张)** | | | |
| 30 | `ui_checkpoint_flag.png` | 64x64 | 深渊模式检查点标记 | Checkpoint flag marker, small military flag on pole, bright color for visibility |
| 31 | `ui_countdown_ring.png` | 256x256 | 广岛倒计时环形进度条 | Countdown ring timer, circular progress ring, red fill depleting, military instrument style |
| 32 | `ui_target_marker.png` | 64x64 | 东京轰炸目标高亮标记 | Bombing target marker, crosshair reticle with red highlight, military targeting icon |

---

## 9. 情报图标（Intel Icons）— 2 文件

### 通用提示词模板

```
flat 2D game UI icon, {SUBJECT},
clean transparent background, game UI asset,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945)
```

**技术参数**: 48x48, PNG with transparent background

| # | 文件名 | 尺寸 | 描述 | SD 主体描述 (SUBJECT) |
|---|--------|------|------|----------------------|
| 1 | `intel_hump_route.png` | 48x48 | 驼峰航线情报图标 | Hump route intel icon, mountain silhouette with dotted flight path, map pin style |
| 2 | `intel_tokyo_defense.png` | 48x48 | 东京防御情报图标 | Tokyo defense intel icon, city skyline silhouette with radar sweep, shield icon |

---

## 附录 A: SD 生成注意事项

### A.1 负面提示词 (Negative Prompt) — 全局通用

```
photo, realistic photo, 3D render, perspective view, side view, horizon, sky, clouds,
watermark, signature, text, logo, label, jpeg artifacts, blur, low quality,
multiple views, collage, border, frame
```

### A.2 背景类额外负面提示词

```
sky, horizon line, clouds, vanishing point, perspective, angled view, oblique,
aerial photo, satellite photo, realistic photography
```

### A.3 BOSS/敌机/玩家类额外负面提示词

```
ocean, sea, water, ground, terrain, background scene, environment,
watermark, signature, photo, 3D render, realistic
```

### A.4 推荐生成参数

| 参数 | 推荐值 |
|------|--------|
| 采样方法 | DPM++ 2M Karras |
| 采样步数 | 30-40 |
| CFG Scale | 7-9 |
| 降噪强度 (img2img) | 0.5-0.7 |
| 背景尺寸 | 512x2048 (SDXL) 或分段 512x512 拼接 |
| Sprite 尺寸 | 按上表目标尺寸直接生成，或 512x512 生成后缩放 |
| 后处理 | PNG-32 RGBA 透明背景，白色/近白(R>230)转Alpha=0 |

### A.5 大尺寸背景生成策略

对于 512x2048 的背景图层：
- **方案A (SDXL)**: 直接生成 512x2048（需要 SDXL 模型支持长宽比）
- **方案B (分段生成)**: 生成 4 段 512x512，使用 crossfade 64px 线性混合拼接为 512x2048
- **方案C (高分辨率修复)**: 先生成 512x512 低分辨率，再 Hires.fix 2x 放大到 512x1024，再拼接

对于 512x6144 的 `bg_hump_extreme_full.png`：
- **必须分段生成**: 3 段 512x2048，crossfade 64px 拼接
- 段1: 平坦冰雪地面
- 段2: 冰川地形
- 段3: 高山高原 (Boss区)

---

## 附录 B: 尺寸速查表（从 DesignLog 推断）

| 类别 | 子类 | 标准尺寸 |
|------|------|---------|
| 背景 | 标准关卡 4层 | 512x2048 |
| 背景 | 昆明 5层 | 512x2048 |
| 背景 | H1 驼峰极端 (分段) | 512x2048 x3 → 512x6144 |
| 背景 | H3 紫电竞技场 (2层) | 512x2048 |
| 玩家 | P-40/P-51 | 128x128 (body/bank/hit), 512x128 (propeller strip) |
| 玩家 | P-38 | 144x128 (body/bank/hit), 576x128 (propeller strip) |
| 玩家 | B-25 | 160x144 (body/bank/hit), 640x144 (propeller strip) |
| 敌机 | 标准战斗机 | 96x96 |
| 敌机 | 大型机/特殊 | 80x64 ~ 160x120 |
| 敌机 | 侧面视图 | 128x64 |
| 敌机 | 坦克/登陆艇/气球 | 128x128 |
| 敌机 | 补给箱 | 64x64 |
| BOSS | 标准阶段 | 512x512 |
| BOSS | 爆炸帧序列 | 256x256 |
| BOSS | 蘑菇云/核爆 | 512x512 |
| BOSS | 事件桥梁 | 512x256 |
| BOSS | 事件轿车 | 128x64 |
| 特效 | 小型爆炸 | 64x64 |
| 特效 | 大型爆炸 | 128x128 |
| 特效 | 爆炸帧序列 | 256x256 |
| 特效 | 炸弹闪光 | 128x128 |
| 特效 | 蓄力发光 | 96x96 |
| 特效 | 核爆闪光 | 512x512 |
| 特效 | 云雾 | 256x256 |
| 特效 | 碎片 | 64x64 |
| 子弹 | 普通弹 | 8x24 |
| 子弹 | 导弹 | 16x32 ~ 64x128 |
| 道具 | 标准道具 | 48x48 (原 32x32 升级) |
| UI | 按钮 | 192x48 |
| UI | 徽章 | 64x64 |
| UI | 军衔 | 48x48 (Ace 64x64) |
| UI | 进度条 | 200x16 |
| UI | 玩家卡片 | 256x256 |
| UI | 大场景 | 1920x1080 |
| UI | 提示条 | 400x40 |
| UI | 倒计时环 | 256x256 |
| UI | 其他 | 32x32 ~ 64x64 |
| 情报 | 图标 | 48x48 |