extends Node

## Zero-dependency procedural score and one-shot mix. Sounds are synthesized
## into small AudioStreamWAV resources at runtime, which works in native and
## Web exports without shipping placeholder audio files.

const MIX_RATE := 22050
const MAX_SFX_PLAYERS := 32
const MUSIC_PATHS := {
	&"title": "res://assets/generated/audio/music_title.wav",
	&"hub": "res://assets/generated/audio/music_hub.wav",
	&"combat": "res://assets/generated/audio/music_combat.wav",
	&"result": "res://assets/generated/audio/music_result.wav",
}

var music_player: AudioStreamPlayer
var music_mode := &""
var music_cache: Dictionary = {}
var sfx_cache: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var previous_health := -1.0
var previous_pulse_remaining := 0.0
var audio_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio_enabled = DisplayServer.get_name() != "headless"
	_ensure_audio_buses()
	_connect_events()
	if not audio_enabled:
		music_mode = &"title"
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "ProceduralMusic"
	music_player.bus = "Music"
	add_child(music_player)
	set_music_mode(&"title")


func _exit_tree() -> void:
	shutdown()


func shutdown() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream = null
		music_player.free()
		music_player = null
	for player in sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	sfx_players.clear()
	music_cache.clear()
	sfx_cache.clear()


func set_music_mode(next_mode: StringName) -> void:
	if not audio_enabled:
		music_mode = next_mode
		return
	if next_mode == music_mode and music_player != null and music_player.playing:
		return
	music_mode = next_mode
	if not music_cache.has(next_mode):
		music_cache[next_mode] = _load_or_make_music(next_mode)
	music_player.stream = music_cache[next_mode] as AudioStreamWAV
	music_player.play()


func _load_or_make_music(mode: StringName) -> AudioStreamWAV:
	var path := str(MUSIC_PATHS.get(mode, MUSIC_PATHS[&"title"]))
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is AudioStreamWAV:
			var stream := loaded as AudioStreamWAV
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
			return stream
	return _make_music_stream(mode)


func play_ui() -> void:
	_play_tone(520.0, 640.0, 0.075, 0.15, &"sine")


func play_select() -> void:
	_play_tone(420.0, 690.0, 0.16, 0.18, &"triangle")


func play_pickup() -> void:
	_play_tone(720.0, 1040.0, 0.10, 0.13, &"sine")


func play_hit() -> void:
	_play_tone(115.0, 62.0, 0.14, 0.23, &"square", 0.18)


func play_pulse() -> void:
	_play_tone(150.0, 610.0, 0.32, 0.22, &"sine", 0.10)
	_play_tone(86.0, 48.0, 0.24, 0.16, &"triangle", 0.18)


func play_breakthrough() -> void:
	var notes := [261.63, 329.63, 392.0, 523.25, 659.25]
	for index in notes.size():
		_play_tone(notes[index], notes[index] * 1.015, 0.18, 0.15, &"triangle", 0.0, float(index) * 0.065)


func play_result(victory: bool) -> void:
	var notes := [261.63, 329.63, 392.0, 523.25] if victory else [392.0, 329.63, 261.63, 196.0]
	for index in notes.size():
		_play_tone(notes[index], notes[index] * (1.01 if victory else 0.96), 0.30, 0.18, &"triangle", 0.0, float(index) * 0.11)


func _connect_events() -> void:
	Events.game_started.connect(func() -> void:
		set_music_mode(&"combat")
		play_breakthrough()
	)
	Events.game_finished.connect(func(victory: bool, _title: String, _details: String) -> void:
		set_music_mode(&"result")
		play_result(victory)
	)
	Events.upgrade_selected.connect(func(_upgrade_id: StringName) -> void: play_breakthrough())
	Events.player_health_changed.connect(_on_health_changed)
	Events.pulse_state_changed.connect(_on_pulse_state_changed)
	Events.banner_requested.connect(_on_banner_requested)
	Events.qi_collected.connect(func(_value: float) -> void: play_pickup())
	Events.sword_fired.connect(_on_sword_fired)
	Events.enemy_defeated.connect(_on_enemy_defeated)


func _on_health_changed(current: float, _maximum: float) -> void:
	if previous_health >= 0.0 and current < previous_health - 0.1:
		play_hit()
	previous_health = current


func _on_pulse_state_changed(remaining: float, cooldown: float) -> void:
	if cooldown > 0.0 and remaining > previous_pulse_remaining + cooldown * 0.55:
		play_pulse()
	previous_pulse_remaining = remaining


func _on_banner_requested(title: String, _subtitle: String, _duration: float) -> void:
	if "ĐỘT PHÁ" in title or "NHẬP ĐẠO" in title:
		play_breakthrough()
	elif "GIÁNG THẾ" in title or "HIỆN THẾ" in title:
		_play_tone(148.0, 74.0, 0.55, 0.19, &"triangle", 0.12)


func _on_sword_fired(empowered: bool) -> void:
	_play_tone(360.0 if empowered else 280.0, 190.0, 0.095, 0.12 if empowered else 0.075, &"sine", 0.12)


func _on_enemy_defeated(was_boss: bool) -> void:
	if not was_boss:
		_play_tone(190.0, 92.0, 0.11, 0.11, &"triangle", 0.15)


func _play_tone(frequency: float, frequency_end: float, duration: float, gain: float, wave: StringName, noise: float = 0.0, delay: float = 0.0) -> void:
	if not audio_enabled:
		return
	var key := "%.2f|%.2f|%.3f|%.3f|%s|%.3f|%.3f" % [frequency, frequency_end, duration, gain, wave, noise, delay]
	if not sfx_cache.has(key):
		sfx_cache[key] = _make_tone_stream(frequency, frequency_end, duration, gain, wave, noise, delay)
	while sfx_players.size() >= MAX_SFX_PLAYERS:
		var oldest: AudioStreamPlayer = sfx_players.pop_front()
		if is_instance_valid(oldest):
			oldest.stop()
			oldest.queue_free()
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = sfx_cache[key] as AudioStreamWAV
	add_child(player)
	sfx_players.append(player)
	player.finished.connect(_on_sfx_finished.bind(player))
	player.play()


func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	sfx_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()


func _make_tone_stream(frequency: float, frequency_end: float, duration: float, gain: float, wave: StringName, noise: float, delay: float) -> AudioStreamWAV:
	var total_duration := maxf(0.01, delay + duration)
	var frame_count := ceili(total_duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%.3f|%.3f|%s" % [frequency, duration, wave])
	for frame in frame_count:
		var t := float(frame) / MIX_RATE
		var sample := 0.0
		if t >= delay:
			var local_t := t - delay
			var progress := clampf(local_t / maxf(duration, 0.001), 0.0, 1.0)
			var current_frequency := lerpf(frequency, frequency_end, progress)
			phase += TAU * current_frequency / MIX_RATE
			var oscillator := sin(phase)
			if wave == &"triangle":
				oscillator = asin(sin(phase)) * (2.0 / PI)
			elif wave == &"square":
				oscillator = 1.0 if sin(phase) >= 0.0 else -1.0
			var noise_sample := rng.randf_range(-1.0, 1.0)
			var envelope := pow(1.0 - progress, 2.2) * minf(1.0, local_t * 180.0)
			sample = (oscillator * (1.0 - noise) + noise_sample * noise) * gain * envelope
		data.encode_s16(frame * 2, int(clampf(sample, -0.98, 0.98) * 32767.0))
	return _wav(data, frame_count, false)


func _make_music_stream(mode: StringName) -> AudioStreamWAV:
	# 32 seconds plus three phrase variants keeps exact repetition outside the
	# immediate attention window while retaining a quiet cultivation ambience.
	var duration := 32.0
	var frame_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for frame in frame_count:
		var t := float(frame) / MIX_RATE
		var sample := _music_sample(t, mode)
		data.encode_s16(frame * 2, int(clampf(sample, -0.78, 0.78) * 32767.0))
	return _wav(data, frame_count, true)


func _music_sample(t: float, mode: StringName) -> float:
	var bpm := 62.0
	var lead_gain := 0.040
	var drone_gain := 0.030
	var patterns: Array[Array] = [
		[261.63, 0.0, 329.63, 0.0, 392.0, 0.0, 329.63, 0.0, 293.66, 0.0, 392.0, 0.0, 440.0, 0.0, 329.63, 0.0],
		[329.63, 0.0, 392.0, 0.0, 440.0, 0.0, 392.0, 0.0, 261.63, 0.0, 293.66, 0.0, 392.0, 0.0, 293.66, 0.0],
		[293.66, 0.0, 329.63, 0.0, 523.25, 0.0, 392.0, 0.0, 329.63, 0.0, 293.66, 0.0, 261.63, 0.0, 0.0, 0.0],
	]
	if mode == &"hub":
		# The sect is a deliberate return space: a slightly wider breath and a
		# warmer pentatonic answer distinguish it from the title vow while keeping
		# the same quiet ink-and-paper identity.
		bpm = 68.0
		lead_gain = 0.036
		drone_gain = 0.026
		patterns = [
			[293.66, 0.0, 349.23, 0.0, 440.0, 0.0, 392.0, 0.0, 329.63, 0.0, 392.0, 0.0, 493.88, 0.0, 392.0, 0.0],
			[261.63, 0.0, 329.63, 0.0, 392.0, 0.0, 440.0, 0.0, 293.66, 0.0, 349.23, 0.0, 392.0, 0.0, 440.0, 0.0],
			[392.0, 0.0, 440.0, 0.0, 523.25, 0.0, 440.0, 0.0, 349.23, 0.0, 392.0, 0.0, 440.0, 0.0, 329.63, 0.0],
		]
	elif mode == &"combat":
		bpm = 84.0
		lead_gain = 0.052
		drone_gain = 0.036
		patterns = [
			[293.66, 0.0, 392.0, 440.0, 0.0, 392.0, 523.25, 0.0, 329.63, 0.0, 440.0, 493.88, 0.0, 392.0, 587.33, 0.0],
			[329.63, 0.0, 440.0, 493.88, 0.0, 440.0, 587.33, 0.0, 392.0, 0.0, 523.25, 659.25, 0.0, 493.88, 392.0, 0.0],
			[293.66, 392.0, 0.0, 440.0, 523.25, 0.0, 392.0, 0.0, 329.63, 440.0, 0.0, 493.88, 587.33, 0.0, 440.0, 0.0],
		]
	elif mode == &"result":
		bpm = 56.0
		lead_gain = 0.034
		patterns = [[261.63, 0.0, 329.63, 0.0, 392.0, 0.0, 523.25, 0.0, 392.0, 0.0, 329.63, 0.0, 293.66, 0.0, 261.63, 0.0]]
	var step_duration := 60.0 / bpm * 0.5
	var phrase_duration := step_duration * 16.0
	var phrase_index := int(floor(t / phrase_duration)) % patterns.size()
	var pattern: Array = patterns[phrase_index]
	var step_index := int(floor(t / step_duration)) % pattern.size()
	var within_step := fmod(t, step_duration)
	var frequency := float(pattern[step_index])
	var pluck := 0.0
	if frequency > 0.0:
		var envelope := exp(-within_step * 5.6) * minf(1.0, within_step * 90.0)
		pluck = asin(sin(TAU * frequency * t)) * (2.0 / PI) * envelope * lead_gain
	var drone_frequency: float = [65.41, 73.42, 82.41][phrase_index % 3]
	var drone := sin(TAU * drone_frequency * t) * drone_gain
	var air := sin(TAU * (drone_frequency * 1.502) * t + sin(t * 0.17)) * 0.012
	return pluck + drone + air


func _wav(data: PackedByteArray, frame_count: int, looped: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frame_count
	return stream


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")
