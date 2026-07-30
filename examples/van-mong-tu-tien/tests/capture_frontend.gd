extends Node

## Deterministic screenshot harness for every authored meta screen.
## Usage: Godot ... tests/capture_frontend.tscn -- title|hub|stages|loadout|inventory|spirit-beast|techniques|codex|achievements|settings|reset|results|results-defeat

const CAPTURE_DIR := "res://production/playtests/frontend"


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested := OS.get_environment("CGM_CAPTURE_SCREEN").to_lower()
	if requested.is_empty():
		requested = "title"
	var args := OS.get_cmdline_user_args()
	if requested == "title" and not args.is_empty():
		requested = str(args[0]).to_lower()
	var phone_landscape := OS.get_environment("CGM_CAPTURE_PHONE").to_lower() in ["1", "true", "yes"]
	if not phone_landscape:
		phone_landscape = args.size() > 1 and str(args[1]).to_lower() == "phone"
	var capture_size := Vector2i(844, 390) if phone_landscape else Vector2i(1600, 900)
	DisplayServer.window_set_size(capture_size)
	await get_tree().process_frame
	await get_tree().process_frame
	MetaProfile.auto_save = false
	MetaProfile.reset(false)
	MetaProfile.grant_currency(550)
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var frontend := game.get_node("FrontEnd") as CultivationFrontEnd
	print("CAPTURE LAYOUT: window=", DisplayServer.window_get_size(), " viewport=", get_viewport().get_visible_rect().size, " root=", frontend.root.size, " phone=", frontend.phone_layout_active)
	match requested:
		"hub":
			frontend._show_screen(frontend.SCREEN_HUB)
		"stages":
			frontend._show_screen(frontend.SCREEN_STAGES)
		"loadout":
			frontend._show_screen(frontend.SCREEN_LOADOUT)
		"inventory":
			frontend._show_screen(frontend.SCREEN_INVENTORY)
		"spirit-beast":
			frontend._show_screen(frontend.SCREEN_SPIRIT_BEAST)
		"techniques":
			frontend._show_screen(frontend.SCREEN_TECHNIQUES)
		"technique-upgrade":
			frontend._show_screen(frontend.SCREEN_TECHNIQUES)
			frontend._purchase_technique(&"sword_damage")
		"codex":
			MetaProfile.discover_bestiary(&"mac_linh")
			frontend._show_screen(frontend.SCREEN_CODEX)
		"achievements":
			MetaProfile.record_run(true, 64, 187.0)
			frontend._show_screen(frontend.SCREEN_ACHIEVEMENTS)
		"settings":
			frontend._show_screen(frontend.SCREEN_SETTINGS)
		"reset":
			frontend._show_screen(frontend.SCREEN_SETTINGS)
			frontend._show_reset_confirmation()
		"results", "results-defeat":
			frontend.run_elapsed = 187.0
			frontend.run_kills = 64
			frontend.last_victory = requested != "results-defeat"
			frontend.last_result_title = "PHI THĂNG THÀNH CÔNG" if frontend.last_victory else "ĐẠO TÂM TAN VỠ"
			frontend.last_result_details = "Đạo tâm đã vượt qua ma kiếp. Một cảnh giới mới đang chờ phía trước." if frontend.last_victory else "Ma khí lấn át đạo tâm. Giữ căn cơ đã lĩnh ngộ và nhập thế lại."
			frontend.last_result = {
				"total": 248 if frontend.last_victory else 46,
				"first_clear": frontend.last_victory,
				"first_clear_bonus": 100 if frontend.last_victory else 0,
				"new_unlocks": ["huyet_van"] if frontend.last_victory else [],
				"new_achievements": ["nhap_dao", "pha_vân_mộng"] if frontend.last_victory else [],
			}
			frontend._show_screen(frontend.SCREEN_RESULTS)
		_:
			frontend._show_screen(frontend.SCREEN_TITLE)
	await get_tree().process_frame
	await get_tree().process_frame
	# Rank ascension deliberately fades in. Capture the fully presented ritual,
	# not the translucent first animation frames where the underlying folios can
	# bleed through and create a false text-overlap finding.
	if requested == "technique-upgrade":
		await get_tree().create_timer(0.24, true, false, true).timeout
	var viewport_image := get_viewport().get_texture().get_image()
	if viewport_image != null and not viewport_image.is_empty():
		var output := viewport_image
		if output.get_width() != capture_size.x or output.get_height() != capture_size.y:
			output = output.duplicate()
			output.resize(capture_size.x, capture_size.y, Image.INTERPOLATE_LANCZOS)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
		var output_name := "%s-phone" % requested if phone_landscape else requested
		var output_path := "%s/%s.png" % [CAPTURE_DIR, output_name]
		output.save_png(output_path)
		print("CAPTURED: ", output_path, " ", output.get_width(), "x", output.get_height())
	else:
		push_error("Front-end capture failed")
	AudioDirector.shutdown()
	await get_tree().create_timer(0.08, true, false, true).timeout
	get_tree().quit(0)
