extends Control
## Menu de pausa (ESC). Funciona aunque el arbol este pausado.

const UIUtil = preload("res://scripts/ui_util.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	box.add_child(UIUtil.label("PAUSA", 48, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := UIUtil.button("CONTINUAR  [ESC]", 22)
	resume.custom_minimum_size = Vector2(320, 52)
	resume.pressed.connect(close)
	box.add_child(resume)
	var menu := UIUtil.button("MENÚ PRINCIPAL", 22)
	menu.custom_minimum_size = Vector2(320, 52)
	menu.pressed.connect(_to_menu)
	box.add_child(menu)


func open() -> void:
	visible = true
	get_tree().paused = true
	SoundBank.set_paused(true)


func close() -> void:
	visible = false
	get_tree().paused = false
	SoundBank.set_paused(false)


func _to_menu() -> void:
	SoundBank.stop_all_loops()
	SoundBank.set_paused(false)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var ke := event as InputEventKey
	if ke != null and ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
