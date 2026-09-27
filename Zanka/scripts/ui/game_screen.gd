extends Control
## 主游戏画面：背景 / 立绘 / CG / 对话框 / 选项 / HUD / 各种弹窗 + 演出效果。

signal ending_reached(id: String)
signal script_ended
signal request_title
signal game_loaded

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const CharDB := preload("res://scripts/core/char_db.gd")
const BgLayer := preload("res://scripts/ui/bg_layer.gd")
const CharLayer := preload("res://scripts/ui/char_layer.gd")
const DialogueBox := preload("res://scripts/ui/dialogue_box.gd")
const ChoicePanel := preload("res://scripts/ui/choice_panel.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const BacklogPanel := preload("res://scripts/ui/backlog_panel.gd")
const SaveLoadPanel := preload("res://scripts/ui/save_load_panel.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const SystemPanel := preload("res://scripts/ui/system_panel.gd")
const MenuPanel := preload("res://scripts/ui/menu_panel.gd")
const GalleryPanel := preload("res://scripts/ui/gallery_panel.gd")
const TidePanel := preload("res://scripts/ui/tide_panel.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")
const VIGNETTE := "res://shaders/vignette.gdshader"

var _stage: Control
var bg
var chars
var cg: TextureRect
var dbox
var choice
var hud
var _vignette: ColorRect
var _vignette_mat: ShaderMaterial
var _flash: ColorRect
var _black: ColorRect
var _chapter_label: Label
var _chapter_date: Label
var _chapter_box: Control

var backlog
var saveload
var settings
var system
var menu
var gallery
var tide
var status
var _status_body: VBoxContainer

var auto_mode: bool = false
var skip_mode: bool = false
var logs: Array = []

## 当前这一句在显示之前是否已经读过（「只跳过已读」要用）。
## 注意不能事后查 GameState：_on_say 里会立刻把当前行标记为已读，
## 所以必须在标记之前把结果抓下来。
var _cur_already_seen: bool = false

var _auto_t: float = 0.0
var _skip_t: float = 0.0
var _shaking: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_connect_engine()

func _build() -> void:
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_stage)

	bg = BgLayer.new()
	_stage.add_child(bg)

	cg = TextureRect.new()
	cg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cg.visible = false
	_stage.add_child(cg)

	chars = CharLayer.new()
	_stage.add_child(chars)

	# ---- 暗角（病征演出）
	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.color = Color(1, 1, 1, 1)
	if ResourceLoader.exists(VIGNETTE):
		_vignette_mat = ShaderMaterial.new()
		_vignette_mat.shader = load(VIGNETTE)
		_vignette_mat.set_shader_parameter("strength", 0.0)
		_vignette.material = _vignette_mat
	add_child(_vignette)

	# ---- 闪白
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	# ---- 黑幕（转场）
	_black = ColorRect.new()
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.color = Color(0, 0, 0, 0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)

	dbox = DialogueBox.new()
	add_child(dbox)

	choice = ChoicePanel.new()
	add_child(choice)
	choice.chosen.connect(_on_choice_chosen)

	hud = HudScript.new()
	add_child(hud)
	hud.action.connect(_on_hud_action)

	# ---- 章节标题
	_chapter_box = Control.new()
	_chapter_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chapter_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_box.modulate.a = 0.0
	add_child(_chapter_box)
	var cbc := CenterContainer.new()
	cbc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cbc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_box.add_child(cbc)
	var cbv := Kit.vbox(14)
	cbc.add_child(cbv)
	_chapter_label = UI.title_label("", 58)
	cbv.add_child(_chapter_label)
	_chapter_date = Kit.label("", 24, UI.C_DIM)
	_chapter_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cbv.add_child(_chapter_date)

	# ---- 弹窗
	backlog = BacklogPanel.new()
	add_child(backlog)
	saveload = SaveLoadPanel.new()
	add_child(saveload)
	saveload.loaded_game.connect(_on_loaded)
	settings = SettingsPanel.new()
	add_child(settings)
	system = SystemPanel.new()
	add_child(system)
	menu = MenuPanel.new()
	add_child(menu)
	menu.request.connect(_on_menu_request)
	gallery = GalleryPanel.new()
	add_child(gallery)
	tide = TidePanel.new()
	add_child(tide)
	_build_status()

func _build_status() -> void:
	status = Shell.new()
	add_child(status)
	status.set_title("当前状态")
	_status_body = Kit.vbox(10)
	status.body.add_child(_status_body)
	var b := Kit.button("关闭", 21)
	b.pressed.connect(func() -> void: status.close())
	status.footer.add_child(b)

func _connect_engine() -> void:
	StoryEngine.say.connect(_on_say)
	StoryEngine.bg_changed.connect(_on_bg)
	StoryEngine.cg_changed.connect(_on_cg)
	StoryEngine.cg_hidden.connect(_on_cg_hide)
	StoryEngine.char_shown.connect(_on_char)
	StoryEngine.char_hidden.connect(_on_char_hide)
	StoryEngine.bgm_requested.connect(_on_bgm)
	StoryEngine.se_requested.connect(_on_se)
	StoryEngine.amb_requested.connect(_on_amb)
	StoryEngine.fx_requested.connect(_on_fx)
	StoryEngine.calendar_updated.connect(_on_calendar)
	StoryEngine.chapter_titled.connect(_on_chapter)
	StoryEngine.log_added.connect(_on_log)
	StoryEngine.choice_requested.connect(_on_choice)
	StoryEngine.system_requested.connect(_on_system)
	StoryEngine.ending_reached.connect(_on_ending)
	StoryEngine.script_finished.connect(_on_finished)
	StoryEngine.stage_reset.connect(_on_stage_reset)

# ---------------------------------------------------------------- 引擎回调

func _on_say(speaker_id: String, speaker_name: String, text: String) -> void:
	_cur_already_seen = (not GameState.cur_line_key.is_empty()) \
		and GameState.is_seen(GameState.cur_line_key)
	if not GameState.cur_line_key.is_empty():
		GameState.mark_seen(GameState.cur_line_key)
	dbox.show_line(speaker_name, CharDB.name_color(speaker_id), text)
	chars.set_speaking(speaker_id)
	_apply_breath()

func _on_bg(id: String, fade: float) -> void:
	bg.show_bg(id, fade)

func _on_cg(id: String, fade: float) -> void:
	var p := "res://assets/cg/" + id + ".png"
	if not ResourceLoader.exists(p):
		push_warning("缺少 CG：%s" % p)
		return
	cg.texture = load(p)
	cg.visible = true
	cg.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cg, "modulate:a", 1.0, maxf(0.05, fade))

func _on_cg_hide(fade: float) -> void:
	var tw := create_tween()
	tw.tween_property(cg, "modulate:a", 0.0, maxf(0.05, fade))
	tw.tween_callback(func() -> void: cg.visible = false)

func _on_char(sprite_id: String, pos: String, fade: float) -> void:
	chars.show_char(sprite_id, pos, fade)

func _on_char_hide(sprite_id: String, fade: float) -> void:
	chars.hide_char(sprite_id, fade)

func _on_bgm(id: String, fade: float) -> void:
	AudioManager.play_bgm(id, fade)

func _on_se(id: String) -> void:
	AudioManager.play_se(id)

func _on_amb(id: String, fade: float) -> void:
	AudioManager.play_amb(id, fade)

func _on_calendar(date_text: String, tide_text: String, period_text: String) -> void:
	hud.set_calendar(date_text, tide_text, period_text)

func _on_chapter(text: String) -> void:
	hud.set_chapter(text)
	_show_chapter_title(text)
	SaveManager.autosave()

func _on_log(text: String) -> void:
	logs.append(text)

func _on_choice(options: Array) -> void:
	_set_auto(false)
	_set_skip(false)
	choice.present(options)

func _on_choice_chosen(index: int) -> void:
	StoryEngine.choose(index)

func _on_system(kind: String, arg: String) -> void:
	_set_auto(false)
	_set_skip(false)
	system.open_kind(kind, arg)

func _on_ending(id: String) -> void:
	SaveManager.autosave()
	ending_reached.emit(id)

func _on_finished() -> void:
	script_ended.emit()

func _on_stage_reset() -> void:
	chars.clear()
	cg.visible = false
	cg.texture = null

func _on_loaded() -> void:
	logs.clear()
	_set_auto(false)
	_set_skip(false)
	_cur_already_seen = false
	set_hud_visible(true)
	game_loaded.emit()

# ---------------------------------------------------------------- 演出

func _show_chapter_title(text: String) -> void:
	if text.is_empty():
		return
	_chapter_label.text = text
	_chapter_date.text = GameState.date_text
	_chapter_box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_chapter_box, "modulate:a", 1.0, 0.7)
	tw.tween_interval(1.9)
	tw.tween_property(_chapter_box, "modulate:a", 0.0, 0.9)

func _set_vignette(v: float) -> void:
	if _vignette_mat != null:
		_vignette_mat.set_shader_parameter("strength", v)

func _vignette_pulse(strength: float, rise: float, fall: float) -> void:
	if GameConfig.effect_level <= 0 or _vignette_mat == null:
		return
	var tw := create_tween()
	tw.tween_method(_set_vignette, 0.0, strength, rise)
	tw.tween_method(_set_vignette, strength, 0.0, fall)

func _shake(power: float, dur: float = 0.45) -> void:
	if GameConfig.effect_level <= 0 or _shaking:
		return
	_shaking = true
	var t := 0.0
	while t < dur:
		_stage.position = Vector2(randf_range(-power, power), randf_range(-power, power))
		await get_tree().process_frame
		t += get_process_delta_time()
	_stage.position = Vector2.ZERO
	_shaking = false

func _do_flash(c: Color, dur: float = 0.5) -> void:
	_flash.color = Color(c.r, c.g, c.b, c.a)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur)

func _do_blackout(to_black: bool, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 1.0 if to_black else 0.0, dur)

func _on_fx(name: String, arg: String) -> void:
	var v: float = arg.to_float() if arg.is_valid_float() else 0.0
	match name:
		"shake":
			_shake(v if v > 0.0 else 14.0)
		"shake_big":
			_shake(26.0, 0.7)
		"flash":
			_do_flash(Color(1, 1, 1, 0.85), 0.55)
		"flash_dark":
			_do_flash(Color(0.05, 0.03, 0.04, 0.9), 1.2)
		"vignette":
			_vignette_pulse(v if v > 0.0 else 0.55, 0.35, 1.4)
		"breath":
			_vignette_pulse(0.28, 0.5, 1.1)
		"tinnitus":
			_vignette_pulse(0.4, 0.2, 1.6)
		"blackout":
			_do_blackout(true, v if v > 0.0 else 1.0)
		"blackout_end":
			_do_blackout(false, v if v > 0.0 else 1.0)
		_:
			push_warning("未知 fx：%s" % name)

## 病征演出的「呼吸」级：随章节推进越来越明显
func _apply_breath() -> void:
	if GameConfig.effect_level <= 0:
		return
	var stress := 0
	if GameState.has_flag("stage_heavy"):
		stress = 2
	elif GameState.has_flag("stage_mid"):
		stress = 1
	if stress <= 0:
		return
	var base := 0.06 * float(stress)
	_vignette_pulse(base, 0.9, 1.3)

# ---------------------------------------------------------------- 输入

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var is_back := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			pressed = true
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			pressed = true
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
				pressed = true
			elif k.keycode == KEY_ESCAPE:
				is_back = true
			elif k.keycode == KEY_CTRL:
				_set_skip(not skip_mode)
			elif k.keycode == KEY_A:
				_set_auto(not auto_mode)

	if is_back:
		if _any_overlay_open():
			_close_all_overlays()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()
		return

	if not pressed:
		return
	get_viewport().set_input_as_handled()

	if _any_overlay_open():
		return
	if choice.visible:
		return
	if dbox.is_typing():
		dbox.skip_typing()
		return
	if StoryEngine.is_waiting_input():
		StoryEngine.advance()

func _process(delta: float) -> void:
	if _any_overlay_open() or choice.visible:
		return
	if not StoryEngine.is_waiting_input():
		return
	if dbox.is_typing():
		return
	if skip_mode:
		# 「只跳过已读」是默认行为：撞到没读过的句子就自动停下来。
		# 想连未读一起跳，在设置里打开「跳过时忽略未读文本」。
		if not GameConfig.skip_unread and not _cur_already_seen:
			_set_skip(false)
			return
		_skip_t += delta
		if _skip_t >= 0.045:
			_skip_t = 0.0
			StoryEngine.advance()
		return
	if auto_mode:
		_auto_t += delta
		if _auto_t >= GameConfig.auto_interval:
			_auto_t = 0.0
			StoryEngine.advance()

func _set_auto(on: bool) -> void:
	auto_mode = on
	if on:
		_auto_t = 0.0
		skip_mode = false
	hud.set_toggle("auto", auto_mode)
	hud.set_toggle("skip", skip_mode)

func _set_skip(on: bool) -> void:
	skip_mode = on
	if on:
		_skip_t = 0.0
		auto_mode = false
	hud.set_toggle("auto", auto_mode)
	hud.set_toggle("skip", skip_mode)

# ---------------------------------------------------------------- HUD / 菜单

func _on_hud_action(name: String) -> void:
	match name:
		"backlog":
			backlog.open()
		"auto":
			_set_auto(not auto_mode)
		"skip":
			_set_skip(not skip_mode)
		"save":
			saveload.open("save")
		"menu":
			_open_menu()
		"tide":
			tide.open()

func _open_menu() -> void:
	_set_auto(false)
	_set_skip(false)
	menu.open()

func _on_menu_request(name: String) -> void:
	match name:
		"load":
			saveload.open("load")
		"settings":
			settings.open()
		"gallery":
			gallery.open()
		"tide":
			tide.open()
		"status":
			_fill_status()
			status.open()
		"title":
			request_title.emit()

func _fill_status() -> void:
	for c in _status_body.get_children():
		_status_body.remove_child(c)
		c.queue_free()
	var rows := [
		["章节", GameState.chapter_title],
		["日期", GameState.date_text + "　" + GameState.period_text],
		["回忆点", str(GameState.memory)],
		["照护评分", str(GameState.care_score)],
		["写下的信", str(GameState.letters.size()) + " 封"],
		["记忆碎片", str(GameState.fragments.size())],
		["周目", "第 %d 周目" % GameState.playthrough],
	]
	for r in rows:
		var h := Kit.hbox(14)
		var l := Kit.label(str(r[0]), 21, UI.C_DIM)
		l.custom_minimum_size = Vector2(180, 0)
		h.add_child(l)
		var v := Kit.label(str(r[1]), 21, UI.C_TEXT)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		_status_body.add_child(h)
	if not logs.is_empty():
		_status_body.add_child(Kit.spacer(8))
		_status_body.add_child(Kit.label("记录", 22, UI.C_HILITE))
		for lg in logs:
			var t := Kit.label(str(lg), 19, UI.C_DIM)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t.custom_minimum_size = Vector2(820, 0)
			_status_body.add_child(t)

func _any_overlay_open() -> bool:
	return backlog.is_open() or saveload.is_open() or settings.is_open() \
		or system.is_open() or menu.is_open() or gallery.is_open() \
		or tide.is_open() or status.is_open()

func _close_all_overlays() -> void:
	for p in [backlog, saveload, settings, system, menu, gallery, tide, status]:
		if p.has_method("close") and p.is_open():
			p.close()

func set_hud_visible(v: bool) -> void:
	hud.set_hud_visible(v)
	dbox.set_box_visible(v)

func reset_view() -> void:
	chars.clear()
	cg.visible = false
	cg.texture = null
	dbox.show_line("", UI.C_TEXT, "")
	logs.clear()
	_set_auto(false)
	_set_skip(false)
	_cur_already_seen = false
	_set_vignette(0.0)
	_black.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 0.0, 0.8)
