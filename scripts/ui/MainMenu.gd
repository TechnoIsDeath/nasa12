class_name MainMenu
extends CanvasLayer

## Menú principal de Cosmic Blueprint: Misión Artemis
## Incluye portada animada, interfaz de 3 ranuras de partida estilo Cuphead / Hollow Knight y opciones.

signal play_slot_requested(slot: int, is_new_game: bool)
signal quit_requested()

var _pulse_time: float = 0.0
var _bg_canvas: Control
var _slot_canvases: Array[Control] = []

var _root_ctrl: Control
var _title_view: VBoxContainer
var _slots_view: VBoxContainer
var _options_view: VBoxContainer
var _slots_list: VBoxContainer

var _confirm_delete_slot: int = -1
var _hovered_slot: int = -1
var _current_view: String = "title"


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS

	_root_ctrl = Control.new()
	_root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_ctrl.theme = UITheme.get_theme()
	_root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_ctrl)

	# Lienzo espacial animado de fondo (estrellas, Tierra, Luna, cápsula Orion)
	_bg_canvas = Control.new()
	_bg_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_canvas.draw.connect(_draw_cosmic_backdrop)
	_root_ctrl.add_child(_bg_canvas)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	_root_ctrl.add_child(center)

	var stage := VBoxContainer.new()
	stage.custom_minimum_size = Vector2(960, 0)
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_theme_constant_override("separation", 12)
	center.add_child(stage)

	_build_title_view(stage)
	_build_slots_view(stage)
	_build_options_view(stage)

	show_view("title")


func _process(delta: float) -> void:
	if not visible:
		return
	_pulse_time += delta
	if is_instance_valid(_bg_canvas):
		_bg_canvas.queue_redraw()
	for c in _slot_canvases:
		if is_instance_valid(c):
			c.queue_redraw()


func show_menu(view_name: String = "title") -> void:
	_confirm_delete_slot = -1
	visible = true
	refresh_slots()
	show_view(view_name)


func hide_menu() -> void:
	visible = false


func show_view(view_name: String) -> void:
	_current_view = view_name
	_title_view.visible = (view_name == "title")
	_slots_view.visible = (view_name == "slots")
	_options_view.visible = (view_name == "options")
	if view_name == "slots":
		refresh_slots()

	var active_node: Control = _title_view if view_name == "title" else (_slots_view if view_name == "slots" else _options_view)
	active_node.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(active_node, "modulate:a", 1.0, 0.22)


func get_current_view() -> String:
	return _current_view


func _build_title_view(parent: VBoxContainer) -> void:
	_title_view = VBoxContainer.new()
	_title_view.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_view.add_theme_constant_override("separation", 14)
	parent.add_child(_title_view)

	# Emblema vectorial superior
	var crest := Control.new()
	crest.custom_minimum_size = Vector2(220, 108)
	crest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crest.draw.connect(func() -> void: _draw_artemis_crest(crest))
	_title_view.add_child(crest)

	var pill := _make_pill("NASA · ARTEMIS II · CAMPAÑA DE UN SOLO ROL", UITheme.CYAN)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_view.add_child(pill)

	var title := UITheme.label("COSMIC BLUEPRINT", 46, Color.WHITE, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_view.add_child(title)

	var sub := UITheme.label("MISIÓN ARTEMIS II — DE CASA A LA CARA OCULTA DE LA LUNA", 16, UITheme.GOLD, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_view.add_child(sub)

	var ornament := _make_filigree_divider(480.0, UITheme.CYAN)
	_title_view.add_child(ornament)

	var btn_box := VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_box.add_theme_constant_override("separation", 12)
	_title_view.add_child(btn_box)

	var play_btn := _make_menu_btn("▶   JUGAR  /  ARCHIVOS DE PARTIDA", UITheme.CYAN, Vector2(380, 56), 16)
	play_btn.pressed.connect(func() -> void: show_view("slots"))
	btn_box.add_child(play_btn)

	var opt_btn := _make_menu_btn("⚙   OPCIONES Y CONTROLES", UITheme.GOLD, Vector2(380, 48), 15)
	opt_btn.pressed.connect(func() -> void: show_view("options"))
	btn_box.add_child(opt_btn)

	var quit_btn := _make_menu_btn("✖   SALIR DEL SIMULADOR", UITheme.RED, Vector2(380, 46), 14)
	quit_btn.pressed.connect(func() -> void: quit_requested.emit())
	btn_box.add_child(quit_btn)

	var foot := UITheme.label("12 Capítulos · 43 Retos de Ingeniería y Vuelo · 44 Logros desbloqueables", 12, UITheme.TEXT_DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_view.add_child(foot)


func _build_slots_view(parent: VBoxContainer) -> void:
	_slots_view = VBoxContainer.new()
	_slots_view.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_view.add_theme_constant_override("separation", 10)
	parent.add_child(_slots_view)

	var hdr_pill := _make_pill("SELECCIÓN DE PARTIDA · ESTILO CUPHEAD & HOLLOW KNIGHT", UITheme.GOLD)
	hdr_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slots_view.add_child(hdr_pill)

	var ttl := UITheme.label("ELIGE TU ARCHIVO DE MISIÓN", 30, Color.WHITE, true)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots_view.add_child(ttl)

	_slots_view.add_child(_make_filigree_divider(640.0, UITheme.GOLD))

	_slots_list = VBoxContainer.new()
	_slots_list.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slots_list.add_theme_constant_override("separation", 12)
	_slots_view.add_child(_slots_list)

	_slots_view.add_child(_make_filigree_divider(640.0, UITheme.CYAN))

	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	back_row.add_theme_constant_override("separation", 16)
	_slots_view.add_child(back_row)

	var back_btn := _make_menu_btn("⬅   VOLVER AL TÍTULO  [ESC]", UITheme.CYAN, Vector2(280, 44), 14)
	back_btn.pressed.connect(func() -> void: show_view("title"))
	back_row.add_child(back_btn)

	var hint_lbl := UITheme.label("Atajo: Pulsa [1], [2] o [3] para cargar una ranura", 12, UITheme.TEXT_DIM)
	back_row.add_child(hint_lbl)


func refresh_slots() -> void:
	if not is_instance_valid(_slots_list):
		return
	for c in _slots_list.get_children():
		_slots_list.remove_child(c)
		c.queue_free()
	_slot_canvases.clear()

	var summaries := SaveSystem.get_all_slot_summaries()
	for info in summaries:
		_slots_list.add_child(_create_slot_card(info))


func _create_slot_card(info: Dictionary) -> PanelContainer:
	var slot_num: int = int(info.get("slot", 1))
	var is_empty: bool = bool(info.get("empty", true))
	var roman: Array[String] = ["", "I", "II", "III"]
	var accent: Color = Color(0.45, 0.54, 0.72) if is_empty else (UITheme.GOLD if float(info.get("pct", 0.0)) >= 99.5 else UITheme.CYAN)
	var bg_col: Color = Color(0.032, 0.052, 0.098, 0.94) if is_empty else Color(0.045, 0.075, 0.145, 0.96)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(820, 118)
	card.add_theme_stylebox_override("panel", UITheme.box(bg_col, accent.darkened(0.15), 2, 14, 18, 12))
	card.mouse_entered.connect(func() -> void:
		_hovered_slot = slot_num
		card.add_theme_stylebox_override("panel", UITheme.box(bg_col.lightened(0.08), accent.lightened(0.25), 2, 14, 18, 12))
	)
	card.mouse_exited.connect(func() -> void:
		if _hovered_slot == slot_num:
			_hovered_slot = -1
		card.add_theme_stylebox_override("panel", UITheme.box(bg_col, accent.darkened(0.15), 2, 14, 18, 12))
	)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 18)
	card.add_child(hbox)

	# Emblema izquierdo (Vessel estilo Hollow Knight + anillo % estilo Cuphead)
	var emblem := Control.new()
	emblem.custom_minimum_size = Vector2(96, 92)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pct_val: float = float(info.get("pct", 0.0))
	emblem.draw.connect(func() -> void:
		_draw_slot_emblem(emblem, slot_num, is_empty, pct_val, accent, _hovered_slot == slot_num)
	)
	hbox.add_child(emblem)
	_slot_canvases.append(emblem)

	# Columna central de datos
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 4)
	hbox.add_child(mid)

	var top_line := HBoxContainer.new()
	top_line.add_theme_constant_override("separation", 10)
	mid.add_child(top_line)

	top_line.add_child(_make_pill("EXPEDICIÓN " + roman[slot_num], accent))

	if is_empty:
		var empty_lbl := UITheme.label("— RANURA VACÍA —", 19, UITheme.TEXT, true)
		top_line.add_child(empty_lbl)
		var sub_empty := UITheme.label("Sin misión iniciada. Comienza Artemis II desde el dormitorio en Casa (Cap. 0).", 13, UITheme.TEXT_DIM, false, true)
		mid.add_child(sub_empty)
	else:
		var ch: int = int(info.get("chapter", 0))
		var ch_name: String = String(info.get("chapter_name", ""))
		var title_lbl := UITheme.label("Cap. %d · %s" % [ch, ch_name], 18, Color.WHITE, true)
		top_line.add_child(title_lbl)

		var obj_lbl := UITheme.label("Objetivo actual: %s" % String(info.get("objective_title", "")), 13, accent.lightened(0.32), false, true)
		mid.add_child(obj_lbl)

		var stats_row := HBoxContainer.new()
		stats_row.add_theme_constant_override("separation", 14)
		mid.add_child(stats_row)
		stats_row.add_child(_make_stat_chip("Retos", "%d / %d" % [int(info.get("completed_count", 0)), int(info.get("total_count", 43))], UITheme.CYAN))
		stats_row.add_child(_make_stat_chip("Logros", "★ %d / %d" % [int(info.get("achievements_count", 0)), int(info.get("achievements_total", 44))], UITheme.GOLD))
		stats_row.add_child(_make_stat_chip("Tiempo", SaveSystem.format_time(float(info.get("mission_time_sec", 0.0))), UITheme.GREEN))
		stats_row.add_child(_make_stat_chip("Zona", String(info.get("zone", "HOME")), UITheme.PURPLE))

		var ts_lbl := UITheme.label("Último guardado: %s   ·   Errores: %d" % [String(info.get("timestamp", "")), int(info.get("errors_count", 0))], 11, UITheme.TEXT_DIM)
		mid.add_child(ts_lbl)

	# Columna derecha de acciones
	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	hbox.add_child(actions)

	if _confirm_delete_slot == slot_num and not is_empty:
		var warn := UITheme.label("¿Borrar partida?", 12, UITheme.RED, true)
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		actions.add_child(warn)

		var c_row := HBoxContainer.new()
		c_row.add_theme_constant_override("separation", 6)
		actions.add_child(c_row)

		var yes_b := _make_menu_btn("Sí, borrar", UITheme.RED, Vector2(96, 36), 12)
		yes_b.pressed.connect(func() -> void:
			SaveSystem.delete_save(slot_num)
			_confirm_delete_slot = -1
			refresh_slots()
		)
		var no_b := _make_menu_btn("Cancelar", UITheme.CYAN, Vector2(88, 36), 12)
		no_b.pressed.connect(func() -> void:
			_confirm_delete_slot = -1
			refresh_slots()
		)
		c_row.add_child(yes_b)
		c_row.add_child(no_b)
	else:
		var play_txt := "▶  NUEVA PARTIDA" if is_empty else "▶  CONTINUAR"
		var play_col := UITheme.GREEN if is_empty else accent
		var go_btn := _make_menu_btn(play_txt, play_col, Vector2(188, 44), 14)
		go_btn.pressed.connect(func() -> void:
			play_slot_requested.emit(slot_num, is_empty)
		)
		actions.add_child(go_btn)

		if not is_empty:
			var del_btn := _make_menu_btn("🗑  BORRAR ARCHIVO", UITheme.RED, Vector2(188, 32), 12)
			del_btn.pressed.connect(func() -> void:
				_confirm_delete_slot = slot_num
				refresh_slots()
			)
			actions.add_child(del_btn)

	return card


func _build_options_view(parent: VBoxContainer) -> void:
	_options_view = VBoxContainer.new()
	_options_view.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_view.add_theme_constant_override("separation", 12)
	parent.add_child(_options_view)

	var opt_panel := PanelContainer.new()
	opt_panel.custom_minimum_size = Vector2(680, 0)
	opt_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	opt_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.068, 0.13, 0.96), UITheme.GOLD, 2, 14, 24, 20))
	_options_view.add_child(opt_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	opt_panel.add_child(vbox)

	var h := UITheme.label("OPCIONES Y CONTROLES DE MISIÓN", 22, Color.WHITE, true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(h)
	vbox.add_child(HSeparator.new())

	# Sensibilidad del ratón
	var sens_row := HBoxContainer.new()
	sens_row.add_theme_constant_override("separation", 12)
	vbox.add_child(sens_row)
	var sens_lbl := UITheme.label("Sensibilidad del Ratón: %.2f" % GameState.mouse_sensitivity, 14, UITheme.CYAN, true)
	sens_lbl.custom_minimum_size = Vector2(240, 0)
	sens_row.add_child(sens_lbl)

	var slider := HSlider.new()
	slider.min_value = 0.06
	slider.max_value = 0.40
	slider.step = 0.02
	slider.value = GameState.mouse_sensitivity
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float) -> void:
		GameState.mouse_sensitivity = v
		sens_lbl.text = "Sensibilidad del Ratón: %.2f" % v
	)
	sens_row.add_child(slider)

	# Filtro CRT MOCR
	var crt_row := HBoxContainer.new()
	crt_row.add_theme_constant_override("separation", 12)
	vbox.add_child(crt_row)
	var crt_chk := CheckButton.new()
	crt_chk.text = "Activar efecto CRT en la sala Control de Misión (MOCR)"
	crt_chk.button_pressed = GameState.crt_enabled
	crt_chk.toggled.connect(func(on: bool) -> void:
		GameState.crt_enabled = on
	)
	crt_row.add_child(crt_chk)

	vbox.add_child(HSeparator.new())

	var ctrl_title := UITheme.label("CONTROLES EN CAMPO", 14, UITheme.GOLD, true)
	vbox.add_child(ctrl_title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	var binds := [
		["WASD / Flechas", "Desplazarse"],
		["Shift + Espacio", "Correr / Saltar"],
		["E", "Interactuar con consolas, carteles y naves"],
		["V / F", "Alternar 1.ª/3.ª persona · Linterna"],
		["H / G / L", "Briefing científico · Glosario · Logros"],
		["ESC", "Abrir mini menú de pausa o cerrar panel"]
	]
	for b in binds:
		grid.add_child(UITheme.key_hint(b[0], b[1]))

	var back := _make_menu_btn("⬅   VOLVER AL MENÚ  [ESC]", UITheme.GOLD, Vector2(260, 44), 14)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: show_view("title"))
	vbox.add_child(back)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE and _current_view != "title":
			get_viewport().set_input_as_handled()
			_confirm_delete_slot = -1
			show_view("title")
		elif _current_view == "slots":
			if k.keycode == KEY_1:
				get_viewport().set_input_as_handled()
				play_slot_requested.emit(1, not SaveSystem.has_save(1))
			elif k.keycode == KEY_2:
				get_viewport().set_input_as_handled()
				play_slot_requested.emit(2, not SaveSystem.has_save(2))
			elif k.keycode == KEY_3:
				get_viewport().set_input_as_handled()
				play_slot_requested.emit(3, not SaveSystem.has_save(3))


func _draw_cosmic_backdrop() -> void:
	var sz := _bg_canvas.size
	_bg_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.015, 0.025, 0.055, 1.0))

	# Halo azul atmosférico inferior
	var earth_c := Vector2(sz.x * 0.16, sz.y * 1.12)
	_bg_canvas.draw_circle(earth_c, sz.y * 0.44, Color(0.05, 0.18, 0.42, 0.35))
	_bg_canvas.draw_circle(earth_c, sz.y * 0.38, Color(0.06, 0.25, 0.56, 0.55))
	_bg_canvas.draw_arc(earth_c, sz.y * 0.40, -PI * 0.72, -PI * 0.08, 48, Color(0.32, 0.75, 1.0, 0.42), 3.0)

	# Disco lunar en esquina superior derecha
	var moon_c := Vector2(sz.x * 0.86, sz.y * 0.22)
	_bg_canvas.draw_circle(moon_c, 64.0, Color(0.76, 0.79, 0.84, 0.28))
	_bg_canvas.draw_circle(moon_c, 50.0, Color(0.84, 0.86, 0.90, 0.65))
	_bg_canvas.draw_circle(moon_c + Vector2(-14, -10), 10.0, Color(0.62, 0.65, 0.72, 0.6))
	_bg_canvas.draw_circle(moon_c + Vector2(18, 12), 14.0, Color(0.62, 0.65, 0.72, 0.5))

	# Estrellas parpadeantes
	for i in range(75):
		var sx := fmod(float(i * 97 + 23), 149.0) / 149.0 * sz.x
		var sy := fmod(float(i * 53 + 17), 127.0) / 127.0 * sz.y
		var tw := 0.28 + 0.72 * absf(sin(_pulse_time * 1.3 + float(i) * 0.7))
		var r := 1.1 + fmod(float(i), 3.0) * 0.65
		_bg_canvas.draw_circle(Vector2(sx, sy), r, Color(0.84, 0.92, 1.0, tw * 0.72))

	# Órbita en ocho translunar sutil + nave Orion viajando
	var pts := PackedVector2Array()
	for i in range(65):
		var u := float(i) / 64.0 * TAU
		var px := lerpf(earth_c.x + 80.0, moon_c.x + 18.0, 0.5 - 0.5 * cos(u))
		var py := lerpf(sz.y * 0.72, moon_c.y, 0.5 - 0.5 * cos(u)) + sin(u) * 58.0
		pts.append(Vector2(px, py))
	_bg_canvas.draw_polyline(pts, Color(UITheme.CYAN.r, UITheme.CYAN.g, UITheme.CYAN.b, 0.22), 2.0)
	var orb_idx := mini(64, int(fmod(_pulse_time * 9.0, 64.0)))
	_bg_canvas.draw_circle(pts[orb_idx], 4.5, UITheme.GOLD)


func _draw_artemis_crest(c: Control) -> void:
	var mid := c.size * 0.5
	var glow := 0.65 + 0.35 * sin(_pulse_time * 2.5)
	c.draw_arc(mid, 44.0, 0.0, TAU, 48, Color(UITheme.CYAN.r, UITheme.CYAN.g, UITheme.CYAN.b, 0.65 * glow), 2.5)
	c.draw_arc(mid, 34.0, -PI * 0.85, PI * 0.15, 32, UITheme.GOLD, 2.5)
	# Silueta chevron "A" de Artemis
	c.draw_line(mid + Vector2(-20, 22), mid + Vector2(0, -28), Color.WHITE, 4.0)
	c.draw_line(mid + Vector2(0, -28), mid + Vector2(20, 22), Color.WHITE, 4.0)
	c.draw_arc(mid + Vector2(0, 12), 28.0, PI * 1.15, PI * 1.85, 20, UITheme.RED, 3.0)
	c.draw_circle(mid + Vector2(18, -18), 5.0, Color(0.88, 0.90, 0.94))


func _draw_slot_emblem(c: Control, slot_num: int, is_empty: bool, pct: float, accent: Color, is_hovered: bool) -> void:
	var mid := c.size * 0.5
	var pulse := sin(_pulse_time * 3.0 + float(slot_num))
	var outer_r := 36.0 + (2.5 if is_hovered else 0.0)

	if is_empty:
		c.draw_arc(mid, outer_r, 0.0, TAU, 36, Color(accent.r, accent.g, accent.b, 0.35 + 0.15 * pulse), 2.0)
		c.draw_circle(mid, 18.0, Color(0.08, 0.12, 0.20, 0.9))
		c.draw_string(ThemeDB.fallback_font, mid + Vector2(-24, 6), "VACÍA", HORIZONTAL_ALIGNMENT_CENTER, 48, 11, UITheme.TEXT_DIM)
	else:
		# Fondo estilo sello Cuphead + anillo Hollow Knight
		c.draw_circle(mid, outer_r, Color(0.06, 0.10, 0.18, 0.95))
		c.draw_arc(mid, outer_r, 0.0, TAU, 48, Color(0.20, 0.28, 0.42), 5.0)
		var end_ang := -PI * 0.5 + TAU * clampf(pct / 100.0, 0.02, 1.0)
		c.draw_arc(mid, outer_r, -PI * 0.5, end_ang, 48, accent, 5.5)
		c.draw_string(ThemeDB.fallback_font, mid + Vector2(-28, 5), "%d%%" % int(roundf(pct)), HORIZONTAL_ALIGNMENT_CENTER, 56, 17, Color.WHITE)
		# Diamantes ornamentales laterales
		c.draw_circle(mid + Vector2(0, -outer_r), 3.5, UITheme.GOLD)
		c.draw_circle(mid + Vector2(0, outer_r), 3.5, UITheme.GOLD)


func _make_filigree_divider(width: float, col: Color) -> Control:
	var div := Control.new()
	div.custom_minimum_size = Vector2(width, 16)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	div.draw.connect(func() -> void:
		var mid := div.size * 0.5
		div.draw_line(Vector2(0, mid.y), Vector2(mid.x - 16, mid.y), Color(col.r, col.g, col.b, 0.45), 1.5)
		div.draw_line(Vector2(mid.x + 16, mid.y), Vector2(div.size.x, mid.y), Color(col.r, col.g, col.b, 0.45), 1.5)
		div.draw_colored_polygon(PackedVector2Array([
			Vector2(mid.x, mid.y - 6), Vector2(mid.x + 7, mid.y), Vector2(mid.x, mid.y + 6), Vector2(mid.x - 7, mid.y)
		]), col)
	)
	return div


func _make_pill(txt: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.box(col.darkened(0.68), col, 1, 12, 12, 4))
	var l := UITheme.label(txt, 11, col.lightened(0.45), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _make_stat_chip(k: String, v: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.box(Color(0.05, 0.08, 0.14), col.darkened(0.25), 1, 8, 8, 3))
	var l := UITheme.label("%s: %s" % [k, v], 11, col.lightened(0.32), true)
	p.add_child(l)
	return p


func _make_menu_btn(txt: String, col: Color, min_sz: Vector2, font_sz: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = min_sz
	b.add_theme_font_size_override("font_size", font_sz)
	b.add_theme_stylebox_override("normal", UITheme.box(col.darkened(0.55), col, 2, 10, 16, 8))
	b.add_theme_stylebox_override("hover", UITheme.box(col.darkened(0.32), col.lightened(0.35), 2, 10, 16, 8))
	b.add_theme_stylebox_override("pressed", UITheme.box(col.darkened(0.18), Color.WHITE, 2, 10, 16, 8))
	return b
