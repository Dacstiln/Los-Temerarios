extends Node3D
## Animacion procedural de los modelos 3D de los monstruos (scenes/3d/monsters/*.tscn).
## No usa AnimationPlayer: respira, se balancea, mueve la cabeza a tirones y parpadea.
##
## El modelo se arma con primitivas de Godot y se puede editar en el editor. Este script
## busca por nombre estos nodos (si falta alguno, simplemente no lo anima):
##   Body     -> respiracion, balanceo y giro (la Bailarina)
##   Head     -> tirones de cabeza + inclinacion extra (head_pitch)
##   ArmL/R   -> vaivén de los brazos
##   EyeL     -> su material (local a la escena) controla el brillo de los ojos
##   EyeLight -> pequena luz que tiñe la cara con el color de los ojos

@export var breathe: float = 0.012        ## cuanto se estira el torso al respirar
@export var sway_deg: float = 1.5         ## balanceo lateral maximo (grados)
@export var twitch: float = 1.0           ## frecuencia de tirones de cabeza (0 = nunca)
@export var eye_color: Color = Color(1.0, 0.9, 0.6)
@export var eye_energy: float = 3.0

## Multiplicador del brillo de ojos: 0 = apagados, 1 = normal, >1 = furioso.
var glow: float = 1.0
## Inclinacion extra de la cabeza en radianes (la Mucama gateando mira hacia arriba).
var head_pitch: float = 0.0
## Velocidad de giro del cuerpo en rad/s (la Bailarina gira mientras suena la caja).
var spin_speed: float = 0.0
## Poses extra (radianes) que se suman a la animacion: las usa el jumpscare 3D
## para levantar brazos, ladear la cabeza, etc.
var head_offset: Vector3 = Vector3.ZERO
var arm_l_offset: Vector3 = Vector3.ZERO
var arm_r_offset: Vector3 = Vector3.ZERO

var _body: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _eye_light: OmniLight3D
var _eye_mat: StandardMaterial3D
var _body_rot: Vector3
var _head_rot: Vector3
var _arm_l_rot: Vector3
var _arm_r_rot: Vector3
var _light_energy: float = 0.0
var _t: float = 0.0
var _spin: float = 0.0
var _blink: float = 0.0
var _twitch_timer: float = 2.0
var _twitch_target: Vector3 = Vector3.ZERO
var _twitch_cur: Vector3 = Vector3.ZERO


func _ready() -> void:
	_body = get_node_or_null("Body") as Node3D
	_head = find_child("Head", true, false) as Node3D
	_arm_l = find_child("ArmL", true, false) as Node3D
	_arm_r = find_child("ArmR", true, false) as Node3D
	_eye_light = find_child("EyeLight", true, false) as OmniLight3D
	if _body != null:
		_body_rot = _body.rotation
	if _head != null:
		_head_rot = _head.rotation
	if _arm_l != null:
		_arm_l_rot = _arm_l.rotation
	if _arm_r != null:
		_arm_r_rot = _arm_r.rotation
	if _eye_light != null:
		_light_energy = _eye_light.light_energy
	var eye := find_child("EyeL", true, false) as MeshInstance3D
	if eye != null:
		_eye_mat = eye.get_surface_override_material(0) as StandardMaterial3D
	# Cada instancia arranca en otra fase para que dos copias no se muevan igual.
	_t = randf() * 20.0
	_twitch_timer = randf_range(0.5, 3.0)
	_update_eyes()


func set_glow(value: float) -> void:
	glow = clampf(value, 0.0, 3.0)


func set_head_pitch(radians: float) -> void:
	head_pitch = radians


func set_spin(rad_per_sec: float) -> void:
	spin_speed = rad_per_sec


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta

	if _body != null:
		var sway: float = deg_to_rad(sway_deg) * sin(_t * 0.6)
		if spin_speed != 0.0:
			_spin = wrapf(_spin + spin_speed * delta, -PI, PI)
		else:
			_spin = lerp_angle(_spin, 0.0, minf(1.0, delta * 3.0))
		_body.rotation = _body_rot + Vector3(0.0, _spin, sway)
		_body.scale = Vector3(1.0, 1.0 + sin(_t * 1.7) * breathe, 1.0)

	if _head != null:
		if twitch > 0.0:
			_twitch_timer -= delta * twitch
			if _twitch_timer <= 0.0:
				_twitch_timer = randf_range(1.2, 3.5)
				_twitch_target = Vector3(randf_range(-0.18, 0.12), randf_range(-0.4, 0.4), randf_range(-0.3, 0.3))
		_twitch_cur = _twitch_cur.lerp(_twitch_target, minf(1.0, delta * 16.0))   # tiron brusco
		_twitch_target = _twitch_target.lerp(Vector3.ZERO, minf(1.0, delta * 0.7)) # vuelve despacio
		var idle := Vector3(sin(_t * 0.9) * 0.03 + head_pitch, sin(_t * 0.37) * 0.05, 0.0)
		_head.rotation = _head_rot + _twitch_cur + idle + head_offset

	if _arm_l != null:
		_arm_l.rotation = _arm_l_rot + Vector3(sin(_t * 1.1) * 0.045, 0.0, 0.0) + arm_l_offset
	if _arm_r != null:
		_arm_r.rotation = _arm_r_rot + Vector3(sin(_t * 1.1 + 1.9) * 0.045, 0.0, 0.0) + arm_r_offset

	# Parpadeo ocasional
	if _blink > 0.0:
		_blink -= delta
	elif randf() < delta * 0.25:
		_blink = 0.12
	_update_eyes()


func _update_eyes() -> void:
	var g: float = glow
	if _blink > 0.0:
		g = 0.0
	g *= 0.92 + 0.08 * sin(_t * 13.0)
	if _eye_mat != null:
		_eye_mat.emission = eye_color
		_eye_mat.emission_energy_multiplier = eye_energy * g
		_eye_mat.albedo_color = Color(0.05, 0.04, 0.04).lerp(eye_color, clampf(g, 0.0, 1.0))
	if _eye_light != null:
		_eye_light.light_energy = _light_energy * g
		_eye_light.visible = g > 0.05
