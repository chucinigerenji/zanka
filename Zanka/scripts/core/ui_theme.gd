extends RefCounted
## 统一视觉风格：字体、配色、样式盒、主题构建。所有 UI 都从这里取样式，保证一致性。
##
## 设计方向（v3「磨砂玻璃」）：
##   在企划 05 的美术基调（「低饱和、暖灰、洗褪色」「纸质质感、褪色商店街配色」）
##   之上，做成 **半透明磨砂玻璃 + 墨字 + 朱色点缀**：
##     * 面板 = 暖白半透明（0.80~0.86），**圆角大**（18~22px），
##       边缘是 1px **亮边**（白高光）而不是深色描边——这是"玻璃感"的来源
##     * 文字 = 暖墨色（不是纯黑），压在磨砂底上依然清晰
##     * 强调 = 朱色，全界面只有这一处彩色（顶边包边、当前项左标记）
##     * 按钮 = 平时只有文字；悬停/选中时浮出一块柔和圆角底 + 朱色短棒
##     * 面板内**不画任何分隔线**，靠间距分组（简洁）
##   配色与几何集中在这里与 ui_kit.gd，改这两处即可全局生效。

const SANS_PATH := "res://assets/ui/ZankaSans.otf"
const SERIF_PATH := "res://assets/ui/ZankaSerif.otf"
const PAPER_SHADER := "res://shaders/paper.gdshader"

# ---- 文字 ----
const C_TEXT := Color(0.145, 0.129, 0.118)        # 墨
const C_DIM := Color(0.420, 0.390, 0.360)         # 淡墨
const C_ACCENT := Color(0.643, 0.208, 0.145)      # 朱
const C_HILITE := Color(0.643, 0.208, 0.145)      # 朱（强调）

# ---- 磨砂底 ----
const C_PAPER := Color(0.985, 0.976, 0.957)       # 纸白（用于文字 / 高光）
const C_PAPER_D := Color(0.965, 0.953, 0.930)     # 暗一档（分区 / 列表项底）
const C_INK := Color(0.145, 0.129, 0.118)         # 浓墨（名牌底）
const C_BOX := Color(0.985, 0.976, 0.957, 0.840)  # 弹窗面板底（半透明）
const C_BOX_SOFT := Color(0.965, 0.953, 0.930, 0.860)
const C_DBOX := Color(0.985, 0.976, 0.957, 0.800) # 对话框底（透出背景）
const C_HUD := Color(0.985, 0.976, 0.957, 0.620)  # HUD 小牌（更透）

# ---- 边缘与遮罩 ----
# 玻璃感的关键：描边是**亮边（白高光）**，不是深色线
const C_LINE := Color(1.0, 1.0, 1.0, 0.550)
const C_LINE_SOFT := Color(1.0, 1.0, 1.0, 0.280)
const C_DIM_BG := Color(0.130, 0.115, 0.100, 0.500)   # 黑幕更淡，透出背景

# 圆角：磨砂玻璃要圆润
const R_BOX := 18
const R_PANEL := 22
const R_BTN := 12

static var _sans: Font = null
static var _serif: Font = null
static var _paper_mat: ShaderMaterial = null
static var _paper_checked: bool = false

static func sans() -> Font:
	if _sans == null and ResourceLoader.exists(SANS_PATH):
		_sans = load(SANS_PATH) as Font
	return _sans

static func serif() -> Font:
	if _serif == null and ResourceLoader.exists(SERIF_PATH):
		_serif = load(SERIF_PATH) as Font
	return _serif

## 和纸颗粒材质：只对 RGB 做极轻微扰动，**不动 alpha**，
## 所以着色器缺失或加载失败都不会有副作用（只是少了纸纹）。
static func paper_mat() -> ShaderMaterial:
	if not _paper_checked:
		_paper_checked = true
		if ResourceLoader.exists(PAPER_SHADER):
			var sh := load(PAPER_SHADER) as Shader
			if sh != null:
				_paper_mat = ShaderMaterial.new()
				_paper_mat.shader = sh
	return _paper_mat

## 给 Control 铺上和纸材质（拿不到着色器就静默跳过）。
static func apply_paper(c: Control) -> void:
	var m := paper_mat()
	if m != null:
		c.material = m

static func flat(bg: Color, radius: int = R_BOX, border: Color = Color(0, 0, 0, 0), bw: int = 0,
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

## 「目录式」按钮样式：无实底无圆角，只有一条底分隔线；
## 需要时可在左侧加一条朱色竖标记。
static func row(border: Color, bottom: int = 1, bg: Color = Color(0, 0, 0, 0),
		left: int = 0, left_color: Color = Color(0, 0, 0, 0),
		pad_h: int = 22, pad_v: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(0)
	s.border_width_bottom = bottom
	s.border_color = border
	if left > 0:
		s.border_width_left = left
		s.border_color = left_color
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

	# ---- Button：平时近乎透明；悬停浮出柔和圆底 + 亮边；按下朱底纸字 ----
	t.set_stylebox("normal", "Button", flat(Color(1, 1, 1, 0.10), R_BTN, C_LINE_SOFT, 1, 18, 12))
	t.set_stylebox("hover", "Button", flat(Color(1, 1, 1, 0.62), R_BTN, C_LINE, 1, 18, 12))
	t.set_stylebox("pressed", "Button", flat(C_ACCENT, R_BTN, C_ACCENT, 1, 18, 12))
	t.set_stylebox("disabled", "Button", flat(Color(1, 1, 1, 0.05), R_BTN, C_LINE_SOFT, 1, 18, 12))
	t.set_stylebox("focus", "Button", flat(Color(1, 1, 1, 0.62), R_BTN, C_LINE, 1, 18, 12))
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_TEXT)
	t.set_color("font_pressed_color", "Button", C_PAPER)
	t.set_color("font_disabled_color", "Button", Color(0.60, 0.57, 0.53))
	t.set_font_size("font_size", "Button", 23)

	# ---- Label：纸面上的字不需要重投影 ----
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_shadow_color", "Label", Color(1, 1, 1, 0.35))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 1)

	# ---- RichTextLabel ----
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_constant("line_separation", "RichTextLabel", 13)

	# ---- Panel / PanelContainer ----
	t.set_stylebox("panel", "Panel", flat(C_BOX, R_PANEL, C_LINE_SOFT, 1, 20, 16))
	t.set_stylebox("panel", "PanelContainer", flat(C_BOX, R_PANEL, C_LINE_SOFT, 1, 20, 16))

	# ---- ScrollContainer / 滚动条 ----
	t.set_stylebox("panel", "ScrollContainer", flat(Color(0, 0, 0, 0), 0))
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = C_LINE
	grabber.set_corner_radius_all(3)
	grabber.content_margin_left = 6
	grabber.content_margin_right = 6
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.145, 0.129, 0.118, 0.100)
	track.set_corner_radius_all(3)
	t.set_stylebox("scroll", "VScrollBar", track)

	# ---- HSlider ----
	t.set_stylebox("slider", "HSlider", flat(Color(0.145, 0.129, 0.118, 0.12), 3, C_LINE_SOFT, 1, 0, 6))
	t.set_stylebox("grabber_area", "HSlider", flat(C_ACCENT, 3, Color(0, 0, 0, 0), 0, 0, 6))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(C_ACCENT, 3, Color(0, 0, 0, 0), 0, 0, 6))

	# ---- CheckButton / OptionButton ----
	t.set_color("font_color", "CheckButton", C_TEXT)
	t.set_color("font_color", "OptionButton", C_TEXT)
	t.set_color("font_color", "CheckBox", C_TEXT)

	return t

## 标题文本：衬线体 + 墨色。和纸方案不放重描边，改用极轻的纸白描边提亮。
static func title_label(text: String, size: int = 56) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	var sf := serif()
	if sf != null:
		l.add_theme_font_override("font", sf)
	l.add_theme_color_override("font_color", C_TEXT)
	l.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func vspace(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
