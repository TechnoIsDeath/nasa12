class_name WaypointBeacon
extends Node3D

## Baliza 3D luminosa con columna de luz y rombo flotante sobre el objetivo activo.

var beam_mesh: MeshInstance3D
var diamond_mesh: MeshInstance3D
var label_3d: Label3D
var _time: float = 0.0

func _ready() -> void:
	beam_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.35
	cyl.height = 18.0
	beam_mesh.mesh = cyl
	beam_mesh.position = Vector3(0.0, 9.0, 0.0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.25, 0.85, 1.0, 0.22)
	bmat.emission_enabled = true
	bmat.emission = Color(0.25, 0.85, 1.0)
	bmat.emission_energy_multiplier = 1.8
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mesh.material_override = bmat
	add_child(beam_mesh)

	diamond_mesh = MeshInstance3D.new()
	var oct := BoxMesh.new()
	oct.size = Vector3(0.55, 0.55, 0.55)
	diamond_mesh.mesh = oct
	diamond_mesh.position = Vector3(0.0, 2.4, 0.0)
	diamond_mesh.rotation_degrees = Vector3(45.0, 0.0, 45.0)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(1.0, 0.85, 0.25)
	dmat.emission_enabled = true
	dmat.emission = Color(1.0, 0.80, 0.20)
	dmat.emission_energy_multiplier = 2.4
	diamond_mesh.material_override = dmat
	add_child(diamond_mesh)

	label_3d = Label3D.new()
	label_3d.position = Vector3(0.0, 3.2, 0.0)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.font_size = 38
	label_3d.modulate = Color(0.95, 0.98, 1.0)
	add_child(label_3d)

func set_target(world_pos: Vector3, title: String) -> void:
	global_position = world_pos
	label_3d.text = title
	visible = true

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	diamond_mesh.rotate_y(delta * 1.8)
	diamond_mesh.position.y = 2.4 + sin(_time * 3.0) * 0.25
