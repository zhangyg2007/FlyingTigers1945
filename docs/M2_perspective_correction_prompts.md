# M2 视角修正 — AI 图像生成提示词指南

> 本文档为 Design Agent 提供修正后的AI生成提示词，确保生成纯俯角视图（Top-Down）的关卡背景和BOSS。

---

## 通用前置提示（所有图共用）

**正向**: `top-down view, aerial view, looking straight down at ground, vertical scrolling shooter game background, 512x2048 vertical strip, satellite view style, iFighter 1945 style, realistic military texture, high detail, low saturation, WWII era`

**负向**: `sky, clouds, horizon, side view, perspective view, landscape, mountains on horizon, sunset, sunrise, people, cartoon, anime style, 3D render, photorealistic, watermarks, signature`

---

## 各关卡背景修正提示词

### Stage 01 昆明 → 高原机场

**色调**: 黄绿暖色、清晨阳光

**Layer 1 (far) — `bg_kunming_far.png`** (完全重绘)
```
top-down aerial view of Kunming plateau, Yunnan landscape from above, distant Western Hills mountain range as top-down silhouette, Dianchi lake as blue water surface from above, scattered rural villages with grey tile roofs, green farmland patches, morning golden hour light, almost no sky visible, 90% ground view, 512x2048 vertical strip, top-down perspective, no horizon, no sky
```

**Layer 2 (mid) — `bg_kunming_mid.png`** (微调，减少天空)
```
top-down view of Kunming airport area, Wujiaba airfield runway as long rectangle from above, 1940s Chinese rural architecture roofs, village houses with grey tiles, dirt roads, scattered trees viewed from above (round canopy tops), green fields, yellow-brown earth, vertical strip 512x2048, minimal sky band at top less than 10%
```

**Layer 3 (near) — `bg_kunming_near.png`** (保持基本正确)
```
top-down close view of Wujiaba airport runway, concrete runway surface with center line markings from above, grass beside runway, parked P-40 Warhawk seen from above (top view of wings and cockpit), hangar roofs, dirt access roads, 512x2048 vertical strip
```

**Layer 4 (ground) — `bg_kunming_ground.png`** (无需修改)

---

### Stage 02 仰光 → 港口空袭

**色调**: 橙红暖色、黄昏

**Layer 1 (far) — `bg_rangoon_far.png`** (完全重绘)
```
top-down aerial view of Yangon port and Irrawaddy river delta, wide river surface from above with water texture, Rangoon harbor with dock facilities from above, Shwedagon pagoda seen as circular top-down structure among green trees, rectangular port warehouses roofs, tropical vegetation canopy from above, distant ocean visible, warm golden sunset light, 512x2048, top-down, no sky visible
```

**Layer 2 (mid) — `bg_rangoon_mid.png`**
```
top-down view of Yangon port area, dock piers extending into water, cargo ship decks seen from above, rows of warehouses with red tile roofs from above, palm tree canopies as circular green shapes, network of roads between buildings, railway tracks, 512x2048, twilight warm colors
```

**Layer 3 (near) — `bg_rangoon_near.png`**
```
close top-down view of Yangon dock, wooden pier structure, docked cargo ship deck with cargo hatches, crane equipment seen from above (top of jib arm), warehouse roof detail, cobblestone street, 512x2048
```

**Layer 4 (ground) — `bg_rangoon_ground.png`**
```
top-down ground texture of Yangon port, water surface lapping at dock edge, reflections on wet stones, cracks in concrete, patches of moss, 512x2048, close ground level
```

---

### Stage 03 怒江 → 峡谷护航

**色调**: 深绿暗沉、阴郁峡谷

**Layer 1 (far) — `bg_salween_far.png`** (完全重绘)
```
top-down aerial view of Salween River gorge, dark green river water winding through deep valley from above, steep canyon walls seen as top-edge contours, dense forest canopy covering both sides of valley, mountain ridges extending away, overcast gloomy lighting, mist in low areas, 512x2048, vertical strip, no sky visible, brooding atmosphere
```

**Layer 2 (mid) — `bg_salween_mid.png`**
```
top-down view of Salween river bend, brown river water surface, narrow mountain road winding alongside river, small suspension bridge crossing river seen from above, military convoy trucks on road (top view of truck roofs), dense jungle canopy, steep hillside, 512x2048
```

**Layer 3 (near) — `bg_salween_near.png`**
```
close top-down view of Salween gorge, river surface with ripples, rocky riverbank, WWII military truck roofs seen from above, soldiers in helmets from above, jungle vegetation canopy, mountain road surface, 512x2048
```

**Layer 4 (ground) — `bg_salween_ground.png`**
```
top-down ground texture of jungle floor, dirt path, rocks, fallen leaves, roots, moss, 512x2048
```

---

### Stage 04 驼峰 → 雪山航线

**色调**: 冷蓝白、严寒

**Layer 1 (far) — `bg_hump_far.png`** (完全重绘)
```
top-down aerial view of Himalayan mountains, snow-capped mountain peaks from above, glacier surfaces with crevasses, mountain ridges as contour lines, clouds below viewpoint, deep valleys, frozen lakes, thin layer of clouds partially obscuring ground, 512x2048, top-down, minimal sky at top, cold blue-white lighting
```

**Layer 2 (mid) — `bg_hump_mid.png`**
```
top-down view of Himalayan valley, snow-covered ground, rocks visible through snow, crashed C-47 transport plane from above (top view of fuselage), scattered wreckage, thin cloud wisps, mountain shadows, no sky visible, 512x2048
```

**Layer 3 (near) — `bg_hump_near.png`**
```
close top-down view of snow-covered mountain terrain, snow texture, exposed rock, ice patches, alpine vegetation, 512x2048
```

**Layer 4 (ground) — `bg_hump_ground.png`**
```
top-down ground texture of snow and ice, cracks in ice, scattered rocks, snowdrift patterns, 512x2048
```

---

### Stage 05 桂林 → 喀斯特空战

**色调**: 金黄黄昏

**Layer 1 (far) — `bg_guilin_far.png`** (完全重绘)
```
top-down aerial view of Guilin karst landscape, Li River winding through limestone peaks, conical karst hills seen from above as circular green tops, rice paddies as geometric patterns, small villages with dark roofs, warm golden hour light, 512x2048, almost no sky, just ground and water
```

**Layer 2 (mid) — `bg_guilin_mid.png`** (微调减少天空)
```
top-down view of Li River valley, meandering river with sandy banks, karst peaks rising from flat ground, farm fields, irrigation canals, Yangshuo countryside, scattered villages, 512x2048, warm golden light
```

**Layer 3 (near) — `bg_guilin_near.png`**
```
close top-down view of Yangtang airfield, runway surface from above, P-40 fighters parked on grass, air raid shelter roofs, hangar buildings, dirt roads, 512x2048
```

**Layer 4 (ground) — `bg_guilin_ground.png`**
```
top-down ground texture of Li River surface, water reflections, ripples, sandy riverbank, 512x2048
```

---

### Stage 06 衡阳 → 城市夜战

**色调**: 暗红火焰、城市废墟夜战

**Layer 1 (far) — `bg_hengyang_far.png`** (完全重绘)
```
top-down aerial view of Hengyang city at night, burning city blocks seen from above, rectangular building roofs with fire and smoke rising from them, grid pattern of city streets, Xiang River cutting through city, fires reflected in water, searchlight beams from ground, dark smoky atmosphere, 512x2048, top-down view, minimal sky visible, red and orange glow
```

**Layer 2 (mid) — `bg_hengyang_mid.png`**
```
top-down view of Hengyang city center, burning buildings seen from above (roofs with flames), destroyed building ruins, rubble, city street grid, military vehicles on streets, collapsed buildings, heavy smoke, red glow, 512x2048
```

**Layer 3 (near) — `bg_hengyang_near.png`**
```
close top-down view of burning city street, rubble and debris, destroyed military vehicles, fires, collapsed buildings, broken road surface, 512x2048
```

**Layer 4 (ground) — `bg_hengyang_ground.png`**
```
top-down ground texture of city rubble, broken concrete, debris, scattered papers, shell casings, 512x2048
```

---

## BOSS 修正提示词

### Stage 2 BOSS：妙高号重巡 → `boss_nachi_phase1.png` (完全重绘)

**正向**:
```
top-down view of Japanese heavy cruiser Myoko, seen from directly above, battleship deck layout clearly visible, three triple turrets from above (circular turret tops), pagoda-style bridge tower from above, two funnels, secondary guns, aircraft catapult, ship oriented vertical (bow up, stern down), military navy grey, greenish-grey hull top, 512x512, transparent background, detailed deck equipment, WWII Japanese warship, pure top-down, no hull sides visible, iFighter 1945 style game sprite
```

**负向**:
`side view, hull side, isometric, 3/4 perspective, hull body visible below deck, water, waves, people, cartoon, anime, signature`

### Stage 2 BOSS：妙高号重巡 Phase 2 → `boss_nachi_phase2.png` (完全重绘)

**正向**:
```
top-down view of Japanese heavy cruiser Myoko transformed for battle, deck armor plates opened, hidden weapon systems revealed from above, enlarged turrets, additional missile launchers, glowing energy core amidships, mechanical arms extending from deck, dark red and grey color scheme, 512x512, transparent background, pure top-down, no hull sides visible, iFighter 1945 style
```

**负向**: 同上

### Stage 3 BOSS：筑波浮桥要塞 → `boss_fortress_phase1.png` (完全重绘)

**正向**:
```
top-down view of river pontoon fortress, circular floating platform on river surface, heavy anti-aircraft gun turrets on platform from above, radar dishes from above, ammunition boxes, control tower from above, surrounded by river water, military green and grey, 512x512, transparent background, pure top-down, no side walls visible, iFighter 1945 style
```

**负向**: 同上

### Stage 3 BOSS：筑波浮桥要塞 Phase 2 → `boss_fortress_phase2.png` (完全重绘)

**正向**:
```
top-down view of river fortress in battle mode, central platform split open, giant anti-aircraft cannon rising from center, seen from above, multiple turrets on extended arms, additional weapon platforms, glowing red energy, destroyed bridge sections around, 512x512, transparent background, pure top-down, no side walls visible, iFighter 1945 style
```

**负向**: 同上

---

## 生成后处理流程

1. 每个文件生成后检查透视角度是否正确
2. 使用Python/Pillow批量处理：
   - 确保PNG-32 RGBA格式
   - 背景图片缩放至精确 512×2048
   - BOSS图片缩放至精确 512×512
   - 白色/近白色背景转透明（仅限BOSS）
3. 验证全部文件格式正确
4. 覆盖原文件（保持文件名完全一致）
5. 更新DesignLog.md

---

**文档结束**