extends Node

## Sistema de guardado automático en user://artemis_save.json.

const SAVE_PATH: String = "user://artemis_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_progress() -> void:
	var data := {
		"version": 1,
		"active_idx": ObjectiveManager.active_idx,
		"completed_ids": ObjectiveManager.completed_ids,
		"unlocked_glossary": ObjectiveManager.unlocked_glossary,
		"unlocked_achievements": AchievementManager.unlocked,
		"current_zone": GameState.current_zone,
		"current_phase": GameState.current_phase,
		"sls_stacked_parts": GameState.sls_stacked_parts,
		"errors_log": GameState.errors_log,
		"chapter_scores": GameState.chapter_scores,
		"mission_time_sec": GameState.mission_time_sec
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_progress() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed

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
	ObjectiveManager.restore_from_save(
		int(d.get("active_idx", 0)),
		d.get("completed_ids", {}),
		glos
	)
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
