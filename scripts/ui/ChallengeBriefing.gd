class_name ChallengeBriefing
extends Control

## Panel de explicación científica (se abre al iniciar un reto o con [H]) y Glosario ([G]).
## Centrado automático sin desbordamientos, con scroll interno y cierre seguro con [H], [ESC] o [ESPACIO].

signal closed()

var panel: PanelContainer
var mode_lbl: Label
var title_lbl: Label
var body_scroll: ScrollContainer
var body_vbox: VBoxContainer
var briefing_lbl: Label
var formula_panel: PanelContainer
var formula_lbl: Label
var fact_panel: PanelContainer
var fact_lbl: Label
var glossary_box: VBoxContainer
var close_btn: Button
var is_glossary_mode: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.get_theme()
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.015, 0.025, 0.05, 0.78)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	panel.add_theme_stylebox_override("panel", UITheme.box(UITheme.PANEL, UITheme.CYAN, 2, 10, 24, 20))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Cabecera con logo NASA
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)

	if ResourceLoader.exists("res://nasa-logo-nasa-icon-transparent-free-png.webp"):
		var tex := load("res://nasa-logo-nasa-icon-transparent-free-png.webp") as Texture2D
		if tex:
			var logo := TextureRect.new()
			logo.texture = tex
			logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			logo.custom_minimum_size = Vector2(44, 44)
			header_row.add_child(logo)

	var h_text := VBoxContainer.new()
	h_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(h_text)

	mode_lbl = UITheme.label("BRIEFING CIENTÍFICO", 12, UITheme.CYAN, true)
	h_text.add_child(mode_lbl)

	title_lbl = UITheme.label("", 22, Color.WHITE, true, true)
	h_text.add_child(title_lbl)

	var top_x := Button.new()
	top_x.text = "✕"
	top_x.theme_type_variation = &"GhostButton"
	top_x.custom_minimum_size = Vector2(36, 36)
	top_x.pressed.connect(hide_panel)
	header_row.add_child(top_x)

	vbox.add_child(HSeparator.new())

	body_scroll = ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(620, 270)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(body_scroll)

	body_vbox = VBoxContainer.new()
	body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vbox.add_theme_constant_override("separation", 12)
	body_scroll.add_child(body_vbox)

	briefing_lbl = UITheme.label("", 15, UITheme.TEXT, false, true)
	body_vbox.add_child(briefing_lbl)

	formula_panel = PanelContainer.new()
	formula_panel.add_theme_stylebox_override("panel", UITheme.card(UITheme.GOLD, Color(0.035, 0.055, 0.10)))
	body_vbox.add_child(formula_panel)

	var f_vbox := VBoxContainer.new()
	f_vbox.add_theme_constant_override("separation", 4)
	formula_panel.add_child(f_vbox)
	f_vbox.add_child(UITheme.label("FUNDAMENTO CIENTÍFICO", 11, UITheme.GOLD, true))
	formula_lbl = UITheme.label("", 14, Color(1.0, 0.90, 0.45), true, true)
	f_vbox.add_child(formula_lbl)

	fact_panel = PanelContainer.new()
	fact_panel.add_theme_stylebox_override("panel", UITheme.card(UITheme.GREEN, Color(0.035, 0.065, 0.08)))
	body_vbox.add_child(fact_panel)

	var fa_vbox := VBoxContainer.new()
	fa_vbox.add_theme_constant_override("separation", 4)
	fact_panel.add_child(fa_vbox)
	fa_vbox.add_child(UITheme.label("DATO REAL NASA / ARTEMIS", 11, UITheme.GREEN, true))
	fact_lbl = UITheme.label("", 13, Color(0.75, 0.96, 0.84), false, true)
	fa_vbox.add_child(fact_lbl)

	glossary_box = VBoxContainer.new()
	glossary_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glossary_box.add_theme_constant_override("separation", 10)
	glossary_box.visible = false
	body_vbox.add_child(glossary_box)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	vbox.add_child(footer)

	close_btn = Button.new()
	close_btn.theme_type_variation = &"PrimaryButton"
	close_btn.text = "ENTENDIDO [ESPACIO / H / ESC]"
	close_btn.custom_minimum_size = Vector2(240, 40)
	close_btn.pressed.connect(hide_panel)
	footer.add_child(close_btn)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			hide_panel()

func show_objective(obj: Dictionary) -> void:
	if obj.is_empty():
		return
	is_glossary_mode = false
	glossary_box.visible = false
	briefing_lbl.visible = true
	formula_panel.visible = true
	fact_panel.visible = true
	body_scroll.scroll_vertical = 0

	var ch: int = int(obj.get("chapter", 0))
	mode_lbl.text = "BRIEFING CIENTÍFICO — %s" % CatalogData.CHAPTER_NAMES.get(ch, "").to_upper()
	title_lbl.text = String(obj.get("title", ""))
	briefing_lbl.text = String(obj.get("briefing", ""))
	formula_lbl.text = String(obj.get("science", ""))
	fact_lbl.text = String(obj.get("fact", ""))
	close_btn.text = "ENTENDIDO [ESPACIO / H]"
	visible = true
	close_btn.grab_focus.call_deferred()

func show_glossary() -> void:
	is_glossary_mode = true
	briefing_lbl.visible = false
	formula_panel.visible = false
	fact_panel.visible = false
	glossary_box.visible = true
	body_scroll.scroll_vertical = 0

	mode_lbl.text = "ENCICLOPEDIA ARTEMIS II"
	title_lbl.text = "Glosario Científico Desbloqueado (%d / %d)" % [
		ObjectiveManager.unlocked_glossary.size(),
		CatalogData.get_glossary_entries().size()
	]
	for c in glossary_box.get_children():
		glossary_box.remove_child(c)
		c.queue_free()

	var all_entries: Dictionary = CatalogData.get_glossary_entries()
	if ObjectiveManager.unlocked_glossary.is_empty():
		var empty_lbl := UITheme.label(
			"Completa retos científicos (desde el Capítulo 2) para desbloquear conceptos aeroespaciales aquí.",
			14, UITheme.TEXT_DIM, false, true
		)
		glossary_box.add_child(empty_lbl)
	else:
		for gid in ObjectiveManager.unlocked_glossary:
			if not all_entries.has(gid):
				continue
			var e: Dictionary = all_entries[gid]
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UITheme.card(UITheme.CYAN, UITheme.PANEL_SOFT))
			var cv := VBoxContainer.new()
			cv.add_theme_constant_override("separation", 4)
			cv.add_child(UITheme.label(String(e["title"]), 15, UITheme.CYAN, true, true))
			cv.add_child(UITheme.label(String(e["formula"]), 13, UITheme.GOLD, true, true))
			cv.add_child(UITheme.label(String(e["summary"]), 13, UITheme.TEXT, false, true))
			card.add_child(cv)
			glossary_box.add_child(card)

	close_btn.text = "CERRAR GLOSARIO [G / ESC]"
	visible = true
	close_btn.grab_focus.call_deferred()

func hide_panel() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
