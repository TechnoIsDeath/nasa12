extends Node

## Sistema de guardado multi-ranura (3 partidas estilo Cuphead / Hollow Knight)
## en user://artemis_slot_1.json .. user://artemis_slot_3.json.

const MAX_SLOTS: int = 3
const LEGACY_SAVE_PATH: String = "user://artemis_save.json"

var active_slot: int = 1
var has_loaded_pose: bool = false
var last_loaded_player_pos: Vector3 = Vector3(0.0, 0.25, 30.0)
var last_loaded_player_yaw: float = 0.0

func _ready() -> void:
	_migrate_legacy_save()

func get_slot_path(slot: int = -1) -> String:
	var s: int = active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	return "user://artemis_slot_%d.json" % s

func select_slot(slot: int) -> void:
	active_slot = clampi(slot, 1, MAX_SLOTS)

func _migrate_legacy_save() -> void:
	if FileAccess.file_exists(LEGACY_SAVE_PATH) and not FileAccess.file_exists(get_slot_path(1)):
		var f_in := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
		if f_in:
			var content := f_in.get_as_text()
			f_in.close()
			var f_out := FileAccess.open(get_slot_path(1), FileAccess.WRITE)
			if f_out:
				f_out.store_string(content)
				f_out.close()

func has_save(slot: int = -1) -> bool:
	return FileAccess.file_exists(get_slot_path(slot))

func save_progress(slot: int = -1, player_node: Node3D = null) -> void:
	var s: int = active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	active_slot = s

	var p_pos: Vector3 = last_loaded_player_pos
	var p_yaw: float = last_loaded_player_yaw
	if is_instance_valid(player_node):
		p_pos = player_node.global_position
		p_yaw = player_node.rotation.y
	elif get_tree() and get_tree().current_scene:
		var found := get_tree().current_scene.get_node_or_null("Player") as Node3D
		if is_instance_valid(found):
			p_pos = found.global_position
			p_yaw = found.rotation.y

	var cur_obj := ObjectiveManager.get_current_objective()
	var data := {
		"version": 2,
		"slot": s,
		"timestamp": Time.get_datetime_string_from_system(false, true).replace("T", " "),
		"active_idx": ObjectiveManager.active_idx,
		"chapter": int(cur_obj.get("chapter", 12 if ObjectiveManager.completed_count() >= ObjectiveManager.total_count() else 0)),
		"objective_title": String(cur_obj.get("title", "Campaña Completada")),
		"completed_count": ObjectiveManager.completed_count(),
		"total_count": ObjectiveManager.total_count(),
		"completed_ids": ObjectiveManager.completed_ids,
		"unlocked_glossary": ObjectiveManager.unlocked_glossary,
		"tour_visited": ObjectiveManager.get_tour_visited_list(),
		"unlocked_achievements": AchievementManager.unlocked,
		"achievements_count": AchievementManager.unlocked.size(),
		"achievements_total": AchievementManager.achievements.size(),
		"current_zone": GameState.current_zone,
		"current_phase": GameState.current_phase,
		"sls_stacked_parts": GameState.sls_stacked_parts,
		"errors_log": GameState.errors_log,
		"errors_count": GameState.errors_log.size(),
		"chapter_scores": GameState.chapter_scores,
		"mission_time_sec": GameState.mission_time_sec,
		"player_pos": [p_pos.x, p_pos.y, p_pos.z],
		"player_yaw": p_yaw
	}
	var file := FileAccess.open(get_slot_path(s), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_progress(slot: int = -1) -> bool:
	var s: int = active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	if not has_save(s):
		return false
	var file := FileAccess.open(get_slot_path(s), FileAccess.READ)
	if not file:
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	active_slot = s

	GameState.current_zone = String(d.get("current_zone", "HOME"))
	GameState.current_phase = int(d.get("current_phase", CatalogData.FlightPhase.PRELAUNCH))
	GameState.mission_time_sec = float(d.get("mission_time_sec", 0.0))

	var sls: Array[String] = []
	for p in d.get("sls_stacked_parts", []):
		sls.append(String(p))
	GameState.sls_stacked_parts = sls

	var errs: Array[Dictionary] = []
	for e in d.get("errors_log", []):
		if typeof(e) == TYPE_DICTIONARY:
			errs.append(e)
	GameState.errors_log = errs
	GameState.chapter_scores = d.get("chapter_scores", {})

	AchievementManager.restore(d.get("unlocked_achievements", {}))

	var glos: Array[String] = []
	for g in d.get("unlocked_glossary", []):
		glos.append(String(g))

	var tour: Array = d.get("tour_visited", [])
	ObjectiveManager.restore_from_save(
		int(d.get("active_idx", 0)),
		d.get("completed_ids", {}),
		glos,
		tour
	)

	var pos_arr = d.get("player_pos", [])
	if typeof(pos_arr) == TYPE_ARRAY and pos_arr.size() == 3:
		last_loaded_player_pos = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
		last_loaded_player_yaw = float(d.get("player_yaw", 0.0))
		has_loaded_pose = true
	else:
		last_loaded_player_pos = Vector3(0.0, 0.25, 30.0)
		last_loaded_player_yaw = 0.0
		has_loaded_pose = false
	return true

func get_slot_summary(slot: int) -> Dictionary:
	var s: int = clampi(slot, 1, MAX_SLOTS)
	if not has_save(s):
		return {"slot": s, "empty": true}
	var file := FileAccess.open(get_slot_path(s), FileAccess.READ)
	if not file:
		return {"slot": s, "empty": true}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"slot": s, "empty": true}
	var d: Dictionary = parsed

	var comp_dict: Dictionary = d.get("completed_ids", {})
	var comp_count: int = int(d.get("completed_count", comp_dict.size()))
	var tot_count: int = maxi(1, int(d.get("total_count", ObjectiveManager.total_count())))
	var pct: float = clampf(float(comp_count) / float(tot_count) * 100.0, 0.0, 100.0)

	var a_dict: Dictionary = d.get("unlocked_achievements", {})
	var a_count: int = int(d.get("achievements_count", a_dict.size()))
	var a_tot: int = maxi(1, int(d.get("achievements_total", AchievementManager.achievements.size())))

	var ch: int = int(d.get("chapter", 0))
	if not d.has("chapter"):
		var idx: int = int(d.get("active_idx", 0))
		if idx >= 0 and idx < ObjectiveManager.objectives.size():
			ch = int(ObjectiveManager.objectives[idx].get("chapter", 0))

	return {
		"slot": s,
		"empty": false,
		"chapter": ch,
		"chapter_name": String(CatalogData.CHAPTER_NAMES.get(ch, "Misión Artemis II")),
		"objective_title": String(d.get("objective_title", "En curso")),
		"completed_count": comp_count,
		"total_count": tot_count,
		"pct": pct,
		"achievements_count": a_count,
		"achievements_total": a_tot,
		"zone": String(d.get("current_zone", "HOME")),
		"errors_count": int(d.get("errors_count", d.get("errors_log", []).size())),
		"mission_time_sec": float(d.get("mission_time_sec", 0.0)),
		"timestamp": String(d.get("timestamp", "Guardado reciente"))
	}

func get_all_slot_summaries() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for s in range(1, MAX_SLOTS + 1):
		res.append(get_slot_summary(s))
	return res

func delete_save(slot: int = -1) -> void:
	var s: int = active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	if has_save(s):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(get_slot_path(s)))
	if s == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))

func format_time(sec: float) -> String:
	var total_s: int = maxi(0, int(sec))
	var mins: int = int(total_s / 60)
	var rem_s: int = total_s % 60
	return "%02d:%02d" % [mins, rem_s]
