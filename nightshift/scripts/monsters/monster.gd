extends Node
## Base de todos los monstruos. Cada uno es una maquina de estados discreta cuyas
## transiciones dependen de un input del jugador y un temporizador (GDD Pagina 4):
## sin IA compleja.

signal jumpscare(monster, reason)

var game = null                 # controlador de la noche (night.gd)
var key: String = ""
var display_name: String = "?"
var counter_hint: String = ""   # que contramedida lo detiene (se muestra al perder)
var active: bool = false
var location: int = -1          # id de camara donde esta (-1 = en la puerta / ninguna)
var state_name: String = ""
var _blackout_timer: float = -1.0


func setup(g, cfg: Dictionary) -> void:
	game = g
	_configure(cfg)


# ---- a sobrescribir ----
func _configure(_cfg: Dictionary) -> void:
	pass


func _tick(_delta: float) -> void:
	pass


## True si esta en estado "Acercandose" / "En la oficina" (relevante para el Apagon).
func is_threatening() -> bool:
	return false


## "left" / "right" si esta visible tras una reja de la oficina; "" si no.
func at_gate_side() -> String:
	return ""


## Respuesta al Sobrecargo de Caldera. Devuelve true si tuvo efecto.
func on_boiler() -> bool:
	return false


## Posicion en pantalla dentro de su camara: x en [-1,1], profundidad en [0,1].
func cam_pos() -> Vector2:
	return Vector2(0.0, 0.5)


func debug_text() -> String:
	return "%s: %s" % [display_name, state_name]


# ---- comun ----
func _process(delta: float) -> void:
	if not active or game == null or game.is_over:
		return
	if game.blackout:
		_blackout_process(delta)
	else:
		_tick(delta)


## Apagon: "Jumpscare garantizado en el siguiente ciclo de patrulla" (GDD Pagina 4).
func on_blackout() -> void:
	if is_threatening():
		_blackout_timer = randf_range(1.5, 3.0)
	else:
		_blackout_timer = randf_range(4.5, 8.0)


func _blackout_process(delta: float) -> void:
	if _blackout_timer < 0.0:
		on_blackout()
	_blackout_timer -= delta
	if _blackout_timer <= 0.0:
		_trigger_jumpscare("apagon")


func _trigger_jumpscare(reason: String) -> void:
	active = false
	jumpscare.emit(self, reason)
