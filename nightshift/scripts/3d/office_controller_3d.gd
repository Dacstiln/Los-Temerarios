extends Node3D
## Controlador del Entorno 3D de la Oficina.
## Maneja: Rotación de cámara tipo FNAF, iluminación en tiempo real,
## rejas mecánicas 3D animadas y puntos de anclaje para modelos GLB externos.

var night = null

# --- Nodos de Cámara y Vista ---
@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight

# --- Nodos de Rejas 3D ---
@onready var gate_left: Node3D = $Gates/GateLeft
@onready var gate_right: Node3D = $Gates/GateRight

# --- Nodos de Iluminación 3D ---
@onready var office_lamp: SpotLight3D = $Lights/DeskLampLight
@onready var room_light: OmniLight3D = $Lights/RoomCeilingLight
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
const GATE_Y_OPEN: float = 3.2
const GATE_Y_CLOSED: float = 1.15
var gate_y_left: float = GATE_Y_OPEN
var gate_y_right: float = GATE_Y_OPEN


func _ready() -> void:
	_setup_props()


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
		office_lamp.light_energy = 0.0
		room_light.light_energy = 0.0
		light_door_left.light_energy = 0.0
		light_door_right.light_energy = 0.0
		flashlight.light_energy = 0.0
		vent_light.light_energy = 0.0
	else:
		# Parpadeo sutil en la lámpara verde
		var flicker: float = 1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.035
		office_lamp.light_energy = 2.2 * flicker
		room_light.light_energy = 0.4

		# Flash (F)
		flashlight.light_energy = 3.8 if (night.flash_time > 0.0) else 0.0

		# Luces en puertas
		light_door_left.light_energy = 1.4 if (night.flash_time > 0.0 and current_yaw > 0.25) else 0.12
		light_door_right.light_energy = 1.4 if (night.flash_time > 0.0 and current_yaw < -0.25) else 0.12

		# Resplandor de caldera
		vent_light.light_energy = night.boiler_glow * 3.0 if night.boiler_glow > 0.0 else 0.0

	# 4. Monstruos en oficina
	_update_monsters_in_office()


func _update_monsters_in_office() -> void:
	var botones_side: String = ""
	for m in night.monsters:
		if m.name == "El Botones" and m.stage == 2:
			botones_side = m.side
			break
	
	monster_left_anchor.visible = (botones_side == "left")
	monster_right_anchor.visible = (botones_side == "right")

	var mucama_in_vent: bool = false
	for m in night.monsters:
		if m.name == "La Mucama" and m.stage == 2:
			mucama_in_vent = true
			break
	monster_vent_anchor.visible = mucama_in_vent


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
			inst.rotation_degrees = Vector3(0.0, 180.0, 0.0) # Orientar pantalla hacia el guardia
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


func _hide_placeholders(anchor: Node) -> void:
	for child in anchor.get_children():
		if child is MeshInstance3D or child is CSGShape3D:
			child.visible = false
