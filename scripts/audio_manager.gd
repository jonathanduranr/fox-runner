extends Node

# AudioManager - Generador y reproductor de sonido procedural dulce, BGM y SFX
var sfx_jump: AudioStreamWAV
var sfx_stars: Array[AudioStreamWAV] = []
var sfx_mode_switch: AudioStreamWAV
var sfx_boing: AudioStreamWAV
var sfx_stumble: AudioStreamWAV
var sfx_celebration: AudioStreamWAV

var bgm_day: AudioStreamWAV
var bgm_night: AudioStreamWAV
var bgm_player: AudioStreamPlayer

var star_pitch_index: int = 0
var last_star_time: float = 0.0

var sfx_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 10
var pool_idx: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pool de efectos
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
		
	# Reproductor de música de fondo
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -12.0 # Música suave y relajante
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)
	
	# Generar sonidos procedurales en memoria
	sfx_jump = generate_jump_sfx()
	sfx_stars = generate_musical_scale_sfx()
	sfx_mode_switch = generate_chime_sfx()
	sfx_boing = generate_boing_sfx()
	sfx_stumble = generate_stumble_sfx()
	sfx_celebration = generate_celebration_sfx()
	
	bgm_day = generate_bgm_track(false)
	bgm_night = generate_bgm_track(true)

func start_bgm(is_night: bool) -> void:
	bgm_player.stream = bgm_night if is_night else bgm_day
	bgm_player.play()

func switch_bgm(is_night: bool) -> void:
	var tw = create_tween()
	tw.tween_property(bgm_player, "volume_db", -30.0, 0.4)
	tw.tween_callback(func():
		bgm_player.stream = bgm_night if is_night else bgm_day
		bgm_player.play()
	)
	tw.tween_property(bgm_player, "volume_db", -12.0, 0.6)

func _on_bgm_finished() -> void:
	bgm_player.play()

func play_jump() -> void:
	play_stream(sfx_jump, -4.0, randf_range(0.96, 1.04))

func play_star() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_star_time < 1.8:
		star_pitch_index = (star_pitch_index + 1) % sfx_stars.size()
	else:
		star_pitch_index = 0
	last_star_time = now
	play_stream(sfx_stars[star_pitch_index], -2.0)

func play_mode_switch() -> void:
	play_stream(sfx_mode_switch, -3.0)

func play_boing() -> void:
	play_stream(sfx_boing, -2.0)

func play_stumble() -> void:
	play_stream(sfx_stumble, -4.0)

func play_celebration() -> void:
	play_stream(sfx_celebration, -1.0)

func play_stream(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not stream:
		return
	var player = sfx_players[pool_idx]
	pool_idx = (pool_idx + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

# ----------------- SÍNTESIS DE SONIDO PROCEDURAL -----------------

func generate_jump_sfx() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = t / duration
		var freq = lerp(240.0, 480.0, pow(progress, 0.7))
		phase += freq * TAU / sample_rate
		var env = sin(progress * PI)
		var sample_val = int(sin(phase) * env * 14000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func generate_boing_sfx() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = t / duration
		# Tono elástico con vibrato ascendente cómico
		var freq = lerp(160.0, 520.0, pow(progress, 0.6)) + sin(t * 40.0) * 30.0
		phase += freq * TAU / sample_rate
		var env = exp(-progress * 3.5)
		var sample_val = int(sin(phase) * env * 18000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func generate_stumble_sfx() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.22
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = t / duration
		var freq = lerp(320.0, 140.0, progress)
		phase += freq * TAU / sample_rate
		var env = exp(-progress * 4.0)
		var sample_val = int((sin(phase) * 0.7 + (randf() - 0.5) * 0.3) * env * 14000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func generate_celebration_sfx() -> AudioStreamWAV:
	# Fanfarria alegre de 3 notas: C5, E5, G5
	var sample_rate = 22050
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	var notes = [523.25, 659.25, 783.99]
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_idx = clamp(int(t / 0.16), 0, 2)
		var freq = notes[note_idx]
		phase += freq * TAU / sample_rate
		var env = exp(-fmod(t, 0.16) * 5.0)
		var wave = sin(phase) * 0.8 + sin(phase * 2.0) * 0.2
		var sample_val = int(wave * env * 18000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func generate_musical_scale_sfx() -> Array[AudioStreamWAV]:
	var frequencies = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50]
	var scale_list: Array[AudioStreamWAV] = []
	var sample_rate = 22050
	var duration = 0.35
	var num_samples = int(sample_rate * duration)
	
	for freq in frequencies:
		var byte_array = PackedByteArray()
		byte_array.resize(num_samples * 2)
		var phase = 0.0
		for i in range(num_samples):
			var t = float(i) / sample_rate
			var progress = t / duration
			phase += freq * TAU / sample_rate
			var env = exp(-progress * 6.0)
			var wave = sin(phase) * 0.7 + sin(phase * 2.0) * 0.3
			var sample_val = int(wave * env * 18000.0)
			byte_array.encode_s16(i * 2, sample_val)
			
		var wav = AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = sample_rate
		wav.data = byte_array
		scale_list.append(wav)
		
	return scale_list

func generate_chime_sfx() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = t / duration
		phase1 += 440.0 * TAU / sample_rate
		phase2 += 660.0 * TAU / sample_rate
		var env = exp(-progress * 4.0)
		var wave = (sin(phase1) + sin(phase2)) * 0.5
		var sample_val = int(wave * env * 16000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

# Melodía de fondo ambiental (BGM) en bucle
func generate_bgm_track(is_night: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 8.0 # 8 segundos en bucle armonioso
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	# Secuencia de acordes pentatónicos C - G - Am - F
	var day_melody = [
		523.25, 659.25, 587.33, 783.99,
		659.25, 523.25, 440.00, 523.25
	]
	var night_melody = [
		440.00, 523.25, 392.00, 440.00,
		329.63, 392.00, 349.23, 392.00
	]
	var melody = night_melody if is_night else day_melody
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_idx = int((t / duration) * melody.size()) % melody.size()
		var freq = melody[note_idx]
		phase += freq * TAU / sample_rate
		
		# Envolvente pulsante suave
		var step_t = fmod(t, duration / melody.size())
		var env = exp(-step_t * (3.0 if is_night else 2.2)) * 0.8
		var sample_val = int(sin(phase) * env * 9000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = byte_array
	return wav
