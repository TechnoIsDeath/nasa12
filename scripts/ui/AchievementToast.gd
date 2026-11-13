class_name AchievementToast
extends PanelContainer

## Aviso emergente arriba a la derecha estilo Minecraft cuando se desbloquea un logro.
## mouse_filter = IGNORE para no interferir nunca con la interacción del jugador.

var icon_lbl: Label
var header_lbl: Label
var title_lbl: Label
var queue: Array[Dictionary] = []
var is_showing: bool = false
var _tween: Tween = null

func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	offset_left = -346.0
	offset_right = -16.0
	offset_top = -100.0
	offset_bottom = -26.0
	custom_minimum_size = Vector2(330, 74)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.get_theme()
	visible = false

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hbox)

	icon_lbl = UITheme.label("★", 28, UITheme.GREEN, true)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_lbl)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	header_lbl = UITheme.label("¡Logro conseguido!", 12, UITheme.GOLD, true)
	header_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_lbl)

	title_lbl = UITheme.label("", 15, Color.WHITE, true, true)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(ach_data: Dictionary) -> void:
	queue.append(ach_data)
	if not is_showing:
		_show_next()

func _show_next() -> void:
	if queue.is_empty():
		is_showing = false
		visible = false
		return

	is_showing = true
	var data: Dictionary = queue.pop_front()
	var atype: String = String(data.get("type", "normal"))

	var border_col: Color = UITheme.GREEN
	if atype == "goal":
		border_col = UITheme.GOLD
		header_lbl.text = "¡Meta de Capítulo!"
		header_lbl.add_theme_color_override("font_color", UITheme.GOLD)
		icon_lbl.text = "🏆"
		icon_lbl.add_theme_color_override("font_color", UITheme.GOLD)
	elif atype == "challenge":
		border_col = UITheme.PURPLE
		header_lbl.text = "¡Desafío Completado!"
		header_lbl.add_theme_color_override("font_color", UITheme.PURPLE)
		icon_lbl.text = "❖"
		icon_lbl.add_theme_color_override("font_color", UITheme.PURPLE)
	else:
		header_lbl.text = "¡Logro conseguido!"
		header_lbl.add_theme_color_override("font_color", UITheme.GOLD)
		icon_lbl.text = "★"
		icon_lbl.add_theme_color_override("font_color", UITheme.GREEN)

	add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.13, 0.96), border_col, 2, 8, 12, 10))
	title_lbl.text = String(data.get("title", "Logro"))

	visible = true
	offset_top = -96.0
	offset_bottom = -22.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "offset_top", 16.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "offset_bottom", 90.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(2.8)
	_tween.tween_property(self, "offset_top", -96.0, 0.25)
	_tween.parallel().tween_property(self, "offset_bottom", -22.0, 0.25)
	_tween.tween_callback(_show_next)
