class_name HardwareMinigames
extends BaseMinigame

## Minijuegos del Capítulo 4 (Hardware de Orion):
## power, eclss, shield, antennas — versión interactiva y visual animada.

var mode: String = ""

# Power
var _solar_on: bool = false
var _batt_on: bool = false
var _loads: Dictionary = {"eclss": true, "avionics": true, "comms": false, "heater": false}
var _power_bar: ProgressBar

# ECLSS
var _amine_installed: bool = false
var _o2_slider: HSlider

# Shield
var _tiles_fixed: int = 0
var _bad_tiles := [2, 5, 7]

# Antennas
var _az_slider: HSlider
var _el_slider: HSlider

static func create(challenge_mode: String) -> HardwareMinigames:
	var m := HardwareMinigames.new()
	m.mode = challenge_mode
	return m

func _ready() -> void:
	match mode:
		"power":
			_setup_power()
		"eclss":
			_setup_eclss()
		"shield":
			_setup_shield()
		"antennas":
			_setup_antennas()

func _setup_power() -> void:
	_build_shell(
		"BUSES DE ENERGÍA DEL ESM (P = V · I)",
		"Conecta los Paneles Solares y Baterías, y activa ECLSS + Aviónica + Comms sin superar la potencia generada.",
		Vector2(820, 600),
		UITheme.GOLD,
		"CAP. 4 · BALANCE ENERGÉTICO"
	)

	create_canvas(120.0, func(c: Control, t: float):
		var s := c.size
		var cx := s.x * 0.5
		var cy := s.y * 0.5
		var sol_col := UITheme.GOLD if _solar_on else Color(0.25, 0.30, 0.40)
		var bat_col := UITheme.CYAN if _batt_on else Color(0.25, 0.30, 0.40)
		c.draw_rect(Rect2(45.0, cy - 36.0, 110.0, 28.0), sol_col, true)
		c.draw_rect(Rect2(45.0, cy + 8.0, 110.0, 28.0), bat_col, true)
		c.draw_line(Vector2(155.0, cy - 22.0), Vector2(cx - 40.0, cy), sol_col, 3.0)
		c.draw_line(Vector2(155.0, cy + 22.0), Vector2(cx - 40.0, cy), bat_col, 3.0)
		# Bus central con pulso eléctrico animado
		c.draw_circle(Vector2(cx, cy), 22.0 + sin(t * 5.0) * 2.0, UITheme.GREEN if (_solar_on and _batt_on) else Color(0.3, 0.35, 0.45))
		var pulse_x := fmod(t * 140.0, maxf(60.0, s.x * 0.35))
		if _solar_on:
			c.draw_circle(Vector2(155.0 + pulse_x * 0.55, cy - 22.0 + pulse_x * 0.12), 4.5, Color.WHITE)
		# Nodos de carga a la derecha
		var keys := ["eclss", "avionics", "comms", "heater"]
		for i in range(keys.size()):
			var ly := 18.0 + float(i) * 24.0
			var on := bool(_loads[keys[i]])
			var lcol := (UITheme.RED if keys[i] == "heater" else UITheme.GREEN) if on else Color(0.22, 0.28, 0.36)
			c.draw_line(Vector2(cx + 22.0, cy), Vector2(s.x - 140.0, ly + 8.0), lcol, 2.5 if on else 1.2)
			c.draw_rect(Rect2(s.x - 140.0, ly, 95.0, 16.0), lcol, true)
	)

	var gen_row := make_centered_row(12)
	var b_sol := CheckBox.new()
	b_sol.text = "☀️ Paneles Solares ESM (+11,200 W)"
	b_sol.toggled.connect(func(v): _solar_on = v; _update_power())
	gen_row.add_child(b_sol)

	var b_bat := CheckBox.new()
	b_bat.text = "🔋 Baterías Respaldo (+2,000 W)"
	b_bat.toggled.connect(func(v): _batt_on = v; _update_power())
	gen_row.add_child(b_bat)

	var items := [
		["eclss", "💨 Soporte Vital ECLSS (3,200 W — Esencial)"],
		["avionics", "🧭 Aviónica y Guiado (2,800 W — Esencial)"],
		["comms", "📡 Transmisor Banda S/Ka (2,400 W — Esencial)"],
		["heater", "🔥 Calefactores Alta Potencia (6,500 W — Opcional)"]
	]
	for it in items:
		var cb := CheckBox.new()
		cb.text = it[1]
		cb.button_pressed = bool(_loads[it[0]])
		cb.toggled.connect(func(v): _loads[it[0]] = v; _update_power())
		content_box.add_child(cb)

	_power_bar = ProgressBar.new()
	_power_bar.max_value = 15000.0
	_power_bar.custom_minimum_size = Vector2(0, 22)
	content_box.add_child(_power_bar)

	var row := make_centered_row()
	var verify_btn := make_action_btn("⚡ VALIDAR BALANCE ENERGÉTICO", UITheme.GREEN, 46.0, 320.0)
	verify_btn.pressed.connect(_verify_power)
	row.add_child(verify_btn)
	_update_power()

func _update_power() -> void:
	var gen: float = (11200.0 if _solar_on else 0.0) + (2000.0 if _batt_on else 0.0)
	var use: float = (3200.0 if _loads["eclss"] else 0.0) + (2800.0 if _loads["avionics"] else 0.0) + (2400.0 if _loads["comms"] else 0.0) + (6500.0 if _loads["heater"] else 0.0)
	_power_bar.value = use
	set_bar_color(_power_bar, UITheme.RED if use > gen else UITheme.GREEN)
	flash_feedback(UITheme.RED if use > gen else UITheme.CYAN, "Generación: %.0f W | Consumo: %.0f W | Margen: %+.0f W" % [gen, use, gen - use])

func _verify_power() -> void:
	var gen: float = (11200.0 if _solar_on else 0.0) + (2000.0 if _batt_on else 0.0)
	var use: float = (3200.0 if _loads["eclss"] else 0.0) + (2800.0 if _loads["avionics"] else 0.0) + (2400.0 if _loads["comms"] else 0.0) + (6500.0 if _loads["heater"] else 0.0)
	if not _solar_on or not _batt_on:
		flash_feedback(UITheme.GOLD, "Conecta primero los paneles solares y las baterías.")
		return
	if not (_loads["eclss"] and _loads["avionics"] and _loads["comms"]):
		flash_feedback(UITheme.GOLD, "Las cargas esenciales (ECLSS, Aviónica, Comms) deben estar activas.")
		return
	if use > gen:
		GameState.record_error(4, "hw_power_buses", "Sobrecarga eléctrica en buses de Orion.", "Cuando P_consumo > P_generada, el bus cae por debajo de tensión nominal.")
		flash_feedback(UITheme.RED, "¡Sobrecarga! Desconecta cargas opcionales.")
		return
	ObjectiveManager.notify_event("hw_power_done")
	finished.emit(true)

func _setup_eclss() -> void:
	_build_shell(
		"SOPORTE VITAL (ECLSS) — FILTROS DE CO₂ Y O₂/N₂",
		"Instala el lecho de amina para capturar CO₂ y ajusta el oxígeno de cabina al 20%–22%.",
		Vector2(820, 560),
		UITheme.GREEN,
		"CAP. 4 · SOPORTE VITAL"
	)

	var o2_lbl := UITheme.label("Concentración de O₂: 14.0 % (N₂: 86.0 %)", 16, Color.WHITE, true)
	o2_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	create_canvas(130.0, func(c: Control, t: float):
		var s := c.size
		var v := _o2_slider.value if is_instance_valid(_o2_slider) else 14.0
		var ok := absf(v - 21.0) <= 1.0
		# Partículas de O2 (cian) y N2 (azul tenue) circulando en cabina
		var o2_count := int(round(v * 0.8))
		for i in range(32):
			var px := fmod(float(i * 67 + 13) + t * (40.0 + float(i % 5) * 9.0), maxf(40.0, s.x - 40.0)) + 20.0
			var py := fmod(float(i * 43 + 7) + sin(t * 2.0 + float(i)) * 18.0, maxf(30.0, s.y - 30.0)) + 15.0
			var pcol := (UITheme.GREEN if ok else UITheme.CYAN) if i < o2_count else Color(0.45, 0.55, 0.72, 0.5)
			c.draw_circle(Vector2(px, py), 5.0 if i < o2_count else 3.5, pcol)
		if _amine_installed:
			c.draw_rect(Rect2(s.x * 0.5 - 110.0, s.y - 30.0, 220.0, 24.0), UITheme.GREEN.darkened(0.4), true)
			c.draw_rect(Rect2(s.x * 0.5 - 110.0, s.y - 30.0, 220.0, 24.0), UITheme.GREEN, false, 2.0)
	)

	var amine_row := make_centered_row()
	var amine_btn := make_action_btn("🧪 INSTALAR LECHO DE AMINA (CAPTURA DE CO₂)", UITheme.CYAN, 46.0, 420.0)
	amine_btn.pressed.connect(func():
		_amine_installed = true
		amine_btn.disabled = true
		amine_btn.text = "✔ LECHO DE AMINA INSTALADO"
		ObjectiveManager.mark_substep(0)
		flash_feedback(UITheme.GREEN, "Filtro de amina activo. Ahora equilibra el O₂ entre 20% y 22%.")
	)
	amine_row.add_child(amine_btn)

	content_box.add_child(o2_lbl)
	_o2_slider = HSlider.new()
	_o2_slider.min_value = 10.0
	_o2_slider.max_value = 40.0
	_o2_slider.step = 0.5
	_o2_slider.value = 14.0
	_o2_slider.value_changed.connect(func(v):
		var col := UITheme.GREEN if absf(v - 21.0) <= 1.0 else UITheme.GOLD
		o2_lbl.text = "Concentración de O₂: %.1f %% (N₂: %.1f %%) — Objetivo: 21%%" % [v, 100.0 - v]
		o2_lbl.add_theme_color_override("font_color", col)
	)
	content_box.add_child(_o2_slider)

	var done_row := make_centered_row()
	var done_btn := make_action_btn("✅ CERTIFICAR ATMÓSFERA DE CABINA", UITheme.GREEN, 46.0, 340.0)
	done_btn.pressed.connect(func():
		if not _amine_installed:
			flash_feedback(UITheme.GOLD, "Instala primero el filtro de amina.")
			return
		if absf(_o2_slider.value - 21.0) <= 1.0:
			ObjectiveManager.notify_event("hw_eclss_done")
			finished.emit(true)
		else:
			GameState.record_error(4, "hw_eclss", "Mezcla O₂/N₂ fuera de rango (%.1f%%)." % _o2_slider.value, "Menos de 19% causa hipoxia; más de 24% eleva el riesgo de incendio.")
			flash_feedback(UITheme.RED, "Ajusta el O₂ exactamente entre 20% y 22%.")
	)
	done_row.add_child(done_btn)

func _setup_shield() -> void:
	_build_shell(
		"INSPECCIÓN DEL ESCUDO TÉRMICO AVCOAT (~2,760 °C)",
		"Haz clic en los 3 bloques rojos con fisura térmica (> 15%) para reemplazarlos sin tocar los sanos.",
		Vector2(820, 560),
		UITheme.RED,
		"CAP. 4 · PROTECCIÓN TÉRMICA"
	)
	var center_grid := CenterContainer.new()
	content_box.add_child(center_grid)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	center_grid.add_child(grid)

	for i in range(10):
		var is_bad: bool = _bad_tiles.has(i)
		var btn := make_action_btn(
			"🔥 #%d\nErosión 28%%" % (i + 1) if is_bad else "🛡️ #%d\nNominal 2%%" % (i + 1),
			UITheme.RED if is_bad else UITheme.CYAN,
			74.0,
			132.0
		)
		btn.pressed.connect(func():
			if is_bad:
				btn.disabled = true
				btn.text = "✔ #%d\nNUEVO" % (i + 1)
				btn.add_theme_stylebox_override("disabled", UITheme.box(UITheme.GREEN.darkened(0.55), UITheme.GREEN, 2, 8, 12, 8))
				_tiles_fixed += 1
				flash_feedback(UITheme.GREEN, "Bloques defectuosos reemplazados: %d / 3" % _tiles_fixed)
				if _tiles_fixed >= 3:
					ObjectiveManager.notify_event("hw_shield_done")
					finished.emit(true)
			else:
				GameState.record_error(4, "hw_heat_shield", "Reemplazo innecesario de bloque Avcoat sano.", "La inspección no destructiva evita desmontar bloques nominales.")
				flash_feedback(UITheme.RED, "Ese bloque está sano (2%). Reemplaza solo los 3 con erosión > 15%.")
		)
		grid.add_child(btn)

func _setup_antennas() -> void:
	_build_shell(
		"ANTENAS EN BANDA S Y RADIO DE ESPACIO PROFUNDO",
		"Orienta la antena en el radar hasta alinear Azimut (180° ± 5°) y Elevación (45° ± 5°).",
		Vector2(820, 580),
		UITheme.CYAN,
		"CAP. 4 · COMUNICACIONES"
	)

	create_canvas(135.0, func(c: Control, t: float):
		var s := c.size
		var cx := s.x * 0.5
		var cy := s.y * 0.5
		var az := _az_slider.value if is_instance_valid(_az_slider) else 120.0
		var el := _el_slider.value if is_instance_valid(_el_slider) else 15.0
		var locked := absf(az - 180.0) <= 5.0 and absf(el - 45.0) <= 5.0
		# Mira polar de radar
		for r in [24.0, 46.0]:
			c.draw_arc(Vector2(cx, cy), r, 0.0, TAU, 36, Color(0.22, 0.38, 0.58), 1.5)
		c.draw_circle(Vector2(cx, cy), 8.0, UITheme.GREEN if locked else UITheme.GOLD)
		# Punto de puntería actual desplazado según error angular
		var err_x := (az - 180.0) * 1.1
		var err_y := -(el - 45.0) * 1.1
		var aim := Vector2(clampf(cx + err_x, 40.0, s.x - 40.0), clampf(cy + err_y, 16.0, s.y - 16.0))
		var acol := UITheme.GREEN if locked else UITheme.RED
		c.draw_line(aim + Vector2(-12, 0), aim + Vector2(12, 0), acol, 2.5)
		c.draw_line(aim + Vector2(0, -12), aim + Vector2(0, 12), acol, 2.5)
		c.draw_arc(aim, 10.0 + sin(t * 6.0) * 2.0, 0.0, TAU, 24, acol, 2.0)
	)

	var az_lbl := UITheme.label("Azimut: 120° (Objetivo: 180° ± 5°)", 14, Color.WHITE, true)
	az_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(az_lbl)
	_az_slider = HSlider.new()
	_az_slider.min_value = 0.0
	_az_slider.max_value = 360.0
	_az_slider.value = 120.0
	_az_slider.value_changed.connect(func(v): az_lbl.text = "Azimut: %.0f° (Objetivo: 180° ± 5°)" % v)
	content_box.add_child(_az_slider)

	var el_lbl := UITheme.label("Elevación: 15° (Objetivo: 45° ± 5°)", 14, Color.WHITE, true)
	el_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(el_lbl)
	_el_slider = HSlider.new()
	_el_slider.min_value = 0.0
	_el_slider.max_value = 90.0
	_el_slider.value = 15.0
	_el_slider.value_changed.connect(func(v): el_lbl.text = "Elevación: %.0f° (Objetivo: 45° ± 5°)" % v)
	content_box.add_child(_el_slider)

	var row := make_centered_row()
	var btn := make_action_btn("📡 BLOQUEAR ENLACE BANDA S", UITheme.GREEN, 46.0, 320.0)
	btn.pressed.connect(func():
		if absf(_az_slider.value - 180.0) <= 5.0 and absf(_el_slider.value - 45.0) <= 5.0:
			ObjectiveManager.notify_event("hw_antennas_done")
			finished.emit(true)
		else:
			flash_feedback(UITheme.RED, "Señal débil. Centra la mira en el blanco (Azimut 180°, Elevación 45°).")
	)
	row.add_child(btn)
