extends Control
## Pantalla de resultado: victoria (6:00 AM), derrota (jumpscare) o fin del MVP.
## Fondo 3D estilo FNAF (stage_3d.gd): en la derrota, el monstruo que te atrapo en rojo;
## en la victoria, los monstruos de la noche en fila, en la penumbra.

const UIUtil = preload("res://scripts/ui_util.gd")
const Stage3D = preload("res://scripts/3d/stage_3d.gd")
const Balance = preload("res://scripts/balance.gd")

var _won: bool = false
var _t: float = 0.0
var _mon_key: String = ""


func _draw() -> void:
	# Sombra a la izquierda para leer el texto sobre el escenario 3D
	for k in 24:
		draw_rect(Rect2(k * 36.0, 0, 36.0, 720.0), Color(0, 0, 0, clampf(0.88 - k * 0.04, 0.0, 0.88)))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var r: Dictionary = GameState.last_result
	_won = bool(r.get("won", false))
	_mon_key = String(r.get("monster_key", ""))
	SoundBank.stop_all_loops()
	SoundBank.play("win" if _won else "lose", -2.0)
	var n: int = int(r.get("night", 1))
	queue_redraw()

	if _won:
		var cfg: Dictionary = Balance.NIGHTS.get(n, {})
		var line: Array = ["botones"]
		for k in ["chef", "mucama", "cornelius"]:
			if cfg.has(k):
				line.append(k)
		if cfg.has("box"):
			line.append("bailarina")
		Stage3D.attach(self, {"mode": Stage3D.Mode.LINEUP, "kinds": line, "darkness": 0.35,
			"light_energy": 1.1, "static_base": 0.1, "light_color": Color(0.95, 0.8, 0.55)})
	else:
		var killer: String = _mon_key if _mon_key != "" else "botones"
		Stage3D.attach(self, {"kinds": [killer], "focus_x": 0.72, "red_mode": true,
			"swap_every": 0.0, "twitch_every": 1.8})

	# Columna de texto a la izquierda, como en FNAF
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.position = Vector2(60, 110)
	box.custom_minimum_size = Vector2(640, 0)
	box.size = Vector2(640, 10)
	add_child(box)

	if _won:
		if n >= GameState.MAX_NIGHT:
			_win_final(box)
		else:
			_win_night(box, n)
	else:
		_lose(box, n, r)


func _win_night(box: VBoxContainer, n: int) -> void:
	box.add_child(_six_am_clock())
	box.add_child(UIUtil.label("Sobreviviste la Noche %d" % n, 30, UIUtil.GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	if n == 3:
		var mvp := UIUtil.label("MVP completado: las 3 noches del mismo sistema.\nLas Noches 4 y 5 (Cornelius) son contenido extra.", 18, Color(0.8, 0.78, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
		mvp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(mvp)
	var nxt := UIUtil.fnaf_button("SIGUIENTE NOCHE", 22)
	nxt.custom_minimum_size = Vector2(0, 54)
	nxt.pressed.connect(func(): GameState.start_night(n + 1))
	box.add_child(nxt)
	_menu_button(box)


func _win_final(box: VBoxContainer) -> void:
	box.add_child(_six_am_clock())
	box.add_child(UIUtil.label("FIN — LAS 5 NOCHES SUPERADAS", 30, UIUtil.GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	var txt := UIUtil.label("Leo cobra su sueldo doble y paga la deuda.\nEl Grand Tenebris vuelve a guardar silencio... hasta la próxima medianoche.", 18, Color(0.8, 0.78, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(txt)
	var again := UIUtil.fnaf_button("JUGAR DE NUEVO (NOCHE 1)", 22)
	again.custom_minimum_size = Vector2(0, 54)
	again.pressed.connect(func(): GameState.start_night(1))
	box.add_child(again)
	_menu_button(box)


func _lose(box: VBoxContainer, n: int, r: Dictionary) -> void:
	box.add_child(UIUtil.title_label("JUMPSCARE", 80, UIUtil.RED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIUtil.label("Noche %d — te alcanzó %s" % [n, String(r.get("monster", "?"))], 28, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var cause: String
	if String(r.get("reason", "")) == "apagon":
		cause = "Derrota por Apagón: la energía llegó a 0%, las rejas se abrieron y las cámaras se apagaron."
	else:
		cause = "Derrota por contramedida incorrecta o tardía."
	var cl := UIUtil.label(cause, 20, Color(0.9, 0.85, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(cl)
	var hl := UIUtil.label("Pista: " + String(r.get("hint", "")), 17, Color(0.7, 0.7, 0.65), HORIZONTAL_ALIGNMENT_CENTER)
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hl)
	var note := UIUtil.label("Toda derrota depende de una decisión tuya: gestión de energía o identificación de la amenaza.", 14, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var retry := UIUtil.fnaf_button("REINTENTAR NOCHE %d" % n, 22)
	retry.custom_minimum_size = Vector2(0, 54)
	retry.pressed.connect(func(): GameState.start_night(n))
	box.add_child(retry)
	_menu_button(box)


## "5:59 AM" que salta a "6:00 AM" con campanada, como en FNAF.
func _six_am_clock() -> Label:
	var l := UIUtil.title_label("5:59 AM", 84, Color(0.9, 0.88, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
	var tw := create_tween()
	tw.tween_interval(1.3)
	tw.tween_callback(func():
		l.text = "6:00 AM"
		l.add_theme_color_override("font_color", UIUtil.GOLD)
		SoundBank.play("bell", -4.0))
	return l


func _menu_button(box: VBoxContainer) -> void:
	var m := UIUtil.fnaf_button("MENÚ PRINCIPAL", 20)
	m.custom_minimum_size = Vector2(0, 48)
	m.pressed.connect(func(): GameState.goto_menu())
	box.add_child(m)
