extends Node

const CAPTURE_DIR := "res://production/playtests/mobile-support"
const ArenaTexture: Texture2D = preload("res://assets/generated/environments/ARENA-001-cloud-ring/arena-ground-1600x900-v001.webp")
const ControlsScene := preload("res://scenes/ui/mobile_touch_controls.tscn")
const RotateScene := preload("res://scenes/ui/rotate_device_overlay.tscn")


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested_state := "landscape-controls"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and str(args[0]).to_lower() == "portrait":
		requested_state = "portrait-overlay"
	DisplayServer.window_set_size(Vector2i(900, 1600) if requested_state == "portrait-overlay" else Vector2i(1600, 900))
	await get_tree().process_frame
	await get_tree().process_frame
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = ArenaTexture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(background)

	var surface: Variant
	if requested_state == "portrait-overlay":
		surface = RotateScene.instantiate()
		get_tree().root.add_child(surface)
		surface.set_orientation_size_override(Vector2(900.0, 1600.0))
		# With canvas_items + expand the Control's logical size is wider/taller
		# than the physical 900x1600 window. Feed safe-area coordinates in that
		# same logical space so the capture validates the real shipping transform.
		var layout_size: Vector2 = surface.size
		surface.set_safe_area_override(Rect2(layout_size * Vector2(0.049, 0.051), layout_size * Vector2(0.902, 0.895)))
	else:
		surface = ControlsScene.instantiate()
		get_tree().root.add_child(surface)
		surface.set_force_visible_for_test(true)
		surface.set_viewport_size_override(Vector2(1600.0, 900.0))
		surface.set_safe_area_override(Rect2(38.0, 22.0, 1524.0, 856.0))
	await get_tree().process_frame
	await get_tree().process_frame
	if requested_state == "portrait-overlay":
		print("PORTRAIT LAYOUT: control=", surface.size, " safe=", surface.get_safe_area_rect(), " message=", surface.get_message_rect())
	await get_tree().create_timer(0.18, true, false, true).timeout

	var viewport_image := get_viewport().get_texture().get_image()
	if viewport_image != null and not viewport_image.is_empty():
		var output := viewport_image.duplicate()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
		var output_path := "%s/%s.png" % [CAPTURE_DIR, requested_state]
		output.save_png(output_path)
		print("CAPTURED: ", output_path, " ", output.get_width(), "x", output.get_height())
	else:
		push_error("Mobile support capture failed: viewport image unavailable")
	if surface.has_method("release_all_inputs"):
		surface.release_all_inputs()
	surface.queue_free()
	background.queue_free()
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null and audio_director.has_method("shutdown"):
		audio_director.call("shutdown")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.10, true, false, true).timeout
	get_tree().quit(0)
