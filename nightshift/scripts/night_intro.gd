extends Control
## Tarjeta de inicio de cada noche (la crea night.gd en _show_intro()).
## Reloj que pasa de 11:59 PM a 12:00 AM con campanada, titulo con destello,
## pista escrita a maquina y las amenazas de la noche (las nuevas marcadas "NUEVO").
## Fondo: escenario 3D estilo FNAF (stage_3d.gd) con el monstruo nuevo de la noche.
## Cualquier tecla la salta; night.gd la desvanece y la libera al empezar.

const UIUtil = preload("res://scripts/ui_util.gd")
const Stage3D = preload("res://scripts/3d/stage_3d.gd")
const COL_W: float = 760.0   # columna izquierda para el texto; el monstruo 3D va a la derecha
const Balance = preload("res://scripts/balance.gd")

const NAMES: Dictionary = {
	"botones": "EL BOTONES", "chef": "EL CHEF", "mucama": "LA MUCAMA",
	"cornelius": "CORNELIUS", "bailarina": "LA BAILARINA",
}
const MIDNIGHT_AT: float = 1.1      # segundo en que el reloj marca las 12:00

var cfg: Dictionary = {}
var night: int = 1

var _t: float = 0.0
var _roster: Array = []
var _new: Array = []
var _chimed: bool = false
var _hint: Label
var _stage = null


func setup(night_cfg: Dictionary, n: int) -> void:
	cfg = night_cfg
	night = n
	_roster = _monsters_of(cfg)
	if Balance.NIGHTS.has(n - 1):
		var before: Array = _monsters_of(Balance.NIGHTS[n - 1])
		for k in _roster:
			if not before.has(k):
				_new.append(k)
	else:
		_new = _roster.duplicate()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint = UIUtil.label(String(cfg.get("hint", "")), 18, Color(0.78, 0.76, 0.7), HORIZONTAL_ALIGNMENT_CENTER)
	_hint.position = Vector2(80, 368)
	_hint.size = Vector2(600, 90)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.visible_ratio = 0.0
	add_child(_hint)
	var tw := create_tween()
	tw.tween_interval(MIDNIGHT_AT + 0.4)
	tw.tween_property(_hint, "visible_ratio", 1.0, 1.6)
	# Capa 29: justo detras de la tarjeta (que esta en la capa 30)
	var faces: Array = _new.duplicate() if not _new.is_empty() else _roster.duplicate()
	_stage = Stage3D.attach(self, {"kinds": faces, "focus_x": 0.74, "swap_every": 3.0, "static_base": 0.2}, 29)


func _process(delta: float) -> void:
	_t += delta
	if _stage != null:
		_stage.modulate.a = modulate.a   # se desvanece junto con la tarjeta
	if not _chimed and _t >= MIDNIGHT_AT:
		_chimed = true
		SoundBank.play("bell", -10.0)
	queue_redraw()


func _monsters_of(c: Dictionary) -> Array:
	var out: Array = ["botones"]
	for k in ["chef", "mucama", "cornelius"]:
		if c.has(k):
			out.append(k)
	if c.has("box"):
		out.append("bailarina")
	return out


func _draw() -> void:
	var gold := UIUtil.GOLD
	var f: Font = UIUtil.title_font()
	# Sombra a la izquierda para leer el texto sobre el escenario 3D
	for k in 24:
		draw_rect(Rect2(k * 36.0, 0, 36.0, 720.0), Color(0, 0, 0, clampf(0.9 - k * 0.04, 0.0, 0.9)))

	var appear: float = clampf(_t / 0.6, 0.0, 1.0)
	var cx: float = COL_W * 0.5

	draw_string(ThemeDB.fallback_font, Vector2(0, 92), "THE GRAND TENEBRIS  ·  REGISTRO DE TURNOS", HORIZONTAL_ALIGNMENT_CENTER, COL_W, 15,
		Color(gold.r, gold.g, gold.b, 0.6 * appear))

	# Titulo con destello al dar la medianoche
	var title: String = String(cfg.get("title", "NOCHE %d" % night))
	var flash: float = clampf(1.0 - (_t - MIDNIGHT_AT) * 2.0, 0.0, 1.0) if _t >= MIDNIGHT_AT else 0.0
	var tcol := Color(0.9, 0.88, 0.82, appear).lerp(Color(1.0, 1.0, 1.0, appear), flash)
	draw_string(f, Vector2(4, 198), title, HORIZONTAL_ALIGNMENT_CENTER, COL_W, 84, Color(0, 0, 0, 0.7 * appear))
	draw_string(f, Vector2(0, 194), title, HORIZONTAL_ALIGNMENT_CENTER, COL_W, 84, tcol)
	UIUtil.draw_divider(self, Vector2(cx, 222), 520.0 * appear)

	# Reloj: 11:59 PM -> 12:00 AM
	var clock: String = "11:59 PM" if _t < MIDNIGHT_AT else "12:00 AM"
	var ccol: Color = Color(0.7, 0.66, 0.55, appear) if _t < MIDNIGHT_AT else Color(0.95, 0.3, 0.22, 1.0)
	if _t < MIDNIGHT_AT and fmod(_t, 0.5) < 0.25:
		clock = "11:59 PM".replace(":", " ")
	draw_string(f, Vector2(0, 276), clock, HORIZONTAL_ALIGNMENT_CENTER, COL_W, 40, ccol)
	_draw_clock_face(Vector2(cx - 150, 262), 22.0)
	_draw_clock_face(Vector2(cx + 150, 262), 22.0)

	var sub: String = String(cfg.get("subtitle", ""))
	draw_string(ThemeDB.fallback_font, Vector2(0, 340), sub, HORIZONTAL_ALIGNMENT_CENTER, COL_W, 22,
		Color(0.85, 0.82, 0.75, clampf((_t - 0.5) / 0.5, 0.0, 1.0)))

	_draw_roster()

	# Pie
	var blink: float = 0.45 + 0.45 * sin(_t * 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(0, 690), "PULSA CUALQUIER TECLA PARA EMPEZAR EL TURNO", HORIZONTAL_ALIGNMENT_CENTER, COL_W, 14,
		Color(gold.r, gold.g, gold.b, blink * clampf(_t - 1.5, 0.0, 1.0)))


func _draw_clock_face(c: Vector2, r: float) -> void:
	var gold := UIUtil.GOLD
	draw_circle(c, r, Color(0.08, 0.06, 0.03))
	draw_arc(c, r, 0.0, TAU, 32, gold, 2.0)
	for i in 12:
		var a: float = TAU * float(i) / 12.0
		draw_line(c + Vector2(cos(a), sin(a)) * (r - 4.0), c + Vector2(cos(a), sin(a)) * (r - 1.0), gold, 1.0)
	# Minutero: llega a las 12 en MIDNIGHT_AT
	var k: float = clampf(_t / MIDNIGHT_AT, 0.0, 1.0)
	var min_a: float = -PI * 0.5 - (1.0 - k) * (TAU / 60.0) * 3.0
	draw_line(c, c + Vector2(cos(min_a), sin(min_a)) * (r - 5.0), Color(0.95, 0.9, 0.75), 2.0)
	draw_line(c, c + Vector2(0, -1) * (r * 0.55), Color(0.95, 0.9, 0.75), 3.0)
	draw_circle(c, 2.5, gold)


## Las amenazas de la noche en lista; las nuevas en blanco con la etiqueta NUEVO.
func _draw_roster() -> void:
	var gold := UIUtil.GOLD
	var a: float = clampf((_t - 0.9) / 0.6, 0.0, 1.0)
	if a <= 0.0:
		return
	var cx: float = COL_W * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(0, 492), "AMENAZAS DE ESTA NOCHE", HORIZONTAL_ALIGNMENT_CENTER, COL_W, 13,
		Color(gold.r, gold.g, gold.b, 0.7 * a))
	UIUtil.draw_divider(self, Vector2(cx, 504), 260.0 * a)
	for i in _roster.size():
		var key: String = String(_roster[i])
		var is_new: bool = _new.has(key)
		var ai: float = clampf((_t - 0.9 - i * 0.15) / 0.4, 0.0, 1.0)
		if ai <= 0.0:
			continue
		var y: float = 532.0 + i * 27.0
		var col: Color = Color(0.95, 0.93, 0.88, ai) if is_new else Color(0.55, 0.53, 0.48, ai)
		draw_string(UIUtil.title_font(), Vector2(0, y), String(NAMES.get(key, key)), HORIZONTAL_ALIGNMENT_CENTER, COL_W, 20, col)
		if is_new:
			var tag := Rect2(cx + 105.0, y - 15.0, 52.0, 18.0)
			draw_rect(tag, Color(0.7, 0.1, 0.08, 0.9 * ai))
			draw_string(ThemeDB.fallback_font, Vector2(tag.position.x, tag.position.y + 14.0), "NUEVO", HORIZONTAL_ALIGNMENT_CENTER, 52.0, 11,
				Color(1, 0.95, 0.85, ai))
