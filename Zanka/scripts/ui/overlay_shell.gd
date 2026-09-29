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

	add_child(Kit.dim(0.70))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = Kit.panel(UI.C_BOX, UI.R_PANEL, UI.C_LINE, 1, 30, 24)
	_panel.custom_minimum_size = Vector2(940, 0)
	UI.apply_paper(_panel)        # 和纸纸纹
	center.add_child(_panel)

	var v := Kit.vbox(16)
	_panel.add_child(v)

	var head := Kit.hbox(12)
	_title = Kit.label("", 32, UI.C_TEXT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	# 用「关闭」而不是「✕」：中文字体是子集化的，✕(U+2715) 不在子集里会渲染成豆腐块
	var x := Kit.button("关闭", 22)
	x.custom_minimum_size = Vector2(88, 44)
	x.pressed.connect(close)
	head.add_child(x)
	v.add_child(head)

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
