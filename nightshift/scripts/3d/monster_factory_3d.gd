extends RefCounted
## Crea el modelo 3D de cada monstruo a partir de su "key" (la misma que usan
## los scripts de scripts/monsters/: "botones", "chef", "mucama", "cornelius", "bailarina").
##
## Prioridad:
##   1. res://assets/3d/monsters/<key>.glb  -> si alguien exporta un modelo propio (Blender,
##      Sketchfab...) con ese nombre, se usa automaticamente. Debe mirar a +Z y medir en metros.
##   2. res://scenes/3d/monsters/<key>_3d.tscn -> modelo hecho con primitivas (editable en Godot).

const GLB_DIR: String = "res://assets/3d/monsters/"
const SCENE_DIR: String = "res://scenes/3d/monsters/"

## Capa visual de los monstruos en la oficina: la luz del techo y la lampara no los
## iluminan, solo las luces de puerta (Q / E), el flash y la caldera.
const MONSTER_LAYER: int = 2


static func create(key: String) -> Node3D:
	var glb_path: String = GLB_DIR + key + ".glb"
	if ResourceLoader.exists(glb_path):
		var glb := load(glb_path) as PackedScene
		if glb != null:
			var inst := glb.instantiate() as Node3D
			if inst != null:
				return inst
	var scene_path: String = SCENE_DIR + key + "_3d.tscn"
	if ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene != null:
			return scene.instantiate() as Node3D
	push_warning("MonsterFactory: no hay modelo 3D para '%s'" % key)
	return null


## Brillo de ojos (0 = apagados). Solo afecta a los modelos con monster_rig_3d.gd.
static func set_glow(model: Node, value: float) -> void:
	if model != null and model.has_method("set_glow"):
		model.set_glow(value)


static func set_head_pitch(model: Node, radians: float) -> void:
	if model != null and model.has_method("set_head_pitch"):
		model.set_head_pitch(radians)


static func set_spin(model: Node, rad_per_sec: float) -> void:
	if model != null and model.has_method("set_spin"):
		model.set_spin(rad_per_sec)


## Pone todas las mallas del modelo en una capa visual concreta (mascara de bits).
static func set_layers(model: Node, layer_mask: int) -> void:
	if model is VisualInstance3D:
		(model as VisualInstance3D).layers = layer_mask
	for child in model.get_children():
		set_layers(child, layer_mask)
