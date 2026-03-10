extends Node

var player: AudioStreamPlayer
var stream: AudioStreamGenerator

var sample_rate: float = 44100.0
var tempo: float = 138.0
var time_accum: float = 0.0

var pulse_phase: float = 0.0
var lead_phase: float = 0.0

# Song Structure
enum Section { INTRO, VERSE, CHORUS, BREAKDOWN }
var current_section: Section = Section.INTRO
var bar_count: int = 0
var step_index: int = 0

# Music Data
var bass_notes = [43.65, 43.65, 51.91, 43.65, 58.27, 43.65, 51.91, 65.41]
var lead_notes = [
	[0, 0, 87.31, 0, 103.83, 0, 116.54, 0], # Motif 1
	[87.31, 98.00, 103.83, 116.54, 130.81, 116.54, 103.83, 98.00] # Motif 2
]

func _ready() -> void:
	player = AudioStreamPlayer.new()
	stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.1
	player.stream = stream
	player.volume_db = -16.0
	add_child(player)
	player.play()

func _process(_delta: float) -> void:
	var playback = player.get_stream_playback()
	if not playback: return
	
	var frames_available = playback.get_frames_available()
	var seconds_per_step = 60.0 / (tempo * 4.0)
	
	for i in range(frames_available):
		time_accum += 1.0 / sample_rate
		
		if time_accum >= seconds_per_step:
			time_accum -= seconds_per_step
			step_index = (step_index + 1) % 32
			if step_index == 0:
				bar_count = (bar_count + 1) % 64
				_update_song_structure()
		
		var final_sample: float = 0.0
		var env = exp(-10.0 * (time_accum / seconds_per_step))
		
		# --- 1. BASS (Pulse 25%) ---
		if current_section != Section.BREAKDOWN:
			var freq = bass_notes[step_index % 8]
			if bar_count % 8 >= 4: freq *= 1.2 # Variation
			pulse_phase = fmod(pulse_phase + (freq / sample_rate), 1.0)
			var bass_osc = 1.0 if pulse_phase < 0.25 else -1.0
			final_sample += bass_osc * env * 0.4

		# --- 2. LEAD (Pulse 50% - Square) ---
		if current_section == Section.CHORUS or (current_section == Section.VERSE and bar_count % 4 >= 2):
			var lead_pattern = lead_notes[1] if current_section == Section.CHORUS else lead_notes[0]
			var l_freq = lead_pattern[step_index % 8]
			if l_freq > 0:
				lead_phase = fmod(lead_phase + (l_freq / sample_rate), 1.0)
				var lead_osc = 1.0 if lead_phase < 0.5 else -1.0
				var l_env = exp(-5.0 * (time_accum / seconds_per_step))
				final_sample += lead_osc * l_env * 0.3

		# --- 3. DRUMS ---
		if current_section != Section.INTRO:
			# Kick
			if step_index % 4 == 0:
				var k_env = exp(-15.0 * (time_accum / seconds_per_step))
				final_sample += sin(50.0 * PI * 2.0 * exp(-15.0 * time_accum)) * k_env * 0.7
			
			# Snare
			if step_index % 8 == 4:
				var s_env = exp(-15.0 * (time_accum / seconds_per_step))
				final_sample += randf_range(-1.0, 1.0) * s_env * 0.4
				
			# Hat
			if step_index % 2 != 0:
				var h_env = exp(-50.0 * (time_accum / seconds_per_step))
				final_sample += randf_range(-1.0, 1.0) * h_env * 0.15

		final_sample = clamp(final_sample, -1.0, 1.0)
		playback.push_frame(Vector2(final_sample, final_sample))

func _update_song_structure() -> void:
	if bar_count < 8:
		current_section = Section.INTRO
	elif bar_count < 24:
		current_section = Section.VERSE
	elif bar_count < 40:
		current_section = Section.CHORUS
	elif bar_count < 48:
		current_section = Section.BREAKDOWN
	elif bar_count < 64:
		current_section = Section.CHORUS # Grand Finale
