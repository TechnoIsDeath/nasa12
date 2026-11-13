extends Node

## Gestor de logros estilo Minecraft (Normal, Meta dorada y Desafío).

signal achievement_unlocked(ach_data: Dictionary)

var achievements: Array[Dictionary] = []
var unlocked: Dictionary = {} # id -> unix_time

func _ready() -> void:
	achievements = MissionScript.get_achievements()

func reset() -> void:
	unlocked.clear()

func restore(unlocked_dict: Dictionary) -> void:
	unlocked = unlocked_dict.duplicate()

func unlock(ach_id: String) -> void:
	if ach_id.is_empty() or unlocked.has(ach_id):
		return
	var data: Dictionary = get_achievement(ach_id)
	if data.is_empty():
		return
	unlocked[ach_id] = int(Time.get_unix_time_from_system())
	achievement_unlocked.emit(data)

func is_unlocked(ach_id: String) -> bool:
	return unlocked.has(ach_id)

func is_available(ach_id: String) -> bool:
	if is_unlocked(ach_id):
		return true
	var data: Dictionary = get_achievement(ach_id)
	var parent_id: String = String(data.get("parent", ""))
	if parent_id.is_empty():
		return true
	return is_unlocked(parent_id)

func get_achievement(ach_id: String) -> Dictionary:
	for a in achievements:
		if a["id"] == ach_id:
			return a
	return {}

func get_by_tab(tab_name: String) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for a in achievements:
		if a["tab"] == tab_name:
			res.append(a)
	return res

func get_tabs() -> Array[String]:
	return ["Tierra", "Entrenamiento", "VAB", "Hardware", "Software", "Vuelo", "Luna", "Regreso"]

func get_progress_pct() -> float:
	if achievements.is_empty():
		return 0.0
	return (float(unlocked.size()) / float(achievements.size())) * 100.0
