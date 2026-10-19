extends "res://scripts/monsters/monster.gd"
## Cornelius Tenebris (Jefe final, Noche 4+). Desactiva camaras y abre puertas ->
## exige reaccion rapida a la mecanica de Interferencia.
##
## Estados (GDD Pagina 4):
## Inactivo -> (sonido de reloj de bolsillo) -> Corto circuito en curso
##   -> [el jugador baja el monitor en < 3 s] Resuelto
##   -> [no reacciona] Camara interferida: esa camara queda ciega el resto de la noche.
##      No es derrota inmediata, pero incrementa el riesgo acumulado (los demas
##      monstruos se aceleran) y atora las rejas abiertas unos segundos.
##
## Antes del corto circuito se OCULTA en una camara oscura (Pasillos / Calderas); el
## Flash de Camara sobre esa camara lo revela y lo expulsa ("revisar si Cornelius se oculta").

const Balance = preload("res://scripts/balance.gd")

enum S { INACTIVO, OCULTO, ACECHANDO, CORTO_CIRCUITO, REVELADO }
const NAMES: Array = ["INACTIVO", "OCULTO EN LA OSCURIDAD", "ACECHANDO", "CORTO CIRCUITO EN CURSO", "REVELADO"]
const DARK_CAMS: Array = [4, 5, 6]

var s: int = S.INACTIVO
var timer: float = 0.0
var idle_min: float = 18.0
var idle_max: float = 28.0
var hide_min: float = 9.0
var hide_max: float = 14.0
var react: float = 3.0
var lockout: float = 4.0   # el monitor se reinicia tras un corto circuito
var _glint: float = 0.0


func _configure(cfg: Dictionary) -> void:
	key = "cornelius"
	display_name = "Cornelius"
	counter_hint = "Cuando oigas el reloj de bolsillo, baja el monitor (ESPACIO) en menos de 3 segundos. El Flash [F] sobre las cámaras oscuras lo expulsa antes de que actúe."
	idle_min = float(cfg.get("idle_min", 18.0))
	idle_max = float(cfg.get("idle_max", 28.0))
	hide_min = float(cfg.get("hide_min", 9.0))
	hide_max = float(cfg.get("hide_max", 14.0))
	react = float(cfg.get("react", 3.0))
	lockout = float(cfg.get("lockout", 4.0))
	location = -1
	timer = randf_range(idle_min, idle_max)
	_set_state(S.INACTIVO)


func _set_state(new_state: int) -> void:
	s = new_state
	state_name = NAMES[new_state]


func cam_pos() -> Vector2:
	return Vector2(0.18, 0.42)


## Pista visual sutil: destello dorado intermitente en la camara oscura donde se oculta.
func glint_on(cam: int) -> bool:
	return (s == S.OCULTO or s == S.ACECHANDO) and location == cam and _glint > 0.0


func _tick(delta: float) -> void:
	_glint = maxf(0.0, _glint - delta)
	match s:
		S.INACTIVO:
			timer -= delta * game.risk_mult()
			if timer <= 0.0:
				_hide()
		S.OCULTO, S.ACECHANDO:
			if randf() < delta * 0.35:
				_glint = 0.12
			# Flash sobre su camara: lo descubre y lo expulsa.
			if game.monitor_up and game.current_cam == location and game.flash_time > 0.0:
				_set_state(S.REVELADO)
				timer = 0.9
				game.sfx("hiss", -2.0)
				game.hud.notify("Cornelius retrocede en la oscuridad", Color(0.83, 0.69, 0.22))
			elif s == S.OCULTO:
				timer -= delta
				if timer <= 0.0:
					_set_state(S.ACECHANDO)
			if s == S.ACECHANDO and game.monitor_up:
				_start_short()
		S.CORTO_CIRCUITO:
			if not game.monitor_up:
				_resolve()
			else:
				timer -= delta
				if timer <= 0.0:
					_fail()
		S.REVELADO:
			timer -= delta
			if timer <= 0.0:
				_go_idle()


func _hide() -> void:
	var options: Array = []
	for c in DARK_CAMS:
		if not game.cams[c].is_blind():
			options.append(c)
	if options.is_empty():
		timer = 30.0   # todas las camaras oscuras ya estan ciegas
		return
	location = options[randi() % options.size()]
	timer = randf_range(hide_min, hide_max)
	_set_state(S.OCULTO)


func _start_short() -> void:
	_set_state(S.CORTO_CIRCUITO)
	timer = react
	game.energy.spend_use(Balance.COST_SHORT_CIRCUIT)
	SoundBank.start_loop("tick", -2.0)
	game.hud.notify("TIC-TAC... ¡BAJA EL MONITOR!", Color(0.9, 0.2, 0.15))


func _resolve() -> void:
	SoundBank.stop_loop("tick")
	game.monitor_lock = lockout
	game.hud.notify("Corto circuito evitado: el monitor se reinicia", Color(0.45, 0.85, 0.5))
	_go_idle()


func _fail() -> void:
	SoundBank.stop_loop("tick")
	var cam: int = location
	_go_idle()
	game.blind_cam(cam)


func _go_idle() -> void:
	location = -1
	timer = randf_range(idle_min, idle_max)
	_set_state(S.INACTIVO)


func on_blackout() -> void:
	SoundBank.stop_loop("tick")
	super.on_blackout()
