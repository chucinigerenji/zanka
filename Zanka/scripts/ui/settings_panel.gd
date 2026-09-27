extends Control
## 游戏设置面板。

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")

var _shell
var _sliders: Dictionary = {}
var _checks: Dictionary = {}
var _effect_opt: OptionButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell = Shell.new()
	add_child(_shell)
	_shell.set_title("游戏设置")

	var scroll := Kit.scroll()
	scroll.custom_minimum_size = Vector2(880, 430)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.body.add_child(scroll)

	var v := Kit.vbox(16)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	v.add_child(Kit.label("文字与演出", 24, UI.C_HILITE))
	_add_slider(v, "文字速度", "text_speed", 0.4, 4.0, 0.1)
	_add_slider(v, "自动播放间隔", "auto_interval", 0.6, 5.0, 0.1)
	_add_slider(v, "字号缩放", "font_scale", 0.8, 1.6, 0.05)

	var eff_row := Kit.hbox(16)
	var el := Kit.label("病征演出强度", 22)
	el.custom_minimum_size = Vector2(220, 0)
	eff_row.add_child(el)
	_effect_opt = OptionButton.new()
	_effect_opt.add_item("关（关闭抖动/耳鸣）", 0)
	_effect_opt.add_item("弱", 1)
	_effect_opt.add_item("全（推荐）", 2)
	_effect_opt.selected = clampi(GameConfig.effect_level, 0, 2)
	_effect_opt.custom_minimum_size = Vector2(360, 44)
	_effect_opt.item_selected.connect(func(i: int) -> void:
		GameConfig.effect_level = i
		GameConfig.save_settings())
	eff_row.add_child(_effect_opt)
	v.add_child(eff_row)

	v.add_child(Kit.spacer(8))
	v.add_child(Kit.label("音量", 24, UI.C_HILITE))
	_add_slider(v, "总音量", "master_volume", 0.0, 1.0, 0.05)
	_add_slider(v, "背景音乐", "bgm_volume", 0.0, 1.0, 0.05)
	_add_slider(v, "音效", "se_volume", 0.0, 1.0, 0.05)

	v.add_child(Kit.spacer(8))
	v.add_child(Kit.label("其它", 24, UI.C_HILITE))
	_add_check(v, "全屏显示", "fullscreen")
	_add_check(v, "跳过时忽略未读文本", "skip_unread")

	var reset := Kit.button("恢复默认", 20)
	reset.pressed.connect(_on_reset)
	_shell.footer.add_child(reset)
	var close := Kit.button("完成", 21)
	close.pressed.connect(_on_close)
	_shell.footer.add_child(close)

func _add_slider(parent: Node, text: String, key: String, mn: float, mx: float, st: float) -> void:
	var row := Kit.hbox(16)
	var l := Kit.label(text, 22)
	l.custom_minimum_size = Vector2(220, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = st
	s.custom_minimum_size = Vector2(480, 44)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value = float(GameConfig.get(key))
	row.add_child(s)
	var vl := Kit.label("%.2f" % s.value, 19, UI.C_DIM)
	vl.custom_minimum_size = Vector2(80, 0)
	row.add_child(vl)
	s.value_changed.connect(func(x: float) -> void:
		vl.text = "%.2f" % x
		GameConfig.set(key, x)
		AudioManager.apply_volumes()
		GameConfig.save_settings())
	_sliders[key] = s
	parent.add_child(row)

func _add_check(parent: Node, text: String, key: String) -> void:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = bool(GameConfig.get(key))
	c.add_theme_font_size_override("font_size", 22)
	c.toggled.connect(func(on: bool) -> void:
		GameConfig.set(key, on)
		GameConfig.save_settings()
		if key == "fullscreen":
			GameConfig.apply_window())
	_checks[key] = c
	parent.add_child(c)

func _on_reset() -> void:
	GameConfig.text_speed = 1.0
	GameConfig.auto_interval = 2.2
	GameConfig.font_scale = 1.0
	GameConfig.effect_level = 2
	GameConfig.master_volume = 1.0
	GameConfig.bgm_volume = 0.65
	GameConfig.se_volume = 0.85
	GameConfig.fullscreen = true
	GameConfig.skip_unread = false
	GameConfig.save_settings()
	for k in _sliders.keys():
		(_sliders[k] as HSlider).value = float(GameConfig.get(k))
	_effect_opt.selected = 2
	for k in _checks.keys():
		(_checks[k] as CheckButton).button_pressed = bool(GameConfig.get(k))
	AudioManager.apply_volumes()
	GameConfig.apply_window()

func _on_close() -> void:
	GameConfig.save_settings()
	AudioManager.apply_volumes()
	_shell.close()

func open() -> void:
	_shell.open()

func is_open() -> bool:
	return _shell.visible
