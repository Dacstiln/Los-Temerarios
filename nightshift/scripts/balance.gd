extends RefCounted
## Todos los numeros de balance en un solo lugar.
## GDD Riesgo #3: ajustar tasas de consumo en incrementos de 10% tras playtesting.

# Duracion real de una noche (12:00 AM -> 6:00 AM). Ajustable.
const NIGHT_DURATION: float = 360.0

# --- Consumo de energia (Anexo B del GDD). Unidades: % de bateria ---
const DRAIN_IDLE: float = 0.02          # generador / oficina (siempre)
const DRAIN_MONITOR: float = 0.045      # "Camaras abiertas (pasivo): Bajo" (por segundo)
const DRAIN_GATE_PER_SEC: float = 0.15  # "Reja cerrada (por segundo): Alto"
const COST_BOILER: float = 2.0          # "Sobrecargo de Caldera (por uso): Medio-Alto"
const COST_FLASH: float = 0.7           # "Flash de Camara (por uso): Medio"
const COST_INTERCOM: float = 1.2        # "Intercomunicador activo: Medio"

# Flash: "Alto si se abusa" -> cada uso reciente encarece el siguiente.
const FLASH_DURATION: float = 1.0
const FLASH_COOLDOWN: float = 1.2
const FLASH_ABUSE_STEP: float = 0.25
const FLASH_ABUSE_DECAY: float = 5.0    # segundos para "olvidar" un uso

const INTERCOM_DURATION: float = 12.0   # la cancion del Chef dura 12 s
const BOILER_COOLDOWN: float = 3.0

# Cornelius (Noches 4-5): una camara interferida atora las rejas abiertas unos segundos
# y acelera a los demas monstruos ("incrementa el riesgo acumulado", GDD Pagina 4).
const GATE_JAM_TIME: float = 3.0
const COST_SHORT_CIRCUIT: float = 1.5   # un corto circuito drena el generador aunque lo evites a tiempo
const RISK_PER_BLIND_CAM: float = 0.08

# --- Cajita de musica (Noches 2-5): se le da cuerda desde la Cam 01 ---
const BOX_CAM: int = 1
const COST_WIND: float = 0.5            # % de energia por darle cuerda
const BOX_EMPTY_RISK: float = 0.5       # con la caja parada, los monstruos avanzan 50% mas rapido

# --- Descuido: si pasas demasiado tiempo sin subir el monitor, los monstruos se vuelven audaces ---
const UNWATCHED_THRESHOLD: float = 18.0 # segundos sin mirar las camaras
const UNWATCHED_RISK: float = 0.25      # +25% de velocidad, y el Chef elige la reja abierta

# --- Modo depuracion (F1-F4 en la noche). false = oculto del todo (version final) ---
const DEBUG_KEYS: bool = false

# --- Parametros por noche (MVP: mismo sistema, solo cambian parametros) ---
# drain: multiplicador de consumo (Noche 1 = -30%, Noche 3 = tasa base 100%, segun GDD Pagina 6).
const NIGHTS: Dictionary = {
	1: {
		"title": "NOCHE 1",
		"subtitle": "Solo el Botones",
		"hint": "Cierra la reja del lado por donde aparezca el Botones.\nA / D = rejas   |   ESPACIO = monitor",
		"drain": 0.7,
		"intercom": false,
		"boiler": false,
		"botones": {"interval": 14.0, "window": 7.0, "block_wait": 6.0},
	},
	2: {
		"title": "NOCHE 2",
		"subtitle": "Botones + Chef",
		"hint": "El Chef reacciona al ruido: aleja su atención con el Intercomunicador [I].\nDale cuerda a la Cajita de Música en la Cam 01 [R] antes de que se detenga.",
		"drain": 0.85,
		"intercom": true,
		"boiler": false,
		"box": {"charge": 50.0, "grace": 14.0},
		"botones": {"interval": 12.0, "window": 6.0, "block_wait": 6.0},
		"chef": {"interval": 13.0, "window": 5.5, "lure_step": 3.5, "return_step": 4.5, "block_wait": 6.0},
	},
	3: {
		"title": "NOCHE 3",
		"subtitle": "Botones + Chef + Mucama",
		"hint": "La Mucama viene por los ductos (Cam 07). Las rejas no sirven: usa el Sobrecargo de Caldera [B].",
		"drain": 1.0,
		"intercom": true,
		"boiler": true,
		"box": {"charge": 46.0, "grace": 13.0},
		"botones": {"interval": 11.0, "window": 5.5, "block_wait": 6.0},
		"chef": {"interval": 11.5, "window": 5.0, "lure_step": 3.5, "return_step": 4.5, "block_wait": 6.0},
		"mucama": {"idle_min": 20.0, "idle_max": 32.0, "approach": 12.0, "window": 4.5},
	},
	# --- Noches 4-5: contenido posterior al MVP (GDD Pagina 7: Cornelius y Noche 5) ---
	4: {
		"title": "NOCHE 4",
		"subtitle": "Botones + Chef + Mucama + Cornelius",
		"hint": "Cornelius se oculta en las cámaras oscuras. Si oyes el reloj de bolsillo, baja el monitor [ESPACIO] antes de 3 segundos.\nEl Flash [F] sobre su cámara lo expulsa.",
		"drain": 0.95,   # ajuste de playtesting: hay mas amenazas que gestionar
		"intercom": true,
		"boiler": true,
		"box": {"charge": 42.0, "grace": 12.0},
		"botones": {"interval": 10.5, "window": 5.2, "block_wait": 6.0},
		"chef": {"interval": 11.0, "window": 4.8, "lure_step": 3.5, "return_step": 4.5, "block_wait": 6.0},
		"mucama": {"idle_min": 18.0, "idle_max": 30.0, "approach": 11.0, "window": 4.4},
		"cornelius": {"idle_min": 22.0, "idle_max": 32.0, "hide_min": 9.0, "hide_max": 14.0, "react": 3.0, "lockout": 4.0},
	},
	5: {
		"title": "NOCHE 5",
		"subtitle": "Todo se vuelve más rápido",
		"hint": "La última noche. Todos se mueven más rápido y Cornelius reacciona antes.\nCuando amanezca, cobras tu sueldo.",
		"drain": 0.92,
		"intercom": true,
		"boiler": true,
		"box": {"charge": 38.0, "grace": 11.0},
		"botones": {"interval": 9.0, "window": 4.6, "block_wait": 6.0},
		"chef": {"interval": 9.5, "window": 4.2, "lure_step": 3.0, "return_step": 4.0, "block_wait": 6.0},
		"mucama": {"idle_min": 17.0, "idle_max": 27.0, "approach": 10.0, "window": 4.0},
		"cornelius": {"idle_min": 17.0, "idle_max": 25.0, "hide_min": 7.0, "hide_max": 11.0, "react": 2.6, "lockout": 5.0},
	},
}
