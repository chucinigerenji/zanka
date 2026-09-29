extends Control
## 存 / 读档面板。6 个手动档 + 1 个自动档。

signal loaded_game
signal closed

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")

var _shell
var _list: VBoxContainer
var mode: String = "load"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell = Shell.new()
	add_child(_shell)

	var scroll := Kit.scroll()
	scroll.custom_minimum_size = Vector2(900, 470)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.body.add_child(scroll)
	_list = Kit.vbox(10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var close := Kit.button("关闭", 21)
	close.pressed.connect(func() -> void: _shell.close())
	_shell.footer.add_child(close)
	_shell.close_requested.connect(func() -> void: closed.emit())

func open(m: String) -> void:
	mode = m
	_shell.set_title("保存进度" if m == "save" else "读取进度")
	_rebuild()
	_shell.open()

func is_open() -> bool:
	return _shell.visible

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	if mode == "load":
		_add_row(SaveManager.AUTO_SLOT, "自动存档")
	for i in range(SaveManager.SLOT_COUNT):
		_add_row(i, "存档位 %d" % (i + 1))

func _add_row(slot: int, name: String) -> void:
	var info: Dictionary = SaveManager.slot_info(slot)
	var has: bool = not info.is_empty()
	# 存档条目：和纸略深一档的底，像贴在纸页上的一行
	var row := Kit.panel(UI.C_PAPER_D, UI.R_PANEL, UI.C_LINE_SOFT, 1, 18, 12)
	_list.add_child(row)

	var h := Kit.hbox(16)
	row.add_child(h)

	var left := Kit.vbox(4)
	left.custom_minimum_size = Vector2(640, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)

	var title := name
	if has:
		var ch := str(info.get("chapter", ""))
		var dt := str(info.get("date", ""))
		if not ch.is_empty() or not dt.is_empty():
			title += "　—　" + ch + "　" + dt
	left.add_child(Kit.label(title, 21, UI.C_TEXT if has else UI.C_DIM))
	var sub := str(info.get("text", "")) if has else "（空）"
	left.add_child(Kit.label(sub, 18, UI.C_DIM))
	if has:
		left.add_child(Kit.label(str(info.get("time", "")), 15, UI.C_DIM))

	var btns := Kit.hbox(8)
	h.add_child(btns)

	if mode == "save":
		var sb := Kit.button("保存", 20, 96)
		sb.pressed.connect(func() -> void:
			SaveManager.save_slot(slot)
			AudioManager.play_se("select")
			_rebuild())
		btns.add_child(sb)
	else:
		var lb := Kit.button("读取", 20, 96)
		lb.disabled = not has
		lb.pressed.connect(func() -> void:
			if SaveManager.load_slot(slot):
				AudioManager.play_se("select")
				_shell.close()
				loaded_game.emit())
		btns.add_child(lb)

	if has and slot != SaveManager.AUTO_SLOT:
		var db := Kit.button("删除", 20, 96)
		db.pressed.connect(func() -> void:
			SaveManager.delete_slot(slot)
			_rebuild())
		btns.add_child(db)
