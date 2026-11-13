class_name SpaceFlightMinigames
extends BaseMinigame

var mode: String = "heo_perigee"

# Proximity Ops
var _prox_dist: float = 48.0
var _prox_vel: float = 0.0
var _rcs_dir: int = 0

# HEO System Check
var _sys_checks: Dictionary = {}

# TLI Burn
var _tli_dv: float = 0.0
var _tli_burning: bool = false
var _tli_bar: ProgressBar

# DSN
var _dsn_step: int = 0
var _dsn_stations: Array[String] = ["Goldstone (EE. UU.)", "Madrid (España)", "Canberra (Australia)"]

# Science photo targets
var _sci_targets: Array[String] = ["Cráter Tsiolkovskiy", "Cuenca Aitken", "Mare Orientale"]
var _sci_done: Dictionary = {}
var _photo_flash: float = 0.0

# Reentry corridor
var _entry_angle: float = -6.2
var _entry_hold: float = 0.0
var _entry_slider: HSlider
var _entry_bar: ProgressBar


static func create(challenge_mode: String) -> SpaceFlightMinigames:
	var m := SpaceFlightMinigames.new()
	m.mode = challenge_mode
	return m


func _ready() -> void:
	match mode:
		"heo_perigee": _build_heo_perigee()
		"heo_prox": _build_heo_prox()
		"heo_check": _build_heo_check()
		"tli_burn": _build_tli_burn()
		"cruise_dsn": _build_cruise_dsn()
		"cruise_tcm": _build_cruise_tcm()
		"cruise_storm": _build_cruise_storm()
		"flyby_los": _build_flyby_los()
		"flyby_science": _build_flyby_science()
		"flyby_gravity": _build_flyby_gravity()
		"reentry_sep": _build_reentry_sep()
		"reentry_corridor": _build_reentry_corridor()
		"reentry_chutes": _build_reentry_chutes()
		"reentry_splash": _build_reentry_splash()


func _build_heo_perigee() -> void:
	_build_shell("Elevación del Perigeo (Apogeo)", "Enciende el motor RL10 en el apogeo para elevar el perigeo por encima de la atmósfera", Vector2(780, 580), UITheme.CYAN, "CAPÍTULO 8 · ÓRBITA TERRESTRE ALTA")
	GameState.set_phase(CatalogData.FlightPhase.HEO)

	create_canvas(195.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 36)
		var ec := Vector2(sz.x * 0.35, sz.y * 0.52)
		c.draw_circle(ec, 24.0, UITheme.NASA_BLUE)
		c.draw_arc(ec, 34.0, 0.0, TAU, 36, Color(0.3, 0.7, 1.0, 0.45), 2.0)
		var pts := PackedVector2Array()
		for i in range(49):
			var th := (float(i) / 48.0) * TAU
			pts.append(Vector2(ec.x + 120.0 + cos(th) * 185.0, ec.y + sin(th) * 70.0))
		c.draw_polyline(pts, UITheme.CYAN, 2.5)
		var apogee := Vector2(ec.x + 120.0 + 185.0, ec.y)
		c.draw_circle(apogee, 8.0 + 3.0 * sin(t * 6.0), UITheme.GOLD)
		c.draw_string(ThemeDB.fallback_font, apogee + Vector2(-46, -16), "APOGEO", HORIZONTAL_ALIGNMENT_CENTER, 92, 12, UITheme.GOLD)
	)

	var btn := make_action_btn("Ejecutar Quemado RL10 en Apogeo (+42 m/s)", UITheme.CYAN, 48.0, 380.0)
	btn.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "Perigeo elevado a 1,850 km. Órbita segura confirmada.")
		ObjectiveManager.notify_event("heo_perigee_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	content_box.add_child(btn)


func _build_heo_prox() -> void:
	_build_shell("Aproximación RCS a la Etapa ICPS", "Reduce la distancia por debajo de 15 m manteniendo la velocidad relativa |v| ≤ 1.5 m/s", Vector2(800, 600), UITheme.CYAN, "CAPÍTULO 8 · PROXIMIDAD")

	create_canvas(195.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 40)
		var icps_x := 145.0
		var cy := sz.y * 0.54
		c.draw_rect(Rect2(icps_x - 36, cy - 20, 60, 40), Color(0.84, 0.86, 0.90))
		c.draw_rect(Rect2(icps_x + 24, cy - 14, 14, 28), Color(0.45, 0.50, 0.58))
		c.draw_string(ThemeDB.fallback_font, Vector2(icps_x - 34, cy - 30), "ICPS", HORIZONTAL_ALIGNMENT_CENTER, 68, 12, Color.WHITE)
		var px_per_m := (sz.x - 280.0) / 52.0
		var zone_x := icps_x + 38.0 + 15.0 * px_per_m
		c.draw_line(Vector2(zone_x, 24), Vector2(zone_x, sz.y - 24), UITheme.GREEN, 2.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(zone_x - 35, 18), "ZONA ≤15m", HORIZONTAL_ALIGNMENT_CENTER, 70, 11, UITheme.GREEN)

		var orion_x := icps_x + 38.0 + clampf(_prox_dist, 0.0, 52.0) * px_per_m
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(orion_x - 16, cy), Vector2(orion_x + 12, cy - 14), Vector2(orion_x + 12, cy + 14)
		]), UITheme.CYAN)
		if _rcs_dir != 0:
			var fx := orion_x - 18.0 if _rcs_dir > 0 else orion_x + 14.0
			c.draw_circle(Vector2(fx, cy), 6.0, UITheme.GOLD)
	)

	var row := make_centered_row(14)

	var b_fwd := make_action_btn("<< Acercar (-0.6 m/s RCS)", UITheme.CYAN, 48.0, 220.0)
	b_fwd.pressed.connect(func() -> void:
		_prox_vel -= 0.6
		_rcs_dir = -1
	)
	var b_brk := make_action_btn("Frenar (+0.6 m/s RCS) >>", UITheme.GOLD, 48.0, 220.0)
	b_brk.pressed.connect(func() -> void:
		_prox_vel += 0.6
		_rcs_dir = 1
	)
	var b_hold := make_action_btn("Mantener Posición", UITheme.GREEN, 48.0, 200.0)
	b_hold.pressed.connect(func() -> void:
		if _prox_dist <= 15.0 and absf(_prox_vel) <= 1.5:
			flash_feedback(UITheme.GREEN, "¡Proximidad controlada! Inspección visual completada.")
			ObjectiveManager.notify_event("heo_prox_done")
			await get_tree().create_timer(0.55).timeout
			finished.emit(true)
		else:
			flash_feedback(UITheme.RED, "Acércate a ≤ 15 m y frena hasta |v| ≤ 1.5 m/s.")
	)
	row.add_child(b_fwd)
	row.add_child(b_brk)
	row.add_child(b_hold)


func _build_heo_check() -> void:
	_build_shell("Verificación Go-For-Lunar-Burn", "Ejecuta el diagnóstico de los 3 sistemas críticos antes de abandonar la órbita terrestre", Vector2(780, 560), UITheme.GREEN, "CAPÍTULO 8 · CHEQUEO PRE-TLI")

	create_canvas(150.0, func(c: Control, t: float) -> void:
		var sz := c.size
		var labels: Array[String] = ["ECLSS Cabina", "Propulsión ESM", "Navegación IMU"]
		var bw := (sz.x - 80.0) / 3.0
		for i in range(3):
			var bx := 20.0 + float(i) * (bw + 20.0)
			var ok: bool = bool(_sys_checks.get(i, false))
			var col := UITheme.GREEN if ok else UITheme.CYAN
			c.draw_rect(Rect2(bx, 20, bw, 110), Color(0.06, 0.10, 0.16, 0.92), true)
			c.draw_rect(Rect2(bx, 20, bw, 110), col, false, 2.0)
			var level := 1.0 if ok else (0.35 + 0.25 * sin(t * 4.0 + float(i)))
			c.draw_rect(Rect2(bx + 16, 60, (bw - 32.0) * level, 18), col)
			c.draw_string(ThemeDB.fallback_font, Vector2(bx, 112), labels[i], HORIZONTAL_ALIGNMENT_CENTER, int(bw), 12, col)
	)

	var row := make_centered_row(12)
	var names: Array[String] = ["1) ECLSS Nominal", "2) Propulsión ESM", "3) Guiado IMU"]
	for i in range(3):
		var idx: int = i
		var b := make_action_btn("Chequear " + names[idx], UITheme.CYAN, 48.0, 220.0)
		b.pressed.connect(func() -> void:
			_sys_checks[idx] = true
			b.disabled = true
			b.modulate = UITheme.GREEN
			flash_feedback(UITheme.GREEN, "Sistema verificado (%d / 3)" % _sys_checks.size())
			if _sys_checks.size() == 3:
				ObjectiveManager.notify_event("heo_check_done")
				await get_tree().create_timer(0.55).timeout
				finished.emit(true)
		)
		row.add_child(b)


func _build_tli_burn() -> void:
	_build_shell("Quemado de Escape Lunar (TLI)", "Enciende el motor y pulsa CORTE (MECO) justo dentro de la ventana verde [3,050 – 3,150 m/s]", Vector2(800, 600), UITheme.GOLD, "CAPÍTULO 9 · INYECCIÓN TLI")
	GameState.set_phase(CatalogData.FlightPhase.TLI)

	create_canvas(175.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 36)
		var bar_x := 60.0
		var bar_w := sz.x - 120.0
		var bar_y := sz.y * 0.48
		c.draw_rect(Rect2(bar_x, bar_y, bar_w, 34), Color(0.08, 0.12, 0.18))
		var gx0 := bar_x + (3050.0 / 3400.0) * bar_w
		var gx1 := bar_x + (3150.0 / 3400.0) * bar_w
		c.draw_rect(Rect2(gx0, bar_y - 6, gx1 - gx0, 46), Color(UITheme.GREEN.r, UITheme.GREEN.g, UITheme.GREEN.b, 0.35))
		c.draw_rect(Rect2(gx0, bar_y - 6, gx1 - gx0, 46), UITheme.GREEN, false, 2.0)
		var fw := clampf(_tli_dv / 3400.0, 0.0, 1.0) * bar_w
		var col := UITheme.GREEN if (_tli_dv >= 3050.0 and _tli_dv <= 3150.0) else (UITheme.RED if _tli_dv > 3150.0 else UITheme.GOLD)
		c.draw_rect(Rect2(bar_x, bar_y + 3, fw, 28), col)
		c.draw_string(ThemeDB.fallback_font, Vector2(bar_x, bar_y - 14), "Δv actual: %.0f m/s   (Zona objetivo: 3,050 – 3,150 m/s)" % _tli_dv, HORIZONTAL_ALIGNMENT_LEFT, int(bar_w), 14, col)
	)

	_tli_bar = ProgressBar.new()
	_tli_bar.max_value = 3400.0
	_tli_bar.custom_minimum_size = Vector2(660, 22)
	_tli_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(_tli_bar)

	var row := make_centered_row(16)

	var b_start := make_action_btn("Iniciar Quemado TLI", UITheme.GOLD, 48.0, 220.0)
	b_start.pressed.connect(func() -> void:
		_tli_burning = true
		b_start.disabled = true
		flash_feedback(UITheme.GOLD, "¡Motor principal encendido! Prepárate para cortar en 3,050–3,150 m/s.")
	)
	var b_cut := make_action_btn("CORTAR MOTOR (MECO)", UITheme.RED, 48.0, 220.0)
	b_cut.pressed.connect(func() -> void:
		_tli_burning = false
		if _tli_dv >= 3050.0 and _tli_dv <= 3150.0:
			flash_feedback(UITheme.GREEN, "¡TLI exacto a %.0f m/s! Rumbo a la Luna." % _tli_dv)
			ObjectiveManager.notify_event("tli_burn_done")
			await get_tree().create_timer(0.55).timeout
			finished.emit(true)
		else:
			GameState.record_error(9, "tli_burn", "Corte TLI fuera de rango (%.0f m/s; objetivo 3050–3150 m/s)." % _tli_dv, "Un corte prematuro o tardío en TLI desvía el apogeo de la distancia lunar (~384,400 km).")
			_tli_dv = 0.0
			_tli_bar.value = 0.0
			b_start.disabled = false
			flash_feedback(UITheme.RED, "Corte fuera de rango. Reinicia el quemado TLI.")
	)
	row.add_child(b_start)
	row.add_child(b_cut)


func _build_cruise_dsn() -> void:
	_build_shell("Relevo de Antenas DSN (Tierra Rotando)", "Transfiere la señal secuencialmente: Goldstone -> Madrid -> Canberra", Vector2(800, 600), UITheme.CYAN, "CAPÍTULO 9 · RED ESPACIO PROFUNDO")
	GameState.set_phase(CatalogData.FlightPhase.CRUISE)

	create_canvas(180.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 32)
		var ec := Vector2(sz.x * 0.28, sz.y * 0.54)
		c.draw_circle(ec, 38.0, UITheme.NASA_BLUE)
		var orion := Vector2(sz.x * 0.80, sz.y * 0.50)
		c.draw_circle(orion, 10.0, Color.WHITE)
		for i in range(3):
			var ang := -0.7 + float(i - _dsn_step) * 1.1 + sin(t * 0.6) * 0.1
			var dish := ec + Vector2(cos(ang), sin(ang)) * 42.0
			var active := i == _dsn_step
			var col := UITheme.GREEN if i < _dsn_step else (UITheme.CYAN if active else Color(0.4, 0.45, 0.55))
			c.draw_circle(dish, 7.0, col)
			if active:
				c.draw_line(dish, orion, Color(UITheme.CYAN.r, UITheme.CYAN.g, UITheme.CYAN.b, 0.75), 3.0)
				var pkt := fmod(t * 1.5, 1.0)
				c.draw_circle(dish.lerp(orion, pkt), 5.0, UITheme.GOLD)
		c.draw_string(ThemeDB.fallback_font, Vector2(20, 24), "Retardo de señal a distancia lunar: ~1.28 s (velocidad luz c)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.CYAN)
	)

	var row := make_centered_row(12)
	for i in range(3):
		var s_idx: int = i
		var st_name: String = _dsn_stations[s_idx]
		var sb := make_action_btn("Enlazar " + st_name, UITheme.CYAN, 48.0, 220.0)
		sb.pressed.connect(func() -> void:
			if s_idx == _dsn_step:
				sb.disabled = true
				sb.modulate = UITheme.GREEN
				GameState.telemetry["dsn_station"] = st_name
				GameState.telemetry["signal_delay_s"] = 1.28
				_dsn_step += 1
				flash_feedback(UITheme.GREEN, "Enlace activo con %s (%d / 3)" % [st_name, _dsn_step])
				if _dsn_step == 3:
					ObjectiveManager.notify_event("cruise_dsn_done")
					await get_tree().create_timer(0.55).timeout
					finished.emit(true)
			else:
				flash_feedback(UITheme.RED, "Sigue la rotación terrestre: conecta primero " + _dsn_stations[_dsn_step])
		)
		row.add_child(sb)


func _build_cruise_tcm() -> void:
	_build_shell("Maniobra TCM-2 con Propulsores RCS", "Aplica el impulso fino (+1.4 m/s) para centrar el punto de impacto en la órbita lunar", Vector2(780, 560), UITheme.CYAN, "CAPÍTULO 9 · CORRECCIÓN TCM")

	create_canvas(175.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 32)
		var target := Vector2(sz.x * 0.72, sz.y * 0.50)
		c.draw_circle(target, 32.0, Color(0.82, 0.84, 0.88))
		c.draw_arc(target, 48.0, 0.0, TAU, 36, UITheme.GREEN, 2.0)
		c.draw_line(Vector2(60, sz.y * 0.65), Vector2(target.x, target.y - 38.0), UITheme.GOLD, 2.5)
		c.draw_line(Vector2(60, sz.y * 0.65), target + Vector2(0, -48), Color(UITheme.GREEN.r, UITheme.GREEN.g, UITheme.GREEN.b, 0.55), 2.0)
	)

	var btn := make_action_btn("Ejecutar Pulso TCM (+1.4 m/s RCS)", UITheme.CYAN, 48.0, 340.0)
	btn.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "Error de punto de puntería reducido a < 1.2 km.")
		ObjectiveManager.notify_event("cruise_tcm_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	content_box.add_child(btn)


func _build_cruise_storm() -> void:
	_build_shell("Tormenta de Partículas Solares (SPE)", "1) Refugia a la tripulación en la bahía protegida  2) Apaga cargas no críticas", Vector2(800, 580), UITheme.RED, "CAPÍTULO 9 · EMERGENCIA SOLAR")

	create_canvas(175.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 28)
		for i in range(28):
			var px := fmod(t * 260.0 + float(i) * 43.0, sz.x)
			var py := fmod(float(i) * 67.0 + sin(t * 3.0 + float(i)) * 14.0, sz.y)
			c.draw_line(Vector2(px, py), Vector2(px + 22, py), Color(1.0, 0.36, 0.22, 0.75), 2.5)
		var cx := sz.x * 0.62
		var cy := sz.y * 0.52
		c.draw_arc(Vector2(cx, cy), 46.0, -PI * 0.6, PI * 0.6, 28, UITheme.GOLD, 4.0)
		c.draw_circle(Vector2(cx, cy), 18.0, UITheme.CYAN)
		c.draw_string(ThemeDB.fallback_font, Vector2(cx - 50, cy + 56), "REFUGIO ANTI-RADIACIÓN", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, UITheme.GOLD)
	)

	var row := make_centered_row(14)
	var b1 := make_action_btn("1) Mover Tripulación al Refugio", UITheme.GOLD, 48.0, 280.0)
	var b2 := make_action_btn("2) Apagar Cargas No Críticas", UITheme.RED, 48.0, 280.0)
	b2.disabled = true
	b1.pressed.connect(func() -> void:
		b1.disabled = true
		b1.modulate = UITheme.GREEN
		b2.disabled = false
		ObjectiveManager.mark_substep(0)
		flash_feedback(UITheme.GOLD, "Tripulación protegida entre bolsas de agua y equipo. ¡Apaga cargas ahora!")
	)
	b2.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "Modo supervivencia solar estable hasta el fin del pico SPE.")
		ObjectiveManager.notify_event("cruise_storm_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	row.add_child(b1)
	row.add_child(b2)


func _build_flyby_los() -> void:
	_build_shell("Pérdida de Señal (LOS ~41 min)", "Activa el guiado autónomo inercial IMU durante el paso por detrás del disco lunar", Vector2(780, 580), UITheme.PURPLE, "CAPÍTULO 10 · CARA OCULTA")
	GameState.set_phase(CatalogData.FlightPhase.FLYBY)

	create_canvas(180.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 36)
		var mc := Vector2(sz.x * 0.5, sz.y * 0.55)
		c.draw_circle(mc, 44.0, Color(0.80, 0.82, 0.86))
		c.draw_colored_polygon(PackedVector2Array([
			mc + Vector2(0, -44), mc + Vector2(220, -68), mc + Vector2(220, 68), mc + Vector2(0, 44)
		]), Color(UITheme.PURPLE.r, UITheme.PURPLE.g, UITheme.PURPLE.b, 0.22))
		var orb_ang := fmod(t * 0.9, TAU)
		c.draw_circle(mc + Vector2(cos(orb_ang), sin(orb_ang)) * 66.0, 6.0, UITheme.CYAN)
		c.draw_string(ThemeDB.fallback_font, Vector2(mc.x + 56, mc.y), "ZONA LOS (SIN ENLACE DSN)", HORIZONTAL_ALIGNMENT_LEFT, 190, 12, UITheme.PURPLE)
	)

	var btn := make_action_btn("Conmutar a Guiado Inercial Autónomo (IMU)", UITheme.PURPLE, 48.0, 380.0)
	btn.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "Grabador de estado autónomo activado para travesía por la cara oculta.")
		ObjectiveManager.notify_event("flyby_los_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	content_box.add_child(btn)


func _build_flyby_science() -> void:
	_build_shell("Cámara Óptica de Alta Resolución", "Captura los 3 objetivos geológicos de la cara oculta durante la ventana de iluminación", Vector2(820, 600), UITheme.GOLD, "CAPÍTULO 10 · CIENCIA LUNAR")

	create_canvas(180.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 32)
		var mc := Vector2(sz.x * 0.5, sz.y * 0.52)
		c.draw_circle(mc, 74.0, Color(0.76, 0.78, 0.82))
		var offsets: Array[Vector2] = [Vector2(-32, -24), Vector2(28, 12), Vector2(-12, 34)]
		for i in range(3):
			var p: Vector2 = mc + offsets[i]
			var done: bool = bool(_sci_done.get(i, false))
			var col := UITheme.GREEN if done else UITheme.GOLD
			c.draw_arc(p, 16.0, 0.0, TAU, 24, col, 2.0)
			c.draw_circle(p, 6.0, Color(col.r, col.g, col.b, 0.4))
		c.draw_rect(Rect2(mc.x - 95, mc.y - 78, 190, 156), Color(UITheme.CYAN.r, UITheme.CYAN.g, UITheme.CYAN.b, 0.55), false, 2.0)
		if _photo_flash > 0.0:
			c.draw_rect(Rect2(0, 0, sz.x, sz.y), Color(1, 1, 1, _photo_flash * 0.45))
	)

	var row := make_centered_row(12)
	for i in range(3):
		var idx: int = i
		var tgt: String = _sci_targets[idx]
		var b := make_action_btn("Fotografiar " + tgt, UITheme.GOLD, 48.0, 230.0)
		b.pressed.connect(func() -> void:
			_sci_done[idx] = true
			_photo_flash = 1.0
			b.disabled = true
			b.modulate = UITheme.GREEN
			flash_feedback(UITheme.GREEN, "Captura %s archivada (%d / 3)" % [tgt, _sci_done.size()])
			if _sci_done.size() == 3:
				ObjectiveManager.notify_event("flyby_science_done")
				await get_tree().create_timer(0.55).timeout
				finished.emit(true)
		)
		row.add_child(b)


func _build_flyby_gravity() -> void:
	_build_shell("Asistencia Gravitatoria Lunar", "Observa el giro hiperbólico que acelera la nave hacia el pasillo de reentrada terrestre", Vector2(780, 580), UITheme.GREEN, "CAPÍTULO 10 · REGRESO PASIVO")

	create_canvas(185.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 36)
		var mc := Vector2(sz.x * 0.72, sz.y * 0.50)
		c.draw_circle(mc, 28.0, Color(0.84, 0.86, 0.90))
		var pts := PackedVector2Array()
		for i in range(33):
			var u := (float(i) / 32.0) * PI - PI * 0.5
			var px := mc.x + 56.0 - cos(u) * 260.0 * (0.25 + absf(sin(u)))
			var py := mc.y + sin(u) * 78.0
			pts.append(Vector2(px, py))
		c.draw_polyline(pts, UITheme.GREEN, 3.0)
		var idx := mini(32, int(fmod(t * 14.0, 32.0)))
		c.draw_circle(pts[idx], 6.0, UITheme.CYAN)
		c.draw_string(ThemeDB.fallback_font, Vector2(24, 24), "Asistencia lunar pasiva: rumbo directo al Pacífico Sur", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.GREEN)
	)

	var btn := make_action_btn("Confirmar Trayectoria de Regreso a Tierra", UITheme.GREEN, 48.0, 360.0)
	btn.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "Alineación trans-terrestre confirmada sin consumo de propelente.")
		ObjectiveManager.notify_event("flyby_gravity_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	content_box.add_child(btn)


func _build_reentry_sep() -> void:
	_build_shell("Separación del Módulo de Servicio (ESM)", "Eyécta el ESM y gira el escudo térmico Avcoat 180° hacia proa", Vector2(780, 580), UITheme.GOLD, "CAPÍTULO 11 · REENTRADA")
	GameState.set_phase(CatalogData.FlightPhase.REENTRY)

	create_canvas(180.0, func(c: Control, t: float) -> void:
		var sz := c.size
		draw_starfield(c, t, 36)
		var sep := fmod(t * 26.0, 55.0)
		var cy := sz.y * 0.54
		c.draw_rect(Rect2(sz.x * 0.36 - sep, cy - 18, 44, 36), Color(0.50, 0.56, 0.66))
		var ox := sz.x * 0.62 + sep * 0.5
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(ox - 18, cy), Vector2(ox + 16, cy - 22), Vector2(ox + 16, cy + 22)
		]), Color(0.88, 0.90, 0.94))
		c.draw_line(Vector2(ox + 18, cy - 22), Vector2(ox + 18, cy + 22), UITheme.GOLD, 5.0)
	)

	var btn := make_action_btn("Separar ESM y Orientar Escudo Térmico", UITheme.GOLD, 48.0, 360.0)
	btn.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "Pernos pirotécnicos detonados. Escudo Avcoat encarando la atmósfera.")
		ObjectiveManager.notify_event("reentry_sep_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	content_box.add_child(btn)


func _build_reentry_corridor() -> void:
	_build_shell("Entrada con Rebote (Skip Entry a ~11 km/s)", "Mantén el ángulo en la banda segura [-5.5° a -7.0°] durante 4.5 s (óptimo -6.2° ± 0.25°)", Vector2(820, 620), UITheme.RED, "CAPÍTULO 11 · CORREDOR ATMOSFÉRICO")

	create_canvas(185.0, func(c: Control, t: float) -> void:
		var sz := c.size
		var ev: Dictionary = AeroPhysics.evaluate_reentry_corridor(_entry_angle)
		var safe: bool = bool(ev.get("safe", false))
		var st: String = String(ev.get("status", ""))
		c.draw_rect(Rect2(0, 0, sz.x, sz.y), Color(0.04, 0.05, 0.12))
		c.draw_rect(Rect2(0, sz.y * 0.34, sz.x, sz.y * 0.34), Color(UITheme.GREEN.r, UITheme.GREEN.g, UITheme.GREEN.b, 0.18))
		c.draw_line(Vector2(0, sz.y * 0.34), Vector2(sz.x, sz.y * 0.34), UITheme.GREEN, 1.5)
		c.draw_line(Vector2(0, sz.y * 0.68), Vector2(sz.x, sz.y * 0.68), UITheme.GREEN, 1.5)

		var norm := clampf((-3.5 - _entry_angle) / 5.5, 0.0, 1.0)
		var py := lerpf(28.0, sz.y - 28.0, norm)
		var px := sz.x * 0.45
		var plasma_col := UITheme.GREEN if safe else UITheme.RED
		c.draw_circle(Vector2(px + 22, py), 26.0 + 6.0 * sin(t * 22.0), Color(plasma_col.r, plasma_col.g, plasma_col.b, 0.35))
		c.draw_circle(Vector2(px, py), 16.0, Color(0.88, 0.90, 0.94))
		c.draw_string(ThemeDB.fallback_font, Vector2(20, 24), "Ángulo: %.2f°  |  %s  |  Estabilidad: %.1f / 4.5 s" % [_entry_angle, st, _entry_hold], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, plasma_col)
	)

	_entry_slider = HSlider.new()
	_entry_slider.min_value = -9.0
	_entry_slider.max_value = -3.5
	_entry_slider.step = 0.05
	_entry_slider.value = -6.2
	_entry_slider.custom_minimum_size = Vector2(640, 26)
	_entry_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_entry_slider.value_changed.connect(func(v: float) -> void: _entry_angle = v)
	content_box.add_child(_entry_slider)

	_entry_bar = ProgressBar.new()
	_entry_bar.max_value = 4.5
	_entry_bar.custom_minimum_size = Vector2(640, 22)
	_entry_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(_entry_bar)


func _build_reentry_chutes() -> void:
	_build_shell("Descenso por Drogues y Principales", "1) Despliega los 2 paracaídas estabilizadores (drogues)  2) Despliega los 3 principales", Vector2(780, 580), UITheme.CYAN, "CAPÍTULO 11 · PARACAÍDAS")

	create_canvas(180.0, func(c: Control, t: float) -> void:
		var sz := c.size
		c.draw_rect(Rect2(0, 0, sz.x, sz.y), Color(0.14, 0.42, 0.72))
		var cx := sz.x * 0.5 + sin(t * 2.0) * 14.0
		var cy := sz.y * 0.72
		for k in [-1, 0, 1]:
			var sx := cx + float(k) * 58.0
			var sy := cy - 92.0
			c.draw_line(Vector2(cx, cy - 10), Vector2(sx, sy), Color.WHITE, 1.5)
			c.draw_arc(Vector2(sx, sy), 26.0, PI, TAU, 16, Color(1.0, 0.46, 0.14), 10.0)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(cx, cy - 18), Vector2(cx - 16, cy + 12), Vector2(cx + 16, cy + 12)
		]), Color(0.90, 0.92, 0.95))
	)

	var row := make_centered_row(14)
	var b1 := make_action_btn("1) Desplegar Drogues (7.6 km)", UITheme.GOLD, 48.0, 280.0)
	var b2 := make_action_btn("2) Desplegar 3 Principales (2.9 km)", UITheme.CYAN, 48.0, 300.0)
	b2.disabled = true
	b1.pressed.connect(func() -> void:
		b1.disabled = true
		b1.modulate = UITheme.GREEN
		b2.disabled = false
		ObjectiveManager.mark_substep(0)
		flash_feedback(UITheme.GREEN, "Drogues inflados. Velocidad estabilizada; lista secuencia principal.")
	)
	b2.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "¡Los 3 paracaídas principales abiertos! Descenso suave a ~8.9 m/s.")
		ObjectiveManager.notify_event("reentry_chutes_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	row.add_child(b1)
	row.add_child(b2)


func _build_reentry_splash() -> void:
	_build_shell("Recuperación USS John P. Murtha", "Activa las balsas de flotación, el faro SARSAT y confirma el rescate de la tripulación", Vector2(780, 580), UITheme.GREEN, "CAPÍTULO 11 · AMERIZAJE PACÍFICO")
	GameState.set_phase(CatalogData.FlightPhase.SPLASHDOWN)

	create_canvas(180.0, func(c: Control, t: float) -> void:
		var sz := c.size
		c.draw_rect(Rect2(0, 0, sz.x, sz.y * 0.56), Color(0.20, 0.52, 0.82))
		c.draw_rect(Rect2(0, sz.y * 0.56, sz.x, sz.y * 0.44), Color(0.06, 0.24, 0.48))
		var cx := sz.x * 0.5
		var bob := sin(t * 2.5) * 6.0
		var cy := sz.y * 0.56 + bob
		c.draw_arc(Vector2(cx, cy - 20), 12.0 + fmod(t * 28.0, 42.0), 0.0, TAU, 24, Color(1.0, 0.72, 0.20, 0.7), 2.5)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(cx, cy - 22), Vector2(cx - 20, cy + 10), Vector2(cx + 20, cy + 10)
		]), Color(0.90, 0.92, 0.95))
	)

	var btn := make_action_btn("Confirmar Flotación, Baliza y Rescate en Cubierta", UITheme.GREEN, 48.0, 420.0)
	btn.pressed.connect(func() -> void:
		flash_feedback(UITheme.GREEN, "¡Bienvenidos de vuelta a casa, tripulación Artemis II!")
		ObjectiveManager.notify_event("reentry_splash_done")
		await get_tree().create_timer(0.55).timeout
		finished.emit(true)
	)
	content_box.add_child(btn)


func _process(delta: float) -> void:
	if _photo_flash > 0.0:
		_photo_flash = maxf(0.0, _photo_flash - delta * 2.8)
	if mode == "heo_prox":
		_prox_dist = clampf(_prox_dist + _prox_vel * delta * 3.0, 0.0, 60.0)
		status_lbl.text = "Distancia a ICPS: %.1f m  (meta ≤ 15 m)  |  Velocidad: %+.1f m/s (meta |v| ≤ 1.5)" % [_prox_dist, _prox_vel]
		status_lbl.add_theme_color_override("font_color", UITheme.GREEN if (_prox_dist <= 15.0 and absf(_prox_vel) <= 1.5) else UITheme.CYAN)
	elif mode == "tli_burn" and _tli_burning:
		_tli_dv += delta * 420.0
		_tli_bar.value = _tli_dv
		set_bar_color(_tli_bar, UITheme.GREEN if (_tli_dv >= 3050.0 and _tli_dv <= 3150.0) else (UITheme.RED if _tli_dv > 3150.0 else UITheme.GOLD))
		status_lbl.text = "Quemando ESM... Δv = %.0f m/s (corta entre 3,050 y 3,150 m/s)" % _tli_dv
	elif mode == "reentry_corridor":
		_entry_angle = clampf(_entry_angle + sin(Time.get_ticks_msec() * 0.003) * delta * 0.35, -9.0, -3.5)
		_entry_slider.set_value_no_signal(_entry_angle)
		var ev: Dictionary = AeroPhysics.evaluate_reentry_corridor(_entry_angle)
		var safe: bool = bool(ev.get("safe", false))
		var st: String = String(ev.get("status", ""))
		if safe:
			_entry_hold += delta
			set_bar_color(_entry_bar, UITheme.GREEN)
		else:
			_entry_hold = maxf(0.0, _entry_hold - delta * 0.6)
			set_bar_color(_entry_bar, UITheme.RED)
		_entry_bar.value = _entry_hold
		status_lbl.text = "Ángulo: %.2f° -> %s | Progreso: %.1f / 4.5 s" % [_entry_angle, st, _entry_hold]
		status_lbl.add_theme_color_override("font_color", UITheme.GREEN if safe else UITheme.RED)
		if _entry_hold >= 4.5:
			set_process(false)
			if bool(ev.get("perfect", false)):
				AchievementManager.unlock("ach_perfect_reentry")
			flash_feedback(UITheme.GREEN, "¡Reentrada superada con éxito! Corredor mantenido.")
			ObjectiveManager.notify_event("reentry_corridor_done")
			await get_tree().create_timer(0.55).timeout
			finished.emit(true)
