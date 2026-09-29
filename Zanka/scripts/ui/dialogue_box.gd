extends Control
## 对话框：名牌 + 打字机文本 + 续行指示。旁白时隐藏名牌。

signal line_finished

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")

const BASE_FONT := 27
const BASE_CPS := 30.0      # 每秒字数（text_speed = 1.0 时）

var _box: Panel
var _name_panel: PanelContainer
var _name_label: Label
var _name_style: StyleBoxFlat
var _text: RichTextLabel
var _indicator: Label

var _total: int = 0
var _shown: float = 0.0
var _typing: bool = false
var _indicator_tw: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 40
	offset_right = -40
	offset_top = -208
	offset_bottom = -36

	_box = Panel.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 磨砂对话条：暖白半透明 + 大圆角 + 1px 亮边，顶边一条朱色「包边」
	var sb := UI.flat(UI.C_DBOX, UI.R_BOX, UI.C_LINE, 1, 0, 0)
	sb.border_width_top = 2
	sb.border_color = UI.C_ACCENT
	_box.add_theme_stylebox_override("panel", sb)
	UI.apply_paper(_box)          # 纸纹（拿不到着色器就自动跳过）
	add_child(_box)

	var m := Kit.margin(36, 30, 36, 26)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.scroll_active = false
	_text.fit_content = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", BASE_FONT)
	_text.add_theme_color_override("default_color", UI.C_TEXT)
	_text.add_theme_constant_override("line_separation", 12)
	m.add_child(_text)

	_name_panel = PanelContainer.new()
	_name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_panel.position = Vector2(12, -46)
	# 名牌：墨色半透明底 + 圆角，骑在对话条上沿；名字用角色配色（浅色，压墨底刚好）
	_name_style = UI.flat(Color(UI.C_INK.r, UI.C_INK.g, UI.C_INK.b, 0.82), 10,
		Color(1, 1, 1, 0.35), 1, 22, 7)
	_name_panel.add_theme_stylebox_override("panel", _name_style)
	add_child(_name_panel)

	_name_label = Kit.label("", 24, UI.C_TEXT)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_panel.add_child(_name_label)

	_indicator = Kit.label("▼", 20, UI.C_HILITE)
	_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_indicator.offset_left = -52
	_indicator.offset_top = -44
	_indicator.offset_right = -18
	_indicator.offset_bottom = -14
	_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_indicator.visible = false
	add_child(_indicator)

func _apply_font_scale() -> void:
	var sz := int(round(BASE_FONT * clampf(GameConfig.font_scale, 0.8, 1.6)))
	_text.add_theme_font_size_override("normal_font_size", sz)
	_name_label.add_theme_font_size_override("font_size", int(round(24 * clampf(GameConfig.font_scale, 0.8, 1.6))))

func show_line(speaker_name: String, name_color: Color, text: String) -> void:
	_apply_font_scale()
	_text.text = text
	_total = _text.get_total_character_count()
	_shown = 0.0
	_text.visible_characters = 0
	_typing = _total > 0
	_indicator.visible = false
	if _indicator_tw != null and _indicator_tw.is_valid():
		_indicator_tw.kill()

	if speaker_name.is_empty():
		_name_panel.visible = false
	else:
		_name_panel.visible = true
		_name_label.text = speaker_name
		_name_label.add_theme_color_override("font_color", name_color)
		_name_style.border_color = name_color
		_name_panel.reset_size()
		_name_panel.position = Vector2(12, -46)

	if not _typing:
		_finish()

func is_typing() -> bool:
	return _typing

func skip_typing() -> void:
	if not _typing:
		return
	_typing = false
	_text.visible_characters = -1
	_finish()

func _finish() -> void:
	_text.visible_characters = -1
	_indicator.visible = true
	_indicator.modulate.a = 1.0
	if _indicator_tw != null and _indicator_tw.is_valid():
		_indicator_tw.kill()
	_indicator_tw = create_tween().set_loops()
	_indicator_tw.tween_property(_indicator, "modulate:a", 0.25, 0.7)
	_indicator_tw.tween_property(_indicator, "modulate:a", 1.0, 0.7)
	line_finished.emit()

func _process(delta: float) -> void:
	if not _typing:
		return
	var cps: float = BASE_CPS * clampf(GameConfig.text_speed, 0.25, 6.0)
	_shown += delta * cps
	var n := int(_shown)
	if n >= _total:
		_typing = false
		_finish()
		return
	_text.visible_characters = n

func set_box_visible(v: bool, fade: float = 0.25) -> void:
	var target: float = 1.0 if v else 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", target, fade)

func full_text() -> String:
	return _text.text
