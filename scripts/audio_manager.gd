extends Node

var crash_player: AudioStreamPlayer
var brake_player: AudioStreamPlayer
var ding_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

var crash_stream: AudioStreamGenerator
var brake_stream: AudioStreamGenerator
var ding_stream: AudioStreamGenerator
var ambient_stream: AudioStreamGenerator

enum AmbientType { NONE, RAIN, WIND, LAVA, SNOW }
var current_ambient: AmbientType = AmbientType.NONE
var ambient_phase: float = 0.0

func _ready() -> void:
	_setup_players()
	
func _setup_players() -> void:
	crash_player = AudioStreamPlayer.new()
	crash_stream = AudioStreamGenerator.new()
	crash_stream.mix_rate = 44100
	crash_stream.buffer_length = 0.5
	crash_player.stream = crash_stream
	add_child(crash_player)
	
	brake_player = AudioStreamPlayer.new()
	brake_stream = AudioStreamGenerator.new()
	brake_stream.mix_rate = 44100
	brake_stream.buffer_length = 0.2
	brake_player.stream = brake_stream
	brake_player.volume_db = -12.0
	add_child(brake_player)
	
	ding_player = AudioStreamPlayer.new()
	ding_stream = AudioStreamGenerator.new()
	ding_stream.mix_rate = 44100
	ding_stream.buffer_length = 1.0
	ding_player.stream = ding_stream
	add_child(ding_player)

	ambient_player = AudioStreamPlayer.new()
	ambient_stream = AudioStreamGenerator.new()
	ambient_stream.mix_rate = 44100
	ambient_stream.buffer_length = 0.1
	ambient_player.stream = ambient_stream
	ambient_player.volume_db = -20.0
	add_child(ambient_player)

func set_ambient(type: AmbientType) -> void:
	current_ambient = type
	if type != AmbientType.NONE:
		if not ambient_player.playing: ambient_player.play()
	else:
		ambient_player.stop()

func _process(_delta: float) -> void:
	if not ambient_player.playing: return
	
	var playback = ambient_player.get_stream_playback()
	if not playback: return
	
	var frames = playback.get_frames_available()
	for i in range(frames):
		ambient_phase += 1.0 / 44100.0
		var sample = 0.0
		
		match current_ambient:
			AmbientType.RAIN:
				# High frequency white noise hiss
				sample = randf_range(-1.0, 1.0) * 0.3
			AmbientType.WIND:
				# Low frequency rumble + filtered noise
				var noise = randf_range(-1.0, 1.0)
				var rumble = sin(ambient_phase * 20.0 * PI * 2.0) * 0.5
				sample = (noise + rumble) * (0.5 + 0.5 * sin(ambient_phase * 0.5))
			AmbientType.LAVA:
				# Bubbling low rumble
				var rumble = sin(ambient_phase * 40.0 * PI * 2.0)
				var bubble = randf_range(-1.0, 1.0) if sin(ambient_phase * 15.0) > 0.98 else 0.0
				sample = (rumble * 0.6) + (bubble * 0.4)
			AmbientType.SNOW:
				# Soft, cold wind
				sample = randf_range(-1.0, 1.0) * 0.1 * (0.8 + 0.2 * sin(ambient_phase))
		
		playback.push_frame(Vector2(sample, sample))

func play_crash() -> void:
	crash_player.play()
	var playback = crash_player.get_stream_playback()
	if not playback: return
	var frames = 44100 * 0.5
	for i in range(frames):
		var env = exp(-5.0 * (float(i) / frames))
		var noise = randf_range(-1.0, 1.0) * env
		playback.push_frame(Vector2(noise, noise))

func play_brake() -> void:
	if brake_player.playing: return
	brake_player.play()
	var playback = brake_player.get_stream_playback()
	if not playback: return
	var frames = 44100 * 0.2
	for i in range(frames):
		var time = float(i) / 44100.0
		var wave = sin(time * 2000.0 * PI * 2.0) * 0.5 + randf_range(-0.5, 0.5)
		var env = 1.0 - (float(i) / frames)
		playback.push_frame(Vector2(wave * env, wave * env))

func play_ding() -> void:
	ding_player.play()
	var playback = ding_player.get_stream_playback()
	if not playback: return
	var frames = 44100 * 1.0
	for i in range(frames):
		var time = float(i) / 44100.0
		var wave = sin(time * 880.0 * PI * 2.0)
		var env = exp(-3.0 * (float(i) / frames))
		playback.push_frame(Vector2(wave * env * 0.5, wave * env * 0.5))
