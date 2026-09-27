extends Control
## 系统面板：信件 / 照护日志 / 时间编排，三种都由 data/systems.json 驱动。

signal system_finished

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")

const DATA_PATH := "res://data/systems.json"

## kind -> systems.json 里的分组键
const GROUP := {"letter": "letters", "care": "care_days", "timeslot": "timeslots"}

var _shell
var _data: Dictionary = {}
var _kind: String = ""
var _key: String = ""
var _picked: Array = []
var _checks: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell = Shell.new()
	add_child(_shell)
	_load_data()

func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_warning("缺少 %s" % DATA_PATH)
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	else:
		push_error("%s 解析失败" % DATA_PATH)

func open_kind(kind: String, key: String) -> void:
	_kind = kind
	_key = key
	_picked.clear()
	_checks.clear()
	_shell.clear_body()

	var group: Dictionary = _data.get(GROUP.get(kind, kind + "s"), {})
	var item: Dictionary = group.get(key, {})
	if item.is_empty():
		push_warning("systems.json 缺少 %s/%s" % [kind, key])
		# 数据缺失时不要卡住剧情
		call_deferred("_finish_immediately")
		return

	_shell.set_title(str(item.get("title", "")))
	_shell.body.add_child(Kit.label(str(item.get("prompt", "")), 22, UI.C_TEXT))

	var opts: Array = item.get("options", [])
	var multi: bool = kind == "timeslot"
	var need: int = int(item.get("slots", 1))

	for i in range(opts.size()):
		var o: Dictionary = opts[i]
		if multi:
			var cb := CheckButton.new()
			cb.text = str(o.get("text", ""))
			cb.add_theme_font_size_override("font_size", 22)
			cb.custom_minimum_size = Vector2(820, 48)
			cb.toggled.connect(_on_multi_toggled.bind(i, need))
			_shell.body.add_child(cb)
			_checks.append(cb)
		else:
			var b := Kit.button(str(o.get("text", "")), 22, 820)
			b.custom_minimum_size = Vector2(820, 58)
			b.pressed.connect(_on_single.bind(i))
			_shell.body.add_child(b)

	if multi:
		var confirm := Kit.button("确定", 21, 140)
		confirm.pressed.connect(_on_multi_confirm)
		_shell.footer.add_child(confirm)
	_shell.open()

func _on_multi_toggled(on: bool, idx: int, need: int) -> void:
	if on:
		if not _picked.has(idx):
			_picked.append(idx)
	else:
		_picked.erase(idx)
	# 超出额度就回退最早选的那项
	while _picked.size() > need:
		var drop: int = _picked.pop_front()
		if drop < _checks.size():
			(_checks[drop] as CheckButton).set_pressed_no_signal(false)

func _on_multi_confirm() -> void:
	var group: Dictionary = _data.get(GROUP.get("timeslot", "timeslots"), {})
	var item: Dictionary = group.get(_key, {})
	var opts: Array = item.get("options", [])
	for idx in _picked:
		if idx >= 0 and idx < opts.size():
			_apply_option(opts[idx])
	_finish()

func _on_single(idx: int) -> void:
	var group: Dictionary = _data.get(GROUP.get(_kind, _kind + "s"), {})
	var item: Dictionary = group.get(_key, {})
	var opts: Array = item.get("options", [])
	if idx >= 0 and idx < opts.size():
		_apply_option(opts[idx])
	_finish()

func _apply_option(o: Dictionary) -> void:
	var oid := str(o.get("id", ""))
	var flag := str(o.get("flag", ""))
	if not flag.is_empty():
		GameState.set_flag(flag, true)
	if oid.is_empty():
		oid = flag
	GameState.memory += int(o.get("memory", 0))
	GameState.set_flag("memory", GameState.memory)
	if _kind == "letter":
		GameState.add_letter(oid)
		GameState.set_flag("letters_count", GameState.letters.size())
	elif _kind == "care":
		GameState.set_care(_key, oid, int(o.get("score", 0)))
		GameState.set_flag("care_score", GameState.care_score)
	elif _kind == "timeslot":
		if o.has("cg"):
			GameState.unlock_cg(str(o.get("cg", "")))
		var frag := str(o.get("fragment", ""))
		if not frag.is_empty():
			GameState.add_fragment(frag)
	AudioManager.play_se("select")

func _finish_immediately() -> void:
	system_finished.emit()
	StoryEngine.system_done()

func _finish() -> void:
	_shell.close()
	system_finished.emit()
	StoryEngine.system_done()

func is_open() -> bool:
	return _shell.visible
