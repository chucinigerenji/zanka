extends Control
## 鉴赏：CG 一览 + 信件抽屉。

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")

const CG_DIR := "res://assets/cg/"
const LETTERS_DATA := "res://data/systems.json"

const CGS := [
	{"id": "cg_umbrella_rain", "name": "雨中的伞"},
	{"id": "cg_piano", "name": "走音的钢琴"},
	{"id": "cg_festival_fireworks", "name": "潮祭的烟火"},
	{"id": "cg_envelopes", "name": "玄关的信封"},
	{"id": "cg_moon_sea", "name": "满月与沉船"},
]

var _shell
var _viewer: Control
var _viewer_tex: TextureRect
var _letters_data: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell = Shell.new()
	add_child(_shell)
	_shell.set_title("鉴赏")

	_load_letters()

	var scroll := Kit.scroll()
	scroll.custom_minimum_size = Vector2(900, 470)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.body.add_child(scroll)
	var v := Kit.vbox(18)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	v.add_child(Kit.label("事件 CG", 24, UI.C_HILITE))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)
	for cg in CGS:
		grid.add_child(_make_cg_cell(str(cg["id"]), str(cg["name"])))

	v.add_child(Kit.spacer(8))
	v.add_child(Kit.label("信件抽屉", 24, UI.C_HILITE))
	v.add_child(Kit.label("这些信一封都没有寄出去。", 19, UI.C_DIM))
	_letters_box = Kit.vbox(8)
	v.add_child(_letters_box)

	var close := Kit.button("关闭", 21)
	close.pressed.connect(func() -> void: _shell.close())
	_shell.footer.add_child(close)

	_build_viewer()

var _letters_box: VBoxContainer

func _load_letters() -> void:
	if not FileAccess.file_exists(LETTERS_DATA):
		return
	var f := FileAccess.open(LETTERS_DATA, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		_letters_data = parsed

func _make_cg_cell(id: String, name: String) -> Control:
	var unlocked: bool = GameState.cgs_seen.has(id)
	var cell := Kit.panel(Color(0.063, 0.071, 0.094, 0.9), 10, UI.C_LINE_SOFT, 1, 8, 8)
	cell.custom_minimum_size = Vector2(276, 196)
	var v := Kit.vbox(6)
	cell.add_child(v)

	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(260, 150)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.clip_contents = true
	if unlocked and ResourceLoader.exists(CG_DIR + id + ".png"):
		tex_rect.texture = load(CG_DIR + id + ".png")
		tex_rect.modulate = Color(1, 1, 1, 1)
	else:
		tex_rect.modulate = Color(0.25, 0.26, 0.30, 1)
	v.add_child(tex_rect)

	var lbl := Kit.label(name if unlocked else "？？？", 19, UI.C_TEXT if unlocked else UI.C_DIM)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl)

	if unlocked:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.pressed.connect(func() -> void: _show_cg(id))
		cell.add_child(b)
	return cell

func _build_viewer() -> void:
	_viewer = Control.new()
	_viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewer.visible = false
	_viewer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_viewer)
	_viewer.add_child(Kit.dim(0.92))
	_viewer_tex = TextureRect.new()
	_viewer_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewer_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewer_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_viewer_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(_viewer_tex)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(func() -> void: _viewer.visible = false)
	_viewer.add_child(b)

func _show_cg(id: String) -> void:
	var p := CG_DIR + id + ".png"
	if not ResourceLoader.exists(p):
		return
	_viewer_tex.texture = load(p)
	_viewer.visible = true
	AudioManager.play_se("select")

func open() -> void:
	_rebuild_letters()
	_shell.open()

func is_open() -> bool:
	return _shell.visible

func _rebuild_letters() -> void:
	for c in _letters_box.get_children():
		_letters_box.remove_child(c)
		c.queue_free()
	if GameState.letters.is_empty():
		_letters_box.add_child(Kit.label("（还没有写下任何东西）", 19, UI.C_DIM))
		return
	var letters: Dictionary = _letters_data.get("letters", {})
	var shown := 0
	for chapter in letters.keys():
		var item: Dictionary = letters[chapter]
		for o in item.get("options", []):
			var oid := str(o.get("id", ""))
			if GameState.letters.has(oid):
				shown += 1
				_letters_box.add_child(Kit.label(str(o.get("text", "")), 20, UI.C_TEXT))
	if shown == 0:
		_letters_box.add_child(Kit.label("（还没有写下任何东西）", 19, UI.C_DIM))
