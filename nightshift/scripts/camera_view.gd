extends Control
## Monitor de camaras CRT: dibuja la camara seleccionada (placeholder procedural),
## los monstruos que estan en ella, estatica y el sello de camara.
## Camaras oscuras (Pasillos, Calderas) solo se ven con el Flash.

const Map = preload("res://scripts/map.gd")
const Figures = preload("res://scripts/figures.gd")

var night = null

const FEED := Rect2(30.0, 30.0, 1220.0, 660.0)
const BACK := Rect2(430.0, 170.0, 420.0, 290.0)
const GOLD := Color(0.83, 0.69, 0.22)


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
	draw_rect(FEED, Color(0.03, 0.035, 0.035))

	var blind: bool = night.cams[cam].is_blind()
	var flash: float = night.flash_time
	var lit: bool = (not Map.is_dark(cam)) or flash > 0.0

	if blind:
		_static(t, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(0, 360), "SIN SEÑAL", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 48, Color(1, 1, 1, 0.7))
	elif not lit:
		_draw_dark(t)
	else:
		_scene(cam)
		_entities(cam, t)
		if flash > 0.0:
			draw_rect(FEED, Color(1, 1, 1, clampf(flash, 0.0, 1.0) * 0.30))
		if cam == 7:
			draw_rect(FEED, Color(0.0, 0.5, 0.1, 0.16))

	_static(t, 1.0 if cam == 7 else 0.6)
	_labels(cam, t)


# ------------------------------------------------------------------ utilidades

func _static(t: float, strength: float) -> void:
	for i in int(40.0 + 120.0 * strength):
		var y: float = FEED.position.y + randf() * FEED.size.y
		var x: float = FEED.position.x + randf() * FEED.size.x
		var w: float = 20.0 + randf() * 160.0
		draw_line(Vector2(x, y), Vector2(minf(x + w, FEED.end.x), y), Color(1, 1, 1, randf() * 0.06 * (1.0 + strength * 2.0)), 1.0)
	var by: float = FEED.position.y + fmod(t * 120.0, FEED.size.y)
	draw_rect(Rect2(FEED.position.x, by, FEED.size.x, 40.0), Color(1, 1, 1, 0.03))


func _draw_dark(_t: float) -> void:
	draw_rect(FEED, Color(0.02, 0.02, 0.025))
	if randf() < 0.1:
		draw_rect(FEED, Color(0.08, 0.09, 0.09, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(0, 360), "SIN LUZ", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 40, Color(1, 1, 1, 0.22))
	draw_string(ThemeDB.fallback_font, Vector2(0, 396), "[F] FLASH DE CÁMARA", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 20, Color(GOLD.r, GOLD.g, GOLD.b, 0.5))
	# Pista sutil: destello dorado donde Cornelius se oculta.
	for m in night.monsters:
		if m.key == "cornelius" and m.glint_on(night.current_cam):
			draw_circle(Vector2(699, 299), 3.0, Color(0.95, 0.78, 0.2, 0.85))
			draw_circle(Vector2(717, 299), 3.0, Color(0.95, 0.78, 0.2, 0.85))


func _labels(cam: int, t: float) -> void:
	draw_rect(FEED, Color(0.6, 0.6, 0.55, 0.5), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(0, 92), Map.cam_name(cam), HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 24, Color(0.8, 1.0, 0.85))
	if fmod(t, 1.2) < 0.7:
		draw_circle(Vector2(430, 84), 7.0, Color(0.9, 0.1, 0.1))
		draw_string(font, Vector2(442, 91), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.9, 0.2, 0.2))
	draw_string(font, Vector2(0, 640), "GRAND TENEBRIS — SEGURIDAD", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 16, Color(0.8, 1.0, 0.85, 0.5))
	if night.intercom_cam == cam:
		var a: float = 0.6 + 0.4 * sin(t * 6.0)
		draw_string(font, Vector2(0, 130), "[ JAZZ SONANDO EN ESTA CÁMARA ]", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 22, Color(GOLD.r, GOLD.g, GOLD.b, a))


# ---------------------------------------------------------------------- escenas

func _box(wall: Color, floor_c: Color, ceil_c: Color) -> void:
	var f: Rect2 = FEED
	var bl: Vector2 = BACK.position
	var br := Vector2(BACK.end.x, BACK.position.y)
	var bbl := Vector2(BACK.position.x, BACK.end.y)
	var bbr: Vector2 = BACK.end
	draw_colored_polygon(PackedVector2Array([f.position, Vector2(f.end.x, f.position.y), br, bl]), ceil_c)
	draw_colored_polygon(PackedVector2Array([Vector2(f.position.x, f.end.y), f.end, bbr, bbl]), floor_c)
	draw_colored_polygon(PackedVector2Array([f.position, bl, bbl, Vector2(f.position.x, f.end.y)]), wall.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(f.end.x, f.position.y), br, bbr, f.end]), wall.darkened(0.25))
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


func _scene(cam: int) -> void:
	var gl := Color(GOLD.r, GOLD.g, GOLD.b, 0.5)
	var grid := Color(GOLD.r, GOLD.g, GOLD.b, 0.14)
	match cam:
		1: # Lobby principal
			_box(Color(0.20, 0.15, 0.09), Color(0.09, 0.08, 0.07), Color(0.07, 0.06, 0.05))
			_floor_grid(grid)
			var c := Vector2(640, 370)
			draw_arc(c, 75.0, 0.0, TAU, 40, gl, 3.0)
			draw_line(c + Vector2(-75, 0), c + Vector2(75, 0), gl, 3.0)
			draw_line(c + Vector2(0, -75), c + Vector2(0, 75), gl, 3.0)
			draw_rect(Rect2(470, 170, 24, 290), Color(0.30, 0.24, 0.12))
			draw_rect(Rect2(786, 170, 24, 290), Color(0.30, 0.24, 0.12))
			draw_line(Vector2(640, 30), Vector2(640, 90), gl, 2.0)
			draw_arc(Vector2(640, 110), 40.0, 0.0, PI, 20, gl, 3.0)
		2: # Recepcion
			_box(Color(0.17, 0.12, 0.09), Color(0.08, 0.07, 0.06), Color(0.06, 0.05, 0.05))
			_floor_grid(grid)
			for gx in 6:
				for gy in 3:
					draw_rect(Rect2(540 + gx * 34, 215 + gy * 34, 26, 26), Color(0.30, 0.24, 0.12), false, 2.0)
			draw_rect(Rect2(480, 400, 320, 60), Color(0.22, 0.13, 0.07))
			draw_line(Vector2(480, 400), Vector2(800, 400), gl, 3.0)
			draw_circle(Vector2(640, 392), 9.0, gl)
		3: # Cocina
			_box(Color(0.30, 0.30, 0.28), Color(0.14, 0.14, 0.13), Color(0.12, 0.12, 0.11))
			_floor_grid(Color(1, 1, 1, 0.08))
			for gx in 8:
				draw_line(Vector2(430 + gx * 52, 170), Vector2(430 + gx * 52, 460), Color(1, 1, 1, 0.10), 1.0)
			for gy in 5:
				draw_line(Vector2(430, 170 + gy * 58), Vector2(850, 170 + gy * 58), Color(1, 1, 1, 0.10), 1.0)
			draw_rect(Rect2(470, 360, 340, 100), Color(0.18, 0.18, 0.19))
			for k in 4:
				draw_circle(Vector2(520 + k * 80, 372), 18.0, Color(0.05, 0.05, 0.05))
			for k in 3:
				draw_line(Vector2(540 + k * 100, 170), Vector2(540 + k * 100, 230), Color(0.5, 0.5, 0.5), 2.0)
				draw_circle(Vector2(540 + k * 100, 245), 18.0, Color(0.4, 0.4, 0.42))
		4, 5: # Pasillos
			_box(Color(0.12, 0.09, 0.07), Color(0.06, 0.05, 0.05), Color(0.05, 0.04, 0.04))
			_floor_grid(Color(GOLD.r, GOLD.g, GOLD.b, 0.10))
			draw_rect(Rect2(600, 300, 80, 160), Color(0.16, 0.11, 0.06))
			draw_rect(Rect2(600, 300, 80, 160), gl, false, 2.0)
			draw_string(ThemeDB.fallback_font, Vector2(600, 292), "OFICINA", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 14, gl)
			for k in 3:
				var yy: float = 200.0 + k * 90.0
				draw_rect(Rect2(60 + k * 60, yy, 18, 30), Color(1.0, 0.75, 0.3, 0.6))
				draw_rect(Rect2(1180 - k * 60, yy, 18, 30), Color(1.0, 0.75, 0.3, 0.6))
		6: # Cuarto de calderas
			_box(Color(0.10, 0.11, 0.12), Color(0.05, 0.05, 0.06), Color(0.04, 0.04, 0.05))
			_floor_grid(Color(1, 1, 1, 0.05))
			draw_circle(Vector2(640, 340), 95.0, Color(0.20, 0.20, 0.22))
			draw_arc(Vector2(640, 340), 95.0, 0.0, TAU, 40, Color(0.5, 0.5, 0.55), 4.0)
			draw_circle(Vector2(640, 300), 24.0, Color(0.9, 0.9, 0.85))
			draw_line(Vector2(640, 300), Vector2(656, 288), Color(0.8, 0.1, 0.1), 3.0)
			for k in 3:
				var py: float = 220.0 + k * 70.0
				draw_line(Vector2(FEED.position.x, py), Vector2(430, py), Color(0.45, 0.35, 0.25), 8.0)
				draw_line(Vector2(850, py), Vector2(FEED.end.x, py), Color(0.45, 0.35, 0.25), 8.0)
		7: # Conductos de ventilacion (tunel)
			draw_rect(FEED, Color(0.05, 0.07, 0.05))
			for i in 9:
				var f: float = float(i) / 9.0
				var w: float = lerpf(FEED.size.x, 180.0, pow(f, 0.7))
				var h: float = lerpf(FEED.size.y, 100.0, pow(f, 0.7))
				draw_rect(Rect2(640.0 - w * 0.5, 360.0 - h * 0.5, w, h), Color(0.3, 0.45, 0.3, 0.55), false, 3.0)


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
