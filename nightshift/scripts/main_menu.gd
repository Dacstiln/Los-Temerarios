extends Control
## Menu principal con 4 paginas dentro de una sola escena:
##   PORTADA (jugar / configuracion / controles / salir)
##   JUGAR   (nuevo juego / continuar / seleccionar noche)
##   CONTROLES y CONFIGURACION
## Todo se construye por codigo; no hace falta tocar main_menu.tscn.

const UIUtil = preload("res://scripts/ui_util.gd")
const Figures = preload("res://scripts/figures.gd")
const Balance = preload("res://scripts/balance.gd")

const NIGHT_INFO: Array = [
	"Solo el Botones",
	"+ Chef y Cajita de Música",
	"+ la Mucama",
	"+ Cornelius",
	"Todo más rápido",
]

enum Page { TITLE, PLAY, CONTROLS, SETTINGS }

var _pages: Dictionary = {}
var _page: int = Page.TITLE
var _t: float = 0.0
var _confirm: Control = null
var _theme_started: bool = false


func _draw() -> void:
	UIUtil.draw_deco_background(self, UIUtil.GOLD, _t)
	# Personajes a los lados (siluetas con ojos brillantes que parpadean).
	var blink: float = 0.0 if fmod(_t, 4.7) > 0.12 else 1.0
	var sway: float = sin(_t * 0.9) * 2.0
	if _page == Page.TITLE or _page == Page.PLAY:
		Figures.draw_figure(self, "botones", Vector2(170 + sway, 705), 1.55, 0.42 + blink * 0.4)
		Figures.draw_figure(self, "chef", Vector2(330 - sway, 705), 1.5, 0.42 + blink * 0.4)
		Figures.draw_figure(self, "mucama", Vector2(950 + sway, 705), 1.55, 0.42 + blink * 0.4)
		Figures.draw_figure(self, "cornelius", Vector2(1110 - sway, 705), 1.5, 0.42 + blink * 0.4)
	if _page == Page.TITLE:
		UIUtil.draw_logo(self, Vector2(640, 130), _t)
	# Letrero de neon "GRAND TENEBRIS" que parpadea
	if _page != Page.TITLE:
		var f: Font = UIUtil.title_font()
		var neon: float = 1.0 if fmod(_t, 7.3) > 0.2 else 0.4
		draw_string(f, Vector2(0, 76), "GRAND TENEBRIS", HORIZONTAL_ALIGNMENT_CENTER, 1280.0, 34, Color(UIUtil.GOLD.r, UIUtil.GOLD.g, UIUtil.GOLD.b, neon))
		UIUtil.draw_divider(self, Vector2(640, 92), 380.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SoundBank.stop_all_loops()
	_build_title()
	_build_play()
	_build_controls()
	_build_settings()
	_show(Page.TITLE)
	# La musica del menu se sintetiza un instante despues de mostrar la portada.
	get_tree().create_timer(0.15).timeout.connect(_start_theme)


func _start_theme() -> void:
	if _theme_started:
		return
	_theme_started = true
	SoundBank.start_loop("menu_theme", -12.0)


func _show(p: int) -> void:
	_page = p
	for k in _pages.keys():
		_pages[k].visible = (k == p)
	if _confirm != null:
		_confirm.visible = false


func _new_page(p: int) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	_pages[p] = c
	return c


func _column(parent: Control, x: float, y: float, w: float, sep: int = 14) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.position = Vector2(x, y)
	v.size = Vector2(w, 10)
	v.add_theme_constant_override("separation", sep)
	parent.add_child(v)
	return v


func _btn(parent: Control, text: String, size: int, w: float, h: float, cb: Callable) -> Button:
	var b := UIUtil.menu_button(text, size)
	b.custom_minimum_size = Vector2(w, h)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# ============================================================== PORTADA

func _build_title() -> void:
	var page: Control = _new_page(Page.TITLE)
	var col: VBoxContainer = _column(page, 490, 330, 300, 14)
	_btn(col, "JUGAR", 24, 300, 56, func(): _show(Page.PLAY))
	_btn(col, "CONFIGURACIÓN", 22, 300, 52, func(): _show(Page.SETTINGS))
	_btn(col, "CONTROLES", 22, 300, 52, func(): _show(Page.CONTROLS))
	_btn(col, "SALIR", 22, 300, 52, func(): get_tree().quit())
	var credit := UIUtil.label("Universidad de Colima · Facultad de Telemática\nIngeniería de Software — Videojuegos · GDD v1", 13, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	credit.position = Vector2(340, 648)
	credit.size = Vector2(600, 40)
	page.add_child(credit)


# ============================================================== JUGAR

func _build_play() -> void:
	var page: Control = _new_page(Page.PLAY)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.deco_panel())
	panel.position = Vector2(390, 120)
	panel.size = Vector2(500, 10)
	page.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	col.add_child(UIUtil.title_label("JUGAR", 40, UIUtil.GOLD))
	col.add_child(UIUtil.label("Un turno de noche en el Grand Tenebris", 15, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_btn(col, "NUEVO JUEGO", 22, 440, 54, _on_new_game)
	var cont: Button = _btn(col, "CONTINUAR — NOCHE %d" % GameState.unlocked_night, 20, 440, 50, func(): GameState.start_night(GameState.unlocked_night))
	cont.disabled = GameState.unlocked_night <= 1
	col.add_child(UIUtil.label("SELECCIONAR NOCHE", 14, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	for n in range(1, GameState.MAX_NIGHT + 1):
		var locked: bool = n > GameState.unlocked_night
		var text: String = "NOCHE %d  —  %s" % [n, NIGHT_INFO[n - 1]] if not locked else "NOCHE %d  —  BLOQUEADA" % n
		var b: Button = _btn(col, text, 16, 440, 38, _start.bind(n))
		b.disabled = locked
	_btn(col, "VOLVER", 18, 440, 42, func(): _show(Page.TITLE))

	# Confirmacion de "Nuevo juego" (solo si hay progreso)
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.visible = false
	page.add_child(_confirm)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	_confirm.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIUtil.deco_panel(Color(0.04, 0.03, 0.03, 0.97)))
	box.position = Vector2(380, 270)
	box.size = Vector2(520, 10)
	_confirm.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	box.add_child(v)
	v.add_child(UIUtil.title_label("¿EMPEZAR DE NUEVO?", 28, UIUtil.GOLD))
	var msg := UIUtil.label("Se borrará tu progreso y volverás a la Noche 1.", 17, Color(0.85, 0.82, 0.7), HORIZONTAL_ALIGNMENT_CENTER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msg)
	_btn(v, "SÍ, NUEVO JUEGO", 20, 440, 48, func():
		GameState.reset_progress()
		GameState.start_night(1))
	_btn(v, "CANCELAR", 18, 440, 42, func(): _confirm.visible = false)


func _on_new_game() -> void:
	if GameState.unlocked_night > 1:
		_confirm.visible = true
	else:
		GameState.start_night(1)


func _start(n: int) -> void:
	GameState.start_night(n)


# ============================================================== CONTROLES

func _build_controls() -> void:
	var page: Control = _new_page(Page.CONTROLS)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.deco_panel())
	panel.position = Vector2(250, 112)
	panel.size = Vector2(780, 10)
	page.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(UIUtil.title_label("CONTROLES", 38, UIUtil.GOLD))
	var rows: Array = [
		["A / D", "Reja izquierda / derecha (gastan energía mientras están cerradas)"],
		["ESPACIO", "Subir / bajar el monitor de cámaras"],
		["1 – 7", "Cambiar de cámara (con el monitor arriba)"],
		["F", "Flash de cámara: ilumina las cámaras oscuras 04, 05 y 06"],
		["I", "Intercomunicador: jazz durante 12 s en la cámara elegida (Chef)"],
		["B", "Sobrecargo de Caldera: repele a la Mucama"],
		["R", "Dar cuerda a la Cajita de Música (mirando la Cam 01)"],
		["ESC", "Pausa"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	for r in rows:
		var cap := PanelContainer.new()
		cap.add_theme_stylebox_override("panel", UIUtil.box(Color(0.10, 0.08, 0.03), UIUtil.GOLD, 2))
		cap.custom_minimum_size = Vector2(120, 0)
		var kl := UIUtil.label(String(r[0]), 18, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		cap.add_child(kl)
		grid.add_child(cap)
		var d := UIUtil.label(String(r[1]), 16, Color(0.86, 0.83, 0.72))
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(d)
	var tip := UIUtil.label("Toda acción cuesta energía del mismo generador. Si llegas a 0% se va la luz y los monstruos entran.\nSi pasas demasiado tiempo sin mirar las cámaras, los monstruos se vuelven más audaces.\nCada monstruo exige una contramedida distinta.", 14, UIUtil.GOLD_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(700, 0)
	col.add_child(tip)
	_btn(col, "VOLVER", 20, 300, 46, func(): _show(Page.TITLE))


# ============================================================== CONFIGURACION

func _build_settings() -> void:
	var page: Control = _new_page(Page.SETTINGS)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.deco_panel())
	panel.position = Vector2(340, 170)
	panel.size = Vector2(600, 10)
	page.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)
	col.add_child(UIUtil.title_label("CONFIGURACIÓN", 38, UIUtil.GOLD))

	var vol_label := UIUtil.label("VOLUMEN GENERAL:  %d%%" % int(round(GameState.master_volume * 100.0)), 18)
	col.add_child(vol_label)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 100.0
	sl.step = 5.0
	sl.value = GameState.master_volume * 100.0
	sl.custom_minimum_size = Vector2(500, 30)
	sl.focus_mode = Control.FOCUS_NONE
	UIUtil.style_slider(sl)
	sl.value_changed.connect(func(v: float):
		GameState.master_volume = v / 100.0
		vol_label.text = "VOLUMEN GENERAL:  %d%%" % int(v)
		GameState.apply_settings())
	sl.drag_ended.connect(func(_changed: bool): SoundBank.play("chime", -6.0))
	col.add_child(sl)

	var fs: Button = _toggle(col, "PANTALLA COMPLETA", GameState.fullscreen, func(on: bool): GameState.fullscreen = on)
	var crt: Button = _toggle(col, "EFECTO DE MONITOR VIEJO (CRT)", GameState.crt_enabled, func(on: bool): GameState.crt_enabled = on)
	var note := UIUtil.label("El efecto CRT añade ruido y curvatura a la imagen. Si te cansa la vista, desactívalo.", 13, UIUtil.GOLD_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(500, 0)
	col.add_child(note)
	_btn(col, "GUARDAR Y VOLVER", 20, 500, 50, func():
		GameState.apply_settings()
		GameState.save_progress()
		_show(Page.TITLE))
	fs.focus_mode = Control.FOCUS_NONE
	crt.focus_mode = Control.FOCUS_NONE


## Boton on/off con texto "SÍ"/"NO".
func _toggle(parent: Control, text: String, initial: bool, on_change: Callable) -> Button:
	var b := UIUtil.button("", 18, true)
	b.custom_minimum_size = Vector2(500, 46)
	b.set_pressed_no_signal(initial)
	b.text = "%s:  %s" % [text, "SÍ" if initial else "NO"]
	b.mouse_entered.connect(func(): SoundBank.play("hover", -6.0))
	b.toggled.connect(func(on: bool):
		SoundBank.play("click", -2.0)
		b.text = "%s:  %s" % [text, "SÍ" if on else "NO"]
		on_change.call(on))
	parent.add_child(b)
	return b
