extends Node

## Gestor de retos basado en datos (MissionScript).
## Controla el reto activo, subpasos, desbloqueo de glosario y progresión de capítulos.

signal objective_started(obj: Dictionary)
signal substep_updated(obj: Dictionary, substep_idx: int)
signal objective_completed(obj: Dictionary)
signal chapter_completed(chapter_idx: int)
signal campaign_finished()

var objectives: Array[Dictionary] = []
var active_idx: int = 0
var completed_ids: Dictionary = {}
var substep_done: Dictionary = {} # objective_id -> Array[bool]
var unlocked_glossary: Array[String] = []
var _tour_visited: Dictionary = {}

func _ready() -> void:
	objectives = MissionScript.get_objectives()
	_init_substeps_for(active_idx)

func start_new_campaign() -> void:
	active_idx = 0
	completed_ids.clear()
	substep_done.clear()
	unlocked_glossary.clear()
	_tour_visited.clear()
	GameState.reset_campaign_state()
	_init_substeps_for(0)
	if not objectives.is_empty():
		objective_started.emit(objectives[0])

func restore_from_save(idx: int, comp: Dictionary, glossary: Array[String], tour: Array = []) -> void:
	active_idx = clampi(idx, 0, objectives.size())
	completed_ids = comp.duplicate()
	unlocked_glossary = glossary.duplicate()
	_tour_visited.clear()
	for s in tour:
		var k: String = String(s)
		_tour_visited[k] = true
		var order := ["training", "vab", "mcc", "pad"]
		var si: int = order.find(k)
		if si >= 0 and active_idx < objectives.size() and String(objectives[active_idx].get("condition", "")) == "tour_4_signs":
			_init_substeps_for(active_idx)
			mark_substep(si)
	_init_substeps_for(active_idx)
	if active_idx < objectives.size():
		objective_started.emit(objectives[active_idx])

func get_tour_visited_list() -> Array[String]:
	var out: Array[String] = []
	for k in _tour_visited.keys():
		out.append(String(k))
	return out

func _init_substeps_for(idx: int) -> void:
	if idx < 0 or idx >= objectives.size():
		return
	var obj: Dictionary = objectives[idx]
	var oid: String = String(obj["id"])
	if not substep_done.has(oid):
		var arr: Array[bool] = []
		for _s in obj.get("substeps", []):
			arr.append(false)
		substep_done[oid] = arr

func get_current_objective() -> Dictionary:
	if active_idx >= 0 and active_idx < objectives.size():
		return objectives[active_idx]
	return {}

func get_substeps_status(obj_id: String) -> Array:
	return substep_done.get(obj_id, [])

func is_sign_visited(sign_name: String) -> bool:
	return _tour_visited.has(sign_name)

func get_visited_signs_count() -> int:
	return _tour_visited.size()

func mark_substep(substep_idx: int) -> void:
	var obj: Dictionary = get_current_objective()
	if obj.is_empty():
		return
	var oid: String = String(obj["id"])
	_init_substeps_for(active_idx)
	var arr: Array = substep_done[oid]
	if substep_idx >= 0 and substep_idx < arr.size() and not arr[substep_idx]:
		arr[substep_idx] = true
		substep_updated.emit(obj, substep_idx)

func notify_event(event_id: String) -> void:
	var obj: Dictionary = get_current_objective()
	if obj.is_empty():
		return
	var cond: String = String(obj.get("condition", ""))

	# Caso especial: recorrido por 4 carteles del campus
	if cond == "tour_4_signs" and event_id.begins_with("visit:"):
		var sign_name: String = event_id.substr(6)
		_tour_visited[sign_name] = true
		var order := ["training", "vab", "mcc", "pad"]
		var idx: int = order.find(sign_name)
		if idx >= 0:
			mark_substep(idx)
		if _tour_visited.size() >= 4:
			complete_current_objective()
		return

	# Caso especial: apilado múltiple en VAB (stack_part:a,b)
	if cond.begins_with("stack_part:") and event_id.begins_with("stack_part:"):
		var req_parts: PackedStringArray = cond.substr(11).split(",")
		var placed_part: String = event_id.substr(11)
		var p_idx: int = req_parts.find(placed_part)
		if p_idx >= 0:
			mark_substep(p_idx)
		var all_placed: bool = true
		for rp in req_parts:
			if not GameState.sls_stacked_parts.has(rp):
				all_placed = false
				break
		if all_placed:
			complete_current_objective()
		return

	if event_id == cond:
		complete_current_objective()

func complete_current_objective() -> void:
	var obj: Dictionary = get_current_objective()
	if obj.is_empty():
		return
	var oid: String = String(obj["id"])
	if completed_ids.has(oid):
		return

	completed_ids[oid] = true
	var arr: Array = substep_done.get(oid, [])
	for i in range(arr.size()):
		arr[i] = true

	var glos: String = String(obj.get("glossary_id", ""))
	if not glos.is_empty() and not unlocked_glossary.has(glos):
		unlocked_glossary.append(glos)

	var ach_id: String = String(obj.get("achievement", ""))
	if not ach_id.is_empty():
		AchievementManager.unlock(ach_id)

	var prev_chapter: int = int(obj["chapter"])
	objective_completed.emit(obj)

	active_idx += 1
	if active_idx < objectives.size():
		var next_obj: Dictionary = objectives[active_idx]
		var next_chapter: int = int(next_obj["chapter"])
		if next_chapter != prev_chapter:
			if not GameState.chapter_scores.has(str(prev_chapter)):
				GameState.set_chapter_score(prev_chapter, 100)
			chapter_completed.emit(prev_chapter)
		_init_substeps_for(active_idx)
		SaveSystem.save_progress()
		objective_started.emit(next_obj)
	else:
		GameState.set_chapter_score(prev_chapter, 100)
		chapter_completed.emit(prev_chapter)
		SaveSystem.save_progress()
		campaign_finished.emit()

func completed_count() -> int:
	return completed_ids.size()

func total_count() -> int:
	return objectives.size()
