extends RefCounted
## 统一视觉风格：字体、配色、样式盒、主题构建。所有 UI 都从这里取样式，保证一致性。

const SANS_PATH := "res://assets/ui/ZankaSans.otf"
const SERIF_PATH := "res://assets/ui/ZankaSerif.otf"

# 配色：低饱和、暖灰、洗褪色的夏天
const C_TEXT := Color(0.910, 0.898, 0.867)
const C_DIM := Color(0.635, 0.655, 0.690)
const C_ACCENT := Color(0.788, 0.541, 0.365)
const C_INK := Color(0.106, 0.110, 0.133)
const C_PAPER := Color(0.937, 0.914, 0.863)
const C_BOX := Color(0.043, 0.051, 0.071, 0.880)
const C_BOX_SOFT := Color(0.078, 0.086, 0.114, 0.900)
const C_LINE := Color(0.596, 0.624, 0.686, 0.400)
const C_LINE_SOFT := Color(0.596, 0.624, 0.686, 0.180)
const C_HILITE := Color(0.878, 0.639, 0.451)

static var _sans: Font = null
static var _serif: Font = null

static func sans() -> Font:
	if _sans == null and ResourceLoader.exists(SANS_PATH):
		_sans = load(SANS_PATH) as Font
	return _sans

static func serif() -> Font:
	if _serif == null and ResourceLoader.exists(SERIF_PATH):
		_serif = load(SERIF_PATH) as Font
	return _serif

static func flat(bg: Color, radius: int = 10, border: Color = Color(0, 0, 0, 0), bw: int = 0,
		pad_h: int = 16, pad_v: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.set_border_width_all(bw)
		s.border_color = border
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	return s

static func make_theme() -> Theme:
	var t := Theme.new()
	var f := sans()
	if f != null:
		t.default_font = f
	t.default_font_size = 24

	# ---- Button
	t.set_stylebox("normal", "Button", flat(Color(0.098, 0.106, 0.137, 0.860), 8, C_LINE_SOFT, 1, 18, 12))
	t.set_stylebox("hover", "Button", flat(Color(0.157, 0.161, 0.196, 0.940), 8, C_ACCENT, 1, 18, 12))
	t.set_stylebox("pressed", "Button", flat(Color(0.204, 0.149, 0.110, 0.960), 8, C_ACCENT, 2, 18, 12))
	t.set_stylebox("disabled", "Button", flat(Color(0.086, 0.090, 0.110, 0.600), 8, C_LINE_SOFT, 1, 18, 12))
	t.set_stylebox("focus", "Button", flat(Color(0, 0, 0, 0), 8, C_ACCENT, 1, 18, 12))
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 0.965, 0.925))
	t.set_color("font_pressed_color", "Button", C_HILITE)
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.46, 0.50))
	t.set_font_size("font_size", "Button", 23)

	# ---- Label
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.65))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 2)

	# ---- RichTextLabel
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_constant("line_separation", "RichTextLabel", 10)

	# ---- Panel / PanelContainer
	t.set_stylebox("panel", "Panel", flat(C_BOX, 12, C_LINE_SOFT, 1, 20, 16))
	t.set_stylebox("panel", "PanelContainer", flat(C_BOX, 12, C_LINE_SOFT, 1, 20, 16))

	# ---- ScrollContainer / 滚动条
	t.set_stylebox("panel", "ScrollContainer", flat(Color(0, 0, 0, 0), 0))
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = C_LINE
	grabber.set_corner_radius_all(6)
	grabber.content_margin_left = 6
	grabber.content_margin_right = 6
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.045)
	track.set_corner_radius_all(6)
	t.set_stylebox("scroll", "VScrollBar", track)

	# ---- HSlider
	t.set_stylebox("slider", "HSlider", flat(Color(0.10, 0.11, 0.14, 0.9), 5, C_LINE_SOFT, 1, 0, 6))
	t.set_stylebox("grabber_area", "HSlider", flat(C_ACCENT, 5, Color(0, 0, 0, 0), 0, 0, 6))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(C_HILITE, 5, Color(0, 0, 0, 0), 0, 0, 6))

	# ---- CheckButton / OptionButton 用默认即可，只调颜色
	t.set_color("font_color", "CheckButton", C_TEXT)
	t.set_color("font_color", "OptionButton", C_TEXT)
	t.set_color("font_color", "CheckBox", C_TEXT)

	return t

## 生成一个带描边的标题文本（用于章节标题、结局标题）
static func title_label(text: String, size: int = 56) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	var sf := serif()
	if sf != null:
		l.add_theme_font_override("font", sf)
	l.add_theme_color_override("font_color", C_PAPER)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func vspace(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
