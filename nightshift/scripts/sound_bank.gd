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
