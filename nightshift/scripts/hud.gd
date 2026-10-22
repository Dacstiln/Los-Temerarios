extends Control
## HUD: energia y hora SIEMPRE visibles en las esquinas superiores (Trade-off elegido,
## GDD Pagina 10), rejas, monitor, acciones y selector de camaras.
## Las zonas de clic estan separadas a proposito (GDD Riesgo #2: error de input).

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
var monitor_btn: Button
var cam_btns: Dictionary = {}
var cam_title: Label
var flash_btn: Button
var intercom_btn: Button
var boiler_btn: Button
var wind_btn: Button
var box_label: Label
var box_bg: ColorRect
var box_fill: ColorRect
var _box_on: bool = false
var notice: Label
var debug_label: Label
var _notice_tween: Tween
var _has_intercom: bool = false
var _has_boiler: bool = false


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


func _panel(rect: Rect2) -> void:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UIUtil.box(Color(0.02, 0.02, 0.025, 0.62), Color(UIUtil.GOLD_DIM.r, UIUtil.GOLD_DIM.g, UIUtil.GOLD_DIM.b, 0.8), 2))
	p.position = rect.position
	p.size = rect.size
	add_child(_ignore(p))


func _build_top() -> void:
	_panel(Rect2(12, 6, 284, 110))
	_panel(Rect2(1280 - 24 - 300 + 4, 6, 292, 82))
	energy_label = UIUtil.label("ENERGÍA  100%", 26)
	energy_label.position = Vector2(24, 12)
	energy_label.size = Vector2(300, 34)
	add_child(energy_label)
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.13, 0.05)
	bg.position = Vector2(24, 50)
	bg.size = Vector2(260, 12)
	add_child(_ignore(bg))
	energy_fill = ColorRect.new()
	energy_fill.color = UIUtil.GOLD
	energy_fill.position = Vector2(24, 50)
	energy_fill.size = Vector2(260, 12)
	add_child(_ignore(energy_fill))
	var uh := UIUtil.label("CONSUMO", 14, UIUtil.GOLD_DIM)
	uh.position = Vector2(24, 68)
	uh.size = Vector2(80, 20)
	add_child(uh)
	for i in 5:
		var seg := ColorRect.new()
		seg.position = Vector2(104 + i * 24, 72)
		seg.size = Vector2(20, 12)
		seg.color = UIUtil.GOLD_DIM
		add_child(_ignore(seg))
		usage_segs.append(seg)
	box_label = UIUtil.label("CAJITA", 14, UIUtil.GOLD_DIM)
	box_label.position = Vector2(24, 92)
	box_label.size = Vector2(80, 20)
	box_label.visible = false
	add_child(box_label)
	box_bg = ColorRect.new()
	box_bg.color = Color(0.15, 0.13, 0.05)
	box_bg.position = Vector2(104, 97)
	box_bg.size = Vector2(180, 8)
	box_bg.visible = false
	add_child(_ignore(box_bg))
	box_fill = ColorRect.new()
	box_fill.color = UIUtil.GOLD
	box_fill.position = Vector2(104, 97)
	box_fill.size = Vector2(180, 8)
	box_fill.visible = false
	add_child(_ignore(box_fill))
	night_label = UIUtil.label("NOCHE 1", 20, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	night_label.position = Vector2(1280 - 24 - 300, 12)
	night_label.size = Vector2(300, 28)
	add_child(night_label)
	clock_label = UIUtil.label("12:00 AM", 32, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	clock_label.position = Vector2(1280 - 24 - 300, 38)
	clock_label.size = Vector2(300, 42)
	add_child(clock_label)


func _build_bottom() -> void:
	var gl := UIUtil.button("REJA IZQ  [A]", 18, true)
	gl.position = Vector2(24, 652)
	gl.size = Vector2(220, 52)
	gl.pressed.connect(func(): gate_pressed.emit("left"))
	add_child(gl)
	gate_btn["left"] = gl
	var gr := UIUtil.button("REJA DER  [D]", 18, true)
	gr.position = Vector2(1280 - 24 - 220, 652)
	gr.size = Vector2(220, 52)
	gr.pressed.connect(func(): gate_pressed.emit("right"))
	add_child(gr)
	gate_btn["right"] = gr
	monitor_btn = UIUtil.button("MONITOR  [ESPACIO]", 18, true)
	monitor_btn.position = Vector2(530, 652)
	monitor_btn.size = Vector2(220, 52)
	monitor_btn.pressed.connect(func(): monitor_pressed.emit())
	add_child(monitor_btn)


func _build_actions() -> void:
	flash_btn = UIUtil.button("FLASH  [F]", 17)
	flash_btn.position = Vector2(24, 440)
	flash_btn.size = Vector2(220, 44)
	flash_btn.pressed.connect(func(): flash_pressed.emit())
	add_child(flash_btn)
	intercom_btn = UIUtil.button("INTERCOM  [I]", 17)
	intercom_btn.position = Vector2(24, 492)
	intercom_btn.size = Vector2(220, 44)
	intercom_btn.pressed.connect(func(): intercom_pressed.emit())
	add_child(intercom_btn)
	boiler_btn = UIUtil.button("CALDERA  [B]", 17)
	boiler_btn.position = Vector2(24, 544)
	boiler_btn.size = Vector2(220, 44)
	boiler_btn.pressed.connect(func(): boiler_pressed.emit())
	add_child(boiler_btn)
	wind_btn = UIUtil.button("CUERDA  [R]", 17)
	wind_btn.position = Vector2(24, 388)
	wind_btn.size = Vector2(220, 44)
	wind_btn.visible = false
	wind_btn.pressed.connect(func(): wind_pressed.emit())
	add_child(wind_btn)


func _build_cam_panel() -> void:
	cam_title = UIUtil.label("CÁMARAS  [1-7]", 16, UIUtil.GOLD_DIM)
	cam_title.position = Vector2(1030, 236)
	cam_title.size = Vector2(226, 22)
	add_child(cam_title)
	for k in range(1, 8):
		var b := UIUtil.button("%02d  %s" % [k, Map.CAMS[k]["short"]], 15, true)
		b.position = Vector2(1030, 262 + (k - 1) * 42)
		b.size = Vector2(226, 36)
		b.pressed.connect(_on_cam_pressed.bind(k))
		add_child(b)
		cam_btns[k] = b


func _on_cam_pressed(k: int) -> void:
	cam_selected.emit(k)


# ---------------------------------------------------------------------- API

func set_energy(v: float) -> void:
	energy_label.text = "ENERGÍA  %d%%" % int(ceil(v))
	energy_fill.size.x = 260.0 * clampf(v / 100.0, 0.0, 1.0)
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


## Medidor de la cajita (siempre visible) y boton CUERDA (solo mirando la Cam 01).
func set_box(enabled: bool, charge: float, show_button: bool) -> void:
	if not enabled:
		return
	box_fill.size.x = 180.0 * clampf(charge, 0.0, 1.0)
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
	for k in cam_btns.keys():
		cam_btns[k].visible = up
	cam_title.visible = up
	flash_btn.disabled = not up
	intercom_btn.disabled = not up


func set_gate(side: String, closed: bool) -> void:
	gate_btn[side].set_pressed_no_signal(closed)


func set_cam(id: int) -> void:
	for k in cam_btns.keys():
		cam_btns[k].set_pressed_no_signal(k == id)


func set_boiler_cd(cd: float) -> void:
	boiler_btn.text = "CALDERA  [B]" if cd <= 0.0 else "CALDERA  (%.0f)" % ceil(cd)
	boiler_btn.disabled = cd > 0.0


func set_intercom_active(cam: int) -> void:
	intercom_btn.text = "INTERCOM  [I]" if cam <= 0 else "JAZZ > CAM %02d" % cam


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
