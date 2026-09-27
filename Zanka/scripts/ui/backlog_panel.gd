extends Control
## 回想（Backlog）：显示已读台词历史，可滚动。

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")

var _shell
var _scroll: ScrollContainer
var _list: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell = Shell.new()
	add_child(_shell)
	_shell.set_title("回想")

	_scroll = Kit.scroll()
	_scroll.custom_minimum_size = Vector2(880, 470)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.body.add_child(_scroll)

	_list = Kit.vbox(14)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)

	var clr := Kit.button("清空显示", 19)
	clr.pressed.connect(func() -> void:
		for c in _list.get_children():
			c.queue_free())
	_shell.footer.add_child(clr)
	var close := Kit.button("关闭", 20)
	close.pressed.connect(close_panel)
	_shell.footer.add_child(close)

func open() -> void:
	_rebuild()
	_shell.open()
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)

func close_panel() -> void:
	_shell.close()

func is_open() -> bool:
	return _shell.visible

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var hist: Array = StoryEngine.history
	if hist.is_empty():
		_list.add_child(Kit.label("（还没有任何记录）", 22, UI.C_DIM))
		return
	for h in hist:
		var d: Dictionary = h
		var row := Kit.hbox(14)
		var nm := str(d.get("speaker", ""))
		if not nm.is_empty():
			var nl := Kit.label(nm, 21, UI.C_HILITE)
			nl.custom_minimum_size = Vector2(150, 0)
			nl.autowrap_mode = TextServer.AUTOWRAP_OFF
			row.add_child(nl)
		else:
			row.add_child(Kit.hspacer(150))
		var tl := Kit.label(str(d.get("text", "")), 21, UI.C_TEXT)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.custom_minimum_size = Vector2(680, 0)
		row.add_child(tl)
		_list.add_child(row)

func close() -> void:
	_shell.close()
