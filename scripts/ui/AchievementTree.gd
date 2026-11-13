class_name AchievementTree
extends Control

## Pestaña de logros estilo Minecraft (tecla [L]) con pestañas por capítulo,
## nodos conectados, estados (bloqueado/disponible/conseguido) y descripción al pasar el ratón.

signal closed()

var tab_bar: HBoxContainer
var tree_canvas: Control
var tooltip_lbl: Label
var progress_lbl: Label
var active_tab: String = "Tierra"
var _tab_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.get_theme()
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.025, 0.05, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(920, 560)
	frame.add_theme_stylebox_override("panel", UITheme.box(UITheme.PANEL, UITheme.CYAN, 2, 10, 20, 16))
	center.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	frame.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	vbox.add_child(top_row)

	var title := UITheme.label("ÁRBOL DE LOGROS — ARTEMIS II", 20, Color.WHITE, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)

	progress_lbl = UITheme.label("", 14, UITheme.GOLD, true)
	top_row.add_child(progress_lbl)

	var close_btn := Button.new()
	close_btn.theme_type_variation = &"GhostButton"
	close_btn.text = "Cerrar [L / ESC]"
	close_btn.pressed.connect(hide_tree)
	top_row.add_child(close_btn)

	tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_bar)
	for tname in AchievementManager.get_tabs():
		var b := Button.new()
		b.text = tname
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(func():
			active_tab = tname
			_rebuild_tree()
		)
		tab_bar.add_child(b)
		_tab_buttons[tname] = b

	var bg_panel := PanelContainer.new()
	bg_panel.custom_minimum_size = Vector2(880, 380)
	bg_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.03, 0.05, 0.085), UITheme.BORDER, 1, 8, 0, 0))
	vbox.add_child(bg_panel)

	tree_canvas = Control.new()
	tree_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.add_child(tree_canvas)

	var tip_panel := PanelContainer.new()
	tip_panel.add_theme_stylebox_override("panel", UITheme.card(UITheme.CYAN, UITheme.PANEL_SOFT))
	vbox.add_child(tip_panel)

	tooltip_lbl = UITheme.label("Pasa el ratón sobre un nodo para ver su descripción y tipo.", 14, UITheme.TEXT, false, true)
	tip_panel.add_child(tooltip_lbl)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			hide_tree()

func show_tree() -> void:
	visible = true
	_rebuild_tree()

func hide_tree() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _rebuild_tree() -> void:
	progress_lbl.text = "%d / %d (%.0f%%)" % [
		AchievementManager.unlocked.size(),
		AchievementManager.achievements.size(),
		AchievementManager.get_progress_pct()
	]
	for tname in _tab_buttons.keys():
		var tb := _tab_buttons[tname] as Button
		if tname == active_tab:
			tb.add_theme_stylebox_override("normal", UITheme.box(UITheme.NASA_BLUE, UITheme.CYAN, 2, 6, 8, 6))
			tb.add_theme_stylebox_override("hover", UITheme.box(UITheme.NASA_BLUE.lightened(0.08), UITheme.CYAN, 2, 6, 8, 6))
		else:
			tb.remove_theme_stylebox_override("normal")
			tb.remove_theme_stylebox_override("hover")

	for c in tree_canvas.get_children():
		tree_canvas.remove_child(c)
		c.queue_free()

	var items: Array[Dictionary] = AchievementManager.get_by_tab(active_tab)
	var start_x: float = 28.0
	var step_x: float = 170.0
	var start_y: float = 60.0
	var step_y: float = 148.0

	var positions: Dictionary = {}
	for i in range(items.size()):
		var col: int = i % 5
		var row: int = i / 5
		positions[items[i]["id"]] = Vector2(start_x + col * step_x, start_y + row * step_y)

	# Líneas de conexión entre nodos dentro de la pestaña
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var pid: String = String(it.get("parent", ""))
		if positions.has(pid):
			var l := Line2D.new()
			l.width = 3.5
			var both_done: bool = AchievementManager.is_unlocked(it["id"])
			l.default_color = UITheme.GREEN if both_done else Color(0.28, 0.34, 0.45)
			l.add_point(positions[pid] + Vector2(74, 34))
			l.add_point(positions[it["id"]] + Vector2(74, 34))
			tree_canvas.add_child(l)
		elif not pid.is_empty():
			var prev_ach: Dictionary = AchievementManager.get_achievement(pid)
			if not prev_ach.is_empty():
				var pre_lbl := UITheme.label("← Requiere: %s (%s)" % [String(prev_ach["title"]), String(prev_ach["tab"])], 11, UITheme.TEXT_DIM)
				pre_lbl.position = positions[it["id"]] + Vector2(0, -20)
				tree_canvas.add_child(pre_lbl)

	# Nodos
	for it in items:
		var aid: String = String(it["id"])
		var pos: Vector2 = positions[aid]
		var is_done: bool = AchievementManager.is_unlocked(aid)
		var is_avail: bool = AchievementManager.is_available(aid)
		var atype: String = String(it.get("type", "normal"))

		var btn := Button.new()
		btn.position = pos
		btn.size = Vector2(148, 68)
		var prefix: String = "🏆 " if atype == "goal" else ("❖ " if atype == "challenge" else "★ ")
		btn.text = prefix + String(it["title"])
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 11)

		var bg_col: Color
		var border_col: Color
		if is_done:
			bg_col = Color(0.11, 0.30, 0.20)
			border_col = UITheme.GOLD if atype == "goal" else (UITheme.PURPLE if atype == "challenge" else UITheme.GREEN)
		elif is_avail:
			bg_col = UITheme.PANEL_HI
			border_col = UITheme.CYAN
		else:
			bg_col = Color(0.06, 0.08, 0.11)
			border_col = Color(0.20, 0.24, 0.30)
			btn.modulate = Color(0.70, 0.72, 0.78)

		var sb_n := UITheme.box(bg_col, border_col, 2, 7, 8, 6)
		var sb_h := UITheme.box(bg_col.lightened(0.08), border_col.lightened(0.2), 2, 7, 8, 6)
		btn.add_theme_stylebox_override("normal", sb_n)
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_h)
		btn.add_theme_stylebox_override("focus", sb_h)

		btn.mouse_entered.connect(func():
			var state_txt: String = "CONSEGUIDO" if is_done else ("DISPONIBLE" if is_avail else "BLOQUEADO")
			var type_txt: String = "Meta dorada" if atype == "goal" else ("Desafío" if atype == "challenge" else "Progreso")
			tooltip_lbl.text = "[%s | %s] %s — %s" % [state_txt, type_txt, String(it["title"]), String(it["desc"])]
		)
		tree_canvas.add_child(btn)
