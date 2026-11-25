extends Node3D
## Controlador del Sistema Multicámara 3D (CCTV).
## Gestiona las 7 salas de vigilancia del hotel (Dioramas 3D independientes),
## la conmutación de cámaras de seguridad, flash en salas oscuras,
## efectos de caldera/jazz y los modelos 3D de los monstruos.
##
## Los monstruos se colocan con los datos que exponen sus scripts (scripts/monsters):
##   m.key, m.location (id de camara), m.cam_pos() (x en [-1,1], profundidad en [0,1]),
##   y para casos especiales m.s, m.progress, m.glint_on(), m.awake_amount().

const MonsterFactory = preload("res://scripts/3d/monster_factory_3d.gd")
const CorneliusScript = preload("res://scripts/monsters/cornelius.gd")
const MucamaScript = preload("res://scripts/monsters/mucama.gd")

## Zona del suelo donde se paran los monstruos en cada sala (coordenadas locales de la sala).
## "center" es el punto para profundidad 0.5; half_w / half_d en metros, medidos segun
## la orientacion de la camara de esa sala.
const ROOM_SPOTS: Dictionary = {
	1: {"center": Vector3(0.9, 0.0, 0.9), "half_w": 1.7, "half_d": 1.2},    # Lobby
	2: {"center": Vector3(0.3, 0.0, 1.3), "half_w": 1.5, "half_d": 0.9},    # Recepcion
	3: {"center": Vector3(0.2, 0.0, -2.0), "half_w": 1.4, "half_d": 0.6},   # Cocina (tras la mesa)
	4: {"center": Vector3(0.0, 0.0, -1.2), "half_w": 0.9, "half_d": 2.6},   # Pasillo Este
	5: {"center": Vector3(0.0, 0.0, -1.2), "half_w": 0.9, "half_d": 2.6},   # Pasillo Oeste
	6: {"center": Vector3(2.0, 0.0, 1.2), "half_w": 1.0, "half_d": 0.8},    # Calderas
}
## Pequeno desplazamiento lateral para que dos monstruos en la misma sala no se encimen.
const SIDE_OFFSET: Dictionary = {"botones": -0.18, "chef": 0.22}

## Ducto (Cam 07): la Mucama avanza gateando de z_far a z_near segun su progreso.
const DUCT_Z_FAR: float = -4.0
const DUCT_Z_NEAR: float = 1.6

var night = null

# Diccionario de cámaras 3D (1 a 7)
var cam_nodes: Dictionary = {}
var current_cam_id: int = -1

var _rooms: Dictionary = {}       # id -> Node3D de la sala
var _cam_right: Dictionary = {}   # id -> Vector3 (derecha de la camara, en el plano del suelo)
var _cam_fwd: Dictionary = {}     # id -> Vector3 (hacia donde mira, en el plano del suelo)
var _cam_pos: Dictionary = {}     # id -> Vector3 (posicion de la camara en la sala)
var _models: Dictionary = {}      # key del monstruo -> Node3D

# Luces de flash en cámaras oscuras (Cam 4, 5, 6)
@onready var flash_cam4: SpotLight3D = $Room_Cam04/FlashLight4
@onready var flash_cam5: SpotLight3D = $Room_Cam05/FlashLight5
@onready var flash_cam6: SpotLight3D = $Room_Cam06/FlashLight6

# Elementos dinámicos de salas
@onready var boiler_fire: OmniLight3D = $Room_Cam06/BoilerLight
@onready var vent_heat: OmniLight3D = $Room_Cam07/VentHeatLight
@onready var speaker_light: OmniLight3D = $Room_Cam03/SpeakerJazzLight

# Anclajes de la escena (los que ya no se usan solo se vacian de siluetas provisionales)
@onready var anchor_ballerina: Marker3D = $Room_Cam01/BallerinaAnchor
@onready var anchor_chef: Marker3D = $Room_Cam03/ChefAnchor
@onready var anchor_mucama_cam6: Marker3D = $Room_Cam06/MucamaAnchor
@onready var anchor_mucama_vent: Marker3D = $Room_Cam07/MucamaVentAnchor
@onready var anchor_cornelius_cam4: Marker3D = $Room_Cam04/CorneliusAnchor
@onready var anchor_cornelius_cam5: Marker3D = $Room_Cam05/CorneliusAnchor
@onready var anchor_cornelius_cam6: Marker3D = $Room_Cam06/CorneliusAnchor


func _ready() -> void:
	# Mapear las 7 cámaras de seguridad
	for id in range(1, 8):
		var room_path: String = "Room_Cam%02d" % id
		if has_node(room_path):
			_rooms[id] = get_node(room_path)
		var cam_path = room_path + "/Camera3D"
		if has_node(cam_path):
			var cam = get_node(cam_path) as Camera3D
			cam_nodes[id] = cam
			cam.current = false
			# Orientacion base (antes del paneo) para colocar a los monstruos sin que "bailen".
			var right: Vector3 = cam.transform.basis.x
			right.y = 0.0
			var fwd: Vector3 = -cam.transform.basis.z
			fwd.y = 0.0
			_cam_right[id] = right.normalized()
			_cam_fwd[id] = fwd.normalized()
			_cam_pos[id] = cam.position

	for anchor in [anchor_ballerina, anchor_chef, anchor_mucama_cam6, anchor_mucama_vent,
			anchor_cornelius_cam4, anchor_cornelius_cam5, anchor_cornelius_cam6]:
		if anchor != null:
			_hide_placeholders(anchor)

	_check_and_load_room_models()


func _process(_delta: float) -> void:
	if night == null:
		return

	var t: float = Time.get_ticks_msec() / 1000.0

	# 1. Conmutar cámara activa si cambió en el juego
	if night.current_cam != current_cam_id:
		_switch_to_camera(night.current_cam)

	# 2. Paneo de seguridad lento y sutil en la cámara activa
	var active_cam: Camera3D = cam_nodes.get(current_cam_id)
	if active_cam != null:
		# Paneo sinusoidal suave de vigilancia (-3 a +3 grados)
		var pan: float = sin(t * 0.7) * deg_to_rad(3.5)
		active_cam.rotation.y = active_cam.get_meta("base_rot_y", 0.0) + pan

	# 3. Cámaras Oscuras y Flash (Tecla F)
	var has_flash: bool = (night.flash_time > 0.0)
	if flash_cam4:
		flash_cam4.light_energy = 5.0 if (has_flash and current_cam_id == 4) else 0.0
	if flash_cam5:
		flash_cam5.light_energy = 5.0 if (has_flash and current_cam_id == 5) else 0.0
	if flash_cam6:
		flash_cam6.light_energy = 5.0 if (has_flash and current_cam_id == 6) else 0.0

	# 4. Caldera en CAM 06 y calor en CAM 07
	if boiler_fire:
		var pulse: float = 1.0 + sin(t * 8.0) * 0.15
		if night.boiler_glow > 0.0:
			boiler_fire.light_energy = 4.5 * pulse
			boiler_fire.light_color = Color(1.0, 0.45, 0.1)
		else:
			boiler_fire.light_energy = 1.6 * pulse
			boiler_fire.light_color = Color(0.9, 0.3, 0.05)

	if vent_heat:
		vent_heat.light_energy = night.boiler_glow * 3.5 if night.boiler_glow > 0.0 else 0.0

	# 5. Altavoz de Jazz en CAM 03
	if speaker_light:
		if night.intercom_cam == 3 and night.intercom_timer > 0.0:
			speaker_light.light_energy = 1.5 + sin(t * 12.0) * 0.5
		else:
			speaker_light.light_energy = 0.0

	# 6. Monstruos en las cámaras
	_update_monsters_in_cctv(t)


func _switch_to_camera(id: int) -> void:
	current_cam_id = id
	for c_id in cam_nodes.keys():
		var cam: Camera3D = cam_nodes[c_id]
		var is_target: bool = (c_id == id)
		cam.current = is_target
		if is_target and not cam.has_meta("base_rot_y"):
			cam.set_meta("base_rot_y", cam.rotation.y)


# ================================================================ MONSTRUOS

func _update_monsters_in_cctv(t: float) -> void:
	for m in night.monsters:
		var model: Node3D = _get_model(m.key)
		if model == null:
			continue
		match m.key:
			"bailarina":
				_place_ballerina(m, model)
			"mucama":
				_place_mucama(m, model, t)
			"cornelius":
				_place_cornelius(m, model)
			_:
				_place_walker(m, model)


func _get_model(key: String) -> Node3D:
	if _models.has(key):
		return _models[key]
	var model: Node3D = MonsterFactory.create(key)
	_models[key] = model   # se guarda aunque sea null para no reintentar cada frame
	if model != null:
		model.visible = false
		if key == "bailarina" and anchor_ballerina != null:
			anchor_ballerina.add_child(model)
		else:
			add_child(model)
	return model


## Botones y Chef: aparecen en la sala de su "location" (igual que en la version 2D).
func _place_walker(m, model: Node3D) -> void:
	var cam: int = m.location
	if not ROOM_SPOTS.has(cam):
		model.visible = false
		return
	var p: Vector2 = m.cam_pos()
	p.x += float(SIDE_OFFSET.get(m.key, 0.0))
	_put_in_room(model, cam, p)
	model.visible = true


## Cornelius: solo esta en una camara oscura mientras se oculta / acecha / provoca el corto.
## Sus ojos estan apagados salvo en el destello (glint) o cuando el flash lo revela.
func _place_cornelius(m, model: Node3D) -> void:
	var cam: int = m.location
	if not ROOM_SPOTS.has(cam) or m.s == CorneliusScript.S.INACTIVO:
		model.visible = false
		return
	_put_in_room(model, cam, m.cam_pos())
	model.visible = true
	var g: float = 0.0
	if m.s == CorneliusScript.S.REVELADO or m.s == CorneliusScript.S.CORTO_CIRCUITO:
		g = 1.5
	elif m.glint_on(cam):
		g = 1.0
	MonsterFactory.set_glow(model, g)


## La Mucama: en la Cam 07 avanza gateando por el ducto (como la cara que crece en 2D).
func _place_mucama(m, model: Node3D, t: float) -> void:
	if m.s == MucamaScript.S.EN_DUCTOS or not _rooms.has(7):
		model.visible = false
		return
	_reparent(model, _rooms[7])
	var progress: float = clampf(m.progress, 0.0, 1.0)
	model.position = Vector3(sin(t * 3.0) * 0.05, 0.45, lerpf(DUCT_Z_FAR, DUCT_Z_NEAR, progress))
	model.rotation = Vector3(deg_to_rad(80.0), 0.0, sin(t * 2.2) * 0.06)
	MonsterFactory.set_head_pitch(model, -1.2)   # gatea boca abajo pero mira a la camara
	model.visible = true


## La Bailarina: figurita sobre la cajita de musica (Cam 01). Gira mientras hay cuerda;
## al pararse la caja crece, se detiene, mira a la camara y se le encienden los ojos.
func _place_ballerina(m, model: Node3D) -> void:
	var wake: float = m.awake_amount() if m.has_method("awake_amount") else 0.0
	model.scale = Vector3.ONE * lerpf(0.16, 0.42, wake)
	model.position = Vector3(0.0, 0.02 + wake * 0.04, 0.0)
	var charge: float = night.box_charge
	MonsterFactory.set_spin(model, 1.6 * clampf(charge * 4.0, 0.0, 1.0))
	MonsterFactory.set_glow(model, smoothstep(0.2, 0.5, wake) * 1.6)
	if anchor_ballerina != null and _cam_pos.has(1):
		_face_camera(model, 1, anchor_ballerina.position + model.position)
	model.visible = true


func _put_in_room(model: Node3D, cam: int, p: Vector2) -> void:
	_reparent(model, _rooms[cam])
	var spot: Dictionary = ROOM_SPOTS[cam]
	var center: Vector3 = spot["center"]
	var right: Vector3 = _cam_right.get(cam, Vector3.RIGHT)
	var fwd: Vector3 = _cam_fwd.get(cam, Vector3.FORWARD)
	var depth: float = clampf(p.y, 0.0, 1.0)
	var pos: Vector3 = center \
		+ right * (clampf(p.x, -1.0, 1.0) * float(spot["half_w"])) \
		+ fwd * ((0.5 - depth) * 2.0 * float(spot["half_d"]))
	model.position = pos
	_face_camera(model, cam, pos)


func _face_camera(model: Node3D, cam: int, from_pos: Vector3) -> void:
	if not _cam_pos.has(cam):
		return
	var to_cam: Vector3 = _cam_pos[cam] - from_pos
	model.rotation = Vector3(0.0, atan2(to_cam.x, to_cam.z), 0.0)


func _reparent(model: Node3D, room: Node) -> void:
	var parent: Node = model.get_parent()
	if parent == room:
		return
	if parent != null:
		parent.remove_child(model)
	room.add_child(model)


func _hide_placeholders(anchor: Node) -> void:
	for child in anchor.get_children():
		if child is MeshInstance3D or child is CSGShape3D:
			child.visible = false


func _check_and_load_room_models() -> void:
	# Carga automática si Mateo guarda modelos para las salas
	_try_load_glb("res://assets/3d/cams/lobby.glb", $Room_Cam01/Props)
	_try_load_glb("res://assets/3d/cams/reception.glb", $Room_Cam02/Props)
	_try_load_glb("res://assets/3d/cams/kitchen.glb", $Room_Cam03/Props)
	_try_load_glb("res://assets/3d/cams/boiler.glb", $Room_Cam06/Props)
	# Los monstruos ya no se cargan aqui: ver monster_factory_3d.gd
	# (assets/3d/monsters/<key>.glb tiene prioridad sobre el modelo de primitivas).


func _try_load_glb(path: String, target: Node) -> void:
	if target and ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		if scene:
			for child in target.get_children():
				if child is MeshInstance3D or child is CSGShape3D:
					child.visible = false
			var inst = scene.instantiate()
			target.add_child(inst)
