# Flying Tigers 1945

二战中国-缅滇战场纵向卷轴射击游戏，灵感来源于彩京《1945突击者》。

## 技术栈

| 项目 | 说明 |
|------|------|
| 引擎 | **Godot 4.7** |
| 语言 | **GDScript 2.0** |
| 类型 | 2D 纵向卷轴 STG |
| 视口 | 1080x1920（竖屏） |

## 快速开始

### 1. 打开项目

使用 Godot 4.7 编辑器，打开本项目根目录（包含 `project.godot` 的文件夹）。

```
Godot 4.7 -> 项目 -> 导入 -> 选择 FlyingTigers1945 文件夹
```

### 2. 运行测试场景

在编辑器中直接运行测试场景验证核心功能：

| 场景路径 | 用途 |
|----------|------|
| `scenes/test/test_player_scene.tscn` | 玩家移动、射击、蓄力、碰撞、无敌闪烁 |
| `scenes/test/test_stage.tscn` | 完整关卡流程：移动、射击、敌机生成、炸弹 |

> 测试场景不依赖任何外部资源，全部使用代码动态创建占位节点（ColorRect），可直接运行。

### 3. 运行单元测试

将 `tests/test_object_pool.gd` 挂载到空Node上运行，或在命令行中执行：

```bash
godot --headless -s res://tests/test_object_pool.gd
```

## 项目结构

```
FlyingTigers1945/
├── project.godot              # 项目配置（输入映射、碰撞层、Autoload）
├── README.md
│
├── autoload/                  # 全局单例（Autoload）
│   ├── game_manager.gd       # 游戏状态：分数、生命、Power、关卡进度
│   ├── audio_manager.gd      # BGM/SFX 播放管理、音量控制
│   ├── pool_manager.gd       # 对象池管理：子弹、敌机、特效的复用
│   ├── save_manager.gd       # 存档：ConfigFile格式，持久化进度
│   └── spawn_manager.gd      # 敌人波次控制：CSV配置驱动
│
├── scenes/                    # 游戏场景和脚本
│   ├── player/
│   │   └── player_base.gd    # 玩家战机基类（8方向移动、射击、蓄力、炸弹）
│   ├── enemies/
│   │   └── enemy_base.gd     # 敌机基类（HP、弹幕、掉落、路径移动）
│   ├── bosses/
│   │   └── boss_base.gd      # Boss基类
│   ├── bullets/
│   │   └── bullet_base.gd     # 子弹基类（玩家弹/敌弹，Layer区分）
│   ├── powerups/
│   │   └── powerup_base.gd   # 道具基类（Power/Bomb/Score/Medkit）
│   └── test/                  # 测试场景
│       ├── test_stage.gd     # 关卡测试：敌机生成、碰撞、炸弹
│       └── test_player_scene.gd  # 玩家测试：移动、射击、蓄力、无敌
│
├── scripts/                    # 通用工具脚本
│   ├── object_pool.gd         # 泛型对象池（PackedScene级别管理）
│   ├── state_machine.gd       # 有限状态机
│   ├── csv_parser.gd          # CSV关卡数据解析器
│   └── difficulty_curve.gd    # 难度曲线计算
│
├── resources/                  # 关卡配置数据
│   └── level_data/
│       ├── stage_01_kunming.csv    # 第1关：昆明
│       └── stage_config.json       # 关卡全局配置
│
├── levels/                     # 关卡基类
│   └── level_base.gd          # 关卡流程基类（波次触发、Boss战、结算）
│
└── tests/                      # 单元测试
    └── test_object_pool.gd    # 对象池测试（注册/获取/归还/溢出/并发）
```

## 项目架构说明

### 全局单例（Autoload）

5个Autoload单例在 `project.godot` 中注册，项目运行时全局可用：

| 单例 | 职责 |
|------|------|
| **GameManager** | 分数、生命、炸弹、Power等级、游戏状态切换、难度倍率 |
| **PoolManager** | 对象池注册与调度，管理子弹/敌机/特效的创建与回收 |
| **SpawnManager** | 读取CSV关卡配置，按时间轴生成敌人波次，支持多种编队 |
| **AudioManager** | BGM循环播放、SFX音效池、音量持久化 |
| **SaveManager** | ConfigFile格式存档，关卡进度/最高分/解锁飞机/设置 |

### 碰撞层定义

| Layer | 名称 | 用途 |
|-------|------|------|
| 1 | Player | 玩家战机 |
| 2 | PlayerBullet | 玩家子弹 |
| 3 | EnemyBullet | 敌方子弹 |
| 4 | Enemy | 敌机 |
| 5 | PowerUp | 道具 |
| 6 | GroundTarget | 地面目标 |
| 7 | Ally | 友军 |
| 8 | Scenery | 场景装饰 |

### 核心机制（彩京式）

- **碰撞判定**：玩家拥有极小的判定点（hitbox_radius=4px），与视觉机身分离
- **Power系统**：火力等级1~4，被敌弹命中时Power>1则降级而非死亡
- **蓄力攻击**：按住射击键超过1.5秒松开，释放扇形强力弹幕
- **炸弹**：全屏清弹 + 2秒无敌 + 对所有敌机造成伤害

## 操作说明

| 按键 | 功能 |
|------|------|
| WASD / 方向键 | 8方向移动 |
| Z / J | 射击（按住连发，长按蓄力） |
| X / K | 炸弹（全屏清弹） |
| Esc / P | 暂停 |

### 测试场景额外按键

**test_stage.gd:**

| 数字键 | 功能 |
|--------|------|
| 1 | 生成普通敌机 |
| 2 | 生成快速敌机 |
| 3 | 生成BOSS |
| 4 | 触发全屏炸弹效果 |
| 5 | 切换Power等级（1->2->3->4循环） |

**test_player_scene.gd:**

| 按键 | 功能 |
|------|------|
| G | 切换上帝模式（不受伤害） |
| R | 重置玩家状态 |

## 资源需求

当前项目使用 ColorRect 占位节点，正式开发需要以下资源：

| 资源 | 存放路径 | 状态 |
|------|----------|------|
| 玩家战机Sprite | `assets/sprites/player/` | 待交付 |
| 敌机Sprite | `assets/sprites/enemies/` | 待交付 |
| Boss Sprite | `assets/sprites/bosses/` | 待交付 |
| 子弹Sprite | `assets/sprites/bullets/` | 待交付 |
| 道具Sprite | `assets/sprites/powerups/` | 待交付 |
| 背景TileMap | `assets/sprites/backgrounds/` | 待交付 |
| BGM音频 | `assets/audio/bgm/` | 待交付 |
| SFX音效 | `assets/audio/sfx/` | 待交付 |

> Design部门交付Sprite后放入 `assets/sprites/` 对应子目录，替换ColorRect占位节点。

## 开发流程

```
1. 在 test 场景中开发和调试核心逻辑
   ├── test_player_scene.gd → 玩家移动/射击/蓄力/无敌
   └── test_stage.gd → 完整关卡流程/敌机生成/碰撞

2. 功能验证通过后，逐步替换占位节点为正式资源
   ├── ColorRect → Sprite2D + Texture2D
   └── 代码创建 → .tscn 场景文件

3. 配置CSV关卡数据（resources/level_data/）
   ├── 波次时间线、敌机类型、编队方式
   └── 速度倍率、移动路径ID

4. 集成测试 → 正式关卡流程
```

## 性能优化要点

- **对象池**：所有频繁创建/销毁的对象（子弹、敌机、特效）通过 `PoolManager` 统一管理，避免运行时GC压力
- **池容量配置**：玩家弹50、敌弹300、敌机30、特效20、道具15（可在 `pool_manager.gd` 中调整）
- **碰撞分层**：8层碰撞层精确控制检测范围，减少不必要的碰撞计算
- **判定点分离**：玩家使用4px判定点而非整机身碰撞，大幅降低碰撞检测面积
- **屏幕外销毁**：子弹和敌机超出屏幕边界后自动归还对象池，不积累无用对象
- **CSV驱动关卡**：关卡数据与逻辑分离，运行时按需解析，避免硬编码大量配置

## CSV关卡配置格式

```csv
wave_index,time,enemy_type,count,formation,spawn_x,spawn_y,speed_mult,path_id
0,0.0,scout,5,line,540,0,1.0,0
1,3.0,fighter,3,v_formation,540,0,1.2,1
2,6.0,bomber,1,solo,540,0,0.8,0
3,12.0,boss,1,solo,540,0,0.5,0
```

| 字段 | 说明 |
|------|------|
| wave_index | 波次序号 |
| time | 生成时间（秒） |
| enemy_type | 敌机类型：scout/fighter/bomber/ace/boss/mid_boss/turret/ground_unit |
| count | 生成数量 |
| formation | 编队：line/v_formation/diamond/swarm/solo |
| spawn_x | 生成X坐标 |
| spawn_y | 生成Y坐标 |
| speed_mult | 速度倍率 |
| path_id | 移动路径ID（0=直线下降） |
