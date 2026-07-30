extends Node

const CAPTURE_DIR := "res://production/playtests"
const CAPTURE_PATH := CAPTURE_DIR + "/title-screen-headless.png"

func _ready() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_image := get_viewport().get_texture().get_image()
	if viewport_image != null and not viewport_image.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
		viewport_image.save_png(CAPTURE_PATH)
		print("CAPTURED: production/playtests/title-screen-headless.png ", viewport_image.get_width(), "x", viewport_image.get_height())
	else:
		print("CAPTURE FAILED: viewport image unavailable")
	AudioDirector.shutdown()
	await get_tree().create_timer(0.08, true, false, true).timeout
	get_tree().quit(0)
