extends Node

const OUTPUT_ROOT := "res://assets/generated/audio"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	for mode: StringName in [&"title", &"hub", &"combat", &"result"]:
		var stream := AudioDirector._make_music_stream(mode) as AudioStreamWAV
		var target_without_extension := "%s/music_%s" % [OUTPUT_ROOT, mode]
		var error := stream.save_to_wav(target_without_extension)
		if error != OK:
			push_error("Failed to save %s: %s" % [target_without_extension, error_string(error)])
			get_tree().quit(1)
			return
		print("GENERATED: ", target_without_extension, ".wav")
	get_tree().quit(0)
