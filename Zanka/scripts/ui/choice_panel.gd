extends Control
## 选项面板：居中竖排按钮。
##
## 动画（刻意做短，总时长都在 0.3 秒内，不拖节奏）：
##   出现 —— 整块渐入 0.16s，同时每个选项错开 0.03s 从左侧轻轻顶出来
##   选择 —— 整块渐出 0.14s，**渐出结束之后**才通知剧情继续
##          （否则点完立刻切走，没有收尾感）
## 渐出期间用 _closing 挡住连点。

signal chosen(index: int)

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")

const FADE_IN := 0.16        ## 整块渐入
const FADE_OUT := 0.14       ## 整块渐出
const ITEM_DELAY := 0.03     ## 选项之间错开的间隔
const ITEM_TIME := 0.20      ## 单个选项淡入 / 顶出的时长

var _root: VBoxContainer
var _buttons: Array[Button] = []
var _closing: bool = false
var _tw: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# 磨砂选项板：暖白半透明 + 大圆角，选项用列表式行（悬停出朱色左短棒）
	var wrap := Kit.panel(UI.C_BOX_SOFT, UI.R_PANEL, UI.C_LINE, 1, 30, 24)
	UI.apply_paper(wrap)
	center.add_child(wrap)

	_root = Kit.vbox(6)
	wrap.add_child(_root)

func present(options: Array) -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_closing = false
	for b in _buttons:
		if is_instance_valid(b):
			b.queue_free()
	_buttons.clear()
	for i in range(options.size()):
		var o: Dictionary = options[i]
		var b := Kit.row_button(str(o.get("text", "…")), 24, 640)
		b.custom_minimum_size = Vector2(640, 58)
		b.pressed.connect(_on_pressed.bind(i))
		_root.add_child(b)
		_buttons.append(b)
	visible = true

	# 整块渐入
	modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, FADE_IN)

	# 每个选项错开一点点「顶出来」：透明度 + 轻微横向拉伸
	for i in range(_buttons.size()):
		var b: Button = _buttons[i]
		b.modulate.a = 0.0
		b.pivot_offset = Vector2(0.0, b.custom_minimum_size.y * 0.5)
		b.scale = Vector2(0.985, 0.88)
		var t := create_tween()
		if i > 0:
			t.tween_interval(ITEM_DELAY * float(i))
		t.set_parallel(true)
		t.tween_property(b, "modulate:a", 1.0, ITEM_TIME)
		t.tween_property(b, "scale", Vector2.ONE, ITEM_TIME + 0.06) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if not _buttons.is_empty():
		_buttons[0].grab_focus()

## 立刻收起（不播动画）。给「返回标题」「读档」这类需要马上清场的场合用。
func dismiss() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
	visible = false
	for b in _buttons:
		if is_instance_valid(b):
			b.queue_free()
	_buttons.clear()

func _on_pressed(index: int) -> void:
	if _closing:
		return                    # 正在渐出，忽略连点
	_closing = true
	AudioManager.play_se("select")
	if not visible:
		chosen.emit(index)
		return
	# 先渐出，渐完再让剧情继续
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	await _tw.finished
	visible = false
	for b in _buttons:
		if is_instance_valid(b):
			b.queue_free()
	_buttons.clear()
	chosen.emit(index)
