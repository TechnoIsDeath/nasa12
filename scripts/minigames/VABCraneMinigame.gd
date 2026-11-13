class_name VABCraneMinigame
extends BaseMinigame

## Capítulo 3: Grúa puente animada del VAB para apilar las 7 piezas del SLS Block 1 en orden real
## y verificar el TWR al despegue (> 1.2).

var _selected_part_id: String = ""
var _align_slider: HSlider
var _angle_slider: HSlider
var _stack_lbl: Label
var _twr_lbl: Label
var _twr_bar: ProgressBar
var _parts_box: HBoxContainer
var _umbilical_btn: Button
var _twr_btn: Button
var _umbilicals_connected: bool = false

func _ready() -> void:
	_build_shell(
		"VAB — GRÚA PUENTE Y ENSAMBLAJE DEL SLS BLOCK 1",
		"Elige la siguiente pieza de abajo hacia arriba (1 → 7), céntrala (0 ± 15 cm, 0° ± 3°) y acóplala sobre la plataforma.",
		Vector2(860, 620),
		Color(0.95, 0.52, 0.16),
		"CAP. 3 · ENSAMBLAJE SLS"
	)

	create_canvas(170.0, func(c: Control, t: float):
		var s := c.size
		var cx := s.x * 0.5
		var base_y := s.y - 20.0
		# Plataforma Lanzador Móvil + Torre de Servicio
		c.draw_rect(Rect2(cx - 110.0, base_y - 12.0, 220.0, 12.0), Color(0.32, 0.36, 0.44), true)
		c.draw_rect(Rect2(cx - 95.0, 16.0, 18.0, base_y - 28.0), Color(0.45, 0.50, 0.58), true)
		# Viga superior de grúa puente
		c.draw_rect(Rect2(40.0, 12.0, s.x - 80.0, 8.0), Color(0.95, 0.65, 0.18), true)

		# Piezas ya apiladas en colores reales
		var stacked := GameState.sls_stacked_parts
		if stacked.has("core_stage"):
			c.draw_rect(Rect2(cx - 16.0, base_y - 98.0, 32.0, 86.0), Color(0.86, 0.42, 0.14), true)
		if stacked.has("srb_left"):
			c.draw_rect(Rect2(cx - 32.0, base_y - 84.0, 13.0, 72.0), Color(0.94, 0.95, 0.98), true)
		if stacked.has("srb_right"):
			c.draw_rect(Rect2(cx + 19.0, base_y - 84.0, 13.0, 72.0), Color(0.94, 0.95, 0.98), true)
		if stacked.has("lvsa_icps"):
			c.draw_rect(Rect2(cx - 13.0, base_y - 116.0, 26.0, 18.0), Color(0.84, 0.86, 0.92), true)
		if stacked.has("msa_esm"):
			c.draw_rect(Rect2(cx - 11.0, base_y - 128.0, 22.0, 12.0), Color(0.28, 0.34, 0.46), true)
		if stacked.has("orion_cm"):
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - 12.0, base_y - 128.0), Vector2(cx + 12.0, base_y - 128.0), Vector2(cx + 7.0, base_y - 140.0), Vector2(cx - 7.0, base_y - 140.0)]), Color(0.95, 0.97, 1.0))
		if stacked.has("las"):
			c.draw_line(Vector2(cx, base_y - 140.0), Vector2(cx, base_y - 156.0), Color(1.0, 0.95, 0.95), 4.0)

		# Pieza activa colgando de la grúa (se mueve e inclina en vivo con los sliders!)
		if not _selected_part_id.is_empty():
			var ox := (_align_slider.value / 100.0) * 140.0
			var ang_deg := _angle_slider.value
			var aligned := (absf(_align_slider.value) <= 15.0 and absf(ang_deg) <= 3.0)
			var col_hook := UITheme.GREEN if aligned else UITheme.RED
			var hx := cx + ox
			c.draw_line(Vector2(hx, 20.0), Vector2(hx, 56.0), Color(0.85, 0.88, 0.95), 2.5)
			c.draw_circle(Vector2(hx, 20.0), 7.0, Color(0.95, 0.65, 0.18))
			var rad := deg_to_rad(ang_deg)
			var w := 28.0
			var h := 22.0
			var p_tl := Vector2(-w * 0.5, 0.0).rotated(rad) + Vector2(hx, 56.0)
			var p_tr := Vector2(w * 0.5, 0.0).rotated(rad) + Vector2(hx, 56.0)
			var p_br := Vector2(w * 0.5, h).rotated(rad) + Vector2(hx, 56.0)
			var p_bl := Vector2(-w * 0.5, h).rotated(rad) + Vector2(hx, 56.0)
			c.draw_colored_polygon(PackedVector2Array([p_tl, p_tr, p_br, p_bl]), col_hook)
			# Guía central verde
			c.draw_line(Vector2(cx, 22.0), Vector2(cx, base_y - 12.0), Color(0.35, 0.92, 0.55, 0.45 + 0.25 * sin(t * 4.0)), 1.5)
	)

	_stack_lbl = UITheme.label("", 14, Color.WHITE, true, true)
	_stack_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(_stack_lbl)

	_parts_box = make_centered_row(6)
	_parts_box.set("alignment", BoxContainer.ALIGNMENT_CENTER)

	var pos_lbl := UITheme.label("Alineación lateral de grúa (Objetivo: 0 cm, tolerancia ±15 cm):", 13, UITheme.CYAN, true)
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(pos_lbl)

	_align_slider = HSlider.new()
	_align_slider.min_value = -100.0
	_align_slider.max_value = 100.0
	_align_slider.value = 65.0
	_align_slider.value_changed.connect(func(v): pos_lbl.text = "Alineación lateral: %+.0f cm (Objetivo: ±15 cm)" % v)
	content_box.add_child(_align_slider)

	var ang_lbl := UITheme.label("Inclinación axial (Objetivo: 0°, tolerancia ±3°):", 13, UITheme.CYAN, true)
	ang_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(ang_lbl)

	_angle_slider = HSlider.new()
	_angle_slider.min_value = -25.0
	_angle_slider.max_value = 25.0
	_angle_slider.value = -14.0
	_angle_slider.value_changed.connect(func(v): ang_lbl.text = "Inclinación axial: %+.1f° (Objetivo: ±3°)" % v)
	content_box.add_child(_angle_slider)

	var drop_row := make_centered_row(10)
	var drop_btn := make_action_btn("🏗️ ACOPLAR PIEZA SELECCIONADA CON GRÚA", Color(0.95, 0.52, 0.16), 46.0, 360.0)
	drop_btn.pressed.connect(_on_drop_part)
	drop_row.add_child(drop_btn)

	var actions_row := make_centered_row(12)
	_umbilical_btn = make_action_btn("🔌 CONECTAR UMBILICALES", UITheme.CYAN, 42.0, 240.0)
	_umbilical_btn.disabled = true
	_umbilical_btn.pressed.connect(_on_connect_umbilicals)
	actions_row.add_child(_umbilical_btn)

	_twr_btn = make_action_btn("🚀 CALCULAR TWR Y CERTIFICAR", UITheme.GREEN, 42.0, 260.0)
	_twr_btn.disabled = true
	_twr_btn.pressed.connect(_on_verify_twr)
	actions_row.add_child(_twr_btn)

	_twr_lbl = UITheme.label("", 13, UITheme.GREEN, true)
	_twr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(_twr_lbl)

	_twr_bar = ProgressBar.new()
	_twr_bar.max_value = 2.0
	_twr_bar.custom_minimum_size = Vector2(0, 18)
	content_box.add_child(_twr_bar)

	_refresh_ui()

func _refresh_ui() -> void:
	for c in _parts_box.get_children():
		c.queue_free()

	var parts: Array[Dictionary] = CatalogData.get_sls_parts()
	for p in parts:
		var pid: String = String(p["id"])
		var placed: bool = GameState.sls_stacked_parts.has(pid)
		var col := UITheme.GREEN if placed else (UITheme.GOLD if pid == _selected_part_id else UITheme.CYAN)
		var b := make_action_btn("%d. %s" % [int(p["order"]), String(p["short"])], col, 38.0, 96.0)
		b.disabled = placed
		b.pressed.connect(func():
			_selected_part_id = pid
			_align_slider.value = randf_range(-75.0, 75.0)
			_angle_slider.value = randf_range(-18.0, 18.0)
			flash_feedback(UITheme.CYAN, "Seleccionado: %s — %s" % [String(p["name"]), String(p["desc"])])
			_refresh_ui()
		)
		_parts_box.add_child(b)

	var eval: Dictionary = AeroPhysics.evaluate_sls_stack(GameState.sls_stacked_parts)
	_stack_lbl.text = "Piezas apiladas (%d/7): %s" % [
		GameState.sls_stacked_parts.size(),
		", ".join(GameState.sls_stacked_parts) if not GameState.sls_stacked_parts.is_empty() else "Ninguna — elige primero los SRB (1 y 2)"
	]
	var twr_val := float(eval["twr"])
	_twr_lbl.text = "Masa actual: %.0f t | Empuje despegue: %.0f kN | TWR: %.2f (Objetivo > 1.20)" % [
		float(eval["total_mass_kg"]) / 1000.0,
		float(eval["liftoff_thrust_kn"]),
		twr_val
	]
	_twr_bar.value = clampf(twr_val, 0.0, 2.0)
	set_bar_color(_twr_bar, UITheme.GREEN if twr_val >= 1.2 else UITheme.GOLD)

	var all_7: bool = GameState.sls_stacked_parts.size() >= 7
	_umbilical_btn.disabled = not all_7 or _umbilicals_connected
	_twr_btn.disabled = not (all_7 and _umbilicals_connected)

func _on_drop_part() -> void:
	if _selected_part_id.is_empty():
		flash_feedback(UITheme.GOLD, "Selecciona primero una pieza de la fila superior.")
		return

	var parts: Array[Dictionary] = CatalogData.get_sls_parts()
	var expected_idx: int = GameState.sls_stacked_parts.size()
	if expected_idx >= parts.size():
		return

	var is_order_ok: bool = false
	if expected_idx < 2 and _selected_part_id in ["srb_left", "srb_right"]:
		is_order_ok = true
	elif String(parts[expected_idx]["id"]) == _selected_part_id:
		is_order_ok = true

	if not is_order_ok:
		GameState.record_error(3, "vab_stack", "Orden de apilado incorrecto en VAB.", "El cohete se apila de abajo hacia arriba: SRB -> Etapa Central -> ICPS -> ESM -> Orion -> LAS.")
		flash_feedback(UITheme.RED, "¡Orden incorrecto! Apila de abajo hacia arriba (1 → 7).")
		return

	if absf(_align_slider.value) > 15.0 or absf(_angle_slider.value) > 3.0:
		GameState.record_error(3, "vab_stack", "Desalineación de grúa al acoplar %s." % _selected_part_id, "Las tolerancias estructurales exigen centrado (±15 cm) y verticalidad (±3°).")
		flash_feedback(UITheme.RED, "¡Desalineado! Centra posición (±15 cm) y ángulo (±3°) hasta que brille en verde.")
		return

	GameState.sls_stacked_parts.append(_selected_part_id)
	ObjectiveManager.notify_event("stack_part:" + _selected_part_id)
	_selected_part_id = ""
	flash_feedback(UITheme.GREEN, "¡Pieza acoplada con precisión milimétrica!")
	_refresh_ui()

func _on_connect_umbilicals() -> void:
	_umbilicals_connected = true
	ObjectiveManager.mark_substep(1)
	flash_feedback(UITheme.CYAN, "Umbilicales de LH₂/LOX y telemetría conectados ✔ — Ahora calcula el TWR.")
	_refresh_ui()

func _on_verify_twr() -> void:
	var eval: Dictionary = AeroPhysics.evaluate_sls_stack(GameState.sls_stacked_parts)
	if bool(eval["safe_liftoff"]):
		ObjectiveManager.mark_substep(2)
		ObjectiveManager.notify_event("vab_complete_twr")
		finished.emit(true)
	else:
		flash_feedback(UITheme.RED, "TWR insuficiente (< 1.2).")
