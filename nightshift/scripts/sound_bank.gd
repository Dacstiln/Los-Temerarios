extends Node
## Autoload: todos los sonidos se sintetizan por codigo (sin archivos de audio).
## Son placeholders funcionales: se pueden reemplazar por .ogg/.wav reales
## simplemente devolviendo otro AudioStream desde _get_stream().

const RATE: int = 22050

var _streams: Dictionary = {}
var _pool: Array = []
var _loops: Dictionary = {}

const ALL_SOUNDS: Array = [
	"hum", "static", "footstep", "clang", "gate", "hiss", "flash", "jazz",
	"scream", "bell", "blackout", "vent", "ui", "arrive", "tick",
	"hover", "click", "chime", "warn", "creak", "wind", "box_stop", "musicbox",
	"ambience", "win", "lose",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


## Sintetiza todo de una vez (se llama mientras se muestra la tarjeta de la noche).
func warmup() -> void:
	for s in ALL_SOUNDS:
		_get_stream(s)


func play(sound: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStreamWAV = _get_stream(sound)
	if stream == null:
		return
	var p: AudioStreamPlayer = _free_player()
	p.stream = stream
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()


func start_loop(sound: String, vol_db: float = -6.0) -> void:
	if _loops.has(sound):
		return
	var stream: AudioStreamWAV = _get_stream(sound)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.volume_db = vol_db
	p.play()
	_loops[sound] = p


## Cambia volumen y tono de un bucle que ya esta sonando (la cajita de musica lo usa).
func set_loop(sound: String, vol_db: float, pitch: float = 1.0) -> void:
	if _loops.has(sound):
		var p: AudioStreamPlayer = _loops[sound]
		p.volume_db = vol_db
		p.pitch_scale = pitch


func stop_loop(sound: String) -> void:
	if _loops.has(sound):
		var p: AudioStreamPlayer = _loops[sound]
		p.stop()
		p.queue_free()
		_loops.erase(sound)


func stop_all_loops() -> void:
	for k in _loops.keys():
		stop_loop(k)


func set_paused(paused: bool) -> void:
	for k in _loops.keys():
		var p: AudioStreamPlayer = _loops[k]
		p.stream_paused = paused


func _free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	var np := AudioStreamPlayer.new()
	add_child(np)
	_pool.append(np)
	return np


func _get_stream(sound: String) -> AudioStreamWAV:
	if _streams.has(sound):
		return _streams[sound]
	var s: AudioStreamWAV = _build(sound)
	if s != null:
		_streams[sound] = s
	return s


func _build(sound: String) -> AudioStreamWAV:
	match sound:
		"hum": return _snd_hum()
		"static": return _snd_static()
		"footstep": return _snd_footstep()
		"clang": return _snd_clang()
		"gate": return _snd_gate()
		"hiss": return _snd_hiss()
		"flash": return _snd_flash()
		"jazz": return _snd_jazz()
		"scream": return _snd_scream()
		"bell": return _snd_bell()
		"blackout": return _snd_blackout()
		"vent": return _snd_vent()
		"ui": return _snd_ui()
		"arrive": return _snd_arrive()
		"tick": return _snd_tick()
		"hover": return _snd_hover()
		"click": return _snd_click()
		"chime": return _snd_chime()
		"warn": return _snd_warn()
		"creak": return _snd_creak()
		"wind": return _snd_wind()
		"box_stop": return _snd_box_stop()
		"musicbox": return _snd_musicbox()
		"ambience": return _snd_ambience()
		"win": return _snd_win()
		"lose": return _snd_lose()
		"menu_theme": return _snd_menu_theme()
	return null


# ---------------------------------------------------------------- utilidades

func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(RATE * seconds))
	return b


func _noise() -> float:
	return randf() * 2.0 - 1.0


func _to_stream(buf: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v: int = clampi(int(buf[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = buf.size()
	return s


# ------------------------------------------------------------------- sonidos

func _snd_hum() -> AudioStreamWAV:
	var b := _buf(2.0)
	for i in b.size():
		var t: float = float(i) / RATE
		b[i] = 0.18 * sin(TAU * 50.0 * t) + 0.10 * sin(TAU * 100.0 * t) + 0.04 * sin(TAU * 150.0 * t) + 0.015 * _noise()
	return _to_stream(b, true)


func _snd_static() -> AudioStreamWAV:
	var b := _buf(1.0)
	for i in b.size():
		b[i] = 0.22 * _noise()
	return _to_stream(b, true)


func _snd_footstep() -> AudioStreamWAV:
	var b := _buf(0.3)
	for i in b.size():
		var t: float = float(i) / RATE
		var env: float = exp(-t * 18.0)
		b[i] = env * (0.8 * sin(TAU * 70.0 * t) + 0.3 * _noise())
	return _to_stream(b, false)


func _snd_clang() -> AudioStreamWAV:
	var b := _buf(1.0)
	for i in b.size():
		var t: float = float(i) / RATE
		var tone: float = sin(TAU * 523.0 * t) + 0.6 * sin(TAU * 831.0 * t) + 0.4 * sin(TAU * 1244.0 * t)
		b[i] = exp(-t * 5.0) * tone * 0.35 + exp(-t * 40.0) * _noise() * 0.3
	return _to_stream(b, false)


func _snd_gate() -> AudioStreamWAV:
	var b := _buf(0.55)
	var ph: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var f: float = 240.0 - 130.0 * minf(t / 0.5, 1.0)
		ph += TAU * f / RATE
		var v: float = 0.35 * sin(ph) * exp(-t * 3.0) + 0.18 * _noise() * exp(-t * 5.0)
		if t > 0.38:
			v += exp(-(t - 0.38) * 28.0) * (0.5 * sin(TAU * 880.0 * t) + 0.3 * sin(TAU * 1330.0 * t))
		b[i] = v
	return _to_stream(b, false)


func _snd_hiss() -> AudioStreamWAV:
	var b := _buf(1.4)
	var lp: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var n: float = _noise()
		lp += 0.2 * (n - lp)
		var hp: float = n - lp
		var env: float = minf(t / 0.08, 1.0) * exp(-t * 1.6)
		b[i] = hp * 0.45 * env
	return _to_stream(b, false)


func _snd_flash() -> AudioStreamWAV:
	var b := _buf(0.2)
	for i in b.size():
		var t: float = float(i) / RATE
		b[i] = exp(-t * 60.0) * sin(TAU * 2400.0 * t) * 0.5 + exp(-t * 20.0) * 0.2 * _noise()
	return _to_stream(b, false)


## Jazz de los años 20 en "radio vieja": bajo caminante + acordes en contratiempo + melodia.
func _snd_jazz() -> AudioStreamWAV:
	var bass: Array = [130.81, 164.81, 110.0, 138.59, 146.83, 174.61, 98.0, 123.47]
	var chords: Array = [
		[261.63, 329.63, 392.0, 493.88],
		[220.0, 277.18, 329.63, 392.0],
		[293.66, 349.23, 440.0, 523.25],
		[196.0, 246.94, 293.66, 349.23],
	]
	var melody: Array = [523.25, 659.25, 587.33, 440.0, 698.46, 587.33, 493.88, 392.0]
	var beat: float = 0.5
	var b := _buf(beat * 8.0)
	var lp: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var bi: int = mini(int(t / beat), 7)
		var tb: float = t - bi * beat
		var v: float = 0.0
		var fb: float = bass[bi]
		v += 0.30 * exp(-tb * 5.0) * (sin(TAU * fb * t) + 0.4 * sin(TAU * fb * 2.0 * t))
		var ts: float = tb - beat * 0.66
		if ts >= 0.0:
			var ch: Array = chords[int(floor(bi * 0.5))]
			var cs: float = 0.0
			for f in ch:
				cs += sin(TAU * float(f) * t)
			v += 0.07 * exp(-ts * 7.0) * cs
		var fm: float = melody[bi]
		v += 0.16 * exp(-tb * 2.5) * sin(TAU * fm * t + 3.0 * sin(TAU * 5.5 * t))
		lp += 0.45 * (v - lp)
		b[i] = lp + 0.012 * _noise()
	return _to_stream(b, true)


func _snd_scream() -> AudioStreamWAV:
	var dur: float = 1.3
	var b := _buf(dur)
	var ph: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var f: float = 320.0 + 700.0 * (t / dur) + 80.0 * sin(TAU * 12.0 * t)
		ph += TAU * f / RATE
		var env: float = minf(t / 0.015, 1.0) * (1.0 - 0.6 * (t / dur))
		var v: float = (0.55 * sin(ph) + 0.25 * signf(sin(ph * 1.5)) + 0.5 * _noise()) * env
		b[i] = tanh(v * 2.2) * 0.9
	return _to_stream(b, false)


func _snd_bell() -> AudioStreamWAV:
	var b := _buf(3.0)
	var partials: Array = [880.0, 1320.0, 1760.0, 2217.0]
	var amps: Array = [1.0, 0.5, 0.3, 0.2]
	for i in b.size():
		var t: float = float(i) / RATE
		var v: float = 0.0
		for k in partials.size():
			v += float(amps[k]) * sin(TAU * float(partials[k]) * t) * exp(-t * (1.2 + k))
		b[i] = v * 0.25
	return _to_stream(b, false)


func _snd_blackout() -> AudioStreamWAV:
	var b := _buf(1.0)
	var ph: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var f: float = 400.0 * exp(-t * 3.0) + 30.0
		ph += TAU * f / RATE
		b[i] = (0.5 * sin(ph) + 0.1 * _noise()) * exp(-t * 2.0)
	return _to_stream(b, false)


func _snd_vent() -> AudioStreamWAV:
	var b := _buf(0.9)
	var lp: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var g: float = 1.0 if sin(TAU * 13.0 * t) > 0.2 else 0.0
		lp += 0.25 * (_noise() - lp)
		b[i] = (lp * 0.9 + 0.2 * sin(TAU * 60.0 * t)) * g * exp(-t * 1.2) * 0.8
	return _to_stream(b, false)


func _snd_ui() -> AudioStreamWAV:
	var b := _buf(0.07)
	for i in b.size():
		var t: float = float(i) / RATE
		b[i] = exp(-t * 55.0) * sin(TAU * 1200.0 * t) * 0.4
	return _to_stream(b, false)


## Sting grave y disonante: un monstruo acaba de llegar a una reja.
func _snd_arrive() -> AudioStreamWAV:
	var b := _buf(0.9)
	for i in b.size():
		var t: float = float(i) / RATE
		var v: float = sin(TAU * 110.0 * t) + sin(TAU * 117.0 * t) + 0.5 * sin(TAU * 233.0 * t)
		b[i] = 0.25 * exp(-t * 3.0) * v
	return _to_stream(b, false)


## Reloj de bolsillo de Cornelius: "tic" agudo y "tac" grave, en bucle de 1 s.
func _snd_tick() -> AudioStreamWAV:
	var b := _buf(1.0)
	for i in b.size():
		var t: float = float(i) / RATE
		var tt: float = fmod(t, 0.5)
		var f: float = 2400.0 if t < 0.5 else 1500.0
		var env: float = exp(-tt * 70.0)
		b[i] = (sin(TAU * f * tt) * 0.6 + _noise() * 0.25) * env * 0.7
	return _to_stream(b, true)


# ================================================= sonidos de interfaz y ambiente (v2)

func _snd_hover() -> AudioStreamWAV:
	var b := _buf(0.05)
	for i in b.size():
		var t: float = float(i) / RATE
		b[i] = exp(-t * 90.0) * sin(TAU * 1800.0 * t) * 0.22
	return _to_stream(b, false)


func _snd_click() -> AudioStreamWAV:
	var b := _buf(0.12)
	for i in b.size():
		var t: float = float(i) / RATE
		b[i] = exp(-t * 45.0) * (0.45 * sin(TAU * 620.0 * t) + 0.2 * sin(TAU * 1240.0 * t)) + exp(-t * 200.0) * _noise() * 0.25
	return _to_stream(b, false)


## Campanilla de recepcion de hotel: "ding" doble.
func _snd_chime() -> AudioStreamWAV:
	var b := _buf(1.6)
	for i in b.size():
		var t: float = float(i) / RATE
		var v: float = exp(-t * 3.2) * (sin(TAU * 1318.5 * t) + 0.4 * sin(TAU * 2637.0 * t))
		var t2: float = t - 0.28
		if t2 > 0.0:
			v += exp(-t2 * 3.0) * (sin(TAU * 1568.0 * t2) + 0.35 * sin(TAU * 3136.0 * t2))
		b[i] = v * 0.2
	return _to_stream(b, false)


## Aviso de bateria baja: dos pitidos.
func _snd_warn() -> AudioStreamWAV:
	var b := _buf(0.7)
	for i in b.size():
		var t: float = float(i) / RATE
		var on: bool = fmod(t, 0.35) < 0.18
		b[i] = (0.3 * signf(sin(TAU * 740.0 * t)) if on else 0.0)
	return _to_stream(b, false)


## Crujido de madera/tuberia vieja: pista de que algo se mueve en la oscuridad.
func _snd_creak() -> AudioStreamWAV:
	var b := _buf(1.1)
	var ph: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var f: float = 95.0 + 55.0 * sin(TAU * 2.3 * t) + 40.0 * t
		ph += TAU * f / RATE
		var env: float = minf(t / 0.1, 1.0) * exp(-t * 2.2)
		b[i] = env * (0.28 * signf(sin(ph)) * (0.6 + 0.4 * sin(TAU * 17.0 * t)) + 0.08 * _noise())
	return _to_stream(b, false)


## Manivela de la cajita: carraca que se acelera.
func _snd_wind() -> AudioStreamWAV:
	var b := _buf(1.0)
	var next_click: float = 0.0
	var interval: float = 0.16
	var env_t: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		if t >= next_click:
			next_click += interval
			interval = maxf(0.05, interval * 0.86)
			env_t = 0.0
		env_t += 1.0 / RATE
		b[i] = exp(-env_t * 90.0) * (_noise() * 0.5 + 0.5 * sin(TAU * 900.0 * env_t)) * 0.55 + 0.05 * sin(TAU * 110.0 * t) * minf(t * 4.0, 1.0)
	return _to_stream(b, false)


## La musica se arrastra y muere: notas que bajan de tono y se alargan.
func _snd_box_stop() -> AudioStreamWAV:
	var b := _buf(1.8)
	var notes: Array = [659.0, 587.0, 523.0, 440.0, 392.0, 330.0]
	var starts: Array = [0.0, 0.18, 0.40, 0.68, 1.02, 1.42]
	for i in b.size():
		var t: float = float(i) / RATE
		var v: float = 0.0
		for k in notes.size():
			var tn: float = t - float(starts[k])
			if tn >= 0.0:
				var f: float = float(notes[k]) * (1.0 - 0.06 * k * 0.3)
				v += exp(-tn * 5.0) * (sin(TAU * f * tn) + 0.3 * sin(TAU * f * 2.76 * tn))
		b[i] = v * 0.22
	return _to_stream(b, false)


## Nana de caja de musica (melodia original, La menor). Bucle de 4.8 s.
func _snd_musicbox() -> AudioStreamWAV:
	var notes: Array = [659.25, 783.99, 880.0, 783.99, 659.25, 587.33, 523.25, 587.33, 659.25, 523.25, 440.0, 493.88]
	var step: float = 0.4
	var b := _buf(step * notes.size())
	for i in b.size():
		var t: float = float(i) / RATE
		var idx: int = mini(int(t / step), notes.size() - 1)
		var tn: float = t - idx * step
		var f: float = notes[idx]
		var v: float = exp(-tn * 4.5) * (sin(TAU * f * tn) + 0.35 * sin(TAU * f * 2.76 * tn) * exp(-tn * 8.0) + 0.15 * sin(TAU * f * 5.4 * tn) * exp(-tn * 14.0))
		# la nota anterior sigue sonando un poco para que no corte seco
		if idx > 0:
			var tp: float = tn + step
			var fp: float = notes[idx - 1]
			v += exp(-tp * 4.5) * sin(TAU * fp * tp)
		b[i] = v * 0.28
	return _to_stream(b, true)


## Ambiente del hotel: viento grave y respiracion lenta de tuberias. Bucle de 6 s.
func _snd_ambience() -> AudioStreamWAV:
	var dur: float = 6.0
	var b := _buf(dur)
	var lp: float = 0.0
	var lp2: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var n: float = _noise()
		lp += 0.015 * (n - lp)
		lp2 += 0.06 * (n - lp2)
		var swell: float = 0.55 + 0.45 * sin(TAU * (2.0 / dur) * t)
		b[i] = (lp * 9.0 * swell + lp2 * 0.9 * (0.5 + 0.5 * sin(TAU * (3.0 / dur) * t + 1.0))) * 0.5 + 0.05 * sin(TAU * 41.0 * t) * swell
	return _to_stream(b, true)


func _snd_win() -> AudioStreamWAV:
	var b := _buf(2.2)
	var notes: Array = [523.25, 659.25, 783.99, 1046.5]
	for i in b.size():
		var t: float = float(i) / RATE
		var v: float = 0.0
		for k in notes.size():
			var tn: float = t - k * 0.18
			if tn >= 0.0:
				v += exp(-tn * 2.4) * (sin(TAU * float(notes[k]) * tn) + 0.3 * sin(TAU * float(notes[k]) * 2.0 * tn))
		b[i] = v * 0.2
	return _to_stream(b, false)


func _snd_lose() -> AudioStreamWAV:
	var b := _buf(2.2)
	for i in b.size():
		var t: float = float(i) / RATE
		var f: float = 180.0 * exp(-t * 0.9)
		var v: float = sin(TAU * f * t) + sin(TAU * f * 1.06 * t) + 0.4 * sin(TAU * f * 2.0 * t)
		b[i] = v * exp(-t * 1.4) * 0.28
	return _to_stream(b, false)


## Musica del menu: jazz lento y de salon (Am7 - Dm7 - G7 - Cmaj7), bajo, piano y escobillas.
## Bucle de 12 s. Se sintetiza una sola vez al abrir el menu.
func _snd_menu_theme() -> AudioStreamWAV:
	var beat: float = 0.75
	var bars: int = 4
	var dur: float = beat * 4.0 * bars
	var b := _buf(dur)
	var chords: Array = [
		[220.0, 261.63, 329.63, 392.0],
		[146.83, 220.0, 261.63, 349.23],
		[196.0, 246.94, 293.66, 349.23],
		[261.63, 329.63, 392.0, 493.88],
	]
	var bass: Array = [110.0, 73.42, 98.0, 130.81]
	var mel: Array = [659.25, 0.0, 587.33, 523.25, 0.0, 698.46, 659.25, 0.0, 587.33, 0.0, 493.88, 587.33, 659.25, 0.0, 523.25, 0.0]
	var lp: float = 0.0
	for i in b.size():
		var t: float = float(i) / RATE
		var bar: int = mini(int(t / (beat * 4.0)), bars - 1)
		var tb: float = fmod(t, beat)
		var bt: int = int(t / beat)
		var v: float = 0.0
		# bajo
		var fb: float = bass[bar]
		v += 0.30 * exp(-tb * 3.5) * (sin(TAU * fb * t) + 0.35 * sin(TAU * fb * 2.0 * t))
		# acorde (en el 2 y el 4)
		if bt % 2 == 1:
			var ts: float = tb
			for f in chords[bar]:
				v += 0.05 * exp(-ts * 2.2) * (sin(TAU * float(f) * t) + 0.25 * sin(TAU * float(f) * 2.0 * t))
		# melodia, una nota cada negra de corchea
		var mi: int = mini(int(t / (beat * 0.25)), mel.size() - 1)
		var fm: float = mel[mi]
		if fm > 0.0:
			var tm: float = fmod(t, beat * 0.25)
			v += 0.10 * exp(-tm * 3.0) * (sin(TAU * fm * t) + 0.2 * sin(TAU * fm * 3.0 * t))
		# escobillas
		if bt % 2 == 1:
			v += 0.04 * _noise() * exp(-tb * 14.0)
		lp += 0.55 * (v - lp)
		b[i] = lp + 0.006 * _noise()
	return _to_stream(b, true)
