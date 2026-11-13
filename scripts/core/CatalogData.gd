class_name CatalogData
extends RefCounted

## Base de datos central de Cosmic Blueprint: Misión Artemis (campaña de un solo rol).
## Contiene las fases de vuelo, piezas reales del SLS Block 1 + Orion y glosario científico.

enum FlightPhase {
	PRELAUNCH = 0,
	LAUNCH = 1,
	HEO = 2,
	TLI = 3,
	CRUISE = 4,
	FLYBY = 5,
	REENTRY = 6,
	SPLASHDOWN = 7,
	DEBRIEF = 8
}

const PHASE_NAMES: Dictionary = {
	FlightPhase.PRELAUNCH: "PRE-LANZAMIENTO EN TIERRA",
	FlightPhase.LAUNCH: "ASCENSO SLS BLOCK 1",
	FlightPhase.HEO: "ÓRBITA TERRESTRE ALTA (HEO)",
	FlightPhase.TLI: "INYECCIÓN TRANSLUNAR (TLI)",
	FlightPhase.CRUISE: "CRUCERO ESPACIO PROFUNDO",
	FlightPhase.FLYBY: "SOBREVUELO CARA OCULTA LUNAR",
	FlightPhase.REENTRY: "REENTRADA ATMOSFÉRICA",
	FlightPhase.SPLASHDOWN: "AMERIZAJE Y RECUPERACIÓN",
	FlightPhase.DEBRIEF: "DEBRIEF Y RECIBO DE MISIÓN"
}

const CHAPTER_NAMES: Dictionary = {
	0: "Capítulo 0: Casa (Tutorial)",
	1: "Capítulo 1: Campus NASA",
	2: "Capítulo 2: Entrenamiento de Astronauta",
	3: "Capítulo 3: VAB — Ensamblaje del SLS",
	4: "Capítulo 4: Hardware de Orion",
	5: "Capítulo 5: Software de Vuelo",
	6: "Capítulo 6: Diseño de Trayectoria (FIDO)",
	7: "Capítulo 7: Lanzamiento (MOCR)",
	8: "Capítulo 8: Órbita Terrestre Alta",
	9: "Capítulo 9: Inyección Translunar y Crucero",
	10: "Capítulo 10: Sobrevuelo Lunar",
	11: "Capítulo 11: Reentrada y Amerizaje",
	12: "Capítulo 12: Debrief y Recibo"
}

## Piezas reales del cohete SLS Block 1 + Orion en orden de apilado en el VAB.
static func get_sls_parts() -> Array[Dictionary]:
	return [
		{
			"id": "srb_left",
			"order": 1,
			"name": "Propulsor Sólido Izquierdo (SRB)",
			"short": "SRB-L",
			"mass_kg": 725000.0,
			"dry_mass_kg": 99000.0,
			"thrust_kn": 16000.0,
			"isp_s": 269.0,
			"height_m": 54.0,
			"radius_m": 1.85,
			"color": Color(0.92, 0.92, 0.94),
			"desc": "Cohete sólido de 5 segmentos. Aporta ~37.5 % del empuje total al despegue."
		},
		{
			"id": "srb_right",
			"order": 2,
			"name": "Propulsor Sólido Derecho (SRB)",
			"short": "SRB-R",
			"mass_kg": 725000.0,
			"dry_mass_kg": 99000.0,
			"thrust_kn": 16000.0,
			"isp_s": 269.0,
			"height_m": 54.0,
			"radius_m": 1.85,
			"color": Color(0.92, 0.92, 0.94),
			"desc": "Gemelo derecho de 5 segmentos. Juntos queman ~10 t de propelente sólido por segundo."
		},
		{
			"id": "core_stage",
			"order": 3,
			"name": "Etapa Central + 4× RS-25",
			"short": "CORE",
			"mass_kg": 1072000.0,
			"dry_mass_kg": 85000.0,
			"thrust_kn": 7440.0,
			"isp_s": 452.0,
			"height_m": 64.6,
			"radius_m": 4.2,
			"color": Color(0.84, 0.43, 0.16),
			"desc": "Tanque naranja de LH₂/LOX con 4 motores criogénicos RS-25 heredados del Transbordador."
		},
		{
			"id": "lvsa_icps",
			"order": 4,
			"name": "Adaptador LVSA + Etapa ICPS (RL10)",
			"short": "ICPS",
			"mass_kg": 33000.0,
			"dry_mass_kg": 5200.0,
			"thrust_kn": 110.0,
			"isp_s": 465.0,
			"height_m": 13.7,
			"radius_m": 2.5,
			"color": Color(0.82, 0.84, 0.88),
			"desc": "Etapa de Propulsión Criogénica Interina con motor RL10 para elevar el apogeo en HEO."
		},
		{
			"id": "msa_esm",
			"order": 5,
			"name": "Adaptador + Módulo de Servicio Europeo (ESM)",
			"short": "ESM",
			"mass_kg": 15460.0,
			"dry_mass_kg": 6185.0,
			"thrust_kn": 26.7,
			"isp_s": 316.0,
			"height_m": 4.0,
			"radius_m": 2.5,
			"color": Color(0.24, 0.28, 0.36),
			"desc": "Construido por la ESA: provee propulsión principal (AJ10), energía solar, agua y O₂."
		},
		{
			"id": "orion_cm",
			"order": 6,
			"name": "Módulo de Tripulación Orion",
			"short": "ORION",
			"mass_kg": 10387.0,
			"dry_mass_kg": 9300.0,
			"thrust_kn": 0.0,
			"isp_s": 0.0,
			"height_m": 3.3,
			"radius_m": 2.5,
			"color": Color(0.88, 0.90, 0.94),
			"desc": "Cápsula habitable para 4 astronautas con escudo térmico ablativo Avcoat."
		},
		{
			"id": "las",
			"order": 7,
			"name": "Torre de Escape (LAS)",
			"short": "LAS",
			"mass_kg": 7300.0,
			"dry_mass_kg": 4200.0,
			"thrust_kn": 1780.0,
			"isp_s": 245.0,
			"height_m": 13.4,
			"radius_m": 0.9,
			"color": Color(0.95, 0.95, 0.96),
			"desc": "Sistema de aborto en lanzamiento capaz de alejar Orion del cohete en milisegundos."
		}
	]

static func get_sls_part_by_id(part_id: String) -> Dictionary:
	for p in get_sls_parts():
		if p["id"] == part_id:
			return p
	return {}

static func get_glossary_entries() -> Dictionary:
	return {
		"g_force": {
			"title": "Fuerza G y Aceleración",
			"formula": "a = F / m   |   G = a / 9.81 m/s²",
			"summary": "Un 'g' equivale a la gravedad terrestre. A 5 g tu sangre pesa 5 veces más; la maniobra de respiración anti-g evita el desmayo (G-LOC)."
		},
		"gas_law": {
			"title": "Ley de los Gases Ideales y Vacío",
			"formula": "P · V = n · R · T",
			"summary": "En el vacío espacial (P ≈ 0 Pa), la ebullición de líquidos corporales ocurre a 37 °C (límite de Armstrong a 19 km). El traje presurizado mantiene ~30 kPa de O₂ puro."
		},
		"newton_laws": {
			"title": "Leyes de Newton en el Espacio",
			"formula": "F = m · a   |   F₁₂ = -F₂₁",
			"summary": "1.ª: inercia sin rozamiento; 2.ª: mayor masa requiere más fuerza para acelerar; 3.ª: el cohete expulsa masa hacia atrás para impulsarse hacia adelante."
		},
		"twr": {
			"title": "Relación Empuje-Peso (TWR)",
			"formula": "TWR = Empuje / (m · g₀)",
			"summary": "Para despegar verticalmente, TWR debe ser > 1.0 (ideal ≥ 1.2). El SLS Block 1 despega con ~39,400 kN y ~2,600 t (TWR ≈ 1.54)."
		},
		"power_balance": {
			"title": "Balance Eléctrico (P = V · I)",
			"formula": "P = V · I   (Watts = Voltios × Amperios)",
			"summary": "Los 4 paneles solares en X del ESM generan ~11 kW a 1 UA. Si la demanda supera la generación, las baterías se agotan."
		},
		"eclss": {
			"title": "Soporte Vital (ECLSS)",
			"formula": "CO₂ + Amina → Carbamato (regenerable)",
			"summary": "Los astronautas exhalan ~1 kg de CO₂ al día. En Apolo 13 un adaptador improvisado salvó a la tripulación al conectar filtros incompatibles."
		},
		"ablative_shield": {
			"title": "Escudo Térmico Ablativo (Avcoat)",
			"formula": "Q_entrada ≈ ½ ρ v³",
			"summary": "Al reentrar desde la Luna a ~11 km/s, el aire se comprime en plasma a ~2,760 °C. El material Avcoat se carboniza y vaporiza llevándose el calor."
		},
		"units_bug": {
			"title": "Error de Unidades en Software",
			"formula": "1 lbf·s = 4.44822 N·s",
			"summary": "En 1999, la sonda Mars Climate Orbiter se perdió porque un módulo enviaba impulso en libras-fuerza·s y el navegador esperaba Newton·s."
		},
		"tsiolkovsky": {
			"title": "Ecuación del Cohete de Tsiolkovsky",
			"formula": "Δv = Isp · g₀ · ln(m₀ / m_f)",
			"summary": "Determina cuánta velocidad puede cambiar un cohete según su impulso específico (Isp) y la fracción de propelente quemado."
		},
		"max_q": {
			"title": "Presión Dinámica Máxima (Max-Q)",
			"formula": "q = ½ · ρ · v²",
			"summary": "Al ascender, la velocidad (v) sube pero la densidad del aire (ρ) baja. El pico estructural ocurre cerca de Mach 1–1.4 (~12 km de altitud)."
		},
		"orbital_rendezvous": {
			"title": "Mecánica Orbital Contraintuitiva",
			"formula": "v_orb = √(μ / r)",
			"summary": "Acelerar hacia adelante eleva el apogeo, haciendo la órbita más grande y el periodo MÁS LENTO. Para alcanzar a un objetivo delante, ¡frena ligeramente para bajar y girar más rápido!"
		},
		"dsn_delay": {
			"title": "Red de Espacio Profundo y Latencia",
			"formula": "t = d / c   (c ≈ 299,792 km/s)",
			"summary": "A 384,400 km, la luz tarda ~1.28 s por trayecto (~2.6 s ida y vuelta). Goldstone, Madrid y Canberra están separados ~120° para cobertura continua."
		},
		"free_return": {
			"title": "Trayectoria de Retorno Libre",
			"formula": "Asistencia gravitatoria lunar → retorno a Tierra",
			"summary": "Permite que la gravedad de la Luna curve la trayectoria de Orion de vuelta hacia el Pacífico sin necesidad de encender el motor principal."
		},
		"skip_reentry": {
			"title": "Corredor de Reentrada y Skip Entry",
			"formula": "Corredor seguro: -5.5° a -7.0°",
			"summary": "Más empinado de -7° genera fuerzas G y calor destructivos. Más plano de -5.5° hace que la cápsula rebote en la atmósfera hacia el espacio."
		}
	}
