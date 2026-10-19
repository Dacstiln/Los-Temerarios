extends Node
## Estado global de energia [0-100%] (GDD Pagina 4).
## Cada accion del jugador resta energia del mismo generador; a 0% -> Apagon (derrota).

signal depleted

const Balance = preload("res://scripts/balance.gd")

var energy: float = 100.0
var multiplier: float = 1.0
var drain_enabled: bool = false
var monitor_up: bool = false
var gate_closed: Dictionary = {"left": false, "right": false}
var _depleted: bool = false


func _process(delta: float) -> void:
	if _depleted or not drain_enabled:
		return
	_spend(current_rate() * multiplier * delta)


## Consumo continuo actual (% por segundo a tasa base, sin multiplicador de noche).
func current_rate() -> float:
	var rate: float = Balance.DRAIN_IDLE
	if monitor_up:
		rate += Balance.DRAIN_MONITOR
	for side in gate_closed.keys():
		if gate_closed[side]:
			rate += Balance.DRAIN_GATE_PER_SEC
	return rate


## Consumo puntual por uso (flash, intercomunicador, caldera).
func spend_use(cost: float) -> void:
	if _depleted:
		return
	_spend(cost * multiplier)


func refill() -> void:
	energy = 100.0
	_depleted = false


func _spend(amount: float) -> void:
	energy = maxf(0.0, energy - amount)
	if energy <= 0.0 and not _depleted:
		_depleted = true
		depleted.emit()
