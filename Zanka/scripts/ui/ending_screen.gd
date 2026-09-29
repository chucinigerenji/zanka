extends Control
## 结局画面：结局名 / 结语 / 玩家写下的信（遗书拼合）/ 已解锁结局一览。

signal request(name: String)

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")

const ENDINGS_PATH := "res://data/endings.json"
const LETTERS_PATH := "res://data/systems.json"

var _bg: TextureRect
var _dim: ColorRect
var _root: VBoxContainer
var _scroll: ScrollContainer
var _endings_data: Dictionary = {}
var _letters_data: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bg = TextureRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# 结局做成「印在和纸上的信」：把背景洗成浅淡底纹，墨字压在上面
	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(UI.C_PAPER.r, UI.C_PAPER.g, UI.C_PAPER.b, 0.82)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_scroll = Kit.scroll()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_left = 90
	_scroll.offset_right = -90
	_scroll.offset_top = 50
	_scroll.offset_bottom = -30
	add_child(_scroll)

	_root = Kit.vbox(16)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_root)

	_load_data()

func _load_data() -> void:
	_endings_data = _read_json(ENDINGS_PATH)
	_letters_data = _read_json(LETTERS_PATH)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func show_ending(id: String) -> void:
	visible = true
	for c in _root.get_children():
		_root.remove_child(c)
		c.queue_free()

	var d: Dictionary = _endings_data.get(id, {})
	var title: String = str(d.get("title", "结局"))
	var subtitle: String = str(d.get("subtitle", ""))
	var body: String = str(d.get("text", ""))
	var bg_id: String = str(d.get("bg", "bg_seawall_night"))

	var bp := "res://assets/bg/" + bg_id + ".png"
	if ResourceLoader.exists(bp):
		_bg.texture = load(bp)

	var t := UI.title_label(title, 62)
	_root.add_child(t)
	if not subtitle.is_empty():
		var s := Kit.label(subtitle, 24, UI.C_ACCENT)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_root.add_child(s)

	_root.add_child(Kit.spacer(10))
	if not body.is_empty():
		var bl := Kit.label(body, 23, UI.C_TEXT)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.custom_minimum_size = Vector2(1020, 0)
		_root.add_child(bl)

	_root.add_child(Kit.spacer(18))
	_add_letter_section()

	_root.add_child(Kit.spacer(14))
	var stats := Kit.label(
		"回忆点 %d　　照护评分 %d　　记忆碎片 %d　　周目 %d" % [
			GameState.memory, GameState.care_score, GameState.fragments.size(), GameState.playthrough],
		19, UI.C_DIM)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(stats)

	_root.add_child(Kit.spacer(10))
	var row := Kit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var b1 := Kit.button("回到标题画面", 23, 260)
	b1.pressed.connect(func() -> void: request.emit("title"))
	row.add_child(b1)
	var b2 := Kit.button("读取进度", 23, 220)
	b2.pressed.connect(func() -> void: request.emit("load"))
	row.add_child(b2)
	_root.add_child(row)

	_root.add_child(Kit.spacer(30))

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.2)

func _add_letter_section() -> void:
	var head := Kit.label("—— 她留下的信（由你写下的字句拼成）——", 21, UI.C_HILITE)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(head)

	var letters: Dictionary = _letters_data.get("letters", {})
	var lines: Array[String] = []
	for chapter in letters.keys():
		var item: Dictionary = letters[chapter]
		for o in item.get("options", []):
			if GameState.letters.has(str(o.get("id", ""))):
				lines.append(str(o.get("text", "")))
	if lines.is_empty():
		lines.append("（你什么都没有写。）")
	# 信纸：比底色略深一档的和纸 + 淡墨描边，像一张夹在里面的纸
	var box := Kit.panel(UI.C_PAPER_D, UI.R_PANEL, UI.C_LINE_SOFT, 1, 28, 22)
	UI.apply_paper(box)
	var v := Kit.vbox(10)
	box.add_child(v)
	for l in lines:
		var ll := Kit.label(l, 22, UI.C_TEXT)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size = Vector2(960, 0)
		v.add_child(ll)
	if GameState.care_score >= 9:
		v.add_child(Kit.label("（你终于学会了申请介护保险。她替你写的那本手册，第一页派上了用场。）", 20, UI.C_DIM))
	_root.add_child(box)

func close() -> void:
	visible = false
