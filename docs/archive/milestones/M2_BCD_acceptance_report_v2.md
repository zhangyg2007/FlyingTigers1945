# Flying Tigers 1945 — M2-B/C/D 验收确认报告 v2

**验收日期**: 2026-07-10
**提交**: f3a19ce (main) — [M2] 代码调优完成 + Design资产更新 + 关卡配置修复
**变更**: 24 文件
**验收人**: PM Agent

---

## 一、Code 部门验收 — 评级 A-

### 代码调优 7 项 — 6/7 通过

| # | 调优项 | 结果 | 说明 |
|---|--------|------|------|
| 1 | StateMachine加入场景树 | ✅ | `add_child(_state_machine)`，自动驱动状态更新 |
| 2 | object_pool字段移除 | ✅ | EnemyBase统一用PoolManager.return_object() |
| 3 | EnemyBase碰撞信号连接 | ✅ | area_entered正确连接，无body_entered误用 |
| 4 | SpawnManager BOSS映射 | ✅ | bomber/nachi/cruiser(别名)/fortress全部精确映射 |
| 5 | LevelBase委托SpawnManager | ✅ | 优先委托，后备enemy_fighter.tscn |
| 6 | BOSS弹幕对象池化 | ⚠️ | 池化获取正确，但**P1 Bug**: `_spawn_bullet`设置`bullet.velocity`(Area2D无此属性)，应改为`bullet.direction`+`bullet.speed`，导致4/5弹幕方向失效 |
| 7 | 场景切换清理对象池 | ✅ | end_level/force_end_level均调return_all_active() |

### 上轮问题闭环

| 上轮问题 | 本轮状态 |
|----------|----------|
| P2: stage_config.json stage_03 bg_layers引用salween | ✅ 已修复为nujiang |
| P3: boss_bomber sprite命名不一致 | ⚠️ 仍存在（M3处理） |

### Code 新发现问题

| 优先级 | 问题 | 影响 | 建议 |
|--------|------|------|------|
| **P1** | `_spawn_bullet`/`_spawn_missile`设置`bullet.velocity`（Area2D无此属性），应为`bullet.direction`+`bullet.speed` | 4/5弹幕模式方向失效，子弹以默认值(向下,400)移动 | 参照EnemyBase.shoot_pattern() L233-234修复 |
| P2 | `area.queue_free()`绕过BulletBase._destroy() | 未来玩家子弹池化后有风险 | 改为`area._destroy()` |
| P3 | missile_enemy.tscn资源缺失 | missile_volley模式静默失效 | M3创建资源 |

### 语法检查: 全通过 ✅
- body_entered on CharacterBody2D: 无复现
- _handle_charge不存在函数: 无复现
- 多行字符串+%格式化: 无复现

---

## 二、Design 部门验收 — 评级 B-

### 上轮P0/P1问题修正情况

| # | 文件 | 上轮问题 | 本轮判定 | 详情 |
|---|------|---------|---------|------|
| P0-1 | `bg_rangoon_far.png` | 高斜角鸟瞰 | ⚠️ 部分修正 | 佛塔已移除✅，建筑改屋顶✅；但整体仍60-75°斜角，树冠带方向阴影 |
| P0-2 | `bg_hump_far.png` | 侧面风景画 | ❌ 未修正 | 天空已去除✅；但雪山仍为侧视3D山体，有透视灭点 |
| P0-3 | `boss_fortress_phase1.png` | 等距斜视角 | ✅ 已修正 | 纯俯角，所有结构仅顶面 ⚠️残留AI水印 |
| P0-4 | `boss_fortress_phase2.png` | 斜视角 | ✅ 已修正 | 纯俯角，炮管为同心圆截面 |
| P1-1 | `boss_cruiser_phase2.png` | 3/4斜视角 | ✅ 已修正 | 纯俯角，与Phase1统一 |

**修正率**: 3/5 P0完全修正，1/5部分修正，1/5未修正

### 新增资产验证

| 资产 | 结果 | 说明 |
|------|------|------|
| bg_kunming_lake.png | ⚠️ | 基本俯视有瑕疵，码头见厚度，约70-80° |
| bg_kunming_mountain.png | ❌ | 非纯俯视，峡谷透视灭点，山脊侧面 |
| 4张玩家卡片UI | ⚠️ | 机型识别正确✅；3处错别字(TIGOTS/ARMIOR/ARKMOR)；尺寸200x320≠规格256x256 |

### 新发现问题

| 优先级 | 问题 | 文件 |
|--------|------|------|
| **P0** | bg_hump_far.png 仍为侧视雪山 | backgrounds/stage_04_hump/ |
| **P1** | bg_rangoon_far.png 仍未达纯俯视 | backgrounds/stage_02_rangoon/ |
| **P1** | bg_kunming_mountain.png 侧视透视 | backgrounds/stage_01_kunming/ |
| **P1** | 3个BOSS缺透明抠图，海水背景烘焙进精灵 | boss_fortress_phase1/2, boss_cruiser_phase2 |
| **P2** | UI卡片3处错别字 | ui_player_card_*.png |
| **P2** | UI卡片尺寸200x320≠规格256x256 | ui_player_card_*.png |
| **P2** | boss_fortress_phase1残留AI水印 | boss/ |

### 技术规格: 格式通过 ✅

- 11/11 PNG-32 RGBA，0个JPEG伪装
- 背景 512x2048 ✅，BOSS 512x512 ✅
- bg_kunming_far.png 已删除确认 ✅

### Design 核心问题分析

**背景"纯俯视"是贯穿三轮的未解难题**。Design在BOSS像素艺术上能做到纯俯角（3/3修正达标），但写实背景始终带斜角/侧视/透视。建议换工艺：改用正射/卫星式生成，或手工消除透视。

---

## 三、配置验收

### stage_config.json

| 关卡 | bg_layers | 结果 |
|------|-----------|------|
| stage_01 | 仍引用已删除的`bg_kunming_far`，未纳入新增的`lake`/`mountain` | ❌ **P1 阻塞** |
| stage_02 | `bg_rangoon_*` ✅ | ✅ |
| stage_03 | 已从`bg_salween_*`修正为`bg_nujiang_*` ✅ | ✅ |

**P1问题**: DesignLog已明确提示Code需更新Stage 1为5层结构(near/mid/ground/lake/mountain)，但Code未执行。运行时第1关背景加载会失败。

### .gitignore ✅
5项规则全部包含，临时文件已清理。

### 文档验收

| 文档 | 评级 | 说明 |
|------|------|------|
| Devlog.md | A | 7项调优逐条记录，验证结果+遗留问题完整 |
| DesignLog.md | A | 视角修正/玩家卡片/kunming重规划全部记录，Code交接提示清晰 |
| 代码评审报告 | A | 自评A级，7项建议已闭环整改 |

---

## 四、总体评级

| 部门 | 评级 | 上轮评级 | 趋势 |
|------|------|----------|------|
| **Code** | **A-** | A- | → 持平（7项调优6项通过，1个P1新发现） |
| **Design** | **B-** | B+ | ↓ 退步（2张P0背景未修正+新背景侧视+BOSS缺透明+UI错别字） |
| **配置** | **B** | — | stage_01 bg_layers未同步（P1阻塞） |
| **文档** | **A** | B+ | ↑ 提升（临时文件已清理，记录完整） |

---

## 五、整改要求

### Code 部门 (P1，限期下次提交)

| 优先级 | 问题 | 修正要求 |
|--------|------|----------|
| **P1** | `_spawn_bullet`/`_spawn_missile`设置`bullet.velocity` | 改为`bullet.direction = dir.normalized()` + `bullet.speed = speed`，参照EnemyBase L233-234 |
| **P1** | stage_config.json stage_01 bg_layers | 从4层(far/mid/near/ground)更新为5层(near/mid/ground/lake/mountain)，移除已删除的`bg_kunming_far` |
| P2 | `area.queue_free()` | 改为`area._destroy()` |

### Design 部门 (P0/P1，限期下次提交)

| 优先级 | 问题 | 修正要求 |
|--------|------|----------|
| **P0** | bg_hump_far.png 侧视雪山 | 完全重绘为纯top-down俯视，只能看到雪山/冰川顶面 |
| **P1** | bg_rangoon_far.png 仍斜角 | 继续修正为纯俯视 |
| **P1** | bg_kunming_mountain.png 侧视 | 重绘为纯俯视山体顶面 |
| **P1** | 3个BOSS缺透明抠图 | 扣除海水背景，仅保留BOSS主体 |
| **P2** | UI卡片3处错别字 | TIGOTS→TIGERS, ARMIOR→ARMOR, ARKMOR→ARMOR |
| **P2** | UI卡片尺寸 | 统一为256x256或与Design Spec对齐 |
| **P2** | boss_fortress_phase1 AI水印 | 移除水印 |

### Design 工艺建议

**写实背景纯俯视问题已贯穿三轮未彻底解决**。建议Design Agent：
1. 放弃"生成后修正"的工艺路线
2. 改用正射/卫星图风格生成（prompt加入`orthophoto, satellite imagery, no perspective, no vanishing point`）
3. 或参照BOSS像素艺术的成功经验，对背景也采用像素/扁平化风格

---

## 六、里程碑状态

M2-B/C/D **有条件通过**。2个P1问题（Code弹幕方向bug + stage_01 bg_layers配置断裂）需在进入M3前修复。Design背景视角问题可并行迭代，不阻塞M3启动。

| 里程碑 | 状态 | 说明 |
|--------|------|------|
| M1 核心原型 | ✅ 已通过 | A / A |
| M2 关卡+BOSS | ⚠️ 有条件通过 | Code A- / Design B-，2个P1限期修复 |
| M3 完整系统 | 等待M2 P1修复后启动 | — |

---

**报告结束**
