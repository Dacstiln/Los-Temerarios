extends Control
## Menu principal: jugar, continuar, seleccionar noche (hasta la desbloqueada) y controles.

const UIUtil = preload("res://scripts/ui_util.gd")

const CONTROLS_TEXT: String = """CONTROLES

A / D ........ Reja izquierda / derecha
ESPACIO ...... Subir / bajar el monitor
1 - 7 ........ Cambiar de cámara
F ............ Flash de cámara (cámaras oscuras)
I ............ Intercomunicador (jazz en la cámara
               seleccionada)
B ............ Sobrecargo de Caldera
ESC .......... Pausa

DEPURACIÓN (playtesting)
F1 estados  F2 +30 s  F3 batería  F4 apagón

Toda acción cuesta energía del mismo generador.
Cada monstruo exige una contramedida distinta."""


func _draw() -> void:
	UIUtil.draw_deco_background(self)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SoundBank.stop_all_loops()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 70)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 70)
	margin.add_child(row)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)

	left.add_child(UIUtil.label("NIGHT SHIFT", 68, UIUtil.GOLD))
	left.add_child(UIUtil.label("AT THE GRAND TENEBRIS", 28, UIUtil.GOLD_DIM))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	left.add_child(spacer)

	var play := UIUtil.button("JUGAR — NOCHE 1", 22)
	play.custom_minimum_size = Vector2(380, 52)
	play.pressed.connect(func(): GameState.start_night(1))
	left.add_child(play)

	var cont := UIUtil.button("CONTINUAR — NOCHE %d" % GameState.unlocked_night, 22)
	cont.custom_minimum_size = Vector2(380, 52)
	cont.disabled = GameState.unlocked_night <= 1
	cont.pressed.connect(func(): GameState.start_night(GameState.unlocked_night))
	left.add_child(cont)

	left.add_child(UIUtil.label("SELECCIONAR NOCHE", 16, UIUtil.GOLD_DIM))
	var nights := HBoxContainer.new()
	nights.add_theme_constant_override("separation", 10)
	left.add_child(nights)
	for n in range(1, GameState.MAX_NIGHT + 1):
		var b := UIUtil.button("NOCHE %d" % n, 18)
		b.custom_minimum_size = Vector2(108, 46)
		b.disabled = n > GameState.unlocked_night
		b.pressed.connect(_start.bind(n))
		nights.add_child(b)

	var quit := UIUtil.button("SALIR", 20)
	quit.custom_minimum_size = Vector2(380, 46)
	quit.pressed.connect(func(): get_tree().quit())
	left.add_child(quit)

	var credit := UIUtil.label("Universidad de Colima · Facultad de Telemática\nIngeniería de Software — Videojuegos · GDD v1 (MVP: 3 noches + 2 extra)", 14, UIUtil.GOLD_DIM)
	left.add_child(credit)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.box(Color(0.03, 0.03, 0.035, 0.85), UIUtil.GOLD_DIM))
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var ctl := UIUtil.label(CONTROLS_TEXT, 17, Color(0.85, 0.82, 0.7))
	ctl.custom_minimum_size = Vector2(440, 0)
	panel.add_child(ctl)


func _start(n: int) -> void:
	GameState.start_night(n)
