class_name WorldManager
extends Node3D

## Mundo 3D decorado y claramente zonificado para NASA Space Apps:
## Casa + Barrio (Cap. 0), Carretera y Garita + Plaza Central Campus NASA (Cap. 1),
## Edificio de Entrenamiento (Cap. 2), VAB + Ensamblaje Dinámico SLS (Cap. 3–4),
## Control de Misión MOCR (Cap. 5–12) y Plataforma 39B.

var player: FirstPersonPlayer
var hud: MissionControlHUD
var beacon: WaypointBeacon

var targets: Dictionary = {}
var badge_node: StaticBody3D
var _centrifuge_arm: Node3D
var _vab_rocket_parts: Dictionary = {}
var _pad_flame: MeshInstance3D
var _anim_t: float = 0.0
var _gate_arm: Node3D
var _portal_cooldown: float = 0.0
var _sign_order: Array[String] = ["training", "vab", "mcc", "pad"]
var _sign_nodes: Dictionary = {}
var _portals: Dictionary = {}
var _patrol_npcs: Array[Dictionary] = []
var _sitio_scene: PackedScene = null
var _diorama_marker: Node3D

func setup(p_player: FirstPersonPlayer, p_hud: MissionControlHUD) -> void:
	player = p_player
	hud = p_hud
	player.interact_requested.connect(_on_player_interact)

	_build_environment()
	_build_home_area()
	_build_campus_and_gate()
	_build_training_building()
	_build_vab_building()
	_build_mcc_room()
	_build_launch_pad_39b()
	_build_portals()

	beacon = WaypointBeacon.new()
	add_child(beacon)

	ObjectiveManager.objective_started.connect(_on_objective_started)
	ObjectiveManager.substep_updated.connect(_on_substep_updated)
	GameState.phase_changed.connect(_on_phase_changed)
	_on_objective_started(ObjectiveManager.get_current_objective())

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var we := Environment.new()
	we.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.10, 0.28, 0.58)
	psky.sky_horizon_color = Color(0.72, 0.82, 0.94)
	psky.ground_bottom_color = Color(0.14, 0.20, 0.16)
	psky.sun_angle_max = 35.0
	sky.sky_material = psky
	we.sky = sky
	we.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	we.ambient_light_energy = 0.62
	we.glow_enabled = true
	we.glow_intensity = 0.45
	env.environment = we
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 32.0, 0.0)
	sun.light_energy = 1.45
	sun.light_color = Color(1.0, 0.96, 0.90)
	sun.shadow_enabled = true
	add_child(sun)

	# Terreno costero de Florida
	_make_static_box(Vector3(0.0, -0.5, -50.0), Vector3(540.0, 1.0, 540.0), Color(0.19, 0.29, 0.19), "Ground", 0.92)
	# Agua costera del Atlántico al fondo
	_make_static_box(Vector3(0.0, -0.35, -210.0), Vector3(540.0, 0.6, 120.0), Color(0.06, 0.22, 0.42), "Ocean", 0.18)

	# Carretera residencial -> Garita NASA -> Plaza
	_make_static_box(Vector3(0.0, 0.02, -16.0), Vector3(9.0, 0.05, 88.0), Color(0.15, 0.16, 0.19), "Highway", 0.85)
	for z_dash in range(-20, 22, 5):
		_make_static_box(Vector3(0.0, 0.055, float(z_dash)), Vector3(0.22, 0.02, 2.2), Color(0.95, 0.78, 0.20), "LaneDash")
	# Bordillos de carretera
	_make_static_box(Vector3(-4.65, 0.08, -16.0), Vector3(0.3, 0.14, 88.0), Color(0.68, 0.70, 0.74), "CurbL")
	_make_static_box(Vector3(4.65, 0.08, -16.0), Vector3(0.3, 0.14, 88.0), Color(0.68, 0.70, 0.74), "CurbR")

	# Farolas y árboles a lo largo de la carretera
	for z_tree in [-12, -2, 8, 18]:
		_make_streetlight(Vector3(-5.2, 0.0, float(z_tree)), 0.0)
		_make_tree(Vector3(-10.5, 0.0, float(z_tree) + 2.0), 1.1)
		_make_tree(Vector3(10.5, 0.0, float(z_tree) - 1.5), 0.95)

func _build_home_area() -> void:
	# Casa en Z = +30 (bien separada del complejo NASA)
	var home_pos := Vector3(0.0, 0.0, 30.0)
	# Césped y entrada de vehículos
	_make_static_box(home_pos + Vector3(0.0, 0.02, -2.0), Vector3(26.0, 0.04, 24.0), Color(0.22, 0.39, 0.22), "HomeLawn", 0.95)
	_make_static_box(Vector3(3.2, 0.04, 19.0), Vector3(5.2, 0.05, 11.0), Color(0.55, 0.56, 0.60), "Driveway")
	# Valla residencial alrededor de la propiedad
	_make_static_box(home_pos + Vector3(-13.0, 0.6, -2.0), Vector3(0.25, 1.2, 24.0), Color(0.92, 0.91, 0.88), "FenceL")
	_make_static_box(home_pos + Vector3(13.0, 0.6, -2.0), Vector3(0.25, 1.2, 24.0), Color(0.92, 0.91, 0.88), "FenceR")
	_make_static_box(home_pos + Vector3(0.0, 0.6, 10.0), Vector3(26.0, 1.2, 0.25), Color(0.92, 0.91, 0.88), "FenceB")

	# Suelo de madera cálida y techo inclinado elegante
	_make_static_box(home_pos + Vector3(0.0, 0.08, 0.0), Vector3(13.0, 0.14, 11.0), Color(0.52, 0.36, 0.23), "HomeFloor", 0.65)
	_make_static_box(home_pos + Vector3(0.0, 3.85, 0.0), Vector3(13.8, 0.25, 11.8), Color(0.28, 0.31, 0.36), "HomeRoof")

	# Paredes con marco de puerta frontal hacia -Z
	var wall_col := Color(0.92, 0.89, 0.83)
	_make_static_box(home_pos + Vector3(-6.4, 1.9, 0.0), Vector3(0.24, 3.8, 11.0), wall_col, "WallL")
	_make_static_box(home_pos + Vector3(6.4, 1.9, 0.0), Vector3(0.24, 3.8, 11.0), wall_col, "WallR")
	_make_static_box(home_pos + Vector3(0.0, 1.9, 5.4), Vector3(13.0, 3.8, 0.24), wall_col, "WallBack")
	_make_static_box(home_pos + Vector3(-4.0, 1.9, -5.4), Vector3(5.0, 3.8, 0.24), wall_col, "WallFL")
	_make_static_box(home_pos + Vector3(4.0, 1.9, -5.4), Vector3(5.0, 3.8, 0.24), wall_col, "WallFR")
	_make_static_box(home_pos + Vector3(0.0, 3.25, -5.4), Vector3(3.0, 1.1, 0.24), wall_col, "WallFTop")
	# Dintel y letrero de puerta
	_make_static_box(home_pos + Vector3(0.0, 2.75, -5.55), Vector3(3.2, 0.18, 0.2), Color(0.18, 0.35, 0.62), "DoorHeader")

	# Mobiliario moderno (Tiny Living Pack) manteniendo posición exacta de escritorio para Credencial y Portátil
	_place_asset("res://assets/models/home_furniture/home_rug.glb", home_pos + Vector3(-0.6, 0.16, 0.4), 1.35, Vector3.ZERO)
	_place_asset("res://assets/models/home_furniture/home_bed.glb", home_pos + Vector3(-4.4, 0.15, 3.0), 1.15, Vector3(0, 90, 0))
	_place_asset("res://assets/models/home_furniture/home_sofa.glb", home_pos + Vector3(-4.3, 0.15, -1.6), 1.1, Vector3(0, 90, 0))
	_place_asset("res://assets/models/home_furniture/home_tv.glb", home_pos + Vector3(-0.8, 0.15, 4.9), 1.1, Vector3(0, 180, 0))
	_place_asset("res://assets/models/home_furniture/home_bookcase.glb", home_pos + Vector3(5.4, 0.15, 4.7), 1.1, Vector3(0, 180, 0))
	_place_asset("res://assets/models/home_furniture/home_plant.glb", home_pos + Vector3(-5.6, 0.15, 4.7), 1.25, Vector3.ZERO)
	_make_static_box(home_pos + Vector3(-4.2, 2.2, 5.24), Vector3(1.6, 2.1, 0.05), Color(0.06, 0.22, 0.52), "ArtemisPoster")
	_make_label3d(self, "ARTEMIS II · NASA", home_pos + Vector3(-4.2, 2.5, 5.18), Color(0.95, 0.85, 0.30), 22)

	# Escritorio + silla moderna + lámpara
	_make_static_box(home_pos + Vector3(3.8, 0.50, 2.8), Vector3(2.4, 0.90, 1.1), Color(0.38, 0.24, 0.14), "Desk")
	_place_asset("res://assets/models/home_furniture/home_chair.glb", home_pos + Vector3(3.8, 0.15, 1.5), 1.05, Vector3(0, 180, 0))
	_place_asset("res://assets/models/home_furniture/home_lamp.glb", home_pos + Vector3(4.7, 0.95, 3.0), 1.0, Vector3.ZERO)

	# Luz cálida acogedora
	var home_light := OmniLight3D.new()
	home_light.position = home_pos + Vector3(0.0, 3.2, 0.0)
	home_light.light_color = Color(1.0, 0.88, 0.68)
	home_light.light_energy = 2.6
	home_light.omni_range = 14.0
	add_child(home_light)

	# Credencial NASA interactiva (elevada y con hitbox cómoda sobre el escritorio)
	badge_node = _make_interactable(
		home_pos + Vector3(3.2, 1.08, 2.7),
		Vector3(0.58, 0.22, 0.44),
		Color(0.10, 0.58, 0.98),
		"badge",
		"Recoger Credencial NASA",
		"Credencial NASA",
		1.2
	)

	# Portátil en el escritorio
	_make_interactable(
		home_pos + Vector3(4.0, 1.08, 2.8),
		Vector3(0.52, 0.34, 0.38),
		Color(0.18, 0.25, 0.38),
		"laptop",
		"Leer correo de asignación Artemis II",
		"Portátil NASA",
		0.8
	)

	# Astrovan NASA detallado en la entrada (Z = +18.5)
	var van_pos := Vector3(3.2, 0.0, 18.5)
	var van := _make_interactable(
		van_pos + Vector3(0.0, 0.95, 0.0),
		Vector3(2.3, 1.55, 4.6),
		Color(0.94, 0.95, 0.97),
		"astrovan",
		"Subir al Astrovan rumbo al Campus NASA",
		"Astrovan NASA"
	)
	_make_box_deco(van, Vector3(0.0, 0.15, 0.0), Vector3(2.34, 0.26, 4.62), Color(0.05, 0.28, 0.68)) # Franja NASA
	_make_box_deco(van, Vector3(0.0, 0.35, -2.32), Vector3(1.9, 0.65, 0.06), Color(0.12, 0.22, 0.34)) # Parabrisas
	for wx in [-1.15, 1.15]:
		for wz in [-1.4, 1.4]:
			_make_cylinder(van, Vector3(wx, -0.68, wz), 0.36, 0.28, Color(0.08, 0.08, 0.10), Vector3(0, 0, 90))

	targets["Home/RoomCenter"] = {"pos": home_pos + Vector3(0.0, 1.0, 0.0), "label": "Tu Dormitorio"}
	targets["Home/DeskBadge"] = {"pos": home_pos + Vector3(3.2, 1.2, 2.7), "label": "Credencial NASA"}
	targets["Home/Laptop"] = {"pos": home_pos + Vector3(4.0, 1.2, 2.8), "label": "Portátil"}
	targets["Home/VehicleGate"] = {"pos": van_pos + Vector3(0.0, 1.5, 0.0), "label": "Astrovan (Salida)"}

func _build_campus_and_gate() -> void:
	# Muro perimetral del Complejo Espacial en Z = -22 (separa claramente Casa/Carretera de NASA)
	_make_static_box(Vector3(-42.0, 1.6, -22.0), Vector3(72.0, 3.2, 0.8), Color(0.68, 0.72, 0.78), "PerimeterFenceL")
	_make_static_box(Vector3(42.0, 1.6, -22.0), Vector3(72.0, 3.2, 0.8), Color(0.68, 0.72, 0.78), "PerimeterFenceR")
	# Arco monumental sobre la entrada
	_make_static_box(Vector3(-5.8, 3.2, -22.0), Vector3(0.8, 6.4, 0.8), Color(0.06, 0.24, 0.58), "GatePillarL")
	_make_static_box(Vector3(5.8, 3.2, -22.0), Vector3(0.8, 6.4, 0.8), Color(0.06, 0.24, 0.58), "GatePillarR")
	_make_static_box(Vector3(0.0, 6.0, -22.0), Vector3(12.6, 1.3, 1.0), Color(0.05, 0.22, 0.52), "GateArch", 0.4, 0.4)
	_make_label3d(self, "NASA · KENNEDY SPACE CENTER · ARTEMIS II", Vector3(0.0, 6.0, -21.4), Color(1.0, 0.92, 0.55), 34)

	# Garita de seguridad con barrera móvil
	_make_static_box(Vector3(-4.2, 1.4, -24.5), Vector3(2.8, 2.8, 2.8), Color(0.88, 0.90, 0.93), "SecurityBooth")
	_make_static_box(Vector3(-4.2, 2.9, -24.5), Vector3(3.3, 0.25, 3.3), Color(0.06, 0.24, 0.58), "SecurityRoof")
	_gate_arm = Node3D.new()
	_gate_arm.position = Vector3(-2.6, 1.15, -24.5)
	add_child(_gate_arm)
	_make_box_deco(_gate_arm, Vector3(2.6, 0.0, 0.0), Vector3(5.2, 0.14, 0.14), Color(0.95, 0.35, 0.18), 0.35)
	_make_interactable(
		Vector3(-2.1, 1.05, -24.5),
		Vector3(1.1, 1.9, 1.1),
		Color(0.18, 0.62, 0.98),
		"security_gate",
		"Mostrar Credencial en Garita de Seguridad",
		"Garita de Seguridad",
		0.7
	)
	_place_prop("floodlight", Vector3(-7.0, 0.0, -24.0), 1.4, Vector3(0, 35, 0))
	_place_prop("floodlight", Vector3(7.0, 0.0, -24.0), 1.4, Vector3(0, -35, 0))
	for bx in [-4.5, -1.0, 1.0, 4.5]:
		_place_sitio_prop("hazard_bollard", Vector3(bx, 0.0, -22.8), 1.0, Vector3.ZERO)
	targets["Campus/SecurityGate"] = {"pos": Vector3(-2.1, 1.5, -24.5), "label": "Garita de Seguridad"}

	# Gran Plaza Central del Campus (X: -26..+26, Z: -32..-84)
	_make_static_box(Vector3(0.0, 0.03, -58.0), Vector3(54.0, 0.06, 56.0), Color(0.40, 0.43, 0.48), "CampusPlaza", 0.82)
	# Anillo decorativo azul NASA en el centro de la plaza
	_make_static_box(Vector3(0.0, 0.065, -58.0), Vector3(14.0, 0.03, 14.0), Color(0.06, 0.25, 0.58), "PlazaCenterRing")

	# Rutas de colores en el suelo hacia cada edificio separado
	_make_static_box(Vector3(-19.0, 0.07, -52.0), Vector3(26.0, 0.02, 2.6), Color(0.18, 0.55, 0.95), "PathTraining")
	_make_static_box(Vector3(19.0, 0.07, -52.0), Vector3(26.0, 0.02, 2.6), Color(0.92, 0.45, 0.14), "PathVAB")
	_make_static_box(Vector3(-19.0, 0.07, -86.0), Vector3(2.6, 0.02, 34.0), Color(0.22, 0.78, 0.45), "PathMCC")
	_make_static_box(Vector3(19.0, 0.07, -96.0), Vector3(2.6, 0.02, 46.0), Color(0.92, 0.25, 0.20), "PathPad")

	# Monumento central: Cohete Atlas de exhibición y antena DSN
	_make_static_box(Vector3(0.0, 0.45, -52.0), Vector3(4.2, 0.9, 4.2), Color(0.24, 0.28, 0.34), "MonumentPlinth")
	_place_prop("atlas_medium", Vector3(0.0, 0.9, -52.0), 1.8, Vector3.ZERO)
	_place_prop("exterior_dish", Vector3(16.0, 0.0, -36.0), 1.25, Vector3(0, -140, 0))
	_place_prop("exterior_dish", Vector3(-16.0, 0.0, -36.0), 1.25, Vector3(0, 140, 0))

	# Exhibición Monumental Space Shuttle (Este de la Plaza) y Maqueta 3D KSC (Oeste)
	_place_shuttle_exhibit(Vector3(24.0, 0.0, -33.5), 0.011, -35.0)
	_place_sitio_diorama(Vector3(-22.5, 0.0, -34.0), 0.019)

	# Palmeras reales de Florida (sitio_lanzamiento.glb) y vehículos de apoyo GSE en el campus
	for pz in [-32.0, -44.0, -60.0, -76.0]:
		_place_sitio_prop("palm_tree", Vector3(-25.8, 0.0, pz), 1.05, Vector3(0, pz * 17.0, 0))
		_place_sitio_prop("palm_tree", Vector3(25.8, 0.0, pz), 1.05, Vector3(0, -pz * 13.0, 0))
	_place_sitio_prop("gse_truck", Vector3(21.5, 0.06, -57.5), 1.25, Vector3(0, -25, 0))
	_place_sitio_prop("gse_truck", Vector3(-11.5, 0.06, -80.5), 1.25, Vector3(0, 90, 0))

	# Ingenieros / Astronautas NASA animados con walk_briefcase.fbx, breathing_idle.fbx y button_pushing.fbx
	_spawn_patrol_astronaut(Vector3(-9.5, 0.08, -41.5), Vector3(9.5, 0.08, -41.5), 1.65, "Ing. Operaciones NASA")
	_spawn_patrol_astronaut(Vector3(-10.0, 0.08, -76.0), Vector3(10.0, 0.08, -76.0), 1.45, "Especialista de Vuelo")
	_spawn_station_astronaut(Vector3(-5.2, 0.08, -23.0), Vector3(0, 15, 0), "res://assets/characters/breathing_idle.fbx", "Oficial Seguridad KSC")
	_spawn_station_astronaut(Vector3(-1.4, 0.40, -65.2), Vector3(0, 145, 0), "res://assets/characters/button_pushing.fbx", "Coordinador Briefing")

	# 4 Carteles de Orientación estilizados en las 4 esquinas de la plaza
	var signs := [
		{
			"id": "training",
			"iid": "sign:training",
			"pos": Vector3(-16.0, 1.3, -46.0),
			"txt": "← ENTRENAMIENTO DE ASTRONAUTAS",
			"short": "Entrenamiento",
			"title": "Centro de Entrenamiento de Astronautas",
			"col": Color(0.15, 0.55, 0.95),
			"desc": "[b]Edificio Oeste · Capítulo 2[/b]\n\nAquí completarás tu preparación física y teórica:\n• [color=#60b4ff]Centrífuga humana[/color] (3g → 5g)\n• [color=#60b4ff]Cámara de vacío y traje OCSS[/color]\n• [color=#60b4ff]Laboratorio de las 3 Leyes de Newton[/color]\n\n[i]Al terminar la orientación, entra por el portal azul del Oeste.[/i]"
		},
		{
			"id": "vab",
			"iid": "sign:vab",
			"pos": Vector3(16.0, 1.3, -46.0),
			"txt": "VAB · ENSAMBLAJE SLS →",
			"short": "VAB (SLS)",
			"title": "Vehicle Assembly Building (VAB)",
			"col": Color(0.92, 0.45, 0.15),
			"desc": "[b]Edificio Este · Capítulos 3 y 4[/b]\n\nEl hangar de ensamblaje vertical del cohete Artemis:\n• Apilarás el [color=#ffa940]SLS Block 1[/color] con la grúa puente (SRB, Etapa Central, ICPS, Orion, LAS)\n• Calcularás el [color=#ffa940]TWR al despegue[/color] (> 1.2)\n• Verificarás buses de energía, soporte vital ECLSS, escudo térmico y antenas."
		},
		{
			"id": "mcc",
			"iid": "sign:mcc",
			"pos": Vector3(-16.0, 1.3, -72.0),
			"txt": "← CONTROL DE MISIÓN (MOCR)",
			"short": "Control de Misión",
			"title": "Mission Control Center (MOCR)",
			"col": Color(0.20, 0.78, 0.45),
			"desc": "[b]Edificio Noroeste · Capítulos 5 al 12[/b]\n\nCentro de mando integral para la misión lunar:\n• Software de vuelo (GLS, depuración Mars Climate Orbiter, redundancia)\n• Sala [color=#5ce08c]FIDO[/color]: ventana, ecuación de Tsiolkovsky y retorno libre\n• Lanzamiento, órbita HEO, TLI, sobrevuelo lunar y reentrada."
		},
		{
			"id": "pad",
			"iid": "sign:pad",
			"pos": Vector3(16.0, 1.3, -72.0),
			"txt": "PLATAFORMA DE LANZAMIENTO 39B →",
			"short": "Plataforma 39B",
			"title": "Complejo de Lanzamiento 39B",
			"col": Color(0.92, 0.26, 0.22),
			"desc": "[b]Sector Noreste · Despegue SLS[/b]\n\nDesde esta plataforma histórica de Apolo y Artemis despegará el SLS con [color=#ff7875]39.1 MN de empuje[/color].\n\n[i]Tras visitar los 4 carteles, ve al Terminal Briefing en el centro de la plaza.[/i]"
		}
	]
	for s in signs:
		_make_static_box(s["pos"] + Vector3(0.0, -0.7, 0.0), Vector3(0.35, 1.2, 0.35), Color(0.25, 0.28, 0.32), "SignPost")
		var sb := _make_interactable(s["pos"], Vector3(2.4, 1.5, 0.45), s["col"], s["iid"], "Leer " + s["txt"], s["txt"], 0.45)
		var lbl: Label3D = null
		for c in sb.get_children():
			if c is Label3D:
				lbl = c as Label3D
				break
		_sign_nodes[s["id"]] = {
			"body": sb,
			"label": lbl,
			"base_txt": s["txt"],
			"short": s["short"],
			"title": s["title"],
			"desc": s["desc"],
			"pos": s["pos"] + Vector3(0.0, 0.4, 0.0)
		}
	targets["Campus/Signs"] = {"pos": Vector3(-16.0, 1.7, -46.0), "label": "Cartel 1/4: Entrenamiento"}

	# Pabellón de Briefing en el centro sur de la plaza (0, 0, -64)
	_make_static_box(Vector3(0.0, 0.2, -64.0), Vector3(7.0, 0.4, 6.0), Color(0.20, 0.24, 0.30), "BriefingDeck")
	_make_static_box(Vector3(0.0, 3.4, -64.0), Vector3(7.4, 0.25, 6.4), Color(0.06, 0.24, 0.58), "BriefingCanopy")
	for px in [-3.1, 3.1]:
		for pz in [-66.5, -61.5]:
			_make_static_box(Vector3(px, 1.8, pz), Vector3(0.25, 3.2, 0.25), Color(0.75, 0.78, 0.82), "CanopyPillar")
	_place_prop("globe_stand", Vector3(-2.0, 0.4, -64.0), 1.3, Vector3.ZERO)
	_make_interactable(
		Vector3(0.8, 1.25, -64.0),
		Vector3(1.8, 1.7, 1.0),
		Color(0.18, 0.80, 0.98),
		"briefing_terminal",
		"Acceder a Sala de Briefing Artemis II",
		"Terminal Briefing Artemis II",
		0.8
	)
	targets["Campus/BriefingTerminal"] = {"pos": Vector3(0.8, 1.5, -64.0), "label": "Terminal Briefing"}

func _build_training_building() -> void:
	# Edificio independiente al Oeste (X = -52, Z = -52)
	var base := Vector3(-52.0, 0.0, -52.0)
	_build_facility_shell(
		base, Vector3(24.0, 6.5, 24.0), "east",
		Color(0.86, 0.89, 0.94), Color(0.16, 0.55, 0.95),
		"ASTRONAUT TRAINING FACILITY · CAP. 2"
	)

	# Bahía 1: Centrífuga humana con brazo giratorio
	_make_cylinder(self, base + Vector3(-5.0, 0.15, -5.0), 3.6, 0.2, Color(0.18, 0.22, 0.28))
	_centrifuge_arm = Node3D.new()
	_centrifuge_arm.position = base + Vector3(-5.0, 1.1, -5.0)
	add_child(_centrifuge_arm)
	_make_box_deco(_centrifuge_arm, Vector3(1.5, 0.0, 0.0), Vector3(3.2, 0.25, 0.35), Color(0.92, 0.55, 0.14))
	_make_box_deco(_centrifuge_arm, Vector3(3.0, 0.1, 0.0), Vector3(1.1, 1.1, 1.1), Color(0.88, 0.90, 0.94))
	_make_interactable(base + Vector3(-5.0, 1.2, -5.0), Vector3(2.6, 1.8, 2.6), Color(0.90, 0.52, 0.15), "centrifuge", "Iniciar Prueba en Centrífuga (3g→5g)", "Centrífuga 3g→5g")

	# Bahía 2: Cámara de Vacío + Galería de Trajes (Gemini + Mark III + Robonaut 2)
	_make_cylinder(self, base + Vector3(0.5, 1.6, -5.5), 1.4, 3.0, Color(0.24, 0.28, 0.35))
	_make_cylinder(self, base + Vector3(-1.8, 0.12, -5.5), 0.75, 0.24, Color(0.14, 0.20, 0.30))
	_place_centered_suit("res://assets/models/mark_iii_spacesuit.glb", base + Vector3(-1.8, 0.24, -5.5), 1.95, Vector3(0, 25, 0))
	_make_cylinder(self, base + Vector3(6.2, 0.12, -5.5), 0.75, 0.24, Color(0.14, 0.20, 0.30))
	_place_centered_suit("res://assets/models/gemini_spacesuit.glb", base + Vector3(6.2, 0.24, -5.5), 1.95, Vector3(0, -25, 0))
	_place_robonaut_display(base + Vector3(3.2, 0.1, -5.5), Vector3(0, -15, 0))
	_make_interactable(base + Vector3(6.2, 1.1, -3.5), Vector3(1.4, 1.3, 0.9), Color(0.32, 0.76, 0.98), "suit_gallery", "Inspeccionar Galería de Trajes (Gemini / Mark III)", "Traje Gemini NASA", 0.5)
	_make_interactable(base + Vector3(0.5, 1.3, -3.5), Vector3(2.2, 2.0, 1.4), Color(0.95, 0.42, 0.15), "vacuum_ocss", "Probar Traje OCSS en Cámara de Vacío", "Cámara Vacío OCSS")

	# Bahía 3: Laboratorio de Newton (Mesa holográfica + cajas de masas)
	_place_prop("holo_table", base + Vector3(5.8, 0.1, 4.5), 1.25, Vector3.ZERO)
	_place_prop("hangar_shelf", base + Vector3(-7.0, 0.1, 6.0), 1.35, Vector3(0, 90, 0))
	_make_static_box(base + Vector3(4.2, 0.45, 7.0), Vector3(0.7, 0.7, 0.7), Color(0.25, 0.78, 0.45), "Mass10kg")
	_make_static_box(base + Vector3(5.6, 0.65, 7.0), Vector3(1.1, 1.1, 1.1), Color(0.90, 0.68, 0.22), "Mass50kg")
	_make_interactable(base + Vector3(5.8, 1.1, 4.5), Vector3(2.2, 1.5, 2.2), Color(0.25, 0.75, 0.48), "newton_lab", "Laboratorio de las 3 Leyes de Newton", "Lab. Newton")

	targets["Training/Centrifuge"] = {"pos": base + Vector3(-5.0, 1.5, -5.0), "label": "Centrífuga"}
	targets["Training/VacuumChamber"] = {"pos": base + Vector3(0.5, 1.5, -3.5), "label": "Cámara Vacío OCSS"}
	targets["Training/NewtonLab"] = {"pos": base + Vector3(5.8, 1.5, 4.5), "label": "Lab. Newton"}

func _build_vab_building() -> void:
	# VAB imponente al Este (X = +54, Z = -52)
	var base := Vector3(54.0, 0.0, -52.0)
	_build_facility_shell(
		base, Vector3(28.0, 18.0, 28.0), "west",
		Color(0.78, 0.80, 0.84), Color(0.92, 0.45, 0.14),
		"VAB · VEHICLE ASSEMBLY BUILDING"
	)

	# Plataforma Lanzador Móvil en el centro del VAB
	_make_static_box(base + Vector3(0.0, 0.55, 0.0), Vector3(8.5, 1.1, 8.5), Color(0.32, 0.34, 0.38), "MobileLauncherBase")
	_make_static_box(base + Vector3(-3.2, 7.0, 0.0), Vector3(1.4, 13.0, 1.4), Color(0.55, 0.58, 0.62), "VABServiceTower")
	_place_prop("bridge_crane", base + Vector3(0.0, 14.5, 0.0), 3.6, Vector3.ZERO)
	_place_prop("pallet_jack", base + Vector3(-7.0, 0.1, -6.5), 1.3, Vector3(0, 40, 0))
	_place_prop("part_dispenser", base + Vector3(8.5, 0.1, -6.5), 1.4, Vector3(0, -90, 0))
	_place_prop("hangar_shelf", base + Vector3(9.5, 0.1, 5.5), 1.5, Vector3(0, -90, 0))

	# Piezas 3D dinámicas del SLS dentro del VAB (visibles según se apilan en Cap. 3)
	var stack_root := Node3D.new()
	stack_root.position = base + Vector3(0.0, 1.1, 0.0)
	add_child(stack_root)
	_vab_rocket_parts["srb_left"] = _make_cylinder(stack_root, Vector3(-1.35, 3.8, 0.0), 0.42, 7.6, Color(0.94, 0.94, 0.96))
	_vab_rocket_parts["srb_right"] = _make_cylinder(stack_root, Vector3(1.35, 3.8, 0.0), 0.42, 7.6, Color(0.94, 0.94, 0.96))
	_vab_rocket_parts["core_stage"] = _make_cylinder(stack_root, Vector3(0.0, 4.6, 0.0), 0.78, 9.2, Color(0.84, 0.42, 0.14))
	_vab_rocket_parts["lvsa_icps"] = _make_cylinder(stack_root, Vector3(0.0, 10.1, 0.0), 0.55, 1.9, Color(0.84, 0.86, 0.90))
	_vab_rocket_parts["msa_esm"] = _make_cylinder(stack_root, Vector3(0.0, 11.4, 0.0), 0.48, 0.9, Color(0.24, 0.28, 0.36))
	var orion_top := _place_asset("res://assets/models/orion_craft.glb", Vector3(0.0, 12.25, 0.0), 0.068, Vector3(-90.0, 0.0, 0.0))
	if orion_top != null:
		orion_top.reparent(stack_root, false)
		orion_top.position = Vector3(0.0, 12.25, 0.0)
		_vab_rocket_parts["orion_cm"] = orion_top
	else:
		_vab_rocket_parts["orion_cm"] = _make_cylinder(stack_root, Vector3(0.0, 12.2, 0.0), 0.46, 0.8, Color(0.92, 0.94, 0.98))
	_vab_rocket_parts["las"] = _make_cylinder(stack_root, Vector3(0.0, 13.4, 0.0), 0.16, 1.8, Color(0.96, 0.96, 0.98))
	_sync_vab_rocket_visuals()

	_make_interactable(base + Vector3(-2.6, 1.4, 3.2), Vector3(2.4, 1.8, 1.8), Color(0.92, 0.48, 0.15), "vab_crane", "Operar Grúa Puente (Ensamblar SLS)", "Consola Grúa VAB")

	# Exhibición de Cápsula Orion real (STL -> GLB) y Técnico animado
	var orion_ex := _place_asset("res://assets/models/orion_capsule.glb", base + Vector3(8.5, 1.45, 0.5), 0.18, Vector3(-90.0, -35.0, 0.0))
	if orion_ex != null:
		_make_interactable(base + Vector3(8.5, 1.1, 2.4), Vector3(1.5, 1.2, 0.8), Color(0.33, 0.77, 0.98), "orion_exhibit", "Inspeccionar Cápsula Orion MPCV", "Cápsula Orion MPCV", 0.55)
	_spawn_station_astronaut(base + Vector3(-4.2, 0.12, 3.2), Vector3(0, 90, 0), "res://assets/characters/button_pushing.fbx", "Técnico Grúa VAB")

	# Banco de Hardware Orion (Cap. 4)
	_place_prop("crt_station", base + Vector3(-7.0, 0.1, 7.0), 1.25, Vector3(0, 180, 0))
	_place_prop("ant_dish", base + Vector3(-5.0, 0.9, 7.0), 1.3, Vector3(0, 180, 0))
	_place_prop("rcs_tank", base + Vector3(-8.8, 0.1, 7.0), 1.8, Vector3.ZERO)
	_place_prop("solar_std", base + Vector3(-3.6, 0.1, 7.0), 1.4, Vector3.ZERO)
	_make_interactable(base + Vector3(-6.2, 1.0, 7.0), Vector3(3.0, 1.6, 1.5), Color(0.20, 0.72, 0.94), "hw_bench", "Banco de Hardware de Orion (Cap. 4)", "Banco Hardware Orion")

	targets["VAB/MobileLauncher"] = {"pos": base + Vector3(-2.6, 1.6, 3.2), "label": "Grúa VAB / SLS"}
	targets["VAB/HardwareBench"] = {"pos": base + Vector3(-6.2, 1.5, 7.0), "label": "Banco Hardware Orion"}

func _build_mcc_room() -> void:
	# Control de Misión (MOCR) separado al Noroeste (X = -46, Z = -104)
	var base := Vector3(-46.0, 0.0, -104.0)
	_build_facility_shell(
		base, Vector3(26.0, 7.5, 22.0), "south",
		Color(0.20, 0.24, 0.30), Color(0.22, 0.80, 0.48),
		"MISSION CONTROL CENTER · MOCR HOUSTON"
	)

	# Pantalla gigante frontal con diagrama Tierra -> Luna
	_make_static_box(base + Vector3(0.0, 4.0, -9.4), Vector3(17.0, 5.4, 0.4), Color(0.04, 0.10, 0.20), "MCCBigScreen", 0.4, 0.35)
	_make_label3d(self, "ARTEMIS II  ·  TRAYECTORIA DE RETORNO LIBRE  ·  TIERRA ━━━▶ LUNA", base + Vector3(0.0, 5.5, -9.1), Color(0.35, 0.85, 1.0), 28)
	_make_cylinder(self, base + Vector3(-4.5, 3.6, -9.15), 1.05, 0.15, Color(0.15, 0.50, 0.95), Vector3(90, 0, 0), 0.5) # Tierra
	_make_cylinder(self, base + Vector3(4.5, 3.6, -9.15), 0.42, 0.15, Color(0.78, 0.80, 0.82), Vector3(90, 0, 0), 0.3) # Luna

	# Gradas escalonadas y consolas CRT
	_make_static_box(base + Vector3(0.0, 0.20, 2.0), Vector3(20.0, 0.4, 6.0), Color(0.14, 0.17, 0.22), "Tier2")
	_place_prop("crt_station", base + Vector3(-6.0, 0.1, -3.5), 1.35, Vector3(0, 180, 0))
	_place_prop("crt_station", base + Vector3(0.0, 0.1, -3.5), 1.35, Vector3(0, 180, 0))
	_place_prop("crt_station", base + Vector3(6.0, 0.1, -3.5), 1.35, Vector3(0, 180, 0))
	_place_prop("globe_stand", base + Vector3(-8.8, 0.1, -5.5), 1.35, Vector3.ZERO)
	_place_robonaut_display(base + Vector3(9.0, 0.1, -5.0), Vector3(0, -145, 0))
	_place_prop("matrix_printer", base + Vector3(0.0, 1.25, 3.2), 1.5, Vector3.ZERO)

	# Controladores de Misión animados tecleando en las consolas (Typing.fbx) y Maqueta Cráter Copérnico (Moon STL)
	_spawn_station_astronaut(base + Vector3(-6.0, 0.12, -2.1), Vector3(0, 0, 0), "res://assets/characters/typing.fbx", "Flight Software")
	_spawn_station_astronaut(base + Vector3(6.0, 0.12, -2.1), Vector3(0, 0, 0), "res://assets/characters/typing.fbx", "FIDO / Director")
	_make_static_box(base + Vector3(-9.2, 0.48, 2.0), Vector3(4.8, 0.85, 3.8), Color(0.10, 0.14, 0.22), "MoonTable")
	_place_asset("res://assets/models/moon_copernicus.glb", base + Vector3(-9.2, 0.88, 2.0), 0.022, Vector3.ZERO)
	_make_interactable(base + Vector3(-9.2, 1.15, 4.1), Vector3(1.4, 1.1, 0.8), Color(0.75, 0.82, 0.95), "moon_exhibit", "Inspeccionar Relieve Lunar (Cráter Copérnico)", "Relieve Lunar 3D", 0.45)

	_make_interactable(base + Vector3(-6.0, 1.0, -3.5), Vector3(2.4, 1.5, 1.4), Color(0.22, 0.80, 0.45), "mcc_software", "Consola de Software de Vuelo (Cap. 5)", "Consola Software")
	_make_interactable(base + Vector3(0.0, 1.0, -3.5), Vector3(2.4, 1.5, 1.4), Color(0.28, 0.62, 0.96), "mcc_fido", "Consola FIDO — Trayectoria (Cap. 6)", "Consola FIDO")
	_make_interactable(base + Vector3(6.0, 1.0, -3.5), Vector3(2.4, 1.5, 1.4), Color(0.95, 0.64, 0.18), "mcc_flight", "Consola FLIGHT — Operaciones (Cap. 7–11)", "Consola FLIGHT")
	_make_interactable(base + Vector3(0.0, 1.0, 3.2), Vector3(2.2, 1.4, 1.4), Color(0.90, 0.86, 0.72), "mcc_debrief", "Terminal de Debrief y Recibo (Cap. 12)", "Terminal Debrief")

	targets["MCC/SoftwareConsole"] = {"pos": base + Vector3(-6.0, 1.5, -3.5), "label": "Consola Software"}
	targets["MCC/FidoConsole"] = {"pos": base + Vector3(0.0, 1.5, -3.5), "label": "Consola FIDO"}
	targets["MCC/FlightConsole"] = {"pos": base + Vector3(6.0, 1.5, -3.5), "label": "Consola FLIGHT"}
	targets["MCC/Debrief"] = {"pos": base + Vector3(0.0, 1.5, 3.2), "label": "Debrief Artemis"}

func _build_launch_pad_39b() -> void:
	var pad_pos := Vector3(54.0, 0.0, -126.0)
	_make_static_box(pad_pos + Vector3(0.0, 0.6, 0.0), Vector3(26.0, 1.2, 26.0), Color(0.45, 0.46, 0.50), "Pad39B")
	_make_static_box(pad_pos + Vector3(0.0, 1.22, 0.0), Vector3(12.0, 0.1, 12.0), Color(0.22, 0.22, 0.25), "FlameTrench")
	_place_prop("launch_tower", pad_pos + Vector3(-6.2, 1.2, 0.0), 3.6, Vector3.ZERO)
	_place_prop("floodlight", pad_pos + Vector3(-11.0, 1.2, 10.0), 2.0, Vector3(0, 45, 0))
	_place_prop("floodlight", pad_pos + Vector3(11.0, 1.2, 10.0), 2.0, Vector3(0, -45, 0))
	_place_prop("exterior_dish", pad_pos + Vector3(14.0, 0.0, 15.0), 1.5, Vector3(0, 180, 0))
	_make_label3d(self, "LAUNCH COMPLEX 39B · SLS BLOCK 1", pad_pos + Vector3(0.0, 3.0, 12.0), Color(1.0, 0.50, 0.35), 36)
	_place_sitio_prop("umbilical_mast", pad_pos + Vector3(5.2, 1.2, -3.5), 1.6, Vector3(0, -90, 0))
	_place_sitio_prop("gse_truck", pad_pos + Vector3(-16.0, 0.0, 16.0), 1.35, Vector3(0, 35, 0))
	_place_sitio_prop("palm_tree", pad_pos + Vector3(-18.0, 0.0, 22.0), 1.1, Vector3.ZERO)
	_place_sitio_prop("palm_tree", pad_pos + Vector3(18.0, 0.0, 22.0), 1.1, Vector3(0, 60, 0))

	var rocket := Node3D.new()
	rocket.position = pad_pos + Vector3(0.0, 1.25, 0.0)
	add_child(rocket)
	_make_cylinder(rocket, Vector3(0.0, 12.0, 0.0), 1.5, 24.0, Color(0.84, 0.43, 0.16))
	_make_cylinder(rocket, Vector3(-2.3, 9.5, 0.0), 0.78, 19.0, Color(0.94, 0.94, 0.96))
	_make_cylinder(rocket, Vector3(2.3, 9.5, 0.0), 0.78, 19.0, Color(0.94, 0.94, 0.96))
	var pad_orion := _place_asset("res://assets/models/orion_craft.glb", Vector3(0.0, 26.2, 0.0), 0.14, Vector3(-90.0, 0.0, 0.0))
	if pad_orion != null:
		pad_orion.reparent(rocket, false)
		pad_orion.position = Vector3(0.0, 26.2, 0.0)
	else:
		_make_cylinder(rocket, Vector3(0.0, 26.2, 0.0), 0.96, 5.2, Color(0.92, 0.94, 0.98))
	_pad_flame = _make_cylinder(rocket, Vector3(0.0, -2.0, 0.0), 1.8, 5.5, Color(1.0, 0.58, 0.15), Vector3.ZERO, 4.0)
	_pad_flame.visible = false

func _build_facility_shell(center: Vector3, sz: Vector3, door_side: String, wall_col: Color, accent_col: Color, header_txt: String) -> void:
	var hw := sz.x * 0.5
	var hh := sz.y * 0.5
	var hd := sz.z * 0.5
	var t := 0.45

	_make_static_box(center + Vector3(0.0, 0.06, 0.0), Vector3(sz.x, 0.12, sz.z), Color(0.24, 0.27, 0.32), "Floor_" + header_txt)
	_make_static_box(center + Vector3(0.0, sz.y, 0.0), Vector3(sz.x + 0.8, 0.4, sz.z + 0.8), wall_col.darkened(0.25), "Roof_" + header_txt)
	# Franja decorativa superior alrededor del edificio
	_make_static_box(center + Vector3(0.0, sz.y - 0.55, 0.0), Vector3(sz.x + 0.5, 0.45, sz.z + 0.5), accent_col, "Stripe_" + header_txt, 0.4, 0.6)

	var ilight := OmniLight3D.new()
	ilight.position = center + Vector3(0.0, sz.y - 1.2, 0.0)
	ilight.light_energy = 3.2
	ilight.omni_range = maxf(sz.x, sz.z) * 0.9
	add_child(ilight)

	# Paredes con apertura amplia (6m) en el lado indicado
	if door_side != "north":
		_make_static_box(center + Vector3(0.0, hh, -hd), Vector3(sz.x, sz.y, t), wall_col, "WallN")
	else:
		_make_door_wall_z(center + Vector3(0.0, 0.0, -hd), sz.x, sz.y, t, wall_col, accent_col, header_txt, Vector3(0, 180, 0))

	if door_side != "south":
		_make_static_box(center + Vector3(0.0, hh, hd), Vector3(sz.x, sz.y, t), wall_col, "WallS")
	else:
		_make_door_wall_z(center + Vector3(0.0, 0.0, hd), sz.x, sz.y, t, wall_col, accent_col, header_txt, Vector3.ZERO)

	if door_side != "west":
		_make_static_box(center + Vector3(-hw, hh, 0.0), Vector3(t, sz.y, sz.z), wall_col, "WallW")
	else:
		_make_door_wall_x(center + Vector3(-hw, 0.0, 0.0), sz.z, sz.y, t, wall_col, accent_col, header_txt, Vector3(0, -90, 0))

	if door_side != "east":
		_make_static_box(center + Vector3(hw, hh, 0.0), Vector3(t, sz.y, sz.z), wall_col, "WallE")
	else:
		_make_door_wall_x(center + Vector3(hw, 0.0, 0.0), sz.z, sz.y, t, wall_col, accent_col, header_txt, Vector3(0, 90, 0))

func _make_door_wall_z(pos: Vector3, width: float, height: float, thick: float, col: Color, acc: Color, title: String, _rot: Vector3) -> void:
	var door_w := 6.0
	var side_w := (width - door_w) * 0.5
	_make_static_box(pos + Vector3(-(door_w * 0.5 + side_w * 0.5), height * 0.5, 0.0), Vector3(side_w, height, thick), col, "WallSideL")
	_make_static_box(pos + Vector3((door_w * 0.5 + side_w * 0.5), height * 0.5, 0.0), Vector3(side_w, height, thick), col, "WallSideR")
	_make_static_box(pos + Vector3(0.0, height - 1.2, 0.0), Vector3(door_w, 2.4, thick), col, "WallTop")
	_make_static_box(pos + Vector3(0.0, 4.2, 0.0), Vector3(door_w + 0.6, 0.45, thick + 0.3), acc, "DoorArch", 0.3, 0.8)
	_make_label3d(self, title, pos + Vector3(0.0, 4.9, 0.4), Color.WHITE, 32)

func _make_door_wall_x(pos: Vector3, depth: float, height: float, thick: float, col: Color, acc: Color, title: String, _rot: Vector3) -> void:
	var door_w := 6.0
	var side_w := (depth - door_w) * 0.5
	_make_static_box(pos + Vector3(0.0, height * 0.5, -(door_w * 0.5 + side_w * 0.5)), Vector3(thick, height, side_w), col, "WallSideL")
	_make_static_box(pos + Vector3(0.0, height * 0.5, (door_w * 0.5 + side_w * 0.5)), Vector3(thick, height, side_w), col, "WallSideR")
	_make_static_box(pos + Vector3(0.0, height - 1.2, 0.0), Vector3(thick, 2.4, door_w), col, "WallTop")
	_make_static_box(pos + Vector3(0.0, 4.2, 0.0), Vector3(thick + 0.3, 0.45, door_w + 0.6), acc, "DoorArch", 0.3, 0.8)
	var sign_offset := Vector3(0.4, 4.9, 0.0) if pos.x < 0 else Vector3(-0.4, 4.9, 0.0)
	_make_label3d(self, title, pos + sign_offset, Color.WHITE, 32)

func _place_prop(prop_name: String, pos: Vector3, scale_mult: float, rot_deg: Vector3) -> Node3D:
	var n := PropModelLoader.instantiate_prop(prop_name)
	if n == null:
		return null
	n.position = pos
	n.scale = Vector3.ONE * scale_mult
	n.rotation_degrees = rot_deg
	add_child(n)
	return n

func _place_asset(res_path: String, pos: Vector3, scale_mult: float, rot_deg: Vector3) -> Node3D:
	if not ResourceLoader.exists(res_path):
		return null
	var ps := load(res_path) as PackedScene
	if ps == null:
		return null
	var n := ps.instantiate() as Node3D
	n.position = pos
	n.scale = Vector3.ONE * scale_mult
	n.rotation_degrees = rot_deg
	add_child(n)
	return n

func _place_robonaut_display(pos: Vector3, rot_deg: Vector3) -> void:
	_make_cylinder(self, pos + Vector3(0.0, 0.12, 0.0), 0.75, 0.24, Color(0.14, 0.20, 0.30))
	var r2 := _place_asset("res://assets/characters/robonaut2.glb", pos + Vector3(0.0, 0.24, 0.0), 0.72, rot_deg)
	if r2 != null:
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color(0.90, 0.66, 0.16)
		gold.metallic = 0.92
		gold.roughness = 0.15
		_tint_visor_recursive(r2, gold)
		_make_label3d(self, "ROBONAUT 2 · ASISTENTE NASA", pos + Vector3(0.0, 2.35, 0.0), Color(0.45, 0.85, 1.0), 20)

func _place_centered_suit(res_path: String, pos: Vector3, target_height: float, rot_deg: Vector3) -> Node3D:
	if not ResourceLoader.exists(res_path):
		return null
	var ps := load(res_path) as PackedScene
	if ps == null:
		return null
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = rot_deg
	add_child(root)

	var model := ps.instantiate() as Node3D
	var b := _calc_model_aabb(model, Transform3D.IDENTITY)
	var s: float = target_height / maxf(0.1, b.size.y)
	model.scale = Vector3.ONE * s
	var cx: float = (b.position.x + b.size.x * 0.5) * s
	var cz: float = (b.position.z + b.size.z * 0.5) * s
	var min_y: float = b.position.y * s
	model.position = Vector3(-cx, -min_y, -cz)
	root.add_child(model)
	return root

func _place_shuttle_exhibit(pos: Vector3, scale_mult: float, rot_y: float) -> void:
	_make_static_box(pos + Vector3(0.0, 0.18, 0.0), Vector3(13.0, 0.36, 9.0), Color(0.22, 0.25, 0.31), "ShuttlePlinth", 0.75)
	_make_static_box(pos + Vector3(-2.6, 1.4, 0.0), Vector3(0.8, 2.4, 1.2), Color(0.10, 0.30, 0.65), "ShuttlePylonA")
	_make_static_box(pos + Vector3(2.4, 2.0, 0.0), Vector3(0.8, 3.6, 1.2), Color(0.10, 0.30, 0.65), "ShuttlePylonB")
	var ps := load("res://assets/models/space_shuttle.glb") as PackedScene if ResourceLoader.exists("res://assets/models/space_shuttle.glb") else null
	if ps != null:
		var holder := Node3D.new()
		holder.position = pos + Vector3(0.0, 3.85, 0.0)
		holder.rotation_degrees = Vector3(0.0, rot_y, 16.0)
		add_child(holder)
		var shut := ps.instantiate() as Node3D
		# Space Shuttle (D).glb tiene longitud en X, envergadura en Y, cola en Z -> rotar -90° en X para enderezarlo
		shut.scale = Vector3.ONE * scale_mult
		shut.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		holder.add_child(shut)
	_make_interactable(pos + Vector3(-5.2, 0.95, 3.8), Vector3(1.6, 1.3, 0.8), Color(0.95, 0.55, 0.16), "shuttle_exhibit", "Inspeccionar Transbordador Espacial (RS-25)", "Space Shuttle · Exhibición NASA", 0.55)

func _place_sitio_diorama(pos: Vector3, scale_mult: float) -> void:
	_make_static_box(pos + Vector3(0.0, 0.38, 0.0), Vector3(6.2, 0.76, 6.2), Color(0.12, 0.17, 0.25), "DioramaTable", 0.5)
	_make_static_box(pos + Vector3(0.0, 0.78, 0.0), Vector3(5.6, 0.05, 5.6), Color(0.05, 0.25, 0.55), "DioramaRim", 0.3, 0.7)
	var sc := _get_sitio_scene()
	if sc != null:
		var dio := sc.instantiate() as Node3D
		dio.position = pos + Vector3(0.0, 0.82, 0.0)
		dio.scale = Vector3.ONE * scale_mult
		add_child(dio)
	_diorama_marker = _place_sitio_prop("athena_rocket", pos + Vector3(0.0, 1.85, 0.0), 0.14, Vector3(0, 0, 18))
	_make_interactable(pos + Vector3(0.0, 0.95, 3.3), Vector3(1.6, 1.3, 0.8), Color(0.20, 0.78, 0.98), "ksc_diorama", "Inspeccionar Maqueta 3D Complejo KSC", "Maqueta 3D · Complejo KSC", 0.5)

func _get_sitio_scene() -> PackedScene:
	if _sitio_scene == null and ResourceLoader.exists("res://assets/models/sitio_lanzamiento.glb"):
		_sitio_scene = load("res://assets/models/sitio_lanzamiento.glb") as PackedScene
	return _sitio_scene

func _place_sitio_prop(node_name: String, pos: Vector3, scale_mult: float, rot_deg: Vector3) -> Node3D:
	var sc := _get_sitio_scene()
	if sc == null:
		return null
	var tmp := sc.instantiate()
	var target := tmp.find_child(node_name, true, false) as MeshInstance3D
	var res_node: Node3D = null
	if target != null and target.mesh != null:
		var holder := Node3D.new()
		holder.position = pos
		holder.rotation_degrees = rot_deg
		holder.scale = Vector3.ONE * scale_mult
		var mi := MeshInstance3D.new()
		mi.mesh = target.mesh
		holder.add_child(mi)
		add_child(holder)
		res_node = holder
	tmp.free()
	return res_node

func _create_animated_npc(fbx_path: String, pos: Vector3, rot_deg: Vector3, label_txt: String, speed_scale: float = 1.0) -> Node3D:
	if not ResourceLoader.exists(fbx_path):
		return null
	var ps := load(fbx_path) as PackedScene
	if ps == null:
		return null
	var npc_root := Node3D.new()
	npc_root.position = pos
	npc_root.rotation_degrees = rot_deg
	add_child(npc_root)

	var model := ps.instantiate() as Node3D
	model.scale = Vector3.ONE * 74.0
	model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	npc_root.add_child(model)
	_tint_npc_suit(model)

	var ap := _find_animation_player_rec(model)
	if ap != null:
		var names := ap.get_animation_list()
		if not names.is_empty():
			var anim := ap.get_animation(names[0]).duplicate() as Animation
			for t in range(anim.get_track_count()):
				if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and "Hips" in String(anim.track_get_path(t)):
					var kc := anim.track_get_key_count(t)
					if kc > 0:
						var b0: Vector3 = anim.track_get_key_value(t, 0)
						for k in range(kc):
							var kv: Vector3 = anim.track_get_key_value(t, k)
							anim.track_set_key_value(t, k, Vector3(b0.x, kv.y, b0.z))
			anim.loop_mode = Animation.LOOP_LINEAR
			var lib := AnimationLibrary.new()
			lib.add_animation(&"loop_anim", anim)
			ap.add_animation_library(&"npc", lib)
			ap.play(&"npc/loop_anim")
			ap.speed_scale = speed_scale

	if not label_txt.is_empty():
		_make_label3d(npc_root, label_txt, Vector3(0.0, 2.25, 0.0), Color(0.65, 0.90, 1.0), 18)
	return npc_root

func _spawn_station_astronaut(pos: Vector3, rot_deg: Vector3, fbx_path: String, label_txt: String) -> void:
	_create_animated_npc(fbx_path, pos, rot_deg, label_txt, 1.0)

func _spawn_patrol_astronaut(p_start: Vector3, p_end: Vector3, speed: float, label_txt: String) -> void:
	var npc_root := _create_animated_npc("res://assets/characters/walk_briefcase.fbx", p_start, Vector3.ZERO, label_txt, clampf(speed / 1.5, 0.75, 1.35))
	if npc_root == null:
		return
	_patrol_npcs.append({
		"root": npc_root,
		"start": p_start,
		"end": p_end,
		"speed": speed,
		"dist": maxf(0.5, p_start.distance_to(p_end)),
		"phase": float(_patrol_npcs.size()) * 1.4
	})

func _tint_npc_suit(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.name.to_lower() in ["obj28", "obj29", "obj30"]:
			var gold := StandardMaterial3D.new()
			gold.albedo_color = Color(0.88, 0.64, 0.14)
			gold.metallic = 0.92
			gold.roughness = 0.14
			mi.material_override = gold
	for c in node.get_children():
		_tint_npc_suit(c)

func _find_animation_player_rec(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for c in node.get_children():
		var f := _find_animation_player_rec(c)
		if f != null:
			return f
	return null

func _calc_model_aabb(node: Node, xform: Transform3D) -> AABB:
	var cur := xform
	if node is Node3D:
		cur = xform * (node as Node3D).transform
	var res := AABB()
	var has := false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		res = cur * (node as MeshInstance3D).mesh.get_aabb()
		has = true
	for c in node.get_children():
		var ca := _calc_model_aabb(c, cur)
		if ca.size != Vector3.ZERO:
			if has:
				res = res.merge(ca)
			else:
				res = ca
				has = true
	return res

func _tint_visor_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var nm: String = node.name.to_lower()
		if "visor" in nm or "face" in nm:
			(node as MeshInstance3D).material_override = mat
	for c in node.get_children():
		_tint_visor_recursive(c, mat)

func _make_streetlight(pos: Vector3, rot_y: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = rot_y
	add_child(n)
	_make_cylinder(n, Vector3(0, 2.2, 0), 0.08, 4.4, Color(0.28, 0.30, 0.34))
	_make_box_deco(n, Vector3(0.45, 4.3, 0), Vector3(1.0, 0.12, 0.24), Color(0.28, 0.30, 0.34))
	_make_box_deco(n, Vector3(0.75, 4.22, 0), Vector3(0.35, 0.06, 0.18), Color(1.0, 0.94, 0.76), 2.2)

func _make_tree(pos: Vector3, s: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.scale = Vector3.ONE * s
	add_child(n)
	_make_cylinder(n, Vector3(0, 1.1, 0), 0.22, 2.2, Color(0.42, 0.27, 0.16))
	var crown := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.45
	sm.height = 2.6
	crown.mesh = sm
	crown.position = Vector3(0, 2.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.42, 0.20)
	mat.roughness = 0.88
	crown.material_override = mat
	n.add_child(crown)

func _make_label3d(parent: Node3D, txt: String, pos: Vector3, col: Color, fsize: int) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = fsize
	l.outline_size = 6
	l.modulate = col
	parent.add_child(l)
	return l

func _make_box_deco(parent: Node3D, pos: Vector3, sz: Vector3, col: Color, emit: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	if emit > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emit
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _make_cylinder(parent: Node3D, pos: Vector3, rad: float, h: float, col: Color, rot_deg: Vector3 = Vector3.ZERO, emit: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rad
	cm.bottom_radius = rad
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	if emit > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emit
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _make_static_box(pos: Vector3, sz: Vector3, col: Color, bname: String, rough: float = 0.72, emit: float = 0.0) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = bname
	sb.position = pos
	sb.collision_layer = 1
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	if emit > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emit
	mi.material_override = mat
	sb.add_child(mi)

	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = sz
	cs.shape = bs
	sb.add_child(cs)
	add_child(sb)
	return sb

func _make_interactable(pos: Vector3, sz: Vector3, col: Color, iid: String, prompt: String, label_txt: String, emit: float = 0.0) -> StaticBody3D:
	var sb := _make_static_box(pos, sz, col, "Interact_" + iid, 0.55, emit)
	sb.collision_layer = 4
	sb.set_meta("interact_id", iid)
	sb.set_meta("interact_prompt", prompt)
	_make_label3d(sb, label_txt, Vector3(0.0, sz.y * 0.5 + 0.55, 0.0), Color(0.96, 0.98, 1.0), 26)
	return sb

func _build_portals() -> void:
	# Portales luminosos estilo Adopt Me! para entrar y salir de edificios y viajar Campus <-> Casa
	_make_portal(
		"campus_to_home",
		Vector3(3.4, 0.08, -16.5),
		Color(0.28, 0.72, 1.0),
		Vector3(0.0, 0.25, 21.5),
		"HOME",
		"BARRIO RESIDENCIAL",
		"Regreso a Casa · Centro de Descanso",
		"Volver a Casa"
	)
	_make_portal(
		"enter_training",
		Vector3(-37.8, 0.08, -52.0),
		Color(0.16, 0.58, 0.98),
		Vector3(-45.5, 0.25, -52.0),
		"TRAINING",
		"CENTRO DE ENTRENAMIENTO",
		"Centrífuga · Cámara OCSS · Lab. Newton",
		"Entrar: Entrenamiento"
	)
	_make_portal(
		"exit_training",
		Vector3(-41.8, 0.08, -52.0),
		Color(0.25, 0.85, 0.65),
		Vector3(-34.2, 0.25, -52.0),
		"CAMPUS",
		"PLAZA CENTRAL NASA",
		"Campus Kennedy Space Center",
		"Salir a Plaza NASA"
	)
	_make_portal(
		"enter_vab",
		Vector3(37.8, 0.08, -52.0),
		Color(0.95, 0.50, 0.16),
		Vector3(45.5, 0.25, -52.0),
		"VAB",
		"VEHICLE ASSEMBLY BUILDING",
		"Ensamblaje SLS & Hardware Orion",
		"Entrar: VAB"
	)
	_make_portal(
		"exit_vab",
		Vector3(41.8, 0.08, -52.0),
		Color(0.25, 0.85, 0.65),
		Vector3(34.2, 0.25, -52.0),
		"CAMPUS",
		"PLAZA CENTRAL NASA",
		"Campus Kennedy Space Center",
		"Salir a Plaza NASA"
	)
	_make_portal(
		"enter_mcc",
		Vector3(-46.0, 0.08, -90.8),
		Color(0.22, 0.85, 0.50),
		Vector3(-46.0, 0.25, -98.5),
		"MCC",
		"CONTROL DE MISIÓN · MOCR",
		"Software · FIDO · Vuelo Artemis II",
		"Entrar: Control de Misión"
	)
	_make_portal(
		"exit_mcc",
		Vector3(-46.0, 0.08, -94.8),
		Color(0.25, 0.85, 0.65),
		Vector3(-46.0, 0.25, -87.2),
		"CAMPUS",
		"PLAZA CENTRAL NASA",
		"Campus Kennedy Space Center",
		"Salir a Plaza NASA"
	)

func _make_portal(pid: String, pos: Vector3, col: Color, dest_pos: Vector3, zone: String, title: String, subtitle: String, label_txt: String) -> void:
	_portals[pid] = {
		"pos": dest_pos,
		"zone": zone,
		"title": title,
		"subtitle": subtitle
	}

	# Base brillante en el suelo + aro flotante para reconocer rápido la entrada
	_make_cylinder(self, pos, 1.45, 0.12, col, Vector3.ZERO, 1.4)
	_make_cylinder(self, pos + Vector3(0.0, 0.10, 0.0), 1.05, 0.06, Color.WHITE, Vector3.ZERO, 1.8)
	_make_label3d(self, "✦ " + label_txt, pos + Vector3(0.0, 2.25, 0.0), col.lightened(0.45), 28)

	# Área automática al pisar (como en Adopt Me!)
	var area := Area3D.new()
	area.name = "PortalArea_" + pid
	area.position = pos + Vector3(0.0, 1.1, 0.0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.4, 2.2, 2.4)
	cs.shape = bs
	area.add_child(cs)
	area.body_entered.connect(func(body: Node3D):
		if body == player and _portal_cooldown <= 0.0:
			_trigger_portal(pid)
	)
	add_child(area)

	# Poste interactivo lateral por si el jugador prefiere pulsar [E]
	var post_sb := _make_interactable(
		pos + Vector3(0.0, 0.85, 0.0),
		Vector3(0.45, 1.5, 0.45),
		col,
		"portal:" + pid,
		label_txt,
		"",
		0.9
	)
	post_sb.collision_layer = 4
	# Desactivar colisión física sólida en el poste invisible de raycast? StaticBody sin colisión de capa 1 deja caminar libremente sobre el pad
	for ch in post_sb.get_children():
		if ch is MeshInstance3D:
			(ch as MeshInstance3D).visible = false
		elif ch is Label3D:
			(ch as Label3D).visible = false

func _trigger_portal(pid: String) -> void:
	if not _portals.has(pid) or not hud or not hud.transition:
		return
	if hud.transition.is_busy():
		return
	_portal_cooldown = 2.0
	var pinfo: Dictionary = _portals[pid]
	var dest: Vector3 = pinfo["pos"]
	var z: String = String(pinfo["zone"])
	hud.transition.play_teleport(
		String(pinfo["title"]),
		String(pinfo["subtitle"]),
		func():
			if is_instance_valid(player):
				player.global_position = dest
				player.velocity = Vector3.ZERO
			GameState.set_zone(z)
	)

func _sync_vab_rocket_visuals() -> void:
	for pid in _vab_rocket_parts.keys():
		var node := _vab_rocket_parts[pid] as Node3D
		if is_instance_valid(node):
			node.visible = GameState.sls_stacked_parts.has(pid)

func _sync_sign_visuals() -> void:
	for sid in _sign_nodes.keys():
		var info: Dictionary = _sign_nodes[sid]
		var lbl := info.get("label", null) as Label3D
		if is_instance_valid(lbl):
			if ObjectiveManager.is_sign_visited(sid):
				lbl.text = "✔ " + String(info["base_txt"]) + " [VISITADO]"
				lbl.modulate = Color(0.42, 0.96, 0.56)
			else:
				lbl.text = String(info["base_txt"])
				lbl.modulate = Color(0.96, 0.98, 1.0)

func _get_active_target() -> Dictionary:
	var obj: Dictionary = ObjectiveManager.get_current_objective()
	if obj.is_empty():
		return {}
	var cur_id: String = String(obj.get("id", ""))
	if cur_id == "campus_tour":
		var visited: int = ObjectiveManager.get_visited_signs_count()
		for sid in _sign_order:
			if not ObjectiveManager.is_sign_visited(sid) and _sign_nodes.has(sid):
				var info: Dictionary = _sign_nodes[sid]
				return {
					"pos": info["pos"],
					"label": "Cartel %d/4: %s" % [visited + 1, String(info["short"])]
				}
	var t_id: String = String(obj.get("target", ""))
	if targets.has(t_id):
		return targets[t_id]
	return {}

func _refresh_beacon() -> void:
	if not is_instance_valid(beacon):
		return
	var t: Dictionary = _get_active_target()
	if t.is_empty():
		beacon.visible = false
	else:
		beacon.set_target(t["pos"], t["label"])

func _on_substep_updated(_obj_id = null, _substep_idx = null) -> void:
	_sync_sign_visuals()
	_refresh_beacon()

func _on_phase_changed(new_phase: int) -> void:
	if is_instance_valid(_pad_flame):
		_pad_flame.visible = (new_phase == CatalogData.FlightPhase.LAUNCH)

func _on_objective_started(obj: Dictionary) -> void:
	_sync_vab_rocket_visuals()
	_sync_sign_visuals()
	_refresh_beacon()
	if not obj.is_empty():
		var cur_id: String = String(obj.get("id", ""))
		if cur_id != "home_badge" and int(obj.get("chapter", 0)) >= 1 and is_instance_valid(badge_node):
			badge_node.visible = false
			badge_node.collision_layer = 0

func sync_from_campaign_state(is_new_campaign: bool = false) -> void:
	if is_instance_valid(player):
		if is_new_campaign or not SaveSystem.has_loaded_pose:
			player.global_position = Vector3(0.0, 0.25, 30.0)
			player.rotation.y = 0.0
		else:
			player.global_position = SaveSystem.last_loaded_player_pos
			player.rotation.y = SaveSystem.last_loaded_player_yaw
		player.velocity = Vector3.ZERO
	if is_instance_valid(badge_node):
		var show_badge: bool = is_new_campaign or not ObjectiveManager.completed_ids.has("home_badge")
		badge_node.visible = show_badge
		badge_node.collision_layer = 5 if show_badge else 0
	if is_instance_valid(_gate_arm):
		var gate_open: bool = (not is_new_campaign) and ObjectiveManager.completed_ids.has("campus_gate")
		_gate_arm.rotation_degrees.z = 72.0 if gate_open else 0.0
	_sync_vab_rocket_visuals()
	_sync_sign_visuals()
	_refresh_beacon()

func _process(delta: float) -> void:
	_anim_t += delta
	if _portal_cooldown > 0.0:
		_portal_cooldown = maxf(0.0, _portal_cooldown - delta)
	if is_instance_valid(_centrifuge_arm):
		_centrifuge_arm.rotate_y(delta * 0.9)
	if is_instance_valid(_diorama_marker):
		_diorama_marker.rotate_y(delta * 0.8)
	for npc in _patrol_npcs:
		var root := npc.get("root", null) as Node3D
		if is_instance_valid(root):
			var p0: Vector3 = npc["start"]
			var p1: Vector3 = npc["end"]
			var dist: float = npc["dist"]
			var cycle: float = fmod(_anim_t * float(npc["speed"]) / dist + float(npc["phase"]), 2.0)
			var u: float = cycle if cycle <= 1.0 else (2.0 - cycle)
			var next_pos: Vector3 = p0.lerp(p1, u)
			var look_target: Vector3 = p1 if cycle <= 1.0 else p0
			root.global_position = next_pos
			if next_pos.distance_squared_to(look_target) > 0.01:
				root.look_at(Vector3(look_target.x, root.global_position.y, look_target.z), Vector3.UP)

	if not player or not hud:
		return

	# Detección automática de zona según posición 3D
	var p := player.global_position
	if p.z > 14.0:
		GameState.set_zone("HOME")
	elif p.x < -38.0 and p.z > -66.0 and p.z < -38.0:
		GameState.set_zone("TRAINING")
	elif p.x > 38.0 and p.z > -68.0 and p.z < -36.0:
		GameState.set_zone("VAB")
	elif p.x < -30.0 and p.z < -90.0:
		GameState.set_zone("MCC")
	else:
		GameState.set_zone("CAMPUS")

	var t: Dictionary = _get_active_target()
	if not t.is_empty():
		var fwd: Vector3 = -player.global_transform.basis.z
		hud.compass.update_compass(player.global_position, fwd, t["pos"], t["label"])

func _on_player_interact(node: Node) -> void:
	var iid: String = String(node.get_meta("interact_id", ""))
	var cur: Dictionary = ObjectiveManager.get_current_objective()
	var cur_id: String = String(cur.get("id", ""))

	if iid.begins_with("portal:"):
		_trigger_portal(iid.substr(7))
		return

	match iid:
		"badge":
			if cur_id == "home_badge":
				ObjectiveManager.notify_event("badge_taken")
				if is_instance_valid(badge_node):
					badge_node.visible = false
					badge_node.collision_layer = 0
				hud.show_hud_notice("Credencial NASA recogida ✔ — Siguiente: lee tu portátil", UITheme.GREEN)
			else:
				hud.show_hud_notice("Credencial ya recogida", UITheme.TEXT_DIM)
		"laptop":
			hud.open_info_popup(
				"CORREO INTERNO NASA · ARTEMIS II",
				"Asignación de Tripulación Confirmada",
				"[b]De:[/b] Dirección de Operaciones de Vuelo (JSC Houston)\n[b]Asunto:[/b] Convocatoria inmediata — Misión Artemis II\n\n¡Enhorabuena, Ingeniero de Misión!\nHas sido seleccionado para dirigir las pruebas, el ensamblaje del cohete [color=#ffa940]SLS[/color] y el sobrevuelo lunar tripulado a bordo de la cápsula [color=#60b4ff]Orion[/color].\n\n• [b]Perfil:[/b] Trayectoria de retorno libre (~10 días)\n• [b]Próximo paso:[/b] Sal de casa y sube al [color=#5ce08c]Astrovan NASA[/color] rumbo al Centro Espacial Kennedy.",
				"Aceptar Misión ✔" if cur_id == "home_email" else "Cerrar",
				func():
					if ObjectiveManager.get_current_objective().get("id", "") == "home_email":
						ObjectiveManager.notify_event("read_email")
						hud.show_hud_notice("Correo leído ✔ — Sal al Astrovan frente a casa", UITheme.CYAN)
			)
		"astrovan":
			if cur_id == "home_depart":
				_portal_cooldown = 2.0
				hud.transition.play_teleport(
					"CAMPUS NASA · KSC",
					"Garita de Seguridad y Plaza Central",
					func():
						ObjectiveManager.notify_event("depart_home")
						GameState.set_zone("CAMPUS")
						player.global_position = Vector3(0.0, 0.25, -18.0)
						player.velocity = Vector3.ZERO
				)
			elif int(cur.get("chapter", 0)) == 0:
				hud.show_hud_notice("Primero completa: %s" % String(cur.get("title", "")), UITheme.GOLD)
			else:
				_portal_cooldown = 2.0
				hud.transition.play_teleport(
					"CAMPUS NASA · KSC",
					"Centro Espacial Kennedy",
					func():
						GameState.set_zone("CAMPUS")
						player.global_position = Vector3(0.0, 0.25, -18.0)
						player.velocity = Vector3.ZERO
				)
		"security_gate":
			if cur_id == "campus_security":
				if is_instance_valid(_gate_arm):
					_gate_arm.rotation_degrees.z = -72.0
				hud.open_info_popup(
					"CONTROL DE SEGURIDAD · KSC",
					"Credencial Verificada — Acceso Autorizado",
					"Tu credencial de tripulación Artemis II ha sido validada en la garita.\n\n[b]Siguiente paso:[/b] Recorre la [color=#60b4ff]Plaza Central[/color] y lee los [color=#5ce08c]4 carteles de orientación[/color] siguiendo la brújula superior y la baliza azul.",
					"Entrar al Campus ✔",
					func():
						if ObjectiveManager.get_current_objective().get("id", "") == "campus_security":
							ObjectiveManager.notify_event("show_badge")
							hud.show_hud_notice("Acceso autorizado ✔ — Visita los 4 carteles del campus", UITheme.GREEN)
				)
			elif int(cur.get("chapter", 0)) >= 1:
				if is_instance_valid(_gate_arm):
					_gate_arm.rotation_degrees.z = -72.0
				hud.show_hud_notice("Garita abierta ✔ — Adelante hacia la Plaza Central", UITheme.GREEN)
			else:
				hud.show_hud_notice("Primero completa los pasos en tu casa (Cap. 0)", UITheme.GOLD)
		"briefing_terminal":
			hud.open_info_popup(
				"SALA DE BRIEFING · ARTEMIS II",
				"Perfil Oficial de Vuelo: Retorno Libre Lunar",
				"[b]Duración:[/b] ~10 días · [b]Tripulación:[/b] 4 astronautas\n[b]Vehículo:[/b] SLS Block 1 + Módulo Orion\n\n[b]Fases clave de la campaña:[/b]\n1. Entrenamiento físico (Centrífuga, Vacío OCSS y Newton)\n2. Ensamblaje del SLS en el VAB + Hardware de Orion\n3. Software de vuelo, FIDO y Lanzamiento desde 39B\n4. Órbita HEO, TLI, sobrevuelo por la [color=#60b4ff]cara oculta lunar[/color] y amerizaje.\n\n[i]Tras confirmar, cruza el portal azul al Oeste (Entrenamiento).[/i]",
				"Confirmar Briefing ✔" if cur_id == "campus_briefing" else "Cerrar",
				func():
					if ObjectiveManager.get_current_objective().get("id", "") == "campus_briefing":
						ObjectiveManager.notify_event("briefing_done")
						hud.show_hud_notice("Briefing completado ✔ — Ve al edificio de Entrenamiento (Oeste)", UITheme.GREEN)
			)
		"centrifuge":
			if cur_id == "train_centrifuge":
				_open_minigame(TrainingMinigames.create("centrifuge"))
			else:
				hud.show_hud_notice("Centrífuga disponible en otro paso · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"vacuum_ocss":
			if cur_id == "train_vacuum_ocss":
				_open_minigame(TrainingMinigames.create("ocss"))
			else:
				hud.show_hud_notice("Cámara de vacío disponible en otro paso · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"newton_lab":
			if cur_id == "train_newton":
				_open_minigame(TrainingMinigames.create("newton"))
			else:
				hud.show_hud_notice("Lab. Newton disponible en otro paso · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"vab_crane":
			if int(cur.get("chapter", -1)) == 3:
				_open_minigame(VABCraneMinigame.new())
			else:
				hud.show_hud_notice("Grúa VAB disponible en Cap. 3 · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"hw_bench":
			match cur_id:
				"hw_power_buses": _open_minigame(HardwareMinigames.create("power"))
				"hw_eclss": _open_minigame(HardwareMinigames.create("eclss"))
				"hw_heat_shield": _open_minigame(HardwareMinigames.create("shield"))
				"hw_antennas": _open_minigame(HardwareMinigames.create("antennas"))
				_: hud.show_hud_notice("Banco Hardware disponible en Cap. 4 · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"mcc_software":
			match cur_id:
				"sw_gls_sequence": _open_minigame(SoftwareMinigames.create("gls"))
				"sw_debug_units": _open_minigame(SoftwareMinigames.create("debug_units"))
				"sw_redundancy": _open_minigame(SoftwareMinigames.create("redundancy"))
				"sw_telemetry": _open_minigame(SoftwareMinigames.create("telemetry"))
				_: hud.show_hud_notice("Consola Software disponible en Cap. 5 · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"mcc_fido":
			match cur_id:
				"fido_window": _open_minigame(TrajectoryAndLaunchMinigames.create("window"))
				"fido_tsiolkovsky": _open_minigame(TrajectoryAndLaunchMinigames.create("tsiolkovsky"))
				"fido_free_return": _open_minigame(TrajectoryAndLaunchMinigames.create("free_return"))
				_: hud.show_hud_notice("Consola FIDO disponible en Cap. 6 · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"mcc_flight":
			match cur_id:
				"launch_gonogo": _open_minigame(TrajectoryAndLaunchMinigames.create("gonogo"))
				"launch_ascent": _open_minigame(TrajectoryAndLaunchMinigames.create("ascent"))
				"heo_perigee_raise": _open_minigame(SpaceFlightMinigames.create("heo_perigee"))
				"heo_proximity_ops": _open_minigame(SpaceFlightMinigames.create("heo_prox"))
				"heo_sys_check": _open_minigame(SpaceFlightMinigames.create("heo_check"))
				"tli_burn": _open_minigame(SpaceFlightMinigames.create("tli_burn"))
				"cruise_dsn": _open_minigame(SpaceFlightMinigames.create("cruise_dsn"))
				"cruise_tcm": _open_minigame(SpaceFlightMinigames.create("cruise_tcm"))
				"cruise_solar_storm": _open_minigame(SpaceFlightMinigames.create("cruise_storm"))
				"flyby_los": _open_minigame(SpaceFlightMinigames.create("flyby_los"))
				"flyby_science": _open_minigame(SpaceFlightMinigames.create("flyby_science"))
				"flyby_gravity_assist": _open_minigame(SpaceFlightMinigames.create("flyby_gravity"))
				"reentry_sep": _open_minigame(SpaceFlightMinigames.create("reentry_sep"))
				"reentry_corridor": _open_minigame(SpaceFlightMinigames.create("reentry_corridor"))
				"reentry_chutes": _open_minigame(SpaceFlightMinigames.create("reentry_chutes"))
				"reentry_splashdown": _open_minigame(SpaceFlightMinigames.create("reentry_splash"))
				_: hud.show_hud_notice("Consola Director de Vuelo disponible en Cap. 7–11 · Actual: %s" % String(cur.get("title", "")), UITheme.GOLD)
		"mcc_debrief":
			if cur_id == "debrief_receipt" or ObjectiveManager.is_campaign_finished():
				hud.show_debrief_receipt()
			else:
				hud.show_hud_notice("Terminal de Debrief disponible al terminar la misión (Cap. 12)", UITheme.GOLD)
		"shuttle_exhibit":
			hud.open_info_popup(
				"PARQUE DE COHETES · NASA KSC",
				"Transbordador Espacial — Herencia RS-25",
				"[b]Conexión directa con Artemis II:[/b]\nLos [color=#ffa940]4 motores RS-25[/color] de la etapa central del cohete [b]SLS[/b] son versiones modernizadas de los legendarios motores principales del Transbordador Espacial.\n\n• [b]Impulso específico (Isp):[/b] ~452 s en vacío (LH₂ / LOX)\n• [b]Escudo térmico:[/b] losetas cerámicas reutilizables inspiraron la protección térmica para reentrada de Orion (~2 760 °C).",
				"Entendido ✔"
			)
		"ksc_diorama":
			hud.open_info_popup(
				"MAQUETA TÁCTICA 3D · KSC",
				"Complejo de Lanzamiento Artemis",
				"[b]Distribución del Campus NASA:[/b]\n• [color=#60b4ff]Oeste:[/color] Centro de Entrenamiento (Centrífuga, Cámara OCSS, Newton)\n• [color=#ffa940]Este:[/color] Edificio de Ensamblaje Vertical (VAB + Grúa Puente)\n• [color=#5ce08c]Noroeste:[/color] Control de Misión (MOCR Houston)\n• [color=#ff7875]Noreste:[/color] Plataforma 39B con torre umbilical y cohete SLS.",
				"Cerrar"
			)
		"suit_gallery":
			hud.open_info_popup(
				"GALERÍA HISTÓRICA DE TRAJES NASA",
				"Del Programa Gemini a Artemis (Mark III / OCSS)",
				"• [b]Traje Gemini G4C (1965):[/b] permitió la primera caminata espacial estadounidense (EVA) manteniendo ~0.25 atm de oxígeno puro.\n• [b]Traje Mark III / xEMU:[/b] articulaciones de cadera y rodamiento rígido para caminar sobre la superficie lunar y soportar radiación/vacío.\n• [b]Robonaut 2:[/b] asistente robótico humanoide probado en la EEI para tareas de mantenimiento.",
				"Cerrar"
			)
		"orion_exhibit":
			hud.open_info_popup(
				"CÁPSULA ORION MPCV · ARTEMIS II",
				"Módulo de Tripulación y Escudo Térmico Avcoat",
				"[b]Nave tripulada de espacio profundo:[/b]\n• [color=#60b4ff][b]Diámetro:[/b][/color] 5.02 m · [b]Capacidad:[/b] 4 astronautas hasta 21 días.\n• [b]Escudo térmico Avcoat:[/b] protege del plasma de reentrada a ~2 760 °C y ~11 km/s al regresar de la Luna.\n• [b]Ubicación en el cohete:[/b] en la punta del SLS Block 1 bajo la torre de escape LAS.",
				"Cerrar"
			)
		"moon_exhibit":
			hud.open_info_popup(
				"TOPOGRAFÍA LUNAR · CRÁTER COPÉRNICO",
				"Geología y Objetivos Científicos de Sobrevuelo",
				"[b]Cráter Copérnico (93 km de diámetro):[/b]\nUno de los cráteres de impacto más jóvenes y brillantes de la Luna, con un sistema de rayos de eyección de hasta 800 km.\n\n• En el [color=#5ce08c]Capítulo 10[/color] fotografiarás regiones lunares objetivo desde la cápsula Orion durante el paso de retorno libre.",
				"Cerrar"
			)
		_:
			if iid.begins_with("sign:"):
				var sname: String = iid.substr(5)
				var info: Dictionary = _sign_nodes.get(sname, {})
				var ttl: String = String(info.get("title", "Cartel de Orientación NASA"))
				var body: String = String(info.get("desc", "Sector del Campus Kennedy Space Center."))
				var can_visit: bool = (cur_id == "campus_tour")
				var btn_txt: String = "Registrar Cartel ✔" if can_visit else "Cerrar"
				hud.open_info_popup(
					"ORIENTACIÓN DEL CAMPUS NASA",
					ttl,
					body,
					btn_txt,
					func():
						if ObjectiveManager.get_current_objective().get("id", "") == "campus_tour":
							ObjectiveManager.notify_event("visit:" + sname)
							_sync_sign_visuals()
							_refresh_beacon()
							var cnt := ObjectiveManager.get_visited_signs_count()
							if cnt < 4:
								hud.show_hud_notice("Cartel %d/4 visitado ✔ — Sigue la baliza al siguiente" % cnt, UITheme.CYAN)
							else:
								hud.show_hud_notice("4/4 Carteles completados ✔ — Ve al Terminal Briefing", UITheme.GREEN)
				)

func _open_minigame(mg: BaseMinigame) -> void:
	mg.finished.connect(func(_ok):
		hud.clear_minigames()
		_sync_vab_rocket_visuals()
	)
	hud.launch_minigame(mg)
