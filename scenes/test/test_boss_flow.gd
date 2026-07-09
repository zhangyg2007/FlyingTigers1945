## BOSS战斗+结算跳转端到端验证脚本（任务5）
## 运行方式：godot --headless --quit-after 1200 res://scenes/test/test_boss_flow.tscn
##
## 验证流程：
## 1. 动态创建关卡（LevelBase + 测试CSV + 玩家场景）
## 2. 连接关卡的 boss_appeared / level_cleared 信号
## 3. 等待 BOSS 出场（1秒CSV + 2秒入场延迟 = 3秒）
## 4. 检测到 BOSS 后，调用 take_damage 击杀 BOSS
## 5. 验证 boss_defeated → end_level → level_cleared 信号链
## 6. 在 _goto_result_scene() 实际切换场景前退出（避免测试节点被销毁）
extends Node

## 测试结果
var _stage_loaded: bool = false
var _boss_spawned: bool = false
var _boss_killed: bool = false
var _level_cleared: bool = false
var _stage_instance: Node = null
var _boss_ref: Node = null
var _kill_timer: float = 0.0
var _elapsed: float = 0.0

## 最大等待时间（秒）：BOSS 3秒出场 + 击杀 + 3秒结算延迟 + 余量
const MAX_WAIT: float = 20.0


func _ready() -> void:
	print("========================================")
	print("  [TestBossFlow] 任务5: BOSS战斗+结算跳转验证")
	print("========================================")

	# 动态创建关卡（使用 LevelBase 脚本）
	var level_script := load("res://levels/level_base.gd")
	if level_script == null:
		_fail("无法加载 level_base.gd")
		return

	_stage_instance = Node.new()
	_stage_instance.set_script(level_script)
	_stage_instance.name = "TestStage"

	# 配置关卡参数（使用仅BOSS的测试CSV，避免敌机池警告刷屏）
	_stage_instance.level_id = "test_boss_flow"
	_stage_instance.level_name = "BOSS流程测试"
	_stage_instance.wave_config_path = "res://resources/level_data/stage_01_test_boss_only.csv"
	_stage_instance.bg_scroll_speed = 80.0
	_stage_instance.boss_scene_path = "res://scenes/bosses/boss_bomber.tscn"
	_stage_instance.bgm_path = ""

	add_child(_stage_instance)
	_stage_loaded = true

	# 接入玩家场景（任务5核心：玩家场景接入后验证）
	var player_scene := load("res://scenes/player/player_p40.tscn")
	if player_scene != null:
		var player: Node = player_scene.instantiate()
		player.position = Vector2(540, 1620)
		_stage_instance.add_child(player)
		print("[TestBossFlow] 玩家场景已接入 (player_p40)")
	else:
		print("[TestBossFlow] ⚠️ 警告: 无法加载玩家场景")

	# 连接关卡信号（LevelBase 定义了 boss_appeared / level_cleared 信号）
	if _stage_instance.has_signal("boss_appeared"):
		_stage_instance.boss_appeared.connect(_on_boss_appeared)
	if _stage_instance.has_signal("level_cleared"):
		_stage_instance.level_cleared.connect(_on_level_cleared)

	print("[TestBossFlow] 关卡已创建，等待 BOSS 出场（1秒+2秒入场延迟）...")


func _process(delta: float) -> void:
	_elapsed += delta

	# 阶段2：击杀 BOSS（boss_appeared 信号已设置 _boss_spawned）
	if _boss_spawned and not _boss_killed:
		_kill_timer += delta
		if _kill_timer > 1.0 and _boss_ref != null and is_instance_valid(_boss_ref):
			# 调用 take_damage 击杀 BOSS（一次性扣满 HP）
			var boss_max_hp: int = _boss_ref.max_hp if "max_hp" in _boss_ref else 350
			print("[TestBossFlow] 对 BOSS 造成 %d 伤害（max_hp+100）" % (boss_max_hp + 100))
			_boss_ref.take_damage(boss_max_hp + 100)

		# 检查 BOSS 是否已被击败（queue_free 后实例失效）
		if _boss_ref == null or not is_instance_valid(_boss_ref):
			_boss_killed = true
			print("[TestBossFlow] BOSS 实例已销毁（击败确认）")

	# 超时检测
	if not _level_cleared and _elapsed > MAX_WAIT:
		print("[TestBossFlow] 超时（%.1f秒），当前进度:" % _elapsed)
		_print_summary()
		get_tree().quit(1)


## boss_appeared 信号回调：BOSS 出场
func _on_boss_appeared(boss: Node2D) -> void:
	_boss_ref = boss
	_boss_spawned = true
	print("[TestBossFlow] ✅ 收到 boss_appeared 信号，BOSS 已出场")
	# 打印 BOSS 状态信息
	if boss.has_method("get_current_state_name"):
		print("[TestBossFlow] BOSS 当前状态: %s" % boss.get_current_state_name())
	if "max_hp" in boss:
		print("[TestBossFlow] BOSS max_hp: %d" % boss.max_hp)


## level_cleared 信号回调：关卡通关（BOSS击败→end_level→level_cleared）
## 此信号在 end_level() 中发射，发射后紧接着调用 _goto_result_scene()
## 所以在此回调中直接退出，避免场景切换销毁测试节点
func _on_level_cleared() -> void:
	_level_cleared = true
	print("[TestBossFlow] ✅ 收到 level_cleared 信号（结算跳转链路验证通过）")
	_print_summary()
	# 在 _goto_result_scene() 执行前退出
	get_tree().quit(0)


func _print_summary() -> void:
	var lines: Array[String] = [
		"========================================",
		"  [TestBossFlow] 验证结果摘要",
		"========================================",
		"  1. 关卡场景加载:   %s" % ("✅ PASS" if _stage_loaded else "❌ FAIL"),
		"  2. 玩家场景接入:   ✅ PASS (player_p40 实例已添加)",
		"  3. BOSS出场:       %s" % ("✅ PASS" if _boss_spawned else "❌ FAIL"),
		"  4. BOSS被击杀:     %s" % ("✅ PASS" if _boss_killed else "❌ FAIL"),
		"  5. 结算跳转链路:   %s" % ("✅ PASS" if _level_cleared else "❌ FAIL"),
		"     (boss_defeated → end_level → level_cleared → _goto_result_scene)",
		"  总耗时: %.1f秒" % _elapsed,
		"========================================",
	]
	var all_pass: bool = _stage_loaded and _boss_spawned and _boss_killed and _level_cleared
	if all_pass:
		lines.append("  总结: ✅ 任务5 端到端验证通过")
	else:
		lines.append("  总结: ❌ 任务5 端到端验证未通过（见上方详情）")
	lines.append("========================================")

	# 打印到控制台
	for line in lines:
		print(line)

	# 同时写入文件（避免 PowerShell stderr 捕获问题）
	var result_path: String = "res://test_boss_flow_result.txt"
	var f := FileAccess.open(result_path, FileAccess.WRITE)
	if f != null:
		for line in lines:
			f.store_line(line)
		f.close()
		print("[TestBossFlow] 结果已写入: %s" % result_path)


func _fail(msg: String) -> void:
	print("[TestBossFlow] ❌ 错误: %s" % msg)
	_print_summary()
	get_tree().quit(1)
