extends Control
## 选项面板：居中竖排按钮。

signal chosen(index: int)

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")

var _root: VBoxContainer
var _buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var wrap := Kit.panel(Color(0.031, 0.039, 0.055, 0.82), 14, UI.C_LINE_SOFT, 1, 30, 26)
	center.add_child(wrap)

	_root = Kit.vbox(16)
	wrap.add_child(_root)

func present(options: Array) -> void:
	for b in _buttons:
		if is_instance_valid(b):
			b.queue_free()
	_buttons.clear()
	for i in range(options.size()):
		var o: Dictionary = options[i]
		var b := Kit.button(str(o.get("text", "…")), 24, 680)
		b.custom_minimum_size = Vector2(680, 62)
		b.pressed.connect(_on_pressed.bind(i))
		_root.add_child(b)
		_buttons.append(b)
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	if not _buttons.is_empty():
		_buttons[0].grab_focus()

func dismiss() -> void:
	visible = false
	for b in _buttons:
		if is_instance_valid(b):
			b.queue_free()
	_buttons.clear()

func _on_pressed(index: int) -> void:
	AudioManager.play_se("select")
	dismiss()
	chosen.emit(index)
