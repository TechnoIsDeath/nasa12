class_name TrajectoryAndLaunchMinigames
extends BaseMinigame

var mode: String = "window"

# Tsiolkovsky & Free-return sliders
var _mass_slider: HSlider
var _dv_bar: ProgressBar
var _peri_slider: HSlider
var _tli_slider: HSlider

# GO/NO-GO state
var _purged: bool = false
var _gonogo_stations: Dictionary = {} # idx -> bool

# Ascent simulation
var _ascent_t: float = 0.0
var _ascent_running: bool = false
var _srb_sep_done: bool = false
var _maxq_done: bool = false
var _ascent_bar: ProgressBar
var _ascent_btn: Button


static func create(challenge_mode: String) -> TrajectoryAndLaunchMinigames:
	var m := TrajectoryAndLaunchMinigames.new()
	m.mode = challenge_mode
	return m


func _ready() -> void:
	match mode:
		"window": _build_window()
		"tsiolkovsky": _build_tsiolkovsky()
		"free_return": _build_free_return()
		"gonogo": _build_gonogo()
		"ascent": _build_ascent()


func _build_window() -> void:
	_build_shell("Selección de Ventana de Lanzamiento", "Elige el ángulo de fase que intercepta a la Luna en su órbita hacia adelante", Vector2(820, 620), UITheme.CYAN, "CAPÍTULO 6 · SALA FIDO")

	create_canvas(185.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 36)
		var ec := Vector2(sz.x * 0.25, sz.y * 0.56)
		c.draw_circle(ec, 24.0, UITheme.NASA_BLUE)
		c.draw_arc(ec, 38.0, 0.0, TAU, 36, Color(0.3, 0.8, 1.0, 0.5), 2.0)
		var mc_b := Vector2(sz.x * 0.78, sz.y * 0.42)
		var mc_a := Vector2(sz.x * 0.62, sz.y * 0.78)
		var mc_c := Vector2(sz.x * 0.72, sz.y * 0.16)
		c.draw_arc(ec, ec.distance_to(mc_b), -0.65, 0.7, 48, Color(0.45, 0.5, 0.6, 0.35), 2.0)
		c.draw_line(ec, mc_a, Color(UITheme.RED.r, UITheme.RED.g, UITheme.RED.b, 0.65), 2.0)
		c.draw_line(ec, mc_c, Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.65), 2.0)
		c.draw_line(ec, mc_b, UITheme.GREEN, 3.0)
		var ship_u := fmod(t * 0.45, 1.0)
		c.draw_circle(ec.lerp(mc_b, ship_u), 5.0, Color.WHITE)
		c.draw_circle(mc_a, 11.0, UITheme.RED)
		c.draw_circle(mc_c, 11.0, UITheme.GOLD)
		c.draw_circle(mc_b, 15.0, Color(0.84, 0.86, 0.90))
		c.draw_string(ThemeDB.fallback_font, mc_b + Vector2(-40, -22), "VENTANA B (+42°)", HORIZONTAL_ALIGNMENT_CENTER, 100, 12, UITheme.GREEN)
	)

	var opts: Array[Dictionary] = [
		{"txt": "Ventana A (Luna en oposición -180°, eclipse total prolongado)", "ok": false},
		{"txt": "Ventana B (Fase óptima +42° adelantada, alineación nodal 28.5°)", "ok": true},
		{"txt": "Ventana C (Inclinación +90° polar, costo Δv prohibitivo)", "ok": false}
	]
	for o in opts:
		var opt: Dictionary = o
		var b := make_action_btn(String(opt["txt"]), UITheme.CYAN, 44.0, 680.0)
		b.pressed.connect(func() -> void:
			if bool(opt["ok"]):
				flash_feedback(UITheme.GREEN, "Ventana B confirmada: geometría de retorno libre verificada.")
				ObjectiveManager.notify_event("fido_window_done")
				await get_tree().create_timer(0.55).timeout
				finished.emit(true)
			else:
				GameState.record_error(6, "fido_window", "Ventana seleccionada no cumple fase lunar ni límites de inclinación / eclipse.", "Para una trayectoria translunar eficiente desde Cabo Cañaveral (~28.5°), se apunta ~42° por delante de la posición lunar.")
				flash_feedback(UITheme.RED, "Geometría subóptima. Busca +42° adelantada e inclinación 28.5°.")
		)
		content_box.add_child(b)


func _build_tsiolkovsky() -> void:
	_build_shell("Presupuesto Δv de Tsiolkovsky", "Ajusta la masa inicial m₀ de la etapa ICPS (Isp=465 s, m_f=15,000 kg) hasta Δv ≥ 3,100 m/s", Vector2(800, 610), UITheme.GOLD, "CAPÍTULO 6 · ECUACIÓN DEL COHETE")

	create_canvas(170.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 28)
		var m0 := _mass_slider.value if _mass_slider else 21000.0
		var dv := AeroPhysics.tsiolkovsky_delta_v(465.0, m0, 15000.0)
		var ok := dv >= 3100.0
		var tx := 90.0
		var ty := sz.y * 0.35
		var tw := sz.x - 180.0
		var th := 62.0
		c.draw_rect(Rect2(tx, ty, tw, th), Color(0.10, 0.14, 0.22), true)
		c.draw_rect(Rect2(tx, ty, tw, th), UITheme.BORDER, false, 2.0)
		var dry_ratio := 15000.0 / 38000.0
		var dry_w := tw * dry_ratio
		var fuel_ratio := clampf((m0 - 15000.0) / (38000.0 - 15000.0), 0.0, 1.0)
		c.draw_rect(Rect2(tx + 4, ty + 4, dry_w - 4, th - 8), Color(0.35, 0.42, 0.54))
		var fuel_col := UITheme.GREEN if ok else UITheme.CYAN
		c.draw_rect(Rect2(tx + dry_w, ty + 4, (tw - dry_w - 4) * fuel_ratio, th - 8), fuel_col)
		c.draw_string(ThemeDB.fallback_font, Vector2(tx + 12, ty + 36), "m_f=15t", HORIZONTAL_ALIGNMENT_LEFT, 90, 13, Color.WHITE)
		c.draw_string(ThemeDB.fallback_font, Vector2(tx, ty - 10), "m₀ = %.0f kg    ->    Δv = %.0f m/s   (Meta ≥ 3,100 m/s)" % [m0, dv], HORIZONTAL_ALIGNMENT_CENTER, int(tw), 14, UITheme.GREEN if ok else UITheme.GOLD)
	)

	_mass_slider = HSlider.new()
	_mass_slider.min_value = 18000.0
	_mass_slider.max_value = 38000.0
	_mass_slider.step = 500.0
	_mass_slider.value = 21000.0
	_mass_slider.custom_minimum_size = Vector2(640, 28)
	_mass_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(_mass_slider)

	_dv_bar = ProgressBar.new()
	_dv_bar.max_value = 4200.0
	_dv_bar.custom_minimum_size = Vector2(640, 22)
	_dv_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(_dv_bar)

	var update_dv := func() -> void:
		var dv := AeroPhysics.tsiolkovsky_delta_v(465.0, _mass_slider.value, 15000.0)
		_dv_bar.value = dv
		set_bar_color(_dv_bar, UITheme.GREEN if dv >= 3100.0 else UITheme.GOLD)
		status_lbl.text = "Masa m₀ = %.0f kg   |   Δv = %.0f m/s (objetivo ≥ 3,100 m/s)" % [_mass_slider.value, dv]
	_mass_slider.value_changed.connect(func(_v: float) -> void: update_dv.call())
	update_dv.call()

	var btn := make_action_btn("Confirmar Propulsión TLI", UITheme.GOLD, 46.0, 320.0)
	btn.pressed.connect(func() -> void:
		var dv := AeroPhysics.tsiolkovsky_delta_v(465.0, _mass_slider.value, 15000.0)
		if dv >= 3100.0:
			flash_feedback(UITheme.GREEN, "Δv certificado: %.0f m/s suficientes para inyección translunar." % dv)
			ObjectiveManager.notify_event("fido_dv_done")
			await get_tree().create_timer(0.55).timeout
			finished.emit(true)
		else:
			GameState.record_error(6, "fido_tsiolkovsky", "Δv insuficiente (%.0f m/s < 3100 m/s)." % dv, "Según Δv = Isp · g₀ · ln(m₀/m_f), hace falta mayor fracción de propelente para alcanzar la velocidad de escape lunar.")
			flash_feedback(UITheme.RED, "Δv insuficiente (%.0f m/s). Incrementa m₀." % dv)
	)
	content_box.add_child(btn)


func _build_free_return() -> void:
	_build_shell("Simulador de Retorno Libre Lunar", "Ajusta el periapsis lunar y la velocidad TLI para que la gravedad devuelva a Orion sin quemado de retorno", Vector2(820, 640), UITheme.CYAN, "CAPÍTULO 6 · TRAYECTORIA EN OCHO")

	create_canvas(195.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 40)
		var earth := Vector2(140.0, sz.y * 0.55)
		var moon := Vector2(sz.x - 165.0, sz.y * 0.55)
		var peri := _peri_slider.value if _peri_slider else 11000.0
		var tli := _tli_slider.value if _tli_slider else 2900.0
		var res: Dictionary = AeroPhysics.evaluate_free_return(peri, tli)
		var valid: bool = bool(res.get("valid", false))
		var status_txt: String = String(res.get("status", ""))

		c.draw_circle(earth, 26.0, UITheme.NASA_BLUE)
		c.draw_circle(moon, 18.0, Color(0.84, 0.86, 0.90))
		c.draw_string(ThemeDB.fallback_font, earth + Vector2(-24, 42), "TIERRA", HORIZONTAL_ALIGNMENT_CENTER, 50, 11, UITheme.CYAN)
		c.draw_string(ThemeDB.fallback_font, moon + Vector2(-24, 34), "LUNA", HORIZONTAL_ALIGNMENT_CENTER, 50, 11, Color.WHITE)

		var bend := clampf((12000.0 - peri) / 10000.0, 0.1, 1.1)
		var speed_scale := clampf((tli - 2800.0) / 600.0, 0.2, 1.3)
		var col := UITheme.GREEN if valid else UITheme.GOLD
		var pts := PackedVector2Array()
		for i in range(49):
			var th := (float(i) / 48.0) * TAU
			var lx := lerpf(earth.x + 28.0, moon.x + 26.0 * bend + 20.0 * speed_scale, 0.5 - 0.5 * cos(th))
			var ly := earth.y + sin(th) * cos(th * 0.5) * (88.0 * bend)
			pts.append(Vector2(lx, ly))
		c.draw_polyline(pts, col, 3.0)
		var s_idx := mini(48, int(fmod(t * 18.0, 48.0)))
		c.draw_circle(pts[s_idx], 6.0, Color.WHITE)
		c.draw_string(ThemeDB.fallback_font, Vector2(20, 24), status_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.GREEN if valid else UITheme.GOLD)
	)

	var p_row := make_centered_row(12)
	p_row.add_child(UITheme.label("Periapsis lunar (km):", 13, UITheme.TEXT_DIM))
	_peri_slider = HSlider.new()
	_peri_slider.min_value = 50.0
	_peri_slider.max_value = 12000.0
	_peri_slider.step = 50.0
	_peri_slider.value = 11000.0
	_peri_slider.custom_minimum_size = Vector2(440, 24)
	p_row.add_child(_peri_slider)

	var t_row := make_centered_row(12)
	t_row.add_child(UITheme.label("Δv de TLI (m/s):     ", 13, UITheme.TEXT_DIM))
	_tli_slider = HSlider.new()
	_tli_slider.min_value = 2800.0
	_tli_slider.max_value = 3400.0
	_tli_slider.step = 10.0
	_tli_slider.value = 2900.0
	_tli_slider.custom_minimum_size = Vector2(440, 24)
	t_row.add_child(_tli_slider)

	var update_fr := func() -> void:
		var res: Dictionary = AeroPhysics.evaluate_free_return(_peri_slider.value, _tli_slider.value)
		var valid: bool = bool(res.get("valid", false))
		var st: String = String(res.get("status", ""))
		status_lbl.text = "Periapsis: %.0f km | TLI: %.0f m/s -> %s" % [_peri_slider.value, _tli_slider.value, st]
		status_lbl.add_theme_color_override("font_color", UITheme.GREEN if valid else UITheme.GOLD)
	_peri_slider.value_changed.connect(func(_v: float) -> void: update_fr.call())
	_tli_slider.value_changed.connect(func(_v: float) -> void: update_fr.call())
	update_fr.call()

	var btn := make_action_btn("Fijar Trayectoria de Retorno Libre", UITheme.CYAN, 46.0, 360.0)
	btn.pressed.connect(func() -> void:
		var res: Dictionary = AeroPhysics.evaluate_free_return(_peri_slider.value, _tli_slider.value)
		var valid: bool = bool(res.get("valid", false))
		var st: String = String(res.get("status", ""))
		if valid:
			flash_feedback(UITheme.GREEN, "Órbita en ocho verificada. Retorno pasivo garantizado.")
			ObjectiveManager.notify_event("fido_return_done")
			await get_tree().create_timer(0.55).timeout
			finished.emit(true)
		else:
			GameState.record_error(6, "fido_free_return", "Parámetros fuera de retorno libre: " + st, "Solo un corredor preciso de periapsis lunar y Δv permite la asistencia gravitatoria de regreso pasivo hacia Tierra.")
			flash_feedback(UITheme.RED, st)
	)
	content_box.add_child(btn)


func _build_gonogo() -> void:
	_build_shell("Poll GO / NO-GO (MOCR)", "Purga primero el sensor de hidrógeno líquido y luego autoriza las 4 estaciones de vuelo", Vector2(820, 620), UITheme.GOLD, "CAPÍTULO 7 · CONTROL DE LANZAMIENTO")

	create_canvas(150.0, func(c: Control, t: float) -> void:
		var sz := c.size
		var box_w := (sz.x - 80.0) / 4.0
		var names: Array[String] = ["FIDO", "GUIDO", "EECOM", "FLIGHT"]
		for i in range(4):
			var bx := 20.0 + float(i) * (box_w + 13.0)
			var is_go: bool = bool(_gonogo_stations.get(i, false))
			var blink := (0.5 + 0.5 * sin(t * 7.0)) if (i == 2 and not _purged) else 1.0
			var col := UITheme.GREEN if is_go else (Color(1.0, 0.35, 0.25, blink) if (i == 2 and not _purged) else UITheme.GOLD)
			c.draw_rect(Rect2(bx, 22, box_w, 106), Color(0.06, 0.10, 0.16, 0.92), true)
			c.draw_rect(Rect2(bx, 22, box_w, 106), col, false, 2.5)
			c.draw_circle(Vector2(bx + box_w * 0.5, 64), 18.0, col)
			c.draw_string(ThemeDB.fallback_font, Vector2(bx, 106), names[i], HORIZONTAL_ALIGNMENT_CENTER, int(box_w), 13, Color.WHITE)
	)

	var purge_btn := make_action_btn("1) Purgar Línea LH₂ & Resetear Sensor de Hidrógeno", UITheme.GOLD, 44.0, 540.0)
	purge_btn.pressed.connect(func() -> void:
		_purged = true
		purge_btn.disabled = true
		purge_btn.modulate = UITheme.GREEN
		ObjectiveManager.mark_substep(1)
		flash_feedback(UITheme.GREEN, "Sensor LH₂ estabilizado (< 0.4%). Procede con el poll GO/NO-GO.")
	)
	content_box.add_child(purge_btn)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(grid)

	var stations: Array[String] = ["FIDO  (Trayectoria)", "GUIDO  (Guiado)", "EECOM  (Propulsión)", "FLIGHT  (Director)"]
	for i in range(4):
		var s_idx: int = i
		var s_name: String = stations[s_idx]
		var sb := make_action_btn("2) Confirmar " + s_name + ": GO", UITheme.CYAN, 46.0, 330.0)
		sb.pressed.connect(func() -> void:
			if not _purged:
				flash_feedback(UITheme.RED, "NO-GO activo en LH₂. Purga la línea de hidrógeno primero.")
				return
			_gonogo_stations[s_idx] = true
			sb.disabled = true
			sb.modulate = UITheme.GREEN
			flash_feedback(UITheme.GREEN, "%s -> GO (%d / 4)" % [s_name, _gonogo_stations.size()])
			if _gonogo_stations.size() == 4:
				ObjectiveManager.notify_event("launch_gonogo_done")
				await get_tree().create_timer(0.55).timeout
				finished.emit(true)
		)
		grid.add_child(sb)


func _build_ascent() -> void:
	_build_shell("Telemetría SLS — Hacia Órbita", "Inicia la ignición y supervisa Max-Q, Separación SRB y MECO", Vector2(820, 620), UITheme.GOLD, "CAPÍTULO 7 · IGNICIÓN Y ASCENSO")
	GameState.set_phase(CatalogData.FlightPhase.LAUNCH)

	create_canvas(195.0, func(c: Control, t: float) -> void:
		var sz := c.size
		var frac := clampf(_ascent_t / 480.0, 0.0, 1.0)
		var sky_top := Color(0.10, 0.34, 0.68).lerp(Color(0.02, 0.03, 0.08), clampf(frac * 1.4, 0.0, 1.0))
		c.draw_rect(Rect2(0, 0, sz.x, sz.y), sky_top)
		if frac > 0.25:
			draw_starfield(c, t, int(frac * 45.0))

		var rx := lerpf(130.0, sz.x - 140.0, frac)
		var ry := lerpf(sz.y - 36.0, 52.0, frac)
		if _ascent_running or _ascent_t > 0.0:
			var flame := 24.0 + 10.0 * sin(t * 28.0)
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(rx - 18, ry - 4), Vector2(rx - 18, ry + 4), Vector2(rx - 18 - flame, ry)
			]), Color(1.0, 0.60, 0.16, 0.92))
		c.draw_rect(Rect2(rx - 18, ry - 5, 36, 10), Color(0.85, 0.45, 0.18))
		if not _srb_sep_done:
			c.draw_rect(Rect2(rx - 14, ry - 9, 26, 4), Color.WHITE)
			c.draw_rect(Rect2(rx - 14, ry + 5, 26, 4), Color.WHITE)
		var alt_now: float = float(GameState.telemetry.get("altitude_km", 0.0))
		var vel_now: float = float(GameState.telemetry.get("velocity_ms", 0.0))
		c.draw_string(ThemeDB.fallback_font, Vector2(18, 26), "T+%.0fs / 480s   |   Alt: %.1f km   |   Vel: %.0f m/s" % [_ascent_t, alt_now, vel_now], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.CYAN)
	)

	_ascent_bar = ProgressBar.new()
	_ascent_bar.max_value = 480.0
	_ascent_bar.custom_minimum_size = Vector2(660, 22)
	_ascent_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(_ascent_bar)

	var row := make_centered_row(14)

	_ascent_btn = make_action_btn("IGNICIÓN T-0  ¡Despegar!", UITheme.GOLD, 48.0, 280.0)
	_ascent_btn.pressed.connect(func() -> void:
		_ascent_running = true
		_ascent_btn.disabled = true
		flash_feedback(UITheme.GOLD, "Ignición RS-25 + SRB confirmada. Ascendiendo hacia Max-Q...")
	)
	row.add_child(_ascent_btn)

	var srb_btn := make_action_btn("Separar SRBs (al alcanzar T+100s)", UITheme.CYAN, 48.0, 300.0)
	srb_btn.pressed.connect(func() -> void:
		if _ascent_t >= 100.0 and not _srb_sep_done:
			_srb_sep_done = true
			srb_btn.disabled = true
			srb_btn.modulate = UITheme.GREEN
			ObjectiveManager.mark_substep(1)
			flash_feedback(UITheme.GREEN, "¡Separación limpia de SRB! Acelerando al MECO...")
		else:
			flash_feedback(UITheme.RED, "Espera a T+100s antes de separar los propulsores sólidos.")
	)
	row.add_child(srb_btn)


func _process(delta: float) -> void:
	if mode != "ascent" or not _ascent_running:
		return
	_ascent_t += delta * 45.0
	_ascent_bar.value = _ascent_t
	var alt_km := clampf((_ascent_t / 480.0) * 185.0, 0.0, 185.0)
	var vel_ms := clampf((_ascent_t / 480.0) * 7820.0, 0.0, 7820.0)
	var q_kpa := AeroPhysics.dynamic_pressure_kpa(alt_km * 1000.0, vel_ms)
	GameState.telemetry["altitude_km"] = alt_km
	GameState.telemetry["velocity_ms"] = vel_ms
	GameState.telemetry["max_q_kpa"] = maxf(float(GameState.telemetry.get("max_q_kpa", 0.0)), q_kpa)
	set_bar_color(_ascent_bar, UITheme.GREEN if _srb_sep_done else UITheme.GOLD)
	status_lbl.text = "T+%.0fs | Alt %.1f km | Vel %.0f m/s | q = %.1f kPa" % [_ascent_t, alt_km, vel_ms, q_kpa]
	if _ascent_t >= 65.0 and not _maxq_done:
		_maxq_done = true
		ObjectiveManager.mark_substep(0)
	if _ascent_t >= 450.0 and _srb_sep_done:
		_ascent_running = false
		flash_feedback(UITheme.GREEN, "¡MECO alcanzado! Orion + ICPS en órbita terrestre.")
		ObjectiveManager.notify_event("launch_ascent_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	elif _ascent_t >= 480.0 and not _srb_sep_done:
		_ascent_t = 479.0
