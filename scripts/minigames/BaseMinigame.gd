class_name BaseMinigame
extends Control

## Clase base renovada para minijuegos interactivos y animados de Artemis II.
## Incluye diseño centrado, paleta vibrante por capítulo, lienzo 2D animado y retroalimentación visual.

signal finished(success: bool)

var panel: PanelContainer
var content_box: VBoxContainer
var title_lbl: Label
var subtitle_lbl: Label
var status_lbl: Label
var status_card: PanelContainer
var _accent_col: Color = UITheme.CYAN
var _pulse_time: float = 0.0
var _canvases: Array[Control] = []

func _build_shell(title_txt: String, subtitle_txt: String, panel_size: Vector2 = Vector2(820, 560), accent_col: Color = UITheme.CYAN, badge_txt: String = "SIMULADOR ARTEMIS II") -> void:
	_accent_col = accent_col
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.get_theme()

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.012, 0.022, 0.045, 0.84)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.042, 0.068, 0.125, 0.98), accent_col, 2, 14, 24, 20))
	center.add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(root_vbox)

	# Franja superior brillante + insignia + botón cerrar
	var accent_bar := ColorRect.new()
	accent_bar.custom_minimum_size = Vector2(0, 4)
	accent_bar.color = accent_col
	root_vbox.add_child(accent_bar)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(top_row)

	top_row.add_child(make_pill_badge(badge_txt, accent_col))

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer_l)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.theme_type_variation = &"GhostButton"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(func(): finished.emit(false))
	top_row.add_child(close_btn)

	title_lbl = UITheme.label(title_txt, 21, Color.WHITE, true, true)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title_lbl)

	subtitle_lbl = UITheme.label(subtitle_txt, 14, accent_col.lightened(0.25), false, true)
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(subtitle_lbl)

	root_vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var inner_center := CenterContainer.new()
	inner_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner_center)

	content_box = VBoxContainer.new()
	content_box.custom_minimum_size = Vector2(panel_size.x - 68.0, 0.0)
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation", 12)
	inner_center.add_child(content_box)

	status_card = PanelContainer.new()
	status_card.add_theme_stylebox_override("panel", UITheme.card(UITheme.GOLD, Color(0.035, 0.055, 0.10)))
	root_vbox.add_child(status_card)

	status_lbl = UITheme.label("Estado: Operación en curso.", 13, Color(1.0, 0.90, 0.45), true, true)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_card.add_child(status_lbl)

	# Animación de entrada vibrante (solo si hay árbol activo y sin modo headless instantáneo)
	panel.pivot_offset = panel_size * 0.5
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.20)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PROCESS:
		_pulse_time += get_process_delta_time()
		for c in _canvases:
			if is_instance_valid(c):
				c.queue_redraw()

func create_canvas(height: float, draw_cb: Callable) -> Control:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.box(Color(0.02, 0.038, 0.075, 0.98), _accent_col.darkened(0.25), 1, 10, 6, 6))
	frame.custom_minimum_size = Vector2(0, height)
	content_box.add_child(frame)

	var canvas := Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.custom_minimum_size = Vector2(0, height - 12.0)
	canvas.draw.connect(func(): draw_cb.call(canvas, _pulse_time))
	frame.add_child(canvas)
	_canvases.append(canvas)
	set_process(true)
	return canvas

func make_pill_badge(txt: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.box(col.darkened(0.68), col, 1, 12, 12, 4))
	var l := UITheme.label(txt, 12, col.lightened(0.45), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func make_centered_row(sep: int = 12) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", sep)
	content_box.add_child(row)
	return row

func make_action_btn(txt: String, col: Color, min_h: float = 46.0, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.add_theme_stylebox_override("normal", UITheme.box(col.darkened(0.48), col, 2, 8, 16, 10))
	b.add_theme_stylebox_override("hover", UITheme.box(col.darkened(0.28), col.lightened(0.3), 2, 8, 16, 10))
	b.add_theme_stylebox_override("pressed", UITheme.box(col.darkened(0.15), Color.WHITE, 2, 8, 16, 10))
	b.add_theme_stylebox_override("disabled", UITheme.box(Color(0.06, 0.08, 0.12), Color(0.16, 0.22, 0.30), 1, 8, 16, 10))
	return b

func set_bar_color(bar: ProgressBar, col: Color) -> void:
	bar.add_theme_stylebox_override("fill", UITheme.box(col, col.lightened(0.2), 0, 5, 0, 0))

func flash_feedback(col: Color, msg: String = "") -> void:
	if not msg.is_empty() and is_instance_valid(status_lbl):
		status_lbl.text = msg
		status_lbl.add_theme_color_override("font_color", col.lightened(0.25))
	if is_instance_valid(status_card):
		status_card.add_theme_stylebox_override("panel", UITheme.card(col, col.darkened(0.75)))
	if is_instance_valid(panel):
		var tw := create_tween()
		tw.tween_property(panel, "modulate", col.lerp(Color.WHITE, 0.72), 0.09)
		tw.tween_property(panel, "modulate", Color.WHITE, 0.22)

func draw_starfield(c: Control, t: float, count: int = 38) -> void:
	var s := c.size
	for i in range(count):
		var fx := fmod(float(i * 73 + 19), 97.0) / 97.0
		var fy := fmod(float(i * 41 + 11), 89.0) / 89.0
		var tw := 0.35 + 0.65 * absf(sin(t * 1.8 + float(i)))
		c.draw_circle(Vector2(fx * s.x, fy * s.y), 1.3 + fmod(float(i), 2.0) * 0.6, Color(0.85, 0.93, 1.0, tw * 0.7))

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			finished.emit(false)
