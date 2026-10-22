extends RefCounted
## Helpers de UI con la estetica Art Deco Decadente (dorado sobre negro).

const GOLD := Color(0.83, 0.69, 0.22)
const GOLD_DIM := Color(0.50, 0.42, 0.14)
const INK := Color(0.04, 0.04, 0.05)
const RED := Color(0.80, 0.18, 0.15)
const GREEN := Color(0.35, 0.95, 0.55)


static func box(bg: Color, border: Color, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb


static func button(text: String, font_size: int = 18, toggle: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_hover_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color(0.38, 0.38, 0.38))
	b.add_theme_stylebox_override("normal", box(Color(0.05, 0.05, 0.06, 0.92), GOLD_DIM))
	b.add_theme_stylebox_override("hover", box(Color(0.13, 0.10, 0.04, 0.95), GOLD))
	b.add_theme_stylebox_override("pressed", box(GOLD, GOLD))
	b.add_theme_stylebox_override("hover_pressed", box(GOLD, Color(1, 1, 1)))
	b.add_theme_stylebox_override("disabled", box(Color(0.05, 0.05, 0.05, 0.7), Color(0.22, 0.22, 0.22)))
	return b


static func label(text: String, font_size: int = 18, color: Color = GOLD, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l




static var _title_font: Font = null


## Fuente decorativa: usa una tipografia del sistema (Copperplate/Georgia...) si existe y,
## si no, la fuente por defecto de Godot. No requiere archivos de fuente en el proyecto.
static func title_font() -> Font:
	if _title_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Copperplate Gothic Bold", "Copperplate", "Poiret One", "Playfair Display", "Cinzel", "Georgia", "Times New Roman", "serif"])
		f.font_weight = 700
		_title_font = f
	return _title_font


## Boton de menu: como `button` pero con sonido al pasar el raton y al pulsar.
static func menu_button(text: String, font_size: int = 20) -> Button:
	var b := button(text, font_size, false)
	b.mouse_entered.connect(func(): SoundBank.play("hover", -6.0))
	b.pressed.connect(func(): SoundBank.play("click", -2.0))
	return b


## Etiqueta con la fuente decorativa (titulos).
static func title_label(text: String, font_size: int = 48, color: Color = GOLD, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, font_size, color, align)
	l.add_theme_font_override("font", title_font())
	return l


## Circulo suave como textura (para el control del slider).
static func dot_texture(color: Color, size: int = 20) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: float = (size - 1) * 0.5
	for y in size:
		for x in size:
			var d: float = Vector2(x - c, y - c).length()
			var a: float = clampf(c + 0.5 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)


## Slider con la estetica dorada.
static func style_slider(sl: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.15, 0.13, 0.05)
	track.content_margin_top = 4.0
	track.content_margin_bottom = 4.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.content_margin_top = 4.0
	fill.content_margin_bottom = 4.0
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	sl.add_theme_icon_override("grabber", dot_texture(GOLD, 22))
	sl.add_theme_icon_override("grabber_highlight", dot_texture(Color(1, 1, 1), 24))
	sl.add_theme_icon_override("grabber_disabled", dot_texture(GOLD_DIM, 22))


## Panel con doble borde (marco Art Deco) para menus.
static func deco_panel(bg: Color = Color(0.03, 0.03, 0.035, 0.88)) -> StyleBoxFlat:
	var sb := box(bg, GOLD_DIM, 2)
	sb.content_margin_left = 28.0
	sb.content_margin_right = 28.0
	sb.content_margin_top = 22.0
	sb.content_margin_bottom = 22.0
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 18
	return sb


# ------------------------------------------------------------------- dibujo

## Fondo Art Deco animado (abanico dorado, rayos de luz, particulas, marco de esquinas).
## `t` = tiempo en segundos (para animar); con 0 queda estatico.
static func draw_deco_background(ci: CanvasItem, tint: Color = GOLD, t: float = 0.0) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.02, 0.025))
	# degradado vertical cálido en la parte baja
	for k in 12:
		var a: float = 0.012 * float(k)
		ci.draw_rect(Rect2(0, 360 + k * 30, 1280, 30), Color(tint.r, tint.g * 0.7, tint.b * 0.3, a))
	var origin := Vector2(640, 800)
	for i in range(-16, 17):
		var wob: float = sin(t * 0.4 + i * 0.7) * 0.02
		var dir := Vector2(0, -1).rotated(i * 0.105 + wob)
		var a2: float = 0.055 + 0.03 * sin(t * 0.8 + i)
		ci.draw_line(origin, origin + dir * 1100.0, Color(tint.r, tint.g, tint.b, a2), 2.0)
	for k in 5:
		ci.draw_arc(origin, 240.0 + k * 62.0, PI * 1.1, PI * 1.9, 56, Color(tint.r, tint.g, tint.b, 0.14 - k * 0.012), 2.0)
	# haz de luz de lampara
	for k in 5:
		ci.draw_circle(Vector2(640, 90), 330.0 - k * 55.0, Color(1.0, 0.8, 0.4, 0.012))
	# particulas de polvo
	for i in 26:
		var seed_x: float = fmod(float(i) * 197.3, 1280.0)
		var y: float = fmod(float(i) * 83.7 + t * (8.0 + (i % 5) * 4.0), 720.0)
		var x: float = seed_x + sin(t * 0.5 + i) * 14.0
		ci.draw_circle(Vector2(x, 720.0 - y), 1.2 + float(i % 3) * 0.5, Color(tint.r, tint.g, tint.b, 0.10 + 0.08 * sin(t + i)))
	# marcos
	ci.draw_rect(Rect2(24, 24, 1232, 672), Color(tint.r, tint.g, tint.b, 0.40), false, 2.0)
	ci.draw_rect(Rect2(36, 36, 1208, 648), Color(tint.r, tint.g, tint.b, 0.16), false, 1.0)
	for c in [Vector2(24, 24), Vector2(1256, 24), Vector2(24, 696), Vector2(1256, 696)]:
		_corner(ci, c, Vector2(-1.0 if c.x > 600.0 else 1.0, -1.0 if c.y > 300.0 else 1.0), tint)


static func _corner(ci: CanvasItem, p: Vector2, dir: Vector2, tint: Color) -> void:
	var col := Color(tint.r, tint.g, tint.b, 0.9)
	for k in 3:
		var o: float = 14.0 + k * 10.0
		ci.draw_line(p + Vector2(dir.x * o, 0), p + Vector2(0, dir.y * o), col, 2.0)
	ci.draw_circle(p + dir * 6.0, 3.0, col)


## Separador ornamental: linea con rombo central.
static func draw_divider(ci: CanvasItem, center: Vector2, width: float, tint: Color = GOLD) -> void:
	var col := Color(tint.r, tint.g, tint.b, 0.8)
	ci.draw_line(center + Vector2(-width * 0.5, 0), center + Vector2(-10, 0), col, 1.5)
	ci.draw_line(center + Vector2(10, 0), center + Vector2(width * 0.5, 0), col, 1.5)
	ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -7), center + Vector2(8, 0), center + Vector2(0, 7), center + Vector2(-8, 0)]), col)
	ci.draw_circle(center + Vector2(-width * 0.5, 0), 3.0, col)
	ci.draw_circle(center + Vector2(width * 0.5, 0), 3.0, col)


## Logo del juego: abanico dorado detras del titulo "NIGHT SHIFT", subtitulo y letrero de neon.
static func draw_logo(ci: CanvasItem, center: Vector2, t: float) -> void:
	var f: Font = title_font()
	var fan_c := center + Vector2(0, 62)
	for i in range(-6, 7):
		var dir := Vector2(0, -1).rotated(i * 0.19)
		var len: float = 150.0 + (30.0 if i % 2 == 0 else 0.0)
		ci.draw_line(fan_c, fan_c + dir * len, Color(GOLD.r, GOLD.g, GOLD.b, 0.55), 2.0)
	for k in 3:
		ci.draw_arc(fan_c, 60.0 + k * 34.0, PI * 1.12, PI * 1.88, 32, Color(GOLD.r, GOLD.g, GOLD.b, 0.5 - k * 0.1), 2.0)
	# titulo con sombra y brillo
	var flick: float = 1.0 if fmod(t, 6.3) > 0.15 else 0.55
	var title := "NIGHT SHIFT"
	var sz: int = 86
	ci.draw_string(f, center + Vector2(-640 + 4, 18 + 4), title, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, sz, Color(0, 0, 0, 0.8))
	ci.draw_string(f, center + Vector2(-640, 18), title, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, sz, Color(GOLD.r, GOLD.g, GOLD.b, flick))
	ci.draw_string(f, center + Vector2(-640, 17), title, HORIZONTAL_ALIGNMENT_CENTER, 1280.0, sz, Color(1.0, 0.92, 0.6, 0.18 * flick))
	draw_divider(ci, center + Vector2(0, 44), 520.0)
	ci.draw_string(f, center + Vector2(-640, 82), "AT THE GRAND TENEBRIS", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 26, Color(GOLD_DIM.r + 0.2, GOLD_DIM.g + 0.18, GOLD_DIM.b + 0.1))
