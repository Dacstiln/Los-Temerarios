extends Node3D
## Decoracion de las 7 salas de camaras (CCTV): muebles, paredes, objetos y detalles de terror.
##
## Todo se arma con mallas primitivas compartidas al iniciar la noche (no se carga ningun
## archivo), asi que casi no suma tiempo de carga. Solo se dibuja la decoracion de la sala
## que se esta viendo. Las zonas donde aparecen los monstruos (ROOM_SPOTS en
## cctv_controller_3d.gd) se dejan libres, y las camaras oscuras (4, 5, 6) siguen oscuras:
## la decoracion de esas salas solo se ve bien con el Flash.
##
## Uso (desde cctv_controller_3d.gd):  decor.build(self, _rooms, $WorldEnvironment)

const TILE_SHADER = preload("res://shaders/tile.gdshader")

var ctrl = null                       # cctv_controller_3d.gd (para leer night y las camaras)
var _rooms: Dictionary = {}           # id -> Node3D de la sala
var _decor: Dictionary = {}           # id -> Node3D con la decoracion de esa sala
var _mats: Dictionary = {}
var _meshes: Dictionary = {}
var _active: int = -1
var _t: float = 0.0

# Elementos animados
var _swingers: Array = []             # [{node, axis, amp, speed, phase, room}]
var _flickers: Array = []             # [{mat, base_e, light, base_l, mode, off, room}]
var _needles: Array = []              # [{node, base, room}]


func build(controller, rooms: Dictionary, world_env: WorldEnvironment) -> void:
	ctrl = controller
	_rooms = rooms
	_setup_fog(world_env)
	for id in _rooms.keys():
		var d := Node3D.new()
		d.name = "Decor"
		_rooms[id].add_child(d)
		_decor[id] = d
	if _decor.has(1): _build_lobby(_decor[1], _rooms[1])
	if _decor.has(2): _build_reception(_decor[2])
	if _decor.has(3): _build_kitchen(_decor[3], _rooms[3])
	if _decor.has(4): _build_corridor(_decor[4], 4)
	if _decor.has(5): _build_corridor(_decor[5], 5)
	if _decor.has(6): _build_boiler(_decor[6])
	if _decor.has(7): _build_duct(_decor[7])
	for id in _decor.keys():
		_decor[id].visible = false


func _setup_fog(we: WorldEnvironment) -> void:
	if we == null or we.environment == null:
		return
	var env: Environment = we.environment
	env.fog_enabled = true
	env.fog_light_color = Color(0.035, 0.035, 0.04)
	env.fog_light_energy = 1.0
	env.fog_density = 0.045
	env.fog_sky_affect = 0.0


# ================================================================ animacion

func _process(delta: float) -> void:
	_t += delta
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var id: int = -1
	if ctrl != null and cam != null:
		for k in ctrl.cam_nodes.keys():
			if ctrl.cam_nodes[k] == cam:
				id = k
				break
	if id != _active:
		_active = id
		for k in _decor.keys():
			_decor[k].visible = (k == id)
	if _active < 0:
		return

	for s in _swingers:
		if s["room"] != _active:
			continue
		var n: Node3D = s["node"]
		var a: float = sin(_t * float(s["speed"]) + float(s["phase"])) * float(s["amp"])
		n.rotation = s["base"] + Vector3(s["axis"]) * a

	var boiler_hot: bool = ctrl != null and ctrl.night != null and float(ctrl.night.boiler_glow) > 0.0
	for g in _needles:
		if g["room"] != _active:
			continue
		var jitter: float = sin(_t * 23.0 + float(g["base"]) * 10.0) * 0.04 + sin(_t * 3.1) * 0.08
		var target: float = float(g["base"]) - (1.6 if boiler_hot else 0.0)
		g["node"].rotation.z = lerpf(g["node"].rotation.z, target + jitter, delta * 4.0)

	for f in _flickers:
		if f["room"] != _active:
			continue
		var k: float = 1.0
		if f["mode"] == "buzz":
			if f["off"] > 0.0:
				f["off"] -= delta
				k = 0.08
			elif randf() < delta * 0.9:
				f["off"] = randf_range(0.04, 0.22)
				k = 0.08
			else:
				k = 0.92 + 0.08 * sin(_t * 90.0)
		else:
			k = 1.0 + 0.07 * sin(_t * 6.3 + float(f["seed"])) + 0.05 * sin(_t * 15.1 + float(f["seed"]) * 2.0)
			if randf() < delta * 0.25:
				k = 0.45
		if f["mat"] != null:
			f["mat"].emission_energy_multiplier = float(f["base_e"]) * k
		if f["light"] != null:
			f["light"].light_energy = float(f["base_l"]) * k


func _swing(n: Node3D, room: int, axis: Vector3, amp_deg: float, speed: float) -> void:
	_swingers.append({"node": n, "room": room, "axis": axis, "amp": deg_to_rad(amp_deg),
		"speed": speed, "phase": randf() * TAU, "base": n.rotation})


func _flicker(room: int, mat, light, mode: String = "gentle") -> void:
	_flickers.append({"room": room, "mat": mat, "light": light, "mode": mode, "off": 0.0,
		"seed": randf() * 10.0,
		"base_e": mat.emission_energy_multiplier if mat != null else 0.0,
		"base_l": light.light_energy if light != null else 0.0})


# ================================================================ materiales y mallas

func _m(key: String, color: Color, rough: float = 0.6, metal: float = 0.0,
		emis: Color = Color.BLACK, emis_e: float = 0.0, unique: bool = false) -> StandardMaterial3D:
	if not unique and _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emis_e > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = emis_e
	if not unique:
		_mats[key] = m
	return m


func _tile(key: String, a: Color, b: Color, grout_col: Color, tiles: Vector2, grout: float,
		checker: bool = false, brick: bool = false, dirt: float = 0.35, rough: float = 0.5) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = TILE_SHADER
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", b)
	m.set_shader_parameter("grout_color", grout_col)
	m.set_shader_parameter("tiles", tiles)
	m.set_shader_parameter("grout", grout)
	m.set_shader_parameter("checker", checker)
	m.set_shader_parameter("brick_offset", brick)
	m.set_shader_parameter("dirt", dirt)
	m.set_shader_parameter("tile_roughness", rough)
	_mats[key] = m
	return m


# Paleta comun
func gold() -> StandardMaterial3D: return _m("gold", Color(0.62, 0.48, 0.2), 0.35, 0.8)
func gold_dim() -> StandardMaterial3D: return _m("gold_dim", Color(0.36, 0.28, 0.13), 0.5, 0.6)
func brass() -> StandardMaterial3D: return _m("brass", Color(0.48, 0.36, 0.15), 0.45, 0.75)
func wood_dark() -> StandardMaterial3D: return _m("wood_dark", Color(0.075, 0.045, 0.028), 0.55)
func wood_panel() -> StandardMaterial3D: return _m("wood_panel", Color(0.12, 0.072, 0.042), 0.5)
func wood_mid() -> StandardMaterial3D: return _m("wood_mid", Color(0.2, 0.12, 0.07), 0.55)
func black() -> StandardMaterial3D: return _m("black", Color(0.015, 0.015, 0.017), 0.8)
func void_mat() -> StandardMaterial3D:
	if _mats.has("void"):
		return _mats["void"]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0, 0, 0)
	_mats["void"] = m
	return m
func cream() -> StandardMaterial3D: return _m("cream", Color(0.52, 0.48, 0.38), 0.7)
func sheet() -> StandardMaterial3D: return _m("sheet", Color(0.3, 0.3, 0.29), 0.95)
func steel() -> StandardMaterial3D: return _m("steel", Color(0.48, 0.5, 0.53), 0.35, 0.8)
func iron() -> StandardMaterial3D: return _m("iron", Color(0.11, 0.11, 0.12), 0.55, 0.7)
func rust() -> StandardMaterial3D: return _m("rust", Color(0.24, 0.11, 0.06), 0.85, 0.35)
func copper() -> StandardMaterial3D: return _m("copper", Color(0.42, 0.2, 0.11), 0.4, 0.8)
func velvet() -> StandardMaterial3D: return _m("velvet", Color(0.28, 0.025, 0.045), 0.85)
func leather() -> StandardMaterial3D: return _m("leather", Color(0.2, 0.11, 0.06), 0.6)
func paper() -> StandardMaterial3D: return _m("paper", Color(0.55, 0.52, 0.44), 0.9)
func blood() -> StandardMaterial3D: return _m("blood", Color(0.09, 0.008, 0.008), 0.15)
func canvas_mat() -> StandardMaterial3D: return _m("canvas", Color(0.09, 0.07, 0.055), 0.9)
func dead_plant() -> StandardMaterial3D: return _m("plant", Color(0.15, 0.1, 0.05), 0.9)
func glass_dark() -> StandardMaterial3D: return _m("glass_dark", Color(0.04, 0.05, 0.06), 0.05, 0.3)


func _cached(key: String) -> Mesh:
	return _meshes.get(key)


func _add(p: Node, mesh: Mesh, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(mi)
	return mi


func _box(p: Node, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key: String = "b%s" % size
	var mesh: Mesh = _cached(key)
	if mesh == null:
		var b := BoxMesh.new()
		b.size = size
		mesh = b
		_meshes[key] = mesh
	return _add(p, mesh, pos, mat, rot)


func _cyl(p: Node, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO, seg: int = 14) -> MeshInstance3D:
	var key: String = "c%s_%s_%s_%d" % [r_top, r_bot, h, seg]
	var mesh: Mesh = _cached(key)
	if mesh == null:
		var c := CylinderMesh.new()
		c.top_radius = r_top
		c.bottom_radius = r_bot
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		mesh = c
		_meshes[key] = mesh
	return _add(p, mesh, pos, mat, rot)


func _sph(p: Node, r: float, pos: Vector3, mat: Material, scl: Vector3 = Vector3.ONE,
		hemi: bool = false) -> MeshInstance3D:
	var key: String = "s%s_%s" % [r, hemi]
	var mesh: Mesh = _cached(key)
	if mesh == null:
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r if hemi else r * 2.0
		sm.is_hemisphere = hemi
		sm.radial_segments = 12
		sm.rings = 6
		mesh = sm
		_meshes[key] = mesh
	return _add(p, mesh, pos, mat, Vector3.ZERO, scl)


func _torus(p: Node, inner: float, outer: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key: String = "t%s_%s" % [inner, outer]
	var mesh: Mesh = _cached(key)
	if mesh == null:
		var t := TorusMesh.new()
		t.inner_radius = inner
		t.outer_radius = outer
		t.rings = 16
		t.ring_segments = 6
		mesh = t
		_meshes[key] = mesh
	return _add(p, mesh, pos, mat, rot)


## Quad que mira a +Z (rotar para paredes: y=90 mira a +X, y=-90 a -X, x=-90 mira arriba (piso) / x=90 abajo (techo)).
func _quad(p: Node, size: Vector2, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key: String = "q%s" % size
	var mesh: Mesh = _cached(key)
	if mesh == null:
		var q := QuadMesh.new()
		q.size = size
		mesh = q
		_meshes[key] = mesh
	return _add(p, mesh, pos, mat, rot)


func _label(p: Node, text: String, pos: Vector3, rot: Vector3, font_size: int, color: Color,
		px: float = 0.004) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = px
	l.modulate = color
	l.outline_size = 0
	l.shaded = true
	l.position = pos
	l.rotation_degrees = rot
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(l)
	return l


func _omni(p: Node, pos: Vector3, color: Color, energy: float, rng: float) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.position = pos
	o.light_color = color
	o.light_energy = energy
	o.omni_range = rng
	o.shadow_enabled = false
	p.add_child(o)
	return o


func _node(p: Node, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees = rot
	p.add_child(n)
	return n


## Polvo flotando en el aire (o brasas si `ember`).
func _particles(p: Node, pos: Vector3, extents: Vector3, amount: int, ember: bool = false) -> void:
	var ps := CPUParticles3D.new()
	ps.position = pos
	ps.amount = amount
	ps.lifetime = 2.6 if ember else 9.0
	ps.preprocess = ps.lifetime
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = extents
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 25.0 if ember else 180.0
	ps.initial_velocity_min = 0.25 if ember else 0.01
	ps.initial_velocity_max = 0.6 if ember else 0.06
	ps.gravity = Vector3(0, 0.15, 0) if ember else Vector3(0, -0.008, 0)
	ps.scale_amount_min = 0.5
	ps.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.03) if ember else Vector2(0.018, 0.018)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.45, 0.1, 0.9) if ember else Color(0.9, 0.82, 0.65, 0.22)
	q.material = m
	ps.mesh = q
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(ps)


# ================================================================ piezas reutilizables

## Paredes de hotel: zoclo, lambrin de madera con paneles, moldura dorada, papel tapiz a rayas
## y cornisa. `back_z` / `left_x` = cara interior de cada pared; `half` = medio ancho de la sala.
func _hotel_walls(d: Node3D, back_z: float, left_x: float, half: float, ceil_y: float, paper: Material) -> void:
	var w: float = half * 2.0 - 0.1
	var paper_h: float = ceil_y - 1.15
	# Fondo
	_quad(d, Vector2(w, paper_h), Vector3(0, 1.15 + paper_h * 0.5, back_z + 0.01), paper)
	_box(d, Vector3(w, 1.15, 0.05), Vector3(0, 0.575, back_z + 0.025), wood_dark())
	_box(d, Vector3(w, 0.05, 0.07), Vector3(0, 1.15, back_z + 0.035), gold_dim())
	_box(d, Vector3(w, 0.12, 0.08), Vector3(0, ceil_y - 0.06, back_z + 0.04), gold_dim())
	_box(d, Vector3(w, 0.12, 0.07), Vector3(0, 0.06, back_z + 0.035), black())
	var n: int = int(w / 1.2)
	for i in n:
		var x: float = -w * 0.5 + (float(i) + 0.5) * w / float(n)
		_box(d, Vector3(w / float(n) - 0.3, 0.65, 0.03), Vector3(x, 0.58, back_z + 0.06), wood_panel())
	# Izquierda
	_quad(d, Vector2(w, paper_h), Vector3(left_x + 0.01, 1.15 + paper_h * 0.5, 0), paper, Vector3(0, 90, 0))
	_box(d, Vector3(0.05, 1.15, w), Vector3(left_x + 0.025, 0.575, 0), wood_dark())
	_box(d, Vector3(0.07, 0.05, w), Vector3(left_x + 0.035, 1.15, 0), gold_dim())
	_box(d, Vector3(0.08, 0.12, w), Vector3(left_x + 0.04, ceil_y - 0.06, 0), gold_dim())
	_box(d, Vector3(0.07, 0.12, w), Vector3(left_x + 0.035, 0.06, 0), black())
	for i in n:
		var z: float = -w * 0.5 + (float(i) + 0.5) * w / float(n)
		_box(d, Vector3(0.03, 0.65, w / float(n) - 0.3), Vector3(left_x + 0.06, 0.58, z), wood_panel())


func _paper(key: String, base: Color, stripes: int) -> ShaderMaterial:
	return _tile(key, base, base, Color(0.3, 0.23, 0.1), Vector2(float(stripes), 1.0), 0.03, false, false, 0.45, 0.8)


## Cuadro con marco dorado. `face` = direccion a la que mira (+Z por defecto).
func _painting(d: Node3D, pos: Vector3, rot: Vector3, w: float, h: float, creepy: bool = false) -> Node3D:
	var n := _node(d, pos, rot)
	_box(n, Vector3(w, h, 0.05), Vector3.ZERO, gold_dim())
	_box(n, Vector3(w - 0.12, h - 0.12, 0.02), Vector3(0, 0, 0.022), canvas_mat())
	if creepy:
		# Retrato: silueta palida con los ojos tachados.
		_sph(n, 0.12, Vector3(0, h * 0.12, 0.035), _m("portrait", Color(0.3, 0.26, 0.22), 0.9), Vector3(0.8, 1.0, 0.15))
		_box(n, Vector3(w * 0.55, h * 0.3, 0.01), Vector3(0, -h * 0.22, 0.035), _m("portrait_suit", Color(0.05, 0.04, 0.035), 0.9))
		_box(n, Vector3(0.16, 0.025, 0.01), Vector3(0, h * 0.14, 0.05), black())
	else:
		_box(n, Vector3(w - 0.12, (h - 0.12) * 0.45, 0.01), Vector3(0, -h * 0.15, 0.035), _m("landscape", Color(0.06, 0.08, 0.06), 0.9))
	return n


## Planta seca en maceta.
func _dead_plant(d: Node3D, pos: Vector3) -> void:
	var n := _node(d, pos)
	_cyl(n, 0.28, 0.2, 0.55, Vector3(0, 0.275, 0), _m("terracotta", Color(0.25, 0.12, 0.07), 0.85))
	_cyl(n, 0.25, 0.25, 0.02, Vector3(0, 0.54, 0), _m("soil", Color(0.04, 0.03, 0.02), 1.0))
	for i in 7:
		var a: float = float(i) * 51.0
		var tilt: float = 25.0 + float(i % 3) * 22.0
		var leaf := _node(n, Vector3(0, 0.55, 0), Vector3(0, a, 0))
		_box(leaf, Vector3(0.05, 0.8, 0.1), Vector3(0, 0.4, 0), dead_plant(), Vector3(tilt, 0, 0)).position = Vector3(0, 0.36, sin(deg_to_rad(tilt)) * 0.4)


## Maleta (caja con asa).
func _suitcase(d: Node3D, pos: Vector3, size: Vector3, mat: Material, rot_y: float = 0.0) -> void:
	var n := _node(d, pos, Vector3(0, rot_y, 0))
	_box(n, size, Vector3(0, size.y * 0.5, 0), mat)
	_box(n, Vector3(size.x + 0.01, 0.03, size.z + 0.01), Vector3(0, size.y * 0.5, 0), brass())
	_box(n, Vector3(0.16, 0.04, 0.03), Vector3(0, size.y + 0.02, 0), black())


# ================================================================ CAM 01 - Vestibulo

func _build_lobby(d: Node3D, room: Node3D) -> void:
	_quad(d, Vector2(8, 8), Vector3(0, 0.002, 0),
		_tile("marble", Color(0.05, 0.05, 0.06), Color(0.2, 0.19, 0.17), Color(0.03, 0.03, 0.03), Vector2(10, 10), 0.015, true, false, 0.5, 0.25),
		Vector3(-90, 0, 0))
	_hotel_walls(d, -3.8, -3.8, 4.0, 3.9, _paper("paper_lobby", Color(0.15, 0.035, 0.045), 22))

	# Borde dorado de la alfombra
	for z in [-2.71, 2.71]:
		_box(d, Vector3(4.5, 0.022, 0.08), Vector3(0, 0.012, z), gold_dim())
	for x in [-2.21, 2.21]:
		_box(d, Vector3(0.08, 0.022, 5.5), Vector3(x, 0.012, 0), gold_dim())

	# Abanico Art Deco en la pared del fondo
	var fan := _node(d, Vector3(0, 2.05, -3.74))
	for i in 9:
		var a: float = -60.0 + float(i) * 15.0
		var dir := Vector2(sin(deg_to_rad(a)), cos(deg_to_rad(a)))
		_box(fan, Vector3(0.04, 1.1, 0.02), Vector3(dir.x * 0.6, dir.y * 0.6, 0), gold(), Vector3(0, 0, -a))
	_cyl(fan, 0.22, 0.22, 0.03, Vector3.ZERO, gold(), Vector3(90, 0, 0), 20)
	_torus(fan, 1.18, 1.23, Vector3.ZERO, gold_dim(), Vector3(90, 0, 0))

	# Basas y capiteles dorados de las columnas
	for x in [-2.5, 2.5]:
		_cyl(d, 0.45, 0.48, 0.22, Vector3(x, 0.11, -2), gold_dim(), Vector3.ZERO, 18)
		_cyl(d, 0.52, 0.38, 0.26, Vector3(x, 3.77, -2), gold(), Vector3.ZERO, 18)
		_torus(d, 0.34, 0.39, Vector3(x, 1.15, -2), gold_dim())

	# Candelabro (se mece un poco)
	var ch := _node(d, Vector3(0, 3.9, 0))
	_cyl(ch, 0.02, 0.02, 0.6, Vector3(0, -0.3, 0), brass())
	_sph(ch, 0.13, Vector3(0, -0.66, 0), gold())
	_torus(ch, 0.55, 0.6, Vector3(0, -0.8, 0), gold())
	var flame := _m("candle", Color(1, 0.8, 0.5), 0.5, 0.0, Color(1.0, 0.7, 0.35), 2.2, true)
	var crystal := _m("crystal", Color(0.55, 0.55, 0.5), 0.08, 0.3)
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		var p := Vector3(cos(a) * 0.575, -0.8, sin(a) * 0.575)
		_box(ch, Vector3(0.02, 0.02, 0.55), Vector3(cos(a) * 0.29, -0.73, sin(a) * 0.29), gold(), Vector3(0, -rad_to_deg(a) + 90, 0))
		_cyl(ch, 0.025, 0.025, 0.12, p + Vector3(0, 0.08, 0), cream())
		_sph(ch, 0.028, p + Vector3(0, 0.17, 0), flame)
		_sph(ch, 0.03, p + Vector3(0, -0.13, 0), crystal, Vector3(1, 2.2, 1))
	_swing(ch, 1, Vector3(1, 0, 0.6), 1.6, 0.55)
	_flicker(1, flame, room.get_node_or_null("ChandelierLight"))

	# Cajita de musica: tapa abierta y patas doradas (la bailarina se pone encima)
	_box(d, Vector3(0.35, 0.3, 0.02), Vector3(0, 1.24, -0.66), _m("mirror", Color(0.3, 0.3, 0.32), 0.05, 0.6), Vector3(-12, 0, 0))
	_box(d, Vector3(0.37, 0.03, 0.32), Vector3(0, 0.9, -0.5), gold_dim())
	# Cordon de terciopelo detras del pedestal
	for x in [-0.7, 0.7]:
		_cyl(d, 0.12, 0.12, 0.03, Vector3(x, 0.015, -1.3), gold_dim())
		_cyl(d, 0.025, 0.025, 0.9, Vector3(x, 0.45, -1.3), gold())
		_sph(d, 0.05, Vector3(x, 0.92, -1.3), gold())
	_cyl(d, 0.025, 0.025, 1.4, Vector3(0, 0.78, -1.3), velvet(), Vector3(0, 0, 90))

	# Retratos en la pared izquierda (uno torcido)
	_painting(d, Vector3(-3.74, 2.35, -1.5), Vector3(0, 90, 0), 0.8, 1.1, true)
	_painting(d, Vector3(-3.74, 2.3, 1.7), Vector3(0, 90, 9), 0.9, 0.7)

	# Sillon cubierto con una sabana
	_box(d, Vector3(1.0, 0.45, 1.0), Vector3(-3.0, 0.23, 1.2), sheet())
	_sph(d, 0.5, Vector3(-3.0, 0.48, 1.2), sheet(), Vector3(1.05, 0.45, 1.0))
	_sph(d, 0.5, Vector3(-3.4, 0.85, 1.2), sheet(), Vector3(0.35, 0.95, 1.0))
	_sph(d, 0.2, Vector3(-3.0, 0.62, 0.72), sheet(), Vector3(2.4, 0.9, 0.7))
	_sph(d, 0.2, Vector3(-3.0, 0.62, 1.68), sheet(), Vector3(2.4, 0.9, 0.7))

	# Reloj de pie parado en la esquina
	var clk := _node(d, Vector3(-3.3, 0, -3.3), Vector3(0, 45, 0))
	_box(clk, Vector3(0.55, 2.2, 0.4), Vector3(0, 1.1, 0), wood_mid())
	_box(clk, Vector3(0.65, 0.32, 0.46), Vector3(0, 2.36, 0), wood_dark())
	_cyl(clk, 0.2, 0.2, 0.03, Vector3(0, 1.85, 0.21), cream(), Vector3(90, 0, 0), 20)
	_box(clk, Vector3(0.012, 0.14, 0.01), Vector3(0, 1.91, 0.23), black())
	_box(clk, Vector3(0.012, 0.1, 0.01), Vector3(0.04, 1.82, 0.23), black(), Vector3(0, 0, 50))
	_box(clk, Vector3(0.3, 1.0, 0.01), Vector3(0, 0.95, 0.205), glass_dark())
	_cyl(clk, 0.09, 0.09, 0.02, Vector3(0, 0.7, 0.19), brass(), Vector3(90, 0, 0), 16)

	_dead_plant(d, Vector3(3.0, 0, -3.1))
	_particles(d, Vector3(0, 2.0, 0), Vector3(3.0, 1.6, 3.0), 36)


# ================================================================ CAM 02 - Recepcion

func _build_reception(d: Node3D) -> void:
	_quad(d, Vector2(7, 7), Vector3(0, 0.002, 0),
		_tile("planks", Color(0.11, 0.065, 0.035), Color(0.11, 0.065, 0.035), Color(0.02, 0.012, 0.008), Vector2(3, 26), 0.03, false, true, 0.45, 0.45),
		Vector3(-90, 0, 0))
	_hotel_walls(d, -3.3, -3.3, 3.5, 3.7, _paper("paper_recep", Color(0.04, 0.085, 0.06), 20))

	# Casillero de llaves detras del mostrador
	_box(d, Vector3(2.6, 1.5, 0.18), Vector3(0, 2.0, -3.2), wood_dark())
	for i in 5:
		_box(d, Vector3(2.6, 0.03, 0.22), Vector3(0, 1.25 + float(i) * 0.375, -3.14), wood_mid())
	for j in 9:
		_box(d, Vector3(0.03, 1.5, 0.22), Vector3(-1.3 + float(j) * 0.325, 2.0, -3.14), wood_mid())
	for i in 4:
		for j in 8:
			if (i * 7 + j * 3) % 4 == 0:
				continue   # llaves que faltan...
			var p := Vector3(-1.3 + 0.1625 + float(j) * 0.325, 1.25 + 0.24 + float(i) * 0.375, -3.07)
			_box(d, Vector3(0.025, 0.1, 0.01), p, brass())
			_box(d, Vector3(0.05, 0.07, 0.008), p + Vector3(0, -0.09, 0), _m("tag", Color(0.4, 0.06, 0.05), 0.8))
	_box(d, Vector3(2.2, 0.36, 0.04), Vector3(0, 3.12, -3.27), wood_dark())
	_label(d, "RECEPCIÓN", Vector3(0, 3.12, -3.24), Vector3.ZERO, 64, Color(0.75, 0.58, 0.25), 0.0055)

	# Reloj de pared detenido en las 3:00
	_cyl(d, 0.32, 0.32, 0.06, Vector3(-3.27, 2.7, -1.6), wood_dark(), Vector3(0, 0, 90), 20)
	_cyl(d, 0.27, 0.27, 0.065, Vector3(-3.265, 2.7, -1.6), cream(), Vector3(0, 0, 90), 20)
	_box(d, Vector3(0.01, 0.035, 0.14), Vector3(-3.23, 2.7, -1.67), black())
	_box(d, Vector3(0.01, 0.2, 0.025), Vector3(-3.23, 2.8, -1.6), black())

	# Mostrador: franjas doradas al frente
	for i in 7:
		_box(d, Vector3(0.04, 0.85, 0.02), Vector3(-1.4 + float(i) * 0.4667, 0.52, 0.115), gold_dim())
	_box(d, Vector3(3.2, 0.05, 0.02), Vector3(0, 1.0, 0.115), gold_dim())

	# Lampara de banquero (parpadea)
	var lamp := _node(d, Vector3(-1.2, 1.15, -0.6))
	_cyl(lamp, 0.08, 0.09, 0.03, Vector3(0, 0.015, 0), brass())
	_cyl(lamp, 0.012, 0.012, 0.3, Vector3(0, 0.16, 0), brass())
	var shade := _m("lamp_green", Color(0.05, 0.22, 0.1), 0.2, 0.0, Color(0.3, 0.9, 0.45), 0.9, true)
	_cyl(lamp, 0.05, 0.16, 0.1, Vector3(0, 0.33, 0.04), shade, Vector3(0, 0, 0))
	var ll := _omni(lamp, Vector3(0, 0.25, 0.1), Color(0.85, 0.95, 0.65), 0.7, 2.4)
	_flicker(2, shade, ll, "buzz")

	# Libro de registro abierto, telefono y pluma
	_box(d, Vector3(0.54, 0.01, 0.36), Vector3(-0.05, 1.155, -0.35), velvet())
	_box(d, Vector3(0.25, 0.012, 0.33), Vector3(-0.18, 1.165, -0.35), paper(), Vector3(0, 0, 4))
	_box(d, Vector3(0.25, 0.012, 0.33), Vector3(0.08, 1.165, -0.35), paper(), Vector3(0, 0, -4))
	_cyl(d, 0.006, 0.006, 0.16, Vector3(0.12, 1.18, -0.3), black(), Vector3(90, 30, 0), 6)
	var ph := _node(d, Vector3(0.45, 1.15, -0.65), Vector3(0, -20, 0))
	_box(ph, Vector3(0.2, 0.08, 0.18), Vector3(0, 0.04, 0), _m("bakelite", Color(0.02, 0.02, 0.02), 0.2))
	_cyl(ph, 0.025, 0.025, 0.22, Vector3(0, 0.11, 0), _m("bakelite", Color.BLACK), Vector3(0, 0, 90), 8)
	_cyl(ph, 0.05, 0.05, 0.01, Vector3(0, 0.07, 0.085), brass(), Vector3(70, 0, 0), 12)

	# Taburete detras del mostrador
	_cyl(d, 0.2, 0.2, 0.06, Vector3(0.3, 0.72, -1.4), velvet())
	_cyl(d, 0.03, 0.03, 0.7, Vector3(0.3, 0.35, -1.4), brass(), Vector3.ZERO, 6)

	# Carrito de equipaje del botones
	var cart := _node(d, Vector3(-2.4, 0, 1.0), Vector3(0, 20, 0))
	_box(cart, Vector3(0.9, 0.05, 0.6), Vector3(0, 0.15, 0), brass())
	for x in [-0.4, 0.4]:
		for z in [-0.25, 0.25]:
			_cyl(cart, 0.07, 0.07, 0.04, Vector3(x, 0.07, z), black(), Vector3(90, 0, 0), 10)
		_cyl(cart, 0.022, 0.022, 1.6, Vector3(x, 0.95, -0.28), brass(), Vector3.ZERO, 8)
	_cyl(cart, 0.022, 0.022, 0.84, Vector3(0, 1.75, -0.28), brass(), Vector3(0, 0, 90), 8)
	_suitcase(cart, Vector3(0, 0.18, 0), Vector3(0.6, 0.38, 0.28), leather(), 5)
	_suitcase(cart, Vector3(0.05, 0.56, 0.02), Vector3(0.5, 0.28, 0.22), velvet(), -8)
	_cyl(cart, 0.15, 0.15, 0.2, Vector3(-0.1, 0.96, 0), _m("hatbox", Color(0.25, 0.2, 0.12), 0.8), Vector3.ZERO, 14)

	# Maletas olvidadas en la esquina
	_suitcase(d, Vector3(-2.7, 0, -2.6), Vector3(0.7, 0.3, 0.45), leather(), 10)
	_suitcase(d, Vector3(-2.65, 0.3, -2.6), Vector3(0.55, 0.25, 0.38), _m("suit_green", Color(0.08, 0.14, 0.09), 0.7), -15)
	_suitcase(d, Vector3(-2.0, 0, -2.9), Vector3(0.45, 0.6, 0.2), leather(), 70)

	# Tapete frente al mostrador
	_box(d, Vector3(2.4, 0.012, 1.4), Vector3(0.3, 0.006, 1.2), velvet())
	_box(d, Vector3(2.2, 0.014, 1.2), Vector3(0.3, 0.008, 1.2), _m("rug_in", Color(0.16, 0.02, 0.03), 0.9))

	_dead_plant(d, Vector3(2.75, 0, -2.75))
	_painting(d, Vector3(-3.24, 2.2, 1.2), Vector3(0, 90, 0), 1.1, 0.8)


# ================================================================ CAM 03 - Cocina

func _build_kitchen(d: Node3D, room: Node3D) -> void:
	_quad(d, Vector2(7.5, 7.5), Vector3(0, 0.002, 0),
		_tile("kitchen_floor", Color(0.03, 0.03, 0.035), Color(0.25, 0.25, 0.24), Color(0.05, 0.05, 0.05), Vector2(10, 10), 0.02, true, false, 0.75, 0.35),
		Vector3(-90, 0, 0))
	var wall_tiles := _tile("kitchen_wall", Color(0.5, 0.53, 0.52), Color(0.5, 0.53, 0.52), Color(0.2, 0.21, 0.2), Vector2(24, 12), 0.04, false, false, 0.55, 0.25)
	_quad(d, Vector2(7.4, 3.7), Vector3(0, 1.85, -3.49), wall_tiles)
	_quad(d, Vector2(7.4, 3.7), Vector3(-3.49, 1.85, 0), wall_tiles, Vector3(0, 90, 0))

	# Estufa industrial contra la pared izquierda
	_box(d, Vector3(0.8, 0.9, 2.0), Vector3(-3.1, 0.45, -1.0), iron())
	_box(d, Vector3(0.84, 0.04, 2.04), Vector3(-3.1, 0.92, -1.0), steel())
	for x in [-3.28, -2.92]:
		for z in [-1.6, -1.0, -0.4]:
			_torus(d, 0.06, 0.1, Vector3(x, 0.95, z), black())
	for z in [-1.48, -0.52]:
		_box(d, Vector3(0.02, 0.45, 0.8), Vector3(-2.69, 0.42, z), steel())
		_cyl(d, 0.015, 0.015, 0.6, Vector3(-2.66, 0.7, z), steel(), Vector3(90, 0, 0), 6)
	_box(d, Vector3(0.9, 0.45, 2.1), Vector3(-3.05, 2.55, -1.0), steel())
	_cyl(d, 0.2, 0.2, 0.9, Vector3(-3.2, 3.25, -1.0), steel())
	# Ollas sobre la estufa
	_cyl(d, 0.18, 0.16, 0.28, Vector3(-3.1, 1.08, -1.6), copper())
	_cyl(d, 0.2, 0.2, 0.05, Vector3(-3.1, 0.97, -0.4), iron())

	# Camara frigorifica entreabierta (se cuela luz fria)
	_box(d, Vector3(1.2, 2.3, 0.06), Vector3(-1.95, 1.15, -3.47), steel())
	_box(d, Vector3(1.05, 2.15, 0.08), Vector3(-1.95, 1.1, -3.43), _m("freezer", Color(0.35, 0.37, 0.4), 0.4, 0.6))
	_box(d, Vector3(0.06, 0.4, 0.08), Vector3(-1.55, 1.1, -3.36), steel())
	_box(d, Vector3(0.025, 2.1, 0.02), Vector3(-1.4, 1.1, -3.45),
		_m("cold_leak", Color(0.3, 0.5, 0.7), 0.5, 0.0, Color(0.4, 0.7, 1.0), 1.6))
	_label(d, "CÁMARA FRÍA", Vector3(-1.95, 2.45, -3.46), Vector3.ZERO, 40, Color(0.7, 0.72, 0.75), 0.004)

	# Repisas con latas y frascos
	for y in [1.5, 2.2]:
		_box(d, Vector3(1.5, 0.04, 0.35), Vector3(2.65, y, -3.3), wood_mid())
	var can := _m("can", Color(0.3, 0.3, 0.32), 0.35, 0.7)
	var jar := _m("jar", Color(0.12, 0.16, 0.08), 0.1, 0.2)
	for i in 6:
		_cyl(d, 0.05, 0.05, 0.12, Vector3(2.0 + float(i) * 0.24, 1.58, -3.28 + float(i % 2) * 0.08), can, Vector3.ZERO, 10)
	for i in 4:
		_cyl(d, 0.07, 0.07, 0.2, Vector3(2.1 + float(i) * 0.33, 2.32, -3.3), jar, Vector3.ZERO, 10)

	# Barra de ollas y cuchillas colgando sobre la mesa (se mece)
	var rack := _node(d, Vector3(0, 3.7, -0.6))
	for x in [-0.9, 0.9]:
		_cyl(rack, 0.01, 0.01, 0.9, Vector3(x, -0.45, 0), iron(), Vector3.ZERO, 6)
	_cyl(rack, 0.025, 0.025, 2.0, Vector3(0, -0.9, 0), iron(), Vector3(0, 0, 90), 8)
	for i in 6:
		var x: float = -0.75 + float(i) * 0.3
		_cyl(rack, 0.006, 0.006, 0.12, Vector3(x, -0.97, 0), iron(), Vector3.ZERO, 4)
		if i % 2 == 0:
			_cyl(rack, 0.14, 0.12, 0.14, Vector3(x, -1.12, 0), copper(), Vector3(0, 0, 8.0 * float(i - 2)))
		else:
			_box(rack, Vector3(0.12, 0.24, 0.01), Vector3(x, -1.14, 0), steel())
	_swing(rack, 3, Vector3(1, 0, 0), 1.2, 0.7)

	# Cosas sobre la mesa de acero
	_box(d, Vector3(0.6, 0.03, 0.4), Vector3(-0.5, 0.915, -0.6), wood_mid())
	_box(d, Vector3(0.02, 0.14, 0.22), Vector3(-0.45, 1.0, -0.6), steel(), Vector3(0, 20, 12))
	_sph(d, 0.18, Vector3(0.55, 0.95, -0.5), _m("meat", Color(0.2, 0.045, 0.04), 0.55), Vector3(1.4, 0.5, 1.0))
	_cyl(d, 0.14, 0.09, 0.1, Vector3(0.2, 0.95, -0.85), steel())

	# Carne colgando de ganchos en el riel del techo
	_box(d, Vector3(0.05, 0.05, 2.4), Vector3(2.7, 3.4, -1.5), iron())
	for z in [-2.3, -1.0]:
		var hook := _node(d, Vector3(2.7, 3.4, z))
		_cyl(hook, 0.008, 0.008, 0.5, Vector3(0, -0.25, 0), iron(), Vector3.ZERO, 4)
		_sph(hook, 0.16, Vector3(0, -0.8, 0), _m("meat", Color.BLACK), Vector3(0.8, 1.9, 0.6))
		_swing(hook, 3, Vector3(0, 0, 1), 2.0, 0.45)

	# Mancha y rastro en el piso frente a la camara frigorifica
	_cyl(d, 0.35, 0.35, 0.004, Vector3(-1.55, 0.005, -2.7), blood(), Vector3.ZERO, 16)
	_cyl(d, 0.22, 0.22, 0.004, Vector3(-1.2, 0.006, -2.45), blood(), Vector3.ZERO, 12)
	_box(d, Vector3(0.14, 0.004, 1.3), Vector3(-0.85, 0.005, -1.75), blood(), Vector3(0, -30, 0))
	_box(d, Vector3(0.02, 0.012, 0.25), Vector3(0.9, 0.008, 0.7), steel(), Vector3(0, 65, 0))

	# Lamparas fluorescentes (una parpadea con la luz de la cocina)
	var tube_ok := _m("tube", Color(0.7, 0.75, 0.8), 0.3, 0.0, Color(0.8, 0.9, 1.0), 1.1)
	var tube_bad := _m("tube_bad", Color(0.7, 0.75, 0.8), 0.3, 0.0, Color(0.8, 0.9, 1.0), 1.1, true)
	_box(d, Vector3(1.4, 0.06, 0.22), Vector3(0, 3.67, 1.1), steel())
	_box(d, Vector3(1.3, 0.04, 0.12), Vector3(0, 3.62, 1.1), tube_ok)
	_box(d, Vector3(1.4, 0.06, 0.22), Vector3(0, 3.67, -2.4), steel())
	_box(d, Vector3(1.3, 0.04, 0.12), Vector3(0, 3.62, -2.4), tube_bad)
	_flicker(3, tube_bad, room.get_node_or_null("KitchenLight"), "buzz")
	# Rejilla del altavoz del intercomunicador
	_box(d, Vector3(0.4, 0.5, 0.02), Vector3(-2.8, 2.6, -3.24), _m("speaker_cloth", Color(0.12, 0.09, 0.05), 0.95))


# ================================================================ CAM 04 / 05 - Pasillos

func _build_corridor(d: Node3D, id: int) -> void:
	var east: bool = (id == 4)
	var paper := _paper("paper_e" if east else "paper_w",
		Color(0.13, 0.03, 0.035) if east else Color(0.03, 0.07, 0.075), 6)
	# Pared del fondo (antes no habia)
	_box(d, Vector3(3.2, 3.2, 0.2), Vector3(0, 1.5, -5.55), wood_dark())
	_quad(d, Vector2(3.0, 1.95), Vector3(0, 2.125, -5.44), paper)
	# Paredes laterales: papel, lambrin, molduras
	for side in [-1.0, 1.0]:
		var x: float = 1.5 * side
		var ry: float = -90.0 * side
		_quad(d, Vector2(11, 1.95), Vector3(x - 0.01 * side, 2.125, 0), paper, Vector3(0, ry, 0))
		_box(d, Vector3(0.05, 1.15, 11), Vector3(x - 0.025 * side, 0.575, 0), wood_dark())
		_box(d, Vector3(0.07, 0.05, 11), Vector3(x - 0.035 * side, 1.15, 0), gold_dim())
		_box(d, Vector3(0.08, 0.1, 11), Vector3(x - 0.04 * side, 3.05, 0), gold_dim())
		_box(d, Vector3(0.07, 0.12, 11), Vector3(x - 0.035 * side, 0.06, 0), black())
	# Bordes dorados del tapete
	for x in [-0.78, 0.78]:
		_box(d, Vector3(0.04, 0.022, 11), Vector3(x, 0.012, 0), gold_dim())

	# Puertas de habitaciones (izquierda y derecha alternadas)
	var doors: Array = [[-1.0, -3.6], [-1.0, -0.6], [-1.0, 2.4], [1.0, -2.1], [1.0, 0.9]]
	var num: int = 201 if east else 214
	for k in doors.size():
		var side: float = doors[k][0]
		var z: float = doors[k][1]
		var ajar: bool = east and k == 1
		_door(d, side, z, str(num + k * 2), ajar)

	# Apliques de pared (luz muy tenue: la camara sigue oscura)
	var sconce := _m("sconce", Color(0.2, 0.14, 0.08), 0.5, 0.0, Color(1.0, 0.6, 0.3), 0.18)
	var sconce_bad := _m("sconce_bad%d" % id, Color(0.2, 0.14, 0.08), 0.5, 0.0, Color(1.0, 0.6, 0.3), 0.18, true)
	var spots: Array = [[-1.0, -4.8], [-1.0, -2.1], [-1.0, 0.9], [1.0, -3.6], [1.0, -0.6], [1.0, 2.4]]
	for k in spots.size():
		var side: float = spots[k][0]
		var x: float = 1.45 * side
		var z: float = spots[k][1]
		_box(d, Vector3(0.08, 0.2, 0.06), Vector3(x, 2.0, z), gold_dim())
		_cyl(d, 0.055, 0.035, 0.11, Vector3(x - 0.08 * side, 2.1, z), sconce_bad if k == 2 else sconce)
	_flicker(id, sconce_bad, null, "buzz")

	# Lamparas colgantes apagadas
	for z in [-3.0, 1.0]:
		_cyl(d, 0.01, 0.01, 0.3, Vector3(0, 2.95, z), brass(), Vector3.ZERO, 4)
		_sph(d, 0.16, Vector3(0, 2.8, z), glass_dark(), Vector3.ONE, true).rotation_degrees = Vector3(180, 0, 0)

	# Cuadros
	_painting(d, Vector3(1.45, 2.05, 3.6), Vector3(0, -90, 0), 0.7, 0.55, false)
	_painting(d, Vector3(-1.45, 2.05, -4.8 if not east else 3.6), Vector3(0, 90, 0), 0.55, 0.75, true)

	if east:
		# Fondo: puerta de ascensor con reja Art Deco e indicador de piso
		_box(d, Vector3(1.4, 2.3, 0.06), Vector3(0, 1.15, -5.42), void_mat())
		_box(d, Vector3(1.6, 0.12, 0.1), Vector3(0, 2.36, -5.4), gold())
		for x in [-0.76, 0.76]:
			_box(d, Vector3(0.1, 2.42, 0.1), Vector3(x, 1.18, -5.4), gold())
		for i in 9:
			_cyl(d, 0.012, 0.012, 2.25, Vector3(-0.6 + float(i) * 0.15, 1.13, -5.36), gold_dim(), Vector3.ZERO, 6)
		for y in [0.4, 1.15, 1.9]:
			_box(d, Vector3(1.35, 0.03, 0.02), Vector3(0, y, -5.35), gold_dim())
		_cyl(d, 0.32, 0.32, 0.04, Vector3(0, 2.7, -5.4), gold(), Vector3(90, 0, 0), 20)
		_cyl(d, 0.27, 0.27, 0.045, Vector3(0, 2.7, -5.39), black(), Vector3(90, 0, 0), 20)
		_box(d, Vector3(0.02, 0.24, 0.01), Vector3(0.09, 2.78, -5.36), _m("needle", Color(0.6, 0.08, 0.05), 0.5), Vector3(0, 0, -40))
		# Carrito de servicio a cuartos abandonado
		var cart := _node(d, Vector3(0.95, 0, -4.6))
		_box(cart, Vector3(0.5, 0.03, 0.85), Vector3(0, 0.8, 0), steel())
		_box(cart, Vector3(0.52, 0.28, 0.87), Vector3(0, 0.66, 0), _m("cloth", Color(0.42, 0.4, 0.37), 0.95))
		_box(cart, Vector3(0.5, 0.03, 0.85), Vector3(0, 0.25, 0), steel())
		_sph(cart, 0.16, Vector3(0, 0.82, 0.15), steel(), Vector3.ONE, true)
		_cyl(cart, 0.1, 0.1, 0.015, Vector3(0.05, 0.82, -0.25), cream())
		# Charola tirada en el piso
		_cyl(d, 0.2, 0.2, 0.015, Vector3(-0.55, 0.008, -4.7), steel(), Vector3.ZERO, 16)
		_cyl(d, 0.09, 0.09, 0.012, Vector3(-0.2, 0.007, -4.4), cream(), Vector3(0, 0, 8), 12)
		_cyl(d, 0.04, 0.03, 0.1, Vector3(-0.75, 0.03, -4.3), glass_dark(), Vector3(0, 0, 90), 8)
	else:
		# Fondo: ventana con luz de luna y cortinas
		var moon := _m("moon", Color(0.2, 0.26, 0.36), 0.2, 0.0, Color(0.35, 0.45, 0.65), 0.35)
		_quad(d, Vector2(1.2, 1.6), Vector3(0, 1.75, -5.42), moon)
		_box(d, Vector3(1.4, 0.08, 0.1), Vector3(0, 2.58, -5.4), wood_dark())
		_box(d, Vector3(1.4, 0.1, 0.16), Vector3(0, 0.92, -5.38), wood_dark())
		for x in [-0.66, 0.66, 0.0]:
			_box(d, Vector3(0.06 if x != 0.0 else 0.03, 1.66, 0.08), Vector3(x, 1.75, -5.4), wood_dark())
		_box(d, Vector3(1.3, 0.03, 0.06), Vector3(0, 1.85, -5.4), wood_dark())
		_cyl(d, 0.02, 0.02, 2.4, Vector3(0, 2.75, -5.3), brass(), Vector3(0, 0, 90), 6)
		for x in [-0.95, 0.95]:
			_box(d, Vector3(0.5, 2.6, 0.08), Vector3(x, 1.45, -5.3), velvet(), Vector3(0, 0, -3.0 * signf(x)))
		# Mesa volcada y florero roto
		_box(d, Vector3(0.45, 0.82, 1.0), Vector3(1.22, 0.41, -4.6), wood_mid())
		_cyl(d, 0.07, 0.1, 0.25, Vector3(1.22, 0.95, -4.75), _m("vase", Color(0.3, 0.32, 0.36), 0.15, 0.2), Vector3.ZERO, 10)
		for i in 4:
			_cyl(d, 0.006, 0.006, 0.35, Vector3(1.2 + float(i % 2) * 0.04, 1.2, -4.75 + float(i) * 0.03), dead_plant(),
				Vector3(25.0 * float(i - 1.5), 0, 15.0 * float(i % 2)), 4)
		var tbl := _node(d, Vector3(-0.85, 0.22, -4.5), Vector3(0, 30, 90))
		_cyl(tbl, 0.25, 0.25, 0.03, Vector3.ZERO, wood_mid(), Vector3.ZERO, 16)
		_cyl(tbl, 0.025, 0.025, 0.6, Vector3(0, -0.3, 0), wood_mid(), Vector3.ZERO, 6)
		for i in 3:
			_box(d, Vector3(0.08, 0.02, 0.05), Vector3(-0.4 + float(i) * 0.15, 0.01, -4.1 - float(i) * 0.1),
				_m("vase", Color.BLACK), Vector3(0, float(i) * 50.0, 0))


func _door(d: Node3D, side: float, z: float, number: String, ajar: bool) -> void:
	var x: float = 1.5 * side
	var ry: float = -90.0 * side
	_box(d, Vector3(0.1, 2.3, 1.2), Vector3(x - 0.02 * side, 1.15, z), wood_dark())
	if ajar:
		_box(d, Vector3(0.02, 2.15, 0.95), Vector3(x - 0.045 * side, 1.075, z), void_mat())
		var hinge := _node(d, Vector3(x - 0.07 * side, 0, z - 0.475), Vector3(0, 28.0 * -side, 0))
		_box(hinge, Vector3(0.05, 2.15, 0.95), Vector3(0, 1.075, 0.475), wood_mid())
		_sph(hinge, 0.035, Vector3(-0.04 * side, 1.0, 0.85), brass())
		_box(hinge, Vector3(0.01, 0.22, 0.1), Vector3(-0.04 * side, 0.85, 0.85), _m("tag", Color.BLACK))
		return
	_box(d, Vector3(0.05, 2.15, 0.95), Vector3(x - 0.07 * side, 1.075, z), wood_mid())
	for y in [0.55, 1.5]:
		_box(d, Vector3(0.02, 0.7, 0.65), Vector3(x - 0.1 * side, y, z), wood_panel())
	_sph(d, 0.035, Vector3(x - 0.11 * side, 1.0, z + 0.36), brass())
	_label(d, number, Vector3(x - 0.1 * side, 1.95, z), Vector3(0, ry, 0), 36, Color(0.45, 0.35, 0.15), 0.0035)


# ================================================================ CAM 06 - Calderas

func _build_boiler(d: Node3D) -> void:
	_quad(d, Vector2(8, 8), Vector3(0, 0.002, 0),
		_tile("concrete", Color(0.11, 0.105, 0.1), Color(0.11, 0.105, 0.1), Color(0.05, 0.05, 0.05), Vector2(4, 4), 0.008, false, false, 0.7, 0.85),
		Vector3(-90, 0, 0))
	var brick := _tile("brick", Color(0.24, 0.1, 0.07), Color(0.24, 0.1, 0.07), Color(0.09, 0.08, 0.07), Vector2(16, 26), 0.06, false, true, 0.6, 0.9)
	_quad(d, Vector2(7.6, 3.9), Vector3(0, 1.95, -3.79), brick)
	_quad(d, Vector2(7.6, 3.9), Vector3(-3.79, 1.95, 0), brick, Vector3(0, 90, 0))

	# Caldera: aros remachados, tubo al techo, manometros
	for y in [0.5, 1.8, 3.1]:
		_torus(d, 1.28, 1.37, Vector3(0, y, -1.0), iron())
	_cyl(d, 1.32, 1.32, 0.1, Vector3(0, 3.53, -1.0), rust(), Vector3.ZERO, 24)
	_cyl(d, 0.22, 0.22, 0.45, Vector3(0, 3.75, -1.0), rust())
	for g in [[-0.42, 2.5], [0.42, 2.65]]:
		var gx: float = g[0]
		var gy: float = g[1]
		var gz: float = -1.0 + sqrt(1.69 - gx * gx) + 0.04
		var gauge := _node(d, Vector3(gx, gy, gz), Vector3(0, rad_to_deg(asin(gx / 1.3)), 0))
		_cyl(gauge, 0.13, 0.13, 0.05, Vector3.ZERO, brass(), Vector3(90, 0, 0), 18)
		_cyl(gauge, 0.11, 0.11, 0.052, Vector3(0, 0, 0.002), _m("gauge", Color(0.55, 0.5, 0.4), 0.6, 0.0, Color(0.6, 0.55, 0.4), 0.12), Vector3(90, 0, 0), 18)
		var pivot := _node(gauge, Vector3(0, 0, 0.03))
		pivot.rotation.z = 0.9
		_box(pivot, Vector3(0.012, 0.09, 0.005), Vector3(0, 0.045, 0), _m("needle", Color.BLACK))
		_needles.append({"node": pivot, "base": 0.9, "room": 6})

	# Tuberias por las paredes y el techo
	_cyl(d, 0.12, 0.12, 7.6, Vector3(0, 3.2, -3.6), rust(), Vector3(0, 0, 90), 10)
	_cyl(d, 0.08, 0.08, 7.6, Vector3(0, 2.7, -3.62), copper(), Vector3(0, 0, 90), 10)
	_cyl(d, 0.1, 0.1, 7.6, Vector3(-3.6, 3.0, 0), rust(), Vector3(90, 0, 0), 10)
	_cyl(d, 0.15, 0.15, 1.5, Vector3(0, 2.9, -3.05), rust(), Vector3(90, 0, 0), 10)
	_sph(d, 0.18, Vector3(0, 2.9, -3.6), rust())
	_cyl(d, 0.08, 0.08, 1.8, Vector3(-3.6, 2.1, -2.0), rust(), Vector3.ZERO, 10)
	var wheel := _node(d, Vector3(-3.45, 1.4, -2.0), Vector3(0, 0, 90))
	var red_paint := _m("red_paint", Color(0.38, 0.05, 0.04), 0.6, 0.3)
	_torus(wheel, 0.15, 0.19, Vector3.ZERO, red_paint)
	for a in [0.0, 60.0, 120.0]:
		_box(wheel, Vector3(0.3, 0.025, 0.025), Vector3.ZERO, red_paint, Vector3(0, a, 0))

	# Tanque secundario
	_cyl(d, 0.55, 0.55, 2.4, Vector3(-2.9, 1.2, -2.9), iron(), Vector3.ZERO, 16)
	for y in [0.4, 2.0]:
		_torus(d, 0.54, 0.6, Vector3(-2.9, y, -2.9), rust())

	# Monton de carbon y pala
	var coal := _m("coal", Color(0.03, 0.03, 0.035), 0.9)
	_sph(d, 0.9, Vector3(-2.6, 0.0, -0.3), coal, Vector3(1.0, 0.45, 1.1))
	for i in 9:
		var a: float = float(i) * 0.8
		_sph(d, 0.12 + float(i % 3) * 0.04, Vector3(-2.6 + cos(a) * (0.7 + float(i % 2) * 0.3), 0.06, -0.3 + sin(a) * 0.9), coal, Vector3(1, 0.7, 1))
	var shovel := _node(d, Vector3(-1.75, 0, 0.6), Vector3(0, 0, -18))
	_cyl(shovel, 0.02, 0.02, 1.2, Vector3(0, 0.75, 0), wood_mid(), Vector3.ZERO, 6)
	_box(shovel, Vector3(0.26, 0.3, 0.03), Vector3(0, 0.13, 0), iron())

	# Letrero de peligro
	_box(d, Vector3(0.95, 0.5, 0.03), Vector3(2.4, 2.1, -3.76), _m("warn", Color(0.5, 0.4, 0.04), 0.7))
	_label(d, "PELIGRO\nALTA PRESIÓN", Vector3(2.4, 2.1, -3.74), Vector3.ZERO, 44, Color(0.02, 0.02, 0.02), 0.0035)

	# Carro de lavanderia de la mucama con sabanas saliendo
	_box(d, Vector3(1.0, 0.7, 0.6), Vector3(2.4, 0.45, -3.25), _m("canvas_cart", Color(0.18, 0.16, 0.12), 0.95))
	_sph(d, 0.35, Vector3(2.3, 0.82, -3.25), sheet(), Vector3(1.3, 0.5, 0.8))
	_box(d, Vector3(0.5, 0.6, 0.02), Vector3(2.0, 0.5, -2.93), sheet(), Vector3(-10, 0, 8))

	# Cadena colgando del techo (se mece)
	var chain := _node(d, Vector3(0.9, 3.9, -2.6))
	for i in 10:
		_torus(chain, 0.025, 0.045, Vector3(0, -0.08 - float(i) * 0.075, 0), iron(), Vector3(0, 90.0 * float(i % 2), 90))
	_swing(chain, 6, Vector3(1, 0, 0.4), 3.0, 0.8)

	# Charco de agua
	_cyl(d, 0.5, 0.5, 0.004, Vector3(1.2, 0.005, -2.4), _m("water", Color(0.02, 0.025, 0.03), 0.04, 0.3), Vector3.ZERO, 16).scale = Vector3(1.5, 1, 1)
	# Brasas que salen de la compuerta del horno
	_particles(d, Vector3(0, 0.75, 0.4), Vector3(0.35, 0.15, 0.08), 14, true)


# ================================================================ CAM 07 - Ductos

func _build_duct(d: Node3D) -> void:
	var panel := _tile("duct", Color(0.3, 0.32, 0.33), Color(0.3, 0.32, 0.33), Color(0.12, 0.12, 0.13), Vector2(2, 9), 0.012, false, false, 0.65, 0.45)
	panel.set_shader_parameter("tile_metallic", 0.6)
	_quad(d, Vector2(1.8, 8.5), Vector3(0, 0.004, 0), panel, Vector3(-90, 0, 0))
	_quad(d, Vector2(1.8, 8.5), Vector3(0, 1.396, 0), panel, Vector3(90, 0, 0))
	_quad(d, Vector2(8.5, 1.4), Vector3(-0.896, 0.7, 0), panel, Vector3(0, 90, 0))
	_quad(d, Vector2(8.5, 1.4), Vector3(0.896, 0.7, 0), panel, Vector3(0, -90, 0))

	# Costillas (uniones del ducto)
	var rib := _m("rib", Color(0.22, 0.23, 0.24), 0.5, 0.7)
	for i in 7:
		var z: float = -3.75 + float(i)
		_box(d, Vector3(1.8, 0.04, 0.06), Vector3(0, 1.38, z), rib)
		_box(d, Vector3(1.8, 0.03, 0.06), Vector3(0, 0.015, z), rib)
		for x in [-0.88, 0.88]:
			_box(d, Vector3(0.04, 1.4, 0.06), Vector3(x, 0.7, z), rib)

	# Rejilla del fondo, con un brillo rojizo detras
	_quad(d, Vector2(1.8, 1.4), Vector3(0, 0.7, -4.3), _m("vent_glow", Color(0.1, 0.02, 0.01), 0.9, 0.0, Color(0.5, 0.06, 0.02), 0.35))
	for i in 6:
		_box(d, Vector3(1.78, 0.05, 0.04), Vector3(0, 0.15 + float(i) * 0.22, -4.15), rib, Vector3(30, 0, 0))

	# Desvio lateral oscuro
	_box(d, Vector3(0.02, 0.75, 0.8), Vector3(-0.885, 0.45, -2.0), void_mat())
	_box(d, Vector3(0.04, 0.06, 0.9), Vector3(-0.87, 0.85, -2.0), rib)

	# Rasguños en las paredes
	var scratch := _m("scratch", Color(0.03, 0.03, 0.03), 0.9)
	for g in [[0.885, -1.0, 0.6], [-0.885, 1.4, 0.45], [0.885, 2.2, 0.35]]:
		for k in 4:
			_box(d, Vector3(0.006, 0.45, 0.012), Vector3(g[0], g[2] + float(k) * 0.02, g[1] + float(k) * 0.05), scratch, Vector3(25, 0, 0))

	# Cable colgando (se mece) y cofia de mucama tirada
	var cable := _node(d, Vector3(0.45, 1.38, -0.8))
	_cyl(cable, 0.012, 0.012, 0.75, Vector3(0, -0.37, 0), black(), Vector3.ZERO, 6)
	_sph(cable, 0.025, Vector3(0, -0.76, 0), copper())
	_swing(cable, 7, Vector3(0, 0, 1), 7.0, 1.1)
	_torus(d, 0.05, 0.11, Vector3(0.64, 0.02, 0.9), _m("lace", Color(0.6, 0.58, 0.55), 0.9), Vector3(0, 0, 0))
	_box(d, Vector3(0.18, 0.01, 0.05), Vector3(0.66, 0.02, 1.02), black(), Vector3(0, 30, 0))
	# Polvo acumulado en las esquinas
	var dust := _m("dust", Color(0.16, 0.15, 0.13), 1.0)
	for z in [-3.2, -1.4, 0.3, 2.0]:
		_sph(d, 0.08, Vector3(-0.8, 0.02, z), dust, Vector3(1.6, 0.5, 2.5))
		_sph(d, 0.07, Vector3(0.82, 0.02, z + 0.6), dust, Vector3(1.4, 0.5, 2.2))
