extends Control
## 通用弹窗外壳：黑幕 + 居中面板 + 标题栏 + 关闭按钮。
## 用「组合」而不是继承，避免 _ready 覆盖带来的初始化顺序问题。

signal close_requested

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")

var body: VBoxContainer
var footer: HBoxContainer
var _title: Label
var _panel: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(Kit.dim(0.76))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = Kit.panel(Color(0.043, 0.051, 0.071, 0.975), 16, UI.C_LINE, 1, 30, 24)
	_panel.custom_minimum_size = Vector2(940, 0)
	center.add_child(_panel)

	var v := Kit.vbox(16)
	_panel.add_child(v)

	var head := Kit.hbox(12)
	_title = Kit.label("", 32, UI.C_PAPER)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	var x := Kit.button("✕", 24)
	x.custom_minimum_size = Vector2(52, 44)
	x.pressed.connect(close)
	head.add_child(x)
	v.add_child(head)

	var line := ColorRect.new()
	line.color = UI.C_LINE_SOFT
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)

	body = Kit.vbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)

	footer = Kit.hbox(12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(footer)

func set_title(t: String) -> void:
	_title.text = t

func open() -> void:
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.16)

func close() -> void:
	visible = false
	close_requested.emit()

func is_open() -> bool:
	return visible

func clear_body() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	for c in footer.get_children():
		footer.remove_child(c)
		c.queue_free()
