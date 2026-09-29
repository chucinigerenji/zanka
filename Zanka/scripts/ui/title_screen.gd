extends Control
## 标题画面。

signal request(name: String)

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const GalleryPanel := preload("res://scripts/ui/gallery_panel.gd")

const TITLE_BG := "res://assets/bg/bg_title.png"
const TOTAL_ENDINGS := 5

var _bg: TextureRect
var settings
var gallery
var _endings_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bg = TextureRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(TITLE_BG):
		_bg.texture = load(TITLE_BG)
	add_child(_bg)
	_bg.resized.connect(_on_bg_resized)

	# 和纸方案：把标题图压成浅淡底纹，墨字才压得住（原来是冷蓝黑幕）
	var grad := ColorRect.new()
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.color = Color(UI.C_PAPER.r, UI.C_PAPER.g, UI.C_PAPER.b, 0.62)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grad)

	# 占满整屏高度 + 垂直居中：手机分辨率各式各样，写死上下偏移会把按钮挤出屏幕
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 90
	left.offset_right = 660
	left.offset_top = 24
	left.offset_bottom = -24
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(left)

	var t1 := UI.title_label("残 夏", 80)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(t1)
	var t2 := Kit.label("The Last Tide", 24, UI.C_ACCENT)
	left.add_child(t2)
	left.add_child(Kit.spacer(6))
	var t3 := Kit.label("汐浦町，最后一个夏天。", 22, UI.C_TEXT)
	left.add_child(t3)
	left.add_child(Kit.spacer(18))

	var items := [
		["new", "开始新的一周目"],
		["continue", "继续游戏"],
		["load", "读取进度"],
		["gallery", "鉴赏与信件"],
		["settings", "游戏设置"],
		["quit", "退出"],
	]
	for it in items:
		# 目录式菜单行：无框、左对齐、底部分隔线，悬停出朱色标记
		var b := Kit.row_button(str(it[1]), 22, 420)
		b.custom_minimum_size = Vector2(420, 46)
		b.pressed.connect(func() -> void:
			AudioManager.play_se("select")
			request.emit(str(it[0])))
		left.add_child(b)

	_endings_label = Kit.label("", 18, UI.C_DIM)
	_endings_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_endings_label.offset_left = 96
	_endings_label.offset_top = -66
	_endings_label.offset_right = 700
	_endings_label.offset_bottom = -38
	add_child(_endings_label)

	settings = SettingsPanel.new()
	add_child(settings)
	gallery = GalleryPanel.new()
	add_child(gallery)

func _on_bg_resized() -> void:
	_bg.pivot_offset = _bg.size * 0.5

func refresh() -> void:
	var n: int = GameState.endings_seen.size()
	var pt: int = GameState.playthrough
	_endings_label.text = "已解锁结局 %d / %d　　第 %d 周目" % [n, TOTAL_ENDINGS, pt]

func open() -> void:
	visible = true
	refresh()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.45)
	# 缓慢推近
	if _bg.texture != null:
		_bg.pivot_offset = _bg.size * 0.5
		_bg.scale = Vector2(1.02, 1.02)
		var kt := create_tween().set_loops()
		kt.tween_property(_bg, "scale", Vector2(1.08, 1.08), 26.0).set_trans(Tween.TRANS_SINE)
		kt.tween_property(_bg, "scale", Vector2(1.02, 1.02), 26.0).set_trans(Tween.TRANS_SINE)

func close() -> void:
	visible = false

func any_overlay_open() -> bool:
	return settings.is_open() or gallery.is_open()
