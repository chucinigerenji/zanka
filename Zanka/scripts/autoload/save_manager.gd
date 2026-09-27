extends Node
## 存档管理：6 个手动档 + 1 个自动档；全局解锁数据存在 global.json（由 GameState 负责）。

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 6
const AUTO_SLOT := -1
const FORMAT_VERSION := 1

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func slot_path(slot: int) -> String:
	if slot == AUTO_SLOT:
		return SAVE_DIR + "/auto.json"
	return SAVE_DIR + "/slot_%d.json" % slot

func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func save_slot(slot: int) -> bool:
	var payload := {
		"version": FORMAT_VERSION,
		"time": Time.get_datetime_string_from_system(),
		"state": GameState.to_dict(),
		"story": StoryEngine.get_snapshot(),
		"preview": _make_preview(),
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("存档写入失败：%s" % slot_path(slot))
		return false
	f.store_string(JSON.stringify(payload))
	f.close()
	return true

func load_slot(slot: int) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("存档解析失败：%s" % path)
		return false
	var d: Dictionary = parsed
	if int(d.get("version", 0)) != FORMAT_VERSION:
		push_warning("存档版本不同（%s），尝试继续读取" % str(d.get("version", "?")))
	GameState.from_dict(d.get("state", {}))
	return StoryEngine.restore_snapshot(d.get("story", {}))

func delete_slot(slot: int) -> void:
	var p := slot_path(slot)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func autosave() -> void:
	save_slot(AUTO_SLOT)

func slot_info(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed
	var pv: Dictionary = d.get("preview", {})
	return {
		"time": str(d.get("time", "")),
		"chapter": str(pv.get("chapter", "")),
		"date": str(pv.get("date", "")),
		"text": str(pv.get("text", "")),
	}

func _make_preview() -> Dictionary:
	var st := StoryEngine.last_say_text
	if st.length() > 42:
		st = st.left(42) + "…"
	return {
		"chapter": GameState.chapter_title,
		"date": GameState.date_text + "　" + GameState.period_text,
		"text": st,
	}
