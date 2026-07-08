# Flying Tigers 1945 — 开发日志 (Devlog)

> Code 部门开发日志。记录每次任务的内容、代码评审发现、排查错误的方案与最终结论。

---

## 任务 0：初始代码评审（开发前）

**日期**: 2026-07-09
**任务**: 在搭建 .tscn 场景文件之前，对项目骨架和 24 个 .gd 脚本进行初始代码评审，识别会阻塞场景运行的致命问题与潜在架构隐患。
**评审范围**: `project.godot`、`autoload/`、`scenes/test/`、`scenes/player/`、`scenes/bullets/`、`scenes/enemies/`、`scenes/powerups/`、`scripts/`、`README.md`
**文档参考**: `docs/README.md`、`docs/tech-spec/tech-spec.html`、`docs/master-interface-spec/master-interface-spec.html`

### 评审发现

#### A. test_player_scene.gd — 致命错误（P0，会阻塞场景启动）

**问题 A1**: `_ready()` 中第 233 行 `_player.body_entered.connect(_on_player_body_entered)`
- `CharacterBody2D` 没有 `body_entered` 信号，该信号属于 `Area2D`。
- 运行时会抛出 `Invalid signal 'body_entered'` 错误，导致 `_ready()` 在此中断，后续的 `_create_bullet_samples()` / `_create_debug_hud()` 不执行，HUD 不显示，且控制台报错刷屏。
- 而 `_on_player_body_entered()`（530-534 行）函数体本身为空（仅注释），无实际作用。
- **修复方案**: 删除该信号连接，并删除空函数 `_on_player_body_entered`。

**问题 A2**: `_handle_extra_keys()` 中 G/R 键用 `Input.is_physical_key_pressed(KEY_G)`（651-657 行）
- `is_physical_key_pressed` 是**电平检测**（按住期间每帧返回 true），而 `_handle_extra_keys` 每帧调用 → 按一下 G 键，`_god_mode` 会在多帧内反复翻转，结果是随机的；按住 R 键会每帧重置玩家状态。
- **修复方案**: 改用边沿检测。最稳妥方式是在 `_input(event)` 中处理 `InputEventKey`，判断 `event.is_pressed() and not event.is_echo()`。

#### B. test_player_scene.gd — 死代码（P2，不影响运行但需清理）

**问题 B1**: 第 232 行 `_hitbox_area.area_entered.connect(_on_hitbox_area_entered)` 与 `_on_hitbox_area_entered()`（521-527 行）
- 判定点 `Area2D` 配置了检测 Layer3(EnemyBullet)/Layer5(PowerUp)，但测试敌弹是 `ColorRect`（非 `Area2D`/`PhysicsBody2D`），`area_entered` 永不触发。
- 该回调内部还判断 `area is ColorRect`，而 `ColorRect` 不是 `CollisionObject2D`，永远不会作为 area 信号参数传入。
- 实际命中检测由 `_update_bullets()` 中的距离检测（488-496 行）完成，功能正常。
- **结论**: 信号连接与回调为死代码。保留 hitbox 可视化（红色小点）用于手感调试，但移除无效信号连接，避免误导。

#### C. test_stage.gd — 同类输入 BUG（P1，本次任务范围外但记录）

**问题 C1**: `_handle_debug_keys()` 第 571-586 行用 `Input.get_pressed_physical_keycodes()` + `is_physical_key_pressed` 处理数字键 1-5
- 同样是电平检测：按住数字键会每帧重复触发（每帧生成敌机/触发炸弹/切换 Power）。
- **结论**: 本次不修复（超出"玩家战机测试场景"任务范围），记录待后续处理。修复方式同 A2。

#### D. 架构不一致 — ObjectPool 命名冲突与接口不兼容（P2，本次不涉及但记录）

**问题 D1**: 全局类名冲突风险
- `scripts/object_pool.gd` 声明 `class_name ObjectPool`（全局类名）。
- `autoload/pool_manager.gd` 内部声明 `class ObjectPool`（内部类，不占全局名）。
- 经核实，全局名 `ObjectPool` 解析到 `scripts/object_pool.gd`，`pool_manager.gd` 的内部类被其自身命名空间遮蔽，不冲突。但代码可读性差。

**问题 D2**: `player_base.gd` 的 `object_pool` 字段与 `PoolManager` 单例接口不兼容
- `player_base.gd` 字段类型为 `ObjectPool`（即 scripts/object_pool.gd），调用 `object_pool.get_object(bullet_scene)`（不带 parent）。
- 全局单例 `PoolManager`（pool_manager.gd）接口为 `get_object(scene, parent=null)`，且会自动 `add_child` 到场景树。
- 两者签名与行为不同。当前 `player_base.gd` 拿到对象后还会自行 `add_child`，若改用 PoolManager 会双重挂载。
- **结论**: 本次测试场景不使用 `player_base.gd`（test_player_scene 自含逻辑），不影响。待后续接入正式玩家场景时需统一：建议统一用 `PoolManager` 单例，移除 `player_base.gd` 的 `object_pool` 字段或改为引用 `PoolManager`。

#### E. 文档与实现的差异（记录，非 bug）

- `tech-spec.html` 未规定测试场景命名，但 `README.md` 明确使用 `scenes/test/test_player_scene.tscn` 与 `scenes/test/test_stage.tscn` → 遵循 README。
- tech-spec 碰撞层矩阵中 Player 的 Mask 为 `3,4,5,6,8`；`player_base.gd` 实现的 mask 只含 Layer4（body）+ hitbox Area2D 含 Layer3/5。基本吻合，测试场景用 ColorRect 不走物理层，无影响。
- Autoload 注册顺序（project.godot）：GameManager → AudioManager → PoolManager → SaveManager → SpawnManager。SaveManager 依赖 AudioManager（保存音量），当前顺序满足该依赖。其余无明确依赖文档。

### 评审结论

- 阻塞 test_player_scene 启动的只有 **A1**（body_entered 连接错误）。必须修复。
- **A2** 严重影响测试体验（G/R 键失效），必须修复。
- B1 建议顺手清理（死代码）。
- C1、D1、D2 记录在案，本次不处理，后续任务跟进。

---

## 任务 1：搭建玩家战机测试场景（test_player_scene）

**日期**: 2026-07-09
**目标**: 创建 `scenes/test/test_player_scene.tscn`，挂载 `test_player_scene.gd`，使其可在 Godot 4.7 中直接运行，验证玩家移动、射击、蓄力、碰撞判定、无敌闪烁。

### 执行步骤

1. 修复 `test_player_scene.gd` 的 P0/P1 问题（A1、A2）并清理 B1 死代码。
2. 创建 `scenes/test/test_player_scene.tscn`（根节点 Node2D + 挂载脚本）。
3. 验证：脚本语法、autoload 依赖、场景可独立运行。

### 修复与排查记录

实际执行中，除了评审阶段已识别的 A1/A2/B1，还发现一个**骨架自带的新致命 bug**：

#### 新发现 P0-A：`_update_hud()` 多行字符串 + `%` 格式化解析错误

- **现象**: `godot --check-only` 报 `Parse Error: Expected closing ")" after grouping expression`，定位到 `_update_hud()` 内第一个字符串行。
- **根因**: 原代码在圆括号分组内使用了"多行相邻字符串字面量拼接 + 紧跟 `% [数组]` 格式化"的写法：
  ```gdscript
  _debug_label.text = (
      "[PlayerTest]\n"
      "FPS: %d\n"
      ...
      % [ ... ]
  )
  ```
  Godot 4.7 解析器在圆括号分组内遇到第一个字符串字面量后，期望 `)` 关闭分组，无法正确处理后续跨行相邻字符串拼接再接 `%` 操作符的结构。
- **影响**: 这是项目骨架自带的解析错误——骨架从未真正通过 Godot 解析，意味着 24 个 .gd 文件创建后并未做过整体编译验证。`test_player_scene.gd` 根本无法加载，场景无法启动。
- **修复**: 先用 `+` 显式连接构造格式串（赋值给局部变量 `fmt`），再单独对 `fmt` 执行 `% [参数数组]` 格式化。将"字符串拼接"与"`%` 格式化"两个操作拆成两条语句，规避解析歧义。
- **排查方法**: 用 `Godot_v4.7-stable_win64_console.exe --headless --check-only --script <path>` 做单脚本语法检查，错误信息会精确定位行号。

#### A1 修复（body_entered 信号）
- 删除 `_ready()` 中的 `_player.body_entered.connect(_on_player_body_entered)`（CharacterBody2D 无此信号）。
- 删除空函数 `_on_player_body_entered`。
- `_on_hitbox_area_entered` 同步删除（B1 死代码：敌弹是 ColorRect，area_entered 永不触发）。
- 命中检测统一由 `_update_bullets()` 中的距离检测（`dist < 6.0`）负责，功能不变。
- 保留 hitbox Area2D 节点仅用于可视化判定点（红色小点），便于手感调试。

#### A2 修复（G/R 输入边沿检测）
- 将 G/R 键从 `_handle_extra_keys()`（每帧轮询）移至新增的 `_input(event)` 回调。
- 用 `InputEventKey.pressed and not echo` 实现按下边沿触发，避免按住时每帧翻转/重置。
- `_handle_extra_keys()` 仅保留每帧轮询的 `_handle_bomb_input()`（内部已用 `is_action_just_pressed`，本身是边沿检测，无需改动）。

#### 场景文件
- 创建 `scenes/test/test_player_scene.tscn`：根节点 `Node2D`（name="TestPlayerScene"）+ 挂载 `res://scenes/test/test_player_scene.gd`。
- 所有子节点（背景、玩家、判定点、子弹样本、调试HUD）均由脚本 `_ready()` 动态创建，故 .tscn 无需静态节点。
- .tscn 故意省略 `uid`，Godot 4.7 打开项目时会自动补全，避免手写 uid 合法性风险。

### 验证结果

1. **语法检查**: `godot --headless --check-only --script res://scenes/test/test_player_scene.gd` → 退出码 0，无错误。
2. **场景运行**: `godot --headless res://scenes/test/test_player_scene.tscn --quit-after 90` → 退出码 0，控制台正确输出启动信息：
   ```
   ========================================
     [TestPlayer] 玩家测试场景已启动
     测试项目: 移动、射击、蓄力、碰撞判定、无敌闪烁
     WASD/方向键=移动  Z/J=射击  X/K=炸弹
     G键=切换上帝模式  R键=重置状态
   ========================================
   ```
   `_ready()` 完整执行（不再被 body_entered 错误中断），无运行时异常。
3. **Autoload 依赖**: test_player_scene 自含逻辑，不调用任何 Autoload 单例；5 个 Autoload（GameManager/AudioManager/PoolManager/SaveManager/SpawnManager）均加载成功，未阻断场景启动。

### 遗留问题（后续任务跟进）

| 编号 | 问题 | 优先级 | 建议处理时机 |
|------|------|--------|--------------|
| C1 | `test_stage.gd` 数字键 1-5 用 `is_physical_key_pressed`（每帧重复触发） | P1 | 搭建 test_stage.tscn 时一并修复 |
| C2 | `test_stage.gd` 的 `_update_debug_info` 存在与本任务相同的"多行字符串+%`"解析错误 | P0 | 搭建 test_stage.tscn 时必须修复 |
| D1 | `scripts/object_pool.gd` 的 `class_name ObjectPool` 与 `pool_manager.gd` 内部类同名（遮蔽合法但可读性差） | P2 | 统一对象池架构时处理 |
| D2 | `player_base.gd` 的 `object_pool` 字段接口与 `PoolManager` 单例不兼容（`get_object` 签名/挂载行为不同） | P2 | 接入正式玩家场景时统一为 PoolManager 单例 |
| - | `project.godot` 的 `run/main_scene` 指向 `res://scenes/ui/main_menu.tscn`（文件不存在） | P1 | 搭建 main_menu.tscn 时解决；当前需在编辑器用"运行指定场景"启动 test_player_scene |

### 如何运行测试场景

- **编辑器内**: 打开项目 → 在文件浏览器选中 `scenes/test/test_player_scene.tscn` → 右键"运行场景"（或按 Ctrl+Shift+F5 / Ctrl+F6 视平台而定）。
- **命令行**: `Godot_v4.7-stable_win64_console.exe --path <项目根> res://scenes/test/test_player_scene.tscn`
- **操作**: WASD/方向键移动，Z/J 射击（按住蓄力 1.5s 松开释放蓄力攻击），X/K 炸弹，G 切换上帝模式，R 重置状态。
