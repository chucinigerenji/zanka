extends Node
## 全局设置：文本速度、音量、演出强度、全屏等。持久化到 user://settings.cfg

const PATH := "user://settings.cfg"

signal changed

var text_speed: float = 1.0      # 1.0 = 每字 1/30 秒；越大越快
var auto_interval: float = 2.2   # 自动播放时每句停顿秒数
var bgm_volume: float = 0.65
var se_volume: float = 0.85
var fullscreen: bool = true
var skip_all: bool = true        # true = 跳过时不分已读未读（默认；否则按一下像没反应）
var font_scale: float = 1.0
var effect_level: int = 2        # 0=关 1=弱 2=全（病征演出强度）
var master_volume: float = 1.0

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	text_speed = cf.get_value("play", "text_speed", text_speed)
	auto_interval = cf.get_value("play", "auto_interval", auto_interval)
	skip_all = cf.get_value("play", "skip_all", skip_all)
	font_scale = cf.get_value("play", "font_scale", font_scale)
	effect_level = cf.get_value("play", "effect_level", effect_level)
	bgm_volume = cf.get_value("audio", "bgm", bgm_volume)
	se_volume = cf.get_value("audio", "se", se_volume)
	master_volume = cf.get_value("audio", "master", master_volume)
	fullscreen = cf.get_value("video", "fullscreen", fullscreen)

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("play", "text_speed", text_speed)
	cf.set_value("play", "auto_interval", auto_interval)
	cf.set_value("play", "skip_all", skip_all)
	cf.set_value("play", "font_scale", font_scale)
	cf.set_value("play", "effect_level", effect_level)
	cf.set_value("audio", "bgm", bgm_volume)
	cf.set_value("audio", "se", se_volume)
	cf.set_value("audio", "master", master_volume)
	cf.set_value("video", "fullscreen", fullscreen)
	cf.save(PATH)
	changed.emit()

func apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
