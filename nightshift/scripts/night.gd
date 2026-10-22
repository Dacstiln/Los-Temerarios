extends Control
## Controlador de una noche: reloj 12 AM -> 6 AM, energia, rejas, monitor, acciones,
## monstruos y condiciones de victoria / derrota (GDD Paginas 4, 5, 6 y 8).

const Balance = preload("res://scripts/balance.gd")
const Map = preload("res://scripts/map.gd")
const UIUtil = preload("res://scripts/ui_util.gd")
const CamState = preload("res://scripts/cam_state.gd")
const EnergySystem = preload("res://scripts/energy_system.gd")
const OfficeView = preload("res://scripts/office_view.gd")
const CameraView = preload("res://scripts/camera_view.gd")
const Hud = preload("res://scripts/hud.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")
const JumpscareView = preload("res://scripts/jumpscare_view.gd")
const Botones = preload("res://scripts/monsters/botones.gd")
const Chef = preload("res://scripts/monsters/chef.gd")
const Mucama = preload("res://scripts/monsters/mucama.gd")
const Cornelius = preload("res://scripts/monsters/cornelius.gd")
const Bailarina = preload("res://scripts/monsters/bailarina.gd")
const CRT_SHADER = preload("res://shaders/crt.gdshader")

# --- estado de la noche (leido por vistas y monstruos) ---
var night: int = 1
var cfg: Dictionary = {}
var elapsed: float = 0.0
var started: bool = false
var is_over: bool = false
var blackout: bool = false
var monitor_up: bool = false
var current_cam: int = 1
var gate_closed: Dictionary = {"left": false, "right": false}
var gate_anim: Dictionary = {"left": 0.0, "right": 0.0}
var intercom_cam: int = -1
var intercom_timer: float = 0.0
var boiler_cd: float = 0.0
var boiler_glow: float = 0.0
var flash_time: float = 0.0
var flash_cd: float = 0.0
var flash_recent: float = 0.0
var monitor_lock: float = 0.0   # monitor reiniciandose tras un corto circuito
var gate_jam: float = 0.0       # rejas atoradas abiertas (Interferencia de Cornelius)
var _crt_alert: bool = false
var box_enabled: bool = false      # Cajita de Musica (Noches 2-5)
var box_charge: float = 1.0        # 1.0 = cuerda llena, 0.0 = parada
var box_seconds: float = 45.0      # duracion de una cuerda completa
var unwatched_t: float = 0.0       # segundos seguidos con el monitor abajo
var _negligent: bool = false
var _low_energy_warned: bool = false
var _last_hour: int = 0
var monsters: Array = []
var cams: Dictionary = {}
var energy: Node = null

var office_view: Control
var camera_view: Control
var hud: Control
var pause_menu: Control
var crt_rect: ColorRect
var intro_overlay: Control = null
var intro_tween: Tween
var debug_on: bool = false


func _ready() -> void:
	night = GameState.current_night
	cfg = GameState.night_config(night)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = false
	SoundBank.stop_all_loops()
	SoundBank.warmup()
	for id in Map.CAMS.keys():
		cams[id] = CamState.new(id)
	_build_views()
	_build_energy()
	_build_monsters()
	_build_hud()
	_show_intro()


# ================================================================ construccion

func _build_views() -> void:
	office_view = OfficeView.new()
	office_view.night = self
	add_child(office_view)
	office_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camera_view = CameraView.new()
	camera_view.night = self
	camera_view.visible = false
	add_child(camera_view)
	camera_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var crt_layer := CanvasLayer.new()
	crt_layer.layer = 5
	add_child(crt_layer)
	crt_rect = ColorRect.new()
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = CRT_SHADER
	crt_rect.material = mat
	crt_layer.add_child(crt_rect)
	crt_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_rect.visible = GameState.crt_enabled


func _build_energy() -> void:
	energy = EnergySystem.new()
	energy.multiplier = float(cfg["drain"])
	energy.gate_closed = gate_closed
	energy.depleted.connect(_on_depleted)
	add_child(energy)


func _build_monsters() -> void:
	var b = Botones.new()
	b.setup(self, cfg["botones"])
	_register_monster(b)
	if cfg.has("chef"):
		var c = Chef.new()
		c.setup(self, cfg["chef"])
		_register_monster(c)
	if cfg.has("mucama"):
		var m = Mucama.new()
		m.setup(self, cfg["mucama"])
		_register_monster(m)
	if cfg.has("cornelius"):
		var k = Cornelius.new()
		k.setup(self, cfg["cornelius"])
		_register_monster(k)
	if cfg.has("box"):
		box_enabled = true
		box_seconds = float(cfg["box"].get("charge", 45.0))
		var bl = Bailarina.new()
		bl.setup(self, cfg["box"])
		_register_monster(bl)


func _register_monster(m) -> void:
	add_child(m)
	m.jumpscare.connect(_on_jumpscare)
	monsters.append(m)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.gate_pressed.connect(toggle_gate)
	hud.monitor_pressed.connect(toggle_monitor)
	hud.cam_selected.connect(select_cam)
	hud.flash_pressed.connect(do_flash)
	hud.intercom_pressed.connect(do_intercom)
	hud.boiler_pressed.connect(do_boiler)
	hud.wind_pressed.connect(do_wind)
	hud.set_night_text(String(cfg["title"]))
	hud.set_features(bool(cfg.get("intercom", false)), bool(cfg.get("boiler", false)), box_enabled)
	hud.set_cam(current_cam)

	var pl := CanvasLayer.new()
	pl.layer = 50
	add_child(pl)
	pause_menu = PauseMenu.new()
	pl.add_child(pause_menu)


func _show_intro() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	intro_overlay = Control.new()
	layer.add_child(intro_overlay)
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	intro_overlay.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := UIUtil.title_label(String(cfg["title"]), 72, UIUtil.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, 190)
	title.size = Vector2(1280, 90)
	intro_overlay.add_child(title)
	var clock := UIUtil.label("12:00 AM", 40, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	clock.position = Vector2(0, 285)
	clock.size = Vector2(1280, 54)
	intro_overlay.add_child(clock)
	var sub := UIUtil.label(String(cfg["subtitle"]), 24, Color(0.8, 0.8, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, 360)
	sub.size = Vector2(1280, 34)
	intro_overlay.add_child(sub)
	var hint := UIUtil.label(String(cfg["hint"]), 18, Color(0.6, 0.6, 0.58), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(140, 430)
	hint.size = Vector2(1000, 80)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_overlay.add_child(hint)
	for ly in [172.0, 520.0]:
		var line := ColorRect.new()
		line.color = Color(UIUtil.GOLD.r, UIUtil.GOLD.g, UIUtil.GOLD.b, 0.55)
		line.position = Vector2(340, ly)
		line.size = Vector2(600, 2)
		intro_overlay.add_child(line)
	var skip := UIUtil.label("(cualquier tecla para empezar)", 14, UIUtil.GOLD_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	skip.position = Vector2(0, 650)
	skip.size = Vector2(1280, 22)
	intro_overlay.add_child(skip)

	intro_tween = create_tween()
	intro_tween.tween_interval(4.5)
	intro_tween.tween_callback(_begin)


func _begin() -> void:
	if started:
		return
	started = true
	if intro_tween != null:
		intro_tween.kill()
	if intro_overlay != null:
		var layer: Node = intro_overlay.get_parent()
		var tw := create_tween()
		tw.tween_property(intro_overlay, "modulate:a", 0.0, 0.7)
		tw.tween_callback(layer.queue_free)
		intro_overlay = null
	energy.drain_enabled = true
	for m in monsters:
		m.active = true
	SoundBank.start_loop("hum", -14.0)
	SoundBank.start_loop("ambience", -22.0)
	if box_enabled:
		SoundBank.start_loop("musicbox", -9.0)
	SoundBank.play("chime", -8.0)
	hud.notify("Sobrevive hasta las 6:00 AM")


# ================================================================== API publica
# (usada por monstruos y vistas)

func is_gate_closed(side: String) -> bool:
	return bool(gate_closed.get(side, false)) and not blackout


## True si el jugador esta viendo la camara `cam` y se ve algo (no oscura sin flash, no interferida).
func can_see(cam: int) -> bool:
	if not monitor_up or current_cam != cam or cam < 1:
		return false
	if cams[cam].is_blind():
		return false
	return (not Map.is_dark(cam)) or flash_time > 0.0


func monster_at_gate(side: String) -> String:
	for m in monsters:
		if m.at_gate_side() == side:
			return m.key
	return ""


func vent_rattle() -> float:
	for m in monsters:
		if m.key == "mucama":
			return m.vent_rattle()
	return 0.0


func sfx(sound: String, vol_db: float = 0.0) -> void:
	SoundBank.play(sound, vol_db)


## "Incrementa el riesgo acumulado": cada camara interferida acelera a los demas monstruos.
func risk_mult() -> float:
	var blind: int = 0
	for id in cams.keys():
		if cams[id].is_blind():
			blind += 1
	var mult: float = 1.0 + Balance.RISK_PER_BLIND_CAM * blind
	if box_enabled and box_charge <= 0.0:
		mult += Balance.BOX_EMPTY_RISK       # sin musica, los monstruos se envalentonan
	if _negligent:
		mult += Balance.UNWATCHED_RISK       # sin vigilancia, tambien
	return mult


## True si llevas demasiado tiempo sin mirar las camaras (los monstruos se vuelven audaces).
func is_negligent() -> bool:
	return _negligent


## Interferencia de Cornelius: la camara queda ciega el resto de la noche y las rejas
## se abren y se atoran unos segundos.
func blind_cam(cam: int) -> void:
	if is_over:
		return
	cams[cam].estado = CamState.Estado.INTERFERIDA
	gate_jam = Balance.GATE_JAM_TIME
	gate_closed["left"] = false
	gate_closed["right"] = false
	SoundBank.play("static", -4.0)
	SoundBank.play("clang", -3.0)
	hud.notify("CAM %02d: SIN SEÑAL — ¡las rejas se atoraron!" % cam, UIUtil.RED)


## Estatica y aberracion del CRT: mas fuertes con el monitor arriba y durante el corto circuito.
func _apply_crt() -> void:
	var mat := crt_rect.material as ShaderMaterial
	var noise: float = 0.09 if monitor_up else 0.05
	var aber: float = 0.003 if monitor_up else 0.0018
	if _crt_alert:
		noise = 0.20
		aber = 0.008
	mat.set_shader_parameter("noise_strength", noise)
	mat.set_shader_parameter("aberration", aber)


func _update_crt_alert() -> void:
	var alert: bool = false
	for m in monsters:
		if m.key == "cornelius" and m.s == 3 and not is_over:
			alert = true
	if alert != _crt_alert:
		_crt_alert = alert
		_apply_crt()


# ================================================================== acciones

func toggle_gate(side: String) -> void:
	if not started or is_over or blackout:
		return
	if gate_jam > 0.0 and not gate_closed[side]:
		SoundBank.play("clang", -6.0)
		hud.notify("Las rejas están atoradas", UIUtil.RED)
		return
	gate_closed[side] = not gate_closed[side]
	SoundBank.play("gate", -4.0)


func toggle_monitor() -> void:
	if not started or is_over or blackout:
		return
	if not monitor_up and monitor_lock > 0.0:
		hud.notify("El monitor se está reiniciando...", UIUtil.RED)
		return
	monitor_up = not monitor_up
	energy.monitor_up = monitor_up
	camera_view.visible = monitor_up
	office_view.visible = not monitor_up
	SoundBank.play("ui")
	hud.set_monitor(monitor_up)
	_apply_crt()


func select_cam(id: int) -> void:
	if not monitor_up or is_over or blackout:
		hud.set_cam(current_cam)
		return
	current_cam = id
	hud.set_cam(id)
	SoundBank.play("ui", -4.0, 0.8)


func do_flash() -> void:
	if not monitor_up or not started or is_over or blackout or flash_cd > 0.0:
		return
	if not Map.is_dark(current_cam):
		hud.notify("Esta cámara no está oscura", UIUtil.GOLD_DIM)
		return
	flash_cd = Balance.FLASH_COOLDOWN
	# "Alto si se abusa": cada uso reciente encarece el siguiente.
	var mult: float = 1.0 + Balance.FLASH_ABUSE_STEP * flash_recent
	energy.spend_use(Balance.COST_FLASH * mult)
	flash_recent += 1.0
	flash_time = Balance.FLASH_DURATION
	SoundBank.play("flash")


func do_intercom() -> void:
	if not monitor_up or not started or is_over or blackout:
		return
	if not bool(cfg.get("intercom", false)):
		return
	if current_cam == 7:
		hud.notify("El altavoz no llega a los ductos", UIUtil.GOLD_DIM)
		return
	energy.spend_use(Balance.COST_INTERCOM)
	var was_playing: bool = intercom_cam > 0
	intercom_cam = current_cam
	intercom_timer = Balance.INTERCOM_DURATION
	if not was_playing:
		SoundBank.start_loop("jazz", -4.0)
	hud.notify("Jazz sonando en CAM %02d" % current_cam)


func _stop_intercom() -> void:
	intercom_cam = -1
	intercom_timer = 0.0
	SoundBank.stop_loop("jazz")


func do_boiler() -> void:
	if not started or is_over or blackout or boiler_cd > 0.0:
		return
	if not bool(cfg.get("boiler", false)):
		return
	boiler_cd = Balance.BOILER_COOLDOWN
	boiler_glow = 1.5
	energy.spend_use(Balance.COST_BOILER)
	SoundBank.play("hiss")
	var effect: bool = false
	for m in monsters:
		if m.on_boiler():
			effect = true
	if effect:
		hud.notify("Sobrecargo de Caldera: la Mucama retrocede", UIUtil.GREEN)
	else:
		hud.notify("Sobrecargo de Caldera: sin efecto", UIUtil.GOLD_DIM)


## Cajita de Musica: solo se le da cuerda mirando la Cam 01 con el monitor arriba.
func do_wind() -> void:
	if not box_enabled or not monitor_up or not started or is_over or blackout:
		return
	if current_cam != Balance.BOX_CAM:
		hud.notify("La cajita está en la Cam 01", UIUtil.GOLD_DIM)
		return
	if box_charge > 0.85:
		hud.notify("La cajita aún tiene cuerda", UIUtil.GOLD_DIM)
		return
	energy.spend_use(Balance.COST_WIND)
	var was_empty: bool = box_charge <= 0.0
	box_charge = 1.0
	SoundBank.play("wind", -2.0)
	if was_empty:
		SoundBank.start_loop("musicbox", -9.0)
	hud.notify("Cajita de Música: cuerda llena", UIUtil.GREEN)


# ============================================================ ciclo de la noche

func _process(delta: float) -> void:
	for side in gate_anim.keys():
		var target: float = 1.0 if (gate_closed[side] and not blackout) else 0.0
		gate_anim[side] = move_toward(gate_anim[side], target, delta * 3.0)
	flash_time = maxf(0.0, flash_time - delta)
	boiler_glow = maxf(0.0, boiler_glow - delta)
	gate_jam = maxf(0.0, gate_jam - delta)
	monitor_lock = maxf(0.0, monitor_lock - delta)
	_update_crt_alert()
	_update_hud()
	if not started or is_over:
		return

	elapsed += delta
	_update_box(delta)
	_update_unwatched(delta)
	_update_audio_cues()
	flash_cd = maxf(0.0, flash_cd - delta)
	boiler_cd = maxf(0.0, boiler_cd - delta)
	flash_recent = maxf(0.0, flash_recent - delta / Balance.FLASH_ABUSE_DECAY)
	if intercom_cam > 0:
		intercom_timer -= delta
		if intercom_timer <= 0.0:
			_stop_intercom()
	if elapsed >= Balance.NIGHT_DURATION:
		_win()


## La cuerda se gasta sola; la musica se vuelve lenta y grave cuando esta por acabarse.
func _update_box(delta: float) -> void:
	if not box_enabled or blackout:
		return
	var before: float = box_charge
	box_charge = maxf(0.0, box_charge - delta / box_seconds)
	if box_charge <= 0.0:
		if before > 0.0:
			SoundBank.stop_loop("musicbox")
			SoundBank.play("box_stop", -3.0)
			hud.notify("¡La cajita de música se detuvo!", UIUtil.RED)
	else:
		var slow: float = clampf(box_charge / 0.25, 0.0, 1.0)
		SoundBank.set_loop("musicbox", -9.0, lerpf(0.55, 1.0, slow))


func _update_unwatched(delta: float) -> void:
	if monitor_up:
		unwatched_t = 0.0
		_negligent = false
		return
	unwatched_t += delta
	if not _negligent and unwatched_t >= Balance.UNWATCHED_THRESHOLD:
		_negligent = true
		SoundBank.play("creak", -6.0)


## Pistas de audio generales: campanada cada hora y aviso de bateria baja.
func _update_audio_cues() -> void:
	var hour: int = int(clampf(elapsed / Balance.NIGHT_DURATION, 0.0, 1.0) * 6.0)
	if hour > _last_hour and hour < 6:
		_last_hour = hour
		SoundBank.play("chime", -6.0)
	if not _low_energy_warned and energy.energy <= 20.0:
		_low_energy_warned = true
		SoundBank.play("warn", -4.0)
		hud.notify("ENERGÍA BAJA", UIUtil.RED)


func _update_hud() -> void:
	hud.set_energy(energy.energy)
	hud.set_time_text(_clock_text())
	var level: int = 1
	if monitor_up:
		level += 1
	for side in gate_closed.keys():
		if gate_closed[side] and not blackout:
			level += 1
	hud.set_usage(mini(level, 5))
	hud.set_gate("left", gate_closed["left"])
	hud.set_gate("right", gate_closed["right"])
	hud.set_boiler_cd(boiler_cd)
	if monitor_lock > 0.0 and not monitor_up:
		hud.monitor_btn.text = "REINICIANDO (%d)" % int(ceil(monitor_lock))
		hud.monitor_btn.disabled = true
	else:
		hud.monitor_btn.text = "MONITOR  [ESPACIO]"
		hud.monitor_btn.disabled = blackout
	hud.set_intercom_active(intercom_cam)
	hud.set_box(box_enabled, box_charge, monitor_up and current_cam == Balance.BOX_CAM and not blackout)
	if debug_on:
		var lines: Array = []
		for m in monsters:
			lines.append(m.debug_text())
		lines.append("consumo base: %.2f%%/s  x%.2f" % [energy.current_rate(), energy.multiplier])
		hud.debug_label.text = "\n".join(lines)


func _clock_text() -> String:
	var hour_f: float = clampf(elapsed / Balance.NIGHT_DURATION, 0.0, 1.0) * 6.0
	var h: int = int(hour_f)
	var minute: int = int((hour_f - h) * 6.0) * 10
	var h12: int = 12 if h == 0 else h
	return "%d:%02d AM" % [h12, minute]


# ============================================================= fin de la noche

func _on_depleted() -> void:
	if is_over or blackout:
		return
	blackout = true
	gate_closed["left"] = false
	gate_closed["right"] = false
	monitor_up = false
	energy.monitor_up = false
	camera_view.visible = false
	office_view.visible = true
	_stop_intercom()
	SoundBank.stop_loop("hum")
	SoundBank.stop_loop("tick")
	SoundBank.stop_loop("musicbox")
	SoundBank.stop_loop("ambience")
	SoundBank.play("blackout")
	hud.set_monitor(false)
	hud.set_blackout(true)
	hud.notify("SIN ENERGÍA", UIUtil.RED)
	for m in monsters:
		m.on_blackout()


func _win() -> void:
	if is_over:
		return
	is_over = true
	for m in monsters:
		m.active = false
	SoundBank.stop_all_loops()
	SoundBank.play("bell")
	GameState.last_result = {"won": true, "night": night}
	GameState.win_night()
	hud.set_time_text("6:00 AM")
	hud.notify("6:00 AM — ¡sobreviviste!", UIUtil.GREEN)
	var tw := create_tween()
	tw.tween_interval(3.2)
	tw.tween_callback(_goto_result)


func _on_jumpscare(m, reason: String) -> void:
	if is_over:
		return
	is_over = true
	for other in monsters:
		other.active = false
	SoundBank.stop_all_loops()
	SoundBank.play("scream", 3.0)
	GameState.last_result = {
		"won": false,
		"night": night,
		"reason": reason,
		"monster": m.display_name,
		"monster_key": m.key,
		"hint": m.counter_hint,
	}
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var js := JumpscareView.new()
	js.kind = m.key
	layer.add_child(js)
	js.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(_goto_result)


func _goto_result() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/result.tscn")


# ================================================================== entrada

func _input(event: InputEvent) -> void:
	if not started and intro_overlay != null:
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
			_begin()
			get_viewport().set_input_as_handled()
			return
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	match ke.keycode:
		KEY_ESCAPE:
			if started and not is_over and not pause_menu.visible:
				pause_menu.open()
				get_viewport().set_input_as_handled()
		KEY_SPACE: toggle_monitor()
		KEY_A: toggle_gate("left")
		KEY_D: toggle_gate("right")
		KEY_F: do_flash()
		KEY_I: do_intercom()
		KEY_B: do_boiler()
		KEY_R: do_wind()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
			select_cam(ke.keycode - KEY_0)
		# --- atajos de depuracion: solo existen si Balance.DEBUG_KEYS = true ---
		KEY_F1:
			if Balance.DEBUG_KEYS:
				debug_on = not debug_on
				hud.debug_label.visible = debug_on
		KEY_F2:
			if Balance.DEBUG_KEYS:
				elapsed += 30.0
		KEY_F3:
			if Balance.DEBUG_KEYS:
				energy.refill()
		KEY_F4:
			if Balance.DEBUG_KEYS:
				energy.energy = 0.5
