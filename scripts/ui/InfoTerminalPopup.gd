class_name InfoTerminalPopup
extends Control

## Ventana emergente interactiva para objetos narrativos al pulsar [E]:
## Portátil (Correo NASA), Carteles del Campus y Terminal de Briefing Artemis II.

signal closed(confirmed: bool)

var header_lbl: Label
var title_lbl: Label
var body_lbl: RichTextLabel
var confirm_btn: Button
var _callback: Callable

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.get_theme()
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.025, 0.05, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	panel.add_theme_stylebox_override("panel", UITheme.box(UITheme.PANEL, UITheme.CYAN, 2, 10, 22, 18))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var top := HBoxContainer.new()
	vbox.add_child(top)

	var hcol := VBoxContainer.new()
	hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hcol)

	header_lbl = UITheme.label("TERMINAL NASA", 12, UITheme.CYAN, true)
	hcol.add_child(header_lbl)
	title_lbl = UITheme.label("", 20, Color.WHITE, true, true)
	hcol.add_child(title_lbl)

	var x_btn := Button.new()
	x_btn.text = "✕"
	x_btn.theme_type_variation = &"GhostButton"
	x_btn.custom_minimum_size = Vector2(36, 36)
	x_btn.pressed.connect(func(): _close(false))
	top.add_child(x_btn)

	vbox.add_child(HSeparator.new())

	body_lbl = RichTextLabel.new()
	body_lbl.bbcode_enabled = true
	body_lbl.fit_content = true
	body_lbl.custom_minimum_size = Vector2(580, 180)
	body_lbl.add_theme_font_size_override("normal_font_size", 15)
	vbox.add_child(body_lbl)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)

	confirm_btn = Button.new()
	confirm_btn.theme_type_variation = &"PrimaryButton"
	confirm_btn.custom_minimum_size = Vector2(220, 42)
	confirm_btn.pressed.connect(func(): _close(true))
	footer.add_child(confirm_btn)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			get_viewport().set_input_as_handled()
			_close(k.keycode != KEY_ESCAPE)

func show_info(hdr: String, ttl: String, bbcode_body: String, btn_txt: String, on_confirm: Callable = Callable()) -> void:
	header_lbl.text = hdr
	title_lbl.text = ttl
	body_lbl.text = bbcode_body
	confirm_btn.text = btn_txt
	_callback = on_confirm
	visible = true
	confirm_btn.grab_focus.call_deferred()

func hide_popup() -> void:
	_close(false)

func _close(confirmed: bool) -> void:
	if not visible:
		return
	visible = false
	if confirmed and _callback.is_valid():
		_callback.call()
	_callback = Callable()
	closed.emit(confirmed)
