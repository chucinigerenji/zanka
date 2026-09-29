extends Control
## 汐浦港 潮汐表。
##
## 这是整个伏笔装置的载体：序章第一天玩家就能在菜单里翻到 9/19 那一行
## （朔望大潮 / 満潮 17:58 / +202cm），并读到页脚那行关于「涨潮提前」的小字。
## 终章那句台词回收的，就是这里。

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")

const DATA_PATH := "res://data/tides.json"

var _shell
var _grid: GridContainer
var _note: Label
var _data: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load()

	_shell = Shell.new()
	add_child(_shell)
	_shell.set_title("汐浦港　潮汐表")

	var scroll := Kit.scroll()
	scroll.custom_minimum_size = Vector2(860, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.body.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 6)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	_note = Kit.label("", 17, UI.C_DIM)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(840, 0)
	_shell.body.add_child(_note)

	var close := Kit.button("关闭", 21)
	close.pressed.connect(func() -> void: _shell.close())
	_shell.footer.add_child(close)

func _load() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		return
	var txt := FileAccess.get_file_as_string(DATA_PATH)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed

func open() -> void:
	_rebuild()
	_shell.open()

func close() -> void:
	_shell.close()

func is_open() -> bool:
	return _shell.visible

func _cell(text: String, size: int, color: Color, width: int = 0) -> Label:
	var l := Kit.label(text, size, color)
	if width > 0:
		l.custom_minimum_size = Vector2(width, 0)
	return l

func _rebuild() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var head := UI.C_DIM
	_grid.add_child(_cell("日期", 19, head, 90))
	_grid.add_child(_cell("潮汐", 19, head, 110))
	_grid.add_child(_cell("満潮／干潮", 19, head, 180))
	_grid.add_child(_cell("潮位", 19, head, 90))
	_grid.add_child(_cell("备考", 19, head, 250))

	var rows: Array = _data.get("rows", [])
	var today: String = GameState.date_text
	for r in rows:
		var d: Dictionary = r
		var date_s: String = str(d.get("date", ""))
		# 高亮「今天」；date_text 形如 "6/17" 或 "9/22·三浦家"
		var is_today: bool = (not today.is_empty()) and today.begins_with(date_s)
		var col: Color = UI.C_ACCENT if is_today else UI.C_TEXT
		var dim: Color = UI.C_ACCENT if is_today else UI.C_DIM
		var mark: String = "▶ " if is_today else ""
		_grid.add_child(_cell(mark + date_s, 20, col, 90))
		_grid.add_child(_cell(str(d.get("moon", "")), 20, col, 110))
		_grid.add_child(_cell(str(d.get("time", "")), 20, col, 180))
		_grid.add_child(_cell(str(d.get("level", "")), 20, dim, 90))
		_grid.add_child(_cell(str(d.get("note", "")), 20, dim, 250))

	_note.text = str(_data.get("note", ""))
