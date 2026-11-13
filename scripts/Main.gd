extends Node3D

## Escena raíz de Cosmic Blueprint: Misión Artemis (campaña de un solo rol).

func _ready() -> void:
	var player := FirstPersonPlayer.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.25, 30.0) # Inicio dentro del dormitorio de Casa
	add_child(player)

	var hud := MissionControlHUD.new()
	hud.name = "MissionControlHUD"
	add_child(hud)
	hud.setup_player(player)

	var world := WorldManager.new()
	world.name = "WorldManager"
	add_child(world)
	world.setup(player, hud)

	if OS.get_cmdline_user_args().has("--run-self-test"):
		_run_automated_verification(player, hud, world)
		return

	if SaveSystem.has_save():
		SaveSystem.load_progress()
	else:
		ObjectiveManager.start_new_campaign()

	hud.show_hud_notice("Bienvenido, Ingeniero · Sigue la baliza (tecla H para briefing)", UITheme.CYAN)

func _process(delta: float) -> void:
	GameState.mission_time_sec += delta

func _run_automated_verification(player: FirstPersonPlayer, hud: MissionControlHUD, world: WorldManager) -> void:
	print("[TEST] === Cosmic Blueprint: Misión Artemis (Self-Test) ===")
	ObjectiveManager.start_new_campaign()

	# 1. Verificar animaciones y modelo de personaje
	var anim_list: PackedStringArray = player.suit_anim_player.get_animation_list() if player.suit_anim_player else PackedStringArray()
	player.toggle_third_person()
	var tp_ok: bool = player.third_person
	player.toggle_third_person()
	print("[TEST] 1. Jugador en pos: %s | Animaciones: %s | 3P toggle: %s" % [
		str(player.global_position), str(anim_list), str(tp_ok)
	])

	# 2. Verificar ventanas emergentes (sin solapamientos ni bloqueo de ratón), InfoPopup y Transición Adopt Me
	var start_auto_popup_off: bool = not hud.briefing.visible
	hud.open_briefing()
	var lock1: bool = player.ui_open and hud.briefing.visible
	hud.open_achievements()
	var lock2: bool = player.ui_open and hud.ach_tree.visible and not hud.briefing.visible
	hud.ach_tree.hide_tree()
	var unlock_ok: bool = not player.ui_open
	hud.open_info_popup("TEST", "Cartel NASA", "Info de prueba", "Cerrar")
	var info_lock: bool = player.ui_open and hud.info_popup.visible
	hud.info_popup.hide_popup()
	var info_unlock: bool = not player.ui_open and not hud.info_popup.visible
	var teleport_res := {"ok": false}
	hud.transition.play_teleport("DESTINO TEST", "Subtítulo", func(): teleport_res["ok"] = true)
	var mg := TrainingMinigames.create("centrifuge")
	hud.launch_minigame(mg)
	var lock3: bool = player.ui_open and hud.has_active_minigame()
	hud.clear_minigames()
	var unlock2_ok: bool = not player.ui_open and not hud.has_active_minigame()
	var mg_specs: Array = [
		TrainingMinigames.create("centrifuge"), TrainingMinigames.create("ocss"), TrainingMinigames.create("newton"),
		VABCraneMinigame.new(),
		HardwareMinigames.create("power"), HardwareMinigames.create("eclss"), HardwareMinigames.create("shield"), HardwareMinigames.create("antennas"),
		SoftwareMinigames.create("gls"), SoftwareMinigames.create("debug_units"), SoftwareMinigames.create("redundancy"), SoftwareMinigames.create("telemetry"),
		TrajectoryAndLaunchMinigames.create("window"), TrajectoryAndLaunchMinigames.create("tsiolkovsky"), TrajectoryAndLaunchMinigames.create("free_return"), TrajectoryAndLaunchMinigames.create("gonogo"), TrajectoryAndLaunchMinigames.create("ascent"),
		SpaceFlightMinigames.create("heo_perigee"), SpaceFlightMinigames.create("heo_prox"), SpaceFlightMinigames.create("heo_check"), SpaceFlightMinigames.create("tli_burn"),
		SpaceFlightMinigames.create("cruise_dsn"), SpaceFlightMinigames.create("cruise_tcm"), SpaceFlightMinigames.create("cruise_storm"),
		SpaceFlightMinigames.create("flyby_los"), SpaceFlightMinigames.create("flyby_science"), SpaceFlightMinigames.create("flyby_gravity"),
		SpaceFlightMinigames.create("reentry_sep"), SpaceFlightMinigames.create("reentry_corridor"), SpaceFlightMinigames.create("reentry_chutes"), SpaceFlightMinigames.create("reentry_splash")
	]
	for item in mg_specs:
		var inst: BaseMinigame = item
		hud.launch_minigame(inst)
		await get_tree().process_frame
		hud.clear_minigames()
	print("[TEST] 2. Popups UI -> NoAutoBriefing=%s | BriefingLock=%s | AchSwitch=%s | Unlock=%s | InfoOK=%s/%s | IrisTeleport=%s | Minigame=%s/%s | All31Minigames=%d" % [
		str(start_auto_popup_off), str(lock1), str(lock2), str(unlock_ok), str(info_lock), str(info_unlock), str(teleport_res["ok"]), str(lock3), str(unlock2_ok), mg_specs.size()
	])

	# 3. Verificar física aeroespacial
	var sls_ids: Array[String] = ["srb_left", "srb_right", "core_stage", "lvsa_icps", "msa_esm", "orion_cm", "las"]
	var sls_eval: Dictionary = AeroPhysics.evaluate_sls_stack(sls_ids)
	var dv_tli: float = AeroPhysics.tsiolkovsky_delta_v(465.0, 32000.0, 15000.0)
	var fr_eval: Dictionary = AeroPhysics.evaluate_free_return(7400.0, 3100.0)
	var re_eval: Dictionary = AeroPhysics.evaluate_reentry_corridor(-6.25)
	print("[TEST] 3. Física -> SLS TWR: %.2f (safe=%s) | Tsiolkovsky dV: %.0f m/s | FreeReturn: %s | Reentrada: %s" % [
		float(sls_eval["twr"]), str(sls_eval["safe_liftoff"]), dv_tli, str(fr_eval["valid"]), str(re_eval["safe"])
	])

	# 4. Simular progresión completa de los 12 capítulos (43 retos)
	var events := [
		"woke_up", "badge_taken", "read_email", "depart_home",
		"show_badge", "visit:training", "visit:vab", "visit:mcc", "visit:pad", "briefing_done",
		"centrifuge_passed", "ocss_checked", "newton_quiz_passed"
	]
	for ev in events:
		ObjectiveManager.notify_event(ev)
		if ev == "show_badge":
			var before_lbl: String = String(world._get_active_target().get("label", ""))
			ObjectiveManager.notify_event("visit:training")
			var after_lbl: String = String(world._get_active_target().get("label", ""))
			print("[TEST] 3b. Carteles Tour -> Antes: '%s' | Tras 1er cartel: '%s'" % [before_lbl, after_lbl])

	for pid in sls_ids:
		GameState.sls_stacked_parts.append(pid)
		ObjectiveManager.notify_event("stack_part:" + pid)
	ObjectiveManager.notify_event("vab_complete_twr")

	var post_vab_events := [
		"hw_power_done", "hw_eclss_done", "hw_shield_done", "hw_antennas_done",
		"sw_gls_done", "sw_debug_done", "sw_redundancy_done", "sw_telemetry_done",
		"fido_window_done", "fido_dv_done", "fido_return_done",
		"launch_gonogo_done", "launch_ascent_done",
		"heo_perigee_done", "heo_prox_done", "heo_check_done",
		"tli_burn_done", "cruise_dsn_done", "cruise_tcm_done", "cruise_storm_done",
		"flyby_los_done", "flyby_science_done", "flyby_gravity_done",
		"reentry_sep_done", "reentry_corridor_done", "reentry_chutes_done", "reentry_splash_done",
		"debrief_viewed"
	]
	for ev in post_vab_events:
		ObjectiveManager.notify_event(ev)

	var receipt: Dictionary = GameState.generate_debrief_receipt()
	print("[TEST] 4. Campaña completada -> Retos: %d/%d | Logros: %d/%d (%.0f%%) | Calificación: %s (%d pts)" % [
		ObjectiveManager.completed_count(),
		ObjectiveManager.total_count(),
		AchievementManager.unlocked.size(),
		AchievementManager.achievements.size(),
		AchievementManager.get_progress_pct(),
		String(receipt.get("grade", "")),
		int(receipt.get("score", 0))
	])

	SaveSystem.save_progress()
	var save_ok: bool = SaveSystem.has_save()
	SaveSystem.delete_save()
	print("[TEST] 5. SaveSystem OK: %s | Baliza válida: %s" % [str(save_ok), str(is_instance_valid(world.beacon))])
	get_tree().quit(0)
