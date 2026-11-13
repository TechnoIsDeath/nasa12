class_name MissionControlHUD
extends CanvasLayer

## HUD principal de Cosmic Blueprint: Misión Artemis.
## Solo muestra automáticamente la notificación de logro estilo Minecraft;
## las ventanas de Briefing [H], Glosario [G] y Logros [L] se abren bajo demanda o al pulsar [E].

signal minigame_requested(challenge_id: String)
signal return_to_main_menu_requested()
signal quit_game_requested()

var player: FirstPersonPlayer
var tracker: ObjectiveTracker
var compass: Compass
var toast: AchievementToast
var ach_tree: AchievementTree
var briefing: ChallengeBriefing
var info_popup: InfoTerminalPopup
var pause_menu: PauseMenu
var transition: TransitionOverlay
var menu_blocked: bool = false

var prompt_panel: PanelContainer
var prompt_lbl: Label
var notice_panel: PanelContainer
var notice_lbl: Label
var _notice_tween: Tween = null
var zone_lbl: Label
var crt_overlay: ColorRect
var receipt_overlay: Control
var receipt_panel: PanelContainer
var receipt_text: RichTextLabel
var minigame_layer: Control

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Overlay CRT sutil (activable en MCC)
	crt_overlay = ColorRect.new()
	crt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.visible = false
	if ResourceLoader.exists("res://shaders/crt_vhs.gdshader"):
		var sh := load("res://shaders/crt_vhs.gdshader") as Shader
		if sh:
			var smat := ShaderMaterial.new()
			smat.shader = sh
			crt_overlay.material = smat
	add_child(crt_overlay)

	# Mira central
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -10
	crosshair.offset_right = 10
	crosshair.offset_top = -14
	crosshair.offset_bottom = 14
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.add_theme_font_size_override("font_size", 22)
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.80))
	add_child(crosshair)

	# Píldora de interacción [E]
	var prompt_center := CenterContainer.new()
	prompt_center.anchor_left = 0.0
	prompt_center.anchor_right = 1.0
	prompt_center.anchor_top = 0.5
	prompt_center.anchor_bottom = 0.5
	prompt_center.offset_top = 34.0
	prompt_center.offset_bottom = 78.0
	prompt_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt_center)

	prompt_panel = PanelContainer.new()
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.theme = UITheme.get_theme()
	prompt_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.07, 0.13, 0.92), UITheme.GOLD, 1, 18, 16, 6))
	prompt_panel.visible = false
	prompt_center.add_child(prompt_panel)

	prompt_lbl = UITheme.label("", 15, UITheme.GOLD, true)
	prompt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.add_child(prompt_lbl)

	# Aviso breve bajo la brújula (retroalimentación al pulsar [E])
	var notice_center := CenterContainer.new()
	notice_center.anchor_left = 0.0
	notice_center.anchor_right = 1.0
	notice_center.anchor_top = 0.0
	notice_center.offset_top = 62.0
	notice_center.offset_bottom = 104.0
	notice_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notice_center)

	notice_panel = PanelContainer.new()
	notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_panel.theme = UITheme.get_theme()
	notice_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.08, 0.15, 0.92), UITheme.CYAN, 1, 10, 16, 6))
	notice_panel.visible = false
	notice_center.add_child(notice_panel)

	notice_lbl = UITheme.label("", 13, Color.WHITE, true)
	notice_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_panel.add_child(notice_lbl)

	# Barra inferior izquierda: ubicación actual
	var zone_panel := PanelContainer.new()
	zone_panel.anchor_left = 0.0
	zone_panel.anchor_top = 1.0
	zone_panel.anchor_bottom = 1.0
	zone_panel.offset_left = 16.0
	zone_panel.offset_top = -52.0
	zone_panel.offset_bottom = -14.0
	zone_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone_panel.theme = UITheme.get_theme()
	zone_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.065, 0.115, 0.86), UITheme.BORDER, 1, 8, 12, 6))
	add_child(zone_panel)

	zone_lbl = UITheme.label("UBICACIÓN: CASA", 13, UITheme.CYAN, true)
	zone_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone_panel.add_child(zone_lbl)

	# Barra inferior derecha: controles rápidos
	var controls_panel := PanelContainer.new()
	controls_panel.anchor_left = 1.0
	controls_panel.anchor_right = 1.0
	controls_panel.anchor_top = 1.0
	controls_panel.anchor_bottom = 1.0
	controls_panel.offset_left = -540.0
	controls_panel.offset_right = -16.0
	controls_panel.offset_top = -52.0
	controls_panel.offset_bottom = -14.0
	controls_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_panel.theme = UITheme.get_theme()
	controls_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.065, 0.115, 0.86), UITheme.BORDER, 1, 8, 12, 6))
	add_child(controls_panel)

	var ctrl_row := HBoxContainer.new()
	ctrl_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl_row.add_theme_constant_override("separation", 12)
	ctrl_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl_row.add_child(UITheme.key_hint("WASD", "Mover"))
	ctrl_row.add_child(UITheme.key_hint("Shift", "Correr"))
	ctrl_row.add_child(UITheme.key_hint("E", "Interactuar"))
	ctrl_row.add_child(UITheme.key_hint("V", "3.ª Pers."))
	ctrl_row.add_child(UITheme.key_hint("F", "Linterna"))
	controls_panel.add_child(ctrl_row)

	tracker = ObjectiveTracker.new()
	add_child(tracker)

	compass = Compass.new()
	add_child(compass)

	toast = AchievementToast.new()
	add_child(toast)

	minigame_layer = Control.new()
	minigame_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	minigame_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(minigame_layer)

	info_popup = InfoTerminalPopup.new()
	info_popup.closed.connect(func(_ok): _sync_ui_lock())
	add_child(info_popup)

	briefing = ChallengeBriefing.new()
	briefing.closed.connect(_on_modal_closed)
	add_child(briefing)

	ach_tree = AchievementTree.new()
	ach_tree.closed.connect(_on_modal_closed)
	add_child(ach_tree)

	_build_receipt_panel()

	pause_menu = PauseMenu.new()
	pause_menu.resume_requested.connect(close_pause_menu)
	pause_menu.save_requested.connect(func() -> void:
		SaveSystem.save_progress(-1, player)
	)
	pause_menu.open_briefing_requested.connect(func() -> void:
		close_pause_menu()
		open_briefing()
	)
	pause_menu.open_achievements_requested.connect(func() -> void:
		close_pause_menu()
		open_achievements()
	)
	pause_menu.open_glossary_requested.connect(func() -> void:
		close_pause_menu()
		open_glossary()
	)
	pause_menu.return_to_menu_requested.connect(func() -> void:
		SaveSystem.save_progress(-1, player)
		close_pause_menu()
		close_all_modals()
		return_to_main_menu_requested.emit()
	)
	pause_menu.quit_requested.connect(func() -> void:
		SaveSystem.save_progress(-1, player)
		quit_game_requested.emit()
	)
	add_child(pause_menu)

	transition = TransitionOverlay.new()
	add_child(transition)

	GameState.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.current_zone)

func setup_player(p: FirstPersonPlayer) -> void:
	player = p
	player.hover_prompt_changed.connect(_on_hover_prompt)
	_sync_ui_lock()

func _on_hover_prompt(txt: String) -> void:
	prompt_lbl.text = txt
	prompt_panel.visible = not txt.is_empty()

func show_hud_notice(txt: String, border_col: Color = UITheme.CYAN) -> void:
	notice_lbl.text = txt
	notice_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.08, 0.15, 0.94), border_col, 1, 10, 16, 6))
	notice_panel.visible = true
	notice_panel.modulate.a = 1.0
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(2.6)
	_notice_tween.tween_property(notice_panel, "modulate:a", 0.0, 0.4)
	_notice_tween.tween_callback(func(): notice_panel.visible = false)

func _on_zone_changed(z: String) -> void:
	var pretty: Dictionary = {
		"HOME": "CASA DEL ASTRONAUTA",
		"CAMPUS": "CAMPUS NASA · CENTRO ESPACIAL KENNEDY",
		"TRAINING": "EDIFICIO DE ENTRENAMIENTO",
		"VAB": "EDIFICIO DE ENSAMBLAJE VERTICAL (VAB)",
		"MCC": "CONTROL DE MISIÓN (MOCR)"
	}
	zone_lbl.text = "UBICACIÓN: %s" % String(pretty.get(z, z))
	crt_overlay.visible = (z == "MCC") and GameState.crt_enabled

func set_menu_blocked(blocked: bool) -> void:
	menu_blocked = blocked
	if blocked:
		if pause_menu:
			pause_menu.close_pause()
		close_all_modals()
	_sync_ui_lock()

func open_pause_menu() -> void:
	if menu_blocked or pause_menu == null:
		return
	pause_menu.open_pause()
	_sync_ui_lock()

func close_pause_menu() -> void:
	if pause_menu == null:
		return
	pause_menu.close_pause()
	crt_overlay.visible = (GameState.current_zone == "MCC") and GameState.crt_enabled
	_sync_ui_lock()

func close_all_modals() -> void:
	if briefing and briefing.visible:
		briefing.visible = false
	if ach_tree and ach_tree.visible:
		ach_tree.visible = false
	if receipt_overlay and receipt_overlay.visible:
		receipt_overlay.visible = false
	if info_popup and info_popup.visible:
		info_popup.visible = false
	clear_minigames()

func _sync_ui_lock() -> void:
	var pause_open: bool = pause_menu != null and pause_menu.visible
	if get_tree():
		get_tree().paused = menu_blocked or pause_open
	if player == null:
		return
	var any_open: bool = menu_blocked or pause_open or briefing.visible or ach_tree.visible or receipt_overlay.visible or info_popup.visible or has_active_minigame()
	player.set_ui_open(any_open)

func open_briefing(obj: Dictionary = {}) -> void:
	var target_obj: Dictionary = obj if not obj.is_empty() else ObjectiveManager.get_current_objective()
	if target_obj.is_empty():
		return
	if ach_tree.visible:
		ach_tree.visible = false
	if receipt_overlay.visible:
		receipt_overlay.visible = false
	if info_popup.visible:
		info_popup.visible = false
	briefing.show_objective(target_obj)
	_sync_ui_lock()

func open_glossary() -> void:
	if ach_tree.visible:
		ach_tree.visible = false
	if receipt_overlay.visible:
		receipt_overlay.visible = false
	if info_popup.visible:
		info_popup.visible = false
	briefing.show_glossary()
	_sync_ui_lock()

func open_achievements() -> void:
	if briefing.visible:
		briefing.visible = false
	if receipt_overlay.visible:
		receipt_overlay.visible = false
	if info_popup.visible:
		info_popup.visible = false
	ach_tree.show_tree()
	_sync_ui_lock()

func open_info_popup(hdr: String, ttl: String, bbcode_body: String, btn_txt: String, on_confirm: Callable = Callable()) -> void:
	if briefing.visible:
		briefing.visible = false
	if ach_tree.visible:
		ach_tree.visible = false
	if receipt_overlay.visible:
		receipt_overlay.visible = false
	info_popup.show_info(hdr, ttl, bbcode_body, btn_txt, on_confirm)
	_sync_ui_lock()

func _on_modal_closed() -> void:
	_sync_ui_lock()

func has_active_minigame() -> bool:
	return minigame_layer.get_child_count() > 0

func launch_minigame(ctrl: Control) -> void:
	clear_minigames()
	if briefing.visible:
		briefing.visible = false
	if ach_tree.visible:
		ach_tree.visible = false
	if receipt_overlay.visible:
		receipt_overlay.visible = false
	if info_popup.visible:
		info_popup.visible = false
	minigame_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	minigame_layer.add_child(ctrl)
	_sync_ui_lock()

func clear_minigames() -> void:
	for c in minigame_layer.get_children():
		minigame_layer.remove_child(c)
		c.queue_free()
	minigame_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_ui_lock()

func _input(event: InputEvent) -> void:
	if menu_blocked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_H:
			if pause_menu and pause_menu.visible:
				pause_menu.close_pause()
			get_viewport().set_input_as_handled()
			if briefing.visible and not briefing.is_glossary_mode:
				briefing.hide_panel()
			else:
				open_briefing()
		elif k.keycode == KEY_G:
			if pause_menu and pause_menu.visible:
				pause_menu.close_pause()
			get_viewport().set_input_as_handled()
			if briefing.visible and briefing.is_glossary_mode:
				briefing.hide_panel()
			else:
				open_glossary()
		elif k.keycode == KEY_L:
			if pause_menu and pause_menu.visible:
				pause_menu.close_pause()
			get_viewport().set_input_as_handled()
			if ach_tree.visible:
				ach_tree.hide_tree()
			else:
				open_achievements()
		elif k.keycode == KEY_ESCAPE:
			if pause_menu and pause_menu.visible:
				get_viewport().set_input_as_handled()
				close_pause_menu()
			elif briefing.visible:
				get_viewport().set_input_as_handled()
				briefing.hide_panel()
			elif ach_tree.visible:
				get_viewport().set_input_as_handled()
				ach_tree.hide_tree()
			elif info_popup.visible:
				get_viewport().set_input_as_handled()
				info_popup.visible = false
				_sync_ui_lock()
			elif receipt_overlay.visible:
				get_viewport().set_input_as_handled()
				receipt_overlay.visible = false
				_sync_ui_lock()
			elif has_active_minigame():
				get_viewport().set_input_as_handled()
				clear_minigames()
			else:
				get_viewport().set_input_as_handled()
				open_pause_menu()

func _build_receipt_panel() -> void:
	receipt_overlay = Control.new()
	receipt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	receipt_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	receipt_overlay.theme = UITheme.get_theme()
	receipt_overlay.visible = false
	add_child(receipt_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.025, 0.05, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	receipt_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	receipt_overlay.add_child(center)

	receipt_panel = PanelContainer.new()
	receipt_panel.custom_minimum_size = Vector2(600, 540)
	receipt_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.96, 0.95, 0.90), Color(0.22, 0.24, 0.28), 3, 6, 22, 18))
	center.add_child(receipt_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	receipt_panel.add_child(vbox)

	receipt_text = RichTextLabel.new()
	receipt_text.bbcode_enabled = true
	receipt_text.custom_minimum_size = Vector2(550, 440)
	receipt_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	receipt_text.add_theme_color_override("default_color", Color(0.10, 0.11, 0.14))
	vbox.add_child(receipt_text)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var close_btn := Button.new()
	close_btn.text = "CERRAR RECIBO [ESC]"
	close_btn.pressed.connect(func():
		receipt_overlay.visible = false
		_sync_ui_lock()
	)
	btn_row.add_child(close_btn)

	var restart_btn := Button.new()
	restart_btn.theme_type_variation = &"PrimaryButton"
	restart_btn.text = "NUEVA CAMPAÑA"
	restart_btn.pressed.connect(func():
		receipt_overlay.visible = false
		SaveSystem.delete_save()
		AchievementManager.reset()
		ObjectiveManager.start_new_campaign()
		_sync_ui_lock()
	)
	btn_row.add_child(restart_btn)

func show_debrief_receipt() -> void:
	var r: Dictionary = GameState.generate_debrief_receipt()
	var txt: String = "[center][b]==========================================\n"
	txt += "NASA — RECIBO MATRICIAL DE MISIÓN\n"
	txt += "%s\n" % r["mission"]
	txt += "==========================================[/b][/center]\n\n"
	txt += "[b]CALIFICACIÓN FINAL:[/b] %s (%d / 100 pts)\n" % [r["grade"], int(r["score"])]
	txt += "[b]LOGROS CONSEGUIDOS:[/b] %.0f%% (%d / %d)\n" % [
		float(r["achievement_pct"]),
		AchievementManager.unlocked.size(),
		AchievementManager.achievements.size()
	]
	txt += "[b]ERRORES REGISTRADOS:[/b] %d\n\n" % int(r["errors_count"])

	txt += "[b]--- DESGLOSE POR CAPÍTULO ---[/b]\n"
	var scores: Dictionary = r["chapter_scores"]
	for ch in range(0, 12):
		var sc: int = int(scores.get(str(ch), 100))
		txt += "  Cap.%02d %-34s %3d pts\n" % [ch, CatalogData.CHAPTER_NAMES.get(ch, ""), sc]

	var errs: Array = r["errors"]
	if not errs.is_empty():
		txt += "\n[b]--- ERRORES Y EXPLICACIÓN FÍSICA ---[/b]\n"
		for e in errs:
			txt += "• [Cap.%d] %s\n  Física: %s\n" % [int(e["chapter"]), String(e["message"]), String(e["physics_explanation"])]
	else:
		txt += "\n[b]¡EJECUCIÓN IMPECABLE! Cero errores operacionales.[/b]\n"

	receipt_text.text = txt
	if briefing.visible:
		briefing.visible = false
	if ach_tree.visible:
		ach_tree.visible = false
	if info_popup.visible:
		info_popup.visible = false
	receipt_overlay.visible = true
	_sync_ui_lock()
	ObjectiveManager.notify_event("debrief_viewed")
