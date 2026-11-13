class_name TransitionOverlay
extends CanvasLayer

## Transición circular estilo Roblox Adopt Me para cambios de escenario y entrada/salida de edificios.

var rect: ColorRect
var shader_mat: ShaderMaterial
var title_box: VBoxContainer
var sub_lbl: Label
var title_lbl: Label
var _is_transitioning: bool = false

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists("res://shaders/iris_transition.gdshader"):
		var sh := load("res://shaders/iris_transition.gdshader") as Shader
		if sh:
			shader_mat = ShaderMaterial.new()
			shader_mat.shader = sh
			shader_mat.set_shader_parameter("progress", 0.0)
			rect.material = shader_mat
	else:
		rect.color = Color(0.02, 0.04, 0.09, 0.0)
	add_child(rect)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	title_box = VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 6)
	title_box.modulate.a = 0.0
	center.add_child(title_box)

	sub_lbl = UITheme.label("TRASLADANDO...", 13, UITheme.CYAN, true)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(sub_lbl)

	title_lbl = UITheme.label("", 28, Color.WHITE, true)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(title_lbl)

func is_busy() -> bool:
	return _is_transitioning

func play_teleport(dest_title: String, dest_subtitle: String, on_midpoint: Callable) -> void:
	if _is_transitioning:
		return
	if OS.get_cmdline_user_args().has("--run-self-test"):
		if on_midpoint.is_valid():
			on_midpoint.call()
		return

	_is_transitioning = true
	visible = true
	title_lbl.text = dest_title.to_upper()
	sub_lbl.text = dest_subtitle.to_upper()
	title_box.modulate.a = 0.0

	var vp_sz := get_viewport().get_visible_rect().size
	if shader_mat and vp_sz.y > 0.0:
		shader_mat.set_shader_parameter("aspect", vp_sz.x / vp_sz.y)

	var tw := create_tween()
	if shader_mat:
		shader_mat.set_shader_parameter("progress", 0.0)
		tw.tween_method(func(v: float): shader_mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(rect, "color:a", 1.0, 0.36)
	tw.parallel().tween_property(title_box, "modulate:a", 1.0, 0.25).set_delay(0.12)
	tw.tween_callback(func():
		if on_midpoint.is_valid():
			on_midpoint.call()
	)
	tw.tween_interval(0.32)
	tw.tween_property(title_box, "modulate:a", 0.0, 0.22)
	if shader_mat:
		tw.parallel().tween_method(func(v: float): shader_mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw.parallel().tween_property(rect, "color:a", 0.0, 0.42)
	tw.tween_callback(func():
		visible = false
		_is_transitioning = false
	)
