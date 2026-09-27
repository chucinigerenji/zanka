extends Node
## 《残夏》主控：构建根 CanvasLayer，在标题 / 游戏 / 结局三个画面之间切换。

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const TitleScreen := preload("res://scripts/ui/title_screen.gd")
const GameScreen := preload("res://scripts/ui/game_screen.gd")
const EndingScreen := preload("res://scripts/ui/ending_screen.gd")

const STORY_ZS := "res://data/story/main.zs"
const STORY_JSON := "res://data/story/main.json"

## 优先读打包产物（导出后只有它会被打进包）
func story_path() -> String:
	if FileAccess.file_exists(STORY_JSON):
		return STORY_JSON
	return STORY_ZS

var _layer: CanvasLayer
var _root: Control
var _title
var _game
var _ending
var _fatal: Label
var _from_title: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	add_child(_layer)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI.make_theme()
	_layer.add_child(_root)

	_title = TitleScreen.new()
	_root.add_child(_title)
	_title.request.connect(_on_title_request)

	_game = GameScreen.new()
	_root.add_child(_game)
	_game.visible = false
	_game.ending_reached.connect(_on_ending)
	_game.script_ended.connect(_on_script_ended)
	_game.request_title.connect(_on_request_title)
	_game.game_loaded.connect(_on_game_loaded)
	_game.saveload.closed.connect(_on_load_panel_closed)

	_ending = EndingScreen.new()
	_root.add_child(_ending)
	_ending.visible = false
	_ending.request.connect(_on_ending_request)

	_fatal = Kit.label("", 20, Color(1, 0.5, 0.5))
	_fatal.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_fatal.offset_left = 24
	_fatal.offset_top = -180
	_fatal.offset_right = 1256
	_fatal.offset_bottom = -20
	_fatal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fatal.visible = false
	_root.add_child(_fatal)

	# 全局读到的剧本错误：启动时先把主剧本编译一遍，有问题直接显示出来
	_check_story()

	_title.open()
	AudioManager.play_bgm("title", 1.2)
	GameConfig.apply_window()

func _check_story() -> void:
	var path := story_path()
	if not FileAccess.file_exists(path):
		_show_fatal("找不到剧本文件：%s" % path)
		return
	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		_show_fatal("剧本无法读取或为空：%s" % path)
		return
	var text := raw
	if path.get_extension().to_lower() == "json":
		var parsed: Variant = JSON.parse_string(raw)
		text = str((parsed as Dictionary).get("text", "")) if typeof(parsed) == TYPE_DICTIONARY else ""
	var compiler = preload("res://scripts/core/zs_compiler.gd").new()
	var ok: bool = compiler.compile(text, path)
	if not ok:
		var msg := "剧本编译发现 %d 处错误：\n" % compiler.errors.size()
		var n: int = mini(6, compiler.errors.size())
		for i in range(n):
			msg += "· " + str(compiler.errors[i]) + "\n"
		_show_fatal(msg)
		push_error(msg)

func _show_fatal(msg: String) -> void:
	_fatal.text = msg
	_fatal.visible = true

# ---------------------------------------------------------------- 画面切换

func _goto_title() -> void:
	AudioManager.play_bgm("title", 1.0)
	_game.visible = false
	_ending.visible = false
	_title.visible = true
	_title.open()

func _on_title_request(name: String) -> void:
	match name:
		"new":
			_start_new()
		"continue":
			_continue_game()
		"load":
			_open_load_from_title()
		"gallery":
			_title.gallery.open()
		"settings":
			_title.settings.open()
		"quit":
			get_tree().quit()

func _open_load_from_title() -> void:
	# 复用游戏里的读档面板：先切到游戏画面（隐藏 HUD），读完再恢复
	_from_title = true
	_game.visible = true
	_game.set_hud_visible(false)
	_game.saveload.open("load")

func _on_game_loaded() -> void:
	_from_title = false
	_title.visible = false
	_ending.visible = false
	_game.visible = true
	_game.set_hud_visible(true)

func _on_load_panel_closed() -> void:
	if not _from_title:
		return
	_from_title = false
	if StoryEngine.is_waiting_input():
		return          # 游戏已经在跑，说明是在游戏里读的档
	_game.visible = false
	_goto_title()

func _start_new() -> void:
	GameState.reset_story()
	AudioManager.stop_all()
	if not StoryEngine.load_script(story_path()):
		_show_fatal("剧本加载失败，请看控制台输出。")
		return
	_fatal.visible = false
	_title.visible = false
	_ending.visible = false
	_game.visible = true
	_game.set_hud_visible(true)
	_game.reset_view()
	StoryEngine.start("start")

func _continue_game() -> void:
	if not SaveManager.has_slot(SaveManager.AUTO_SLOT):
		_show_fatal("没有自动存档。请先「开始新的一周目」。")
		return
	if SaveManager.load_slot(SaveManager.AUTO_SLOT):
		_title.visible = false
		_ending.visible = false
		_game.visible = true
		_game.set_hud_visible(true)
	else:
		_show_fatal("自动存档读取失败。")

func _on_ending(id: String) -> void:
	_game.visible = false
	_ending.show_ending(id)

func _on_script_ended() -> void:
	# 没有触发 ending 就走到头了（例如 @fin）——回标题
	if _game.visible:
		_goto_title()

func _on_request_title() -> void:
	StoryEngine.abort()
	AudioManager.stop_bgm(0.6)
	_goto_title()

func _on_ending_request(name: String) -> void:
	match name:
		"title":
			_ending.visible = false
			_goto_title()
		"load":
			_ending.visible = false
			_from_title = true
			_game.visible = true
			_game.set_hud_visible(false)
			_game.saveload.open("load")

func _goto_title_reset() -> void:
	_from_title = false
	_game.visible = false
	_goto_title()
