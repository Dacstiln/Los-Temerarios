extends Control
## Pantalla de resultado: victoria (6:00 AM), derrota (jumpscare) o fin del MVP.

const UIUtil = preload("res://scripts/ui_util.gd")

var _won: bool = false


func _draw() -> void:
	UIUtil.draw_deco_background(self, UIUtil.GOLD if _won else UIUtil.RED)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var r: Dictionary = GameState.last_result
	_won = bool(r.get("won", false))
	var n: int = int(r.get("night", 1))
	queue_redraw()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(760, 0)
	center.add_child(box)

	if _won:
		if n >= GameState.MAX_NIGHT:
			_win_final(box)
		else:
			_win_night(box, n)
	else:
		_lose(box, n, r)


func _win_night(box: VBoxContainer, n: int) -> void:
	box.add_child(UIUtil.label("6:00 AM", 84, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIUtil.label("Sobreviviste la Noche %d" % n, 30, UIUtil.GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	if n == 3:
		var mvp := UIUtil.label("MVP completado: las 3 noches del mismo sistema.\nLas Noches 4 y 5 (Cornelius) son contenido posterior al MVP.", 18, Color(0.8, 0.78, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
		mvp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(mvp)
	var nxt := UIUtil.button("SIGUIENTE NOCHE", 22)
	nxt.custom_minimum_size = Vector2(0, 54)
	nxt.pressed.connect(func(): GameState.start_night(n + 1))
	box.add_child(nxt)
	_menu_button(box)


func _win_final(box: VBoxContainer) -> void:
	box.add_child(UIUtil.label("6:00 AM", 84, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIUtil.label("FIN — LAS 5 NOCHES SUPERADAS", 30, UIUtil.GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	var txt := UIUtil.label("Leo cobra su sueldo doble y paga la deuda.\nEl Grand Tenebris vuelve a guardar silencio... hasta la próxima medianoche.", 18, Color(0.8, 0.78, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(txt)
	var again := UIUtil.button("JUGAR DE NUEVO (NOCHE 1)", 22)
	again.custom_minimum_size = Vector2(0, 54)
	again.pressed.connect(func(): GameState.start_night(1))
	box.add_child(again)
	_menu_button(box)


func _lose(box: VBoxContainer, n: int, r: Dictionary) -> void:
	box.add_child(UIUtil.label("JUMPSCARE", 80, UIUtil.RED, HORIZONTAL_ALIGNMENT_CENTER))
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
	var retry := UIUtil.button("REINTENTAR NOCHE %d" % n, 22)
	retry.custom_minimum_size = Vector2(0, 54)
	retry.pressed.connect(func(): GameState.start_night(n))
	box.add_child(retry)
	_menu_button(box)


func _menu_button(box: VBoxContainer) -> void:
	var m := UIUtil.button("MENÚ PRINCIPAL", 20)
	m.custom_minimum_size = Vector2(0, 48)
	m.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	box.add_child(m)
