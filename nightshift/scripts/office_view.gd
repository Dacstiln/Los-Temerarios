extends Control
## Vista de la oficina (zona segura, punto de todas las decisiones): escritorio con monitor CRT,
## dos rejas de ascensor (izq/der) y la rejilla de ventilacion.

const Figures = preload("res://scripts/figures.gd")

var night = null

const W: float = 1280.0
const H: float = 720.0
const GATE_L := Rect2(250.0, 150.0, 220.0, 410.0)
const GATE_R := Rect2(810.0, 150.0, 220.0, 410.0)
const GOLD := Color(0.83, 0.69, 0.22)


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

	# --- pared Art Deco ---
	draw_rect(Rect2(0, 0, W, H), Color(0.045, 0.04, 0.035))
	for i in 13:
		draw_line(Vector2(i * 100.0, 0), Vector2(i * 100.0, 560), Color(GOLD.r, GOLD.g, GOLD.b, 0.10), 2.0)
	for k in 4:
		var ins: float = k * 16.0
		draw_polyline(PackedVector2Array([
			Vector2(500 + ins, 560), Vector2(500 + ins, 270 + ins), Vector2(545 + ins, 215 + ins),
			Vector2(590 + ins, 165 + ins), Vector2(640, 128 + ins), Vector2(690 - ins, 165 + ins),
			Vector2(735 - ins, 215 + ins), Vector2(780 - ins, 270 + ins), Vector2(780 - ins, 560)
		]), Color(GOLD.r, GOLD.g, GOLD.b, 0.35 - k * 0.06), 2.0)

	# --- rejilla de ventilacion (Mucama) ---
	_draw_vent(t)

	# --- aberturas con rejas ---
	for side in ["left", "right"]:
		_draw_gate(side, t, blackout)

	# --- escritorio y monitor ---
	draw_rect(Rect2(0, 560, W, 160), Color(0.07, 0.05, 0.04))
	draw_rect(Rect2(110, 590, 1060, 130), Color(0.13, 0.08, 0.05))
	draw_line(Vector2(110, 590), Vector2(1170, 590), GOLD, 3.0)
	draw_rect(Rect2(500, 360, 280, 200), Color(0.10, 0.10, 0.11))
	draw_rect(Rect2(516, 376, 248, 160), Color(0.02, 0.07, 0.05))
	for i in 14:
		var ly: float = 380.0 + randf() * 150.0
		draw_line(Vector2(520, ly), Vector2(520 + randf() * 230.0, ly), Color(0.3, 0.9, 0.5, 0.18), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(516, 460), "MONITOR", HORIZONTAL_ALIGNMENT_CENTER, 248.0, 22, Color(0.35, 0.95, 0.55, 0.5))
	# lampara tungsteno
	for k in 6:
		draw_circle(Vector2(640, 330), 260.0 - k * 38.0, Color(1.0, 0.75, 0.35, 0.022))

	# --- apagon / energia baja ---
	if blackout:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.94))
		for side in ["left", "right"]:
			if night.monster_at_gate(side) != "":
				var r: Rect2 = GATE_L if side == "left" else GATE_R
				var cx: float = r.position.x + r.size.x * 0.5
				var a: float = 0.5 + 0.5 * sin(t * 9.0)
				draw_circle(Vector2(cx - 14, r.position.y + 190), 5.0, Color(1, 0.2, 0.1, a))
				draw_circle(Vector2(cx + 14, r.position.y + 190), 5.0, Color(1, 0.2, 0.1, a))
	elif night.energy.energy < 15.0 and randf() < 0.06:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.55))


func _draw_vent(t: float) -> void:
	var rat: float = night.vent_rattle()
	var glow: float = night.boiler_glow
	var base := Rect2(590, 40, 100, 70)
	var shake: float = sin(t * 55.0) * 3.0 * rat
	draw_rect(Rect2(base.position.x + shake, base.position.y, base.size.x, base.size.y), Color(0.06, 0.06, 0.07))
	var col: Color = Color(GOLD.r, GOLD.g, GOLD.b, 0.5)
	if glow > 0.0:
		col = Color(1.0, 0.45, 0.1, 0.9)
	elif rat > 0.0:
		col = Color(0.5, 1.0, 0.6, 0.3 + 0.5 * rat)
	for i in 6:
		var y: float = base.position.y + 8.0 + i * 10.0
		draw_line(Vector2(base.position.x + 8 + shake, y), Vector2(base.end.x - 8 + shake, y), col, 3.0)
	draw_rect(Rect2(base.position.x + shake, base.position.y, base.size.x, base.size.y), GOLD, false, 2.0)


func _draw_gate(side: String, t: float, blackout: bool) -> void:
	var r: Rect2 = GATE_L if side == "left" else GATE_R
	draw_rect(r, Color(0.01, 0.01, 0.015))
	var cx: float = r.position.x + r.size.x * 0.5
	var cy: float = r.position.y + r.size.y * 0.45
	for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		draw_line(p, Vector2(cx, cy), Color(0.4, 0.33, 0.12, 0.12), 1.0)

	# monstruo tras la reja (silueta con ojos brillantes)
	if not blackout:
		var kind: String = night.monster_at_gate(side)
		if kind != "":
			var sway: float = sin(t * 2.0) * 3.0
			Figures.draw_figure(self, kind, Vector2(cx + sway, r.end.y - 6.0), 1.6, 0.8)

	# reja de ascensor (acordeon que baja)
	var a: float = night.gate_anim[side]
	if a > 0.01:
		var bh: float = r.size.y * a
		var x: float = r.position.x
		while x <= r.end.x + 0.1:
			draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + bh), Color(0.6, 0.5, 0.18), 3.0)
			x += 22.0
		var y0: float = r.position.y
		while y0 + 40.0 <= r.position.y + bh:
			var pts := PackedVector2Array()
			var n: int = int(r.size.x / 22.0) + 1
			for i in n:
				pts.append(Vector2(r.position.x + i * 22.0, y0 + (i % 2) * 40.0))
			draw_polyline(pts, Color(0.7, 0.58, 0.2), 2.0)
			y0 += 40.0
		draw_line(Vector2(r.position.x, r.position.y + bh), Vector2(r.end.x, r.position.y + bh), GOLD, 5.0)
	draw_rect(r, GOLD, false, 4.0)
	var label: String = "REJA IZQ" if side == "left" else "REJA DER"
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.position.y - 12.0), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color(GOLD.r, GOLD.g, GOLD.b, 0.6))
