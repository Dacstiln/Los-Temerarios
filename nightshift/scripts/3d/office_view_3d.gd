extends SubViewportContainer
## Envoltorio 3D compatible con la arquitectura de night.gd.
## Es el Control que night.gd usa como vista de oficina (office_view)
## pero renderiza un mundo 3D inmersivo en tiempo real con SubViewport.

const OFFICE_3D_SCENE = preload("res://scenes/3d/office_3d.tscn")

var night = null:
	set(val):
		night = val
		if office_3d_instance != null:
			office_3d_instance.night = val

var sub_viewport: SubViewport
var office_3d_instance: Node3D


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

	office_3d_instance = OFFICE_3D_SCENE.instantiate()
	sub_viewport.add_child(office_3d_instance)


func _ready() -> void:
	if night != null and office_3d_instance != null:
		office_3d_instance.night = night
