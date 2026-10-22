extends "res://scripts/monsters/monster.gd"
## El Chef (Amenaza 3). Agresivo y sensible al ruido -> exige el Intercomunicador como
## señuelo (jazz en una camara). Tambien lo detienen las Rejas de Ascensor.
##
## Estados: En cocina -> Acercandose -> En la oficina -> [reja] Bloqueado.
## El señuelo (intercomunicador) tiene prioridad: Atraido -> Regresando -> En cocina.

const Map = preload("res://scripts/map.gd")

enum S { EN_COCINA, ACERCANDOSE, ATRAIDO, REGRESANDO, EN_PUERTA, BLOQUEADO }
const NAMES: Array = ["EN COCINA", "ACERCÁNDOSE", "ATRAÍDO POR EL JAZZ", "REGRESANDO", "EN LA OFICINA", "BLOQUEADO"]

var s: int = S.EN_COCINA
var side: String = ""
var interval: float = 12.0
var window: float = 5.5
var lure_step: float = 3.5
var return_step: float = 4.5
var block_wait: float = 6.0
var progress: float = 0.0
var step_timer: float = 0.0
var timer: float = 0.0


func _configure(cfg: Dictionary) -> void:
	key = "chef"
	display_name = "El Chef"
	counter_hint = "El Chef se aleja con el Intercomunicador [I] (jazz en una cámara lejana a tu pasillo) o se bloquea con las Rejas."
	interval = float(cfg.get("interval", 12.0))
	window = float(cfg.get("window", 5.5))
	lure_step = float(cfg.get("lure_step", 3.5))
	return_step = float(cfg.get("return_step", 4.5))
	block_wait = float(cfg.get("block_wait", 6.0))
	location = 3
	_set_state(S.EN_COCINA)


func _set_state(new_state: int) -> void:
	s = new_state
	state_name = NAMES[new_state]


func is_threatening() -> bool:
	return s == S.ACERCANDOSE or s == S.EN_PUERTA or s == S.BLOQUEADO


func at_gate_side() -> String:
	if s == S.EN_PUERTA or s == S.BLOQUEADO:
		return side
	return ""


func cam_pos() -> Vector2:
	match location:
		1: return Vector2(0.3, 0.5)
		2: return Vector2(-0.2, 0.45)
		3: return Vector2(0.25, 0.5)
		4, 5: return Vector2(0.0, 0.4)
	return Vector2(0.0, 0.5)


func _tick(delta: float) -> void:
	var lure: int = game.intercom_cam

	# El señuelo de audio tiene prioridad sobre cualquier otro comportamiento.
	if lure > 0:
		if s == S.EN_PUERTA or s == S.BLOQUEADO:
			# Se da la vuelta hacia la musica y se aleja de la reja.
			location = Map.DOOR_CAM[side]
			side = ""
			_set_state(S.ATRAIDO)
			step_timer = 1.0
		elif s != S.ATRAIDO:
			_set_state(S.ATRAIDO)
			step_timer = lure_step * 0.6

	match s:
		S.EN_COCINA, S.ACERCANDOSE:
			_advance(delta)
		S.ATRAIDO:
			if lure <= 0:
				_set_state(S.REGRESANDO)
				step_timer = return_step
			else:
				step_timer -= delta
				if step_timer <= 0.0:
					step_timer = lure_step
					if location != lure:
						location = Map.next_step(location, lure)
						game.sfx("footstep", -14.0)
		S.REGRESANDO:
			step_timer -= delta
			if step_timer <= 0.0:
				step_timer = return_step
				location = Map.next_step(location, 3)
				game.sfx("footstep", -16.0)
				if location == 3:
					progress = 0.0
					_set_state(S.EN_COCINA)
		S.EN_PUERTA:
			if game.is_gate_closed(side):
				_set_state(S.BLOQUEADO)
				timer = block_wait
				game.sfx("clang", -6.0)
			else:
				timer -= delta
				if timer <= 0.0:
					_trigger_jumpscare("fallo")
		S.BLOQUEADO:
			if not game.is_gate_closed(side):
				_set_state(S.EN_PUERTA)
				timer = 2.0
			else:
				timer -= delta
				if timer <= 0.0:
					location = Map.DOOR_CAM[side]
					side = ""
					_set_state(S.REGRESANDO)
					step_timer = return_step


## Reja por la que llega. Normalmente 50/50; si llevas tiempo sin mirar las camaras,
## el Chef "huele" el hueco: elige la reja que esta abierta (y si ambas, al azar).
func _pick_side() -> String:
	if game.is_negligent():
		var l: bool = game.is_gate_closed("left")
		var r: bool = game.is_gate_closed("right")
		if l and not r:
			return "right"
		if r and not l:
			return "left"
	return "left" if randf() < 0.5 else "right"


func _advance(delta: float) -> void:
	progress += delta * game.risk_mult()
	if progress >= interval:
		progress = 0.0
		_step()


func _step() -> void:
	game.sfx("footstep", -10.0)
	if location == 3:
		location = 2
		_set_state(S.ACERCANDOSE)
	elif location == 2:
		side = _pick_side()
		location = Map.DOOR_CAM[side]
		game.sfx("clang", -10.0)
	elif location == 4 or location == 5:
		location = -1
		timer = window
		_set_state(S.EN_PUERTA)
		game.sfx("arrive", -2.0)
	else:
		# Estaba en otra camara (p. ej. tras el señuelo): vuelve a la ruta normal.
		location = Map.next_step(location, 2)
		_set_state(S.ACERCANDOSE)
