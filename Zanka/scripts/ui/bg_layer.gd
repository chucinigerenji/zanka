extends Control
## 背景层：双层 TextureRect 交叉淡入 + 锐化/颗粒着色器 + 时段调色。

const UI := preload("res://scripts/core/ui_theme.gd")

const BG_DIR := "res://assets/bg/"
const SHADER_PATH := "res://shaders/bg_sharpen.gdshader"

var _front: TextureRect
var _back: TextureRect
var _tw: Tween
var _current: String = ""
var _cache: Dictionary = {}
var _shader: Shader = null
var _missing: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(SHADER_PATH):
		_shader = load(SHADER_PATH) as Shader
	_front = _mk()
	_back = _mk()
	add_child(_front)
	add_child(_back)
	_back.modulate.a = 0.0

func _mk() -> TextureRect:
	var t := TextureRect.new()
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader != null:
		var m := ShaderMaterial.new()
		m.shader = _shader
		m.set_shader_parameter("sharpness", 0.45)
		m.set_shader_parameter("grain", 0.028)
		t.material = m
	return t

func texture_for(id: String) -> Texture2D:
	if id.is_empty():
		return null
	if _cache.has(id):
		return _cache[id]
	if _missing.has(id):
		return null
	var path := BG_DIR + id + ".png"
	if not ResourceLoader.exists(path):
		_missing[id] = true
		push_warning("缺少背景资源：%s" % path)
		return null
	var tex := load(path) as Texture2D
	_cache[id] = tex
	return tex

func show_bg(id: String, fade: float = 0.6) -> void:
	if id == _current:
		return
	if id == "none" or id.is_empty():
		_current = "none"
		if _tw != null and _tw.is_valid():
			_tw.kill()
		var tw0 := create_tween()
		tw0.set_parallel(true)
		tw0.tween_property(_front, "modulate:a", 0.0, maxf(0.05, fade))
		tw0.tween_property(_back, "modulate:a", 0.0, maxf(0.05, fade))
		return
	var tex := texture_for(id)
	if tex == null:
		return
	if _front.texture == null:
		fade = 0.0
	_current = id
	if _tw != null and _tw.is_valid():
		_tw.kill()
	if fade <= 0.02:
		_front.texture = tex
		_front.modulate.a = 1.0
		_back.modulate.a = 0.0
		return
	_back.texture = tex
	_back.modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(_back, "modulate:a", 1.0, fade)
	_tw.tween_callback(func() -> void:
		_front.texture = tex
		_front.modulate.a = 1.0
		_back.modulate.a = 0.0)

## 时段调色（晨/昼/夕/夜），不换图也能改变氛围
func set_tint(c: Color, time: float = 1.2) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_front, "self_modulate", c, time)
	tw.tween_property(_back, "self_modulate", c, time)

func current_id() -> String:
	return _current

func clear() -> void:
	_current = ""
	_front.texture = null
	_back.texture = null
