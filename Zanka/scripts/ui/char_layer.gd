extends Control
## 立绘层：站位（l/c/r）、淡入淡出、发言者高亮、呼吸起伏。

const CharDB := preload("res://scripts/core/char_db.gd")

const POS_X := {"l": 0.235, "c": 0.5, "r": 0.765, "left": 0.235, "center": 0.5, "right": 0.765}
const RISE_PX := 14.0             # 出场时从下方浮上来的距离
const RISE_SPEED := 82.0          # 归位速度（px/秒）——约 0.17 秒走完，别拖

var _sprites: Dictionary = {}     # sprite_id -> TextureRect
var _pos: Dictionary = {}         # sprite_id -> 站位键
var _bob: Dictionary = {}         # sprite_id -> 呼吸相位
var _rise: Dictionary = {}        # sprite_id -> 出场动画还差多少像素没归位
var _speaking: String = ""
var _cache: Dictionary = {}
var _missing: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_layout)

func _process(delta: float) -> void:
	for id in _sprites.keys():
		var tr: TextureRect = _sprites[id]
		if not is_instance_valid(tr):
			continue
		var ph: float = float(_bob.get(id, 0.0)) + delta * 1.5
		_bob[id] = ph
		var amp: float = 5.0 if id == _speaking else 2.2
		# 出场时额外叠加一个「上浮」偏移，随时间归零。
		# 必须并进呼吸位移一起算，否则会和这一行的 base_pos 打架。
		var rise: float = float(_rise.get(id, 0.0))
		if rise > 0.0:
			rise = maxf(0.0, rise - delta * RISE_SPEED)
			_rise[id] = rise
		var base: Vector2 = tr.get_meta("base_pos", tr.position)
		tr.position = base + Vector2(0.0, sin(ph) * amp + rise)

func _place(id: String) -> void:
	var tr: TextureRect = _sprites.get(id)
	if tr == null or not is_instance_valid(tr):
		return
	# 立绘是「腰部以上的半身像」，所以按屏高的 80% 摆放，
	# 底边压到屏幕外一点，露出部分正好落在对话框上方。
	var h: float = maxf(size.y, 360.0)
	var sprite_h: float = h * 0.80
	var sprite_w: float = sprite_h
	var key: String = str(_pos.get(id, "c"))
	var cx: float = size.x * float(POS_X.get(key, 0.5))
	tr.size = Vector2(sprite_w, sprite_h)
	var base := Vector2(cx - sprite_w * 0.5, h - sprite_h + h * 0.02)
	tr.set_meta("base_pos", base)
	tr.position = base

func _layout() -> void:
	for id in _sprites.keys():
		_place(id)

func _get_tex(sprite_id: String) -> Texture2D:
	if _cache.has(sprite_id):
		return _cache[sprite_id]
	if _missing.has(sprite_id):
		return null
	var path: String = CharDB.sprite_path(sprite_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		_missing[sprite_id] = true
		push_warning("缺少立绘资源：%s (%s)" % [sprite_id, path])
		return null
	var tex := load(path) as Texture2D
	_cache[sprite_id] = tex
	return tex

func show_char(sprite_id: String, pos: String = "c", fade: float = 0.4) -> void:
	var tex := _get_tex(sprite_id)
	if tex == null:
		return
	# 同一角色的旧表情要先撤掉：剧本用 @char shiori_normal 之后又 @char shiori_smile
	# 时，是两个不同的立绘 id，不主动收旧的就会两张叠在一起。
	var base: String = CharDB.base_id(sprite_id)
	for other in _sprites.keys():
		if other != sprite_id and CharDB.base_id(str(other)) == base:
			hide_char(str(other), fade)
	var tr: TextureRect = _sprites.get(sprite_id)
	if tr == null or not is_instance_valid(tr):
		tr = TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		_sprites[sprite_id] = tr
		_bob[sprite_id] = randf() * TAU
		tr.modulate.a = 0.0
		if fade > 0.02:
			_rise[sprite_id] = RISE_PX      # 只有真的在淡入时才播出场动画
	tr.texture = tex
	_pos[sprite_id] = pos
	_place(sprite_id)
	tr.modulate = Color(1, 1, 1, 1) if _speaking == sprite_id else Color(0.72, 0.74, 0.80, 1)
	if fade <= 0.02:
		tr.modulate.a = 1.0
		return
	var tw := create_tween()
	tw.tween_property(tr, "modulate:a", 1.0, fade)

func hide_char(sprite_id: String, fade: float = 0.4) -> void:
	if sprite_id == "all":
		hide_all(fade)
		return
	var tr: TextureRect = _sprites.get(sprite_id)
	if tr == null or not is_instance_valid(tr):
		return
	_sprites.erase(sprite_id)
	_pos.erase(sprite_id)
	_bob.erase(sprite_id)
	_rise.erase(sprite_id)
	if fade <= 0.02:
		tr.queue_free()
		return
	var tw := create_tween()
	tw.tween_property(tr, "modulate:a", 0.0, fade)
	tw.tween_callback(tr.queue_free)

func hide_all(fade: float = 0.4) -> void:
	for id in _sprites.keys():
		hide_char(id, fade)

## 高亮当前发言者（对应企划里的「发言者呼吸更明显」）
func set_speaking(speaker_id: String) -> void:
	var target: String = ""
	if not speaker_id.is_empty():
		if _sprites.has(speaker_id):
			target = speaker_id
		else:
			for id in _sprites.keys():
				if CharDB.base_id(id) == CharDB.base_id(speaker_id):
					target = id
					break
	if target == _speaking:
		return
	_speaking = target
	for id in _sprites.keys():
		var tr: TextureRect = _sprites[id]
		if not is_instance_valid(tr):
			continue
		var want := Color(1, 1, 1, tr.modulate.a) if id == target else Color(0.72, 0.74, 0.80, tr.modulate.a)
		var tw := create_tween()
		tw.tween_property(tr, "modulate", want, 0.22)

func has_char(sprite_id: String) -> bool:
	return _sprites.has(sprite_id)

func clear() -> void:
	for id in _sprites.keys():
		var tr: TextureRect = _sprites[id]
		if is_instance_valid(tr):
			tr.queue_free()
	_sprites.clear()
	_pos.clear()
	_bob.clear()
	_rise.clear()
	_speaking = ""
