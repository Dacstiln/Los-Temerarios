extends "res://scripts/monsters/monster.gd"
## La Bailarina (Noches 2-5). Vive dentro de la Cajita de Musica del Lobby (Cam 01).
## Mientras la caja suena, duerme. Si la musica se detiene, despierta; si pasa demasiado
## tiempo sin que le des cuerda -> jumpscare. No se mueve: solo exige ir a la Cam 01.
##
## Estados: DORMIDA -> DESPERTANDO (caja parada, cuenta atras) -> DORMIDA (al darle cuerda)

enum S { DORMIDA, DESPERTANDO }
const NAMES: Array = ["DORMIDA", "DESPERTANDO"]

var s: int = S.DORMIDA
var grace: float = 14.0
var wake: float = 0.0   # segundos acumulados con la caja parada


func _configure(cfg: Dictionary) -> void:
	key = "bailarina"
	display_name = "La Bailarina"
	counter_hint = "La Cajita de Música necesita cuerda: ve a la Cam 01 y pulsa CUERDA [R]. Si la música se apaga, la Bailarina despierta en pocos segundos."
	grace = float(cfg.get("grace", 14.0))
	location = -1
	_set_state(S.DORMIDA)


func _set_state(new_state: int) -> void:
	s = new_state
	state_name = NAMES[new_state]


## 0..1: que tan despierta esta (lo usa la camara 01 para dibujarla).
func awake_amount() -> float:
	return clampf(wake / grace, 0.0, 1.0)


func is_threatening() -> bool:
	return s == S.DESPERTANDO


func _tick(delta: float) -> void:
	if game.box_charge <= 0.0:
		if s == S.DORMIDA:
			_set_state(S.DESPERTANDO)
			game.sfx("creak", -4.0)
		wake += delta
		if wake >= grace:
			_trigger_jumpscare("fallo")
	else:
		# Con cuerda se vuelve a dormir rapido.
		wake = maxf(0.0, wake - delta * 3.0)
		if wake <= 0.0 and s == S.DESPERTANDO:
			_set_state(S.DORMIDA)


## En el apagon no actua: la caja deja de importar (los demas monstruos ya cobran).
func on_blackout() -> void:
	_blackout_timer = 9999.0


func _blackout_process(_delta: float) -> void:
	pass


func debug_text() -> String:
	return "%s: %s  (%.1f/%.1f s)" % [display_name, state_name, wake, grace]
