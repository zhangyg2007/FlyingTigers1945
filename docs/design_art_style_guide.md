# Flying Tigers 1945 — Design 美术风格规范（基于参考图提炼）

> **版本**: v1.0  
> **日期**: 2026-07-11  
> **接收人**: Design Agent  
> **状态**: 立即生效，后续所有素材生成必须遵循本文档  
> **参考来源**: 用户提供的 3 张参考截图（山地关卡 / 海上战舰 / 海空大战）

---

## 1. 核心风格定位

**一句话定义**: 二战军事写实卡通化（Military Cartoon Realism）— 移动端复古街机 STG 美学，手绘纹理 + 立体光影体积感，非纯像素也非纯矢量。

**风格谱系**:
```
彩京 Strikers 1945 (1990s) → iFighter 1945 (移动端) → 本项目目标风格
```

**关键区分**: 之前 M2 阶段使用的 orthophoto/卫星图风格（纯写实俯拍）**需要调整**为本规范定义的"手绘纹理 + 体积感"风格。背景不是照片级的卫星图，而是**带手绘笔触质感的游戏地图**。

---

## 2. 背景地图规范

### 2.1 视角与透视

| 规则 | 说明 |
|------|------|
| **视角** | 纯 90° 垂直俯视（Top-down），零透视变形 |
| **比例** | 游戏性优先于真实比例。飞机约为建筑的 1/3~1/2 大小，坦克极小（飞机的 1/4） |
| **纵深感** | 无透视缩放，所有物体等大。通过色彩明暗暗示高低差，不通过尺寸缩放 |

### 2.2 地面/海洋处理

**陆地关卡（山地/城市/机场）**:
- **地面底色**: 低饱和度土黄/棕褐/灰绿色系，带**手绘笔触纹理**（非纯色填充）
- **地形起伏**: 通过色彩深浅变化（深褐/浅黄交替）暗示高低，边缘用深色描边 + 植被覆盖
- **禁止**: 纯色平铺、照片级卫星图纹理、天空/地平线/侧视角元素

**海洋关卡（战舰/港口）**:
- **海水底色**: 低明度蓝绿（#0a3a5a ~ #1e5a7a），带**波纹质感**（非纯色）
- **海面细节**: 细微的波光纹理，可带半透明的浅色水纹叠加
- **禁止**: 纯蓝平铺、高饱和度亮蓝

### 2.3 地面元素绘制规则

**植被（树木/灌木）**:
- 风格化团块造型，深绿色不规则圆形/椭圆形簇状
- 边缘有深色描边，无单棵树叶细节
- 色彩：墨绿、深绿、少量黄绿变化

**建筑（军事设施/民居）**:
- 木质建筑：棕色屋顶带木板纹理，墙体有风化做旧效果
- 军事工事：灰色混凝土质感，带射击孔、加固棱角，几何造型硬朗
- **关键**: 所有建筑有**立体光影**（顶亮底暗），2D 素材呈现 3D 体积感

**载具（坦克/车辆）**:
- 极小型设计，顶部视角可见炮塔和履带轮廓
- 迷彩涂装，带阴影投射
- 体积约为玩家飞机的 1/4

### 2.4 背景图层比例规范

每关 4 层背景，512x2048 像素：

| 图层 | 速度系数 | 内容 | 滚动速度 |
|------|---------|------|---------|
| far（远景） | 0.2x | 天际线/远景轮廓/大面积色块 | 最慢 |
| mid（中景） | 0.5x | 主要地形/建筑群/道路/河流 | 中等 |
| near（近景） | 0.8x | 近处植被/小建筑/细节元素 | 较快 |
| ground（地面） | 1.0x | 地面纹理/碎石/水纹/轮胎痕 | 最快（与玩家同步） |

**注意**: far 层不是"全览地图"，而是远景天际线轮廓（如远山、海岸线），内容量应最少，色彩最淡。

---

## 3. BOSS（战舰/飞行器）规范

### 3.1 整体设计原则

| 规则 | 说明 |
|------|------|
| **体积感** | 微缩模型感 — 如同精致的塑料模型，细节丰富但比例适度夸张 |
| **炮台 oversized** | 炮台比真实比例更大，增强可读性（参考图 2 中战舰炮台非常醒目） |
| **立体光影** | 顶亮底暗，侧面有阴影，2D 素材呈现 3D 体积感 |
| **甲板纹理** | 舰船类 BOSS 必须有甲板木质/金属纹理，不能是纯色填充 |

### 3.2 海上战舰 BOSS 绘制规范（参考图 2）

| 元素 | 绘制要求 |
|------|---------|
| 舰体 | 深灰金属质感 + 棕黄木质甲板，带铆钉/焊缝细节 |
| 舰桥 | 多层结构，有窗户/雷达/烟囱，顶亮侧暗 |
| 炮塔 | 圆形底座 + 炮管，炮管方向向下（朝玩家），有旋转关节暗示 |
| 烟囱 | 灰色圆柱，顶部可有微弱烟雾暗示 |
| 伤害状态(phase2) | 甲板破洞、火焰特效、烟柱、侧舷火光 |
| **禁止** | 纯色扁平填充、无甲板纹理、无立体光影、海水烘焙到 Sprite |

### 3.3 飞行器 BOSS 绘制规范

| 元素 | 绘制要求 |
|------|---------|
| 机身 | 金属质感蒙皮，带面板线/铆钉/涂装标记 |
| 驾驶舱 | 玻璃罩反光效果（浅蓝色高光） |
| 发动机 | 明显的进气口/排气口，phase2 可有起火效果 |
| 机翼 | 有厚度感（非纸片薄），翼尖可有导航灯 |

---

## 4. 敌机绘制规范（含侧飞姿态）

### 4.1 标准姿态（向下飞行）

- 机身轴线垂直，机翼水平展开
- 顶部俯视可见机身、机翼、尾翼完整轮廓
- 现有 10 种敌机 Sprite 已符合此规范

### 4.2 侧飞姿态（横向进入/抛物线轨迹）— **新增需求**

根据参考图 3 分析，敌机横向进入屏幕时需要**明显的机身倾斜**：

| 进入方向 | 倾斜角度 | 姿态描述 | 需要的素材 |
|---------|---------|---------|-----------|
| 从左上→右下 | 向右倾斜 ~30° | 抛物线轨迹，轻微右倾 | `enemy_[type]_bank_right.png` |
| 从右上→左下 | 向左倾斜 ~30° | 抛物线轨迹，轻微左倾 | `enemy_[type]_bank_left.png` |
| 从左侧水平→右 | 向右倾斜 ~15° | 直线横穿，轻微右倾 | `enemy_[type]_bank_right.png`（可复用） |
| 从右侧水平→左 | 向左倾斜 ~15° | 直线横穿，轻微左倾 | `enemy_[type]_bank_left.png`（可复用） |

**倾斜量**: 参考图 3 中敌机侧飞时倾斜约 30°~45°。本项目建议标准化为：
- **浅倾斜（bank）**: 15°~20° — 用于水平横穿
- **深倾斜（dive）**: 30°~35° — 用于斜向抛物线进入

### 4.3 侧飞素材优先级

并非所有敌机都需要侧飞素材。优先为以下类型制作：

| 优先级 | 敌机类型 | 原因 |
|--------|---------|------|
| P0 | `ki43_hayabusa`（隼） | 最常见横穿敌机 |
| P0 | `a6m_zero`（零战） | 高速横穿敌机 |
| P1 | `ki84_hayate`（疾风） | 后期关卡横穿 |
| P1 | `d3a_val`（九九舰爆） | 俯冲轰炸轨迹 |
| P2 | 其余 6 种 | 按需补充 |

### 4.4 侧飞素材命名

```
enemy_[model]_bank_right.png   # 向右倾斜 15~20°
enemy_[model]_bank_left.png    # 向左倾斜 15~20°
```

尺寸与正面 Sprite 一致（128x128），PNG-32 RGBA，透明背景。

---

## 5. 弹幕与特效风格

### 5.1 子弹视觉风格（参考三张图统一）

| 类型 | 造型 | 色彩 | 尺寸参考 |
|------|------|------|---------|
| 普通敌弹 | 圆形/椭圆形，带短尾焰 | 橙红色/金黄色 | 直径 6~8px |
| 玩家弹 | 细长条状，带发光 | 黄白色/蓝白色 | 长 12~16px |
| 导弹 | 尖头锥体 + 长尾焰 | 银灰弹体 + 橙红尾焰 | 16~24px |
| 大型弹（BOSS） | 更大圆形 + 明显拖尾 | 粉红/紫色光弹 | 直径 10~14px |

### 5.2 爆炸特效风格

- **小型爆炸**: 圆形扩散，橙黄→红→暗红渐变，0.3 秒
- **大型爆炸（BOSS）**: "洋葱式"多层扩散 — 火光核心 → 橙黄光晕 → 烟雾碎片 → 消散，0.8 秒
- **风格**: 非写实物理爆炸，而是**卡通化能量释放**，带自发光效果

### 5.3 浪花/尾迹（海上关卡）

- 战舰/敌机在海上移动时，尾部有白色泡沫尾迹
- 半透明椭圆纹理序列，近大远小
- 在 Sprite 中不需要绘制（由 Code 用粒子系统实现），但 BOSS Sprite 的尾部应预留尾迹锚点

---

## 6. 色调系统

### 6.1 全局色调谱

```
环境底色（低饱和度，不抢焦点）：
├── 陆地：土黄 #8B7355 → 棕褐 #654321 → 灰绿 #556B2F
├── 海洋：深蓝绿 #0a3a5a → 蓝绿 #1e5a7a
└── 夜间：深蓝 #0d1b2a → 暗红 #3d0c0c（Stage 12 专用）

敌方识别色（高对比度，跳出背景）：
├── 机身：草绿 #4a7c3f → 橄榄绿 #6b8e5a
├── 机徽：警示红 #DC143C（日之丸）
└── 弹幕：火焰橙 #FF4500 → 金黄 #FFD700

友方识别色：
├── 机身：军绿 #556B2F → 银灰 #A0A0A0（P-40 沙漠涂装）
└── 弹幕：蓝白 #87CEEB → #FFFFFF

UI/特效高亮：
├── 爆炸核心：白 #FFFFFF → 淡黄 #FFFACD
├── 爆炸外围：橙 #FF8C00 → 红 #FF0000
└── 道具发光：金 #FFD700
```

### 6.2 色调策略原则

- **冷底色 + 暖高光**: 背景低饱和冷色调，弹幕/爆炸高饱和暖色调
- **军事大地色系**作为基底，关键游戏元素使用高饱和对比色跳出
- 所有颜色**避免纯黑 #000000 和纯白 #FFFFFF**（背景/底色），但爆炸核心和 UI 文字可用纯白

---

## 7. AI 生图提示词模板

以下为 Design Agent 使用 AI 图像生成时的通用提示词模板，已融入本规范的风格要求：

### 7.1 陆地关卡背景

```
Top-down orthographic view of [地形描述], WWII era military base,
hand-painted game texture style with visible brush strokes and material textures,
low saturation earth tones (olive/brown/tan), no sky, no horizon line,
90 degree vertical overhead camera, no perspective distortion,
game art style like classic arcade vertical scrolling shooter (Strikers 1945 / iFighter 1945),
small military buildings with shadow casting (top-lit, bottom-dark),
clustered dark green bush/tree canopies, dirt roads, 
muted color palette serving as gameplay background, seamless vertical scrolling tile,
transparent background, PNG format
```

### 7.2 海上关卡背景

```
Top-down orthographic view of open ocean, deep blue-green water (#0a3a5a),
subtle wave ripple texture, hand-painted game art style,
low saturation cool tones, no sky, no horizon line,
90 degree vertical overhead camera, game art style like classic arcade STG,
small white foam/wake trails suggesting ship movement,
muted color palette for gameplay background, seamless vertical scrolling tile,
transparent background, PNG format
```

### 7.3 海上战舰 BOSS

```
Top-down orthographic view of WWII Japanese [战舰类型], detailed micro-model style,
dark gray metal hull with brown wooden deck planking and rivet details,
multiple gun turrets with barrels pointing downward (toward viewer),
superstructure with windows and radar, funnels with subtle smoke,
3D volumetric shading (top-lit, sides darker, bottom shadows),
hand-painted game sprite style, no ocean/sea background baked in (pure transparent),
512x512 pixel, PNG with transparent background,
game art style like Strikers 1945 / iFighter 1945
```

### 7.4 敌机（含侧飞）

```
Top-down orthographic view of WWII Japanese [机型名称] fighter aircraft,
green/olive camo with red hinomaru roundel markings,
[bank_right: "banking right 20 degrees" / bank_left: "banking left 20 degrees" / normal: "level flight, wings horizontal"],
hand-painted game sprite with 3D volumetric shading,
metallic skin with panel lines and canopy glass reflection,
game art style like classic arcade vertical scrolling shooter,
128x128 pixel, PNG with transparent background
```

---

## 8. 与之前 M2 风格的差异对比

| 维度 | M2 阶段（旧） | 本规范（新） |
|------|-------------|------------|
| 背景风格 | orthophoto/卫星图，照片级写实 | 手绘纹理 + 体积感，游戏地图风格 |
| 色调 | 偏高饱和度写实色彩 | 低饱和度大地色系底色 + 高饱和弹幕 |
| 建筑表现 | 纯俯视色块 | 有立体光影（顶亮底暗） |
| BOSS | 扁平 2D，无纹理 | 微缩模型感，甲板/蒙皮纹理，炮台 oversized |
| 敌机 | 仅正面俯视 | 新增侧飞倾斜素材 |
| 整体质感 | 接近地图截图 | 接近精致的游戏 Sprite |

---

## 9. 生效范围

本文档自发布之日起，**覆盖所有后续素材生成**，包括但不限于：
- M3-B 的 Stage 04~08 背景 + BOSS 04~08
- M3-C 的 Stage 09~12 背景 + 隐藏关背景 + BOSS 09~12 + 隐藏 BOSS
- M3-D 的 UI 素材
- M3-E 的移动端素材

**已交付的 M1/M2 素材不需要立即重做**，但如果后续有关卡重新生成背景的机会（如质量升级），应按本规范执行。

---

## 10. 参考图关键特征速查

| 参考图 | 场景 | 核心风格关键词 |
|--------|------|---------------|
| 图 1（山地关卡） | 陆地军事基地 | 手绘纹理地面、灌木团块、木质建筑顶亮底暗、迷彩坦克极小 |
| 图 2（海上战舰） | 海上 BOSS 战 | 深蓝海面波纹、战舰微缩模型感、炮台 oversized、白色浪花尾迹、弹幕橙红金黄 |
| 图 3（海空大战） | 空战 | 敌机侧飞 30°倾斜、抛物线轨迹、火焰弹带拖尾、海陆交界分层 |

---

**Design Agent 必须在开始 M3-B 素材生成前阅读本文档，并在 DesignLog.md 中确认已遵循本规范。**
