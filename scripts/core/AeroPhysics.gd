class_name AeroPhysics
extends RefCounted

## Motor de física aeroespacial para Cosmic Blueprint: Misión Artemis.
## Incluye Tsiolkovsky, TWR, Max-Q, retorno libre Tierra-Luna y corredor de reentrada.

const G0: float = 9.80665
const MU_EARTH: float = 3.986004418e14 # m^3/s^2
const R_EARTH_M: float = 6371000.0

static func tsiolkovsky_delta_v(isp_s: float, m0_kg: float, mf_kg: float) -> float:
	if isp_s <= 0.0 or m0_kg <= 0.0 or mf_kg <= 0.0 or m0_kg <= mf_kg:
		return 0.0
	return isp_s * G0 * log(m0_kg / mf_kg)

static func compute_twr(thrust_kn: float, total_mass_kg: float) -> float:
	if total_mass_kg <= 0.0:
		return 0.0
	return (thrust_kn * 1000.0) / (total_mass_kg * G0)

static func air_density_at_alt(alt_m: float) -> float:
	if alt_m < 0.0:
		alt_m = 0.0
	# Modelo exponencial simplificado (H = 8500 m)
	return 1.225 * exp(-alt_m / 8500.0)

static func dynamic_pressure_kpa(alt_m: float, velocity_ms: float) -> float:
	var rho: float = air_density_at_alt(alt_m)
	return 0.5 * rho * velocity_ms * velocity_ms / 1000.0

static func evaluate_sls_stack(part_ids: Array[String]) -> Dictionary:
	var total_mass: float = 0.0
	var liftoff_thrust_kn: float = 0.0
	for pid in part_ids:
		var p: Dictionary = CatalogData.get_sls_part_by_id(pid)
		if p.is_empty():
			continue
		total_mass += float(p["mass_kg"])
		if pid in ["srb_left", "srb_right", "core_stage"]:
			liftoff_thrust_kn += float(p["thrust_kn"])
	var twr: float = compute_twr(liftoff_thrust_kn, total_mass)
	return {
		"total_mass_kg": total_mass,
		"liftoff_thrust_kn": liftoff_thrust_kn,
		"twr": twr,
		"safe_liftoff": twr >= 1.2
	}

static func evaluate_free_return(periapsis_km: float, tli_dv_ms: float) -> Dictionary:
	# En Artemis II, TLI ~ 3100 m/s y periapsis lunar seguro ~ 100 a 9000 km (objetivo ~ 7400 km / sobrevuelo).
	var dv_err: float = absf(tli_dv_ms - 3100.0)
	var peri_ok: bool = periapsis_km >= 150.0 and periapsis_km <= 9500.0
	var dv_ok: bool = dv_err <= 80.0
	var return_angle_ok: bool = peri_ok and dv_ok
	var status: String = "RETORNO LIBRE NOMINAL"
	if periapsis_km < 150.0:
		status = "IMPACTO LUNAR INMINENTE"
	elif periapsis_km > 9500.0:
		status = "ÓRBITA PERDIDA (SIN CAPTURA DE RETORNO)"
	elif not dv_ok:
		status = "Δv TLI FUERA DE VENTANA (OBJETIVO ~3100 m/s)"
	return {
		"valid": return_angle_ok,
		"periapsis_km": periapsis_km,
		"tli_dv_ms": tli_dv_ms,
		"status": status
	}

static func evaluate_reentry_corridor(angle_deg: float) -> Dictionary:
	# Corredor seguro: -5.5° a -7.0°
	if angle_deg < -7.0:
		return {
			"zone": "STEEP",
			"safe": false,
			"heat_mult": 1.85,
			"g_load": 9.5,
			"message": "Ángulo muy empinado (< -7.0°): ¡sobrecalentamiento y sobrecarga G!"
		}
	elif angle_deg > -5.5:
		return {
			"zone": "SHALLOW",
			"safe": false,
			"heat_mult": 0.65,
			"g_load": 1.8,
			"message": "Ángulo muy plano (> -5.5°): ¡rebote atmosférico hacia el espacio!"
		}
	else:
		var perfect: bool = absf(angle_deg - (-6.25)) <= 0.20
		return {
			"zone": "NOMINAL",
			"safe": true,
			"perfect": perfect,
			"heat_mult": 1.0,
			"g_load": 4.2,
			"message": "Corredor de reentrada nominal (-5.5° a -7.0°)."
		}
