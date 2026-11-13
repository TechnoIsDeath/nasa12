class_name TrainingMinigames
extends BaseMinigame

## Minijuegos del Capítulo 2 (Entrenamiento): Centrífuga 3g->5g, Traje OCSS y Leyes de Newton.
## Rediseño interactivo, animado, colorido y centrado.

var mode: String = ""

# Centrífuga
var _g_level: float = 3.0
var _consciousness: float = 100.0
var _cursor: float = 0.0
var _cursor_dir: float = 1.0
var _hits: int = 0
var _cent_angle: float = 0.0
var _cent_bar: ProgressBar
var _consc_bar: ProgressBar
var _g_lbl: Label

# OCSS
var _ocss_step: int = 0
var _ocss_pressure: float = 101.3

# Newton
var _newton_q: int = 0

static func create(challenge_mode: String) -> TrainingMinigames:
	var m := TrainingMinigames.new()
	m.mode = challenge_mode
	return m

func _ready() -> void:
	match mode:
		"centrifuge":
			_setup_centrifuge()
		"ocss":
			_setup_ocss()
		"newton":
			_setup_newton()

func _setup_centrifuge() -> void:
	_build_shell(
		"CENTRÍFUGA HUMANA (3g → 5g)",
		"Pulsa [RESPIRAR ANTI-G] o la barra [ESPACIO] justo en la zona verde (38%–68%) para mantener el flujo sanguíneo.",
		Vector2(820, 580),
		Color(0.95, 0.56, 0.16),
		"CAP. 2 · ENTRENAMIENTO FÍSICO"
	)

	create_canvas(148.0, func(c: Control, t: float):
		var s := c.size
		# Fondo radial y brazo giratorio de centrífuga
		var cx := 105.0
		var cy := s.y * 0.5
		c.draw_circle(Vector2(cx, cy), 56.0, Color(0.08, 0.14, 0.24))
		c.draw_arc(Vector2(cx, cy), 56.0, 0.0, TAU, 36, Color(0.95, 0.56, 0.16, 0.65), 2.5)
		var arm_end := Vector2(cx + cos(_cent_angle) * 48.0, cy + sin(_cent_angle) * 48.0)
		c.draw_line(Vector2(cx, cy), arm_end, Color(0.95, 0.65, 0.22), 5.0)
		c.draw_circle(Vector2(cx, cy), 9.0, Color(0.33, 0.77, 0.98))
		c.draw_circle(arm_end, 11.0, UITheme.GREEN if (_cursor >= 38.0 and _cursor <= 68.0) else Color(0.95, 0.35, 0.22))

		# Pista rítmica de gran visibilidad a la derecha
		var tx := 200.0
		var tw := maxf(220.0, s.x - 230.0)
		var ty := cy - 18.0
		var th := 36.0
		c.draw_rect(Rect2(tx, ty, tw, th), Color(0.08, 0.13, 0.22), true)
		# Zona verde dulce (38% - 68%)
		var zx0 := tx + tw * 0.38
		var zw := tw * 0.30
		var pulse_g := 0.70 + 0.30 * absf(sin(t * 5.0))
		c.draw_rect(Rect2(zx0, ty, zw, th), Color(0.20, 0.85, 0.48, 0.45 * pulse_g), true)
		c.draw_rect(Rect2(zx0, ty, zw, th), UITheme.GREEN, false, 2.5)
		# Cursor brillante
		var cur_x := tx + tw * (_cursor / 100.0)
		var in_zone := (_cursor >= 38.0 and _cursor <= 68.0)
		var cur_col := UITheme.GREEN.lightened(0.25) if in_zone else UITheme.CYAN
		c.draw_rect(Rect2(cur_x - 6.0, ty - 6.0, 12.0, th + 12.0), cur_col, true)
		c.draw_line(Vector2(tx, cy - 32.0), Vector2(tx + tw, cy - 32.0), Color(0.25, 0.35, 0.50), 1.0)
		for hit_i in range(5):
			var col_h := UITheme.GREEN if hit_i < _hits else Color(0.20, 0.26, 0.36)
			c.draw_circle(Vector2(tx + 24.0 + float(hit_i) * 34.0, cy + 44.0), 10.0, col_h)
	)

	_g_lbl = UITheme.label("Aceleración actual: 3.0 g   |   Ciclos completados: 0 / 5", 17, UITheme.GOLD, true)
	_g_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(_g_lbl)

	var c_lbl := UITheme.label("Consciencia Cerebral (Flujo Sanguíneo):", 13, UITheme.TEXT_DIM, true)
	c_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(c_lbl)

	_consc_bar = ProgressBar.new()
	_consc_bar.value = 100.0
	_consc_bar.custom_minimum_size = Vector2(0, 24)
	set_bar_color(_consc_bar, UITheme.GREEN)
	content_box.add_child(_consc_bar)

	_cent_bar = ProgressBar.new()
	_cent_bar.value = 0.0
	_cent_bar.custom_minimum_size = Vector2(0, 18)
	set_bar_color(_cent_bar, UITheme.CYAN)
	content_box.add_child(_cent_bar)

	var row := make_centered_row()
	var btn := make_action_btn("⚡  MANIOBRA ANTI-G  [ESPACIO / CLIC EN ZONA VERDE]", UITheme.GREEN, 50.0, 440.0)
	btn.pressed.connect(_on_centrifuge_pulse)
	row.add_child(btn)
	flash_feedback(UITheme.GOLD, "Fórmula: a = F / m | Pulsa [ESPACIO] o clic cuando el cursor esté en verde (38%–68%).")

func _process(delta: float) -> void:
	if mode != "centrifuge":
		return
	var speed: float = 95.0 if _g_level < 4.5 else 135.0
	_cent_angle += delta * (_g_level * 1.4)
	_cursor += _cursor_dir * speed * delta
	if _cursor >= 100.0:
		_cursor = 100.0
		_cursor_dir = -1.0
	elif _cursor <= 0.0:
		_cursor = 0.0
		_cursor_dir = 1.0
	_cent_bar.value = _cursor
	_consciousness = maxf(0.0, _consciousness - (_g_level * 2.4) * delta)
	_consc_bar.value = _consciousness
	set_bar_color(_consc_bar, UITheme.GREEN if _consciousness > 55.0 else (UITheme.GOLD if _consciousness > 25.0 else UITheme.RED))
	if _consciousness <= 0.0:
		_consciousness = 100.0
		_hits = 0
		_g_level = 3.0
		GameState.record_error(2, "train_centrifuge", "Pérdida de consciencia (G-LOC) en centrífuga.", "A altas G la presión hidrostática reduce el riego cerebral.")
		flash_feedback(UITheme.RED, "¡G-LOC! Reiniciando prueba a 3.0 g...")

func _input(event: InputEvent) -> void:
	super._input(event)
	if mode == "centrifuge" and visible and event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode in [KEY_SPACE, KEY_ENTER]:
			get_viewport().set_input_as_handled()
			_on_centrifuge_pulse()

func _on_centrifuge_pulse() -> void:
	if _cursor >= 38.0 and _cursor <= 68.0:
		_hits += 1
		_consciousness = minf(100.0, _consciousness + 28.0)
		if _hits >= 2:
			_g_level = 5.0
		_g_lbl.text = "Aceleración actual: %.1f g   |   Ciclos completados: %d / 5" % [_g_level, _hits]
		flash_feedback(UITheme.GREEN, "¡Excelente maniobra anti-g! (%d/5)" % _hits)
		if _hits >= 5:
			ObjectiveManager.notify_event("centrifuge_passed")
			finished.emit(true)
	else:
		_consciousness = maxf(10.0, _consciousness - 18.0)
		flash_feedback(UITheme.RED, "Fuera de ritmo (%.0f%%). Apunta a la zona verde (38%%–68%%)." % _cursor)

func _setup_ocss() -> void:
	_build_shell(
		"CÁMARA DE VACÍO — TRAJE OCSS",
		"Ejecuta los 3 protocolos del traje espacial en el orden físico seguro antes de despresurizar.",
		Vector2(820, 560),
		UITheme.CYAN,
		"CAP. 2 · PRESIÓN Y VACÍO"
	)

	create_canvas(130.0, func(c: Control, t: float):
		var s := c.size
		var cx := s.x * 0.5
		var cy := s.y * 0.5
		# Esquema animado de 3 módulos: Sellado -> Presión -> O2
		var labels := ["1. SELLADO", "2. PRESIÓN 30 kPa", "3. FLUJO O₂"]
		for i in range(3):
			var bx := cx + (float(i) - 1.0) * 210.0
			var done := i < _ocss_step
			var active := i == _ocss_step
			var col := UITheme.GREEN if done else (UITheme.CYAN if active else Color(0.25, 0.32, 0.45))
			c.draw_rect(Rect2(bx - 76.0, cy - 38.0, 152.0, 76.0), col.darkened(0.65), true)
			c.draw_rect(Rect2(bx - 76.0, cy - 38.0, 152.0, 76.0), col, false, 3.0 if active else 1.5)
			c.draw_circle(Vector2(bx, cy), 14.0 + (sin(t * 5.0) * 2.5 if active else 0.0), col)
			if i < 2:
				c.draw_line(Vector2(bx + 76.0, cy), Vector2(bx + 134.0, cy), UITheme.GREEN if i < _ocss_step else Color(0.3, 0.4, 0.5), 3.0)
			c.draw_string(ThemeDB.fallback_font, Vector2(bx - 70.0, cy + 28.0), String(labels[i]), HORIZONTAL_ALIGNMENT_CENTER, 140, 12, col)
	)

	var steps := [
		{"id": 0, "label": "🔒 Comprobar sellos herméticos de casco y guantes", "col": UITheme.CYAN},
		{"id": 1, "label": "🌡️ Presurizar traje a 30 kPa (evitar límite de Armstrong)", "col": UITheme.GOLD},
		{"id": 2, "label": "💨 Verificar flujo continuo de O₂ puro", "col": UITheme.GREEN}
	]
	var order := [1, 2, 0]
	for idx in order:
		var s: Dictionary = steps[idx]
		var b := make_action_btn(String(s["label"]), s["col"], 50.0)
		b.pressed.connect(func():
			if int(s["id"]) == _ocss_step:
				b.disabled = true
				b.text = "✔ " + String(s["label"])
				ObjectiveManager.mark_substep(_ocss_step)
				_ocss_step += 1
				flash_feedback(UITheme.GREEN, "¡Paso %d/3 completado!" % _ocss_step)
				if _ocss_step >= 3:
					ObjectiveManager.notify_event("ocss_checked")
					finished.emit(true)
			else:
				GameState.record_error(2, "train_vacuum_ocss", "Orden incorrecto en verificación OCSS.", "Primero se sellan juntas, luego se presuriza (P·V=nRT) y finalmente se regula el flujo de O₂.")
				flash_feedback(UITheme.RED, "¡Orden inseguro! Secuencia: 1. Sellos → 2. Presurizar → 3. Flujo O₂.")
		)
		content_box.add_child(b)
	flash_feedback(UITheme.CYAN, "Paso esperado: 1 de 3 — Sellado hermético.")

func _setup_newton() -> void:
	_build_shell(
		"LABORATORIO DE LAS 3 LEYES DE NEWTON",
		"Observa la simulación física animada y elige la respuesta científica correcta.",
		Vector2(820, 580),
		UITheme.GREEN,
		"CAP. 2 · DINÁMICA ESPACIAL"
	)
	_render_newton_question()

func _render_newton_question() -> void:
	for c in content_box.get_children():
		c.queue_free()
	_canvases.clear()

	var questions := [
		{
			"q": "1/3 (Inercia): En el espacio profundo sin rozamiento, empujas una caja de 50 kg y la sueltas. ¿Qué ocurre?",
			"opts": ["Se detiene tras unos metros", "Continúa moviéndose a velocidad constante en línea recta", "Acelera indefinidamente"],
			"ans": 1,
			"err": "La 1.ª Ley de Newton indica que sin fuerza neta la velocidad permanece constante."
		},
		{
			"q": "2/3 (F = m·a): Aplicas la misma fuerza de 100 N a una caja de 10 kg y a otra de 50 kg. ¿Cuál acelera más?",
			"opts": ["La de 10 kg (a = 10 m/s² vs 2 m/s²)", "La de 50 kg porque tiene más inercia", "Ambas aceleran igual"],
			"ans": 0,
			"err": "Según a = F/m, a menor masa mayor aceleración para una misma fuerza."
		},
		{
			"q": "3/3 (Acción-Reacción): ¿Por qué un cohete SLS acelera en el vacío si no hay aire contra el cual 'empujar'?",
			"opts": ["Empuja contra la gravedad terrestre", "Expulsa gases a alta velocidad hacia atrás y los gases empujan al cohete hacia adelante", "El vacío succiona el cohete"],
			"ans": 1,
			"err": "Por la 3.ª Ley de Newton (F₁₂ = -F₂₁), el cohete intercambia momento lineal con su propio propelente."
		}
	]
	if _newton_q >= questions.size():
		ObjectiveManager.notify_event("newton_quiz_passed")
		finished.emit(true)
		return

	var q_idx := _newton_q
	create_canvas(118.0, func(c: Control, t: float):
		var s := c.size
		draw_starfield(c, t, 22)
		if q_idx == 0:
			# Caja deslizándose a velocidad constante en vacío
			var px := fmod(t * 140.0, maxf(120.0, s.x - 80.0)) + 40.0
			c.draw_rect(Rect2(px - 22.0, s.y * 0.5 - 22.0, 44.0, 44.0), UITheme.CYAN, true)
			c.draw_line(Vector2(px + 24.0, s.y * 0.5), Vector2(px + 68.0, s.y * 0.5), UITheme.GOLD, 3.0)
		elif q_idx == 1:
			# Comparación 10kg rápida vs 50kg lenta con F = 100N
			var cy1 := s.y * 0.30
			var cy2 := s.y * 0.72
			var p1 := fmod(pow(fmod(t * 0.7, 1.4), 2.0) * 320.0, maxf(100.0, s.x - 100.0)) + 50.0
			var p2 := fmod(pow(fmod(t * 0.7, 1.4), 2.0) * 85.0, maxf(100.0, s.x - 100.0)) + 50.0
			c.draw_rect(Rect2(p1 - 14.0, cy1 - 14.0, 28.0, 28.0), UITheme.GREEN, true)
			c.draw_rect(Rect2(p2 - 22.0, cy2 - 22.0, 44.0, 44.0), Color(0.95, 0.56, 0.16), true)
		else:
			# Cohete SLS expulsando chorro de gases hacia la izquierda
			var rx := s.x * 0.55 + sin(t * 3.0) * 14.0
			var ry := s.y * 0.5
			c.draw_circle(Vector2(rx - 38.0 - fmod(t * 80.0, 45.0), ry), 11.0, Color(1.0, 0.55, 0.15, 0.85))
			c.draw_circle(Vector2(rx - 52.0 - fmod(t * 80.0, 45.0), ry + sin(t * 9.0) * 5.0), 8.0, Color(1.0, 0.85, 0.30, 0.65))
			c.draw_rect(Rect2(rx - 26.0, ry - 14.0, 56.0, 28.0), Color(0.92, 0.94, 0.98), true)
			c.draw_colored_polygon(PackedVector2Array([Vector2(rx + 30.0, ry - 14.0), Vector2(rx + 54.0, ry), Vector2(rx + 30.0, ry + 14.0)]), UITheme.RED)
	)

	var item: Dictionary = questions[_newton_q]
	var qlbl := UITheme.label(String(item["q"]), 16, Color.WHITE, true, true)
	qlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(qlbl)

	var opts: Array = item["opts"]
	var cols := [UITheme.CYAN, UITheme.GREEN, UITheme.GOLD]
	var letters := ["A", "B", "C"]
	for i in range(opts.size()):
		var b := make_action_btn("[%s]  %s" % [letters[i], String(opts[i])], cols[i % cols.size()], 48.0)
		b.pressed.connect(func():
			if i == int(item["ans"]):
				ObjectiveManager.mark_substep(_newton_q)
				_newton_q += 1
				flash_feedback(UITheme.GREEN, "¡Respuesta correcta! Avanzando...")
				_render_newton_question()
			else:
				GameState.record_error(2, "train_newton", "Error en Ley de Newton (%d/3)." % (_newton_q + 1), String(item["err"]))
				flash_feedback(UITheme.RED, "Incorrecto. Pista: " + String(item["err"]))
		)
		content_box.add_child(b)
	flash_feedback(UITheme.GREEN, "Prueba práctica %d de 3 — Selecciona la ley física correcta." % (_newton_q + 1))
