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


## Fondo Art Deco simple (abanico dorado + marco) para menus.
static func draw_deco_background(ci: CanvasItem, tint: Color = GOLD) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.02, 0.025))
	var origin := Vector2(640, 780)
	for i in range(-14, 15):
		var dir := Vector2(0, -1).rotated(i * 0.115)
		ci.draw_line(origin, origin + dir * 1000.0, Color(tint.r, tint.g, tint.b, 0.07), 2.0)
	for k in 4:
		ci.draw_arc(origin, 260.0 + k * 70.0, PI * 1.12, PI * 1.88, 48, Color(tint.r, tint.g, tint.b, 0.12), 2.0)
	ci.draw_rect(Rect2(24, 24, 1232, 672), Color(tint.r, tint.g, tint.b, 0.35), false, 2.0)
	ci.draw_rect(Rect2(36, 36, 1208, 648), Color(tint.r, tint.g, tint.b, 0.15), false, 1.0)
