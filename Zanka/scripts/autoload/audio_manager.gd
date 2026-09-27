extends Node
## 音频管理：BGM 交叉淡入、SE 池、环境音。音频文件由 tools/gen_audio.py 合成。
## 所有播放都做了「文件不存在就静默跳过」的处理，缺资源不会导致报错崩溃。

const BGM_DIR := "res://assets/audio/bgm_"
const SE_DIR := "res://assets/audio/se_"
const AMB_DIR := "res://assets/audio/amb_"
const EXT := ".wav"

var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _se_pool: Array[AudioStreamPlayer] = []
var _se_next: int = 0
var _current_bgm: String = ""
var _active_is_a: bool = true
var _missing: Dictionary = {}

func _ready() -> void:
	_bgm_a = _mk_player(-6.0)
	_bgm_b = _mk_player(-80.0)
	_amb = _mk_player(-10.0)
	for i in range(4):
		_se_pool.append(_mk_player(0.0))
	apply_volumes()

func _mk_player(vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = vol_db
	add_child(p)
	return p

func apply_volumes() -> void:
	var m: float = GameConfig.master_volume
	if _active_is_a:
		_bgm_a.volume_db = _db(GameConfig.bgm_volume * m)
		_bgm_b.volume_db = -80.0
	else:
		_bgm_b.volume_db = _db(GameConfig.bgm_volume * m)
		_bgm_a.volume_db = -80.0
	_amb.volume_db = _db(0.5 * m)
	if _current_bgm.is_empty():
		_bgm_a.volume_db = -80.0
		_bgm_b.volume_db = -80.0

func _db(linear: float) -> float:
	if linear <= 0.001:
		return -80.0
	return linear_to_db(clampf(linear, 0.0, 2.0))

func _load_stream(path: String) -> AudioStream:
	if _missing.has(path):
		return null
	if not ResourceLoader.exists(path):
		_missing[path] = true
		return null
	var s: Resource = load(path)
	if s == null:
		_missing[path] = true
		return null
	if s is AudioStreamWAV:
		var w: AudioStreamWAV = s
		var bytes_per_frame: int = 2 * (2 if w.stereo else 1)
		if w.format == AudioStreamWAV.FORMAT_16_BITS and w.data.size() > 0:
			var frames: int = w.data.size() / bytes_per_frame
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = frames
	return s

# ---------------------------------------------------------------- BGM

func play_bgm(id: String, fade: float = 1.2) -> void:
	if id.is_empty() or id == "none":
		stop_bgm(fade)
		return
	if id == _current_bgm and (_bgm_a.playing or _bgm_b.playing):
		return
	var stream := _load_stream(BGM_DIR + id + EXT)
	_current_bgm = id
	GameState.unlock_bgm(id)
	if stream == null:
		return
	var incoming: AudioStreamPlayer = _bgm_b if _active_is_a else _bgm_a
	var outgoing: AudioStreamPlayer = _bgm_a if _active_is_a else _bgm_b
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()
	_active_is_a = not _active_is_a
	var target := _db(GameConfig.bgm_volume * GameConfig.master_volume)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(incoming, "volume_db", target, maxf(0.05, fade))
	if outgoing.playing:
		tw.tween_property(outgoing, "volume_db", -80.0, maxf(0.05, fade))
	tw.chain().tween_callback(outgoing.stop)

func stop_bgm(fade: float = 1.0) -> void:
	_current_bgm = ""
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_bgm_a, "volume_db", -80.0, maxf(0.05, fade))
	tw.tween_property(_bgm_b, "volume_db", -80.0, maxf(0.05, fade))
	tw.chain().tween_callback(func() -> void:
		_bgm_a.stop()
		_bgm_b.stop())

func current_bgm() -> String:
	return _current_bgm

# ---------------------------------------------------------------- 环境音

func play_amb(id: String, fade: float = 1.5) -> void:
	if id.is_empty() or id == "none":
		stop_amb(fade)
		return
	var stream := _load_stream(AMB_DIR + id + EXT)
	if stream == null:
		return
	if _amb.stream == stream and _amb.playing:
		return
	_amb.stream = stream
	_amb.volume_db = -80.0
	_amb.play()
	var target := _db(0.5 * GameConfig.master_volume)
	var tw := create_tween()
	tw.tween_property(_amb, "volume_db", target, maxf(0.05, fade))

func stop_amb(fade: float = 1.2) -> void:
	var tw := create_tween()
	tw.tween_property(_amb, "volume_db", -80.0, maxf(0.05, fade))
	tw.chain().tween_callback(_amb.stop)

# ---------------------------------------------------------------- SE

func play_se(id: String) -> void:
	var stream := _load_stream(SE_DIR + id + EXT)
	if stream == null:
		return
	var p: AudioStreamPlayer = _se_pool[_se_next]
	_se_next = (_se_next + 1) % _se_pool.size()
	p.stream = stream
	p.volume_db = _db(GameConfig.se_volume * GameConfig.master_volume)
	p.play()

func stop_all() -> void:
	_bgm_a.stop()
	_bgm_b.stop()
	_amb.stop()
	for p in _se_pool:
		p.stop()
	_current_bgm = ""
