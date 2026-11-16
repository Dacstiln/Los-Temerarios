extends RefCounted
## Dibujo procedural avanzado de los monstruos (Art Déco Decadente).
## Sombreado volumétrico direccional, claroscuro, halos espectrales en ojos
## y detalles siniestros para las cámaras, rejas y jumpscares.
##
## Convención: unidades de figura con pies en (0,0) y altura hacia arriba (y negativa).
## `s` = escala. `dark` = nivel de penumbra (las siluetas se oscurecen pero los ojos brillan).

const SKIN := Color(0.86, 0.79, 0.68)
const SKIN_SHADE := Color(0.58, 0.50, 0.42)
const RED_UNIFORM := Color(0.58, 0.08, 0.11)
const RED_DARK := Color(0.32, 0.04, 0.06)
const GOLD := Color(0.83, 0.69, 0.22)
const GOLD_DARK := Color(0.48, 0.38, 0.10)
const WHITE := Color(0.92, 0.91, 0.88)
const GREY := Color(0.68, 0.68, 0.70)
const BLACK_DRESS := Color(0.08, 0.08, 0.11)
const INK := Color(0.03, 0.03, 0.04)


# ================================================================ UTILIDADES

static func _c(col: Color, dark: float) -> Color:
	return col.lerp(Color(0.015, 0.018, 0.025, col.a), clampf(dark, 0.0, 1.0))


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


## Elipse rellena para volúmenes anatómicos
static func _ell(ci: CanvasItem, foot: Vector2, s: float, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var arr := PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		arr.append(foot + Vector2(cx + cos(a) * rx, cy + sin(a) * ry) * s)
	ci.draw_colored_polygon(arr, col)


static func _shadow(ci: CanvasItem, foot: Vector2, s: float, rx: float) -> void:
	_ell(ci, foot, s, 0, 2, rx, 7, Color(0, 0, 0, 0.55))


## Cabeza volumétrica con pómulos, sombra lateral y brillo de luz
static func _head(ci: CanvasItem, foot: Vector2, s: float, cx: float, cy: float, rx: float, ry: float, d: float) -> void:
	_ell(ci, foot, s, cx, cy, rx, ry, _c(SKIN, d))
	# Sombra direccional derecha
	_ell(ci, foot, s, cx + rx * 0.28, cy + ry * 0.05, rx * 0.74, ry * 0.94, _c(SKIN_SHADE, d + 0.12).lerp(_c(SKIN, d), 0.50))
	# Pómulo iluminado izquierdo
	_ell(ci, foot, s, cx - rx * 0.32, cy - ry * 0.22, rx * 0.34, ry * 0.30, _c(SKIN, d).lightened(0.14))


## Ojo espectral: cuenca oscura + halo exterior difuminado + pupila brillante
static func _eye(ci: CanvasItem, foot: Vector2, s: float, x: float, y: float, r: float, glow: Color) -> void:
	# Cuenca sombría
	_ell(ci, foot, s, x, y, r * 1.45, r * 1.15, Color(0.012, 0.008, 0.008, 0.95))
	# Halo espectral difuminado
	_circ(ci, foot, s, x, y, r * 1.25, Color(glow.r, glow.g, glow.b, 0.32))
	# Iris luminoso
	_circ(ci, foot, s, x, y, r * 0.65, glow)
	# Reflejo especular
	_circ(ci, foot, s, x - r * 0.20, y - r * 0.22, r * 0.22, Color(1, 1, 1, 0.95))


# ================================================================ PUNTO DE ENTRADA

## Dibuja la figura de cuerpo entero. `foot` = posición de los pies.
static func draw_figure(ci: CanvasItem, kind: String, foot: Vector2, s: float, dark: float = 0.0) -> void:
	match kind:
		"botones": _botones(ci, foot, s, dark)
		"chef": _chef(ci, foot, s, dark)
		"mucama": _mucama(ci, foot, s, dark)
		"cornelius": _cornelius(ci, foot, s, dark)
		"bailarina": _bailarina(ci, foot, s, dark)


# ================================================================ 1. EL BOTONES

static func _botones(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var red: Color = _c(RED_UNIFORM, d)
	var red_d: Color = _c(RED_DARK, d)
	var gold: Color = _c(GOLD, d)
	var trou: Color = _c(Color(0.07, 0.07, 0.09), d)

	_shadow(ci, f, s, 36)

	# Piernas con raya dorada de uniforme de lujo
	_poly(ci, f, s, [Vector2(-20, -64), Vector2(-3, -64), Vector2(-5, -6), Vector2(-22, -6)], trou)
	_poly(ci, f, s, [Vector2(3, -64), Vector2(20, -64), Vector2(22, -6), Vector2(5, -6)], trou)
	_line(ci, f, s, Vector2(-18, -62), Vector2(-20, -8), gold, 1.8)
	_line(ci, f, s, Vector2(18, -62), Vector2(20, -8), gold, 1.8)
	_ell(ci, f, s, -14, -3, 14, 5.5, _c(INK, d * 0.5))
	_ell(ci, f, s, 14, -3, 14, 5.5, _c(INK, d * 0.5))

	# Brazos con mangas escarlata y guantes blancos de botones
	_poly(ci, f, s, [Vector2(-25, -124), Vector2(-38, -120), Vector2(-42, -62), Vector2(-31, -60)], red)
	_poly(ci, f, s, [Vector2(25, -124), Vector2(38, -120), Vector2(42, -62), Vector2(31, -60)], red_d)
	_ell(ci, f, s, -36, -53, 7.5, 9.5, _c(WHITE, d))
	_ell(ci, f, s, 36, -53, 7.5, 9.5, _c(WHITE, d * 1.1))

	# Torso: Chaqueta de gala con doble abotonadura dorada
	_poly(ci, f, s, [Vector2(-26, -128), Vector2(26, -128), Vector2(23, -58), Vector2(-23, -58)], red)
	_poly(ci, f, s, [Vector2(4, -128), Vector2(26, -128), Vector2(23, -58), Vector2(4, -58)], red_d)
	_line(ci, f, s, Vector2(0, -128), Vector2(0, -58), gold, 1.6)

	for i in 5:
		var by: float = -120.0 + i * 13.0
		_circ(ci, f, s, -10, by, 3.2, gold)
		_circ(ci, f, s, -10, by, 1.2, Color(1, 1, 0.9))
		_circ(ci, f, s, 10, by, 3.2, gold)
		_circ(ci, f, s, 10, by, 1.2, Color(1, 1, 0.9))

	# Charreteras doradas militares en los hombros
	_rect(ci, f, s, -36, -130, 18, 6, gold)
	_rect(ci, f, s, 18, -130, 18, 6, gold)
	for i in 4:
		_line(ci, f, s, Vector2(-35 + i * 4.5, -124), Vector2(-35 + i * 4.5, -116), gold, 1.2)
		_line(ci, f, s, Vector2(19 + i * 4.5, -124), Vector2(19 + i * 4.5, -116), gold, 1.2)

	# Cuello y cabeza
	_rect(ci, f, s, -6, -136, 12, 10, _c(SKIN_SHADE, d))
	_head(ci, f, s, 0, -150, 20, 23, d)

	# Gorra cilíndrica de botones con visera y barboquejo
	_poly(ci, f, s, [Vector2(-19, -168), Vector2(19, -168), Vector2(16, -185), Vector2(-16, -185)], red)
	_poly(ci, f, s, [Vector2(2, -168), Vector2(19, -168), Vector2(16, -185), Vector2(2, -185)], red_d)
	_rect(ci, f, s, -20, -170, 40, 4.5, gold)
	_circ(ci, f, s, 0, -190, 3.2, gold)
	_line(ci, f, s, Vector2(-20, -152), Vector2(-15, -135), _c(INK, d), 1.5)
	_line(ci, f, s, Vector2(20, -152), Vector2(15, -135), _c(INK, d), 1.5)

	# Cara siniestra: cejas caídas, ojos espectrales y sonrisa cosida
	_line(ci, f, s, Vector2(-14, -160), Vector2(-3, -157), _c(INK, d * 0.4), 2.0)
	_line(ci, f, s, Vector2(14, -160), Vector2(3, -157), _c(INK, d * 0.4), 2.0)
	_eye(ci, f, s, -8, -150, 4.8, Color(1.0, 0.95, 0.70))
	_eye(ci, f, s, 8, -150, 4.8, Color(1.0, 0.95, 0.70))

	# Sonrisa cosida con puntadas negras
	var smile := PackedVector2Array()
	for i in 13:
		var u: float = float(i) / 12.0
		smile.append(f + Vector2(-16.0 + u * 32.0, -137.0 + sin(u * PI) * 6.5) * s)
	ci.draw_polyline(smile, _c(Color(0.28, 0.02, 0.03), d * 0.3), maxf(1.8 * s, 1.0))
	for i in 7:
		var u: float = float(i) / 6.0
		var px: float = -14.0 + u * 28.0
		var py: float = -137.0 + sin((px + 16.0) / 32.0 * PI) * 6.5
		_line(ci, f, s, Vector2(px, py - 3), Vector2(px, py + 4), _c(INK, d * 0.25), 1.2)


# ================================================================ 2. EL CHEF

static func _chef(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var white: Color = _c(WHITE, d)
	var shade: Color = _c(Color(0.60, 0.59, 0.58), d)
	var blood: Color = _c(Color(0.48, 0.04, 0.05), d)

	_shadow(ci, f, s, 44)

	# Pantalones a cuadros oscuros y botas de trabajo
	_poly(ci, f, s, [Vector2(-28, -66), Vector2(-2, -66), Vector2(-4, -6), Vector2(-28, -6)], _c(Color(0.16, 0.16, 0.18), d))
	_poly(ci, f, s, [Vector2(2, -66), Vector2(28, -66), Vector2(28, -6), Vector2(4, -6)], _c(Color(0.12, 0.12, 0.14), d))
	for i in 5:
		_line(ci, f, s, Vector2(-28, -60 + i * 12), Vector2(-3, -60 + i * 12), _c(Color(0.28, 0.28, 0.30), d), 1.2)
		_line(ci, f, s, Vector2(3, -60 + i * 12), Vector2(28, -60 + i * 12), _c(Color(0.28, 0.28, 0.30), d), 1.2)
	_ell(ci, f, s, -16, -3, 16, 6.5, _c(INK, d * 0.5))
	_ell(ci, f, s, 16, -3, 16, 6.5, _c(INK, d * 0.5))

	# Brazos masivos remangados
	_poly(ci, f, s, [Vector2(-32, -134), Vector2(-50, -128), Vector2(-52, -76), Vector2(-36, -72)], white)
	_poly(ci, f, s, [Vector2(32, -134), Vector2(50, -128), Vector2(52, -82), Vector2(36, -78)], shade)
	_ell(ci, f, s, -45, -66, 10, 12, _c(SKIN, d))
	_ell(ci, f, s, 47, -72, 10, 12, _c(SKIN, d))

	# Torso voluminoso: chaquetilla con delantal manchado
	_poly(ci, f, s, [Vector2(-35, -138), Vector2(35, -138), Vector2(32, -60), Vector2(-32, -60)], white)
	_poly(ci, f, s, [Vector2(6, -138), Vector2(35, -138), Vector2(32, -60), Vector2(6, -60)], shade)
	_poly(ci, f, s, [Vector2(-24, -102), Vector2(24, -102), Vector2(28, -56), Vector2(-28, -56)], _c(Color(0.78, 0.76, 0.72), d))

	# Manchas siniestras de sangre en el delantal
	_ell(ci, f, s, -10, -90, 9, 12, blood)
	_ell(ci, f, s, 14, -76, 7, 9, blood)
	_circ(ci, f, s, 8, -108, 3.5, blood)
	_circ(ci, f, s, -16, -68, 4.0, blood)

	for i in 4:
		_circ(ci, f, s, -4, -130 + i * 10, 2.5, _c(GREY, d))

	# Pañuelo rojo al cuello
	_poly(ci, f, s, [Vector2(-15, -142), Vector2(15, -142), Vector2(0, -127)], _c(RED_UNIFORM, d))

	# Cabeza pesada, bigote victoriano y ojos rojos
	_head(ci, f, s, 0, -160, 23, 23, d)
	_poly(ci, f, s, [Vector2(-19, -150), Vector2(0, -154), Vector2(19, -150), Vector2(13, -144), Vector2(0, -148), Vector2(-13, -144)], _c(INK, d * 0.2))
	_eye(ci, f, s, -10, -164, 5.2, Color(1.0, 0.15, 0.10))
	_eye(ci, f, s, 10, -164, 5.2, Color(1.0, 0.15, 0.10))
	_line(ci, f, s, Vector2(-17, -173), Vector2(-4, -169), _c(INK, d * 0.3), 2.4)
	_line(ci, f, s, Vector2(17, -173), Vector2(4, -169), _c(INK, d * 0.3), 2.4)

	# Gorro alto arrugado de cocinero
	_poly(ci, f, s, [Vector2(-21, -180), Vector2(21, -180), Vector2(18, -195), Vector2(-18, -195)], white)
	_ell(ci, f, s, -14, -202, 13, 12, white)
	_ell(ci, f, s, 0, -210, 15, 13, white)
	_ell(ci, f, s, 14, -202, 13, 12, white)
	_ell(ci, f, s, 9, -204, 10, 9, shade)

	# Cuchilla de carnicero de acero con filo resplandeciente
	_line(ci, f, s, Vector2(48, -78), Vector2(56, -106), _c(Color(0.24, 0.14, 0.08), d), 5.5)
	_poly(ci, f, s, [Vector2(50, -106), Vector2(70, -148), Vector2(84, -140), Vector2(65, -100)], _c(Color(0.75, 0.76, 0.82), d * 0.5))
	_line(ci, f, s, Vector2(70, -148), Vector2(84, -140), Color(1, 1, 1, 0.95), 2.0)
	_circ(ci, f, s, 64, -116, 2.5, blood)


# ================================================================ 3. LA MUCAMA

static func _mucama(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var dress: Color = _c(BLACK_DRESS, maxf(d - 0.25, 0.0))
	var dress_l: Color = _c(Color(0.15, 0.15, 0.19), maxf(d - 0.25, 0.0))
	var white: Color = _c(WHITE, d)
	var hair: Color = _c(Color(0.04, 0.03, 0.04), d * 0.3)

	_shadow(ci, f, s, 42)

	# Vestido largo victoriano en campana
	_poly(ci, f, s, [Vector2(-40, -2), Vector2(40, -2), Vector2(18, -130), Vector2(-18, -130)], dress)
	_poly(ci, f, s, [Vector2(7, -2), Vector2(40, -2), Vector2(18, -130), Vector2(5, -130)], dress_l)
	var hem := PackedVector2Array()
	for i in 14:
		hem.append(f + Vector2(-40.0 + i * 6.15, -2.0 - (i % 2) * 6.0) * s)
	ci.draw_polyline(hem, white, maxf(1.6 * s, 1.0))

	# Delantal blanco andrajoso
	_poly(ci, f, s, [Vector2(-16, -14), Vector2(16, -14), Vector2(11, -106), Vector2(-11, -106)], white)
	_poly(ci, f, s, [Vector2(-9, -106), Vector2(9, -106), Vector2(7, -128), Vector2(-7, -128)], white)
	_line(ci, f, s, Vector2(-16, -14), Vector2(-10, -102), _c(GREY, d), 1.2)

	# Brazos largos esqueléticos
	_poly(ci, f, s, [Vector2(-18, -128), Vector2(-30, -122), Vector2(-28, -66), Vector2(-18, -68)], dress)
	_poly(ci, f, s, [Vector2(18, -128), Vector2(30, -122), Vector2(32, -70), Vector2(21, -68)], dress_l)
	_ell(ci, f, s, -23, -62, 5.5, 8.5, _c(SKIN, d))
	_ell(ci, f, s, 26, -64, 5.5, 8.5, _c(SKIN, d))

	# Plumero de servicio antiguo
	_line(ci, f, s, Vector2(27, -66), Vector2(32, -160), _c(Color(0.35, 0.22, 0.10), d), 3.0)
	for i in 7:
		var a: float = -0.95 + i * 0.32
		_line(ci, f, s, Vector2(32, -160), Vector2(32 + sin(a) * 20.0, -160 - cos(a) * 24.0), _c(Color(0.65, 0.58, 0.48), d), 2.2)

	# Cabello oscuro largo y rostro espectral
	_poly(ci, f, s, [Vector2(-21, -160), Vector2(-26, -106), Vector2(-13, -110), Vector2(-15, -152)], hair)
	_poly(ci, f, s, [Vector2(21, -160), Vector2(26, -106), Vector2(13, -110), Vector2(15, -152)], hair)
	_rect(ci, f, s, -5, -136, 10, 10, _c(SKIN_SHADE, d))
	_head(ci, f, s, 0, -148, 17, 21, d)

	# Cofia de encaje
	_poly(ci, f, s, [Vector2(-18, -162), Vector2(18, -162), Vector2(14, -176), Vector2(-14, -176)], white)
	for i in 5:
		_circ(ci, f, s, -14 + i * 7, -163, 4.2, white)

	# Ojos espectrales ciegos con halo azulado y lágrimas oscuras
	for sx in [-6.5, 6.5]:
		_ell(ci, f, s, sx, -149, 5.8, 4.5, Color(0.06, 0.04, 0.08, 0.8))
		_ell(ci, f, s, sx, -149, 4.2, 3.4, Color(0.95, 0.96, 1.0))
		_line(ci, f, s, Vector2(sx, -145), Vector2(sx + (1.0 if sx > 0 else -1.0), -136), Color(0.05, 0.04, 0.06, 0.8), 1.2)


# ================================================================ 4. CORNELIUS

static func _cornelius(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var suit: Color = _c(Color(0.05, 0.05, 0.07), d * 0.6)
	var suit_l: Color = _c(Color(0.13, 0.13, 0.17), d * 0.6)
	var skin: Color = _c(Color(0.78, 0.76, 0.68), d)
	var gold: Color = _c(GOLD, d)

	_shadow(ci, f, s, 38)

	# Piernas largas y estilizadas
	_poly(ci, f, s, [Vector2(-19, -90), Vector2(-3, -90), Vector2(-5, -6), Vector2(-18, -6)], suit)
	_poly(ci, f, s, [Vector2(3, -90), Vector2(19, -90), Vector2(18, -6), Vector2(5, -6)], suit)
	_ell(ci, f, s, -14, -3, 13, 5.0, _c(INK, d * 0.3))
	_ell(ci, f, s, 14, -3, 13, 5.0, _c(INK, d * 0.3))

	# Levita larga con faldones en pico
	_poly(ci, f, s, [Vector2(-27, -170), Vector2(27, -170), Vector2(22, -86), Vector2(-22, -86)], suit)
	_poly(ci, f, s, [Vector2(-27, -86), Vector2(-4, -90), Vector2(-15, -34), Vector2(-28, -30)], suit)
	_poly(ci, f, s, [Vector2(27, -86), Vector2(4, -90), Vector2(14, -34), Vector2(28, -30)], suit_l)

	# Chaleco dorado y reloj de bolsillo reluciente
	_poly(ci, f, s, [Vector2(-9, -166), Vector2(9, -166), Vector2(10, -94), Vector2(-10, -94)], _c(Color(0.48, 0.38, 0.12), d))
	_line(ci, f, s, Vector2(-9, -130), Vector2(9, -114), gold, 1.8)
	_line(ci, f, s, Vector2(9, -114), Vector2(11, -105), gold, 1.5)

	# Reloj de bolsillo de oro con destello
	_circ(ci, f, s, 11, -101, 7.0, gold)
	_circ(ci, f, s, 11, -101, 4.5, Color(1.0, 0.95, 0.8))
	_circ(ci, f, s, 11, -101, 10.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.25))

	_poly(ci, f, s, [Vector2(-5, -170), Vector2(5, -170), Vector2(0, -152)], _c(WHITE, d))
	_poly(ci, f, s, [Vector2(-7, -160), Vector2(7, -160), Vector2(0, -152)], _c(RED_UNIFORM, d))

	# Brazos largos con bastón de empuñadura dorada
	_poly(ci, f, s, [Vector2(-27, -168), Vector2(-42, -160), Vector2(-44, -60), Vector2(-33, -58)], suit)
	_poly(ci, f, s, [Vector2(27, -168), Vector2(42, -160), Vector2(44, -60), Vector2(33, -58)], suit_l)

	# Bastón en la mano izquierda
	_line(ci, f, s, Vector2(-38, -60), Vector2(-40, 0), Color(0.15, 0.10, 0.08), 3.5)
	_circ(ci, f, s, -38, -62, 5.0, gold)

	# Cabeza cadavérica y monóculo brillante
	_rect(ci, f, s, -5, -178, 10, 10, _c(SKIN_SHADE, d))
	_head(ci, f, s, 0, -190, 16, 22, d)
	_eye(ci, f, s, -7, -192, 4.6, Color(1.0, 0.85, 0.25))
	_eye(ci, f, s, 7, -192, 4.6, Color(1.0, 0.85, 0.25))

	# Monóculo dorado en el ojo derecho
	var mono := PackedVector2Array()
	for i in 17:
		var a: float = TAU * float(i) / 16.0
		mono.append(f + Vector2(7.0 + cos(a) * 8.5, -192.0 + sin(a) * 8.5) * s)
	ci.draw_polyline(mono, gold, maxf(1.6 * s, 1.0))
	_line(ci, f, s, Vector2(11, -184), Vector2(15, -152), gold, 1.2)

	# Sombrero de copa alto Art Déco
	_rect(ci, f, s, -16, -250, 32, 50, _c(Color(0.04, 0.04, 0.05), d * 0.6))
	_rect(ci, f, s, 2, -250, 14, 50, _c(Color(0.12, 0.12, 0.14), d * 0.6))
	_rect(ci, f, s, -16, -216, 32, 7, gold)
	_ell(ci, f, s, 0, -202, 31, 5.5, _c(Color(0.03, 0.03, 0.04), d * 0.6))


# ================================================================ 5. LA BAILARINA

static func _bailarina(ci: CanvasItem, f: Vector2, s: float, d: float) -> void:
	var porc: Color = _c(Color(0.94, 0.91, 0.87), d)
	var tutu: Color = _c(Color(0.92, 0.82, 0.90), d)
	var tutu_d: Color = _c(Color(0.65, 0.52, 0.65), d)

	_shadow(ci, f, s, 32)

	# Piernas finas de porcelana en punta
	_line(ci, f, s, Vector2(-6, -52), Vector2(-9, -4), porc, 4.0)
	_line(ci, f, s, Vector2(6, -52), Vector2(9, -4), porc, 4.0)
	_poly(ci, f, s, [Vector2(-12, -6), Vector2(-5, -6), Vector2(-9, 0)], _c(Color(0.9, 0.55, 0.68), d))
	_poly(ci, f, s, [Vector2(12, -6), Vector2(5, -6), Vector2(9, 0)], _c(Color(0.9, 0.55, 0.68), d))

	# Tutú en abanico con pétalos geométricos
	for i in 11:
		var a: float = -0.55 + i * 0.11
		_poly(ci, f, s, [
			Vector2(0, -64),
			Vector2(sin(a * PI) * 40.0 - 6.0, -52.0 + abs(a) * 11.0),
			Vector2(sin(a * PI) * 40.0 + 6.0, -52.0 + abs(a) * 11.0)
		], tutu if i % 2 == 0 else tutu_d)

	# Torso y brazos arqueados de ballet clásico
	_poly(ci, f, s, [Vector2(-10, -64), Vector2(10, -64), Vector2(8, -106), Vector2(-8, -106)], _c(Color(0.85, 0.42, 0.58), d))
	var armL := PackedVector2Array([f + Vector2(-9, -102) * s, f + Vector2(-28, -126) * s, f + Vector2(-15, -152) * s, f + Vector2(-3, -160) * s])
	var armR := PackedVector2Array([f + Vector2(9, -102) * s, f + Vector2(28, -126) * s, f + Vector2(15, -152) * s, f + Vector2(3, -160) * s])
	ci.draw_polyline(armL, porc, maxf(3.2 * s, 1.0))
	ci.draw_polyline(armR, porc, maxf(3.2 * s, 1.0))

	# Cabeza de porcelana agrietada y tiara
	_ell(ci, f, s, 0, -120, 15, 17, porc)
	_circ(ci, f, s, 0, -140, 8.5, _c(Color(0.08, 0.06, 0.07), d * 0.3))

	# Grietas de porcelana rotas en el rostro
	_line(ci, f, s, Vector2(3, -134), Vector2(0, -125), _c(INK, d * 0.2), 1.2)
	_line(ci, f, s, Vector2(0, -125), Vector2(6, -117), _c(INK, d * 0.2), 1.2)

	_eye(ci, f, s, -5.5, -123, 3.6, Color(1.0, 0.18, 0.15))
	_eye(ci, f, s, 5.5, -123, 3.6, Color(1.0, 0.18, 0.15))


# ================================================================ PRIMER PLANO (JUMPSCARES)

## Primer plano hiperdetallado para jumpscares y apariciones en conductos
static func draw_face(ci: CanvasItem, kind: String, c: Vector2, r: float, dark: float = 0.0) -> void:
	var body: Color = RED_UNIFORM
	if kind == "chef":
		body = WHITE
	elif kind == "mucama" or kind == "cornelius":
		body = BLACK_DRESS
	elif kind == "bailarina":
		body = Color(0.85, 0.45, 0.60)

	# Hombros y faldón en sombra
	ci.draw_rect(Rect2(c.x - r * 1.65, c.y + r * 0.95, r * 3.3, r * 2.6), _c(body, dark))
	ci.draw_rect(Rect2(c.x + r * 0.1, c.y + r * 0.95, r * 1.55, r * 2.6), Color(0, 0, 0, 0.30))

	# Cuello anatómico
	ci.draw_rect(Rect2(c.x - r * 0.32, c.y + r * 0.68, r * 0.64, r * 0.52), _c(SKIN_SHADE, dark))

	# Cabeza con volumen y sombreado
	var skin: Color = _c(Color(0.93, 0.90, 0.86) if kind == "bailarina" else SKIN, dark)
	ci.draw_circle(c, r, skin)
	ci.draw_circle(c + Vector2(r * 0.24, r * 0.06), r * 0.82, _c(SKIN_SHADE, dark + 0.12).lerp(skin, 0.50))
	ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.26), r * 0.32, skin.lightened(0.12))

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
				Vector2(c.x + r * 0.5, c.y + r * 0.58), Vector2(c.x, c.y + r * 0.46), Vector2(c.x - r * 0.5, c.y + r * 0.58)
			]), Color(0.03, 0.02, 0.03))

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
			ci.draw_line(Vector2(c.x + r * 0.2, c.y - r * 0.95), Vector2(c.x - r * 0.05, c.y - r * 0.35), Color(0.05, 0.03, 0.03), maxf(r * 0.025, 1.0))
			ci.draw_line(Vector2(c.x - r * 0.05, c.y - r * 0.35), Vector2(c.x + r * 0.25, c.y + r * 0.1), Color(0.05, 0.03, 0.03), maxf(r * 0.025, 1.0))

	# Ojos con cuencas profundas y resplandor
	var ey: float = c.y - r * 0.1
	var ex: float = r * 0.38
	if kind == "mucama":
		for sx in [-1.0, 1.0]:
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.28, Color(0.08, 0.04, 0.08, 0.85))
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.20, Color(0.95, 0.96, 1.0))
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.32, Color(0.6, 0.8, 1.0, 0.18))
	else:
		var glow: Color = Color(1.0, 0.18, 0.10) if (kind == "chef" or kind == "bailarina") else (Color(1.0, 0.82, 0.20) if kind == "cornelius" else Color(1.0, 0.95, 0.70))
		for sx in [-1.0, 1.0]:
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.26, Color(0, 0, 0))
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.22, Color(glow.r, glow.g, glow.b, 0.35))
			ci.draw_circle(Vector2(c.x + sx * ex, ey), r * 0.12, glow)
			ci.draw_circle(Vector2(c.x + sx * ex - r * 0.03, ey - r * 0.04), r * 0.04, Color(1, 1, 1, 0.95))

		# Cejas en ángulo amenazante
		ci.draw_line(Vector2(c.x - ex - r * 0.26, ey - r * 0.40), Vector2(c.x - ex + r * 0.22, ey - r * 0.22), Color(0.04, 0.03, 0.03), maxf(r * 0.055, 1.0))
		ci.draw_line(Vector2(c.x + ex + r * 0.26, ey - r * 0.40), Vector2(c.x + ex - r * 0.22, ey - r * 0.22), Color(0.04, 0.03, 0.03), maxf(r * 0.055, 1.0))

	# Fauces abiertas con dientes irregulares y afilados
	var mw: float = r * 0.64
	var my: float = c.y + r * 0.45
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - mw, my), Vector2(c.x + mw, my),
		Vector2(c.x + mw * 0.7, my + r * 0.58), Vector2(c.x - mw * 0.7, my + r * 0.58)
	]), Color(0.20, 0.015, 0.025))

	for i in 6:
		var x0: float = c.x - mw + i * (2.0 * mw / 6.0)
		var th: float = r * (0.17 + 0.11 * float((i * 7) % 3))
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(x0, my), Vector2(x0 + 2.0 * mw / 6.0, my),
			Vector2(x0 + mw / 6.0, my + th)
		]), Color(0.96, 0.95, 0.88))

	for i in 4:
		var x1: float = c.x - mw * 0.6 + i * (1.2 * mw / 4.0)
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(x1, my + r * 0.58), Vector2(x1 + 0.3 * mw, my + r * 0.58),
			Vector2(x1 + 0.15 * mw, my + r * 0.42)
		]), Color(0.92, 0.90, 0.82))
