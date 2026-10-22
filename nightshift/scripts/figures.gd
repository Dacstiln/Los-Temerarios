extends RefCounted
## Dibujo procedural de los monstruos (v2: mas detalle, sombreado y siluetas propias).
## `dark` oscurece el cuerpo (siluetas tras las rejas) pero los ojos siempre brillan.
##
## Convencion: todo se dibuja en unidades "de figura" con los pies en (0,0) y la altura hacia
## arriba (y negativa). `s` escala la figura completa. Cada monstruo tiene una silueta distinta
## para reconocerlo incluso a oscuras: Botones (gorra cuadrada), Chef (gorro alto), Mucama
## (vestido largo y cofia), Cornelius (sombrero de copa), Bailarina (tutu).

const SKIN := Color(0.86, 0.79, 0.68)
const SKIN_SHADE := Color(0.60, 0.52, 0.44)
const RED_UNIFORM := Color(0.58, 0.08, 0.11)
const RED_DARK := Color(0.33, 0.04, 0.07)
const GOLD := Color(0.83, 0.69, 0.22)
const GOLD_DARK := Color(0.50, 0.40, 0.10)
const WHITE := Color(0.92, 0.91, 0.88)
const GREY := Color(0.70, 0.70, 0.72)
const BLACK_DRESS := Color(0.09, 0.09, 0.12)
const INK := Color(0.03, 0.03, 0.04)


# ------------------------------------------------------------------ utilidades

static func _c(col: Color, dark: float) -> Color:
	return col.lerp(Color(0.02, 0.02, 0.03, col.a), clampf(dark, 0.0, 1.0))


static func _pt(foot: Vector2, s: float, p: Vector2) -> Vector2:
	return foot + p * s


static func _poly(ci: CanvasItem, foot: Vector2, s: float, pts: Array, col: Color) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(foot + (p as Vector2) * s)
	ci.draw_colored_polygon(arr, col)


static func _line(ci: CanvasItem, foot: Vector2, s: float, a: Vector2, b: Vector2, col: Color, w: float = 2.0) -> void:
	ci.draw_line(foot + a * s, foot + b * s, col, maxf(w * s, 1.0))


static func _rect(ci: CanvasItem, foot: Vector2, s: float, x: float, y: float, w: float, h: float, col: Color) -> void:
	ci.draw_rect(Rect2(foot + Vector2(x, y) * s, Vector2(w, h) * s), col)


static func _circ(ci: CanvasItem, foot: Vector2, s: float, x: float, y: float, r: float, col: Color) -> void:
	ci.draw_circle(foot + Vector2(x, y) * s, r * s, col)


## Elipse rellena (cabezas, manchas, sombras).
static func _ell(ci: CanvasItem, foot: Vector2, s: float, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var arr := PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		arr.append(foot + Vector2(cx + cos(a) * rx, cy + sin(a) * ry) * s)
	ci.draw_colored_polygon(arr, col)


static func _shadow(ci: CanvasItem, foot: Vector2, s: float, rx: float) -> void:
	_ell(ci, foot, s, 0, 2, rx, 6, Color(0, 0, 0, 0.45))


## Cabeza con sombra lateral y mejilla: vuelve la cara mas volumetrica.
static func _head(ci: CanvasItem, foot: Vector2, s: float, cx: float, cy: float, rx: float, ry: float, d: float) -> void:
	_ell(ci, foot, s, cx, cy, rx, ry, _c(SKIN, d))
	_ell(ci, foot, s, cx + rx * 0.28, cy + ry * 0.05, rx * 0.72, ry * 0.92, _c(SKIN_SHADE, d + 0.1).lerp(_c(SKIN, d), 0.55))
	_ell(ci, foot, s, cx - rx * 0.30, cy - ry * 0.20, rx * 0.32, ry * 0.28, _c(SKIN, d).lightened(0.12))


## Ojo hundido: cuenca oscura + brillo propio (el brillo NO se oscurece con `dark`).
static func _eye(ci: CanvasItem, foot: Vector2, s: float, x: float, y: float, r: float, glow: Color) -> void:
	_ell(ci, foot, s, x, y, r * 1.35, r * 1.05, Color(0.02, 0.0, 0.0, 0.92))
	_circ(ci, foot, s, x, y, r * 0.62, glow)
	_circ(ci, foot, s, x - r * 0.18, y - r * 0.2, r * 0.2, Color(1, 1, 1, 0.9))


## Figura de cuerpo completo. `foot` = punto de los pies (centro inferior). Altura ~190 * s.
static func draw_figure(ci: CanvasItem, kind: String, foot: Vector2, s: float, dark: float = 0.0) -> void:
	match kind:
		"botones": _botones(ci, foot, s, dark)
		"chef": _chef(ci, foot, s, dark)
		"mucama": _mucama(ci, foot, s, dark)
		"cornelius": _cornelius(ci, foot, s, dark)
		"bailarina": _bailarina(ci, foot, s, dark)


# ------------------------------------------------------------------- BOTONES

static func _botones(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var red: Color = _c(RED_UNIFORM, d)
	var red_d: Color = _c(RED_DARK, d)
	var gold: Color = _c(GOLD, d)
	var trou: Color = _c(Color(0.08, 0.08, 0.10), d)
	_shadow(ci, f, s, 34)
	# piernas con franja dorada y zapatos
	_poly(ci, f, s, [Vector2(-19, -62), Vector2(-3, -62), Vector2(-5, -6), Vector2(-21, -6)], trou)
	_poly(ci, f, s, [Vector2(3, -62), Vector2(19, -62), Vector2(21, -6), Vector2(5, -6)], trou)
	_line(ci, f, s, Vector2(-17, -60), Vector2(-19, -8), gold, 1.6)
	_line(ci, f, s, Vector2(17, -60), Vector2(19, -8), gold, 1.6)
	_ell(ci, f, s, -13, -3, 13, 5, _c(INK, d * 0.5))
	_ell(ci, f, s, 13, -3, 13, 5, _c(INK, d * 0.5))
	# brazos (mangas) y guantes blancos
	_poly(ci, f, s, [Vector2(-24, -122), Vector2(-36, -118), Vector2(-40, -62), Vector2(-30, -60)], red)
	_poly(ci, f, s, [Vector2(24, -122), Vector2(36, -118), Vector2(40, -62), Vector2(30, -60)], red_d)
	_ell(ci, f, s, -35, -54, 7, 9, _c(WHITE, d))
	_ell(ci, f, s, 35, -54, 7, 9, _c(WHITE, d * 1.1))
	# torso: chaqueta con solapa y botonadura doble
	_poly(ci, f, s, [Vector2(-25, -126), Vector2(25, -126), Vector2(22, -58), Vector2(-22, -58)], red)
	_poly(ci, f, s, [Vector2(4, -126), Vector2(25, -126), Vector2(22, -58), Vector2(4, -58)], red_d)
	_line(ci, f, s, Vector2(0, -126), Vector2(0, -58), gold, 1.5)
	for i in 4:
		_circ(ci, f, s, -9, -114 + i * 14, 2.8, gold)
		_circ(ci, f, s, 9, -114 + i * 14, 2.8, gold)
	# charreteras con flecos
	_rect(ci, f, s, -34, -128, 16, 6, gold)
	_rect(ci, f, s, 18, -128, 16, 6, gold)
	for i in 4:
		_line(ci, f, s, Vector2(-33 + i * 4.5, -122), Vector2(-33 + i * 4.5, -115), gold, 1.0)
		_line(ci, f, s, Vector2(19 + i * 4.5, -122), Vector2(19 + i * 4.5, -115), gold, 1.0)
	# cuello y cabeza
	_rect(ci, f, s, -6, -134, 12, 10, _c(SKIN_SHADE, d))
	_head(ci, f, s, 0, -148, 19, 22, d)
	# gorra de botones: copa cuadrada, visera y barboquejo
	_poly(ci, f, s, [Vector2(-18, -166), Vector2(18, -166), Vector2(15, -182), Vector2(-15, -182)], red)
	_poly(ci, f, s, [Vector2(2, -166), Vector2(18, -166), Vector2(15, -182), Vector2(2, -182)], red_d)
	_rect(ci, f, s, -19, -168, 38, 4, gold)
	_line(ci, f, s, Vector2(-19, -150), Vector2(-14, -134), _c(INK, d), 1.4)
	_line(ci, f, s, Vector2(19, -150), Vector2(14, -134), _c(INK, d), 1.4)
	_circ(ci, f, s, 0, -188, 3.0, gold)
	# cara: cejas, ojos huecos y sonrisa cosida demasiado ancha
	_line(ci, f, s, Vector2(-13, -158), Vector2(-3, -155), _c(INK, d * 0.4), 1.8)
	_line(ci, f, s, Vector2(13, -158), Vector2(3, -155), _c(INK, d * 0.4), 1.8)
	_eye(ci, f, s, -7, -149, 4.6, Color(1, 1, 0.9))
	_eye(ci, f, s, 7, -149, 4.6, Color(1, 1, 0.9))
	var smile := PackedVector2Array()
	for i in 11:
		var u: float = float(i) / 10.0
		smile.append(f + Vector2(-15.0 + u * 30.0, -136.0 + sin(u * PI) * 6.0) * s)
	ci.draw_polyline(smile, _c(Color(0.25, 0.02, 0.03), d * 0.3), maxf(1.6 * s, 1.0))
	for i in 6:
		var u: float = float(i) / 5.0
		var px: float = -13.0 + u * 26.0
		var py: float = -136.0 + sin((px + 15.0) / 30.0 * PI) * 6.0
		_line(ci, f, s, Vector2(px, py - 2), Vector2(px, py + 3), _c(INK, d * 0.3), 1.0)


# ---------------------------------------------------------------------- CHEF

static func _chef(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var white: Color = _c(WHITE, d)
	var shade: Color = _c(Color(0.62, 0.61, 0.60), d)
	var blood: Color = _c(Color(0.45, 0.04, 0.05), d)
	_shadow(ci, f, s, 42)
	# pantalon de cuadros y botas
	_poly(ci, f, s, [Vector2(-26, -64), Vector2(-2, -64), Vector2(-4, -6), Vector2(-26, -6)], _c(Color(0.18, 0.18, 0.20), d))
	_poly(ci, f, s, [Vector2(2, -64), Vector2(26, -64), Vector2(26, -6), Vector2(4, -6)], _c(Color(0.14, 0.14, 0.16), d))
	for i in 4:
		_line(ci, f, s, Vector2(-26, -58 + i * 14), Vector2(-3, -58 + i * 14), _c(Color(0.3, 0.3, 0.33), d), 1.0)
		_line(ci, f, s, Vector2(3, -58 + i * 14), Vector2(26, -58 + i * 14), _c(Color(0.3, 0.3, 0.33), d), 1.0)
	_ell(ci, f, s, -15, -3, 15, 6, _c(INK, d * 0.5))
	_ell(ci, f, s, 15, -3, 15, 6, _c(INK, d * 0.5))
	# brazos gruesos remangados
	_poly(ci, f, s, [Vector2(-30, -132), Vector2(-46, -126), Vector2(-48, -76), Vector2(-34, -72)], white)
	_poly(ci, f, s, [Vector2(30, -132), Vector2(48, -126), Vector2(50, -82), Vector2(34, -78)], shade)
	_ell(ci, f, s, -42, -66, 9, 11, _c(SKIN, d))
	_ell(ci, f, s, 44, -72, 9, 11, _c(SKIN, d))
	# torso: chaqueta doble botonadura con delantal manchado
	_poly(ci, f, s, [Vector2(-33, -136), Vector2(33, -136), Vector2(30, -60), Vector2(-30, -60)], white)
	_poly(ci, f, s, [Vector2(6, -136), Vector2(33, -136), Vector2(30, -60), Vector2(6, -60)], shade)
	_poly(ci, f, s, [Vector2(-22, -100), Vector2(22, -100), Vector2(26, -56), Vector2(-26, -56)], _c(Color(0.80, 0.78, 0.74), d))
	_ell(ci, f, s, -9, -88, 8, 11, blood)
	_ell(ci, f, s, 12, -74, 6, 8, blood)
	_circ(ci, f, s, 6, -106, 3, blood)
	for i in 3:
		_circ(ci, f, s, -4, -128 + i * 10, 2.4, _c(GREY, d))
	# panuelo rojo al cuello
	_poly(ci, f, s, [Vector2(-14, -140), Vector2(14, -140), Vector2(0, -126)], _c(RED_UNIFORM, d))
	# cabeza ancha, bigote y ojos rojos
	_head(ci, f, s, 0, -158, 22, 22, d)
	_poly(ci, f, s, [Vector2(-18, -148), Vector2(0, -152), Vector2(18, -148), Vector2(12, -142), Vector2(0, -146), Vector2(-12, -142)], _c(INK, d * 0.2))
	_eye(ci, f, s, -9, -162, 5.0, Color(1, 0.2, 0.1))
	_eye(ci, f, s, 9, -162, 5.0, Color(1, 0.2, 0.1))
	_line(ci, f, s, Vector2(-16, -171), Vector2(-3, -167), _c(INK, d * 0.3), 2.2)
	_line(ci, f, s, Vector2(16, -171), Vector2(3, -167), _c(INK, d * 0.3), 2.2)
	# gorro alto (toque) de pliegues
	_poly(ci, f, s, [Vector2(-20, -178), Vector2(20, -178), Vector2(17, -192), Vector2(-17, -192)], white)
	_ell(ci, f, s, -13, -198, 12, 11, white)
	_ell(ci, f, s, 0, -206, 14, 12, white)
	_ell(ci, f, s, 13, -198, 12, 11, white)
	_ell(ci, f, s, 8, -200, 9, 8, shade)
	_line(ci, f, s, Vector2(-8, -196), Vector2(-6, -182), shade, 1.2)
	_line(ci, f, s, Vector2(6, -198), Vector2(5, -182), shade, 1.2)
	# cuchilla (la mano derecha del jugador): hoja con filo brillante
	_line(ci, f, s, Vector2(46, -78), Vector2(54, -104), _c(Color(0.25, 0.15, 0.08), d), 5.0)
	_poly(ci, f, s, [Vector2(48, -104), Vector2(66, -142), Vector2(78, -136), Vector2(62, -100)], _c(Color(0.72, 0.73, 0.78), d * 0.5))
	_line(ci, f, s, Vector2(66, -142), Vector2(78, -136), Color(1, 1, 1, 0.85), 1.4)
	_circ(ci, f, s, 60, -112, 2.2, blood)


# -------------------------------------------------------------------- MUCAMA

static func _mucama(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var dress: Color = _c(BLACK_DRESS, maxf(d - 0.3, 0.0))
	var dress_l: Color = _c(Color(0.16, 0.16, 0.20), maxf(d - 0.3, 0.0))
	var white: Color = _c(WHITE, d)
	var hair: Color = _c(Color(0.05, 0.04, 0.05), d * 0.3)
	_shadow(ci, f, s, 40)
	# vestido largo en campana con dobladillo de volantes
	_poly(ci, f, s, [Vector2(-38, -2), Vector2(38, -2), Vector2(17, -128), Vector2(-17, -128)], dress)
	_poly(ci, f, s, [Vector2(6, -2), Vector2(38, -2), Vector2(17, -128), Vector2(4, -128)], dress_l)
	var hem := PackedVector2Array()
	for i in 13:
		hem.append(f + Vector2(-38.0 + i * 6.33, -2.0 - (i % 2) * 6.0) * s)
	ci.draw_polyline(hem, white, maxf(1.6 * s, 1.0))
	# delantal blanco con peto y lazo
	_poly(ci, f, s, [Vector2(-15, -14), Vector2(15, -14), Vector2(10, -104), Vector2(-10, -104)], white)
	_poly(ci, f, s, [Vector2(-8, -104), Vector2(8, -104), Vector2(6, -126), Vector2(-6, -126)], white)
	_line(ci, f, s, Vector2(-15, -14), Vector2(-9, -100), _c(GREY, d), 1.0)
	_circ(ci, f, s, 0, -70, 3.0, _c(RED_UNIFORM, d))
	_poly(ci, f, s, [Vector2(0, -96), Vector2(-14, -102), Vector2(-14, -90)], white)
	_poly(ci, f, s, [Vector2(0, -96), Vector2(14, -102), Vector2(14, -90)], white)
	# brazos largos y manos palidas; sostiene un plumero
	_poly(ci, f, s, [Vector2(-17, -126), Vector2(-28, -120), Vector2(-26, -66), Vector2(-17, -68)], dress)
	_poly(ci, f, s, [Vector2(17, -126), Vector2(28, -120), Vector2(30, -70), Vector2(20, -68)], dress_l)
	_ell(ci, f, s, -22, -62, 5, 8, _c(SKIN, d))
	_ell(ci, f, s, 25, -64, 5, 8, _c(SKIN, d))
	_line(ci, f, s, Vector2(26, -66), Vector2(30, -156), _c(Color(0.35, 0.22, 0.10), d), 3.0)
	for i in 6:
		var a: float = -0.9 + i * 0.36
		_line(ci, f, s, Vector2(30, -156), Vector2(30 + sin(a) * 18.0, -156 - cos(a) * 22.0), _c(Color(0.7, 0.62, 0.5), d), 2.2)
	# cabello largo a los lados, cara palida
	_poly(ci, f, s, [Vector2(-20, -158), Vector2(-24, -108), Vector2(-12, -112), Vector2(-14, -150)], hair)
	_poly(ci, f, s, [Vector2(20, -158), Vector2(24, -108), Vector2(12, -112), Vector2(14, -150)], hair)
	_rect(ci, f, s, -5, -134, 10, 10, _c(SKIN_SHADE, d))
	_head(ci, f, s, 0, -146, 16, 20, d)
	# cofia con volantes
	_poly(ci, f, s, [Vector2(-17, -160), Vector2(17, -160), Vector2(13, -174), Vector2(-13, -174)], white)
	for i in 5:
		_circ(ci, f, s, -14 + i * 7, -161, 4.0, white)
	_line(ci, f, s, Vector2(-17, -160), Vector2(17, -160), _c(GREY, d), 1.0)
	# ojos ciegos (blancos, sin pupila) con ojeras
	for sx in [-6.0, 6.0]:
		_ell(ci, f, s, sx, -147, 5.4, 4.2, Color(0.08, 0.05, 0.08, 0.7))
		_ell(ci, f, s, sx, -147, 4.0, 3.2, Color(0.96, 0.96, 0.92))
	_line(ci, f, s, Vector2(-5, -134), Vector2(5, -134), _c(Color(0.35, 0.1, 0.12), d * 0.5), 1.4)


# ----------------------------------------------------------------- CORNELIUS

## Cornelius: alto, de negro, con sombrero de copa, monoculo y reloj de bolsillo dorado.
## Altura ~235 * s.
static func _cornelius(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var suit: Color = _c(Color(0.06, 0.06, 0.08), d * 0.6)
	var suit_l: Color = _c(Color(0.14, 0.14, 0.18), d * 0.6)
	var skin: Color = _c(Color(0.80, 0.78, 0.70), d)
	var gold: Color = _c(GOLD, d)
	_shadow(ci, f, s, 36)
	# piernas muy largas y zapatos de charol
	_poly(ci, f, s, [Vector2(-18, -88), Vector2(-3, -88), Vector2(-5, -6), Vector2(-17, -6)], suit)
	_poly(ci, f, s, [Vector2(3, -88), Vector2(18, -88), Vector2(17, -6), Vector2(5, -6)], suit)
	_ell(ci, f, s, -13, -3, 12, 4.5, _c(INK, d * 0.3))
	_ell(ci, f, s, 13, -3, 12, 4.5, _c(INK, d * 0.3))
	# levita con faldones
	_poly(ci, f, s, [Vector2(-26, -168), Vector2(26, -168), Vector2(21, -84), Vector2(-21, -84)], suit)
	_poly(ci, f, s, [Vector2(-26, -84), Vector2(-4, -88), Vector2(-14, -34), Vector2(-27, -30)], suit)
	_poly(ci, f, s, [Vector2(26, -84), Vector2(4, -88), Vector2(14, -34), Vector2(27, -30)], suit_l)
	# chaleco dorado y cadena del reloj
	_poly(ci, f, s, [Vector2(-8, -164), Vector2(8, -164), Vector2(9, -92), Vector2(-9, -92)], _c(Color(0.45, 0.35, 0.10), d))
	_line(ci, f, s, Vector2(-8, -128), Vector2(8, -112), gold, 1.6)
	_line(ci, f, s, Vector2(8, -112), Vector2(10, -104), gold, 1.2)
	_circ(ci, f, s, 10, -100, 6.5, gold)
	_circ(ci, f, s, 10, -100, 4.2, _c(Color(0.9, 0.88, 0.8), d))
	_line(ci, f, s, Vector2(10, -100), Vector2(12, -103), _c(INK, d), 1.0)
	_poly(ci, f, s, [Vector2(-4, -168), Vector2(4, -168), Vector2(0, -150)], _c(WHITE, d))
	_poly(ci, f, s, [Vector2(-6, -158), Vector2(6, -158), Vector2(0, -150)], _c(RED_UNIFORM, d))
	# brazos larguisimos y dedos como agujas
	_poly(ci, f, s, [Vector2(-26, -166), Vector2(-40, -158), Vector2(-42, -60), Vector2(-32, -58)], suit)
	_poly(ci, f, s, [Vector2(26, -166), Vector2(40, -158), Vector2(42, -60), Vector2(32, -58)], suit_l)
	for i in 4:
		_line(ci, f, s, Vector2(-39 + i * 2.6, -60), Vector2(-42 + i * 3.4, -28), skin, 1.5)
		_line(ci, f, s, Vector2(32 + i * 2.6, -60), Vector2(33 + i * 3.4, -28), skin, 1.5)
	# cabeza alargada, monoculo, sonrisa fina
	_rect(ci, f, s, -5, -176, 10, 10, _c(SKIN_SHADE, d))
	_head(ci, f, s, 0, -188, 15, 21, d)
	_eye(ci, f, s, -6, -190, 4.4, Color(1.0, 0.8, 0.2))
	_eye(ci, f, s, 6, -190, 4.4, Color(1.0, 0.8, 0.2))
	var mono := PackedVector2Array()
	for i in 17:
		var a: float = TAU * float(i) / 16.0
		mono.append(f + Vector2(6.0 + cos(a) * 8.0, -190.0 + sin(a) * 8.0) * s)
	ci.draw_polyline(mono, gold, maxf(1.4 * s, 1.0))
	_line(ci, f, s, Vector2(10, -182), Vector2(14, -150), gold, 1.0)
	var grin := PackedVector2Array()
	for i in 9:
		var u: float = float(i) / 8.0
		grin.append(f + Vector2(-9.0 + u * 18.0, -176.0 + sin(u * PI) * 3.0) * s)
	ci.draw_polyline(grin, _c(Color(0.2, 0.02, 0.03), d * 0.4), maxf(1.2 * s, 1.0))
	# sombrero de copa con cinta dorada
	_rect(ci, f, s, -15, -246, 30, 46, _c(Color(0.05, 0.05, 0.06), d * 0.6))
	_rect(ci, f, s, 2, -246, 13, 46, _c(Color(0.10, 0.10, 0.12), d * 0.6))
	_rect(ci, f, s, -15, -214, 30, 6, gold)
	_ell(ci, f, s, 0, -200, 29, 5, _c(Color(0.04, 0.04, 0.05), d * 0.6))
	_ell(ci, f, s, 0, -246, 15, 3.5, _c(Color(0.12, 0.12, 0.14), d * 0.6))


# ----------------------------------------------------------------- BAILARINA

## La Bailarina de la cajita de musica: muñeca de porcelana agrietada con tutu. Altura ~150 * s.
static func _bailarina(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var porc: Color = _c(Color(0.93, 0.90, 0.86), d)
	var tutu: Color = _c(Color(0.90, 0.80, 0.88), d)
	var tutu_d: Color = _c(Color(0.68, 0.55, 0.68), d)
	_shadow(ci, f, s, 30)
	# piernas finas en punta
	_line(ci, f, s, Vector2(-6, -52), Vector2(-9, -4), porc, 4.0)
	_line(ci, f, s, Vector2(6, -52), Vector2(9, -4), porc, 4.0)
	_poly(ci, f, s, [Vector2(-12, -6), Vector2(-5, -6), Vector2(-9, 0)], _c(Color(0.9, 0.6, 0.7), d))
	_poly(ci, f, s, [Vector2(12, -6), Vector2(5, -6), Vector2(9, 0)], _c(Color(0.9, 0.6, 0.7), d))
	# tutu: abanico de petalos
	for i in 9:
		var a: float = -0.5 + i * 0.125
		_poly(ci, f, s, [Vector2(0, -62), Vector2(sin(a * PI) * 38.0 - 6.0, -50.0 + abs(a) * 10.0), Vector2(sin(a * PI) * 38.0 + 6.0, -50.0 + abs(a) * 10.0)], tutu if i % 2 == 0 else tutu_d)
	# torso y brazos arqueados sobre la cabeza
	_poly(ci, f, s, [Vector2(-9, -62), Vector2(9, -62), Vector2(7, -104), Vector2(-7, -104)], _c(Color(0.85, 0.45, 0.60), d))
	var armL := PackedVector2Array([f + Vector2(-8, -100) * s, f + Vector2(-26, -124) * s, f + Vector2(-14, -150) * s, f + Vector2(-3, -158) * s])
	var armR := PackedVector2Array([f + Vector2(8, -100) * s, f + Vector2(26, -124) * s, f + Vector2(14, -150) * s, f + Vector2(3, -158) * s])
	ci.draw_polyline(armL, porc, maxf(3.0 * s, 1.0))
	ci.draw_polyline(armR, porc, maxf(3.0 * s, 1.0))
	# cabeza de porcelana con grieta, mejillas y moño
	_ell(ci, f, s, 0, -118, 14, 16, porc)
	_circ(ci, f, s, 0, -138, 8, _c(Color(0.08, 0.06, 0.07), d * 0.3))
	_circ(ci, f, s, -9, -118, 3.2, _c(Color(0.9, 0.5, 0.5, 0.8), d))
	_circ(ci, f, s, 9, -118, 3.2, _c(Color(0.9, 0.5, 0.5, 0.8), d))
	_line(ci, f, s, Vector2(3, -132), Vector2(0, -124), _c(INK, d * 0.2), 1.0)
	_line(ci, f, s, Vector2(0, -124), Vector2(5, -116), _c(INK, d * 0.2), 1.0)
	_eye(ci, f, s, -5, -121, 3.4, Color(1.0, 0.2, 0.15))
	_eye(ci, f, s, 5, -121, 3.4, Color(1.0, 0.2, 0.15))
	_line(ci, f, s, Vector2(-5, -110), Vector2(5, -110), _c(Color(0.5, 0.05, 0.08), d * 0.3), 1.4)


# --------------------------------------------------------------- PRIMER PLANO

## Primer plano (jumpscare / Mucama en ductos). `c` = centro de la cabeza, `r` = radio.
static func draw_face(ci: CanvasItem, kind: String, c: Vector2, r: float, dark: float = 0.0) -> void:
	var body: Color = RED_UNIFORM
	if kind == "chef":
		body = WHITE
	elif kind == "mucama" or kind == "cornelius":
		body = BLACK_DRESS
	elif kind == "bailarina":
		body = Color(0.85, 0.45, 0.60)
	# hombros / torso
	ci.draw_rect(Rect2(c.x - r * 1.6, c.y + r * 0.95, r * 3.2, r * 2.6), _c(body, dark))
	ci.draw_rect(Rect2(c.x + r * 0.1, c.y + r * 0.95, r * 1.5, r * 2.6), Color(0, 0, 0, 0.25))
	# cuello
	ci.draw_rect(Rect2(c.x - r * 0.3, c.y + r * 0.7, r * 0.6, r * 0.5), _c(SKIN_SHADE, dark))
	# cabeza volumetrica
	var skin: Color = _c(Color(0.93, 0.90, 0.86) if kind == "bailarina" else SKIN, dark)
	ci.draw_circle(c, r, skin)
	ci.draw_circle(c + Vector2(r * 0.22, r * 0.05), r * 0.82, _c(SKIN_SHADE, dark + 0.1).lerp(skin, 0.55))
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.25), r * 0.3, skin.lightened(0.1))
	match kind:
		"botones":
			ci.draw_rect(Rect2(c.x - r * 0.95, c.y - r * 1.62, r * 1.9, r * 0.9), _c(RED_UNIFORM, dark))
			ci.draw_rect(Rect2(c.x + r * 0.1, c.y - r * 1.62, r * 0.85, r * 0.9), _c(RED_DARK, dark))
			ci.draw_rect(Rect2(c.x - r * 1.0, c.y - r * 0.86, r * 2.0, r * 0.16), _c(GOLD, dark))
			ci.draw_line(Vector2(c.x - r * 0.98, c.y - r * 0.7), Vector2(c.x - r * 0.7, c.y + r * 0.6), Color(0.05, 0.05, 0.05), maxf(r * 0.03, 1.0))
			ci.draw_line(Vector2(c.x + r * 0.98, c.y - r * 0.7), Vector2(c.x + r * 0.7, c.y + r * 0.6), Color(0.05, 0.05, 0.05), maxf(r * 0.03, 1.0))
		"chef":
			ci.draw_rect(Rect2(c.x - r * 0.85, c.y - r * 1.7, r * 1.7, r * 1.0), _c(WHITE, dark))
			ci.draw_circle(Vector2(c.x - r * 0.7, c.y - r * 1.8), r * 0.55, _c(WHITE, dark))
			ci.draw_circle(Vector2(c.x, c.y - r * 2.05), r * 0.62, _c(WHITE, dark))
			ci.draw_circle(Vector2(c.x + r * 0.7, c.y - r * 1.8), r * 0.55, _c(WHITE, dark))
			ci.draw_circle(Vector2(c.x + r * 0.3, c.y - r * 1.9), r * 0.35, _c(Color(0.7, 0.69, 0.68), dark))
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(c.x - r * 0.75, c.y + r * 0.38), Vector2(c.x, c.y + r * 0.28), Vector2(c.x + r * 0.75, c.y + r * 0.38),
				Vector2(c.x + r * 0.5, c.y + r * 0.58), Vector2(c.x, c.y + r * 0.46), Vector2(c.x - r * 0.5, c.y + r * 0.58)]),
				Color(0.03, 0.02, 0.03))
		"mucama":
			ci.draw_rect(Rect2(c.x - r * 1.0, c.y - r * 1.25, r * 2.0, r * 0.5), _c(WHITE, dark))
			for i in 5:
				ci.draw_circle(Vector2(c.x - r * 0.8 + i * r * 0.4, c.y - r * 1.2), r * 0.22, _c(WHITE, dark))
			ci.draw_rect(Rect2(c.x - r * 1.05, c.y - r * 0.8, r * 0.28, r * 1.8), Color(0.04, 0.03, 0.04))
			ci.draw_rect(Rect2(c.x + r * 0.77, c.y - r * 0.8, r * 0.28, r * 1.8), Color(0.04, 0.03, 0.04))
		"cornelius":
			ci.draw_rect(Rect2(c.x - r * 0.7, c.y - r * 2.2, r * 1.4, r * 1.4), _c(Color(0.04, 0.04, 0.05), dark))
			ci.draw_rect(Rect2(c.x + r * 0.15, c.y - r * 2.2, r * 0.55, r * 1.4), Color(0.12, 0.12, 0.14))
			ci.draw_rect(Rect2(c.x - r * 0.7, c.y - r * 1.15, r * 1.4, r * 0.18), _c(GOLD, dark))
			ci.draw_rect(Rect2(c.x - r * 1.2, c.y - r * 0.85, r * 2.4, r * 0.16), _c(Color(0.04, 0.04, 0.05), dark))
			ci.draw_arc(Vector2(c.x + r * 0.38, c.y - r * 0.1), r * 0.36, 0.0, TAU, 32, _c(GOLD, dark), maxf(r * 0.04, 1.0))
		"bailarina":
			ci.draw_circle(Vector2(c.x, c.y - r * 1.15), r * 0.5, Color(0.08, 0.06, 0.07))
			ci.draw_circle(Vector2(c.x, c.y - r * 0.55), r * 0.95, Color(0.08, 0.06, 0.07, 0.0))
			ci.draw_line(Vector2(c.x + r * 0.2, c.y - r * 0.95), Vector2(c.x - r * 0.05, c.y - r * 0.35), Color(0.05, 0.03, 0.03), maxf(r * 0.025, 1.0))
			ci.draw_line(Vector2(c.x - r * 0.05, c.y - r * 0.35), Vector2(c.x + r * 0.25, c.y + r * 0.1), Color(0.05, 0.03, 0.03), maxf(r * 0.025, 1.0))
			ci.draw_circle(Vector2(c.x - r * 0.55, c.y + r * 0.2), r * 0.16, Color(0.9, 0.5, 0.5, 0.8))
			ci.draw_circle(Vector2(c.x + r * 0.55, c.y + r * 0.2), r * 0.16, Color(0.9, 0.5, 0.5, 0.8))
	# ojos
	var ey: float = c.y - r * 0.1
	var ex: float = r * 0.38
	if kind == "mucama":
		for sx in [-1.0, 1.0]:
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.26, Color(0.1, 0.05, 0.1, 0.7))
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.2, Color(0.96, 0.96, 0.92))
	else:
		var glow: Color = Color(1, 0.2, 0.1) if (kind == "chef" or kind == "bailarina") else (Color(1.0, 0.8, 0.2) if kind == "cornelius" else Color(1, 1, 0.9))
		for sx in [-1.0, 1.0]:
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.24, Color(0, 0, 0))
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.1, glow)
			ci.draw_circle(Vector2(c.x + sx * ex - r * 0.03, ey - r * 0.04), r * 0.03, Color(1, 1, 1, 0.9))
		# cejas furiosas
		ci.draw_line(Vector2(c.x - ex - r * 0.25, ey - r * 0.38), Vector2(c.x - ex + r * 0.2, ey - r * 0.22), Color(0.04, 0.03, 0.03), maxf(r * 0.05, 1.0))
		ci.draw_line(Vector2(c.x + ex + r * 0.25, ey - r * 0.38), Vector2(c.x + ex - r * 0.2, ey - r * 0.22), Color(0.04, 0.03, 0.03), maxf(r * 0.05, 1.0))
	# boca abierta con dientes irregulares
	var mw: float = r * 0.62
	var my: float = c.y + r * 0.45
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - mw, my), Vector2(c.x + mw, my),
		Vector2(c.x + mw * 0.7, my + r * 0.55), Vector2(c.x - mw * 0.7, my + r * 0.55)
	]), Color(0.22, 0.02, 0.03))
	for i in 6:
		var x0: float = c.x - mw + i * (2.0 * mw / 6.0)
		var th: float = r * (0.16 + 0.1 * float((i * 7) % 3))
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(x0, my), Vector2(x0 + 2.0 * mw / 6.0, my),
			Vector2(x0 + mw / 6.0, my + th)
		]), Color(0.95, 0.94, 0.88))
	for i in 4:
		var x1: float = c.x - mw * 0.6 + i * (1.2 * mw / 4.0)
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(x1, my + r * 0.55), Vector2(x1 + 0.3 * mw, my + r * 0.55),
			Vector2(x1 + 0.15 * mw, my + r * 0.4)
		]), Color(0.9, 0.9, 0.84))
