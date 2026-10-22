extends "res://scripts/monsters/monster.gd"
## El Botones (Amenaza 1). Lento pero acelera si no se le vigila -> exige monitoreo
## constante de Cam 01. Se detiene con las Rejas de Ascensor.
##
## Estados (GDD Pagina 4):
## Lejos (Cam 01) -> Acercandose (Cam 02 / 04-05) -> En la oficina (ventana de reaccion)
##   -> [reja cerrada] Bloqueado -> (espera) -> Retirado -> Lejos
##   -> [reja abierta y vence la ventana] Jumpscare

const Map = preload("res://scripts/map.gd")

enum S { LEJOS, ACERCANDOSE, EN_PUERTA, BLOQUEADO, RETIRADO }
const NAMES: Array = ["LEJOS", "ACERCÁNDOSE", "EN LA OFICINA", "BLOQUEADO", "RETIRADO"]

var s: int = S.LEJOS
var side: String = ""
var interval: float = 12.0
var window: float = 6.0
var block_wait: float = 6.0
var progress: float = 0.0
var unwatched: float = 0.0
var timer: float = 0.0


func _configure(cfg: Dictionary) -> void:
	key = "botones"
	display_name = "El Botones"
	counter_hint = "El Botones solo se detiene con las Rejas de Ascensor (A / D) y avanza más rápido si no vigilas la Cam 01."
	interval = float(cfg.get("interval", 12.0))
	window = float(cfg.get("window", 6.0))
	block_wait = float(cfg.get("block_wait", 6.0))
	_reset()


func _reset() -> void:
	location = 1
	side = ""
	progress = 0.0
	unwatched = 0.0
	timer = 0.0
	_set_state(S.LEJOS)


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
		1: return Vector2(-0.35, 0.55)
		2: return Vector2(0.2, 0.5)
		4, 5: return Vector2(0.0, 0.4)
	return Vector2(0.0, 0.5)


func _tick(delta: float) -> void:
	match s:
		S.LEJOS, S.ACERCANDOSE:
			_advance(delta)
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
				# Abriste demasiado pronto: vuelve a la puerta con poco margen.
				_set_state(S.EN_PUERTA)
				timer = 2.0
			else:
				timer -= delta
				if timer <= 0.0:
					_set_state(S.RETIRADO)
					timer = 2.5
					side = ""
		S.RETIRADO:
			timer -= delta
			if timer <= 0.0:
				_reset()


func _advance(delta: float) -> void:
	var watched: bool = game.can_see(location)
	if watched:
		unwatched = maxf(0.0, unwatched - delta * 2.0)
	else:
		unwatched += delta
	var rate: float = 0.4
	if not watched:
		rate = 1.0 + minf(unwatched / 25.0, 1.5)
	progress += delta * rate * game.risk_mult()
	if progress >= interval:
		progress = 0.0
		_step()


func _step() -> void:
	game.sfx("footstep", -12.0)
	if location == 1:
		location = 2
		_set_state(S.ACERCANDOSE)
	elif location == 2:
		side = "left" if randf() < 0.5 else "right"
		location = Map.DOOR_CAM[side]
	else:
		location = -1
		timer = window
		_set_state(S.EN_PUERTA)
		game.sfx("arrive", -2.0)
