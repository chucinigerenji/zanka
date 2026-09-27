extends RefCounted
## 《残夏》剧本编译器
##
## 把 .zs 剧本文本编译成扁平指令数组，供 StoryEngine 逐条执行。
## 编译期就解析好标签跳转目标，并收集全部错误，便于静态校验。
##
## .zs 语法：
##   # 注释
##   ::标签名
##   角色id|台词
##   |旁白
##   @指令 参数...
##   @choice / * 选项 -> 标签 | flag=值 / @endchoice
##   @if 条件 / @else / @endif

var commands: Array = []
var labels: Dictionary = {}
var errors: Array = []
var warnings: Array = []

const JUMP_OPS := ["goto", "call"]

func compile(text: String, source: String = "") -> bool:
	commands = []
	labels = {}
	errors = []
	warnings = []

	var lines: PackedStringArray = text.split("\n")
	var if_stack: Array = []
	var choice_stack: Array = []

	for li in range(lines.size()):
		var line_no: int = li + 1
		var line: String = lines[li].strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("#") or line.begins_with("//"):
			continue

		# ---------------- 标签
		if line.begins_with("::"):
			var lname: String = line.substr(2).strip_edges()
			if lname.is_empty():
				errors.append("%s:%d 空标签名" % [source, line_no])
			elif labels.has(lname):
				errors.append("%s:%d 标签 '%s' 重复定义（首次在第 %d 行）" % [source, line_no, lname, int(labels[lname]) + 1])
			else:
				labels[lname] = commands.size()
			continue

		# ---------------- 选项
		if line.begins_with("*"):
			if choice_stack.is_empty():
				errors.append("%s:%d '*' 选项不在 @choice 块内" % [source, line_no])
				continue
			var body: String = line.substr(1).strip_edges()
			var arrow: int = body.find("->")
			if arrow < 0:
				errors.append("%s:%d 选项缺少 '-> 目标标签'：%s" % [source, line_no, body])
				continue
			var otext: String = body.substr(0, arrow).strip_edges()
			var rest: String = body.substr(arrow + 2).strip_edges()
			var target: String = rest
			var sets: Array = []
			var pipe: int = rest.find("|")
			if pipe >= 0:
				target = rest.substr(0, pipe).strip_edges()
				for kv in rest.substr(pipe + 1).split(",", false):
					var kv2: String = kv.strip_edges()
					if kv2.is_empty():
						continue
					var eq: int = kv2.find("=")
					if eq < 0:
						sets.append([kv2, true])
					else:
						sets.append([kv2.substr(0, eq).strip_edges(), _typed(kv2.substr(eq + 1).strip_edges())])
			if otext.is_empty():
				errors.append("%s:%d 选项文本为空" % [source, line_no])
			if target.is_empty():
				errors.append("%s:%d 选项目标为空" % [source, line_no])
			var ci: int = choice_stack.back()
			commands[ci]["options"].append({"text": otext, "target": target, "sets": sets, "jmp": -1})
			continue

		# ---------------- 指令
		if line.begins_with("@"):
			var sp: int = line.find(" ")
			var dname: String = (line.substr(1, sp - 1) if sp > 0 else line.substr(1)).strip_edges()
			var argstr: String = (line.substr(sp + 1).strip_edges() if sp > 0 else "")
			# 全角空格（U+3000）也当分隔符：企划文案里习惯用全角空格断词
			var args: PackedStringArray = argstr.replace("\u3000", " ").split(" ", false)

			match dname:
				"choice":
					choice_stack.append(commands.size())
					commands.append({"op": "choice", "options": [], "line": line_no})
				"endchoice":
					if choice_stack.is_empty():
						errors.append("%s:%d @endchoice 没有对应的 @choice" % [source, line_no])
					else:
						var ci2: int = choice_stack.pop_back()
						if commands[ci2]["options"].is_empty():
							errors.append("%s:%d @choice 块里没有任何选项" % [source, line_no])
				"if":
					var cond: Dictionary = _parse_cond(argstr)
					if cond.is_empty():
						errors.append("%s:%d @if 条件无法解析：'%s'" % [source, line_no, argstr])
					var idx: int = commands.size()
					commands.append({"op": "if", "cond": cond, "jmp": -1, "line": line_no})
					if_stack.append({"if": idx, "else": -1})
				"else":
					if if_stack.is_empty():
						errors.append("%s:%d @else 没有对应的 @if" % [source, line_no])
					else:
						var fr: Dictionary = if_stack.back()
						commands.append({"op": "else", "jmp": -1, "line": line_no})
						fr["else"] = commands.size() - 1
						commands[int(fr["if"])]["jmp"] = commands.size()
				"endif":
					if if_stack.is_empty():
						errors.append("%s:%d @endif 没有对应的 @if" % [source, line_no])
					else:
						var fr2: Dictionary = if_stack.pop_back()
						if int(fr2["else"]) >= 0:
							commands[int(fr2["else"])]["jmp"] = commands.size()
						else:
							commands[int(fr2["if"])]["jmp"] = commands.size()
				"bg":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "bg", "id": _a(args, 0), "fade": _f(args, 1, 0.6), "line": line_no})
				"cg":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "cg", "id": _a(args, 0), "fade": _f(args, 1, 0.6), "line": line_no})
				"cg_hide":
					commands.append({"op": "cg_hide", "fade": _f(args, 0, 0.6), "line": line_no})
				"char":
					_require(args, 2, source, line_no, dname)
					commands.append({"op": "char", "id": _a(args, 0), "pos": _a(args, 1), "fade": _f(args, 2, 0.4), "line": line_no})
				"hide":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "hide", "id": _a(args, 0), "fade": _f(args, 1, 0.4), "line": line_no})
				"bgm":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "bgm", "id": _a(args, 0), "fade": _f(args, 1, 1.2), "line": line_no})
				"se":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "se", "id": _a(args, 0), "line": line_no})
				"amb":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "amb", "id": _a(args, 0), "fade": _f(args, 1, 1.5), "line": line_no})
				"fx":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "fx", "name": _a(args, 0), "arg": _a(args, 1), "line": line_no})
				"wait":
					commands.append({"op": "wait", "sec": _f(args, 0, 1.0), "line": line_no})
				"cal":
					_require(args, 3, source, line_no, dname)
					commands.append({"op": "cal", "date": _a(args, 0), "tide": _a(args, 1), "period": _a(args, 2), "line": line_no})
				"chapter":
					commands.append({"op": "chapter", "text": argstr, "line": line_no})
				"log":
					commands.append({"op": "log", "text": argstr, "line": line_no})
				"set":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "set", "flag": _a(args, 0),
						"value": (_typed(" ".join(args.slice(1))) if args.size() > 1 else true), "line": line_no})
				"goto":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "goto", "target": _a(args, 0), "jmp": -1, "line": line_no})
				"call":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "call", "target": _a(args, 0), "jmp": -1, "line": line_no})
				"return":
					commands.append({"op": "return", "line": line_no})
				"letter":
					commands.append({"op": "letter", "chapter": _a(args, 0), "line": line_no})
				"care":
					commands.append({"op": "care", "day": _a(args, 0), "line": line_no})
				"timeslot":
					commands.append({"op": "timeslot", "chapter": _a(args, 0), "line": line_no})
				"ending":
					_require(args, 1, source, line_no, dname)
					commands.append({"op": "ending", "id": _a(args, 0), "line": line_no})
				"fin":
					commands.append({"op": "fin", "line": line_no})
				_:
					errors.append("%s:%d 未知指令 @%s" % [source, line_no, dname])
			continue

		# ---------------- 台词 / 旁白
		var sep: int = line.find("|")
		if sep < 0:
			errors.append("%s:%d 无法识别（台词请用 '角色id|文本'，旁白请用 '|文本'）：%s" % [source, line_no, line.left(24)])
			continue
		var spk: String = line.substr(0, sep).strip_edges()
		var txt: String = line.substr(sep + 1).strip_edges()
		if txt.is_empty():
			warnings.append("%s:%d 空台词" % [source, line_no])
		commands.append({"op": "say", "speaker": spk, "text": txt, "line": line_no})

	if not if_stack.is_empty():
		errors.append("%s 有 %d 个 @if 没有闭合（缺 @endif）" % [source, if_stack.size()])
	if not choice_stack.is_empty():
		errors.append("%s 有 %d 个 @choice 没有闭合（缺 @endchoice）" % [source, choice_stack.size()])

	_resolve_jumps(source)
	return errors.is_empty()

func _resolve_jumps(source: String) -> void:
	for c in commands:
		var op: String = c.get("op", "")
		if op in JUMP_OPS:
			var t: String = c.get("target", "")
			if not labels.has(t):
				errors.append("%s:%d @%s 目标标签 '%s' 不存在" % [source, c.get("line", 0), op, t])
			else:
				c["jmp"] = labels[t]
		elif op == "choice":
			for o in c["options"]:
				if not labels.has(o["target"]):
					errors.append("%s:%d 选项 '%s' 目标标签 '%s' 不存在" % [source, c.get("line", 0), o["text"], o["target"]])
				else:
					o["jmp"] = labels[o["target"]]

# ---------------------------------------------------------------- 小工具

func _parse_cond(s: String) -> Dictionary:
	var t: String = s.strip_edges()
	if t.is_empty():
		return {}
	if t.begins_with("!"):
		return {"flag": t.substr(1).strip_edges(), "op": "falsy", "value": null}
	for op in ["==", "!=", ">=", "<=", ">", "<"]:
		var p: int = t.find(op)
		if p > 0:
			return {"flag": t.substr(0, p).strip_edges(), "op": op, "value": _typed(t.substr(p + op.length()).strip_edges())}
	return {"flag": t, "op": "truthy", "value": null}

func _typed(s: String) -> Variant:
	var t: String = s.strip_edges()
	if t == "true":
		return true
	if t == "false":
		return false
	if t.is_valid_int():
		return t.to_int()
	if t.is_valid_float():
		return t.to_float()
	if t.begins_with("\"") and t.ends_with("\"") and t.length() >= 2:
		return t.substr(1, t.length() - 2)
	return t

func _a(args: PackedStringArray, i: int) -> String:
	return args[i] if i < args.size() else ""

func _f(args: PackedStringArray, i: int, def: float) -> float:
	if i >= args.size():
		return def
	return args[i].to_float() if args[i].is_valid_float() else def

func _require(args: PackedStringArray, n: int, source: String, line_no: int, dname: String) -> void:
	if args.size() < n:
		errors.append("%s:%d @%s 至少需要 %d 个参数，实际 %d 个" % [source, line_no, dname, n, args.size()])
