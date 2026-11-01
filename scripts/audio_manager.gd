extends Node

# AudioManager - Sistema de audio balanceado con buses dedicados, limitadores anti-saturación y síntesis armónica suave.

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
const POOL_SIZE: int = 6
var pool_idx: int = 0

var star_players: Array[AudioStreamPlayer] = []
var star_player_idx: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_audio_buses()
	_create_players()
	_generate_audio_streams()

func _setup_audio_buses() -> void:
	# 1. Limiter en Master (evita recorte digital duro en bocinas de celulares)
	var master_limiter = AudioEffectLimiter.new()
	master_limiter.ceiling_db = -0.5
	master_limiter.threshold_db = 0.0
	master_limiter.soft_clip_db = 3.0
	master_limiter.soft_clip_ratio = 10.0
	
	var master_has_limiter = false
	for i in range(AudioServer.get_bus_effect_count(0)):
		if AudioServer.get_bus_effect(0, i) is AudioEffectLimiter:
			master_has_limiter = true
			break
	if not master_has_limiter:
		AudioServer.add_bus_effect(0, master_limiter)
	
	# 2. Bus BGM (Música de fondo)
	var bgm_bus_idx = AudioServer.get_bus_index("BGM")
	if bgm_bus_idx == -1:
		AudioServer.add_bus()
		bgm_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bgm_bus_idx, "BGM")
		AudioServer.set_bus_send(bgm_bus_idx, "Master")
		AudioServer.set_bus_volume_db(bgm_bus_idx, -2.0)
		
	# 3. Bus SFX (Efectos de sonido) con su propio limitador para evitar suma descontrolada
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx == -1:
		AudioServer.add_bus()
		sfx_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")
		AudioServer.set_bus_volume_db(sfx_bus_idx, -1.0)
		
		var sfx_limiter = AudioEffectLimiter.new()
		sfx_limiter.ceiling_db = -1.0
		sfx_limiter.threshold_db = 0.0
		AudioServer.add_bus_effect(sfx_bus_idx, sfx_limiter)

func _create_players() -> void:
	# Pool de efectos generales
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)
		
	# Jugadores dedicados para estrellas (máximo 2 voces para que la escala musical suene limpia y dulce)
	for i in range(2):
		var sp = AudioStreamPlayer.new()
		sp.bus = "SFX"
		add_child(sp)
		star_players.append(sp)
		
	# Reproductor de música de fondo
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	bgm_player.volume_db = -14.0 # Música dulce y sutil
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)

func _generate_audio_streams() -> void:
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
	tw.tween_property(bgm_player, "volume_db", -14.0, 0.6)

func _on_bgm_finished() -> void:
	bgm_player.play()

func play_jump() -> void:
	play_stream(sfx_jump, -7.0, randf_range(0.97, 1.03))

func play_star() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_star_time < 1.8:
		star_pitch_index = (star_pitch_index + 1) % sfx_stars.size()
	else:
		star_pitch_index = 0
	last_star_time = now
	
	# Usar pool de 2 voces para estrellas con alternancia para evitar saturación de notas repetidas
	var sp = star_players[star_player_idx]
	star_player_idx = (star_player_idx + 1) % star_players.size()
	sp.stream = sfx_stars[star_pitch_index]
	sp.volume_db = -6.0
	sp.pitch_scale = 1.0
	sp.play()

func play_mode_switch() -> void:
	play_stream(sfx_mode_switch, -6.0)

func play_boing() -> void:
	play_stream(sfx_boing, -6.0)

func play_stumble() -> void:
	play_stream(sfx_stumble, -6.0)

func play_celebration() -> void:
	play_stream(sfx_celebration, -4.0)

func play_stream(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not stream:
		return
	var player = sfx_players[pool_idx]
	pool_idx = (pool_idx + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

# ----------------- SÍNTESIS DE SONIDO PROCEDURAL SEDOSA Y BALANCEADA -----------------

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
		var freq = lerp(240.0, 460.0, pow(progress, 0.7))
		phase += freq * TAU / sample_rate
		var env = sin(progress * PI)
		var sample_val = int(sin(phase) * env * 11000.0)
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
		var freq = lerp(160.0, 500.0, pow(progress, 0.6)) + sin(t * 35.0) * 25.0
		phase += freq * TAU / sample_rate
		var att = clamp(progress / 0.02, 0.0, 1.0)
		var rel = clamp((1.0 - progress) / 0.08, 0.0, 1.0)
		var env = exp(-progress * 3.5) * att * rel
		var sample_val = int(sin(phase) * env * 11000.0)
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
		var freq = lerp(300.0, 130.0, progress)
		phase += freq * TAU / sample_rate
		var att = clamp(t / 0.008, 0.0, 1.0)
		var rel = clamp((duration - t) / 0.03, 0.0, 1.0)
		var env = exp(-progress * 4.5) * att * rel
		var noise = (randf() - 0.5) * 0.25
		var wave = sin(phase) * 0.75 + noise
		var sample_val = int(wave * env * 10000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func generate_celebration_sfx() -> AudioStreamWAV:
	# Fanfarria de 3 notas armoniosas: C5, E5, G5
	var sample_rate = 22050
	var duration = 0.55
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	var notes = [523.25, 659.25, 783.99]
	var note_phases = [0.0, 0.0, 0.0]
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var master_fade = clamp((duration - t) / 0.04, 0.0, 1.0)
		var sample = 0.0
		for idx in range(3):
			var t_note = t - float(idx) * 0.14
			var freq = notes[idx]
			note_phases[idx] += freq * TAU / sample_rate
			if t_note >= 0.0 and t_note < 0.28:
				var note_prog = t_note / 0.28
				var att = clamp(t_note / 0.008, 0.0, 1.0)
				var rel = clamp((0.28 - t_note) / 0.05, 0.0, 1.0)
				var env = exp(-note_prog * 4.0) * att * rel
				var wave = sin(note_phases[idx]) * 0.75 + sin(note_phases[idx] * 2.0) * 0.25
				sample += wave * env * 7500.0
		var sample_val = int(sample * master_fade)
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
	var duration = 0.32
	var num_samples = int(sample_rate * duration)
	
	for freq in frequencies:
		var byte_array = PackedByteArray()
		byte_array.resize(num_samples * 2)
		var phase = 0.0
		for i in range(num_samples):
			var t = float(i) / sample_rate
			var progress = t / duration
			phase += freq * TAU / sample_rate
			var att = clamp(t / 0.005, 0.0, 1.0)
			var rel = clamp((duration - t) / 0.03, 0.0, 1.0)
			var env = exp(-progress * 5.0) * att * rel
			var wave = sin(phase) * 0.8 + sin(phase * 2.0) * 0.2
			var sample_val = int(wave * env * 9500.0)
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
		var att = clamp(t / 0.008, 0.0, 1.0)
		var rel = clamp((duration - t) / 0.05, 0.0, 1.0)
		var env = exp(-progress * 4.0) * att * rel
		var wave = (sin(phase1) + sin(phase2)) * 0.5
		var sample_val = int(wave * env * 10000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func generate_bgm_track(is_night: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 8.0 # 8 segundos en bucle armonioso
	var num_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	var day_melody = [
		523.25, 659.25, 587.33, 783.99,
		659.25, 523.25, 440.00, 523.25
	]
	var night_melody = [
		440.00, 523.25, 392.00, 440.00,
		329.63, 392.00, 349.23, 392.00
	]
	var melody = night_melody if is_night else day_melody
	
	var step_dur = duration / float(melody.size()) # 1.0s por nota
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var step_idx = int(t / step_dur) % melody.size()
		var freq = melody[step_idx]
		phase += freq * TAU / sample_rate
		
		var step_t = fmod(t, step_dur)
		var att = clamp(step_t / 0.04, 0.0, 1.0)
		var rel = clamp((step_dur - step_t) / 0.12, 0.0, 1.0)
		var env = exp(-step_t * (3.0 if is_night else 2.2)) * att * rel * 0.8
		var sample_val = int(sin(phase) * env * 6000.0)
		byte_array.encode_s16(i * 2, sample_val)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = byte_array
	return wav
