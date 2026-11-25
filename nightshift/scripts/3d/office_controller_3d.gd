extends Node3D
## Controlador del Entorno 3D de la Oficina.
## Maneja: Rotación de cámara tipo FNAF, iluminación equilibrada en tiempo real,
## luces de puertas (Q/E) con revelado de monstruos en sombra y modelos GLB.
##
## Monstruos: se leen con la misma interfaz que usa la version 2D
## (m.key, m.at_gate_side(), m.vent_rattle()), no con nombres de nodo.

const MonsterFactory = preload("res://scripts/3d/monster_factory_3d.gd")

## Monstruos que pueden aparecer en las rejas de la oficina.
const GATE_MONSTERS: Array = ["botones", "chef"]
## Escala por monstruo en la puerta (el gorro del Chef no cabe por el marco).
const GATE_SCALE: Dictionary = {"botones": 1.0, "chef": 0.93}
## Cuanto se separa de la reja (z local negativo = hacia el pasillo). El Chef es mas ancho.
const GATE_BACK: Dictionary = {"botones": 0.0, "chef": -0.28}

var night = null

var _gate_models: Dictionary = {"left": {}, "right": {}}   # lado -> key -> Node3D
var _vent_model: Node3D = null

# --- Nodos de Cámara y Vista ---
@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight

# --- Nodos de Rejas 3D ---
@onready var gate_left: Node3D = $Gates/GateLeft
@onready var gate_right: Node3D = $Gates/GateRight

# --- Nodos de Iluminación 3D ---
@onready var room_light: OmniLight3D = $Lights/RoomCeilingLight
@onready var office_lamp: SpotLight3D = $Lights/DeskLampLight
@onready var lamp_bulb: OmniLight3D = $Lights/DeskLampBulb
@onready var tv_glow: SpotLight3D = $Lights/MonitorGlowLight
@onready var light_door_left: SpotLight3D = $Lights/DoorLeftLight
@onready var light_door_right: SpotLight3D = $Lights/DoorRightLight
@onready var vent_light: OmniLight3D = $Lights/VentLight

# --- Anclajes para Modelos 3D GLB externos ---
@onready var desk_anchor: Marker3D = $Props/DeskAnchor
@onready var monitor_anchor: Marker3D = $Props/MonitorAnchor
@onready var lamp_anchor: Marker3D = $Props/LampAnchor
@onready var chair_anchor: Marker3D = $Props/ChairAnchor
@onready var monster_left_anchor: Marker3D = $Characters/LeftMonsterAnchor
@onready var monster_right_anchor: Marker3D = $Characters/RightMonsterAnchor
@onready var monster_vent_anchor: Marker3D = $Characters/VentMonsterAnchor

# --- Parámetros de Cámara (FNAF Mouse Look) ---
const MAX_YAW_RAD: float = deg_to_rad(58.0)   # 58 grados a la izq / der
const MAX_PITCH_RAD: float = deg_to_rad(14.0) # Inclinación arriba/abajo
var current_yaw: float = 0.0
var current_pitch: float = 0.0
var target_yaw: float = 0.0
var target_pitch: float = 0.0

# Posiciones Y para rejas mecánicas (Abierta vs Cerrada)
const GATE_Y_OPEN: float = 3.75   # los barrotes quedan por encima del marco (antes tapaban la cabeza)
const GATE_Y_CLOSED: float = 1.15
var gate_y_left: float = GATE_Y_OPEN
var gate_y_right: float = GATE_Y_OPEN


func _ready() -> void:
	_setup_props()
	_setup_door_lights()
	_fix_lighting()
	_build_hallways()
	_build_vent_duct()
	_build_gate_bars(gate_left)
	_build_gate_bars(gate_right)
	_setup_monsters()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp_size: Vector2 = get_viewport().get_visible_rect().size
		if vp_size.x > 0.0 and vp_size.y > 0.0:
			var norm_x: float = (event.position.x / vp_size.x) * 2.0 - 1.0 # -1.0 a +1.0
			var norm_y: float = (event.position.y / vp_size.y) * 2.0 - 1.0 # -1.0 a +1.0
			
			target_yaw = -norm_x * MAX_YAW_RAD
			target_pitch = -norm_y * MAX_PITCH_RAD


func _process(delta: float) -> void:
	# 1. Paneo suave de cámara
	current_yaw = lerp_angle(current_yaw, target_yaw, delta * 7.5)
	current_pitch = lerp(current_pitch, target_pitch, delta * 7.5)
	camera.rotation = Vector3(current_pitch, current_yaw, 0.0)

	if night == null:
		return

	# 2. Control dinámico de Rejas 3D (A y D)
	var target_y_l: float = GATE_Y_CLOSED if night.gate_closed.get("left", false) else GATE_Y_OPEN
	var target_y_r: float = GATE_Y_CLOSED if night.gate_closed.get("right", false) else GATE_Y_OPEN
	
	gate_y_left = lerp(gate_y_left, target_y_l, delta * 12.0)
	gate_y_right = lerp(gate_y_right, target_y_r, delta * 12.0)
	gate_left.position.y = gate_y_left
	gate_right.position.y = gate_y_right

	# 3. Iluminación y estados de juego
	if night.blackout:
		room_light.light_energy = 0.0
		office_lamp.light_energy = 0.0
		lamp_bulb.light_energy = 0.0
		tv_glow.light_energy = 0.0
		light_door_left.light_energy = 0.0
		light_door_right.light_energy = 0.0
		flashlight.light_energy = 0.0
		vent_light.light_energy = 0.0
	else:
		# Oficina general: iluminada de forma clara y nítida
		room_light.light_energy = 0.85

		# Lámpara de escritorio: sutil, no quema
		var lamp_flicker: float = 1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.03
		office_lamp.light_energy = 1.15 * lamp_flicker
		lamp_bulb.light_energy = 0.35 * lamp_flicker

		# TV / Monitor CRT: brillo de fósforo azul tenue
		var tv_flicker: float = 1.0 + (sin(Time.get_ticks_msec() * 0.035) + sin(Time.get_ticks_msec() * 0.08)) * 0.04
		tv_glow.light_energy = 0.65 * tv_flicker

		# Luces en las puertas (Controladas por Q y E)
		var left_on: bool = night.door_light.get("left", false)
		var right_on: bool = night.door_light.get("right", false)

		light_door_left.light_energy = 4.2 if left_on else 0.0
		light_door_right.light_energy = 4.2 if right_on else 0.0

		# Linterna / Flash
		flashlight.light_energy = 3.5 if (night.flash_time > 0.0) else 0.0

		# Resplandor de caldera
		vent_light.light_energy = night.boiler_glow * 3.0 if night.boiler_glow > 0.0 else 0.0

	# 4. Monstruos en oficina
	_update_monsters_in_office()


func _update_monsters_in_office() -> void:
	# Quien esta en cada reja (pueden coincidir el Botones y el Chef en el mismo lado).
	var occupants: Dictionary = {"left": [], "right": []}
	var rattle: float = 0.0
	for m in night.monsters:
		var side: String = m.at_gate_side()
		if occupants.has(side):
			occupants[side].append(m.key)
		if m.key == "mucama" and m.has_method("vent_rattle"):
			rattle = m.vent_rattle()

	for side in ["left", "right"]:
		var here: Array = occupants[side]
		var models: Dictionary = _gate_models[side]
		for key in models.keys():
			var model: Node3D = models[key]
			var idx: int = here.find(key)
			model.visible = idx >= 0
			if idx >= 0:
				# Si hay dos, uno se aparta a un lado y un poco atras.
				var lateral: float = 0.0
				if here.size() > 1:
					lateral = -0.34 if idx == 0 else 0.34
				model.position = Vector3(lateral, 0.0, float(GATE_BACK.get(key, 0.0)) - 0.15 * idx)

	# La Mucama asoma por la rejilla de ventilacion cuando esta cerca.
	if _vent_model != null:
		_vent_model.visible = rattle > 0.0 and not night.blackout
		if _vent_model.visible:
			var shake: float = sin(Time.get_ticks_msec() * 0.03) * 0.012 * rattle
			# Inclinada hacia la rejilla: la cara asoma por el hueco y la falda queda tras el muro.
			_vent_model.position = Vector3(shake, -1.05, lerpf(-1.3, -1.06, rattle))


## Crea los modelos de los monstruos una sola vez y los deja ocultos en sus anclajes.
func _setup_monsters() -> void:
	for anchor in [monster_left_anchor, monster_right_anchor, monster_vent_anchor]:
		_hide_placeholders(anchor)
		anchor.visible = true   # en la escena vienen ocultos; ahora se controla cada modelo

	for side in ["left", "right"]:
		var side_anchor: Marker3D = monster_left_anchor if side == "left" else monster_right_anchor
		for key in GATE_MONSTERS:
			var model: Node3D = MonsterFactory.create(key)
			if model == null:
				continue
			model.scale = Vector3.ONE * float(GATE_SCALE.get(key, 1.0))
			model.visible = false
			side_anchor.add_child(model)
			MonsterFactory.set_layers(model, MonsterFactory.MONSTER_LAYER)
			_gate_models[side][key] = model

	_vent_model = MonsterFactory.create("mucama")
	if _vent_model != null:
		_vent_model.visible = false
		_vent_model.rotation = Vector3(deg_to_rad(25.0), 0.0, 0.0)
		monster_vent_anchor.add_child(_vent_model)
		MonsterFactory.set_head_pitch(_vent_model, -0.5)
		MonsterFactory.set_layers(_vent_model, MonsterFactory.MONSTER_LAYER)

	# Las luces de ambiente de la oficina NO tocan a los monstruos: en el pasillo solo
	# se les ve la silueta y los ojos hasta que enciendes la luz de la puerta (Q / E).
	for l in [room_light, office_lamp, lamp_bulb, tv_glow]:
		l.light_cull_mask = l.light_cull_mask & ~MonsterFactory.MONSTER_LAYER


## Las luces de puerta venian apuntando hacia dentro de la oficina. Ahora apuntan
## hacia fuera, al pasillo, donde se para el monstruo.
func _setup_door_lights() -> void:
	light_door_left.look_at_from_position(Vector3(-3.55, 2.25, -0.6), Vector3(-4.45, 0.9, -0.6), Vector3.UP)
	light_door_right.look_at_from_position(Vector3(3.55, 2.25, -0.6), Vector3(4.45, 0.9, -0.6), Vector3.UP)


## Ajustes de luz que evitan manchas y rayas en las paredes con el renderer Compatibility.
func _fix_lighting() -> void:
	# La luz del techo con sombras omnidireccionales generaba rayas (shadow acne) en las paredes.
	room_light.shadow_enabled = false
	# La lampara de escritorio apuntaba a la pared de enfrente (mancha de luz con sombras duras).
	# Ahora ilumina el escritorio, como una lampara de banquero real.
	office_lamp.look_at_from_position(office_lamp.position, Vector3(0.25, 0.76, -0.75), Vector3.FORWARD)
	for l in [office_lamp, light_door_left, light_door_right]:
		l.shadow_bias = 0.06
		l.shadow_normal_bias = 1.5


## Pasillos detras de cada reja: antes la puerta daba al vacio y el suelo se cortaba.
## Quedan a oscuras; solo los alumbra la luz de puerta (Q / E).
func _build_hallways() -> void:
	var wall_mat: Material = ($Room/WallLeft as CSGBox3D).material
	var floor_mat: Material = ($Room/Floor as CSGBox3D).material
	for sx in [-1.0, 1.0]:
		var hall := Node3D.new()
		hall.name = "HallwayLeft" if sx < 0.0 else "HallwayRight"
		add_child(hall)
		var cx: float = sx * 6.5            # de la cara exterior del muro (x = 4.0) a x = 9.0
		var cz: float = -0.6                # centro de la puerta
		# El suelo empieza donde acaba el de la oficina (x = 4.25) para no solaparse con el.
		_add_box(hall, Vector3(4.75, 0.2, 2.2), Vector3(sx * 6.625, -0.1, cz), floor_mat) # suelo
		_add_box(hall, Vector3(5.0, 0.2, 2.2), Vector3(cx, 2.7, cz), wall_mat)            # techo
		_add_box(hall, Vector3(5.0, 2.8, 0.2), Vector3(cx, 1.3, cz - 1.0), wall_mat)      # pared
		_add_box(hall, Vector3(5.0, 2.8, 0.2), Vector3(cx, 1.3, cz + 1.0), wall_mat)      # pared
		_add_box(hall, Vector3(0.2, 2.8, 2.2), Vector3(sx * 9.0, 1.3, cz), wall_mat)     # fondo
		# Luz de emergencia muy tenue al fondo (no ilumina a los monstruos: capa 2 excluida).
		var exit_light := OmniLight3D.new()
		exit_light.light_color = Color(0.9, 0.25, 0.15)
		exit_light.light_energy = 0.25
		exit_light.omni_range = 3.0
		exit_light.position = Vector3(sx * 8.6, 2.3, cz)
		exit_light.light_cull_mask = exit_light.light_cull_mask & ~MonsterFactory.MONSTER_LAYER
		hall.add_child(exit_light)


## Ducto detras de la rejilla de ventilacion de la pared de enfrente (antes era un hueco al vacio).
func _build_vent_duct() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.23, 0.25)
	mat.metallic = 0.7
	mat.roughness = 0.45
	var duct := Node3D.new()
	duct.name = "VentDuct"
	add_child(duct)
	_add_box(duct, Vector3(1.4, 0.1, 1.6), Vector3(0.0, 2.15, -4.8), mat)    # suelo
	_add_box(duct, Vector3(1.4, 0.1, 1.6), Vector3(0.0, 3.05, -4.8), mat)    # techo
	_add_box(duct, Vector3(0.1, 1.0, 1.6), Vector3(-0.7, 2.6, -4.8), mat)    # lados
	_add_box(duct, Vector3(0.1, 1.0, 1.6), Vector3(0.7, 2.6, -4.8), mat)
	_add_box(duct, Vector3(1.4, 1.0, 0.1), Vector3(0.0, 2.6, -5.6), mat)     # fondo
	# Lamas de la rejilla
	for i in 4:
		_add_box(duct, Vector3(1.2, 0.025, 0.04), Vector3(0.0, 2.3 + i * 0.18, -3.82), mat)


func _add_box(parent: Node, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## Sustituye la placa solida de la reja por barrotes de ascensor tipo acordeon,
## para que se vea al monstruo detras cuando la reja esta cerrada.
func _build_gate_bars(gate: Node3D) -> void:
	var mat: Material = null
	for child in gate.get_children():
		if child is CSGBox3D:
			mat = (child as CSGBox3D).material
			(child as CSGBox3D).visible = false

	var bar_mesh := CylinderMesh.new()
	bar_mesh.top_radius = 0.018
	bar_mesh.bottom_radius = 0.018
	bar_mesh.height = 2.4
	bar_mesh.radial_segments = 8
	bar_mesh.rings = 1
	for i in 11:
		var bar := MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.material_override = mat
		bar.position = Vector3(0.0, 0.0, lerpf(-0.72, 0.72, float(i) / 10.0))
		gate.add_child(bar)

	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(0.05, 0.07, 1.5)
	for y in [-1.15, -0.38, 0.38, 1.15]:
		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.material_override = mat
		rail.position = Vector3(0.0, y, 0.0)
		gate.add_child(rail)

	# Tijeras diagonales entre travesanos
	var diag_mesh := BoxMesh.new()
	diag_mesh.size = Vector3(0.022, 0.022, 0.8)
	for yc in [-0.765, 0.0, 0.765]:
		for k in 5:
			for sgn in [-1.0, 1.0]:
				var d := MeshInstance3D.new()
				d.mesh = diag_mesh
				d.material_override = mat
				d.position = Vector3(0.0, yc, lerpf(-0.56, 0.56, float(k) / 4.0))
				d.rotation = Vector3(sgn * deg_to_rad(58.0), 0.0, 0.0)
				gate.add_child(d)


func _setup_props() -> void:
	# Cargar y calibrar los modelos descargados por Mateo
	
	# 1. ESCRITORIO
	if ResourceLoader.exists("res://assets/3d/office/desk.glb"):
		var desk_scene = load("res://assets/3d/office/desk.glb") as PackedScene
		if desk_scene:
			_hide_placeholders(desk_anchor)
			var inst = desk_scene.instantiate() as Node3D
			inst.scale = Vector3(0.85, 0.85, 0.85)
			inst.position = Vector3(0.0, 0.0, 0.0)
			desk_anchor.add_child(inst)

	# 2. MONITOR CRT
	if ResourceLoader.exists("res://assets/3d/office/monitor.glb"):
		var mon_scene = load("res://assets/3d/office/monitor.glb") as PackedScene
		if mon_scene:
			_hide_placeholders(monitor_anchor)
			var inst = mon_scene.instantiate() as Node3D
			inst.scale = Vector3(0.18, 0.18, 0.18)
			inst.rotation_degrees = Vector3(0.0, 180.0, 0.0)
			inst.position = Vector3(0.0, 0.0, 0.0)
			monitor_anchor.add_child(inst)

	# 3. LÁMPARA DE BANQUERO
	if ResourceLoader.exists("res://assets/3d/office/lamp.glb"):
		var lamp_scene = load("res://assets/3d/office/lamp.glb") as PackedScene
		if lamp_scene:
			_hide_placeholders(lamp_anchor)
			var inst = lamp_scene.instantiate() as Node3D
			inst.scale = Vector3(0.012, 0.012, 0.012)
			inst.position = Vector3(0.0, 0.0, 0.0)
			lamp_anchor.add_child(inst)

	# 4. SILLA DE OFICINA
	if chair_anchor and ResourceLoader.exists("res://assets/3d/office/chair.glb"):
		var chair_scene = load("res://assets/3d/office/chair.glb") as PackedScene
		if chair_scene:
			_hide_placeholders(chair_anchor)
			var inst = chair_scene.instantiate() as Node3D
			inst.scale = Vector3(0.55, 0.55, 0.55)
			inst.rotation_degrees = Vector3(0.0, 180.0, 0.0)
			inst.position = Vector3(0.0, 0.0, 0.0)
			chair_anchor.add_child(inst)
	# Los monstruos se crean en _setup_monsters() con MonsterFactory
	# (usa assets/3d/monsters/<key>.glb si existe, si no el modelo de primitivas).


func _hide_placeholders(anchor: Node) -> void:
	for child in anchor.get_children():
		if child is MeshInstance3D or child is CSGShape3D:
			child.visible = false
