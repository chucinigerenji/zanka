extends Node
## 剧情引擎：加载并编译 .zs 剧本，逐条执行，通过信号驱动 UI。
##
## 执行模型：非阻塞指令一路执行到底；遇到 say / choice / wait / 系统面板 / ending
## 就停下来把控制权交回 UI，由 UI 调用 advance() / choose() / system_done() 继续。

const ZSCompiler = preload("res://scripts/core/zs_compiler.gd")
const CharDB = preload("res://scripts/core/char_db.gd")

signal say(speaker_id: String, speaker_name: String, text: String)
signal bg_changed(id: String, fade: float)
signal cg_changed(id: String, fade: float)
signal cg_hidden(fade: float)
signal char_shown(sprite_id: String, pos: String, fade: float)
signal char_hidden(sprite_id: String, fade: float)
signal bgm_requested(id: String, fade: float)
signal se_requested(id: String)
signal amb_requested(id: String, fade: float)
signal fx_requested(name: String, arg: String)
signal calendar_updated(date_text: String, tide_text: String, period_text: String)
signal chapter_titled(text: String)
signal log_added(text: String)
signal choice_requested(options: Array)
signal system_requested(kind: String, arg: String)
signal ending_reached(id: String)
signal script_finished()
signal error_reported(msg: String)
signal stage_reset()

enum St { IDLE, RUNNING, WAIT_INPUT, WAIT_CHOICE, WAIT_TIMER, WAIT_SYSTEM, DONE }

var cmds: Array = []
var labels: Dictionary = {}
var errors: Array = []
var warnings: Array = []

var state: int = St.IDLE
var pc: int = 0
var current_path: String = ""
var call_stack: Array = []
var history: Array = []
var last_say_text: String = ""

var stage: Dictionary = {"bg": "", "cg": "", "chars": {}, "bgm": "", "amb": ""}

var _gen: int = 0
var _last_say_pc: int = -1
var _pending_choice: Array = []

# ---------------------------------------------------------------- 加载 / 编译

func load_script(path: String) -> bool:
	if not FileAccess.file_exists(path):
		error_reported.emit("剧本文件不存在：%s" % path)
		return false
	var text := _read_text(path)
	if text.is_empty():
		error_reported.emit("剧本为空或读取失败：%s" % path)
		return false
	return compile_text(text, path)

## .zs 是编辑源；.json 是打包产物（Godot 只认后者为资源，导出 APK 才带得上）。
func _read_text(path: String) -> String:
	var raw := FileAccess.get_file_as_string(path)
	if path.get_extension().to_lower() == "json":
		var parsed: Variant = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			return str((parsed as Dictionary).get("text", ""))
		return ""
	return raw

func compile_text(text: String, source: String = "<内存>") -> bool:
	var c: RefCounted = ZSCompiler.new()
	var ok: bool = c.compile(text, source)
	cmds = c.commands
	labels = c.labels
	errors = c.errors
	warnings = c.warnings
	current_path = source
	for e in errors:
		error_reported.emit(e)
	for w in warnings:
		push_warning(w)
	return ok

func is_loaded() -> bool:
	return not cmds.is_empty()

# ---------------------------------------------------------------- 运行控制

func start(label: String = "") -> void:
	_gen += 1
	pc = 0
	if not label.is_empty():
		if labels.has(label):
			pc = int(labels[label])
		else:
			error_reported.emit("起始标签不存在：%s" % label)
	call_stack = []
	history = []
	_last_say_pc = -1
	state = St.RUNNING
	_run()

func advance() -> void:
	if state != St.WAIT_INPUT:
		return
	state = St.RUNNING
	_run()

func choose(index: int) -> void:
	if state != St.WAIT_CHOICE:
		return
	if index < 0 or index >= _pending_choice.size():
		return
	var o: Dictionary = _pending_choice[index]
	for kv in o.get("sets", []):
		GameState.set_flag(str(kv[0]), kv[1])
	pc = int(o.get("jmp", pc))
	_pending_choice = []
	state = St.RUNNING
	if history.is_empty() or history.back().get("choice", false) == false:
		history.append({"speaker": "", "text": "→ " + str(o.get("text", "")), "choice": true})
	_run()

func system_done() -> void:
	if state != St.WAIT_SYSTEM:
		return
	state = St.RUNNING
	_run()

func abort() -> void:
	_gen += 1
	state = St.IDLE

func is_waiting_input() -> bool:
	return state == St.WAIT_INPUT

func is_finished() -> bool:
	return state == St.DONE

# ---------------------------------------------------------------- 主循环

func _run() -> void:
	var my_gen: int = _gen
	while true:
		if my_gen != _gen:
			return
		if pc < 0 or pc >= cmds.size():
			state = St.DONE
			script_finished.emit()
			return
		var c: Dictionary = cmds[pc]
		pc += 1
		var op: String = str(c.get("op", ""))
		match op:
			"say":
				_last_say_pc = pc - 1
				var sid: String = str(c.get("speaker", ""))
				var nm: String = CharDB.display_name(sid)
				var tx: String = str(c.get("text", ""))
				last_say_text = tx
				GameState.cur_line_key = "%s#%d" % [current_path, pc - 1]
				history.append({"speaker": nm, "text": tx})
				if history.size() > 400:
					history.pop_front()
				state = St.WAIT_INPUT
				say.emit(sid, nm, tx)
				return
			"bg":
				stage["bg"] = str(c.get("id", ""))
				bg_changed.emit(str(c.get("id", "")), float(c.get("fade", 0.6)))
			"cg":
				var cid: String = str(c.get("id", ""))
				stage["cg"] = cid
				GameState.unlock_cg(cid)
				cg_changed.emit(cid, float(c.get("fade", 0.6)))
			"cg_hide":
				stage["cg"] = ""
				cg_hidden.emit(float(c.get("fade", 0.6)))
			"char":
				var sprite: String = str(c.get("id", ""))
				var pos: String = str(c.get("pos", "c"))
				(stage["chars"] as Dictionary)[sprite] = pos
				char_shown.emit(sprite, pos, float(c.get("fade", 0.4)))
			"hide":
				var hid: String = str(c.get("id", ""))
				if hid == "all":
					(stage["chars"] as Dictionary).clear()
				else:
					(stage["chars"] as Dictionary).erase(hid)
				char_hidden.emit(hid, float(c.get("fade", 0.4)))
			"bgm":
				var bid: String = str(c.get("id", ""))
				stage["bgm"] = bid
				if not bid.is_empty() and bid != "none":
					GameState.unlock_bgm(bid)
				bgm_requested.emit(bid, float(c.get("fade", 1.2)))
			"se":
				se_requested.emit(str(c.get("id", "")))
			"amb":
				var aid: String = str(c.get("id", ""))
				stage["amb"] = aid
				amb_requested.emit(aid, float(c.get("fade", 1.5)))
			"fx":
				fx_requested.emit(str(c.get("name", "")), str(c.get("arg", "")))
			"wait":
				state = St.WAIT_TIMER
				var sec: float = float(c.get("sec", 1.0))
				if sec > 0.0:
					await get_tree().create_timer(sec).timeout
				if my_gen != _gen:
					return
				state = St.RUNNING
			"cal":
				GameState.date_text = str(c.get("date", ""))
				GameState.tide_text = str(c.get("tide", ""))
				GameState.period_text = str(c.get("period", ""))
				calendar_updated.emit(GameState.date_text, GameState.tide_text, GameState.period_text)
			"chapter":
				var t: String = str(c.get("text", ""))
				GameState.chapter_title = t
				chapter_titled.emit(t)
			"log":
				log_added.emit(str(c.get("text", "")))
			"set":
				GameState.set_flag(str(c.get("flag", "")), c.get("value", true))
			"if":
				if not GameState.test(c.get("cond", {})):
					pc = int(c.get("jmp", pc))
			"else":
				pc = int(c.get("jmp", pc))
			"goto":
				pc = int(c.get("jmp", pc))
			"call":
				call_stack.append(pc)
				pc = int(c.get("jmp", pc))
			"return":
				if call_stack.is_empty():
					state = St.DONE
					script_finished.emit()
					return
				pc = int(call_stack.pop_back())
			"choice":
				_pending_choice = c.get("options", [])
				if _pending_choice.is_empty():
					continue
				state = St.WAIT_CHOICE
				choice_requested.emit(_pending_choice)
				return
			"letter":
				state = St.WAIT_SYSTEM
				system_requested.emit("letter", str(c.get("chapter", "")))
				return
			"care":
				state = St.WAIT_SYSTEM
				system_requested.emit("care", str(c.get("day", "")))
				return
			"timeslot":
				state = St.WAIT_SYSTEM
				system_requested.emit("timeslot", str(c.get("chapter", "")))
				return
			"ending":
				var eid: String = str(c.get("id", ""))
				GameState.record_ending(eid)
				state = St.DONE
				ending_reached.emit(eid)
				return
			"fin":
				state = St.DONE
				script_finished.emit()
				return
			_:
				push_warning("未知指令 op=%s" % op)

# ---------------------------------------------------------------- 存档快照

func get_snapshot() -> Dictionary:
	return {
		"path": current_path,
		"pc": _last_say_pc if _last_say_pc >= 0 else pc,
		"call_stack": call_stack.duplicate(),
		"stage": stage.duplicate(true),
		"last_say_text": last_say_text,
	}

func restore_snapshot(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	var path: String = str(d.get("path", ""))
	if path.is_empty() or not load_script(path):
		return false
	_gen += 1
	pc = int(d.get("pc", 0))
	call_stack = (d.get("call_stack", []) as Array).duplicate()
	stage = (d.get("stage", {}) as Dictionary).duplicate(true)
	last_say_text = str(d.get("last_say_text", ""))
	history = []
	state = St.RUNNING
	_last_say_pc = pc
	rebuild_stage()
	_run()
	return true

## 读档后把画面重建到快照时的状态。
func rebuild_stage() -> void:
	stage_reset.emit()
	var bg: String = str(stage.get("bg", ""))
	if not bg.is_empty():
		bg_changed.emit(bg, 0.0)
	var cg: String = str(stage.get("cg", ""))
	if not cg.is_empty():
		cg_changed.emit(cg, 0.0)
	var chars: Dictionary = stage.get("chars", {})
	for sprite in chars.keys():
		char_shown.emit(str(sprite), str(chars[sprite]), 0.0)
	var bgm: String = str(stage.get("bgm", ""))
	if not bgm.is_empty():
		bgm_requested.emit(bgm, 0.4)
	var amb: String = str(stage.get("amb", ""))
	if not amb.is_empty():
		amb_requested.emit(amb, 0.4)
	GameState.date_text = GameState.date_text
	calendar_updated.emit(GameState.date_text, GameState.tide_text, GameState.period_text)
