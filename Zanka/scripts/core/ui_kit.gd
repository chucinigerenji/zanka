extends RefCounted
## UI 构建小工具，减少各面板里的重复样板。

const UI := preload("res://scripts/core/ui_theme.gd")

static func label(text: String, size: int = 24, color: Color = UI.C_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func button(text: String, size: int = 23, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	if min_w > 0.0:
		b.custom_minimum_size = Vector2(min_w, 46)
	else:
		b.custom_minimum_size = Vector2(0, 44)
	return b

static func panel(bg: Color = UI.C_BOX, radius: int = 12, border: Color = UI.C_LINE_SOFT, bw: int = 1,
		pad_h: int = 20, pad_v: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.flat(bg, radius, border, bw, pad_h, pad_v))
	return p

static func vbox(sep: int = 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func margin(l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	return m

static func spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func hspacer(w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c

static func center(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c

static func scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	return s

## 半透明黑幕，用于弹窗背景
static func dim(alpha: float = 0.72, block: bool = true) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.02, 0.024, 0.035, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP if block else Control.MOUSE_FILTER_IGNORE
	return r
