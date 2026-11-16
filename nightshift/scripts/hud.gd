extends Control
## HUD: energia, hora, acciones difuminadas y mapa esquemático de cámaras.
## Todos los elementos integrados dentro del encuadre de la pantalla (FEED).
## Los textos guía inferiores y laterales son difuminados, sin recuadros y no interactivos.

signal gate_pressed(side: String)
signal monitor_pressed
signal cam_selected(id: int)
signal flash_pressed
signal intercom_pressed
signal boiler_pressed
signal wind_pressed

const UIUtil = preload("res://scripts/ui_util.gd")
const Map = preload("res://scripts/map.gd")

var energy_label: Label
var energy_fill: ColorRect
var clock_label: Label
var night_label: Label
var usage_segs: Array = []
var gate_btn: Dictionary = {}
var monitor_btn: TextGuide

# Acciones difuminadas no interactivas (solo texto guía sin recuadro)
var flash_btn: ActionGuide
var intercom_btn: ActionGuide
var boiler_btn: ActionGuide
var wind_btn: ActionGuide

# Plano esquemático de cámaras interactivo y traslúcido
var map_panel: MapBlueprint
var cam_btns: Dictionary:
	get:
		return map_panel.cam_btns if map_panel != null else {}
var cam_title: Label:
	get:
		return map_panel.title_label if map_panel != null else null

var box_label: Label
var box_bg: ColorRect
var box_fill: ColorRect
var _box_on: bool = false
var notice: Label
var debug_label: Label
var _notice_tween: Tween
var _has_intercom: bool = false
var _has_boiler: bool = false


# ================================================================ SUBCLASES UI

## Texto guía inferior puramente informativo, difuminado y sin recuadro.
## Al presionarlo con el ratón no funciona (mouse_filter = IGNORE).
class TextGuide extends Control:
	var label: Label
	var is_active: bool = false
	var is_disabled: bool = false
	var base_title: String = ""

	var text: String = "":
		get:
			return label.text if label != null else ""
		set(value):
			if label != null:
				label.text = value
				_update_style()

	var disabled: bool = false:
		get:
			return is_disabled
		set(value):
			is_disabled = value
			_update_style()

	var button_pressed: bool = false:
		get:
			return is_active
		set(value):
			is_active = value
			_update_style()

	func set_pressed_no_signal(v: bool) -> void:
		is_active = v
		_update_style()

	func _init(title_text: String) -> void:
		base_title = title_text
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(230, 30)

		label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = base_title
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(label)
		_update_style()

	func _update_style() -> void:
		if label == null:
			return
		if is_disabled:
			label.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40, 0.30))
		elif is_active:
			label.add_theme_color_override("font_color", UIUtil.GOLD)
		else:
			label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65, 0.55))


## Etiqueta guía difuminada lateral sin recuadro exterior.
class ActionGuide extends Control:
	var key_label: Label
	var text_label: Label
	var default_key: String = ""
	var default_action: String = ""
	var is_disabled: bool = false

	var text: String = "":
		set(value):
			text = value
			_update_display()

	var disabled: bool = false:
		set(value):
			disabled = value
			is_disabled = value
			_update_style()

	func _init(k_str: String, act_str: String) -> void:
		default_key = k_str
		default_action = act_str
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(220, 28)

		key_label = Label.new()
		key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key_label.text = "[ %s ]" % k_str
		key_label.add_theme_font_size_override("font_size", 13)
		key_label.add_theme_color_override("font_color", Color(UIUtil.GOLD.r, UIUtil.GOLD.g, UIUtil.GOLD.b, 0.80))
		key_label.position = Vector2(0, 4)
		key_label.size = Vector2(44, 20)
		add_child(key_label)

		text_label = Label.new()
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.text = act_str
		text_label.add_theme_font_size_override("font_size", 13)
		text_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.80, 0.60))
		text_label.position = Vector2(48, 4)
		text_label.size = Vector2(172, 20)
		add_child(text_label)

	func _update_display() -> void:
		if text_label == null:
			return
		if "JAZZ >" in text:
			text_label.text = text
			text_label.add_theme_color_override("font_color", UIUtil.GREEN)
		elif "(" in text and ")" in text:
			text_label.text = text
			text_label.add_theme_color_override("font_color", Color(0.85, 0.35, 0.25, 0.70))
		else:
			var clean: String = text.replace("[F]", "").replace("[I]", "").replace("[B]", "").replace("[R]", "").strip_edges()
			if clean.is_empty():
				clean = default_action
			text_label.text = clean
			_update_style()

	func _update_style() -> void:
		if is_disabled:
			modulate = Color(0.5, 0.5, 0.5, 0.25)
		else:
			modulate = Color(1.0, 1.0, 1.0, 0.90)
			if "(" not in text and "JAZZ >" not in text:
				text_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.80, 0.60))


## Plano esquemático traslúcido y sin marco envolvente.
## Calderas (CAM 06) está conectada directamente de frente con la Oficina [YOU].
class MapBlueprint extends Control:
	signal cam_clicked(id: int)

	var active_cam: int = 1
	var blink_timer: float = 0.0
	var title_label: Label
	var cam_name_label: Label
	var hint_label: Label
	var cam_btns: Dictionary = {}

	# Posiciones de las salas en el minimapa (360 x 425)
	const ROOMS: Dictionary = {
		1: {"rect": Rect2(135, 46, 90, 36), "short": "01 LOBBY"},
		2: {"rect": Rect2(135, 118, 90, 36), "short": "02 RECEP"},
		3: {"rect": Rect2(255, 118, 88, 36), "short": "03 COCINA"},
		4: {"rect": Rect2(250, 204, 92, 36), "short": "04 P. ESTE"},
		5: {"rect": Rect2(18, 204, 92, 36), "short": "05 P. OESTE"},
		6: {"rect": Rect2(135, 218, 90, 36), "short": "06 CALDERA"},
		7: {"rect": Rect2(18, 74, 88, 36), "short": "07 DUCTOS"},
	}
	const OFFICE_RECT := Rect2(135, 338, 90, 36)

	func _init() -> void:
		size = Vector2(360, 425)

		title_label = Label.new()
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_label.text = "PLANO DE VIGILANCIA"
		title_label.add_theme_font_size_override("font_size", 12)
		title_label.add_theme_color_override("font_color", Color(0.35, 0.75, 0.85, 0.80))
		title_label.position = Vector2(10, 8)
		title_label.size = Vector2(200, 18)
		add_child(title_label)

		cam_name_label = Label.new()
		cam_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cam_name_label.text = "CAM 01 — LOBBY PRINCIPAL"
		cam_name_label.add_theme_font_size_override("font_size", 12)
		cam_name_label.add_theme_color_override("font_color", UIUtil.GOLD)
		cam_name_label.position = Vector2(10, 26)
		cam_name_label.size = Vector2(340, 18)
		add_child(cam_name_label)

		_create_buttons()

		hint_label = Label.new()
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.text = "[1-7] TECLADO  •  CLIC EN CÁMARA"
		hint_label.add_theme_font_size_override("font_size", 11)
		hint_label.add_theme_color_override("font_color", Color(0.35, 0.65, 0.75, 0.65))
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(0, 394)
		hint_label.size = Vector2(360, 18)
		add_child(hint_label)

	func _create_buttons() -> void:
		for k in ROOMS.keys():
			var r_info: Dictionary = ROOMS[k]
			var rect: Rect2 = r_info["rect"]
			var b := Button.new()
			b.text = r_info["short"]
			b.toggle_mode = true
			b.focus_mode = Control.FOCUS_NONE
			b.position = rect.position
			b.size = rect.size
			b.add_theme_font_size_override("font_size", 12)

			# Cajas traslúcidas (se ve el escenario detrás)
			var sb_norm := StyleBoxFlat.new()
			sb_norm.bg_color = Color(0.02, 0.04, 0.06, 0.35)
			sb_norm.border_color = Color(0.22, 0.50, 0.65, 0.65)
			sb_norm.set_border_width_all(1)
			sb_norm.corner_radius_top_left = 3
			sb_norm.corner_radius_top_right = 3
			sb_norm.corner_radius_bottom_left = 3
			sb_norm.corner_radius_bottom_right = 3
			b.add_theme_stylebox_override("normal", sb_norm)

			var sb_hover := sb_norm.duplicate() as StyleBoxFlat
			sb_hover.bg_color = Color(0.05, 0.10, 0.16, 0.50)
			sb_hover.border_color = Color(0.40, 0.85, 1.0, 0.85)
			b.add_theme_stylebox_override("hover", sb_hover)

			var sb_press := StyleBoxFlat.new()
			sb_press.bg_color = Color(0.68, 0.54, 0.14, 0.50)
			sb_press.border_color = Color(1.0, 0.92, 0.45, 0.95)
			sb_press.set_border_width_all(2)
			sb_press.corner_radius_top_left = 3
			sb_press.corner_radius_top_right = 3
			sb_press.corner_radius_bottom_left = 3
			sb_press.corner_radius_bottom_right = 3
			b.add_theme_stylebox_override("pressed", sb_press)
			b.add_theme_stylebox_override("hover_pressed", sb_press)

			b.add_theme_color_override("font_color", Color(0.82, 0.90, 0.94, 0.85))
			b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
			b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

			b.pressed.connect(func(): cam_clicked.emit(k))
			add_child(b)
			cam_btns[k] = b

	func _process(delta: float) -> void:
		if is_visible_in_tree():
			blink_timer += delta
			queue_redraw()

	func set_cam(id: int) -> void:
		active_cam = id
		if Map.CAMS.has(id):
			cam_name_label.text = Map.cam_name(id)
		for k in cam_btns.keys():
			cam_btns[k].set_pressed_no_signal(k == id)
		queue_redraw()

	func _draw() -> void:
		# Fondo general muy traslúcido para ver la cámara detrás
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.01, 0.015, 0.02, 0.20))

		var pipe_col := Color(0.20, 0.55, 0.70, 0.65)
		var pipe_w := 2.5

		# 1. CAM 01 (Lobby) a CAM 02 (Recepción)
		draw_line(Vector2(180, 82), Vector2(180, 118), pipe_col, pipe_w)

		# 2. CAM 02 (Recepción) a CAM 03 (Cocina)
		draw_line(Vector2(225, 136), Vector2(255, 136), pipe_col, pipe_w)

		# 3. CAM 02 hacia Pasillos Este (CAM 04) y Oeste (CAM 05)
		draw_line(Vector2(180, 154), Vector2(180, 178), pipe_col, pipe_w)
		draw_line(Vector2(64, 178), Vector2(296, 178), pipe_col, pipe_w)
		draw_line(Vector2(64, 178), Vector2(64, 204), pipe_col, pipe_w)
		draw_line(Vector2(296, 178), Vector2(296, 204), pipe_col, pipe_w)

		# 4. Conexión central desde Recepción hasta Calderas (CAM 06)
		draw_line(Vector2(180, 178), Vector2(180, 218), pipe_col, pipe_w)

		# 5. CONEXIÓN DE FRENTE: Calderas (CAM 06) conectada de frente con Oficina [YOU]
		draw_line(Vector2(180, 254), Vector2(180, 338), pipe_col, pipe_w)

		# 6. Pasillo Oeste a Reja Izquierda de la Oficina [YOU]
		draw_line(Vector2(64, 240), Vector2(64, 356), pipe_col, pipe_w)
		draw_line(Vector2(64, 356), Vector2(135, 356), pipe_col, pipe_w)

		# 7. Pasillo Este a Reja Derecha de la Oficina [YOU]
		draw_line(Vector2(296, 240), Vector2(296, 356), pipe_col, pipe_w)
		draw_line(Vector2(296, 356), Vector2(225, 356), pipe_col, pipe_w)

		# 8. CAM 07 (Conductos de ventilación) - Línea punteada de ducto
		var vent_col := Color(0.25, 0.70, 0.45, 0.50)
		for vy in range(110, 175, 8):
			draw_line(Vector2(62, vy), Vector2(62, vy + 4), vent_col, 2.0)

		# Oficina [YOU] (traslúcida)
		draw_rect(OFFICE_RECT, Color(0.04, 0.08, 0.05, 0.35))
		draw_rect(OFFICE_RECT, Color(0.25, 0.75, 0.45, 0.75), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(164, 360), "YOU", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.35, 0.95, 0.55, 0.90))

		# Indicador parpadeante verde en YOU
		var blink: float = 0.45 + 0.55 * sin(blink_timer * 6.0)
		draw_circle(Vector2(150, 356), 3.5, Color(0.3, 0.95, 0.5, blink))

		# Indicador parpadeante REC en la cámara seleccionada
		if ROOMS.has(active_cam):
			var a_rect: Rect2 = ROOMS[active_cam]["rect"]
			var rec_blink: float = 0.40 + 0.60 * sin(blink_timer * 8.0)
			draw_circle(Vector2(a_rect.position.x + 10, a_rect.position.y + 10), 3.0, Color(1.0, 0.25, 0.2, rec_blink))


# ================================================================ CONSTRUCCIÓN HUD

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top()
	_build_bottom()
	_build_actions()
	_build_cam_panel()
	notice = UIUtil.label("", 24, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	notice.position = Vector2(240, 100)
	notice.size = Vector2(800, 40)
	add_child(notice)
	debug_label = UIUtil.label("", 14, UIUtil.GREEN)
	debug_label.position = Vector2(330, 8)
	debug_label.size = Vector2(620, 100)
	debug_label.visible = false
	add_child(debug_label)
	set_monitor(false)


func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _build_top() -> void:
	# Integrado dentro de FEED (Rect2(30, 30, 1220, 660)), sin recuadros exteriores
	energy_label = UIUtil.label("ENERGÍA  100%", 24)
	energy_label.position = Vector2(50, 42)
	energy_label.size = Vector2(260, 30)
	add_child(energy_label)

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.13, 0.05, 0.70)
	bg.position = Vector2(50, 74)
	bg.size = Vector2(240, 10)
	add_child(_ignore(bg))

	energy_fill = ColorRect.new()
	energy_fill.color = UIUtil.GOLD
	energy_fill.position = Vector2(50, 74)
	energy_fill.size = Vector2(240, 10)
	add_child(_ignore(energy_fill))

	var uh := UIUtil.label("CONSUMO", 13, UIUtil.GOLD_DIM)
	uh.position = Vector2(50, 90)
	uh.size = Vector2(70, 18)
	add_child(uh)

	for i in 5:
		var seg := ColorRect.new()
		seg.position = Vector2(124 + i * 22, 93)
		seg.size = Vector2(18, 10)
		seg.color = UIUtil.GOLD_DIM
		add_child(_ignore(seg))
		usage_segs.append(seg)

	box_label = UIUtil.label("CAJITA", 13, UIUtil.GOLD_DIM)
	box_label.position = Vector2(50, 112)
	box_label.size = Vector2(70, 18)
	box_label.visible = false
	add_child(box_label)

	box_bg = ColorRect.new()
	box_bg.color = Color(0.15, 0.13, 0.05, 0.70)
	box_bg.position = Vector2(124, 116)
	box_bg.size = Vector2(160, 8)
	box_bg.visible = false
	add_child(_ignore(box_bg))

	box_fill = ColorRect.new()
	box_fill.color = UIUtil.GOLD
	box_fill.position = Vector2(124, 116)
	box_fill.size = Vector2(160, 8)
	box_fill.visible = false
	add_child(_ignore(box_fill))

	# Noche y reloj sin recuadro exterior, alineados dentro de FEED
	night_label = UIUtil.label("NOCHE 1", 18, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	night_label.position = Vector2(1230 - 240, 42)
	night_label.size = Vector2(240, 24)
	add_child(night_label)

	clock_label = UIUtil.label("12:00 AM", 30, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	clock_label.position = Vector2(1230 - 240, 68)
	clock_label.size = Vector2(240, 36)
	add_child(clock_label)


func _build_bottom() -> void:
	# Textos guía inferiores difuminados y sin recuadro (dentro de FEED, y = 652..682)
	var gl := TextGuide.new("REJA IZQ  [A]")
	gl.position = Vector2(50, 652)
	add_child(gl)
	gate_btn["left"] = gl

	monitor_btn = TextGuide.new("MONITOR  [ESPACIO]")
	monitor_btn.position = Vector2(525, 652)
	add_child(monitor_btn)

	var gr := TextGuide.new("REJA DER  [D]")
	gr.position = Vector2(1230 - 230, 652)
	add_child(gr)
	gate_btn["right"] = gr


func _build_actions() -> void:
	# Acciones laterales difuminadas dentro de FEED (x = 50)
	wind_btn = ActionGuide.new("R", "CUERDA CAJITA")
	wind_btn.position = Vector2(50, 440)
	wind_btn.visible = false
	add_child(wind_btn)

	flash_btn = ActionGuide.new("F", "FLASH CÁMARA")
	flash_btn.position = Vector2(50, 480)
	add_child(flash_btn)

	intercom_btn = ActionGuide.new("I", "INTERCOM JAZZ")
	intercom_btn.position = Vector2(50, 520)
	add_child(intercom_btn)

	boiler_btn = ActionGuide.new("B", "CALDERA")
	boiler_btn.position = Vector2(50, 560)
	add_child(boiler_btn)


func _build_cam_panel() -> void:
	# Plano esquemático traslúcido dentro de FEED (x = 870..1230, y = 200..625)
	map_panel = MapBlueprint.new()
	map_panel.position = Vector2(870, 200)
	map_panel.cam_clicked.connect(_on_cam_pressed)
	add_child(map_panel)


func _on_cam_pressed(k: int) -> void:
	cam_selected.emit(k)


# ================================================================ API PÚBLICA

func set_energy(v: float) -> void:
	energy_label.text = "ENERGÍA  %d%%" % int(ceil(v))
	energy_fill.size.x = 240.0 * clampf(v / 100.0, 0.0, 1.0)
	var col: Color = UIUtil.GOLD if v > 25.0 else UIUtil.RED
	energy_fill.color = col
	energy_label.add_theme_color_override("font_color", col)


func set_usage(level: int) -> void:
	for i in usage_segs.size():
		var seg: ColorRect = usage_segs[i]
		seg.color = UIUtil.GOLD if i < level else Color(0.2, 0.17, 0.06)


func set_time_text(text: String) -> void:
	clock_label.text = text


func set_night_text(text: String) -> void:
	night_label.text = text


func set_features(intercom: bool, boiler: bool, box: bool = false) -> void:
	_box_on = box
	box_label.visible = box
	box_bg.visible = box
	box_fill.visible = box
	_has_intercom = intercom
	_has_boiler = boiler
	intercom_btn.visible = intercom
	boiler_btn.visible = boiler


## Medidor de la cajita (siempre visible) y aviso CUERDA (solo mirando la Cam 01).
func set_box(enabled: bool, charge: float, show_button: bool) -> void:
	if not enabled:
		return
	box_fill.size.x = 160.0 * clampf(charge, 0.0, 1.0)
	var low: bool = charge < 0.25
	var blink: bool = int(Time.get_ticks_msec() / 250.0) % 2 == 0
	var col: Color = UIUtil.GOLD
	if low:
		col = UIUtil.RED if blink else Color(0.45, 0.1, 0.08)
	box_fill.color = col
	box_label.add_theme_color_override("font_color", UIUtil.RED if low else UIUtil.GOLD_DIM)
	wind_btn.visible = show_button
	wind_btn.disabled = false


func set_monitor(up: bool) -> void:
	monitor_btn.set_pressed_no_signal(up)
	map_panel.visible = up
	flash_btn.disabled = not up
	intercom_btn.disabled = not up


func set_gate(side: String, closed: bool) -> void:
	gate_btn[side].set_pressed_no_signal(closed)


func set_cam(id: int) -> void:
	map_panel.set_cam(id)


func set_boiler_cd(cd: float) -> void:
	boiler_btn.text = "CALDERA" if cd <= 0.0 else "CALDERA  (%.0f)" % ceil(cd)
	boiler_btn.disabled = cd > 0.0


func set_intercom_active(cam: int) -> void:
	intercom_btn.text = "INTERCOM" if cam <= 0 else "JAZZ > CAM %02d" % cam


func set_blackout(on: bool) -> void:
	for side in gate_btn.keys():
		gate_btn[side].disabled = on
	monitor_btn.disabled = on
	flash_btn.disabled = on or not monitor_btn.button_pressed
	intercom_btn.disabled = on or not monitor_btn.button_pressed
	boiler_btn.disabled = on


func notify(text: String, color: Color = UIUtil.GOLD) -> void:
	notice.text = text
	notice.add_theme_color_override("font_color", color)
	notice.modulate.a = 1.0
	if _notice_tween != null:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(1.8)
	_notice_tween.tween_property(notice, "modulate:a", 0.0, 0.6)
