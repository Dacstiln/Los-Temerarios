extends Control
## Escenario 3D de fondo para menus y pantallas, al estilo del menu de FNAF 1:
## la cara de un monstruo en la penumbra, luz que parpadea, tirones de cabeza,
## estatica de TV y, cada cierto tiempo, una rafaga de estatica que cambia de monstruo.
##
## Uso (se dibuja DETRAS de la interfaz porque vive en un CanvasLayer propio):
##   var stage = Stage3D.attach(self, {"kinds": ["chef"], "focus_x": 0.7})
## Propiedades utiles: kinds, mode, focus_x, darkness, static_base, red_mode, swap_every.

const MonsterFactory = preload("res://scripts/3d/monster_factory_3d.gd")

enum Mode { PORTRAIT, LINEUP }

## Altura de los ojos y cuanto sobresale la cara (modelos a escala 1).
const EYE_HEIGHT: Dictionary = {"botones": 1.76, "chef": 2.03, "mucama": 1.64, "cornelius": 1.81, "bailarina": 0.87}
const FACE_Z: Dictionary = {"botones": 0.27, "chef": 0.39, "mucama": 0.11, "cornelius": 0.09, "bailarina": 0.065}

var mode: int = Mode.PORTRAIT
var kinds: Array = ["botones"]           # monstruos (PORTRAIT los va alternando; LINEUP los pone en fila)
var focus_x: float = 0.68                # donde queda la cara en pantalla (0 = izquierda, 1 = derecha)
var distance: float = 0.9                # distancia de la camara a la cara (PORTRAIT)
var light_color: Color = Color(0.95, 0.86, 0.72)
var light_energy: float = 1.7
var static_base: float = 0.16            # estatica de fondo permanente (0..1)
var darkness: float = 0.0                # 0..1: oscurece toda la escena (para paginas con paneles)
var red_mode: bool = false               # luz roja y mas estatica (pantalla de derrota)
var swap_every: float = 7.5              # segundos entre cambios de monstruo (0 = nunca)
var twitch_every: float = 3.5            # segundos medios entre tirones

var _t: float = 0.0
var _world: Node3D
var _cam: Camera3D
var _key: SpotLight3D
var _rim: OmniLight3D
var _models: Array = []
var _kind_idx: int = 0
var _swap_timer: float = 0.0
var _twitch_timer: float = 2.0
var _twitch_left: float = 0.0
var _twitch_pose: Vector3 = Vector3.ZERO
var _spike: float = 0.0
var _swap_pending: bool = false
var _flicker_left: float = 0.0
var _fx: Control
var _static_frames: Array = []
var _vignette: GradientTexture2D
var _eye_y: float = 1.7
var _cam_base: Vector3


## Crea el escenario en un CanvasLayer (por defecto -1, detras de la interfaz) dentro de `parent`.
static func attach(parent: Node, props: Dictionary = {}, layer: int = -1):
	var cl := CanvasLayer.new()
	cl.layer = layer
	parent.add_child(cl)
	var stage = load("res://scripts/3d/stage_3d.gd").new()
	for k in props.keys():
		stage.set(k, props[k])
	cl.add_child(stage)
	return stage


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	_world = Node3D.new()
	vp.add_child(_world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.32, 0.36)
	env.ambient_light_energy = 0.12
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	_world.add_child(we)

	_cam = Camera3D.new()
	_cam.fov = 48.0
	_cam.near = 0.02
	_world.add_child(_cam)
	_cam.current = true

	_key = SpotLight3D.new()
	_key.spot_range = 9.0
	_key.spot_angle = 38.0
	_key.shadow_enabled = false
	_world.add_child(_key)
	_rim = OmniLight3D.new()
	_rim.omni_range = 3.5
	_world.add_child(_rim)

	if red_mode:
		light_color = Color(1.0, 0.25, 0.18)
		static_base = maxf(static_base, 0.24)

	_build_static()
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_fx)
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.draw.connect(_draw_fx)

	if kinds.is_empty():
		kinds = ["botones"]
	_kind_idx = 0
	_swap_timer = swap_every
	_twitch_timer = randf_range(1.0, twitch_every)
	_build_scene()
	_spike = 0.8   # entra con una rafaga de estatica


func _build_scene() -> void:
	for m in _models:
		m.queue_free()
	_models.clear()
	if mode == Mode.LINEUP:
		var n: int = kinds.size()
		var spacing: float = 0.95
		for i in n:
			var key: String = String(kinds[i])
			var model: Node3D = MonsterFactory.create(key)
			if model == null:
				continue
			var s: float = 2.0 if key == "bailarina" else 1.0
			model.scale = Vector3.ONE * s
			var x: float = (float(i) - float(n - 1) * 0.5) * spacing
			model.position = Vector3(x, 0.0, -absf(x) * 0.35)
			model.rotation = Vector3(0.0, -x * 0.18, 0.0)
			_world.add_child(model)
			model.set("twitch", 0.6)
			MonsterFactory.set_glow(model, 1.2)
			_models.append(model)
		_eye_y = 1.75
		_cam_base = Vector3(0.0, 1.6, 4.4)
		_cam.position = _cam_base
		_cam.look_at(Vector3(0.0, 1.25, 0.0), Vector3.UP)
		_key.look_at_from_position(Vector3(0.0, 4.2, 2.2), Vector3(0.0, 1.1, 0.0), Vector3.UP)
		_rim.position = Vector3(0.0, 2.2, -1.6)
	else:
		var key: String = String(kinds[_kind_idx % kinds.size()])
		var model: Node3D = MonsterFactory.create(key)
		if model == null:
			return
		var s: float = 2.0 if key == "bailarina" else 1.0
		model.scale = Vector3.ONE * s
		model.rotation = Vector3(0.0, -0.22, 0.0)   # mira un poco hacia la camara
		_world.add_child(model)
		model.set("twitch", 0.0)
		MonsterFactory.set_glow(model, 1.0)
		_models.append(model)
		_eye_y = float(EYE_HEIGHT.get(key, 1.7)) * s
		var face_z: float = float(FACE_Z.get(key, 0.2)) * s
		# Desplaza la camara para que la cara quede en focus_x
		var half_h: float = distance * tan(deg_to_rad(_cam.fov * 0.5))
		var half_w: float = half_h * (1280.0 / 720.0)
		var off: float = (focus_x - 0.5) * 2.0 * half_w
		_cam_base = Vector3(-off, _eye_y - 0.1, face_z + distance)
		_cam.position = _cam_base
		_cam.rotation = Vector3.ZERO
		_key.look_at_from_position(Vector3(-0.9, _eye_y + 0.8, face_z + 1.1), Vector3(0.0, _eye_y - 0.1, 0.0), Vector3.UP)
		_rim.position = Vector3(0.55, _eye_y + 0.25, -0.7)
	_key.light_color = light_color
	_rim.light_color = light_color.lerp(Color(0.5, 0.6, 1.0), 0.5)


## Prepara unos cuantos cuadros de estatica (ruido en blanco y negro de baja resolucion).
func _build_static() -> void:
	for f in 4:
		var data := PackedByteArray()
		data.resize(160 * 90)
		for i in data.size():
			data[i] = randi() % 256
		var img := Image.create_from_data(160, 90, false, Image.FORMAT_L8, data)
		_static_frames.append(ImageTexture.create_from_image(img))
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0, 0, 0, 0.92))
	grad.set_offset(0, 0.45)
	_vignette = GradientTexture2D.new()
	_vignette.gradient = grad
	_vignette.fill = GradientTexture2D.FILL_RADIAL
	_vignette.fill_from = Vector2(0.5, 0.5)
	_vignette.fill_to = Vector2(1.05, 1.05)
	_vignette.width = 256
	_vignette.height = 144


func _process(delta: float) -> void:
	_t += delta
	_spike = maxf(0.0, _spike - delta * 2.4)

	# Cambio de monstruo con rafaga de estatica (solo PORTRAIT con varios monstruos)
	if mode == Mode.PORTRAIT and swap_every > 0.0 and kinds.size() > 1:
		_swap_timer -= delta
		if _swap_timer <= 0.0 and not _swap_pending:
			_swap_pending = true
			_spike = 1.0
			_swap_timer = swap_every + randf_range(-1.5, 1.5)
		elif _swap_pending and _spike < 0.75:
			_swap_pending = false
			_kind_idx += 1
			_build_scene()

	# Tirones: la cabeza da un giro brusco, los ojos se encienden y salta la estatica
	_twitch_timer -= delta
	if _twitch_timer <= 0.0:
		_twitch_timer = randf_range(twitch_every * 0.5, twitch_every * 1.5)
		_twitch_left = randf_range(0.12, 0.35)
		_twitch_pose = Vector3(randf_range(-0.25, 0.2), randf_range(-0.6, 0.6), randf_range(-0.5, 0.5))
		_spike = maxf(_spike, 0.45)
	var twitching: bool = _twitch_left > 0.0
	_twitch_left -= delta

	for i in _models.size():
		var m: Node3D = _models[i]
		var idle := Vector3(sin(_t * 0.31 + i) * 0.05, sin(_t * 0.23 + i * 2.0) * 0.12, sin(_t * 0.17 + i) * 0.04)
		var target_pick: bool = mode == Mode.PORTRAIT or (i == int(_t * 0.37) % _models.size())
		var pose: Vector3 = idle + (_twitch_pose if twitching and target_pick else Vector3.ZERO)
		m.set("head_offset", pose)
		var glow: float = 1.0 if mode == Mode.PORTRAIT else 1.2
		if twitching and target_pick:
			glow = 2.6
		if red_mode:
			glow *= 1.5
		MonsterFactory.set_glow(m, glow)

	# Camara que "respira" muy despacio
	_cam.h_offset = sin(_t * 0.21) * 0.02
	_cam.v_offset = sin(_t * 0.17) * 0.015
	if mode == Mode.PORTRAIT:
		_cam.position = _cam_base + Vector3(0.0, 0.0, -minf(_t * 0.01, 0.12))   # se acerca poco a poco

	# Parpadeo de bombilla
	if _flicker_left > 0.0:
		_flicker_left -= delta
	elif randf() < delta * 0.5:
		_flicker_left = randf_range(0.05, 0.2)
	var flick: float = 0.18 if _flicker_left > 0.0 else 1.0
	_key.light_energy = light_energy * flick * (0.92 + 0.08 * sin(_t * 17.0)) * (1.0 - darkness * 0.6)
	_rim.light_energy = 0.5 * flick * (1.0 - darkness * 0.6)
	_fx.queue_redraw()


func _draw_fx() -> void:
	var sz: Vector2 = _fx.size
	if darkness > 0.0:
		_fx.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, darkness))
	if red_mode:
		_fx.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.5, 0.0, 0.0, 0.12 + 0.06 * sin(_t * 3.0)))
	_fx.draw_texture_rect(_vignette, Rect2(Vector2.ZERO, sz), false)
	# Estatica
	var amount: float = clampf(static_base + _spike * 0.8, 0.0, 1.0)
	if not _static_frames.is_empty():
		var tex: Texture2D = _static_frames[int(_t * 24.0) % _static_frames.size()]
		_fx.draw_texture_rect(tex, Rect2(Vector2.ZERO, sz), false, Color(1, 1, 1, amount * 0.55))
	# Bandas de interferencia durante las rafagas
	if _spike > 0.2:
		for i in int(_spike * 6.0):
			var y: float = randf() * sz.y
			_fx.draw_rect(Rect2(0, y, sz.x, randf_range(2.0, 14.0)), Color(1, 1, 1, randf() * 0.18 * _spike))
	# Lineas de barrido
	var y2: float = 0.0
	while y2 < sz.y:
		_fx.draw_line(Vector2(0, y2), Vector2(sz.x, y2), Color(0, 0, 0, 0.18), 1.0)
		y2 += 3.0
