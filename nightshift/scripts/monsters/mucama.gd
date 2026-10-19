extends "res://scripts/monsters/monster.gd"
## La Mucama (Amenaza 2). Ciega, oido fino, se mueve por ductos -> exige vigilancia de
## Cam 07 y el Sobrecargo de Caldera. Las rejas NO sirven contra ella.
##
## Estados (GDD Pagina 4):
## En ductos (Cam 07) -> Acercandose a la rejilla de la oficina
##   -> [Sobrecargo de Caldera] Repelida -> En ductos
##   -> [sin contramedida a tiempo] Jumpscare

enum S { EN_DUCTOS, ACERCANDOSE, EN_REJILLA, REPELIDA }
const NAMES: Array = ["EN DUCTOS", "ACERCÁNDOSE A LA REJILLA", "EN LA REJILLA", "REPELIDA"]

var s: int = S.EN_DUCTOS
var progress: float = 0.0   # 0 = lejos en el ducto, 1 = en la rejilla de la oficina
var timer: float = 0.0
var idle_min: float = 20.0
var idle_max: float = 32.0
var approach: float = 12.0
var window: float = 4.5
var _cue_timer: float = 0.0


func _configure(cfg: Dictionary) -> void:
	key = "mucama"
	display_name = "La Mucama"
	counter_hint = "La Mucama viaja por los ductos: solo la repele el Sobrecargo de Caldera [B]. Las rejas no sirven. Vigila la Cam 07."
	idle_min = float(cfg.get("idle_min", 20.0))
	idle_max = float(cfg.get("idle_max", 32.0))
	approach = float(cfg.get("approach", 12.0))
	window = float(cfg.get("window", 4.5))
	location = 7
	timer = randf_range(idle_min, idle_max)
	_set_state(S.EN_DUCTOS)


func _set_state(new_state: int) -> void:
	s = new_state
	state_name = NAMES[new_state]


func is_threatening() -> bool:
	return s == S.ACERCANDOSE or s == S.EN_REJILLA


## 0..1: cuanto se agita la rejilla de la oficina (señal visual cuando esta cerca).
func vent_rattle() -> float:
	if s == S.EN_REJILLA:
		return 1.0
	if s == S.ACERCANDOSE and progress > 0.5:
		return (progress - 0.5) * 2.0
	return 0.0


func on_boiler() -> bool:
	if s == S.ACERCANDOSE or s == S.EN_REJILLA:
		_set_state(S.REPELIDA)
		timer = 2.5
		return true
	return false


func _tick(delta: float) -> void:
	match s:
		S.EN_DUCTOS:
			timer -= delta
			if timer <= 0.0:
				progress = 0.0
				_cue_timer = 0.0
				_set_state(S.ACERCANDOSE)
		S.ACERCANDOSE:
			progress = minf(1.0, progress + delta / approach * game.risk_mult())
			_vent_cue(delta)
			if progress >= 1.0:
				_set_state(S.EN_REJILLA)
				timer = window
				game.sfx("vent", 0.0)
		S.EN_REJILLA:
			timer -= delta
			_vent_cue(delta)
			if timer <= 0.0:
				_trigger_jumpscare("fallo")
		S.REPELIDA:
			progress = maxf(0.0, progress - delta * 0.8)
			timer -= delta
			if timer <= 0.0:
				progress = 0.0
				timer = randf_range(idle_min, idle_max)
				_set_state(S.EN_DUCTOS)


## Ruido de ductos que crece con la cercania (pista de audio).
func _vent_cue(delta: float) -> void:
	_cue_timer -= delta
	if _cue_timer <= 0.0:
		_cue_timer = 2.4 if progress < 0.6 else 1.4
		game.sfx("vent", lerpf(-22.0, -4.0, progress))
