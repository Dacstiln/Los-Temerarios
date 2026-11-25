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


## Opcion de menu al estilo FNAF 1: texto plano alineado a la izquierda, sin caja;
## al pasar el raton aparece ">>" delante y se oye el click.
static func fnaf_button(text: String, font_size: int = 30) -> Button:
	var b := Button.new()
	b.text = "    " + text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_font_override("font", title_font())
	b.add_theme_color_override("font_color", Color(0.80, 0.78, 0.74))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_hover_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.30, 0.30, 0.30))
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.text = ">>  " + text
			SoundBank.play("hover", -6.0))
	b.mouse_exited.connect(func(): b.text = "    " + text)
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

## Separador ornamental: linea con rombo central.
static func draw_divider(ci: CanvasItem, center: Vector2, width: float, tint: Color = GOLD) -> void:
	var col := Color(tint.r, tint.g, tint.b, 0.8)
	ci.draw_line(center + Vector2(-width * 0.5, 0), center + Vector2(-10, 0), col, 1.5)
	ci.draw_line(center + Vector2(10, 0), center + Vector2(width * 0.5, 0), col, 1.5)
	ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -7), center + Vector2(8, 0), center + Vector2(0, 7), center + Vector2(-8, 0)]), col)
	ci.draw_circle(center + Vector2(-width * 0.5, 0), 3.0, col)
	ci.draw_circle(center + Vector2(width * 0.5, 0), 3.0, col)
