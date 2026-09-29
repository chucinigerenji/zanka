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

## 「列表式」按钮（磨砂方案）：平时只有文字，不加边框、不加分隔线；
## 悬停 / 键盘聚焦时浮出一块柔和圆角底，左缘一条朱色短棒；按下整块变朱底纸字。
## 用于标题菜单、选项支、弹窗列表——这些地方用实底方框会看着像输入框。
## 注意：朱色短棒是用 StyleBoxFlat 的 border_width_left 画的，
## 它会跟着圆角一起被裁剪，所以端头看起来是圆的。
static func row_button(text: String, size: int = 23, min_w: float = 0.0,
		align_left: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_ALL
	if align_left:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var idle := UI.flat(Color(0, 0, 0, 0), UI.R_BTN, Color(0, 0, 0, 0), 0, 22, 12)
	var sel := UI.flat(Color(1, 1, 1, 0.62), UI.R_BTN, UI.C_ACCENT, 0, 22, 12)
	sel.border_width_left = 4
	var press := UI.flat(UI.C_ACCENT, UI.R_BTN, UI.C_ACCENT, 0, 22, 12)
	press.border_width_left = 4
	b.add_theme_stylebox_override("normal", idle)
	b.add_theme_stylebox_override("hover", sel)
	b.add_theme_stylebox_override("focus", sel)
	b.add_theme_stylebox_override("pressed", press)
	b.add_theme_color_override("font_hover_color", UI.C_TEXT)
	b.add_theme_color_override("font_focus_color", UI.C_TEXT)
	b.add_theme_color_override("font_pressed_color", UI.C_PAPER)
	if min_w > 0.0:
		b.custom_minimum_size = Vector2(min_w, 52)
	else:
		b.custom_minimum_size = Vector2(0, 50)
	return b

## HUD 上的小按钮：纯文字；按下（自动/跳过开启）时是一块朱色圆角底。
static func text_button(text: String, size: int = 19, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(min_w, 38)
	var none := UI.flat(Color(0, 0, 0, 0), 8, Color(0, 0, 0, 0), 0, 12, 4)
	b.add_theme_stylebox_override("normal", none)
	b.add_theme_stylebox_override("hover", UI.flat(Color(1, 1, 1, 0.55), 8, Color(0, 0, 0, 0), 0, 12, 4))
	b.add_theme_stylebox_override("focus", none)
	b.add_theme_stylebox_override("pressed", UI.flat(UI.C_ACCENT, 8, Color(0, 0, 0, 0), 0, 12, 4))
	b.add_theme_color_override("font_hover_color", UI.C_TEXT)
	b.add_theme_color_override("font_pressed_color", UI.C_PAPER)
	return b

static func panel(bg: Color = UI.C_BOX, radius: int = UI.R_PANEL, border: Color = UI.C_LINE_SOFT,
		bw: int = 1, pad_h: int = 20, pad_v: int = 16) -> PanelContainer:
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

## 弹窗黑幕：暖调暗部（和纸方案不用冷蓝），alpha 可调
static func dim(alpha: float = 0.72, block: bool = true) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(UI.C_DIM_BG.r, UI.C_DIM_BG.g, UI.C_DIM_BG.b, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP if block else Control.MOUSE_FILTER_IGNORE
	return r
