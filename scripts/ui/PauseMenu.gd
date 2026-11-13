class_name PauseMenu
extends Control

## Mini menú de pausa al pulsar ESC durante la campaña.

signal resume_requested()
signal save_requested()
signal open_briefing_requested()
signal open_achievements_requested()
signal open_glossary_requested()
signal return_to_menu_requested()
signal quit_requested()

var _panel: PanelContainer
var _slot_pill_lbl: Label
var _stats_lbl: Label
var _save_feedback_lbl: Label
var _options_drawer: PanelContainer
var _sens_lbl: Label
var _sens_slider: HSlider
var _crt_chk: CheckButton


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.get_theme()
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.012, 0.022, 0.048, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(460, 0)
	_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.038, 0.062, 0.12, 0.97), UITheme.CYAN, 2, 14, 22, 18))
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	var top_bar := ColorRect.new()
	top_bar.custom_minimum_size = Vector2(0, 4)
	top_bar.color = UITheme.CYAN
	vbox.add_child(top_bar)

	var pill_box := PanelContainer.new()
	pill_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pill_box.add_theme_stylebox_override("panel", UITheme.box(UITheme.CYAN.darkened(0.68), UITheme.CYAN, 1, 10, 12, 3))
	_slot_pill_lbl = UITheme.label("PAUSA · ARCHIVO I", 11, UITheme.CYAN.lightened(0.45), true)
	pill_box.add_child(_slot_pill_lbl)
	vbox.add_child(pill_box)

	var title := UITheme.label("MENÚ DE MISIÓN", 22, Color.WHITE, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_stats_lbl = UITheme.label("Retos: 0/43  ·  Logros: 0/44  ·  00:00", 12, UITheme.TEXT_DIM)
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_stats_lbl)

	vbox.add_child(HSeparator.new())

	var b_resume := _btn("▶  Reanudar Misión  [ESC]", UITheme.GREEN, 44.0)
	b_resume.pressed.connect(func() -> void: resume_requested.emit())
	vbox.add_child(b_resume)

	var b_save := _btn("💾  Guardar Partida", UITheme.CYAN, 42.0)
	b_save.pressed.connect(func() -> void:
		save_requested.emit()
		_flash_saved()
	)
	vbox.add_child(b_save)

	_save_feedback_lbl = UITheme.label("", 12, UITheme.GREEN, true)
	_save_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_feedback_lbl.visible = false
	vbox.add_child(_save_feedback_lbl)

	# Fila rápida para paneles de ayuda
	var quick_row := HBoxContainer.new()
	quick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	quick_row.add_theme_constant_override("separation", 8)
	vbox.add_child(quick_row)

	var q_brief := _btn("[H] Briefing", UITheme.GOLD, 36.0, 130.0)
	q_brief.pressed.connect(func() -> void: open_briefing_requested.emit())
	var q_ach := _btn("[L] Logros", UITheme.GOLD, 36.0, 130.0)
	q_ach.pressed.connect(func() -> void: open_achievements_requested.emit())
	var q_glos := _btn("[G] Glosario", UITheme.PURPLE, 36.0, 130.0)
	q_glos.pressed.connect(func() -> void: open_glossary_requested.emit())
	quick_row.add_child(q_brief)
	quick_row.add_child(q_ach)
	quick_row.add_child(q_glos)

	var b_opts := _btn("⚙  Opciones Rápidas", UITheme.NASA_BLUE, 38.0)
	b_opts.pressed.connect(func() -> void:
		_options_drawer.visible = not _options_drawer.visible
	)
	vbox.add_child(b_opts)

	_options_drawer = PanelContainer.new()
	_options_drawer.visible = false
	_options_drawer.add_theme_stylebox_override("panel", UITheme.card(UITheme.GOLD, Color(0.03, 0.05, 0.095)))
	vbox.add_child(_options_drawer)

	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 6)
	_options_drawer.add_child(dbox)

	_sens_lbl = UITheme.label("Sensibilidad Ratón: %.2f" % GameState.mouse_sensitivity, 12, UITheme.GOLD)
	dbox.add_child(_sens_lbl)

	_sens_slider = HSlider.new()
	_sens_slider.min_value = 0.06
	_sens_slider.max_value = 0.40
	_sens_slider.step = 0.02
	_sens_slider.value = GameState.mouse_sensitivity
	_sens_slider.value_changed.connect(func(v: float) -> void:
		GameState.mouse_sensitivity = v
		_sens_lbl.text = "Sensibilidad Ratón: %.2f" % v
	)
	dbox.add_child(_sens_slider)

	_crt_chk = CheckButton.new()
	_crt_chk.text = "Efecto CRT en MOCR"
	_crt_chk.button_pressed = GameState.crt_enabled
	_crt_chk.toggled.connect(func(on: bool) -> void:
		GameState.crt_enabled = on
	)
	dbox.add_child(_crt_chk)

	vbox.add_child(HSeparator.new())

	var b_menu := _btn("🏠  Guardar y Volver al Menú de Partidas", UITheme.GOLD, 42.0)
	b_menu.pressed.connect(func() -> void: return_to_menu_requested.emit())
	vbox.add_child(b_menu)

	var b_quit := _btn("✖  Salir del Simulador", UITheme.RED, 38.0)
	b_quit.pressed.connect(func() -> void: quit_requested.emit())
	vbox.add_child(b_quit)


func open_pause() -> void:
	var roman: Array[String] = ["", "I", "II", "III"]
	var s: int = clampi(SaveSystem.active_slot, 1, 3)
	var cur := ObjectiveManager.get_current_objective()
	var ch: int = int(cur.get("chapter", 12))
	_slot_pill_lbl.text = "PAUSA · ARCHIVO %s · CAPÍTULO %d" % [roman[s], ch]
	_stats_lbl.text = "Retos: %d / %d   ·   Logros: %d / %d   ·   %s" % [
		ObjectiveManager.completed_count(),
		ObjectiveManager.total_count(),
		AchievementManager.unlocked.size(),
		AchievementManager.achievements.size(),
		SaveSystem.format_time(GameState.mission_time_sec)
	]
	_save_feedback_lbl.visible = false
	_options_drawer.visible = false
	_sens_slider.set_value_no_signal(GameState.mouse_sensitivity)
	_sens_lbl.text = "Sensibilidad Ratón: %.2f" % GameState.mouse_sensitivity
	_crt_chk.set_pressed_no_signal(GameState.crt_enabled)
	visible = true

	_panel.pivot_offset = Vector2(230, 180)
	_panel.scale = Vector2(0.92, 0.92)
	_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.16)


func close_pause() -> void:
	visible = false


func _flash_saved() -> void:
	var roman: Array[String] = ["", "I", "II", "III"]
	var s: int = clampi(SaveSystem.active_slot, 1, 3)
	_save_feedback_lbl.text = "✔  Progreso guardado en Expedición %s" % roman[s]
	_save_feedback_lbl.visible = true


func _btn(txt: String, col: Color, min_h: float, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.add_theme_stylebox_override("normal", UITheme.box(col.darkened(0.54), col, 2, 8, 14, 8))
	b.add_theme_stylebox_override("hover", UITheme.box(col.darkened(0.30), col.lightened(0.32), 2, 8, 14, 8))
	b.add_theme_stylebox_override("pressed", UITheme.box(col.darkened(0.18), Color.WHITE, 2, 8, 14, 8))
	return b
