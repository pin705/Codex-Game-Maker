extends Node

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var tone := AudioDirector._make_tone_stream(220.0, 660.0, 0.18, 0.2, &"triangle", 0.05, 0.02) as AudioStreamWAV
	_expect(tone != null, "tone stream synthesizes")
	_expect(tone.data.size() > 4000, "tone contains PCM samples")
	_expect(_has_nonzero_pcm(tone.data), "tone PCM is not silent")
	var music := AudioDirector._make_music_stream(&"combat") as AudioStreamWAV
	_expect(music != null, "combat score synthesizes")
	_expect(music.loop_mode == AudioStreamWAV.LOOP_FORWARD, "score loops seamlessly")
	_expect(music.loop_end == int(32.0 * AudioDirector.MIX_RATE), "score has a 32 second anti-repetition loop")
	_expect(_has_nonzero_pcm(music.data), "score PCM is not silent")
	for mode: StringName in [&"title", &"hub", &"combat", &"result"]:
		var path := str(AudioDirector.MUSIC_PATHS[mode])
		_expect(ResourceLoader.exists(path), "%s shipping loop is imported" % mode)
		var shipping := AudioDirector._load_or_make_music(mode) as AudioStreamWAV
		_expect(shipping.data.size() > 100000 and shipping.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s shipping loop has PCM and loop metadata" % mode)
	var title_shipping := AudioDirector._load_or_make_music(&"title") as AudioStreamWAV
	var hub_shipping := AudioDirector._load_or_make_music(&"hub") as AudioStreamWAV
	_expect(not _same_pcm(title_shipping.data, hub_shipping.data), "title and hub shipping loops are distinct arrangements")
	_expect(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "music and SFX buses exist")
	if failures.is_empty():
		print("AUDIO RESULT: PASS")
		get_tree().quit(0)
	else:
		print("AUDIO RESULT: FAIL (", failures.size(), ")")
		get_tree().quit(1)


func _has_nonzero_pcm(data: PackedByteArray) -> bool:
	for index in range(0, data.size() - 1, 2):
		if data.decode_s16(index) != 0:
			return true
	return false


func _same_pcm(left: PackedByteArray, right: PackedByteArray) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if left[index] != right[index]:
			return false
	return true


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		print("FAIL: ", label)
