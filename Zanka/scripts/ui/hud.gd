extends Control
## 常驻 HUD：左上角章节/日期/潮汐，右上角快捷按钮。

signal action(name: String)

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")

var _chapter: Label
var _cal: Label
var _btn_auto: Button
var _btn_skip: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ---- 左上：章节 + 日历/潮汐
	var left := Kit.panel(Color(0.031, 0.039, 0.055, 0.66), 10, UI.C_LINE_SOFT, 1, 18, 10)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.position = Vector2(28, 22)
	add_child(left)
	var lv := Kit.vbox(4)
	left.add_child(lv)
	_chapter = Kit.label("", 21, UI.C_PAPER)
	lv.add_child(_chapter)
	_cal = Kit.label("", 18, UI.C_DIM)
	lv.add_child(_cal)
	# 整块日期区可点：这是潮汐表的入口
	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(func() -> void: action.emit("tide"))
	left.add_child(hit)

	# ---- 右上：快捷按钮
	var row := Kit.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	row.offset_left = -560
	row.offset_top = 22
	row.offset_right = -28
	row.offset_bottom = 70
	row.alignment = BoxContainer.ALIGNMENT_END
	add_child(row)

	row.add_child(_mk("回想", "backlog"))
	_btn_auto = _mk("自动", "auto", true)
	row.add_child(_btn_auto)
	_btn_skip = _mk("跳过", "skip", true)
	row.add_child(_btn_skip)
	row.add_child(_mk("存档", "save"))
	row.add_child(_mk("菜单", "menu"))

func _mk(text: String, act: String, toggle: bool = false) -> Button:
	var b := Kit.button(text, 19)
	b.custom_minimum_size = Vector2(76, 42)
	b.toggle_mode = toggle
	b.pressed.connect(func() -> void: action.emit(act))
	return b

func set_chapter(t: String) -> void:
	_chapter.text = t if not t.is_empty() else "《残夏》"
	_chapter.visible = not t.is_empty()

func set_calendar(date_text: String, tide_text: String, period_text: String) -> void:
	var parts: Array[String] = []
	if not date_text.is_empty():
		parts.append(date_text)
	if not period_text.is_empty():
		parts.append(period_text)
	if not tide_text.is_empty() and tide_text != "-":
		parts.append("潮 " + tide_text)
	_cal.text = "　".join(parts)
	_cal.visible = not parts.is_empty()

func set_toggle(name: String, on: bool) -> void:
	if name == "auto":
		_btn_auto.set_pressed_no_signal(on)
	elif name == "skip":
		_btn_skip.set_pressed_no_signal(on)

func set_hud_visible(v: bool) -> void:
	visible = v
