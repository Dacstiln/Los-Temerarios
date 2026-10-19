extends RefCounted
## Dibujo procedural de los monstruos (placeholders de arte).
## `dark` oscurece el cuerpo (siluetas tras las rejas) pero los ojos siempre brillan.

const SKIN := Color(0.85, 0.78, 0.66)
const RED_UNIFORM := Color(0.55, 0.08, 0.10)
const GOLD := Color(0.83, 0.69, 0.22)
const WHITE := Color(0.90, 0.90, 0.88)
const BLACK_DRESS := Color(0.08, 0.08, 0.10)


static func _c(col: Color, dark: float) -> Color:
	return col.lerp(Color(0.02, 0.02, 0.03, col.a), clampf(dark, 0.0, 1.0))


static func _rect(ci: CanvasItem, foot: Vector2, s: float, x: float, y: float, w: float, h: float, col: Color) -> void:
	ci.draw_rect(Rect2(foot + Vector2(x, y) * s, Vector2(w, h) * s), col)


static func _circ(ci: CanvasItem, foot: Vector2, s: float, x: float, y: float, r: float, col: Color) -> void:
	ci.draw_circle(foot + Vector2(x, y) * s, r * s, col)


static func _poly(ci: CanvasItem, foot: Vector2, s: float, pts: Array, col: Color) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(foot + (p as Vector2) * s)
	ci.draw_colored_polygon(arr, col)


## Figura de cuerpo completo. `foot` = punto de los pies (centro inferior). Altura ~190 * s.
static func draw_figure(ci: CanvasItem, kind: String, foot: Vector2, s: float, dark: float = 0.0) -> void:
	match kind:
		"botones": _botones(ci, foot, s, dark)
		"chef": _chef(ci, foot, s, dark)
		"mucama": _mucama(ci, foot, s, dark)
		"cornelius": _cornelius(ci, foot, s, dark)


static func _botones(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var red: Color = _c(RED_UNIFORM, d)
	var skin: Color = _c(SKIN, d)
	_rect(ci, f, s, -18, -58, 16, 58, _c(Color(0.10, 0.10, 0.12), d))
	_rect(ci, f, s, 2, -58, 16, 58, _c(Color(0.10, 0.10, 0.12), d))
	_rect(ci, f, s, -22, -122, 44, 66, red)
	_rect(ci, f, s, -33, -120, 11, 56, red)
	_rect(ci, f, s, 22, -120, 11, 56, red)
	for i in 3:
		_circ(ci, f, s, 0, -110 + i * 15, 3.0, _c(GOLD, d))
	_circ(ci, f, s, 0, -142, 18, skin)
	_rect(ci, f, s, -16, -172, 32, 17, red)
	_rect(ci, f, s, -16, -158, 32, 3, _c(GOLD, d))
	# ojos: huecos negros con brillo
	_circ(ci, f, s, -7, -144, 4.5, Color(0, 0, 0))
	_circ(ci, f, s, 7, -144, 4.5, Color(0, 0, 0))
	_circ(ci, f, s, -7, -144, 2.0, Color(1, 1, 0.9))
	_circ(ci, f, s, 7, -144, 2.0, Color(1, 1, 0.9))


static func _chef(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var white: Color = _c(WHITE, d)
	var skin: Color = _c(SKIN, d)
	_rect(ci, f, s, -22, -60, 18, 60, _c(Color(0.15, 0.15, 0.17), d))
	_rect(ci, f, s, 4, -60, 18, 60, _c(Color(0.15, 0.15, 0.17), d))
	_rect(ci, f, s, -30, -128, 60, 72, white)
	_rect(ci, f, s, -41, -126, 12, 58, white)
	_rect(ci, f, s, 29, -126, 12, 58, white)
	_circ(ci, f, s, -8, -95, 5, _c(Color(0.5, 0.05, 0.05), d))
	_circ(ci, f, s, 10, -80, 4, _c(Color(0.5, 0.05, 0.05), d))
	_circ(ci, f, s, 0, -150, 20, skin)
	_rect(ci, f, s, -15, -190, 30, 22, white)
	_circ(ci, f, s, -13, -192, 11, white)
	_circ(ci, f, s, 0, -198, 12, white)
	_circ(ci, f, s, 13, -192, 11, white)
	ci.draw_line(f + Vector2(41, -70) * s, f + Vector2(58, -118) * s, _c(Color(0.6, 0.6, 0.65), d), 5.0 * s)
	_circ(ci, f, s, -8, -152, 4.5, Color(0, 0, 0))
	_circ(ci, f, s, 8, -152, 4.5, Color(0, 0, 0))
	_circ(ci, f, s, -8, -152, 2.0, Color(1, 0.2, 0.1))
	_circ(ci, f, s, 8, -152, 2.0, Color(1, 0.2, 0.1))


static func _mucama(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var dress: Color = _c(BLACK_DRESS, maxf(d - 0.3, 0.0))
	var skin: Color = _c(SKIN, d)
	_poly(ci, f, s, [Vector2(-32, 0), Vector2(32, 0), Vector2(15, -122), Vector2(-15, -122)], dress)
	_poly(ci, f, s, [Vector2(-14, -8), Vector2(14, -8), Vector2(9, -100), Vector2(-9, -100)], _c(WHITE, d))
	_rect(ci, f, s, -26, -118, 8, 58, dress)
	_rect(ci, f, s, 18, -118, 8, 58, dress)
	_circ(ci, f, s, 0, -140, 17, skin)
	_rect(ci, f, s, -15, -162, 30, 9, _c(WHITE, d))
	# ciega: ojos blancos sin pupila
	_circ(ci, f, s, -6, -142, 4.0, Color(0.95, 0.95, 0.9))
	_circ(ci, f, s, 6, -142, 4.0, Color(0.95, 0.95, 0.9))


## Primer plano (jumpscare / Mucama en ductos). `c` = centro de la cabeza, `r` = radio.
static func draw_face(ci: CanvasItem, kind: String, c: Vector2, r: float, dark: float = 0.0) -> void:
	var body: Color = RED_UNIFORM
	if kind == "chef":
		body = WHITE
	elif kind == "mucama" or kind == "cornelius":
		body = BLACK_DRESS
	ci.draw_rect(Rect2(c.x - r * 1.5, c.y + r * 0.9, r * 3.0, r * 2.4), _c(body, dark))
	ci.draw_circle(c, r, _c(SKIN, dark))
	match kind:
		"botones":
			ci.draw_rect(Rect2(c.x - r * 0.9, c.y - r * 1.5, r * 1.8, r * 0.8), _c(RED_UNIFORM, dark))
			ci.draw_rect(Rect2(c.x - r * 0.9, c.y - r * 0.85, r * 1.8, r * 0.14), _c(GOLD, dark))
		"chef":
			ci.draw_rect(Rect2(c.x - r * 0.8, c.y - r * 1.6, r * 1.6, r * 0.9), _c(WHITE, dark))
			ci.draw_circle(Vector2(c.x - r * 0.7, c.y - r * 1.65), r * 0.5, _c(WHITE, dark))
			ci.draw_circle(Vector2(c.x, c.y - r * 1.9), r * 0.55, _c(WHITE, dark))
			ci.draw_circle(Vector2(c.x + r * 0.7, c.y - r * 1.65), r * 0.5, _c(WHITE, dark))
		"mucama":
			ci.draw_rect(Rect2(c.x - r * 0.95, c.y - r * 1.2, r * 1.9, r * 0.45), _c(WHITE, dark))
		"cornelius":
			ci.draw_rect(Rect2(c.x - r * 0.7, c.y - r * 2.1, r * 1.4, r * 1.3), _c(Color(0.04, 0.04, 0.05), dark))
			ci.draw_rect(Rect2(c.x - r * 0.7, c.y - r * 1.1, r * 1.4, r * 0.16), _c(GOLD, dark))
			ci.draw_rect(Rect2(c.x - r * 1.15, c.y - r * 0.85, r * 2.3, r * 0.16), _c(Color(0.04, 0.04, 0.05), dark))
	var ey: float = c.y - r * 0.1
	var ex: float = r * 0.38
	if kind == "mucama":
		ci.draw_circle(Vector2(c.x - ex, ey), r * 0.2, Color(0.95, 0.95, 0.9))
		ci.draw_circle(Vector2(c.x + ex, ey), r * 0.2, Color(0.95, 0.95, 0.9))
	else:
		var glow: Color = Color(1, 0.2, 0.1) if kind == "chef" else (Color(1.0, 0.8, 0.2) if kind == "cornelius" else Color(1, 1, 0.9))
		ci.draw_circle(Vector2(c.x - ex, ey), r * 0.2, Color(0, 0, 0))
		ci.draw_circle(Vector2(c.x + ex, ey), r * 0.2, Color(0, 0, 0))
		ci.draw_circle(Vector2(c.x - ex, ey), r * 0.08, glow)
		ci.draw_circle(Vector2(c.x + ex, ey), r * 0.08, glow)
	# boca abierta con dientes
	var mw: float = r * 0.6
	var my: float = c.y + r * 0.45
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - mw, my), Vector2(c.x + mw, my),
		Vector2(c.x + mw * 0.7, my + r * 0.5), Vector2(c.x - mw * 0.7, my + r * 0.5)
	]), Color(0.25, 0.02, 0.03))
	for i in 5:
		var x0: float = c.x - mw + i * (2.0 * mw / 5.0)
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(x0, my), Vector2(x0 + 2.0 * mw / 5.0, my),
			Vector2(x0 + mw / 5.0, my + r * 0.2)
		]), Color(0.95, 0.95, 0.9))


## Cornelius: alto, de negro, con sombrero de copa y reloj de bolsillo dorado. Altura ~235 * s.
static func _cornelius(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var suit: Color = _c(Color(0.05, 0.05, 0.07), d * 0.6)
	var skin: Color = _c(Color(0.80, 0.78, 0.70), d)
	_rect(ci, f, s, -18, -84, 14, 84, suit)
	_rect(ci, f, s, 4, -84, 14, 84, suit)
	_poly(ci, f, s, [Vector2(-28, -80), Vector2(28, -80), Vector2(22, -162), Vector2(-22, -162)], suit)
	_poly(ci, f, s, [Vector2(-28, -80), Vector2(-14, -80), Vector2(-24, -34)], suit)
	_poly(ci, f, s, [Vector2(28, -80), Vector2(14, -80), Vector2(24, -34)], suit)
	_rect(ci, f, s, -39, -160, 10, 104, suit)
	_rect(ci, f, s, 29, -160, 10, 104, suit)
	for i in 4:
		ci.draw_line(f + Vector2(-36 + i * 2.5, -56) * s, f + Vector2(-38 + i * 3.0, -30) * s, skin, 1.6 * s)
		ci.draw_line(f + Vector2(31 + i * 2.5, -56) * s, f + Vector2(31 + i * 3.0, -30) * s, skin, 1.6 * s)
	_rect(ci, f, s, -5, -156, 10, 72, _c(GOLD, d + 0.45))
	ci.draw_line(f + Vector2(-12, -128) * s, f + Vector2(9, -108) * s, _c(GOLD, d), 2.0 * s)
	_circ(ci, f, s, 10, -106, 6, _c(GOLD, d))
	_circ(ci, f, s, 0, -180, 17, skin)
	_rect(ci, f, s, -16, -234, 32, 42, _c(Color(0.04, 0.04, 0.05), d * 0.6))
	_rect(ci, f, s, -16, -204, 32, 6, _c(GOLD, d))
	_rect(ci, f, s, -26, -196, 52, 6, _c(Color(0.04, 0.04, 0.05), d * 0.6))
	_circ(ci, f, s, -6, -178, 4.5, Color(0, 0, 0))
	_circ(ci, f, s, 6, -178, 4.5, Color(0, 0, 0))
	_circ(ci, f, s, -6, -178, 2.0, Color(1.0, 0.8, 0.2))
	_circ(ci, f, s, 6, -178, 2.0, Color(1.0, 0.8, 0.2))
