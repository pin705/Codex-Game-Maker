extends Node

const OUTPUT_DIR := "res://production/playtests/responsive"


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested := "hub-wide"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var mode := str(args[0]).to_lower()
		if mode.contains("combat"):
			requested = "combat-wide-touch"
		elif mode.contains("reset"):
			requested = "reset-wide"
	DisplayServer.window_set_size(Vector2i(2100, 900))
	await get_tree().process_frame
	await get_tree().process_frame

	MetaProfile.auto_save = false
	MetaProfile.reset(false)
	MetaProfile.grant_currency(700)
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	if requested == "hub-wide":
		var frontend := game.get_node("FrontEnd") as CultivationFrontEnd
		frontend._show_screen(frontend.SCREEN_HUB)
	elif requested == "reset-wide":
		var frontend := game.get_node("FrontEnd") as CultivationFrontEnd
		frontend._show_screen(frontend.SCREEN_SETTINGS)
		frontend._show_reset_confirmation()
	else:
		game._start_run()
		await get_tree().process_frame
		game.get_node("MobileSupportLayer").set_force_mobile_preview(true)
		var helper: Node = load("res://tests/capture_state.gd").new()
		helper._populate_gameplay(game)
		helper.free()
		game.get_node("HUD").banner_panel.hide()
		game.get_node("HUD").banner_remaining = 0.0
	await get_tree().create_timer(0.32, true, false, true).timeout
	var image := get_viewport().get_texture().get_image()
	if image != null and not image.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		var output_path := "%s/%s.png" % [OUTPUT_DIR, requested]
		image.save_png(output_path)
		print("CAPTURED: ", output_path, " ", image.get_width(), "x", image.get_height())
	else:
		push_error("Responsive capture failed")
	AudioDirector.shutdown()
	await get_tree().create_timer(0.08, true, false, true).timeout
	get_tree().quit(0)
