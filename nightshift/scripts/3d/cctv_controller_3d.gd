extends Node3D
## Controlador del Sistema Multicámara 3D (CCTV).
## Gestiona las 7 salas de vigilancia del hotel (Dioramas 3D independientes),
## la conmutación de cámaras de seguridad, flash en salas oscuras,
## efectos de caldera/jazz y anclajes de monstruos.

var night = null

# Diccionario de cámaras 3D (1 a 7)
var cam_nodes: Dictionary = {}
var current_cam_id: int = -1

# Luces de flash en cámaras oscuras (Cam 4, 5, 6)
@onready var flash_cam4: SpotLight3D = $Room_Cam04/FlashLight4
@onready var flash_cam5: SpotLight3D = $Room_Cam05/FlashLight5
@onready var flash_cam6: SpotLight3D = $Room_Cam06/FlashLight6

# Elementos dinámicos de salas
@onready var boiler_fire: OmniLight3D = $Room_Cam06/BoilerLight
@onready var vent_heat: OmniLight3D = $Room_Cam07/VentHeatLight
@onready var speaker_light: OmniLight3D = $Room_Cam03/SpeakerJazzLight

# Anclajes de monstruos por sala
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
		var cam_path = "Room_Cam%02d/Camera3D" % id
		if has_node(cam_path):
			var cam = get_node(cam_path) as Camera3D
			cam_nodes[id] = cam
			cam.current = false
	
	_check_and_load_room_models()


func _process(delta: float) -> void:
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

	# 6. Actualizar visibilidad de monstruos en las cámaras
	_update_monsters_in_cctv()


func _switch_to_camera(id: int) -> void:
	current_cam_id = id
	for c_id in cam_nodes.keys():
		var cam: Camera3D = cam_nodes[c_id]
		var is_target: bool = (c_id == id)
		cam.current = is_target
		if is_target and not cam.has_meta("base_rot_y"):
			cam.set_meta("base_rot_y", cam.rotation.y)


func _update_monsters_in_cctv() -> void:
	# Visibilidad de La Mucama en conductos o calderas
	var mucama_in_cam6: bool = false
	var mucama_in_vent: bool = false
	var mucama_progress: float = 0.0

	for m in night.monsters:
		if m.name == "La Mucama":
			if m.stage == 1:
				mucama_in_cam6 = true
			elif m.stage == 2:
				mucama_in_vent = true
				if "progress" in m:
					mucama_progress = m.progress
			break

	if anchor_mucama_cam6:
		anchor_mucama_cam6.visible = mucama_in_cam6
	if anchor_mucama_vent:
		anchor_mucama_vent.visible = mucama_in_vent
		# Avanzar por el túnel hacia la cámara
		anchor_mucama_vent.position.z = lerpf(-4.0, -0.8, mucama_progress)

	# Visibilidad del Chef en Cocina (CAM 03)
	var chef_in_kitchen: bool = false
	for m in night.monsters:
		if m.name == "El Chef":
			chef_in_kitchen = (m.stage == 0) # En cocina esperando
			break
	if anchor_chef:
		anchor_chef.visible = chef_in_kitchen

	# Destello de Cornelius en cámaras oscuras (CAM 4, 5, 6)
	var cornelius_cam: int = 0
	for m in night.monsters:
		if m.name == "Cornelius":
			if "target_cam" in m:
				cornelius_cam = m.target_cam
			break

	if anchor_cornelius_cam4:
		anchor_cornelius_cam4.visible = (cornelius_cam == 4)
	if anchor_cornelius_cam5:
		anchor_cornelius_cam5.visible = (cornelius_cam == 5)
	if anchor_cornelius_cam6:
		anchor_cornelius_cam6.visible = (cornelius_cam == 6)


func _check_and_load_room_models() -> void:
	# Carga automática si Mateo guarda modelos para las salas
	_try_load_glb("res://assets/3d/cams/lobby.glb", $Room_Cam01/Props)
	_try_load_glb("res://assets/3d/cams/reception.glb", $Room_Cam02/Props)
	_try_load_glb("res://assets/3d/cams/kitchen.glb", $Room_Cam03/Props)
	_try_load_glb("res://assets/3d/cams/boiler.glb", $Room_Cam06/Props)
	_try_load_glb("res://assets/3d/monsters/chef.glb", anchor_chef)
	_try_load_glb("res://assets/3d/monsters/mucama.glb", anchor_mucama_cam6)


func _try_load_glb(path: String, target: Node) -> void:
	if target and ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		if scene:
			for child in target.get_children():
				if child is MeshInstance3D or child is CSGShape3D:
					child.visible = false
			var inst = scene.instantiate()
			target.add_child(inst)
