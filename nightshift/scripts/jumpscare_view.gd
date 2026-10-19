extends Control
## Jumpscare a pantalla completa: la cara del monstruo crece y tiembla.

const Figures = preload("res://scripts/figures.gd")

var kind: String = "botones"
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0))
	var k: float = clampf(_t / 0.35, 0.0, 1.0)
	var shake := Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0)) * k
	var r: float = lerpf(120.0, 330.0, k * k)
	Figures.draw_face(self, kind, Vector2(640.0, 300.0) + shake, r, 0.0)
	var red_a: float = clampf(0.55 - _t * 0.3, 0.0, 0.55)
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.8, 0.0, 0.0, red_a))
	for i in 160:
		var y: float = randf() * 720.0
		draw_line(Vector2(0, y), Vector2(randf() * 1280.0, y), Color(1, 1, 1, randf() * 0.12), 1.0)
