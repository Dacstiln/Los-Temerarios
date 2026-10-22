extends Node
## Autoload: progreso, noche actual y resultado de la ultima partida.

const Balance = preload("res://scripts/balance.gd")
const SAVE_PATH: String = "user://save.cfg"
const MAX_NIGHT: int = 5   # MVP = noches 1-3; 4-5 incluyen a Cornelius

var current_night: int = 1
var unlocked_night: int = 1
var last_result: Dictionary = {}

# --- configuracion (se guarda en save.cfg) ---
var master_volume: float = 0.8     # 0.0 - 1.0
var fullscreen: bool = false
var crt_enabled: bool = true       # efecto de monitor viejo (ruido, curvatura)


func _ready() -> void:
	load_progress()
	apply_settings()


## Aplica volumen y pantalla completa. Se llama al iniciar y al cambiar la configuracion.
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## "Nuevo juego": borra el progreso (vuelve a la Noche 1).
func reset_progress() -> void:
	unlocked_night = 1
	save_progress()


func start_night(n: int) -> void:
	current_night = clampi(n, 1, MAX_NIGHT)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/night.tscn")


func night_config(n: int = -1) -> Dictionary:
	if n < 0:
		n = current_night
	return Balance.NIGHTS[n]


func win_night() -> void:
	if current_night >= unlocked_night and current_night < MAX_NIGHT:
		unlocked_night = current_night + 1
	save_progress()


func save_progress() -> void:
	var cf := ConfigFile.new()
	cf.set_value("progress", "unlocked_night", unlocked_night)
	cf.set_value("settings", "master_volume", master_volume)
	cf.set_value("settings", "fullscreen", fullscreen)
	cf.set_value("settings", "crt_enabled", crt_enabled)
	cf.save(SAVE_PATH)


func load_progress() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		unlocked_night = clampi(int(cf.get_value("progress", "unlocked_night", 1)), 1, MAX_NIGHT)
		master_volume = clampf(float(cf.get_value("settings", "master_volume", 0.8)), 0.0, 1.0)
		fullscreen = bool(cf.get_value("settings", "fullscreen", false))
		crt_enabled = bool(cf.get_value("settings", "crt_enabled", true))
