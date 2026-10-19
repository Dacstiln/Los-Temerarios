extends Node
## Autoload: progreso, noche actual y resultado de la ultima partida.

const Balance = preload("res://scripts/balance.gd")
const SAVE_PATH: String = "user://save.cfg"
const MAX_NIGHT: int = 5   # MVP = noches 1-3; 4-5 incluyen a Cornelius

var current_night: int = 1
var unlocked_night: int = 1
var last_result: Dictionary = {}


func _ready() -> void:
	load_progress()


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
	cf.save(SAVE_PATH)


func load_progress() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		unlocked_night = clampi(int(cf.get_value("progress", "unlocked_night", 1)), 1, MAX_NIGHT)
