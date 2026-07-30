extends Node

## Renderer-backed 844x390 evidence for the actual mobile combat journey.
## Usage: Godot ... capture_phone_gameplay.tscn -- combat|boss|breakthrough|pause

const OUTPUT_DIR := "res://production/playtests/mobile-support"


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested := "combat"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		requested = str(args[0]).to_lower()
	if requested not in ["combat", "boss", "breakthrough", "pause"]:
		requested = "combat"
	DisplayServer.window_set_size(Vector2i(844, 390))
	await get_tree().process_frame
	await get_tree().process_frame
	MetaProfile.auto_save = false
	MetaProfile.reset(false)
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._start_run()
	await get_tree().process_frame
	var support := game.get_node("MobileSupportLayer")
	support.set_force_mobile_preview(true)
	var helper: Node = load("res://tests/capture_state.gd").new()
	match requested:
		"boss":
			helper._populate_boss(game)
		"breakthrough":
			game._on_qi_collected(game.xp_required)
		"pause":
			helper._populate_gameplay(game)
			game._pause_run()
		_:
			helper._populate_gameplay(game)
	helper.free()
	game.get_node("HUD").banner_panel.hide()
	game.get_node("HUD").banner_remaining = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.32, true, false, true).timeout
	var controls: Variant = support.get_touch_controls()
	print("PHONE COMBAT LAYOUT: viewport=", get_viewport().get_visible_rect().size, " controls=", controls.get_layout_snapshot())
	var hud := game.get_node("HUD") as CultivationHUD
	print("PHONE HUD RECTS: life=", Rect2(hud.life_plaque.position, hud.life_plaque.size), " pulse=", Rect2(hud.pulse_plaque.position, hud.pulse_plaque.size), " time=", Rect2(hud.time_plaque.position, hud.time_plaque.size), " root=", hud.root_control.size)
	var image := get_viewport().get_texture().get_image()
	if image != null and not image.is_empty():
		var output := image.duplicate()
		if output.get_width() != 844 or output.get_height() != 390:
			output.resize(844, 390, Image.INTERPOLATE_LANCZOS)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		var output_path := "%s/%s-phone.png" % [OUTPUT_DIR, requested]
		output.save_png(output_path)
		print("CAPTURED: ", output_path, " ", output.get_width(), "x", output.get_height())
	else:
		push_error("Phone gameplay capture failed")
	controls.release_all_inputs()
	AudioDirector.shutdown()
	await get_tree().create_timer(0.08, true, false, true).timeout
	get_tree().quit(0)
