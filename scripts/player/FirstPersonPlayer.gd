class_name FirstPersonPlayer
extends CharacterBody3D

## Controlador de Jugador en 1.ª/3.ª Persona para Cosmic Blueprint: Misión Artemis.
## Usa el rig Mixamo de walk_briefcase.fbx con animaciones de jump_a.fbx, jump_b.fbx
## y running_jump.fbx (con root motion XZ eliminado), más guantes astronaut_glove.glb en 1.ª persona.

signal hover_prompt_changed(prompt: String)
signal interact_requested(target_node: Node)

const WALK_SPEED: float = 6.5
const SPRINT_SPEED: float = 11.2
const JUMP_VELOCITY: float = 6.2
const GRAVITY: float = 15.5
const MOUSE_SENSITIVITY: float = 0.16

var head: Node3D
var camera: Camera3D
var raycast: RayCast3D
var flashlight: SpotLight3D
var left_arm_mesh: Node3D
var right_arm_mesh: Node3D
var suit_pivot: Node3D
var suit_meshes: Array[MeshInstance3D] = []
var suit_anim_player: AnimationPlayer = null

var third_person: bool = false
var ui_open: bool = false
var current_prompt: String = ""
var _jump_toggle: bool = false
var _bob_time: float = 0.0
var _interact_anim_timer: float = 0.0

# Seguimiento para el tutorial del Capítulo 0
var _moved_dist: float = 0.0
var _looked_deg: float = 0.0
var _has_jumped: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.80
	col.shape = cap
	col.position = Vector3(0.0, 0.90, 0.0)
	add_child(col)

	head = Node3D.new()
	head.position = Vector3(0.0, 1.62, 0.0)
	add_child(head)

	camera = Camera3D.new()
	camera.fov = 72.0
	camera.current = true
	head.add_child(camera)

	raycast = RayCast3D.new()
	raycast.target_position = Vector3(0.0, 0.0, -5.2)
	raycast.collision_mask = 4
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = true
	raycast.enabled = true
	camera.add_child(raycast)

	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(0.95, 0.97, 1.0)
	flashlight.light_energy = 2.8
	flashlight.spot_range = 30.0
	flashlight.spot_angle = 38.0
	flashlight.visible = false
	camera.add_child(flashlight)

	_build_first_person_arms()
	_build_spacesuit_model()
	_apply_camera_perspective()

func _build_spacesuit_model() -> void:
	suit_pivot = Node3D.new()
	suit_pivot.name = "SpacesuitPivot"
	add_child(suit_pivot)

	var base_path: String = "res://assets/characters/walk_briefcase.fbx"
	var suit_scene_node: Node3D = _load_scene(base_path)
	if suit_scene_node == null:
		suit_scene_node = _load_scene("res://assets/models/robonaut_player.glb")
	if suit_scene_node == null:
		return

	# walk_briefcase.fbx mide ~0.0241 unidades en Y (escala cm) y mira hacia +Z -> escalar a 1.80m y rotar 180°
	if ResourceLoader.exists(base_path):
		suit_scene_node.scale = Vector3.ONE * 74.0
		suit_scene_node.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	else:
		suit_scene_node.scale = Vector3.ONE
		suit_scene_node.rotation_degrees = Vector3.ZERO
	suit_scene_node.position = Vector3.ZERO
	suit_pivot.add_child(suit_scene_node)

	suit_meshes.clear()
	_collect_meshes(suit_scene_node)
	_style_robonaut_meshes()

	suit_anim_player = _find_animation_player(suit_scene_node)
	if suit_anim_player != null:
		_setup_character_animations(suit_anim_player)

func _setup_character_animations(ap: AnimationPlayer) -> void:
	var lib := AnimationLibrary.new()
	var walk_anim := _extract_clean_anim("res://assets/characters/walk_briefcase.fbx", true)
	if walk_anim != null:
		lib.add_animation(&"walk", walk_anim)
	else:
		var list := ap.get_animation_list()
		if not list.is_empty():
			var existing := ap.get_animation(list[0]).duplicate() as Animation
			_strip_xz_root_motion(existing)
			existing.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation(&"walk", existing)

	var ja := _extract_clean_anim("res://assets/characters/jump_a.fbx", false)
	if ja != null:
		lib.add_animation(&"jump_a", ja)

	var jb := _extract_clean_anim("res://assets/characters/jump_b.fbx", false)
	if jb != null:
		lib.add_animation(&"jump_b", jb)

	var rj := _extract_clean_anim("res://assets/characters/running_jump.fbx", false)
	if rj != null:
		lib.add_animation(&"run_jump", rj)

	var idle_a := _extract_clean_anim("res://assets/characters/breathing_idle.fbx", true)
	if idle_a != null:
		lib.add_animation(&"idle", idle_a)

	var push_a := _extract_clean_anim("res://assets/characters/button_pushing.fbx", false)
	if push_a != null:
		lib.add_animation(&"interact", push_a)

	if ap.has_animation_library(&"artemis"):
		ap.remove_animation_library(&"artemis")
	ap.add_animation_library(&"artemis", lib)

	if lib.has_animation(&"idle"):
		ap.play(&"artemis/idle")
	elif lib.has_animation(&"walk"):
		ap.play(&"artemis/walk")
		ap.seek(0.0, true)
		ap.pause()

func _extract_clean_anim(fbx_path: String, should_loop: bool) -> Animation:
	if not ResourceLoader.exists(fbx_path):
		return null
	var ps := load(fbx_path) as PackedScene
	if ps == null:
		return null
	var inst := ps.instantiate()
	var ap := _find_animation_player(inst)
	var result: Animation = null
	if ap != null:
		var names := ap.get_animation_list()
		if not names.is_empty():
			result = ap.get_animation(names[0]).duplicate() as Animation
			_strip_xz_root_motion(result)
			result.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	inst.free()
	return result

func _strip_xz_root_motion(anim: Animation) -> void:
	if anim == null:
		return
	for t in range(anim.get_track_count()):
		if anim.track_get_type(t) == Animation.TYPE_POSITION_3D:
			var path_str: String = String(anim.track_get_path(t))
			if "Hips" in path_str:
				var kc: int = anim.track_get_key_count(t)
				if kc <= 0:
					continue
				var base_v: Vector3 = anim.track_get_key_value(t, 0)
				for k in range(kc):
					var v: Vector3 = anim.track_get_key_value(t, k)
					anim.track_set_key_value(t, k, Vector3(base_v.x, v.y, base_v.z))

func _style_robonaut_meshes() -> void:
	# Mejora el aspecto cerámico/dorado del Robonaut manteniendo limpieza
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.88, 0.64, 0.14)
	visor_mat.metallic = 0.92
	visor_mat.roughness = 0.14
	for mi in suit_meshes:
		var nm: String = mi.name.to_lower()
		if nm in ["obj28", "obj29", "obj30"]: # Visor en walk_briefcase
			mi.material_override = visor_mat

func _build_first_person_arms() -> void:
	left_arm_mesh = _create_astronaut_arm(true)
	left_arm_mesh.position = Vector3(-0.34, -0.35, -0.46)
	left_arm_mesh.rotation_degrees = Vector3(14.0, -16.0, 20.0)
	camera.add_child(left_arm_mesh)

	right_arm_mesh = _create_astronaut_arm(false)
	right_arm_mesh.position = Vector3(0.34, -0.35, -0.46)
	right_arm_mesh.rotation_degrees = Vector3(14.0, 16.0, -20.0)
	camera.add_child(right_arm_mesh)

func _create_astronaut_arm(is_left: bool) -> Node3D:
	var arm_root := Node3D.new()
	var glove := _load_scene("res://assets/models/astronaut_glove.glb")
	if glove != null:
		glove.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		var first_mesh := _find_first_mesh(glove)
		var target_scale: float = 0.028
		if first_mesh != null:
			var sz: Vector3 = first_mesh.get_aabb().size
			var md: float = maxf(sz.x, maxf(sz.y, sz.z))
			if md > 0.01:
				target_scale = 0.34 / md
		glove.scale = Vector3.ONE * target_scale
		_disable_shadow_recursive(glove)
		var holder := Node3D.new()
		holder.scale = Vector3(1.0 if is_left else -1.0, 1.0, 1.0)
		holder.add_child(glove)
		arm_root.add_child(holder)
	return arm_root

func _disable_shadow_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in node.get_children():
		_disable_shadow_recursive(c)

func _load_scene(res_path: String) -> Node3D:
	if ResourceLoader.exists(res_path):
		var packed := load(res_path) as PackedScene
		if packed:
			return packed.instantiate() as Node3D
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path) and doc.append_from_file(abs_path, state) == OK:
		return doc.generate_scene(state) as Node3D
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for c in node.get_children():
		var found := _find_animation_player(c)
		if found != null:
			return found
	return null

func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for c in node.get_children():
		var found := _find_first_mesh(c)
		if found != null:
			return found
	return null

func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		suit_meshes.append(mi)
	for c in node.get_children():
		_collect_meshes(c)

func _apply_camera_perspective() -> void:
	if third_person:
		camera.position = Vector3(0.42, 0.42, 2.85)
		raycast.target_position = Vector3(0.0, 0.0, -7.8)
		for m in suit_meshes:
			m.visible = true
		if left_arm_mesh:
			left_arm_mesh.visible = false
		if right_arm_mesh:
			right_arm_mesh.visible = false
	else:
		camera.position = Vector3.ZERO
		raycast.target_position = Vector3(0.0, 0.0, -5.2)
		for m in suit_meshes:
			m.visible = false
		if left_arm_mesh:
			left_arm_mesh.visible = true
		if right_arm_mesh:
			right_arm_mesh.visible = true

func toggle_third_person() -> void:
	third_person = not third_person
	_apply_camera_perspective()

func set_ui_open(open: bool) -> void:
	ui_open = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if ui_open:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		var sens: float = GameState.mouse_sensitivity if GameState else MOUSE_SENSITIVITY
		rotate_y(deg_to_rad(-mm.relative.x * sens))
		head.rotate_x(deg_to_rad(-mm.relative.y * sens))
		var max_pitch: float = 55.0 if third_person else 82.0
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
		_looked_deg += absf(mm.relative.x) + absf(mm.relative.y)
		if _looked_deg > 180.0:
			ObjectiveManager.mark_substep(1)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_F:
			flashlight.visible = not flashlight.visible
		elif k.keycode == KEY_V:
			toggle_third_person()
		elif k.keycode == KEY_E:
			_try_interact()

func _try_interact() -> void:
	if raycast.is_colliding():
		var hit := raycast.get_collider() as Node
		if hit:
			var target: Node = hit
			if not target.has_meta("interact_id") and target.get_parent() and target.get_parent().has_meta("interact_id"):
				target = target.get_parent()
			if target.has_meta("interact_id"):
				_interact_anim_timer = 0.75
				interact_requested.emit(target)

func _physics_process(delta: float) -> void:
	if ui_open:
		velocity.x = 0.0
		velocity.z = 0.0
		_update_character_animation(false, false, false, delta)
		return

	var jumped_now := false
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_VELOCITY
		jumped_now = true
		if not _has_jumped:
			_has_jumped = true
			ObjectiveManager.mark_substep(2)

	var dir_input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir_input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir_input.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir_input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir_input.x += 1.0

	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)
	var speed: float = SPRINT_SPEED if is_sprinting else WALK_SPEED
	var direction: Vector3 = (transform.basis * Vector3(dir_input.x, 0.0, dir_input.y)).normalized()
	var is_moving: bool = direction != Vector3.ZERO
	if is_moving:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		_moved_dist += speed * delta
		if _moved_dist > 2.5:
			ObjectiveManager.mark_substep(0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
	_update_character_animation(is_moving, is_sprinting, jumped_now, delta)

	var obj: Dictionary = ObjectiveManager.get_current_objective()
	if not obj.is_empty() and obj.get("id", "") == "home_wake_up":
		if _moved_dist > 2.5 and _looked_deg > 180.0 and _has_jumped:
			ObjectiveManager.notify_event("woke_up")

	_update_hover_prompt()

func _update_character_animation(is_moving: bool, is_sprinting: bool, jumped_now: bool, delta: float) -> void:
	# Balanceo sutil de brazos en 1.ª persona
	if not third_person and left_arm_mesh and right_arm_mesh:
		if is_moving and is_on_floor():
			_bob_time += delta * (11.5 if is_sprinting else 7.8)
			var dy := sin(_bob_time) * 0.018
			var dx := cos(_bob_time * 0.5) * 0.012
			left_arm_mesh.position = Vector3(-0.34 + dx, -0.35 + dy, -0.46)
			right_arm_mesh.position = Vector3(0.34 - dx, -0.35 - dy, -0.46)
		else:
			left_arm_mesh.position = left_arm_mesh.position.lerp(Vector3(-0.34, -0.35, -0.46), minf(1.0, delta * 8.0))
			right_arm_mesh.position = right_arm_mesh.position.lerp(Vector3(0.34, -0.35, -0.46), minf(1.0, delta * 8.0))

	if suit_anim_player == null:
		return

	if _interact_anim_timer > 0.0:
		_interact_anim_timer = maxf(0.0, _interact_anim_timer - delta)
		if not is_moving and suit_anim_player.has_animation(&"artemis/interact"):
			if String(suit_anim_player.current_animation) != "artemis/interact":
				suit_anim_player.speed_scale = 1.35
				suit_anim_player.play(&"artemis/interact", 0.10)
			return

	if jumped_now:
		_jump_toggle = not _jump_toggle
		if is_moving and suit_anim_player.has_animation(&"artemis/run_jump"):
			suit_anim_player.speed_scale = 1.15
			suit_anim_player.play(&"artemis/run_jump", 0.12)
			return
		var jname := &"artemis/jump_a" if _jump_toggle else &"artemis/jump_b"
		if suit_anim_player.has_animation(jname):
			suit_anim_player.speed_scale = 1.25
			suit_anim_player.play(jname, 0.12)
			return

	if not is_on_floor():
		return

	var cur: String = String(suit_anim_player.current_animation)
	if is_moving:
		if cur != "artemis/walk" or not suit_anim_player.is_playing():
			suit_anim_player.play(&"artemis/walk", 0.18)
		suit_anim_player.speed_scale = 1.55 if is_sprinting else 1.05
	else:
		if suit_anim_player.has_animation(&"artemis/idle"):
			if cur != "artemis/idle" or not suit_anim_player.is_playing():
				suit_anim_player.speed_scale = 1.0
				suit_anim_player.play(&"artemis/idle", 0.22)
		elif suit_anim_player.has_animation(&"artemis/walk"):
			if cur != "artemis/walk":
				suit_anim_player.play(&"artemis/walk", 0.15)
			suit_anim_player.seek(0.0, true)
			suit_anim_player.pause()

func _update_hover_prompt() -> void:
	var new_prompt: String = ""
	if raycast.is_colliding():
		var hit := raycast.get_collider() as Node
		if hit:
			var target: Node = hit
			if not target.has_meta("interact_id") and target.get_parent() and target.get_parent().has_meta("interact_id"):
				target = target.get_parent()
			if target.has_meta("interact_prompt"):
				new_prompt = "[E] " + String(target.get_meta("interact_prompt"))
	if new_prompt != current_prompt:
		current_prompt = new_prompt
		hover_prompt_changed.emit(current_prompt)
