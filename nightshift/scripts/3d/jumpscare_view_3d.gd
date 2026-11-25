extends Control
## Jumpscare 3D a pantalla completa, con una coreografia distinta para cada monstruo.
## Usa los mismos modelos que la oficina y las camaras (monster_factory_3d.gd).
## Lo crea night.gd en _on_jumpscare() cuando la version 3D esta activa.
##
##   El Botones   -> sale de la reja por la que vino y se lanza con los brazos estirados.
##   El Chef      -> corre hacia ti, levanta la cuchilla y la baja de golpe.
##   La Mucama    -> cae de cabeza desde el ducto del techo, colgando boca abajo.
##   Cornelius    -> oscuridad total, solo sus ojos dorados... y de pronto esta en tu cara.
##   La Bailarina -> gira sin control, se detiene en seco y se lanza con la cabeza torcida.

const MonsterFactory = preload("res://scripts/3d/monster_factory_3d.gd")

## Altura de los ojos y cuanto sobresale la cara por delante del origen (modelo a escala 1).
const EYE_HEIGHT: Dictionary = {"botones": 1.76, "chef": 2.03, "mucama": 1.64, "cornelius": 1.81, "bailarina": 0.87}
const FACE_Z: Dictionary = {"botones": 0.27, "chef": 0.39, "mucama": 0.11, "cornelius": 0.09, "bailarina": 0.065}

var kind: String = "botones"
var side: String = ""          # "left" / "right": reja por la que entro (Botones / Chef)

var _t: float = 0.0
var _cam: Camera3D
var _env: Environment
var _model: Node3D
var _key_light: SpotLight3D
var _red_light: OmniLight3D
var _fx: Control
var _scale: float = 1.0
var _eye_y: float = 1.7
var _face_z: float = 0.2
var _shake: float = 0.0
var _flash: float = 0.0
var _flash_color: Color = Color(0.85, 0.0, 0.0)
var _impact_done: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(vp)

	var world := Node3D.new()
	vp.add_child(world)

	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.0, 0.0, 0.0)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.3, 0.26, 0.28)
	_env.ambient_light_energy = 0.5
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.glow_enabled = true
	_env.glow_intensity = 1.0
	var we := WorldEnvironment.new()
	we.environment = _env
	world.add_child(we)

	_scale = 2.0 if kind == "bailarina" else 1.0
	_eye_y = float(EYE_HEIGHT.get(kind, 1.7)) * _scale
	_face_z = float(FACE_Z.get(kind, 0.2)) * _scale

	_cam = Camera3D.new()
	_cam.fov = 62.0
	_cam.near = 0.02
	_cam.position = Vector3(0.0, _eye_y, 0.0)
	world.add_child(_cam)
	_cam.current = true

	# Luz desde abajo (la clasica luz de "linterna bajo la barbilla")
	_key_light = SpotLight3D.new()
	_key_light.light_color = Color(1.0, 0.86, 0.72)
	_key_light.light_energy = 2.6
	_key_light.spot_range = 7.0
	_key_light.spot_angle = 42.0
	world.add_child(_key_light)
	_key_light.look_at_from_position(Vector3(0.0, _eye_y - 0.75, 0.15), Vector3(0.0, _eye_y, -0.7), Vector3.UP)

	_red_light = OmniLight3D.new()
	_red_light.light_color = Color(1.0, 0.08, 0.04)
	_red_light.omni_range = 4.0
	_red_light.light_energy = 0.0
	_red_light.position = Vector3(0.7, _eye_y + 0.6, -0.4)
	world.add_child(_red_light)

	_model = MonsterFactory.create(kind)
	if _model != null:
		_model.scale = Vector3.ONE * _scale
		world.add_child(_model)
		_model.set("twitch", 0.0)   # la coreografia controla la cabeza
		MonsterFactory.set_glow(_model, 2.0)

	# Capa de efectos 2D (tinte rojo, destello y estatica) por encima del 3D.
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.draw.connect(_draw_fx)

	_process(0.0)


func _process(delta: float) -> void:
	_t += delta
	if _model != null:
		match kind:
			"botones":
				_anim_botones()
			"chef":
				_anim_chef()
			"mucama":
				_anim_mucama()
			"cornelius":
				_anim_cornelius()
			"bailarina":
				_anim_bailarina()
			_:
				_anim_botones()

	# Temblor de camara
	_shake = maxf(0.0, _shake - delta * 0.6)
	_cam.h_offset = randf_range(-1.0, 1.0) * _shake * 0.035
	_cam.v_offset = randf_range(-1.0, 1.0) * _shake * 0.035
	_cam.rotation = Vector3(0.0, 0.0, randf_range(-1.0, 1.0) * _shake * 0.03)

	# Luz roja parpadeante
	if _t > 0.2 and kind != "cornelius":
		_red_light.light_energy = randf_range(0.5, 3.5)
	_flash = maxf(0.0, _flash - delta * 3.0)
	_fx.queue_redraw()


# ================================================================ coreografias

## Coloca al monstruo a "dist" metros de la camara (medidos hasta su cara).
func _place(dist: float, x: float = 0.0, y: float = 0.0) -> void:
	_model.position = Vector3(x, y, -dist - _face_z)


func _impact(strength: float, col: Color) -> void:
	if _impact_done:
		return
	_impact_done = true
	_shake = strength
	_flash = 1.0
	_flash_color = col


func _anim_botones() -> void:
	var sx: float = 1.0 if side == "right" else -1.0
	var k: float = _ease_out_back(clampf(_t / 0.22, 0.0, 1.0))
	_place(lerpf(2.6, 0.42, k), lerpf(sx * 1.4, 0.0, k))
	_model.rotation = Vector3(0.0, lerpf(-sx * 0.6, 0.0, k), 0.0)
	var reach: float = lerpf(0.0, -1.35, clampf(_t / 0.25, 0.0, 1.0))
	_model.set("arm_l_offset", Vector3(reach, 0.0, -0.15))
	_model.set("arm_r_offset", Vector3(reach, 0.0, 0.15))
	if _t > 0.22:
		_impact(1.0, Color(0.85, 0.0, 0.0))
		_model.set("head_offset", Vector3(0.0, sin(_t * 31.0) * 0.08, sin(_t * 43.0) * 0.18))


func _anim_chef() -> void:
	var k: float = _ease_out(clampf(_t / 0.28, 0.0, 1.0))
	_place(lerpf(3.2, 0.62, k))
	var arm: float
	if _t < 0.3:
		arm = lerpf(0.0, -2.7, _t / 0.3)                    # levanta la cuchilla
	elif _t < 0.42:
		arm = lerpf(-2.7, -0.55, (_t - 0.3) / 0.12)          # golpe
	else:
		arm = -0.55 + sin(_t * 50.0) * 0.04                  # tiembla de rabia
	_model.set("arm_r_offset", Vector3(arm, 0.0, 0.0))
	_model.set("arm_l_offset", Vector3(lerpf(0.0, -0.9, k), 0.0, 0.0))
	_model.set("head_offset", Vector3(0.25 * k, 0.0, sin(_t * 18.0) * 0.05))
	if _t >= 0.42:
		_impact(1.5, Color(0.9, 0.0, 0.0))
	MonsterFactory.set_glow(_model, 2.4)


func _anim_mucama() -> void:
	# Boca abajo: girada 180 grados sobre Z, la cabeza queda abajo y la falda arriba.
	var k: float = clampf(_t / 0.3, 0.0, 1.0)
	var drop: float = lerpf(2.6, 0.0, _ease_out_back(k))
	var swing: float = sin(_t * 5.0) * 0.18 * (1.0 - 0.6 * k)
	_model.rotation = Vector3(swing, 0.0, PI)
	_model.position = Vector3(0.0, _eye_y + 1.64 + drop, -0.5 - _face_z)
	_model.set("head_offset", Vector3(0.0, 0.0, sin(_t * 23.0) * 0.22))
	_model.set("arm_l_offset", Vector3(-1.2 * k, 0.0, 0.0))
	_model.set("arm_r_offset", Vector3(-1.2 * k, 0.0, 0.0))
	if _t > 0.28:
		_impact(1.1, Color(0.55, 0.7, 1.0))
	MonsterFactory.set_glow(_model, 2.6)


func _anim_cornelius() -> void:
	if _t < 0.55:
		# Todo a oscuras: solo sus ojos dorados al fondo.
		_env.ambient_light_energy = 0.0
		_key_light.light_energy = 0.0
		_red_light.light_energy = 0.0
		_place(4.0)
		MonsterFactory.set_glow(_model, 1.8)
	else:
		_env.ambient_light_energy = 0.35
		_place(0.48 + sin(_t * 9.0) * 0.01)
		# Luz estroboscopica
		_key_light.light_energy = 3.2 if fmod(_t, 0.12) < 0.06 else 0.4
		_red_light.light_energy = randf_range(0.0, 2.0)
		_model.set("head_offset", Vector3(0.1, 0.0, -0.35))
		_model.set("arm_r_offset", Vector3(-1.1, 0.0, 0.0))
		MonsterFactory.set_glow(_model, 2.8)
		_impact(1.2, Color(1.0, 0.85, 0.35))


func _anim_bailarina() -> void:
	if _t < 0.45:
		_place(2.4)
		MonsterFactory.set_spin(_model, 28.0)
		MonsterFactory.set_glow(_model, lerpf(0.5, 2.5, _t / 0.45))
	else:
		MonsterFactory.set_spin(_model, 0.0)
		var k: float = _ease_out_back(clampf((_t - 0.45) / 0.17, 0.0, 1.0))
		_place(lerpf(2.4, 0.42, k))
		_model.set("head_offset", Vector3(0.0, 0.0, lerpf(0.0, 1.35, k)))   # cabeza torcida
		MonsterFactory.set_glow(_model, 3.0)
		if k >= 0.95:
			_impact(1.2, Color(0.9, 0.0, 0.05))


# ================================================================ efectos 2D

func _draw_fx() -> void:
	var sz: Vector2 = _fx.size
	var red_a: float = clampf(0.4 - _t * 0.2, 0.0, 0.4)
	if kind == "cornelius" and _t < 0.55:
		red_a = 0.0
	_fx.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.8, 0.0, 0.0, red_a))
	if _flash > 0.0:
		_fx.draw_rect(Rect2(Vector2.ZERO, sz), Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash * 0.7))
	for i in 140:
		var y: float = randf() * sz.y
		_fx.draw_line(Vector2(0.0, y), Vector2(randf() * sz.x, y), Color(1, 1, 1, randf() * 0.1), 1.0)


# ================================================================ curvas

func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


func _ease_out_back(x: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)
