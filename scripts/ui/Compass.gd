class_name Compass
extends PanelContainer

## Brújula superior con flecha direccional hacia el objetivo activo y distancia en metros.

var dir_lbl: Label
var target_lbl: Label

func _ready() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	offset_left = -180.0
	offset_right = 180.0
	offset_top = 14.0
	custom_minimum_size = Vector2(360, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.get_theme()
	add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.065, 0.115, 0.88), UITheme.CYAN, 1, 20, 16, 6))

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hbox)

	dir_lbl = UITheme.label("▲", 16, UITheme.GREEN, true)
	dir_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(dir_lbl)

	target_lbl = UITheme.label("Objetivo — 0 m", 14, Color.WHITE, true)
	target_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(target_lbl)

func update_compass(player_pos: Vector3, player_forward: Vector3, target_pos: Vector3, target_name: String) -> void:
	var flat_to: Vector3 = Vector3(target_pos.x - player_pos.x, 0.0, target_pos.z - player_pos.z)
	var dist: float = flat_to.length()
	if dist < 0.8:
		dir_lbl.text = "●"
		dir_lbl.add_theme_color_override("font_color", UITheme.GOLD)
		target_lbl.text = "%s — AQUÍ" % target_name
		return
	dir_lbl.add_theme_color_override("font_color", UITheme.GREEN)
	var dir_to: Vector3 = flat_to.normalized()
	var fwd: Vector3 = Vector3(player_forward.x, 0.0, player_forward.z).normalized()
	var cross_y: float = fwd.cross(dir_to).y
	var dot_val: float = fwd.dot(dir_to)
	if dot_val > 0.80:
		dir_lbl.text = "▲"
	elif dot_val < -0.70:
		dir_lbl.text = "▼"
	elif cross_y > 0.0:
		dir_lbl.text = "◀"
	else:
		dir_lbl.text = "▶"
	target_lbl.text = "%s — %.0f m" % [target_name, dist]
