extends Control
## 游戏内主菜单（点 HUD 的「菜单」）。

signal request(name: String)

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const Shell := preload("res://scripts/ui/overlay_shell.gd")

var _shell

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell = Shell.new()
	add_child(_shell)
	_shell.set_title("菜单")

	var items := [
		["load", "读取进度"],
		["settings", "游戏设置"],
		["gallery", "鉴赏与信件"],
		["status", "当前状态"],
		["tide", "汐浦港　潮汐表"],
		["title", "返回标题画面"],
	]
	for it in items:
		var b := Kit.button(str(it[1]), 23, 820)
		b.custom_minimum_size = Vector2(820, 58)
		b.pressed.connect(func() -> void:
			AudioManager.play_se("select")
			_shell.close()
			request.emit(str(it[0])))
		_shell.body.add_child(b)

	var resume := Kit.button("回到游戏", 22)
	resume.pressed.connect(func() -> void: _shell.close())
	_shell.footer.add_child(resume)

func open() -> void:
	_shell.open()

func is_open() -> bool:
	return _shell.visible

func close() -> void:
	_shell.close()
