extends SubViewportContainer
## Envoltorio 3D para el sistema de cámaras CCTV.
## Es el Control que night.gd usa como vista de camaras (camera_view)
## y renderiza en tiempo real las 7 salas 3D con cámaras de seguridad dinámicas.

const CCTV_3D_SCENE = preload("res://scenes/3d/cctv_3d.tscn")

var night = null:
	set(val):
		night = val
		if cctv_instance != null:
			cctv_instance.night = val

var sub_viewport: SubViewport
var cctv_instance: Node3D
var blind_overlay: ColorRect
var blind_label: Label


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2i(1280, 720)
	# Mundo 3D propio: si no, la oficina y las 7 salas de camaras comparten el mismo
	# mundo y se ven unas dentro de otras (el Lobby esta en el mismo origen que la oficina).
	sub_viewport.own_world_3d = true
	sub_viewport.handle_input_locally = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE   # solo se dibuja la vista que se esta viendo
	add_child(sub_viewport)

	cctv_instance = CCTV_3D_SCENE.instantiate()
	sub_viewport.add_child(cctv_instance)

	# Capa de "SIN SEÑAL" para cámaras dañadas/ciegas por Cornelius
	blind_overlay = ColorRect.new()
	blind_overlay.color = Color(0.03, 0.03, 0.04, 0.97)
	blind_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blind_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blind_overlay.visible = false
	add_child(blind_overlay)

	blind_label = Label.new()
	blind_label.text = "SIN SEÑAL\n[CÁMARA FUERA DE SERVICIO]"
	blind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blind_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	blind_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blind_label.add_theme_font_size_override("font_size", 40)
	blind_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.75))
	blind_overlay.add_child(blind_label)


func _ready() -> void:
	if night != null and cctv_instance != null:
		cctv_instance.night = night


func _process(_delta: float) -> void:
	if night == null:
		return
	var cam: int = night.current_cam
	var is_blind: bool = false
	if night.cams.has(cam) and night.cams[cam].is_blind():
		is_blind = true
	blind_overlay.visible = is_blind
