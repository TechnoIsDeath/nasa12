class_name MissionScript
extends RefCounted

## Guion completo de la campaña "Cosmic Blueprint: Misión Artemis" (12 capítulos, 45 retos)
## y definición del árbol de logros estilo Minecraft.

static func get_objectives() -> Array[Dictionary]:
	return [
		# --- CAPÍTULO 0: CASA (TUTORIAL) ---
		{
			"id": "home_wake_up",
			"chapter": 0,
			"title": "Despertar del Astronauta",
			"briefing": "Hoy comienza tu asignación a Artemis II. Familiarízate con tus controles de movimiento en tu dormitorio.",
			"science": "Orientación espacial y propiocepción humana en 1g.",
			"fact": "La tripulación de Artemis II realiza cuarentena previa de 14 días antes del lanzamiento.",
			"target": "Home/RoomCenter",
			"condition": "woke_up",
			"substeps": ["Moverte (WASD)", "Mirar alrededor (Ratón)", "Saltar (Espacio)"],
			"achievement": "ach_awake",
			"glossary_id": ""
		},
		{
			"id": "home_badge",
			"chapter": 0,
			"title": "Credencial NASA",
			"briefing": "Encuentra y recoge tu credencial de acceso de la NASA sobre el escritorio.",
			"science": "Protocolos de seguridad aeroespacial (interacción con objetos [E]).",
			"fact": "El Centro Espacial Kennedy (KSC) abarca más de 580 km² de zona restringida.",
			"target": "Home/DeskBadge",
			"condition": "badge_taken",
			"substeps": ["Acercarte al escritorio", "Recoger la credencial con [E]"],
			"achievement": "ach_badge",
			"glossary_id": ""
		},
		{
			"id": "home_email",
			"chapter": 0,
			"title": "Correo de Asignación",
			"briefing": "Revisa tu ordenador portátil para leer el correo oficial de asignación a la misión Artemis II.",
			"science": "Perfil de misión: trayectoria de retorno libre alrededor de la Luna.",
			"fact": "Artemis II será la primera misión tripulada en la historia en usar la nave Orion y el cohete SLS.",
			"target": "Home/Laptop",
			"condition": "read_email",
			"substeps": ["Interactuar con el portátil [E]", "Confirmar lectura del briefing"],
			"achievement": "ach_assigned",
			"glossary_id": ""
		},
		{
			"id": "home_depart",
			"chapter": 0,
			"title": "Rumbo al Centro Espacial",
			"briefing": "Sal de tu casa siguiendo la baliza luminosa hasta el vehículo de transporte rumbo al campus de la NASA.",
			"science": "Navegación por puntos de referencia (waypoints).",
			"fact": "Los astronautas se trasladan al complejo de lanzamiento en vehículos Astrovan eléctricos.",
			"target": "Home/VehicleGate",
			"condition": "depart_home",
			"substeps": ["Salir por la puerta principal", "Subir al vehículo con [E]"],
			"achievement": "ach_ch0_complete",
			"glossary_id": ""
		},

		# --- CAPÍTULO 1: LLEGADA AL CAMPUS NASA ---
		{
			"id": "campus_security",
			"chapter": 1,
			"title": "Control de Seguridad",
			"briefing": "Has llegado a la entrada del complejo espacial. Muestra tu credencial en la garita de seguridad.",
			"science": "Control de acceso a instalaciones de lanzamiento orbital.",
			"fact": "La puerta del KSC está custodiada las 24 h por seguridad federal de la NASA.",
			"target": "Campus/SecurityGate",
			"condition": "show_badge",
			"substeps": ["Acercarte a la garita", "Presentar credencial con [E]"],
			"achievement": "ach_clearance",
			"glossary_id": ""
		},
		{
			"id": "campus_tour",
			"chapter": 1,
			"title": "Recorrido de Orientación",
			"briefing": "Visita los 4 carteles informativos del campus (Entrenamiento, VAB, Control de Misión y Plataforma 39B) para desbloquear el mapa completo.",
			"science": "Logística de integración vertical y operaciones de tierra.",
			"fact": "El VAB mide 160 m de alto: uno de los edificios de un solo piso más grandes del mundo.",
			"target": "Campus/Signs",
			"condition": "tour_4_signs",
			"substeps": ["Visitar Entrenamiento", "Visitar VAB", "Visitar Control de Misión", "Visitar Plataforma 39B"],
			"achievement": "ach_explorer",
			"glossary_id": ""
		},
		{
			"id": "campus_briefing",
			"chapter": 1,
			"title": "Sala de Briefing Artemis II",
			"briefing": "Accede a la terminal de briefing para revisar los parámetros reales de Artemis II (~10 días, 4 tripulantes, sobrevuelo lunar).",
			"science": "Arquitectura general de vuelo cislunar (~384,400 km de distancia).",
			"fact": "La tripulación viajará más lejos de la Tierra que ningún ser humano en la historia (~400,000+ km).",
			"target": "Campus/BriefingTerminal",
			"condition": "briefing_done",
			"substeps": ["Abrir terminal de briefing [E]", "Completar lectura de perfil"],
			"achievement": "ach_ch1_complete",
			"glossary_id": ""
		},

		# --- CAPÍTULO 2: ENTRENAMIENTO DE ASTRONAUTA ---
		{
			"id": "train_centrifuge",
			"chapter": 2,
			"title": "Prueba en Centrífuga (3g → 5g)",
			"briefing": "Mantén la consciencia bajo aceleración creciente regulando tu respiración en el minijuego de ritmo.",
			"science": "a = F / m  |  G = a / 9.81 m/s²",
			"fact": "Durante el ascenso del SLS y la reentrada, la tripulación experimenta hasta ~4g.",
			"target": "Training/Centrifuge",
			"condition": "centrifuge_passed",
			"substeps": ["Subir a la centrífuga [E]", "Superar fase 3g y fase 5g sin desmayo"],
			"achievement": "ach_g_force",
			"glossary_id": "g_force"
		},
		{
			"id": "train_vacuum_ocss",
			"chapter": 2,
			"title": "Cámara de Vacío y Traje OCSS",
			"briefing": "Verifica sellos del casco, presurización y flujo de O₂ del traje Orion Crew Survival System en el orden correcto.",
			"science": "P · V = n · R · T  (Ley de los gases ideales)",
			"fact": "El traje naranja OCSS puede mantener con vida a la tripulación hasta 6 días en caso de despresurización.",
			"target": "Training/VacuumChamber",
			"condition": "ocss_checked",
			"substeps": ["Comprobar sellos", "Presurizar a 30 kPa", "Verificar flujo de O₂"],
			"achievement": "ach_suited_up",
			"glossary_id": "gas_law"
		},
		{
			"id": "train_newton",
			"chapter": 2,
			"title": "Laboratorio de las 3 Leyes de Newton",
			"briefing": "Empuja cajas de distintas masas y responde 3 preguntas interactivas sobre inercia, F=m·a y acción-reacción.",
			"science": "F = m · a   |   F₁₂ = -F₂₁",
			"fact": "En microgravedad, un objeto de 100 kg sigue teniendo la misma inercia que en la Tierra.",
			"target": "Training/NewtonLab",
			"condition": "newton_quiz_passed",
			"substeps": ["Probar masas físicas", "Superar 3 preguntas de Newton"],
			"achievement": "ach_ch2_complete",
			"glossary_id": "newton_laws"
		},

		# --- CAPÍTULO 3: VAB — ENSAMBLAJE DEL SLS ---
		{
			"id": "vab_stack_srbs",
			"chapter": 3,
			"title": "Cimientos de Fuego: Propulsores SRB",
			"briefing": "Usa la grúa puente para colocar los 2 propulsores sólidos (SRB) de 5 segmentos sobre el Lanzador Móvil.",
			"science": "Empuje sólido combinado: 32,000 kN (~75 % del empuje inicial).",
			"fact": "Cada SRB quema ~5 toneladas de propelente sólido por segundo durante 126 segundos.",
			"target": "VAB/MobileLauncher",
			"condition": "stack_part:srb_left,srb_right",
			"substeps": ["Apilar SRB Izquierdo", "Apilar SRB Derecho"],
			"achievement": "ach_srb_stacked",
			"glossary_id": "twr"
		},
		{
			"id": "vab_stack_core",
			"chapter": 3,
			"title": "Etapa Central y 4× RS-25",
			"briefing": "Acopla la etapa central criogénica (LH₂/LOX) con sus cuatro motores RS-25 entre los dos SRB.",
			"science": "Isp ≈ 452 s en vacío con hidrógeno y oxígeno líquidos.",
			"fact": "Los motores RS-25 del SLS son versiones mejoradas de los motores principales del Transbordador Espacial.",
			"target": "VAB/MobileLauncher",
			"condition": "stack_part:core_stage",
			"substeps": ["Alinear y bajar Etapa Central"],
			"achievement": "ach_core_stacked",
			"glossary_id": "twr"
		},
		{
			"id": "vab_stack_icps",
			"chapter": 3,
			"title": "Adaptador LVSA y Etapa ICPS",
			"briefing": "Coloca el adaptador de etapa de vehículo de lanzamiento (LVSA) y la etapa superior criogénica ICPS (motor RL10).",
			"science": "Propulsión de alta eficiencia en vacío (Isp = 465 s).",
			"fact": "La ICPS eleva el apogeo de Orion en órbita terrestre alta antes de separarse.",
			"target": "VAB/MobileLauncher",
			"condition": "stack_part:lvsa_icps",
			"substeps": ["Apilar LVSA + ICPS"],
			"achievement": "ach_icps_stacked",
			"glossary_id": ""
		},
		{
			"id": "vab_stack_esm_orion",
			"chapter": 3,
			"title": "Módulo de Servicio Europeo y Orion",
			"briefing": "Instala el Adaptador de Orion, el Módulo de Servicio Europeo (ESM) y el Módulo de Tripulación Orion.",
			"science": "Centro de masas y simetría axial del vehículo integrado.",
			"fact": "El ESM aporta 33 motores, paneles solares de 19 m de envergadura y agua/aire para 4 astronautas.",
			"target": "VAB/MobileLauncher",
			"condition": "stack_part:msa_esm,orion_cm",
			"substeps": ["Apilar ESM", "Apilar Cápsula Orion"],
			"achievement": "ach_orion_stacked",
			"glossary_id": ""
		},
		{
			"id": "vab_stack_las_twr",
			"chapter": 3,
			"title": "Torre de Escape (LAS) y Cálculo de TWR",
			"briefing": "Corona el cohete con la Torre de Escape (LAS), conecta umbilicales y verifica que el TWR al despegue sea > 1.2.",
			"science": "TWR = Empuje / (m · g₀)  > 1.2",
			"fact": "El cohete SLS Block 1 completo mide 98 metros de altura y pesa ~2,600 toneladas al despegar.",
			"target": "VAB/MobileLauncher",
			"condition": "vab_complete_twr",
			"substeps": ["Apilar Torre de Escape (LAS)", "Conectar umbilicales", "Verificar TWR > 1.2"],
			"achievement": "ach_ch3_complete",
			"glossary_id": "twr"
		},

		# --- CAPÍTULO 4: HARDWARE DE ORION ---
		{
			"id": "hw_power_buses",
			"chapter": 4,
			"title": "Buses de Energía del ESM",
			"briefing": "Resuelve el puzle de cableado uniendo paneles solares del ESM, baterías y cargas sin superar el límite de potencia.",
			"science": "P = V · I  (Balance energético positivo)",
			"fact": "Los 4 paneles solares de Orion generan ~11.2 kW en órbita lunar.",
			"target": "VAB/HardwareBench",
			"condition": "hw_power_done",
			"substeps": ["Conectar paneles y baterías", "Equilibrar cargas sin sobrecarga"],
			"achievement": "ach_power_ok",
			"glossary_id": "power_balance"
		},
		{
			"id": "hw_eclss",
			"chapter": 4,
			"title": "Soporte Vital (ECLSS)",
			"briefing": "Instala los lechos de amina regenerables para capturar CO₂ y equilibra la mezcla O₂/N₂ al 21 % / 79 %.",
			"science": "Captación química de CO₂ + control de presión parcial de O₂.",
			"fact": "En Apolo 13, los ingenieros adaptaron filtros cuadrados de hidróxido de litio en tomas redondas.",
			"target": "VAB/HardwareBench",
			"condition": "hw_eclss_done",
			"substeps": ["Instalar filtros de amina", "Estabilizar O₂/N₂"],
			"achievement": "ach_eclss_ok",
			"glossary_id": "eclss"
		},
		{
			"id": "hw_heat_shield",
			"chapter": 4,
			"title": "Inspección del Escudo Térmico Avcoat",
			"briefing": "Inspecciona los bloques del escudo térmico de Orion y marca los defectuosos antes del vuelo.",
			"science": "Ablación térmica a ~2,760 °C (Q ∝ ½ ρ v³).",
			"fact": "El escudo de Orion mide 5 m de diámetro y es el mayor escudo ablativo jamás construido.",
			"target": "VAB/HardwareBench",
			"condition": "hw_shield_done",
			"substeps": ["Detectar bloques dañados", "Aprobar reemplazo Avcoat"],
			"achievement": "ach_shield_ok",
			"glossary_id": "ablative_shield"
		},
		{
			"id": "hw_antennas",
			"chapter": 4,
			"title": "Antenas en Banda S y Radio",
			"briefing": "Instala y alinea las antenas en banda S y banda Ka de Orion para comunicaciones de espacio profundo.",
			"science": "Ganancia direccional y frecuencia portadora (2.2 GHz Banda S).",
			"fact": "La antena de alta ganancia permite transmitir vídeo HD desde la órbita lunar.",
			"target": "VAB/HardwareBench",
			"condition": "hw_antennas_done",
			"substeps": ["Montar antena Banda S", "Calibrar ganancia"],
			"achievement": "ach_ch4_complete",
			"glossary_id": "dsn_delay"
		},

		# --- CAPÍTULO 5: SOFTWARE DE VUELO ---
		{
			"id": "sw_gls_sequence",
			"chapter": 5,
			"title": "Secuencia de Cuenta Atrás (GLS)",
			"briefing": "Ordena correctamente los comandos críticos del Secuenciador de Lanzamiento Terrestre desde T-10 min hasta T-0.",
			"science": "Automatización determinista en milisegundos (T-6.6 s encendido RS-25).",
			"fact": "Los RS-25 se encienden 6.6 s antes del despegue para comprobar su empuje antes de soltar los SRB.",
			"target": "MCC/SoftwareConsole",
			"condition": "sw_gls_done",
			"substeps": ["Ordenar comandos GLS en secuencia"],
			"achievement": "ach_gls_ok",
			"glossary_id": ""
		},
		{
			"id": "sw_debug_units",
			"chapter": 5,
			"title": "Depurar el Guiado (Bug de Unidades)",
			"briefing": "Encuentra y corrige el error en el pseudocódigo de guiado que mezcla unidades imperiales con el Sistema Internacional.",
			"science": "1 lbf·s = 4.44822 N·s  (Consistencia dimensional).",
			"fact": "En 1999, Mars Climate Orbiter se destruyó en Marte por mezclar lbf·s y N·s entre dos módulos de software.",
			"target": "MCC/SoftwareConsole",
			"condition": "sw_debug_done",
			"substeps": ["Identificar línea con lbf·s", "Convertir a N·s (SI)"],
			"achievement": "ach_bug_squashed",
			"glossary_id": "units_bug"
		},
		{
			"id": "sw_redundancy",
			"chapter": 5,
			"title": "Votación de Computadoras Redundantes",
			"briefing": "Configura el esquema de votación por mayoría (TMR) entre las 3 computadoras de vuelo de Orion ante un fallo inyectado.",
			"science": "Tolerancia a fallos mediante Redundancia Modular Triple.",
			"fact": "Orion usa computadoras tolerantes a radiación con canales redundantes independientes.",
			"target": "MCC/SoftwareConsole",
			"condition": "sw_redundancy_done",
			"substeps": ["Aislar canal corrupto", "Validar consenso 2 de 3"],
			"achievement": "ach_fault_tolerant",
			"glossary_id": ""
		},
		{
			"id": "sw_telemetry",
			"chapter": 5,
			"title": "Mapeo de Canales de Telemetría",
			"briefing": "Asocia cada sensor crítico (presión de cámara, O₂ cabina, temperatura escudo) con su canal de telemetría.",
			"science": "Multiplexación y diagnóstico remoto en tiempo real.",
			"fact": "Durante el lanzamiento, el SLS transmite miles de parámetros por segundo al Control de Lanzamiento.",
			"target": "MCC/SoftwareConsole",
			"condition": "sw_telemetry_done",
			"substeps": ["Enlazar sensores a canales"],
			"achievement": "ach_ch5_complete",
			"glossary_id": ""
		},

		# --- CAPÍTULO 6: DISEÑO DE TRAYECTORIA (SALA FIDO) ---
		{
			"id": "fido_window",
			"chapter": 6,
			"title": "Ventana de Lanzamiento Lunar",
			"briefing": "Elige la fecha/hora de lanzamiento en la que la posición relativa Tierra–Luna permite el retorno libre.",
			"science": "Mecánica de fases orbitales: la Luna avanza ~13.2° por día.",
			"fact": "Las ventanas de lanzamiento lunares suelen durar entre 1 y 2 horas en días específicos del mes.",
			"target": "MCC/FidoConsole",
			"condition": "fido_window_done",
			"substeps": ["Seleccionar ventana óptima Tierra-Luna"],
			"achievement": "ach_window_ok",
			"glossary_id": "free_return"
		},
		{
			"id": "fido_tsiolkovsky",
			"chapter": 6,
			"title": "Ecuación del Cohete (Δv)",
			"briefing": "Calcula el Δv disponible con Tsiolkovsky y verifica que alcanza los ~3.1 km/s necesarios para la Inyección Translunar.",
			"science": "Δv = Isp · g₀ · ln(m₀ / m_f)",
			"fact": "Para escapar de la órbita terrestre hacia la Luna se necesitan ~3,100 m/s de Δv adicional desde LEO/HEO.",
			"target": "MCC/FidoConsole",
			"condition": "fido_dv_done",
			"substeps": ["Calcular Δv disponible", "Confirmar Δv ≥ 3.1 km/s"],
			"achievement": "ach_tsiolkovsky",
			"glossary_id": "tsiolkovsky"
		},
		{
			"id": "fido_free_return",
			"chapter": 6,
			"title": "Ajuste de Retorno Libre 2D",
			"briefing": "Ajusta el periapsis lunar en el mapa 2D para que la gravedad de la Luna devuelva a Orion a la Tierra sin quemar motor.",
			"science": "Trayectoria en figura de 8 con asistencia gravitatoria natural.",
			"fact": "Artemis II usa una órbita de retorno libre para garantizar la vuelta segura incluso si falla el motor del ESM.",
			"target": "MCC/FidoConsole",
			"condition": "fido_return_done",
			"substeps": ["Ajustar periapsis lunar", "Validar retorno a la Tierra"],
			"achievement": "ach_ch6_complete",
			"glossary_id": "free_return"
		},

		# --- CAPÍTULO 7: LANZAMIENTO (MOCR) ---
		{
			"id": "launch_gonogo",
			"chapter": 7,
			"title": "Poll GO / NO-GO en Consola",
			"briefing": "Recorre las estaciones del MOCR y resuelve el NO-GO detectado en el sensor de hidrógeno líquido antes de dar luz verde.",
			"science": "Criterios de compromiso de lanzamiento (LCC) y seguridad criogénica.",
			"fact": "El director de lanzamiento pregunta a cada estación ('FLIGHT, GUIDO, FIDO, EECOM...') antes de T-0.",
			"target": "MCC/FlightConsole",
			"condition": "launch_gonogo_done",
			"substeps": ["Revisar estaciones", "Resolver anomalía LH₂", "Emitir GO final"],
			"achievement": "ach_all_go",
			"glossary_id": ""
		},
		{
			"id": "launch_ascent",
			"chapter": 7,
			"title": "Ignición y Ascenso (Max-Q, SRB, MECO)",
			"briefing": "Supervisa el despegue del SLS: controla el paso por Max-Q, la separación de los SRB (~2 min) y el corte de motores centrales (MECO ~8 min).",
			"science": "q = ½ · ρ · v²  (Max-Q)  |  Masa decreciente → aceleración creciente.",
			"fact": "Al acercarse a MECO, el cohete acelera hasta ~28,000 km/h para alcanzar órbita.",
			"target": "MCC/FlightConsole",
			"condition": "launch_ascent_done",
			"substeps": ["Superar Max-Q", "Separar SRB", "Confirmar MECO y separación de Etapa Central"],
			"achievement": "ach_ch7_complete",
			"glossary_id": "max_q"
		},

		# --- CAPÍTULO 8: ÓRBITA TERRESTRE ALTA (HEO) ---
		{
			"id": "heo_perigee_raise",
			"chapter": 8,
			"title": "Elevación del Perigeo (ICPS)",
			"briefing": "Ejecuta el encendido del motor RL10 de la etapa ICPS en el apogeo para elevar el perigeo de forma segura.",
			"science": "Efecto Oberth y maniobra en apogeo para circularizar/elevar perigeo.",
			"fact": "Artemis II pasa ~24 horas en órbita terrestre alta verificando todos sus sistemas antes de ir a la Luna.",
			"target": "MCC/FlightConsole",
			"condition": "heo_perigee_done",
			"substeps": ["Esperar ventana en apogeo", "Ejecutar quemado ICPS"],
			"achievement": "ach_perigee_ok",
			"glossary_id": ""
		},
		{
			"id": "heo_proximity_ops",
			"chapter": 8,
			"title": "Demostración de Proximidad con RCS",
			"briefing": "Pilota Orion manualmente con propulsores RCS para acercarte a la etapa ICPS separada sin colisionar.",
			"science": "Mecánica orbital contraintuitiva: acelerar eleva la órbita y reduce la velocidad angular.",
			"fact": "Esta maniobra real de Artemis II prueba el pilotaje manual de Orion para futuras misiones Artemis III.",
			"target": "MCC/FlightConsole",
			"condition": "heo_prox_done",
			"substeps": ["Aproximarse a < 15 m", "Mantener velocidad relativa segura"],
			"achievement": "ach_rendezvous",
			"glossary_id": "orbital_rendezvous"
		},
		{
			"id": "heo_sys_check",
			"chapter": 8,
			"title": "Chequeo de Sistemas Pre-TLI",
			"briefing": "Verifica soporte vital, energía y propulsión del ESM antes de comprometer a la tripulación al viaje lunar.",
			"science": "Punto de no retorno parcial: confirmación de integridad de cabina.",
			"fact": "Si algún sistema crítico fallara en HEO, Orion podría regresar a la Tierra en pocas horas.",
			"target": "MCC/FlightConsole",
			"condition": "heo_check_done",
			"substeps": ["Validar O₂, Potencia y Propulsión"],
			"achievement": "ach_ch8_complete",
			"glossary_id": ""
		},

		# --- CAPÍTULO 9: TLI Y CRUCERO ---
		{
			"id": "tli_burn",
			"chapter": 9,
			"title": "Inyección Translunar (TLI)",
			"briefing": "Enciende el motor principal del ESM y corta exactamente al alcanzar el Δv objetivo de ~3.1 km/s.",
			"science": "Velocidad de escape parcial (~10.9 km/s respecto a la Tierra).",
			"fact": "El quemado TLI dura varios minutos y lanza a Orion en un viaje de ~4 días hacia la Luna.",
			"target": "MCC/FlightConsole",
			"condition": "tli_burn_done",
			"substeps": ["Iniciar quemado TLI", "Cortar motor en Δv objetivo"],
			"achievement": "ach_tli_burn",
			"glossary_id": "tsiolkovsky"
		},
		{
			"id": "cruise_dsn",
			"chapter": 9,
			"title": "Red de Espacio Profundo (DSN)",
			"briefing": "Transfiere el enlace de radio entre Goldstone, Madrid y Canberra conforme rota la Tierra.",
			"science": "Retardo de señal t = d / c (~1.3 s hasta la Luna) y cobertura global a 120°.",
			"fact": "Las antenas parabólicas de 70 m de la DSN captan señales miles de millones de veces más débiles que un móvil.",
			"target": "MCC/FlightConsole",
			"condition": "cruise_dsn_done",
			"substeps": ["Realizar handover Goldstone → Madrid → Canberra"],
			"achievement": "ach_dsn_link",
			"glossary_id": "dsn_delay"
		},
		{
			"id": "cruise_tcm",
			"chapter": 9,
			"title": "Correcciones de Trayectoria (TCM)",
			"briefing": "Ejecuta pequeños impulsos RCS de corrección intermedia para mantener el corredor lunar exacto.",
			"science": "Sensibilidad de trayectorias cislunares: 1 m/s de error hoy son cientos de km en la Luna.",
			"fact": "Se programan varias maniobras TCM durante el crucero de ida.",
			"target": "MCC/FlightConsole",
			"condition": "cruise_tcm_done",
			"substeps": ["Ajustar vector Δv de corrección"],
			"achievement": "ach_tcm_ok",
			"glossary_id": ""
		},
		{
			"id": "cruise_solar_storm",
			"chapter": 9,
			"title": "Crisis: Tormenta Solar",
			"briefing": "Una eyección de masa coronal se aproxima: ordena refugiar a la tripulación tras las bolsas de agua/provisiones y apaga sistemas no críticos.",
			"science": "Blindaje contra protones solares usando materiales ricos en hidrógeno (agua).",
			"fact": "Orion cuenta con un refugio de radiación improvisable en el suelo de la cabina.",
			"target": "MCC/FlightConsole",
			"condition": "cruise_storm_done",
			"substeps": ["Activar refugio de radiación", "Apagar cargas no críticas"],
			"achievement": "ach_ch9_complete",
			"glossary_id": ""
		},

		# --- CAPÍTULO 10: SOBREVUELO LUNAR ---
		{
			"id": "flyby_los",
			"chapter": 10,
			"title": "Pérdida de Señal (Cara Oculta)",
			"briefing": "Al pasar por detrás de la Luna se pierde todo contacto con la Tierra (LOS). Opera de forma autónoma hasta recuperar señal.",
			"science": "Ocultación electromagnética por masa planetaria (~45 min sin enlace).",
			"fact": "Durante el paso por la cara oculta, ninguna señal de radio puede atravesar los 3,474 km de roca lunar.",
			"target": "MCC/FlightConsole",
			"condition": "flyby_los_done",
			"substeps": ["Mantener actitud autónoma en LOS", "Recuperar señal (AOS)"],
			"achievement": "ach_far_side",
			"glossary_id": "dsn_delay"
		},
		{
			"id": "flyby_science",
			"chapter": 10,
			"title": "Fotografía de Regiones Lunares",
			"briefing": "Captura imágenes de los cráteres y mares lunares objetivo en el instante de máxima aproximación.",
			"science": "Teledetección óptica y reconocimiento geológico de futuros sitios de aterrizaje.",
			"fact": "La tripulación inspeccionará visualmente cráteres de impacto nunca vistos tan de cerca en 50 años.",
			"target": "MCC/FlightConsole",
			"condition": "flyby_science_done",
			"substeps": ["Fotografiar 3 objetivos lunares"],
			"achievement": "ach_lunar_photo",
			"glossary_id": ""
		},
		{
			"id": "flyby_gravity_assist",
			"chapter": 10,
			"title": "Asistencia Gravitatoria de Retorno",
			"briefing": "Observa y confirma cómo la gravedad lunar curva la trayectoria de Orion de vuelta hacia la Tierra sin gasto de propelente.",
			"science": "Conservación del momento angular y trayectoria de retorno libre.",
			"fact": "La Luna actúa como un 'tirachinas' gravitacional que redirige a Orion directo al Pacífico.",
			"target": "MCC/FlightConsole",
			"condition": "flyby_gravity_done",
			"substeps": ["Confirmar curva de retorno hacia Tierra"],
			"achievement": "ach_ch10_complete",
			"glossary_id": "free_return"
		},

		# --- CAPÍTULO 11: REENTRADA Y AMERIZAJE ---
		{
			"id": "reentry_sep",
			"chapter": 11,
			"title": "Separación del ESM y Orientación",
			"briefing": "Separa el Módulo de Servicio Europeo antes de tocar la atmósfera y orienta el escudo térmico Avcoat hacia adelante.",
			"science": "Centro de gravedad desplazado para generar sustentación aerodinámica.",
			"fact": "El ESM se desintegra en la atmósfera superior mientras Orion entra protegida por su escudo.",
			"target": "MCC/FlightConsole",
			"condition": "reentry_sep_done",
			"substeps": ["Separar ESM", "Orientar escudo térmico a 0° ataque"],
			"achievement": "ach_esm_sep",
			"glossary_id": "ablative_shield"
		},
		{
			"id": "reentry_corridor",
			"chapter": 11,
			"title": "Corredor de Reentrada (-5.5° a -7.0°)",
			"briefing": "Mantén el ángulo de entrada dentro del corredor seguro a ~11 km/s para evitar sobrecalentamiento o rebote espacial.",
			"science": "Corredor seguro: -5.5° a -7.0°  |  Skip entry (~2,760 °C).",
			"fact": "Artemis usa 'skip entry': entra, rebota ligeramente para disipar energía y vuelve a descender con precisión.",
			"target": "MCC/FlightConsole",
			"condition": "reentry_corridor_done",
			"substeps": ["Mantener ángulo entre -5.5° y -7.0° durante el pico térmico"],
			"achievement": "ach_skip_entry",
			"glossary_id": "skip_reentry"
		},
		{
			"id": "reentry_chutes",
			"chapter": 11,
			"title": "Despliegue de Paracaídas",
			"briefing": "Despliega los paracaídas estabilizadores (drogues) a ~7.6 km y los 3 paracaídas principales a ~2.9 km.",
			"science": "Fuerza de arrastre aerodinámico para reducir velocidad de ~480 km/h a ~32 km/h.",
			"fact": "En total, Orion despliega 11 paracaídas en una secuencia pirotécnica cronometrada.",
			"target": "MCC/FlightConsole",
			"condition": "reentry_chutes_done",
			"substeps": ["Desplegar drogues (< 8 km)", "Desplegar principales (< 3 km)"],
			"achievement": "ach_chutes_ok",
			"glossary_id": ""
		},
		{
			"id": "reentry_splashdown",
			"chapter": 11,
			"title": "Amerizaje y Recuperación",
			"briefing": "Confirma el amerizaje en el Océano Pacífico y coordina el equipo de recuperación naval.",
			"science": "Amortiguación hidrodinámica y flotabilidad de la cápsula.",
			"fact": "La Marina de EE. UU. recupera la cápsula Orion con un buque dique anfibio frente a San Diego.",
			"target": "MCC/FlightConsole",
			"condition": "reentry_splash_done",
			"substeps": ["Confirmar amerizaje en el Pacífico"],
			"achievement": "ach_ch11_complete",
			"glossary_id": ""
		},

		# --- CAPÍTULO 12: DEBRIEF ---
		{
			"id": "debrief_receipt",
			"chapter": 12,
			"title": "Debrief y Recibo de Misión",
			"briefing": "Revisa tu recibo matricial con la calificación por capítulo, explicación física de errores y porcentaje de logros.",
			"science": "Evaluación post-vuelo e ingeniería de lecciones aprendidas.",
			"fact": "¡Misión Artemis II completada con éxito!",
			"target": "MCC/Debrief",
			"condition": "debrief_viewed",
			"substeps": ["Revisar informe final"],
			"achievement": "ach_artemis_legend",
			"glossary_id": ""
		}
	]

static func get_achievements() -> Array[Dictionary]:
	# Árbol de logros estilo Minecraft con pestañas de capítulo y tipos: normal, goal (dorado), challenge (morado/desafío)
	return [
		{"id": "ach_awake", "tab": "Tierra", "title": "Primeros Pasos", "desc": "Despierta y domina el movimiento básico.", "type": "normal", "parent": ""},
		{"id": "ach_badge", "tab": "Tierra", "title": "Identificación Oficial", "desc": "Recoge tu credencial de la NASA.", "type": "normal", "parent": "ach_awake"},
		{"id": "ach_assigned", "tab": "Tierra", "title": "Llamado Lunar", "desc": "Lee el correo de asignación a Artemis II.", "type": "normal", "parent": "ach_badge"},
		{"id": "ach_ch0_complete", "tab": "Tierra", "title": "Camino al Cabo", "desc": "Sal de casa rumbo al complejo espacial.", "type": "goal", "parent": "ach_assigned"},
		{"id": "ach_clearance", "tab": "Tierra", "title": "Acceso Autorizado", "desc": "Supera el control de seguridad del KSC.", "type": "normal", "parent": "ach_ch0_complete"},
		{"id": "ach_explorer", "tab": "Tierra", "title": "Orientación Completa", "desc": "Visita los 4 edificios clave del campus.", "type": "normal", "parent": "ach_clearance"},
		{"id": "ach_ch1_complete", "tab": "Tierra", "title": "Listo para Entrenar", "desc": "Completa el briefing de Artemis II.", "type": "goal", "parent": "ach_explorer"},

		{"id": "ach_g_force", "tab": "Entrenamiento", "title": "Corazón de Acero", "desc": "Supera 5g en la centrífuga sin perder la consciencia.", "type": "normal", "parent": "ach_ch1_complete"},
		{"id": "ach_suited_up", "tab": "Entrenamiento", "title": "Traje Naranja Listo", "desc": "Verifica el traje OCSS en la cámara de vacío.", "type": "normal", "parent": "ach_g_force"},
		{"id": "ach_ch2_complete", "tab": "Entrenamiento", "title": "Discípulo de Newton", "desc": "Supera el entrenamiento físico y teórico.", "type": "goal", "parent": "ach_suited_up"},

		{"id": "ach_srb_stacked", "tab": "VAB", "title": "Cimientos de Fuego", "desc": "Apila ambos SRB de 5 segmentos.", "type": "normal", "parent": "ach_ch2_complete"},
		{"id": "ach_core_stacked", "tab": "VAB", "title": "Corazón Criogénico", "desc": "Coloca la etapa central con 4× RS-25.", "type": "normal", "parent": "ach_srb_stacked"},
		{"id": "ach_icps_stacked", "tab": "VAB", "title": "Impulso Interino", "desc": "Acopla el adaptador LVSA y la etapa ICPS.", "type": "normal", "parent": "ach_core_stacked"},
		{"id": "ach_orion_stacked", "tab": "VAB", "title": "Hogar en el Espacio", "desc": "Instala el ESM y la cápsula Orion.", "type": "normal", "parent": "ach_icps_stacked"},
		{"id": "ach_ch3_complete", "tab": "VAB", "title": "Arquitecto del SLS", "desc": "Completa el cohete con LAS y TWR > 1.2.", "type": "goal", "parent": "ach_orion_stacked"},

		{"id": "ach_power_ok", "tab": "Hardware", "title": "Maestro de Vatios", "desc": "Equilibra los buses eléctricos de Orion.", "type": "normal", "parent": "ach_ch3_complete"},
		{"id": "ach_eclss_ok", "tab": "Hardware", "title": "Aire Puro", "desc": "Instala filtros de CO₂ y regula el O₂.", "type": "normal", "parent": "ach_power_ok"},
		{"id": "ach_shield_ok", "tab": "Hardware", "title": "A Prueba de Plasma", "desc": "Inspecciona el escudo térmico Avcoat.", "type": "normal", "parent": "ach_eclss_ok"},
		{"id": "ach_ch4_complete", "tab": "Hardware", "title": "Orion Certificado", "desc": "Todo el hardware de Orion listo para volar.", "type": "goal", "parent": "ach_shield_ok"},

		{"id": "ach_gls_ok", "tab": "Software", "title": "Cuenta Atrás Perfecta", "desc": "Ordena la secuencia GLS de lanzamiento.", "type": "normal", "parent": "ach_ch4_complete"},
		{"id": "ach_bug_squashed", "tab": "Software", "title": "Cero Unidades Mixtas", "desc": "Corrige el bug estilo Mars Climate Orbiter.", "type": "challenge", "parent": "ach_gls_ok"},
		{"id": "ach_fault_tolerant", "tab": "Software", "title": "Votación 2 de 3", "desc": "Supera un fallo de computadora por redundancia.", "type": "normal", "parent": "ach_bug_squashed"},
		{"id": "ach_ch5_complete", "tab": "Software", "title": "Código de Vuelo Limpio", "desc": "Completa la verificación de software.", "type": "goal", "parent": "ach_fault_tolerant"},

		{"id": "ach_window_ok", "tab": "Vuelo", "title": "Alineación Lunar", "desc": "Encuentra la ventana de lanzamiento.", "type": "normal", "parent": "ach_ch5_complete"},
		{"id": "ach_tsiolkovsky", "tab": "Vuelo", "title": "Hijo de Tsiolkovsky", "desc": "Calcula el Δv necesario para TLI.", "type": "normal", "parent": "ach_window_ok"},
		{"id": "ach_ch6_complete", "tab": "Vuelo", "title": "Boleto de Ida y Vuelta", "desc": "Diseña la trayectoria de retorno libre.", "type": "goal", "parent": "ach_tsiolkovsky"},
		{"id": "ach_all_go", "tab": "Vuelo", "title": "Todos GO para Lanzamiento", "desc": "Resuelve el NO-GO y completa el poll MOCR.", "type": "normal", "parent": "ach_ch6_complete"},
		{"id": "ach_ch7_complete", "tab": "Vuelo", "title": "¡Tenemos Despegue!", "desc": "Supera Max-Q, SRB sep y MECO.", "type": "goal", "parent": "ach_all_go"},
		{"id": "ach_perigee_ok", "tab": "Vuelo", "title": "Órbita Estabilizada", "desc": "Eleva el perigeo con el motor RL10.", "type": "normal", "parent": "ach_ch7_complete"},
		{"id": "ach_rendezvous", "tab": "Vuelo", "title": "Baile Orbital", "desc": "Completa operaciones de proximidad con RCS.", "type": "challenge", "parent": "ach_perigee_ok"},
		{"id": "ach_ch8_complete", "tab": "Vuelo", "title": "Listos para la Luna", "desc": "Completa los chequeos en HEO.", "type": "goal", "parent": "ach_rendezvous"},

		{"id": "ach_tli_burn", "tab": "Luna", "title": "Rumbo a Selene", "desc": "Ejecuta el quemado TLI con precisión.", "type": "normal", "parent": "ach_ch8_complete"},
		{"id": "ach_dsn_link", "tab": "Luna", "title": "Tres Continentes", "desc": "Realiza el relevo entre Goldstone, Madrid y Canberra.", "type": "normal", "parent": "ach_tli_burn"},
		{"id": "ach_tcm_ok", "tab": "Luna", "title": "Puntería Cósmica", "desc": "Corrige el rumbo en espacio profundo.", "type": "normal", "parent": "ach_dsn_link"},
		{"id": "ach_ch9_complete", "tab": "Luna", "title": "Superviviente Solar", "desc": "Protege a la tripulación de la tormenta solar.", "type": "goal", "parent": "ach_tcm_ok"},
		{"id": "ach_far_side", "tab": "Luna", "title": "Silencio de Radio", "desc": "Opera de forma autónoma en la cara oculta.", "type": "normal", "parent": "ach_ch9_complete"},
		{"id": "ach_lunar_photo", "tab": "Luna", "title": "Ojos en la Luna", "desc": "Fotografía los objetivos científicos lunares.", "type": "normal", "parent": "ach_far_side"},
		{"id": "ach_ch10_complete", "tab": "Luna", "title": "Honda Gravitacional", "desc": "Completa el sobrevuelo lunar de retorno libre.", "type": "goal", "parent": "ach_lunar_photo"},

		{"id": "ach_esm_sep", "tab": "Regreso", "title": "Último Adiós al ESM", "desc": "Separa el módulo de servicio antes de reentrar.", "type": "normal", "parent": "ach_ch10_complete"},
		{"id": "ach_skip_entry", "tab": "Regreso", "title": "Surfista del Plasma", "desc": "Mantén el corredor de entrada (-5.5° a -7.0°).", "type": "normal", "parent": "ach_esm_sep"},
		{"id": "ach_perfect_reentry", "tab": "Regreso", "title": "Reentrada Perfecta (±0.2°)", "desc": "Desafío: clava el ángulo central de reentrada.", "type": "challenge", "parent": "ach_skip_entry"},
		{"id": "ach_chutes_ok", "tab": "Regreso", "title": "Once Seda y Nylon", "desc": "Despliega drogues y paracaídas principales.", "type": "normal", "parent": "ach_skip_entry"},
		{"id": "ach_ch11_complete", "tab": "Regreso", "title": "¡Bienvenidos a Casa!", "desc": "Ameriza sano y salvo en el Pacífico.", "type": "goal", "parent": "ach_chutes_ok"},
		{"id": "ach_artemis_legend", "tab": "Regreso", "title": "Leyenda Artemis", "desc": "Completa toda la campaña y revisa tu recibo.", "type": "goal", "parent": "ach_ch11_complete"}
	]
