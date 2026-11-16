extends Control
## Monitor de cámaras CRT con escenografías detalladas (Art Déco Decadente).
## Dibujo procedural avanzado de las 7 salas del hotel con claroscuro,
## alfombras de época, azulejos, calderas industriales, viñeta CCTV y monstruos.

const Map = preload("res://scripts/map.gd")
const Figures = preload("res://scripts/figures.gd")

var night = null

const FEED := Rect2(30.0, 30.0, 1220.0, 660.0)
const BACK := Rect2(430.0, 170.0, 420.0, 290.0)
const GOLD := Color(0.83, 0.69, 0.22)
const GOLD_DIM := Color(0.50, 0.40, 0.14)
const BRONZE := Color(0.58, 0.42, 0.20)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if night == null:
		return
	var cam: int = night.current_cam
	var t: float = Time.get_ticks_msec() / 1000.0
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.015, 0.018))
	draw_rect(FEED, Color(0.025, 0.028, 0.028))

	var blind: bool = night.cams[cam].is_blind()
	var flash: float = night.flash_time
	var lit: bool = (not Map.is_dark(cam)) or flash > 0.0

	if blind:
		_static(t, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(0, 360), "SIN SEÑAL", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 48, Color(1, 1, 1, 0.7))
	elif not lit:
		_draw_dark(t, cam)
	else:
		_scene(cam, t)
		_entities(cam, t)
		if flash > 0.0:
			draw_rect(FEED, Color(1, 1, 1, clampf(flash, 0.0, 1.0) * 0.35))
		if cam == 7:
			draw_rect(FEED, Color(0.0, 0.6, 0.15, 0.14))

	if night.box_enabled and cam == 1 and lit and not blind:
		_music_box(t)

	_static(t, 1.0 if cam == 7 else 0.5)
	_cctv_vignette()
	_labels(cam, t)


# ================================================================ UTILIDADES CRT

func _static(t: float, strength: float) -> void:
	for i in int(30.0 + 90.0 * strength):
		var y: float = FEED.position.y + randf() * FEED.size.y
		var x: float = FEED.position.x + randf() * FEED.size.x
		var w: float = 20.0 + randf() * 150.0
		draw_line(Vector2(x, y), Vector2(minf(x + w, FEED.end.x), y), Color(1, 1, 1, randf() * 0.05 * (1.0 + strength * 2.0)), 1.0)
	var by: float = FEED.position.y + fmod(t * 110.0, FEED.size.y)
	draw_rect(Rect2(FEED.position.x, by, FEED.size.x, 32.0), Color(1, 1, 1, 0.025))


func _cctv_vignette() -> void:
	# Viñeta oscura redondeada en las esquinas simulando lente de seguridad ojo de pez
	var v_col := Color(0, 0, 0, 0.45)
	var f: Rect2 = FEED
	draw_colored_polygon(PackedVector2Array([f.position, Vector2(f.position.x + 85, f.position.y), Vector2(f.position.x, f.position.y + 85)]), v_col)
	draw_colored_polygon(PackedVector2Array([Vector2(f.end.x, f.position.y), Vector2(f.end.x - 85, f.position.y), Vector2(f.end.x, f.position.y + 85)]), v_col)
	draw_colored_polygon(PackedVector2Array([Vector2(f.position.x, f.end.y), Vector2(f.position.x + 85, f.end.y), Vector2(f.position.x, f.end.y - 85)]), v_col)
	draw_colored_polygon(PackedVector2Array([f.end, Vector2(f.end.x - 85, f.end.y), Vector2(f.end.x, f.end.y - 85)]), v_col)


func _draw_dark(t: float, cam: int) -> void:
	draw_rect(FEED, Color(0.012, 0.015, 0.018))
	if randf() < 0.1:
		draw_rect(FEED, Color(0.06, 0.07, 0.08, 0.4))

	# Si es calderas en la oscuridad, las brasas siguen ardiendo en el fondo
	if cam == 6:
		var glow: float = night.boiler_glow
		var fire_a: float = 0.4 + 0.3 * sin(t * 4.0) + glow * 0.4
		draw_circle(Vector2(640, 395), 18.0 + glow * 8.0, Color(1.0, 0.35, 0.1, fire_a))

	draw_string(ThemeDB.fallback_font, Vector2(0, 350), "SIN LUZ", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 38, Color(1, 1, 1, 0.20))
	draw_string(ThemeDB.fallback_font, Vector2(0, 388), "[F] FLASH DE CÁMARA", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 18, Color(GOLD.r, GOLD.g, GOLD.b, 0.50))

	# Pista sutil: destello dorado donde Cornelius se oculta
	for m in night.monsters:
		if m.key == "cornelius" and m.glint_on(night.current_cam):
			var glint: float = 0.6 + 0.4 * sin(t * 8.0)
			draw_circle(Vector2(699, 299), 3.5, Color(0.95, 0.82, 0.25, glint))
			draw_circle(Vector2(717, 299), 3.5, Color(0.95, 0.82, 0.25, glint))


func _labels(cam: int, t: float) -> void:
	draw_rect(FEED, Color(0.55, 0.55, 0.50, 0.45), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	var c_name: String = Map.cam_name(cam)
	var font_size: int = 24
	var text_w: float = font.get_string_size(c_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var start_x: float = (1280.0 - text_w) * 0.5
	var text_y: float = 78.0

	draw_string(font, Vector2(start_x, text_y), c_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.8, 1.0, 0.85))
	if fmod(t, 1.2) < 0.7:
		var rec_x: float = start_x - 56.0
		draw_circle(Vector2(rec_x, text_y - 8.0), 6.0, Color(0.9, 0.15, 0.15))
		draw_string(font, Vector2(rec_x + 12.0, text_y - 1.0), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.9, 0.2, 0.2))
	draw_string(font, Vector2(0, 630), "GRAND TENEBRIS — SEGURIDAD", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 16, Color(0.8, 1.0, 0.85, 0.5))

	if night.box_enabled and cam == 1:
		var low: bool = night.box_charge < 0.25
		var msg: String = "CAJITA DE MÚSICA: SIN CUERDA" if night.box_charge <= 0.0 else "CAJITA DE MÚSICA: %d%%" % int(round(night.box_charge * 100.0))
		var c: Color = Color(1.0, 0.3, 0.25, 0.9) if low else Color(0.8, 1.0, 0.85, 0.7)
		draw_string(font, Vector2(0, 605), msg + "   [R] DAR CUERDA", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 17, c)

	if night.intercom_cam == cam:
		var a: float = 0.6 + 0.4 * sin(t * 6.0)
		draw_string(font, Vector2(0, 120), "[ JAZZ SONANDO EN ESTA CÁMARA ]", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 20, Color(GOLD.r, GOLD.g, GOLD.b, a))


# ================================================================ ESCENARIOS

func _box(wall: Color, floor_c: Color, ceil_c: Color) -> void:
	var f: Rect2 = FEED
	var bl: Vector2 = BACK.position
	var br := Vector2(BACK.end.x, BACK.position.y)
	var bbl := Vector2(BACK.position.x, BACK.end.y)
	var bbr: Vector2 = BACK.end
	draw_colored_polygon(PackedVector2Array([f.position, Vector2(f.end.x, f.position.y), br, bl]), ceil_c)
	draw_colored_polygon(PackedVector2Array([Vector2(f.position.x, f.end.y), f.end, bbr, bbl]), floor_c)
	draw_colored_polygon(PackedVector2Array([f.position, bl, bbl, Vector2(f.position.x, f.end.y)]), wall.darkened(0.22))
	draw_colored_polygon(PackedVector2Array([Vector2(f.end.x, f.position.y), br, bbr, f.end]), wall.darkened(0.22))
	draw_rect(BACK, wall)


func _floor_grid(col: Color) -> void:
	for i in range(-3, 4):
		var xb: float = 640.0 + i * 170.0
		var xt: float = 640.0 + i * 70.0
		draw_line(Vector2(xb, FEED.end.y), Vector2(xt, BACK.end.y), col, 1.0)
	for j in range(1, 6):
		var d: float = pow(float(j) / 6.0, 1.8)
		var y: float = lerpf(BACK.end.y, FEED.end.y, d)
		var hw: float = lerpf(210.0, 610.0, d)
		draw_line(Vector2(640.0 - hw, y), Vector2(640.0 + hw, y), col, 1.0)


func _scene(cam: int, t: float) -> void:
	var gl := Color(GOLD.r, GOLD.g, GOLD.b, 0.50)
	match cam:
		1: _scene_lobby(t, gl)
		2: _scene_reception(t, gl)
		3: _scene_kitchen(t, gl)
		4, 5: _scene_hallway(cam, t, gl)
		6: _scene_boiler(t, gl)
		7: _scene_ducts(t)


# --- 1. LOBBY PRINCIPAL (Cam 01) ---
func _scene_lobby(t: float, gl: Color) -> void:
	# Paredes de madera caoba y techo art déco
	_box(Color(0.18, 0.12, 0.08), Color(0.24, 0.06, 0.08), Color(0.08, 0.07, 0.06))

	# Alfombra central señorial con diamantes dorados
	var carpet_l := PackedVector2Array([
		Vector2(490, BACK.end.y), Vector2(790, BACK.end.y),
		Vector2(950, FEED.end.y), Vector2(330, FEED.end.y)
	])
	draw_colored_polygon(carpet_l, Color(0.35, 0.06, 0.09))
	draw_polyline(carpet_l, Color(GOLD.r, GOLD.g, GOLD.b, 0.40), 2.0)

	# Diamantes dorados en perspectiva a lo largo de la alfombra
	for r in 5:
		var d: float = pow(float(r + 1) / 5.5, 1.5)
		var cy: float = lerpf(BACK.end.y, FEED.end.y, d)
		var rw: float = lerpf(18.0, 52.0, d)
		var rh: float = lerpf(9.0, 26.0, d)
		var diamond := PackedVector2Array([
			Vector2(640, cy - rh), Vector2(640 + rw, cy),
			Vector2(640, cy + rh), Vector2(640 - rw, cy)
		])
		draw_polyline(diamond, Color(GOLD.r, GOLD.g, GOLD.b, 0.30), 1.5)

	# Columnas laterales de mármol negro y estrías doradas
	for side_x in [160.0, 1060.0]:
		draw_rect(Rect2(side_x, 120, 55, 520), Color(0.06, 0.06, 0.07))
		draw_rect(Rect2(side_x - 4, 115, 63, 15), Color(0.32, 0.25, 0.12))
		draw_rect(Rect2(side_x - 6, 625, 67, 20), Color(0.32, 0.25, 0.12))
		for l in 3:
			draw_line(Vector2(side_x + 12 + l * 15, 130), Vector2(side_x + 12 + l * 15, 625), Color(GOLD.r, GOLD.g, GOLD.b, 0.20), 1.5)

	# Gran arco Art Déco en la pared de fondo
	var arc_c := Vector2(640, 360)
	draw_arc(arc_c, 85.0, PI, TAU, 32, gl, 3.0)
	draw_line(Vector2(arc_c.x - 85, arc_c.y), Vector2(arc_c.x - 85, BACK.end.y), gl, 2.0)
	draw_line(Vector2(arc_c.x + 85, arc_c.y), Vector2(arc_c.x + 85, BACK.end.y), gl, 2.0)

	# Rótulo de bronce tallado en la pared
	draw_string(ThemeDB.fallback_font, Vector2(500, 240), "THE GRAND TENEBRIS", HORIZONTAL_ALIGNMENT_CENTER, 280.0, 15, Color(GOLD.r, GOLD.g, GOLD.b, 0.8))

	# Candelabro cenital con cálido cono de luz
	var chan := Vector2(640, 95)
	draw_line(Vector2(640, 30), chan, Color(0.5, 0.4, 0.18), 3.0)
	draw_arc(chan, 35.0, 0.0, PI, 16, gl, 3.0)
	for cr in 5:
		draw_line(chan + Vector2(-30 + cr * 15, 0), chan + Vector2(-30 + cr * 15, 16), Color(1, 1, 0.9, 0.7), 2.0)
	# Cono de luz sobre el vestíbulo
	draw_colored_polygon(PackedVector2Array([
		Vector2(590, chan.y + 10), Vector2(690, chan.y + 10),
		Vector2(880, FEED.end.y), Vector2(400, FEED.end.y)
	]), Color(1.0, 0.85, 0.45, 0.035))


# --- 2. RECEPCIÓN (Cam 02) ---
func _scene_reception(t: float, gl: Color) -> void:
	# Suelo de parqué oscuro en espiga
	_box(Color(0.16, 0.11, 0.08), Color(0.09, 0.07, 0.05), Color(0.06, 0.05, 0.05))
	_floor_grid(Color(GOLD.r, GOLD.g, GOLD.b, 0.08))

	# Casillero de llaves de habitaciones al fondo (4x4 casillas)
	var rack_pos := Vector2(530, 200)
	draw_rect(Rect2(rack_pos.x - 6, rack_pos.y - 6, 232, 142), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(rack_pos.x - 6, rack_pos.y - 6, 232, 142), gl, false, 2.0)
	for gx in 4:
		for gy in 4:
			var cx: float = rack_pos.x + gx * 55.0
			var cy: float = rack_pos.y + gy * 32.0
			draw_rect(Rect2(cx, cy, 50, 28), Color(0.06, 0.04, 0.03))
			draw_rect(Rect2(cx, cy, 50, 28), Color(GOLD.r, GOLD.g, GOLD.b, 0.3), false, 1.0)
			# Llavecitas con borla en casillas
			if (gx + gy) % 2 == 0:
				draw_circle(Vector2(cx + 25, cy + 10), 3.0, GOLD)
				draw_line(Vector2(cx + 25, cy + 13), Vector2(cx + 25, cy + 22), Color(0.8, 0.15, 0.1), 1.5)

	# Placa grabada sobre el casillero
	draw_string(ThemeDB.fallback_font, Vector2(530, 192), "CONCIERGE & KEYS", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 13, gl)

	# Mostrador señorial de recepción con sobre de mármol
	var desk := Rect2(450, 390, 380, 70)
	draw_rect(desk, Color(0.18, 0.10, 0.06))
	# Frentes de moldura Art Déco en la madera
	for d in 3:
		draw_rect(Rect2(desk.position.x + 20 + d * 120, desk.position.y + 12, 100, 46), Color(0.12, 0.06, 0.03))
		draw_rect(Rect2(desk.position.x + 20 + d * 120, desk.position.y + 12, 100, 46), Color(GOLD.r, GOLD.g, GOLD.b, 0.35), false, 1.0)
	# Tapa de mármol verde
	draw_rect(Rect2(desk.position.x - 10, desk.position.y - 8, desk.size.x + 20, 12), Color(0.06, 0.22, 0.12))
	draw_line(Vector2(desk.position.x - 10, desk.position.y - 8), Vector2(desk.end.x + 10, desk.position.y - 8), GOLD, 2.5)

	# Timbre de conserje dorado brillante
	var bell_pos := Vector2(640, 376)
	draw_circle(bell_pos, 8.0, GOLD)
	draw_circle(bell_pos + Vector2(0, -6), 2.5, Color(1, 1, 0.9))
	# Teléfono clásico de disco a la izquierda
	draw_rect(Rect2(480, 368, 28, 14), Color(0.05, 0.05, 0.06))
	draw_circle(Vector2(494, 375), 5.0, Color(0.2, 0.2, 0.22))


# --- 3. COCINA (Cam 03) ---
func _scene_kitchen(t: float, gl: Color) -> void:
	# Suelo de damero ajedrezado blanco y negro
	_box(Color(0.26, 0.27, 0.28), Color(0.14, 0.14, 0.15), Color(0.10, 0.10, 0.11))
	# Baldosas en perspectiva
	for gx in range(-4, 5):
		var xb: float = 640.0 + gx * 140.0
		var xt: float = 640.0 + gx * 55.0
		draw_line(Vector2(xb, FEED.end.y), Vector2(xt, BACK.end.y), Color(1, 1, 1, 0.12), 1.0)
	for gy in range(1, 7):
		var d: float = pow(float(gy) / 7.0, 1.6)
		var y: float = lerpf(BACK.end.y, FEED.end.y, d)
		var hw: float = lerpf(210.0, 610.0, d)
		draw_line(Vector2(640.0 - hw, y), Vector2(640.0 + hw, y), Color(1, 1, 1, 0.12), 1.0)

	# Azulejos en la pared del fondo
	for ax in 8:
		draw_line(Vector2(BACK.position.x + ax * 52.0, BACK.position.y), Vector2(BACK.position.x + ax * 52.0, BACK.end.y), Color(1, 1, 1, 0.06), 1.0)
	for ay in 6:
		draw_line(Vector2(BACK.position.x, BACK.position.y + ay * 48.0), Vector2(BACK.end.x, BACK.position.y + ay * 48.0), Color(1, 1, 1, 0.06), 1.0)

	# Mesas de trabajo de acero inoxidable
	var table := Rect2(470, 360, 340, 100)
	draw_rect(table, Color(0.18, 0.19, 0.21))
	draw_line(Vector2(table.position.x, table.position.y), Vector2(table.end.x, table.position.y), Color(0.85, 0.88, 0.92, 0.8), 2.5)
	# Quemadores de gas
	for k in 4:
		var qx: float = table.position.x + 45.0 + k * 80.0
		draw_circle(Vector2(qx, table.position.y + 14), 16.0, Color(0.08, 0.08, 0.09))
		draw_circle(Vector2(qx, table.position.y + 14), 8.0, Color(0.15, 0.15, 0.16))

	# Estante colgante superior con ollas y cuchillos en penumbra
	draw_line(Vector2(460, 190), Vector2(820, 190), Color(0.35, 0.35, 0.38), 3.0)
	for k in 4:
		var px: float = 500.0 + k * 85.0
		draw_line(Vector2(px, 190), Vector2(px, 225), Color(0.4, 0.4, 0.4), 1.5)
		# Sartén u olla
		draw_circle(Vector2(px, 240), 16.0, Color(0.28, 0.20, 0.14))
		draw_circle(Vector2(px, 240), 12.0, Color(0.15, 0.12, 0.10))

	# Altavoz del intercomunicador en la pared izquierda
	var spk := Vector2(240, 260)
	draw_rect(Rect2(spk.x - 20, spk.y - 20, 40, 40), Color(0.12, 0.12, 0.14))
	draw_circle(spk, 14.0, Color(0.3, 0.3, 0.32))
	draw_circle(spk, 10.0, Color(0.08, 0.08, 0.10))
	if night.intercom_cam == 3:
		# Ondas de jazz radiando del altavoz
		for w in 3:
			var wr: float = 18.0 + fmod(t * 25.0 + w * 12.0, 36.0)
			draw_arc(spk, wr, -PI * 0.4, PI * 0.4, 12, Color(GOLD.r, GOLD.g, GOLD.b, 0.7 - wr / 50.0), 2.0)


# --- 4 & 5. PASILLOS ESTE Y OESTE (Cam 04 y 05) ---
func _scene_hallway(cam: int, t: float, gl: Color) -> void:
	# Perspectiva de túnel oscuro de pasillo de hotel
	_box(Color(0.13, 0.09, 0.07), Color(0.08, 0.05, 0.05), Color(0.05, 0.04, 0.04))

	# Alfombra central burdeos
	var carpet := PackedVector2Array([
		Vector2(570, BACK.end.y), Vector2(710, BACK.end.y),
		Vector2(840, FEED.end.y), Vector2(440, FEED.end.y)
	])
	draw_colored_polygon(carpet, Color(0.25, 0.04, 0.06))
	draw_line(Vector2(570, BACK.end.y), Vector2(440, FEED.end.y), gl, 1.5)
	draw_line(Vector2(710, BACK.end.y), Vector2(840, FEED.end.y), gl, 1.5)

	# Puertas numeradas en los laterales
	var is_east: bool = (cam == 4)
	var n1: String = "104" if is_east else "101"
	var n2: String = "102" if is_east else "103"

	# Puertas izquierdas y derechas en perspectiva
	for s in 2:
		var py: float = 230.0 + s * 110.0
		var lx: float = 80.0 + s * 90.0
		var rx: float = 1140.0 - s * 90.0
		# Puerta izquierda
		draw_rect(Rect2(lx, py, 32, 90), Color(0.12, 0.07, 0.04))
		draw_rect(Rect2(lx, py, 32, 90), Color(GOLD.r, GOLD.g, GOLD.b, 0.25), false, 1.0)
		draw_circle(Vector2(lx + 26, py + 48), 2.5, GOLD)
		# Puerta derecha
		draw_rect(Rect2(rx, py, 32, 90), Color(0.12, 0.07, 0.04))
		draw_rect(Rect2(rx, py, 32, 90), Color(GOLD.r, GOLD.g, GOLD.b, 0.25), false, 1.0)
		draw_circle(Vector2(rx + 6, py + 48), 2.5, GOLD)

	# Lámparas de pared en aplique (antorchas)
	for a in 2:
		var ay: float = 240.0 + a * 120.0
		for ax in [210.0, 1070.0]:
			draw_circle(Vector2(ax, ay), 5.0, Color(1.0, 0.85, 0.45))
			draw_line(Vector2(ax, ay), Vector2(ax, ay + 14), GOLD, 2.0)
			# Conos suaves de luz hacia arriba y abajo
			draw_colored_polygon(PackedVector2Array([
				Vector2(ax - 2, ay), Vector2(ax + 2, ay),
				Vector2(ax + 22, ay + 38), Vector2(ax - 22, ay + 38)
			]), Color(1.0, 0.8, 0.35, 0.04))

	# Puerta blindada de acceso a la OFICINA al fondo
	var office_door := Rect2(595, 290, 90, 170)
	draw_rect(office_door, Color(0.15, 0.10, 0.06))
	draw_rect(office_door, gl, false, 2.0)
	draw_rect(Rect2(office_door.position.x + 28, office_door.position.y + 35, 34, 45), Color(0.04, 0.04, 0.05))
	draw_rect(Rect2(office_door.position.x + 28, office_door.position.y + 35, 34, 45), gl, false, 1.5)
	# Letrero de la puerta
	draw_string(ThemeDB.fallback_font, Vector2(office_door.position.x, office_door.position.y - 12), "OFICINA", HORIZONTAL_ALIGNMENT_CENTER, office_door.size.x, 14, gl)


# --- 6. CUARTO DE CALDERAS (Cam 06) ---
func _scene_boiler(t: float, gl: Color) -> void:
	# Sala industrial de carbón y hierro fundido
	_box(Color(0.10, 0.10, 0.12), Color(0.06, 0.06, 0.07), Color(0.04, 0.04, 0.05))
	_floor_grid(Color(1, 1, 1, 0.05))

	var glow: float = night.boiler_glow
	var bc := Vector2(640, 335)

	# Caldera monumental cilíndrica de remaches
	draw_circle(bc, 105.0, Color(0.18, 0.18, 0.20))
	draw_arc(bc, 105.0, 0.0, TAU, 36, Color(0.45, 0.45, 0.50), 4.0)
	# Hilera circular de remaches
	for rm in 18:
		var ra: float = rm * (TAU / 18.0)
		draw_circle(bc + Vector2(cos(ra), sin(ra)) * 96.0, 2.8, Color(0.6, 0.6, 0.65))

	# Portezuela inferior de fuego
	var f_box := Rect2(bc.x - 36, bc.y + 25, 72, 55)
	draw_rect(f_box, Color(0.06, 0.06, 0.08))
	draw_rect(f_box, Color(0.4, 0.4, 0.45), false, 2.0)

	# Fuego / brasas ardientes animadas
	var pulse: float = 0.5 + 0.5 * sin(t * 5.0)
	var fire_col := Color(1.0, 0.35 + glow * 0.3, 0.08)
	draw_circle(Vector2(bc.x, bc.y + 52), 18.0 + glow * 10.0 + pulse * 3.0, Color(fire_col.r, fire_col.g, fire_col.b, 0.85))
	# Rejas de la portezuela
	for r in 4:
		var rx: float = f_box.position.x + 12.0 + r * 14.0
		draw_line(Vector2(rx, f_box.position.y + 4), Vector2(rx, f_box.end.y - 4), Color(0.1, 0.1, 0.1), 3.0)

	# Resplandor intenso si se activó el Sobrecargo de Caldera
	if glow > 0.0:
		draw_circle(Vector2(bc.x, bc.y + 52), 90.0 * glow, Color(1.0, 0.45, 0.1, 0.25))

	# Manómetro de presión con aguja roja
	var gauge := Vector2(bc.x, bc.y - 50)
	draw_circle(gauge, 24.0, Color(0.88, 0.86, 0.82))
	draw_arc(gauge, 24.0, 0.0, TAU, 24, Color(0.6, 0.5, 0.2), 2.5)
	# Zona roja de peligro
	draw_arc(gauge, 18.0, -PI * 0.2, PI * 0.3, 8, Color(0.85, 0.1, 0.1), 3.0)
	# Aguja vibrando
	var needle_ang: float = 0.2 + (pulse * 0.2) + (glow * 0.8)
	draw_line(gauge, gauge + Vector2(cos(needle_ang), sin(needle_ang)) * 17.0, Color(0.8, 0.1, 0.1), 2.0)

	# Red de tuberías de vapor gruesas con bridas
	for k in 3:
		var py: float = 210.0 + k * 72.0
		draw_line(Vector2(FEED.position.x, py), Vector2(430, py), Color(0.42, 0.34, 0.26), 10.0)
		draw_line(Vector2(FEED.position.x, py - 3), Vector2(430, py - 3), Color(0.7, 0.6, 0.4, 0.4), 2.0)
		draw_line(Vector2(850, py), Vector2(FEED.end.x, py), Color(0.42, 0.34, 0.26), 10.0)
		draw_line(Vector2(850, py - 3), Vector2(FEED.end.x, py - 3), Color(0.7, 0.6, 0.4, 0.4), 2.0)
		# Ruedas de válvulas
		if k == 1:
			draw_circle(Vector2(320, py), 14.0, Color(0.65, 0.15, 0.15))
			draw_circle(Vector2(320, py), 6.0, Color(0.3, 0.3, 0.3))


# --- 7. CONDUCTOS DE VENTILACIÓN (Cam 07) ---
func _scene_ducts(t: float) -> void:
	# Túnel de ventilación cuadrado en perspectiva acelerada
	draw_rect(FEED, Color(0.045, 0.065, 0.048))

	# 9 secciones de chapa galvanizada
	for i in 9:
		var f: float = float(i) / 9.0
		var w: float = lerpf(FEED.size.x, 170.0, pow(f, 0.68))
		var h: float = lerpf(FEED.size.y, 95.0, pow(f, 0.68))
		var rect := Rect2(640.0 - w * 0.5, 360.0 - h * 0.5, w, h)
		draw_rect(rect, Color(0.28, 0.48, 0.30, 0.55), false, 2.5)

		# Remaches en las esquinas de cada sección
		for p in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			draw_circle(p, 2.2, Color(0.35, 0.60, 0.38, 0.7))

	# Marcas de arrastre y rasguños en el fondo metálico
	for sc in 6:
		var sy: float = 370.0 + sc * 12.0
		draw_line(Vector2(610 - sc * 8, sy), Vector2(670 + sc * 8, sy + 3), Color(0.02, 0.03, 0.02, 0.6), 2.0)


# ================================================================ ENTIDADES

func _entities(cam: int, t: float) -> void:
	var idx: int = 0
	for m in night.monsters:
		idx += 1
		if m.key == "mucama":
			if cam == 7 and m.s != 0:
				var rr: float = lerpf(14.0, 120.0, m.progress)
				Figures.draw_face(self, "mucama", Vector2(640.0 + sin(t * 3.0) * 4.0, 340.0), rr, 0.1)
			continue
		if m.location != cam:
			continue
		var pos: Vector2 = m.cam_pos()
		var d: float = clampf(pos.y, 0.0, 1.0)
		var y: float = lerpf(BACK.end.y, FEED.end.y, d)
		var hw: float = lerpf(210.0, 610.0, d)
		var x: float = 640.0 + pos.x * hw + sin(t * 1.3 + idx) * 3.0
		var sc: float = lerpf(0.9, 2.2, d)
		Figures.draw_figure(self, m.key, Vector2(x, y), sc, 0.1)


func _music_box(t: float) -> void:
	var charge: float = night.box_charge
	var wake: float = 0.0
	for m in night.monsters:
		if m.key == "bailarina":
			wake = m.awake_amount()
	var base := Vector2(930.0, 455.0)

	# Pedestal de caoba
	draw_rect(Rect2(base.x - 46, base.y - 70, 92, 70), Color(0.18, 0.12, 0.06))
	draw_rect(Rect2(base.x - 54, base.y - 78, 108, 10), Color(0.32, 0.24, 0.10))
	draw_rect(Rect2(base.x - 54, base.y - 78, 108, 10), GOLD, false, 2.0)

	# Caja de música
	draw_rect(Rect2(base.x - 40, base.y - 112, 80, 36), Color(0.25, 0.11, 0.08))
	draw_rect(Rect2(base.x - 40, base.y - 112, 80, 36), GOLD, false, 2.0)
	draw_rect(Rect2(base.x - 34, base.y - 106, 68, 6), Color(GOLD.r, GOLD.g, GOLD.b, 0.5))

	# Manivela giratoria
	var ang: float = t * 3.0 * clampf(charge * 4.0, 0.0, 1.0)
	var crank := Vector2(base.x + 40, base.y - 94)
	draw_line(crank, crank + Vector2(cos(ang), sin(ang)) * 16.0, GOLD, 3.0)
	draw_circle(crank + Vector2(cos(ang), sin(ang)) * 16.0, 3.5, GOLD)

	# Bailarina
	var h: float = lerpf(34.0, 96.0, wake)
	var top := Vector2(base.x + sin(t * 2.0) * 3.0 * wake, base.y - 112 - h)
	var tint: Color = Color(0.92, 0.88, 0.80).lerp(Color(1.0, 0.55, 0.5), wake)
	draw_line(Vector2(base.x, base.y - 112), top, tint, 3.0)
	draw_circle(top, 7.0 + 3.0 * wake, tint)
	var tutu := Vector2(base.x, base.y - 112 - h * 0.35)
	draw_colored_polygon(PackedVector2Array([
		tutu + Vector2(-22, 6), tutu + Vector2(22, 6),
		tutu + Vector2(8, -8), tutu + Vector2(-8, -8)
	]), Color(0.9, 0.85, 0.9, 0.9))
	if wake > 0.25:
		draw_circle(top + Vector2(-3, -1), 1.8, Color(1, 0.15, 0.1))
		draw_circle(top + Vector2(3, -1), 1.8, Color(1, 0.15, 0.1))

	# Notas musicales flotando
	if charge > 0.0:
		for i in 3:
			var ph: float = fmod(t * 0.6 + i * 0.33, 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(base.x - 30 + i * 28 + sin(ph * 6.0) * 6.0, base.y - 130 - ph * 70.0), "♪", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(GOLD.r, GOLD.g, GOLD.b, 1.0 - ph))
