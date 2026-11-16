extends Control
## Vista de la oficina (zona segura y centro de mando del guardia).
## Estética Art Déco Decadente: maderas nobles, bronce, lámpara de banquero,
## bitácora de turnos, monitor CRT de seguridad y rejas de tijera remachadas.

const Figures = preload("res://scripts/figures.gd")

var night = null

const W: float = 1280.0
const H: float = 720.0
const GATE_L := Rect2(250.0, 150.0, 220.0, 410.0)
const GATE_R := Rect2(810.0, 150.0, 220.0, 410.0)
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
	var t: float = Time.get_ticks_msec() / 1000.0
	var blackout: bool = night.blackout

	# --- 1. Fondo, Paredes y Arquitectura Art Déco ---
	_draw_architecture(t, blackout)

	# --- 2. Rejilla de Ventilación (Mucama / Caldera) ---
	_draw_vent(t)

	# --- 3. Huecos de Ascensor y Rejas Laterales ---
	for side in ["left", "right"]:
		_draw_gate(side, t, blackout)

	# --- 4. Escritorio de Caoba y Accesorios de Guardia ---
	_draw_desk_and_props(t, blackout)

	# --- 5. Monitor CRT Central ---
	_draw_crt_monitor(t, blackout)

	# --- 6. Iluminación Ambiental y Estados Críticos ---
	_draw_lighting_and_alerts(t, blackout)


# ================================================================ ARQUITECTURA

func _draw_architecture(t: float, blackout: bool) -> void:
	# Pared base en verde carbón oscuro
	draw_rect(Rect2(0, 0, W, 560), Color(0.028, 0.035, 0.030))

	# Franjas verticales de papel tapiz textil
	for i in 14:
		var x: float = i * 92.0 + 8.0
		draw_line(Vector2(x, 0), Vector2(x, 560), Color(0.04, 0.05, 0.042), 40.0)
		draw_line(Vector2(x - 20, 0), Vector2(x - 20, 560), Color(GOLD.r, GOLD.g, GOLD.b, 0.04), 1.0)

	# Zócalo inferior de caoba pulida con moldura biselada
	draw_rect(Rect2(0, 510, W, 50), Color(0.065, 0.040, 0.025))
	draw_line(Vector2(0, 510), Vector2(W, 510), Color(GOLD.r, GOLD.g, GOLD.b, 0.35), 2.0)
	draw_line(Vector2(0, 514), Vector2(W, 514), Color(0.04, 0.02, 0.015), 2.0)

	# Arcos concéntricos monumentales Art Déco en la pared central
	for k in 5:
		var ins: float = k * 14.0
		var col := Color(GOLD.r, GOLD.g, GOLD.b, 0.28 - k * 0.045)
		draw_polyline(PackedVector2Array([
			Vector2(490 + ins, 510), Vector2(490 + ins, 260 + ins), Vector2(535 + ins, 205 + ins),
			Vector2(580 + ins, 155 + ins), Vector2(640, 118 + ins), Vector2(700 - ins, 155 + ins),
			Vector2(745 - ins, 205 + ins), Vector2(790 - ins, 260 + ins), Vector2(790 - ins, 510)
		]), col, 2.0)

	# Reloj analógico redondo de pared de hotel (avanza con la noche)
	var rc := Vector2(640, 75)
	draw_circle(rc, 24.0, Color(0.08, 0.07, 0.05))
	draw_circle(rc, 21.0, Color(0.88, 0.85, 0.76))
	draw_arc(rc, 24.0, 0.0, TAU, 32, GOLD, 2.5)
	# Marcas de horas
	for h in 12:
		var ang: float = h * (TAU / 12.0)
		var p1: Vector2 = rc + Vector2(cos(ang), sin(ang)) * 16.0
		var p2: Vector2 = rc + Vector2(cos(ang), sin(ang)) * 19.0
		draw_line(p1, p2, Color(0.15, 0.12, 0.10), 1.5)
	# Manecillas basadas en la hora del juego
	var progress: float = clampf(night.elapsed / 360.0, 0.0, 1.0)
	var hour_ang: float = (progress * TAU * 0.5) - PI * 0.5 # De 12 a 6
	var min_ang: float = (progress * TAU * 6.0) - PI * 0.5
	draw_line(rc, rc + Vector2(cos(hour_ang), sin(hour_ang)) * 10.0, Color(0.1, 0.1, 0.1), 2.0)
	draw_line(rc, rc + Vector2(cos(min_ang), sin(min_ang)) * 15.0, Color(0.1, 0.1, 0.1), 1.2)
	draw_circle(rc, 2.0, GOLD)


# ================================================================ VENTILACIÓN

func _draw_vent(t: float) -> void:
	var rat: float = night.vent_rattle()
	var glow: float = night.boiler_glow
	var base := Rect2(585, 140, 110, 75)
	var shake: float = sin(t * 60.0) * 3.5 * rat

	var bx: float = base.position.x + shake
	var by: float = base.position.y

	# Marco de bronce oscuro y fondo del ducto
	draw_rect(Rect2(bx - 4, by - 4, base.size.x + 8, base.size.y + 8), Color(0.04, 0.035, 0.03))
	draw_rect(Rect2(bx, by, base.size.x, base.size.y), Color(0.015, 0.018, 0.015))

	# Persiana / lamas de la rejilla
	var col := Color(GOLD.r, GOLD.g, GOLD.b, 0.45)
	if glow > 0.0:
		col = Color(1.0, 0.40, 0.10, 0.95)
		# Vapor caliente sutil emanando
		for v in 4:
			var vy: float = by + 10.0 + v * 14.0
			draw_circle(Vector2(bx + 20.0 + v * 20.0 + sin(t * 8.0 + v) * 6.0, vy), 8.0 + glow * 4.0, Color(1.0, 0.5, 0.2, 0.18))
	elif rat > 0.0:
		col = Color(0.35, 0.95, 0.55, 0.4 + 0.6 * rat)
		# Ojos de la Mucama asomándose en la penumbra del ducto
		var eye_a: float = clampf(rat * 1.5, 0.0, 1.0)
		draw_circle(Vector2(bx + 45, by + 36), 3.0, Color(1.0, 0.25, 0.2, eye_a))
		draw_circle(Vector2(bx + 65, by + 36), 3.0, Color(1.0, 0.25, 0.2, eye_a))

	for i in 6:
		var ly: float = by + 8.0 + i * 11.0
		draw_line(Vector2(bx + 8, ly), Vector2(bx + base.size.x - 8, ly), col, 3.0)
		draw_line(Vector2(bx + 8, ly + 2), Vector2(bx + base.size.x - 8, ly + 2), Color(0.02, 0.02, 0.02), 1.0)

	# Remaches y borde de latón
	draw_rect(Rect2(bx, by, base.size.x, base.size.y), GOLD, false, 2.0)
	for cx in [bx + 4, bx + base.size.x - 4]:
		for cy in [by + 4, by + base.size.y - 4]:
			draw_circle(Vector2(cx, cy), 2.2, Color(GOLD.r, GOLD.g, GOLD.b, 0.75))


# ================================================================ REJAS Y PUERTAS

func _draw_gate(side: String, t: float, blackout: bool) -> void:
	var r: Rect2 = GATE_L if side == "left" else GATE_R
	var cx: float = r.position.x + r.size.x * 0.5

	# Profundidad del hueco del ascensor
	draw_rect(r, Color(0.012, 0.012, 0.015))
	for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		draw_line(p, Vector2(cx, r.position.y + r.size.y * 0.45), Color(0.3, 0.25, 0.10, 0.12), 1.0)

	# Rieles verticales de acero en los bordes
	draw_line(Vector2(r.position.x + 4, r.position.y), Vector2(r.position.x + 4, r.end.y), Color(0.18, 0.18, 0.20), 4.0)
	draw_line(Vector2(r.end.x - 4, r.position.y), Vector2(r.end.x - 4, r.end.y), Color(0.18, 0.18, 0.20), 4.0)

	# Monstruo acechando tras la reja
	if not blackout:
		var kind: String = night.monster_at_gate(side)
		if kind != "":
			var sway: float = sin(t * 2.0) * 3.5
			Figures.draw_figure(self, kind, Vector2(cx + sway, r.end.y - 6.0), 1.6, 0.75)

	# Reja de ascensor de tijera (acordeón pesado con remaches)
	var a: float = night.gate_anim[side]
	if a > 0.01:
		var bh: float = r.size.y * a

		# Sombra proyectada por la reja sobre el suelo
		draw_rect(Rect2(r.position.x - 10, r.end.y, r.size.x + 20, 24), Color(0, 0, 0, 0.45 * a))

		# Barrotes verticales
		var x: float = r.position.x + 6.0
		while x <= r.end.x - 5.0:
			draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + bh), Color(0.55, 0.45, 0.18), 3.0)
			draw_line(Vector2(x + 1, r.position.y), Vector2(x + 1, r.position.y + bh), Color(0.85, 0.75, 0.35, 0.6), 1.0)
			x += 24.0

		# Estructura de tijeras cruzadas con remaches
		var y0: float = r.position.y
		while y0 + 36.0 <= r.position.y + bh:
			var n: int = int((r.size.x - 12.0) / 24.0) + 1
			for i in n:
				var px: float = r.position.x + 6.0 + i * 24.0
				var py_top: float = y0
				var py_bot: float = y0 + 36.0
				var next_px: float = px + 24.0
				if i < n - 1:
					draw_line(Vector2(px, py_top), Vector2(next_px, py_bot), Color(0.65, 0.52, 0.18), 2.0)
					draw_line(Vector2(px, py_bot), Vector2(next_px, py_top), Color(0.65, 0.52, 0.18), 2.0)
					# Remache en el centro del cruce
					draw_circle(Vector2(px + 12.0, y0 + 18.0), 2.4, Color(GOLD.r, GOLD.g, GOLD.b, 0.9))
			y0 += 36.0

		# Barra pesada de impacto inferior
		draw_line(Vector2(r.position.x, r.position.y + bh), Vector2(r.end.x, r.position.y + bh), GOLD, 6.0)
		draw_circle(Vector2(r.position.x + 10, r.position.y + bh), 4.0, Color(0.3, 0.25, 0.1))
		draw_circle(Vector2(r.end.x - 10, r.position.y + bh), 4.0, Color(0.3, 0.25, 0.1))

	# Marco exterior de bronce labrado
	draw_rect(r, Color(BRONZE.r, BRONZE.g, BRONZE.b, 0.8), false, 4.0)

	# Placa de bronce sobre el marco
	var p_rect := Rect2(cx - 75, r.position.y - 28, 150, 20)
	draw_rect(p_rect, Color(0.12, 0.09, 0.05))
	draw_rect(p_rect, GOLD, false, 1.5)
	var title_str: String = "ASCENSOR OESTE" if side == "left" else "ASCENSOR ESTE"
	draw_string(ThemeDB.fallback_font, Vector2(p_rect.position.x, p_rect.position.y + 14), title_str, HORIZONTAL_ALIGNMENT_CENTER, 150.0, 11, Color(GOLD.r, GOLD.g, GOLD.b, 0.85))


# ================================================================ ESCRITORIO Y PROPS

func _draw_desk_and_props(t: float, blackout: bool) -> void:
	# Faldón y superficie del escritorio de caoba en perspectiva
	draw_rect(Rect2(0, 560, W, 160), Color(0.055, 0.038, 0.025))
	draw_rect(Rect2(90, 580, 1100, 140), Color(0.095, 0.060, 0.038))

	# Moldura de borde biselado de caoba y latón
	draw_line(Vector2(80, 580), Vector2(1200, 580), GOLD, 3.0)
	draw_line(Vector2(80, 584), Vector2(1200, 584), Color(0.04, 0.025, 0.015), 2.0)

	# --- PROP 1: Taza de café de porcelana y platillo ---
	var cup_pos := Vector2(370, 625)
	# Platillo
	draw_colored_polygon(PackedVector2Array([
		cup_pos + Vector2(-24, 8), cup_pos + Vector2(24, 8),
		cup_pos + Vector2(20, 14), cup_pos + Vector2(-20, 14)
	]), Color(0.78, 0.76, 0.72))
	# Taza
	draw_colored_polygon(PackedVector2Array([
		cup_pos + Vector2(-16, -16), cup_pos + Vector2(16, -16),
		cup_pos + Vector2(12, 8), cup_pos + Vector2(-12, 8)
	]), Color(0.85, 0.83, 0.78))
	draw_line(cup_pos + Vector2(-16, -16), cup_pos + Vector2(16, -16), GOLD, 1.5)
	# Interior del café
	draw_colored_polygon(PackedVector2Array([
		cup_pos + Vector2(-14, -14), cup_pos + Vector2(14, -14),
		cup_pos + Vector2(12, -8), cup_pos + Vector2(-12, -8)
	]), Color(0.12, 0.06, 0.03))
	# Asa dorada
	draw_arc(cup_pos + Vector2(-16, -4), 7.0, PI * 0.5, PI * 1.5, 8, GOLD, 2.0)
	# Humo sutil animado
	for i in 2:
		var sy: float = fmod(t * 18.0 + i * 15.0, 30.0)
		var sx: float = sin(t * 3.0 + i * 2.0) * 4.0
		var sa: float = clampf(1.0 - (sy / 30.0), 0.0, 1.0) * 0.25
		draw_circle(cup_pos + Vector2(sx, -20.0 - sy), 3.0 + sy * 0.2, Color(0.9, 0.9, 0.9, sa))

	# --- PROP 2: Bitácora de turnos y hojas de reporte ---
	var log_pos := Vector2(430, 610)
	# Carpeta de cuero marrón oscuro
	draw_colored_polygon(PackedVector2Array([
		log_pos + Vector2(-10, -5), log_pos + Vector2(85, -5),
		log_pos + Vector2(80, 85), log_pos + Vector2(-15, 85)
	]), Color(0.18, 0.10, 0.06))
	# Hoja de papel beige desgastada
	draw_colored_polygon(PackedVector2Array([
		log_pos + Vector2(-5, 0), log_pos + Vector2(78, 0),
		log_pos + Vector2(74, 80), log_pos + Vector2(-9, 80)
	]), Color(0.80, 0.76, 0.65))
	# Líneas simuladas de texto mecanografiado
	for l in 5:
		var ly: float = log_pos.y + 12.0 + l * 10.0
		draw_line(Vector2(log_pos.x + 2, ly), Vector2(log_pos.x + 60, ly), Color(0.35, 0.32, 0.28, 0.6), 1.2)
	# Sello rojo del Grand Tenebris
	draw_arc(log_pos + Vector2(50, 55), 11.0, 0.0, TAU, 16, Color(0.70, 0.15, 0.12, 0.55), 1.5)
	# Bolígrafo de latón
	draw_line(log_pos + Vector2(82, 5), log_pos + Vector2(75, 75), GOLD, 2.5)

	# --- PROP 3: Lámpara de Banquero clásica (bronce y pantalla verde esmeralda) ---
	var lamp_pos := Vector2(845, 620)
	# Base de latón
	draw_circle(lamp_pos, 16.0, Color(0.40, 0.30, 0.12))
	draw_circle(lamp_pos, 12.0, GOLD)
	# Mástil curvo de latón
	draw_line(lamp_pos, lamp_pos + Vector2(0, -42), GOLD, 3.5)
	# Pantalla cilíndrica de vidrio esmeralda
	var glass_rect := Rect2(lamp_pos.x - 30, lamp_pos.y - 58, 60, 18)
	draw_rect(glass_rect, Color(0.04, 0.35, 0.15, 0.95))
	draw_line(Vector2(glass_rect.position.x, glass_rect.position.y + 3), Vector2(glass_rect.end.x, glass_rect.position.y + 3), Color(0.3, 0.85, 0.45, 0.6), 1.5)
	draw_rect(glass_rect, GOLD, false, 1.5)
	# Cadena de encendido con bolita
	draw_line(Vector2(lamp_pos.x + 18, lamp_pos.y - 42), Vector2(lamp_pos.x + 18, lamp_pos.y - 25), GOLD, 1.2)
	draw_circle(Vector2(lamp_pos.x + 18, lamp_pos.y - 23), 2.0, GOLD)
	# Cono suave de luz esmeralda sobre la mesa
	if not blackout:
		draw_colored_polygon(PackedVector2Array([
			Vector2(glass_rect.position.x, glass_rect.end.y), Vector2(glass_rect.end.x, glass_rect.end.y),
			lamp_pos + Vector2(65, 30), lamp_pos + Vector2(-65, 30)
		]), Color(0.15, 0.75, 0.35, 0.04))


# ================================================================ MONITOR CRT

func _draw_crt_monitor(t: float, blackout: bool) -> void:
	var m_base := Rect2(495, 360, 290, 202)
	var screen := Rect2(512, 375, 256, 164)

	# Carcasa retro con bisel de baquelita / plástico noventero
	draw_rect(m_base, Color(0.09, 0.095, 0.105))
	draw_rect(Rect2(m_base.position.x + 4, m_base.position.y + 4, m_base.size.x - 8, m_base.size.y - 8), Color(0.13, 0.135, 0.145))
	draw_rect(m_base, Color(0.22, 0.22, 0.24), false, 2.0)

	# Ranuras de ventilación superiores de la carcasa
	for v in 8:
		var vx: float = m_base.position.x + 55.0 + v * 22.0
		draw_line(Vector2(vx, m_base.position.y + 8), Vector2(vx + 12, m_base.position.y + 8), Color(0.04, 0.04, 0.05), 2.0)

	# Pantalla convexa de cristal CRT (fósforo verde apagado o encendido)
	var screen_col := Color(0.015, 0.045, 0.030) if not blackout else Color(0.008, 0.012, 0.010)
	draw_rect(screen, screen_col)
	draw_rect(screen, Color(0.04, 0.04, 0.05), false, 3.0)

	if not blackout:
		# Estática sutil de fósforo y líneas de barrido
		for i in 12:
			var ly: float = screen.position.y + 6.0 + randf() * (screen.size.y - 12.0)
			var lw: float = 40.0 + randf() * 180.0
			draw_line(Vector2(screen.position.x + 10, ly), Vector2(screen.position.x + 10 + lw, ly), Color(0.25, 0.90, 0.50, 0.10), 1.0)

		# Reflejo curvo de lente de vidrio CRT
		draw_arc(Vector2(screen.position.x + screen.size.x * 0.5, screen.position.y + 35), 90.0, PI * 0.1, PI * 0.9, 20, Color(1, 1, 1, 0.04), 3.0)

		# Texto de señal en pantalla
		var pulse: float = 0.55 + 0.45 * sin(t * 3.5)
		draw_string(ThemeDB.fallback_font, Vector2(screen.position.x, screen.position.y + 92), "VIGILANCIA ACTIVA", HORIZONTAL_ALIGNMENT_CENTER, screen.size.x, 15, Color(0.35, 0.95, 0.55, 0.65 * pulse))
		draw_string(ThemeDB.fallback_font, Vector2(screen.position.x, screen.position.y + 115), "[ESPACIO] MONITOR", HORIZONTAL_ALIGNMENT_CENTER, screen.size.x, 12, Color(0.25, 0.70, 0.40, 0.50))

		# Resplandor verde tenue emitido por el monitor sobre el escritorio
		draw_colored_polygon(PackedVector2Array([
			Vector2(screen.position.x, m_base.end.y), Vector2(screen.end.x, m_base.end.y),
			Vector2(screen.end.x + 40, m_base.end.y + 45), Vector2(screen.position.x - 40, m_base.end.y + 45)
		]), Color(0.20, 0.85, 0.45, 0.035))

	# Botones de ajuste del monitor (Brillo, Contraste, LED de encendido)
	var by: float = m_base.end.y - 14.0
	draw_circle(Vector2(m_base.position.x + 28, by), 3.5, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2(m_base.position.x + 44, by), 3.5, Color(0.05, 0.05, 0.06))
	# LED de estado (verde si funciona, rojo en apagón)
	var led_col := Color(0.2, 0.95, 0.4, 0.9) if not blackout else Color(0.8, 0.1, 0.1, 0.4)
	draw_circle(Vector2(m_base.end.x - 28, by), 3.0, led_col)


# ================================================================ ILUMINACIÓN Y ESTADOS

func _draw_lighting_and_alerts(t: float, blackout: bool) -> void:
	if blackout:
		# Oscuridad total de apagón
		draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.01, 0.012, 0.94))
		for side in ["left", "right"]:
			if night.monster_at_gate(side) != "":
				var r: Rect2 = GATE_L if side == "left" else GATE_R
				var cx: float = r.position.x + r.size.x * 0.5
				var a: float = 0.5 + 0.5 * sin(t * 9.0)
				# Ojos penetrantes acechando en el apagón
				draw_circle(Vector2(cx - 15, r.position.y + 195), 5.5, Color(1.0, 0.2, 0.1, a))
				draw_circle(Vector2(cx + 15, r.position.y + 195), 5.5, Color(1.0, 0.2, 0.1, a))
				draw_circle(Vector2(cx - 15, r.position.y + 195), 2.0, Color(1.0, 0.9, 0.8, a))
				draw_circle(Vector2(cx + 15, r.position.y + 195), 2.0, Color(1.0, 0.9, 0.8, a))
	else:
		# Cono central de lámpara de tungsteno cálida
		for k in 6:
			var rad: float = 280.0 - k * 40.0
			draw_circle(Vector2(640, 310), rad, Color(1.0, 0.80, 0.45, 0.018))

		# Viñeta oscura en las esquinas de la oficina (profundidad)
		var v_col := Color(0.01, 0.01, 0.015, 0.45)
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(160, 0), Vector2(0, 160)]), v_col)
		draw_colored_polygon(PackedVector2Array([Vector2(W, 0), Vector2(W - 160, 0), Vector2(W, 160)]), v_col)

		# Parpadeo de tensión si la energía es crítica (< 15%)
		if night.energy.energy < 15.0 and randf() < 0.08:
			draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.60))
