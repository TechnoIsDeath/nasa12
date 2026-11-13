class_name ObjectiveTracker
extends PanelContainer

## Panel superior izquierdo que muestra el capítulo, el reto activo y sus subpasos (✔ / ☐).

var chapter_lbl: Label
var title_lbl: Label
var substeps_box: VBoxContainer
var progress_lbl: Label

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 16.0
	offset_top = 16.0
	custom_minimum_size = Vector2(345, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.get_theme()
	add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.065, 0.115, 0.90), UITheme.CYAN, 2, 8, 14, 12))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	chapter_lbl = UITheme.label("", 11, UITheme.CYAN, true)
	chapter_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(chapter_lbl)

	title_lbl = UITheme.label("", 16, Color.WHITE, true, true)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	substeps_box = VBoxContainer.new()
	substeps_box.add_theme_constant_override("separation", 4)
	substeps_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(substeps_box)

	vbox.add_child(HSeparator.new())

	progress_lbl = UITheme.label("", 12, UITheme.TEXT_DIM)
	progress_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(progress_lbl)

	var hints_row := HBoxContainer.new()
	hints_row.add_theme_constant_override("separation", 10)
	hints_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hints_row.add_child(UITheme.key_hint("H", "Briefing"))
	hints_row.add_child(UITheme.key_hint("L", "Logros"))
	hints_row.add_child(UITheme.key_hint("G", "Glosario"))
	vbox.add_child(hints_row)

	ObjectiveManager.objective_started.connect(_on_refresh)
	ObjectiveManager.substep_updated.connect(_on_substep)
	ObjectiveManager.objective_completed.connect(_on_refresh)
	refresh()

func _on_refresh(_obj: Dictionary) -> void:
	refresh()

func _on_substep(_obj: Dictionary, _idx: int) -> void:
	refresh()

func refresh() -> void:
	var obj: Dictionary = ObjectiveManager.get_current_objective()
	if obj.is_empty():
		chapter_lbl.text = "CAMPAÑA COMPLETADA"
		title_lbl.text = "¡Misión Artemis II Finalizada!"
		for c in substeps_box.get_children():
			substeps_box.remove_child(c)
			c.queue_free()
		progress_lbl.text = "Retos: %d / %d" % [ObjectiveManager.completed_count(), ObjectiveManager.total_count()]
		return

	var ch: int = int(obj.get("chapter", 0))
	chapter_lbl.text = CatalogData.CHAPTER_NAMES.get(ch, "Capítulo %d" % ch).to_upper()
	title_lbl.text = String(obj.get("title", ""))

	for c in substeps_box.get_children():
		substeps_box.remove_child(c)
		c.queue_free()

	var subs: Array = obj.get("substeps", [])
	var done_arr: Array = ObjectiveManager.get_substeps_status(String(obj["id"]))
	for i in range(subs.size()):
		var is_done: bool = i < done_arr.size() and bool(done_arr[i])
		var lbl := UITheme.label(
			"%s %s" % ["✔" if is_done else "☐", String(subs[i])],
			13,
			UITheme.GREEN if is_done else UITheme.TEXT,
			is_done,
			true
		)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		substeps_box.add_child(lbl)

	progress_lbl.text = "Campaña: %d / %d retos   |   Logros: %d%%" % [
		ObjectiveManager.completed_count(),
		ObjectiveManager.total_count(),
		int(round(AchievementManager.get_progress_pct()))
	]
