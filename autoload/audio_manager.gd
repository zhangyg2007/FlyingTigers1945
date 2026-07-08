extends Node
## 音频管理器（Autoload单例）
## 负责BGM和SFX的播放管理，提供统一的音量控制和持久化设置。
##
## 使用方式：
##   AudioManager.play_bgm("res://audio/bgm/stage_01.ogg")
##   AudioManager.play_sfx("res://audio/sfx/shoot.wav")
##   AudioManager.bgm_volume = 0.5

# ============================================================
# 节点引用（内部创建）
# ============================================================

## BGM播放器（AudioStreamPlayer，循环播放）
var _bgm_player: AudioStreamPlayer = null

## SFX播放器池（多个AudioStreamPlayer2D，避免同时播放冲突）
var _sfx_pool: Array[AudioStreamPlayer2D] = []

## SFX池大小（最多同时播放几个音效）
const SFX_POOL_SIZE: int = 8

# ============================================================
# 公开变量
# ============================================================

## 主音量（0.0~1.0）
var master_volume: float = 1.0:
	set(value):
		master_volume = clampf(value, 0.0, 1.0)
		_update_volumes()

## BGM音量（0.0~1.0）
var bgm_volume: float = 0.7:
	set(value):
		bgm_volume = clampf(value, 0.0, 1.0)
		_update_volumes()

## SFX音量（0.0~1.0）
var sfx_volume: float = 0.8:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_update_volumes()

## 当前正在播放的BGM路径
var current_bgm_path: String = ""

## BGM音量渐变动画引用
var _bgm_tween: Tween = null

# ============================================================
# 内部变量
# ============================================================

## SFX资源缓存，避免重复加载
var _sfx_cache: Dictionary = {}  # String -> AudioStream

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	## 创建BGM播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	add_child(_bgm_player)

	## 创建SFX播放器池
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer2D.new()
		player.bus = "Master"
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		player.finished.connect(_on_sfx_finished.bind(player))
		add_child(player)
		_sfx_pool.append(player)

	## 加载保存的音量设置
	load_volume()

	## 连接SaveManager信号，在存档加载后同步音量
	if SaveManager:
		SaveManager.data_loaded.connect(_on_save_data_loaded)

# ============================================================
# BGM播放
# ============================================================

## 播放背景音乐（循环播放）
## [param path]: 音频文件路径
## [param fade_in_duration]: 淡入时间（秒），0表示不淡入
func play_bgm(path: String, fade_in_duration: float = 0.0) -> void:
	if path.is_empty():
		push_warning("AudioManager: BGM路径为空，跳过播放。")
		return

	# 如果正在播放相同的BGM，跳过
	if current_bgm_path == path and _bgm_player.playing:
		return

	# 加载音频流
	var stream: AudioStream = _load_stream(path)
	if stream == null:
		push_error("AudioManager: 无法加载BGM '%s'" % path)
		return

	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(0.0)  # 淡入从0开始

	if fade_in_duration > 0.0:
		_bgm_player.play()
		# 使用Tween实现淡入
		if _bgm_tween and _bgm_tween.is_running():
			_bgm_tween.kill()
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(
			_bgm_player, "volume_db",
			linear_to_db(bgm_volume * master_volume),
			fade_in_duration
		)
	else:
		_bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
		_bgm_player.play()

	current_bgm_path = path
	print("AudioManager: 播放BGM '%s'" % path)


## 停止背景音乐
## [param fade_out_duration]: 淡出时间（秒），0表示立即停止
func stop_bgm(fade_out_duration: float = 0.0) -> void:
	if fade_out_duration > 0.0 and _bgm_player.playing:
		# 使用Tween实现淡出
		if _bgm_tween and _bgm_tween.is_running():
			_bgm_tween.kill()
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(
			_bgm_player, "volume_db",
			-80.0,  # 静音
			fade_out_duration
		)
		_bgm_tween.tween_callback(_bgm_player.stop)
	else:
		_bgm_player.stop()

	current_bgm_path = ""


## 暂停BGM
func pause_bgm() -> void:
	_bgm_player.stream_paused = true


## 恢复BGM
func resume_bgm() -> void:
	_bgm_player.stream_paused = false

# ============================================================
# SFX播放
# ============================================================

## 播放音效
## [param path]: 音频文件路径
## [param volume_override]: 单次播放音量覆盖（0.0~1.0），-1表示不覆盖
## [param pitch_scale]: 音调缩放（默认1.0）
## [returns]: 播放该音效的AudioStreamPlayer2D实例（可用于特殊控制）
func play_sfx(path: String, volume_override: float = -1.0, pitch_scale: float = 1.0) -> AudioStreamPlayer2D:
	if path.is_empty():
		push_warning("AudioManager: SFX路径为空，跳过播放。")
		return null

	var stream: AudioStream = _load_stream(path)
	if stream == null:
		push_error("AudioManager: 无法加载SFX '%s'" % path)
		return null

	# 从池中找一个空闲的播放器
	var player: AudioStreamPlayer2D = _get_available_sfx_player()
	if player == null:
		# 所有播放器都在忙，强制回收最早开始播放的那个
		player = _get_oldest_playing_sfx_player()
		if player == null:
			return null

	# 设置音频流和参数
	player.stream = stream
	player.pitch_scale = pitch_scale

	if volume_override >= 0.0:
		player.volume_db = linear_to_db(volume_override * sfx_volume * master_volume)
	else:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

	player.play()
	return player


## 播放音效（指定位置，使用AudioStreamPlayer2D的2D定位功能）
## [param path]: 音频文件路径
## [param global_position]: 音效发出位置
## [param volume_override]: 音量覆盖
func play_sfx_at_position(path: String, global_position: Vector2, volume_override: float = -1.0) -> AudioStreamPlayer2D:
	var player := play_sfx(path, volume_override)
	if player:
		player.global_position = global_position
	return player

# ============================================================
# 音量控制
# ============================================================

## 更新所有播放器的音量
func _update_volumes() -> void:
	if _bgm_player:
		if _bgm_player.playing and not (_bgm_tween and _bgm_tween.is_running()):
			_bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	for player in _sfx_pool:
		player.volume_db = linear_to_db(sfx_volume * master_volume)


## 设置主音量（带setter的快捷方法）
func set_master_volume(value: float) -> void:
	master_volume = value


## 设置BGM音量
func set_bgm_volume(value: float) -> void:
	bgm_volume = value


## 设置SFX音量
func set_sfx_volume(value: float) -> void:
	sfx_volume = value

# ============================================================
# 持久化
# ============================================================

## 保存音量设置到SaveManager
func save_volume() -> void:
	if SaveManager:
		SaveManager.save_settings(master_volume, bgm_volume, sfx_volume)


## 从SaveManager加载音量设置
func load_volume() -> void:
	if SaveManager and SaveManager.has_save():
		var settings: Dictionary = SaveManager.get_settings()
		if settings.is_empty():
			return
		master_volume = settings.get("master_volume", master_volume)
		bgm_volume = settings.get("bgm_volume", bgm_volume)
		sfx_volume = settings.get("sfx_volume", sfx_volume)
		_update_volumes()

# ============================================================
# 内部辅助方法
# ============================================================

## 加载音频流（带缓存）
func _load_stream(path: String) -> AudioStream:
	if _sfx_cache.has(path):
		return _sfx_cache[path] as AudioStream

	var stream: AudioStream = load(path) as AudioStream
	if stream != null:
		_sfx_cache[path] = stream
	return stream


## 获取一个空闲的SFX播放器
func _get_available_sfx_player() -> AudioStreamPlayer2D:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null


## 获取最早开始播放的SFX播放器（用于强制回收）
func _get_oldest_playing_sfx_player() -> AudioStreamPlayer2D:
	var oldest: AudioStreamPlayer2D = null
	for player in _sfx_pool:
		if player.playing:
			if oldest == null:
				oldest = player
			else:
				# 比较播放进度（近似判断）
				if player.get_playback_position() > oldest.get_playback_position():
					oldest = player
	return oldest


## SFX播放完成的回调
func _on_sfx_finished(player: AudioStreamPlayer2D) -> void:
	# 播放完成后不做特殊处理，播放器自动回到空闲状态
	pass


## 当SaveManager加载存档数据后，同步音量设置
func _on_save_data_loaded() -> void:
	load_volume()


## 清理SFX缓存
func clear_cache() -> void:
	_sfx_cache.clear()
	print("AudioManager: SFX缓存已清理。")
