extends Node

## Singleton global para Cosmic Blueprint: Misión Artemis (un solo rol).
## Gestiona fase de vuelo, zona actual, telemetría de Orion/SLS, registro de errores y recibo final.

signal phase_changed(new_phase: int)
signal zone_changed(new_zone: String)
signal telemetry_updated()
signal error_recorded(err: Dictionary)
signal log_message_added(msg: String)

var current_phase: int = CatalogData.FlightPhase.PRELAUNCH
var current_zone: String = "HOME"
var mission_time_sec: float = 0.0
var comms_log: Array[String] = []
var errors_log: Array[Dictionary] = []
var chapter_scores: Dictionary = {}
var sls_stacked_parts: Array[String] = []

var telemetry: Dictionary = {
	"altitude_km": 0.0,
	"velocity_ms": 0.0,
	"downrange_km": 0.0,
	"max_q_kpa": 0.0,
	"twr": 1.54,
	"delta_v_left": 3150.0,
	"fuel_pct": 100.0,
	"o2_pct": 21.0,
	"co2_pct": 0.04,
	"power_w": 11000.0,
	"dsn_station": "Goldstone",
	"signal_delay_s": 0.0,
	"los_active": false,
	"entry_angle_deg": -6.2,
	"heat_shield_temp_c": 22.0,
	"chutes_drogue": false,
	"chutes_main": false
}

var last_receipt: Dictionary = {}

func _ready() -> void:
	add_log("[ARTEMIS II] Sistema de Misión inicializado (Modo Un Solo Rol).")

func reset_campaign_state() -> void:
	current_phase = CatalogData.FlightPhase.PRELAUNCH
	current_zone = "HOME"
	mission_time_sec = 0.0
	comms_log.clear()
	errors_log.clear()
	chapter_scores.clear()
	sls_stacked_parts.clear()
	last_receipt.clear()
	telemetry["altitude_km"] = 0.0
	telemetry["velocity_ms"] = 0.0
	telemetry["downrange_km"] = 0.0
	telemetry["max_q_kpa"] = 0.0
	telemetry["twr"] = 1.54
	telemetry["delta_v_left"] = 3150.0
	telemetry["fuel_pct"] = 100.0
	telemetry["o2_pct"] = 21.0
	telemetry["co2_pct"] = 0.04
	telemetry["power_w"] = 11000.0
	telemetry["dsn_station"] = "Goldstone"
	telemetry["signal_delay_s"] = 0.0
	telemetry["los_active"] = false
	telemetry["entry_angle_deg"] = -6.2
	telemetry["heat_shield_temp_c"] = 22.0
	telemetry["chutes_drogue"] = false
	telemetry["chutes_main"] = false
	telemetry_updated.emit()

func set_phase(new_phase: int) -> void:
	if current_phase == new_phase:
		return
	current_phase = new_phase
	add_log("[FASE] %s" % CatalogData.PHASE_NAMES.get(new_phase, "DESCONOCIDA"))
	phase_changed.emit(new_phase)

func set_zone(new_zone: String) -> void:
	if current_zone == new_zone:
		return
	current_zone = new_zone
	add_log("[ZONA] Traslado a: %s" % new_zone)
	zone_changed.emit(new_zone)

func record_error(chapter: int, challenge_id: String, msg: String, physics_exp: String) -> void:
	var err := {
		"chapter": chapter,
		"challenge_id": challenge_id,
		"message": msg,
		"physics_explanation": physics_exp,
		"time_sec": mission_time_sec
	}
	errors_log.append(err)
	add_log("[ERROR CAP.%d] %s" % [chapter, msg])
	error_recorded.emit(err)

func set_chapter_score(chapter: int, score: int) -> void:
	chapter_scores[str(chapter)] = clampi(score, 0, 100)

func add_log(msg: String) -> void:
	comms_log.append(msg)
	if comms_log.size() > 80:
		comms_log.remove_at(0)
	log_message_added.emit(msg)

func generate_debrief_receipt() -> Dictionary:
	var total_score: int = 0
	var count: int = 0
	for ch in range(0, 12):
		var s: int = int(chapter_scores.get(str(ch), 100))
		total_score += s
		count += 1
	var avg: float = float(total_score) / maxf(float(count), 1.0)
	var penalty: float = float(errors_log.size()) * 2.5
	var final_score: float = clampf(avg - penalty, 0.0, 100.0)
	var grade: String = "F"
	if final_score >= 92.0:
		grade = "S"
	elif final_score >= 82.0:
		grade = "A"
	elif final_score >= 70.0:
		grade = "B"
	elif final_score >= 55.0:
		grade = "C"
	elif final_score >= 40.0:
		grade = "D"

	var ach_pct: float = AchievementManager.get_progress_pct() if AchievementManager else 0.0
	last_receipt = {
		"mission": "ARTEMIS II — RETORNO LIBRE LUNAR",
		"grade": grade,
		"score": int(round(final_score)),
		"errors_count": errors_log.size(),
		"errors": errors_log.duplicate(),
		"chapter_scores": chapter_scores.duplicate(),
		"achievement_pct": ach_pct,
		"duration_sec": mission_time_sec
	}
	return last_receipt
