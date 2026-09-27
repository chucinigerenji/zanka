extends Node
## 剧情状态：旗标、回忆点、信件、照护日志、周目、已解锁内容。

signal flagged(name, value)
signal letter_added(id)

const GLOBAL_PATH := "user://global.json"

# ---- 单周目状态 ----
var flags: Dictionary = {}
var memory: int = 0
var letters: Array = []
var care: Dictionary = {}
var care_score: int = 0
var chapter_id: String = ""
var chapter_title: String = ""
var date_text: String = ""
var tide_text: String = ""
var period_text: String = ""
var last_ending: String = ""

# ---- 跨周目持久状态 ----
var playthrough: int = 1
var endings_seen: Array = []
var cgs_seen: Array = []
var bgms_seen: Array = []
var fragments: Array = []          # 记忆碎片 id
var seen_lines: Dictionary = {}    # 已读台词（用于「只跳过已读」）
var cur_line_key: String = ""      # 当前正在显示的台词键，由 StoryEngine 设置

func _ready() -> void:
	load_global()

# ---------------------------------------------------------------- 旗标

func set_flag(name: String, value: Variant = true) -> void:
	flags[name] = value
	flagged.emit(name, value)

func get_flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)

func flag_int(name: String) -> int:
	var v: Variant = flags.get(name, 0)
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return int(v)
	if typeof(v) == TYPE_BOOL:
		return 1 if v else 0
	return 0

func has_flag(name: String) -> bool:
	var v: Variant = flags.get(name, false)
	if typeof(v) == TYPE_BOOL:
		return v
	if typeof(v) == TYPE_INT:
		return v != 0
	if typeof(v) == TYPE_STRING:
		return not (v as String).is_empty()
	return v != null

## 供 @if 使用
func test(cond: Dictionary) -> bool:
	if cond.is_empty():
		return false
	var name: String = cond.get("flag", "")
	var op: String = cond.get("op", "truthy")
	var val: Variant = cond.get("value", null)
	match op:
		"truthy":
			return has_flag(name)
		"falsy":
			return not has_flag(name)
		"==":
			return _cmp_eq(get_flag(name, null), val)
		"!=":
			return not _cmp_eq(get_flag(name, null), val)
		">":
			return _num(name) > _to_num(val)
		"<":
			return _num(name) < _to_num(val)
		">=":
			return _num(name) >= _to_num(val)
		"<=":
			return _num(name) <= _to_num(val)
	return false

func _cmp_eq(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT:
		return int(a) == int(b)
	if typeof(a) == TYPE_FLOAT or typeof(b) == TYPE_FLOAT:
		if _is_num(a) and _is_num(b):
			return absf(_to_num(a) - _to_num(b)) < 0.0001
	return str(a) == str(b)

func _is_num(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT

func _num(name: String) -> float:
	return _to_num(get_flag(name, 0))

func _to_num(v: Variant) -> float:
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return float(v)
	if typeof(v) == TYPE_BOOL:
		return 1.0 if v else 0.0
	if typeof(v) == TYPE_STRING:
		return (v as String).to_float()
	return 0.0

# ---------------------------------------------------------------- 信件

func add_letter(fragment_id: String) -> void:
	if fragment_id.is_empty() or letters.has(fragment_id):
		return
	letters.append(fragment_id)
	letter_added.emit(fragment_id)

# ---------------------------------------------------------------- 照护日志

func set_care(day: String, choice: String, score: int) -> void:
	care[day] = choice
	care_score += score

# ---------------------------------------------------------------- 解锁

func record_ending(id: String) -> void:
	last_ending = id
	if not endings_seen.has(id):
		endings_seen.append(id)
	save_global()

func unlock_cg(id: String) -> void:
	if id.is_empty() or cgs_seen.has(id):
		return
	cgs_seen.append(id)
	save_global()

func unlock_bgm(id: String) -> void:
	if id.is_empty() or bgms_seen.has(id):
		return
	bgms_seen.append(id)
	save_global()

func add_fragment(id: String) -> void:
	if id.is_empty() or fragments.has(id):
		return
	fragments.append(id)
	save_global()

# ---------------------------------------------------------------- 已读

func mark_seen(key: String) -> void:
	if key.is_empty() or seen_lines.has(key):
		return
	seen_lines[key] = true

func is_seen(key: String) -> bool:
	return seen_lines.has(key)

# ---------------------------------------------------------------- 周目

func reset_story() -> void:
	flags = {}
	memory = 0
	letters = []
	care = {}
	care_score = 0
	chapter_id = ""
	chapter_title = ""
	date_text = ""
	tide_text = ""
	period_text = ""
	last_ending = ""

func next_playthrough() -> void:
	playthrough += 1
	save_global()

# ---------------------------------------------------------------- 序列化

func to_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(true),
		"memory": memory,
		"letters": letters.duplicate(),
		"care": care.duplicate(true),
		"care_score": care_score,
		"chapter_id": chapter_id,
		"chapter_title": chapter_title,
		"date_text": date_text,
		"tide_text": tide_text,
		"period_text": period_text,
		"playthrough": playthrough,
	}

func from_dict(d: Dictionary) -> void:
	flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	memory = int(d.get("memory", 0))
	letters = (d.get("letters", []) as Array).duplicate()
	care = (d.get("care", {}) as Dictionary).duplicate(true)
	care_score = int(d.get("care_score", 0))
	chapter_id = str(d.get("chapter_id", ""))
	chapter_title = str(d.get("chapter_title", ""))
	date_text = str(d.get("date_text", ""))
	tide_text = str(d.get("tide_text", ""))
	period_text = str(d.get("period_text", ""))
	playthrough = int(d.get("playthrough", 1))

func save_global() -> void:
	var d := {
		"playthrough": playthrough,
		"endings_seen": endings_seen,
		"cgs_seen": cgs_seen,
		"bgms_seen": bgms_seen,
		"fragments": fragments,
		"seen_lines": seen_lines,
	}
	var f := FileAccess.open(GLOBAL_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("无法写入 global.json")
		return
	f.store_string(JSON.stringify(d, "  "))
	f.close()

func load_global() -> void:
	if not FileAccess.file_exists(GLOBAL_PATH):
		return
	var f := FileAccess.open(GLOBAL_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("global.json 解析失败，使用默认值")
		return
	var d: Dictionary = parsed
	playthrough = int(d.get("playthrough", 1))
	endings_seen = d.get("endings_seen", [])
	cgs_seen = d.get("cgs_seen", [])
	bgms_seen = d.get("bgms_seen", [])
	fragments = d.get("fragments", [])
	seen_lines = d.get("seen_lines", {})
