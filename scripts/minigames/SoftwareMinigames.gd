class_name SoftwareMinigames
extends BaseMinigame

var mode: String = "gls"

# GLS countdown sequence
var _gls_order: Array[String] = ["T-10:00  Inicio GLS", "T-00:30  Retirar umbilicales", "T-00:06.6  Ignición RS-25", "T-00:00  SRB & Despegue"]
var _gls_step: int = 0
var _gls_btns: Array[Button] = []

# Debug units (Mars Climate Orbiter reference)
var _debug_fixed: bool = false

# Telemetry interactive node-to-channel wiring
var _telem_sensors: Array[Dictionary] = [
	{"name": "Sensor O₂ Cabina", "target": 0, "color": UITheme.CYAN},
	{"name": "Termopar Escudo Avcoat", "target": 1, "color": UITheme.GOLD},
	{"name": "Presión Cámara RS-25", "target": 2, "color": UITheme.PURPLE}
]
var _telem_channels: Array[String] = ["CH-01  ECLSS", "CH-02  TÉRMICO", "CH-03  PROPULSIÓN"]
var _selected_sensor: int = -1
var _wired_pairs: Dictionary = {} # sensor_idx -> channel_idx
var _sensor_btns: Array[Button] = []
var _channel_btns: Array[Button] = []


static func create(challenge_mode: String) -> SoftwareMinigames:
	var m := SoftwareMinigames.new()
	m.mode = challenge_mode
	return m


func _ready() -> void:
	match mode:
		"gls": _build_gls()
		"debug_units": _build_debug()
		"redundancy": _build_redundancy()
		"telemetry": _build_telemetry()


func _build_gls() -> void:
	_build_shell("Secuenciador de Lanzamiento (GLS)", "Ejecuta la cascada final en el orden exacto de despegue", Vector2(780, 610), UITheme.CYAN, "CAPÍTULO 5 · SOFTWARE GLS")

	create_canvas(175.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 28)
		c.draw_rect(Rect2(0, sz.y - 26, sz.x, 26), Color(0.08, 0.12, 0.19, 1.0))

		var start_x := 82.0
		var end_x := sz.x - 190.0
		var step_w := (end_x - start_x) / 3.0
		var y_line := sz.y * 0.52
		c.draw_line(Vector2(start_x, y_line), Vector2(end_x, y_line), Color(0.24, 0.34, 0.48), 4.0)
		if _gls_step > 0:
			var prog_x := start_x + minf(float(_gls_step), 3.0) * step_w
			c.draw_line(Vector2(start_x, y_line), Vector2(prog_x, y_line), UITheme.GREEN, 5.0)

		var labels: Array[String] = ["T-10m", "T-30s", "T-6.6s", "T-00s"]
		for i in range(4):
			var nx := start_x + float(i) * step_w
			var done := i < _gls_step
			var active := i == _gls_step
			var col := UITheme.GREEN if done else (UITheme.GOLD if active else Color(0.26, 0.32, 0.42))
			var pulse := 1.0 + (0.16 * sin(t * 6.0) if active else 0.0)
			c.draw_circle(Vector2(nx, y_line), 20.0 * pulse, Color(col.r, col.g, col.b, 0.24))
			c.draw_circle(Vector2(nx, y_line), 13.0, col)
			c.draw_string(ThemeDB.fallback_font, Vector2(nx - 22, y_line - 24), labels[i], HORIZONTAL_ALIGNMENT_CENTER, 44, 12, col)

		var rx := sz.x - 105.0
		var lift := 32.0 * maxf(0.0, sin(t * 2.5)) if _gls_step >= 4 else 0.0
		var base_y := sz.y - 26.0 - lift
		c.draw_rect(Rect2(rx + 24, sz.y - 140, 14, 114), Color(0.28, 0.34, 0.44))
		var arm_ang := -0.45 if _gls_step >= 2 else 0.0
		c.draw_line(Vector2(rx + 24, sz.y - 98), Vector2(rx + 6, sz.y - 98 + sin(arm_ang) * 26.0), UITheme.GOLD, 3.0)
		c.draw_rect(Rect2(rx - 16, base_y - 78, 8, 78), Color(0.88, 0.90, 0.94))
		c.draw_rect(Rect2(rx + 8, base_y - 78, 8, 78), Color(0.88, 0.90, 0.94))
		c.draw_rect(Rect2(rx - 7, base_y - 96, 14, 96), Color(0.85, 0.45, 0.18))
		if _gls_step >= 3:
			var f_h := (18.0 + 8.0 * sin(t * 28.0)) * (1.6 if _gls_step >= 4 else 0.9)
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(rx - 8, base_y), Vector2(rx + 8, base_y), Vector2(rx, base_y + f_h)
			]), Color(1.0, 0.62, 0.16, 0.92))
	)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(grid)

	var presented: Array[int] = [2, 0, 3, 1]
	for idx in presented:
		var step_idx: int = idx
		var step_txt: String = _gls_order[step_idx]
		var btn := make_action_btn(step_txt, UITheme.CYAN, 48.0, 320.0)
		btn.pressed.connect(func() -> void:
			if step_idx == _gls_step:
				btn.disabled = true
				btn.modulate = UITheme.GREEN
				_gls_step += 1
				flash_feedback(UITheme.GREEN, "Paso %d / 4 ejecutado correctamente" % _gls_step)
				if _gls_step == 4:
					ObjectiveManager.notify_event("sw_gls_done")
					await get_tree().create_timer(0.55).timeout
					finished.emit(true)
			else:
				GameState.record_error(5, "sw_gls_sequence", "Error de secuencia GLS: pulsaste '%s' antes de completar la etapa previa." % step_txt, "La ignición RS-25 y retracción de umbilicales requieren secuencia cronológica estricta.")
				flash_feedback(UITheme.RED, "Orden incorrecto. Siguiente esperado: " + _gls_order[_gls_step])
		)
		grid.add_child(btn)
		_gls_btns.append(btn)


func _build_debug() -> void:
	_build_shell("Inspector de Guiado — Bug de Unidades", "Corrige la conversión lbf -> N antes de la maniobra orbital (ref. Mars Climate Orbiter 1999)", Vector2(800, 620), UITheme.GOLD, "CAPÍTULO 5 · DEPURACIÓN")

	create_canvas(175.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 30)
		var cx := sz.x * 0.5
		var cy := sz.y * 0.55
		c.draw_circle(Vector2(cx + 150, cy), 42.0, Color(0.68, 0.34, 0.24))
		c.draw_arc(Vector2(cx + 150, cy), 64.0, 0.0, TAU, 48, Color(0.32, 0.58, 0.85, 0.45), 2.0)

		var pts_ok := PackedVector2Array()
		var pts_bug := PackedVector2Array()
		for i in range(25):
			var u := float(i) / 24.0
			var x := lerpf(60.0, cx + 150, u)
			var y_ok := lerpf(cy + 36, cy - 64, sin(u * PI * 0.55))
			var y_bug := lerpf(cy + 36, cy - 6, u * u)
			pts_ok.append(Vector2(x, y_ok))
			pts_bug.append(Vector2(x, y_bug))

		if _debug_fixed:
			c.draw_polyline(pts_bug, Color(0.5, 0.2, 0.2, 0.35), 2.0)
			c.draw_polyline(pts_ok, UITheme.GREEN, 3.5)
			var idx := mini(24, int(fmod(t * 14.0, 24.0)))
			c.draw_circle(pts_ok[idx], 6.0, UITheme.CYAN)
			c.draw_string(ThemeDB.fallback_font, Vector2(20, 24), "TRAYECTORIA CORREGIDA (N·s): Órbita estable", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.GREEN)
		else:
			c.draw_polyline(pts_ok, Color(0.2, 0.6, 0.4, 0.3), 2.0)
			c.draw_polyline(pts_bug, UITheme.RED, 3.5)
			var idx := mini(24, int(fmod(t * 14.0, 24.0)))
			c.draw_circle(pts_bug[idx], 6.0, UITheme.RED)
			c.draw_string(ThemeDB.fallback_font, Vector2(20, 24), "ALERTA: Empuje 4.45× menor (lbf sin convertir) -> Caída atmosférica", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.RED)
	)

	var code_card := PanelContainer.new()
	code_card.add_theme_stylebox_override("panel", UITheme.card(UITheme.GOLD, UITheme.PANEL))
	content_box.add_child(code_card)
	var code := UITheme.label(
		"func aplicar_impulso(empuje_lbf: float, dt: float) -> float:\n" +
		"    # BUG CRÍTICO: el integrador de navegación espera Newtons (N)\n" +
		"    var empuje_si = empuje_lbf   # <-- FALTA CONVERSIÓN SI\n" +
		"    return empuje_si * dt / masa_orion_kg", 13, UITheme.GOLD
	)
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	code_card.add_child(code)

	var opts: Array[Dictionary] = [
		{"txt": "var empuje_si = empuje_lbf * 4.44822  # lbf -> Newtons (SI)", "ok": true},
		{"txt": "var empuje_si = empuje_lbf / 2.20462  # masa lb -> kg", "ok": false},
		{"txt": "var empuje_si = empuje_lbf * 0.3048   # pies -> metros", "ok": false}
	]
	for o in opts:
		var opt: Dictionary = o
		var b := make_action_btn(String(opt["txt"]), UITheme.CYAN, 42.0, 680.0)
		b.pressed.connect(func() -> void:
			if bool(opt["ok"]):
				_debug_fixed = true
				flash_feedback(UITheme.GREEN, "Parche compilado: empuje convertido a Newtons (×4.44822).")
				ObjectiveManager.notify_event("sw_debug_done")
				await get_tree().create_timer(0.65).timeout
				finished.emit(true)
			else:
				GameState.record_error(5, "sw_debug_units", "Conversión incorrecta de libras-fuerza (lbf) a Newtons.", "1 libra-fuerza (lbf) equivale exactamente a 4.44822 Newtons en el Sistema Internacional.")
				flash_feedback(UITheme.RED, "Factor incorrecto. Fuerza en SI requiere lbf × 4.44822 N.")
		)
		content_box.add_child(b)


func _build_redundancy() -> void:
	_build_shell("Votación Triple Modular (TMR)", "Compara las 3 computadoras de vuelo en tiempo real y aísla el canal corrupto", Vector2(800, 600), UITheme.PURPLE, "CAPÍTULO 5 · TOLERANCIA A FALLOS")

	create_canvas(195.0, func(c: Control, t: float) -> void:
		var sz := c.size
		var lane_h := sz.y / 3.0
		var labels: Array[String] = ["GPC-A  (42.00°)", "GPC-B  (ERROR)", "GPC-C  (42.01°)"]
		for ch in range(3):
			var y0 := float(ch) * lane_h
			var mid := y0 + lane_h * 0.55
			var is_bad := ch == 1
			var col := UITheme.RED if is_bad else UITheme.CYAN
			c.draw_rect(Rect2(10, y0 + 6, sz.x - 20, lane_h - 12), Color(0.05, 0.08, 0.13, 0.9))
			c.draw_string(ThemeDB.fallback_font, Vector2(22, y0 + 24), labels[ch], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

			var pts := PackedVector2Array()
			for i in range(44):
				var u := float(i) / 43.0
				var x := lerpf(165.0, sz.x - 24.0, u)
				var y := mid + sin(u * 10.0 - t * 5.0) * 8.0
				if is_bad:
					y += sin(u * 47.0 + t * 22.0) * 16.0
				pts.append(Vector2(x, y))
			c.draw_polyline(pts, col, 2.5)
	)

	var row := make_centered_row(14)
	var btns_cfg: Array[Dictionary] = [
		{"txt": "Aislar GPC-A", "ok": false},
		{"txt": "Aislar GPC-B (Consenso A + C)", "ok": true},
		{"txt": "Aislar GPC-C", "ok": false}
	]
	for info in btns_cfg:
		var cfg: Dictionary = info
		var b := make_action_btn(String(cfg["txt"]), UITheme.PURPLE, 48.0, 220.0)
		b.pressed.connect(func() -> void:
			if bool(cfg["ok"]):
				flash_feedback(UITheme.GREEN, "GPC-B aislado. Bus activo con consenso 2-de-2 (A y C).")
				ObjectiveManager.notify_event("sw_redundancy_done")
				await get_tree().create_timer(0.55).timeout
				finished.emit(true)
			else:
				GameState.record_error(5, "sw_redundancy", "Aislaste un canal sano dejando un canal discrepante en el bus de votación.", "La arquitectura TMR compara 3 canales independientes y descarta por mayoría al que diverge.")
				flash_feedback(UITheme.RED, "Canal sano: observa cuál onda tiene picos erráticos.")
		)
		row.add_child(b)


func _build_telemetry() -> void:
	_build_shell("Enrutado de Sensores a Canales", "Haz clic en un sensor (izquierda) y luego en su canal correspondiente (derecha)", Vector2(820, 620), UITheme.CYAN, "CAPÍTULO 5 · TELEMETRÍA")

	create_canvas(150.0, func(c: Control, t: float) -> void:
		var sz := c.size
		var left_x := 180.0
		var right_x := sz.x - 180.0
		for i in range(3):
			var y := 28.0 + float(i) * 44.0
			var s_col: Color = _telem_sensors[i]["color"]
			var s_name: String = _telem_sensors[i]["name"]
			c.draw_circle(Vector2(left_x, y), 10.0, s_col)
			c.draw_string(ThemeDB.fallback_font, Vector2(18, y + 5), s_name, HORIZONTAL_ALIGNMENT_LEFT, 155, 12, s_col)
			c.draw_circle(Vector2(right_x, y), 10.0, Color(0.38, 0.48, 0.62))
			c.draw_string(ThemeDB.fallback_font, Vector2(right_x + 18, y + 5), _telem_channels[i], HORIZONTAL_ALIGNMENT_LEFT, 160, 12, UITheme.TEXT)
			if _wired_pairs.has(i):
				var ch_idx: int = int(_wired_pairs[i])
				var ry := 28.0 + float(ch_idx) * 44.0
				c.draw_line(Vector2(left_x, y), Vector2(right_x, ry), UITheme.GREEN, 3.5)
				var pulse_u := fmod(t * 1.4 + float(i) * 0.3, 1.0)
				c.draw_circle(Vector2(lerpf(left_x, right_x, pulse_u), lerpf(y, ry, pulse_u)), 5.0, Color.WHITE)
	)

	var cols := make_centered_row(24)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 8)
	cols.add_child(left_col)

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 8)
	cols.add_child(right_col)

	for i in range(3):
		var s_idx: int = i
		var s_col: Color = _telem_sensors[s_idx]["color"]
		var s_name: String = _telem_sensors[s_idx]["name"]
		var sb := make_action_btn(s_name, s_col, 44.0, 300.0)
		sb.pressed.connect(func() -> void:
			if _wired_pairs.has(s_idx):
				return
			_selected_sensor = s_idx
			for k in range(_sensor_btns.size()):
				_sensor_btns[k].modulate = Color(1.3, 1.3, 1.3) if k == s_idx else Color.WHITE
			flash_feedback(s_col, "Sensor seleccionado: elige su canal a la derecha")
		)
		left_col.add_child(sb)
		_sensor_btns.append(sb)

	for j in range(3):
		var c_idx: int = j
		var cb := make_action_btn(_telem_channels[c_idx], UITheme.NASA_BLUE, 44.0, 300.0)
		cb.pressed.connect(func() -> void:
			if _selected_sensor < 0:
				flash_feedback(UITheme.GOLD, "Primero selecciona un sensor en la columna izquierda.")
				return
			if int(_telem_sensors[_selected_sensor]["target"]) == c_idx:
				_wired_pairs[_selected_sensor] = c_idx
				_sensor_btns[_selected_sensor].disabled = true
				_sensor_btns[_selected_sensor].modulate = UITheme.GREEN
				cb.disabled = true
				cb.modulate = UITheme.GREEN
				_selected_sensor = -1
				flash_feedback(UITheme.GREEN, "Enlace verificado (%d / 3 conectados)" % _wired_pairs.size())
				if _wired_pairs.size() == 3:
					ObjectiveManager.notify_event("sw_telemetry_done")
					await get_tree().create_timer(0.55).timeout
					finished.emit(true)
			else:
				flash_feedback(UITheme.RED, "Canal incompatible con el tipo de sensor seleccionado.")
		)
		right_col.add_child(cb)
		_channel_btns.append(cb)
