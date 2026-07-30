extends Node

const BackgroundScript := preload("res://scripts/gameplay/ink_background.gd")


## The headless display driver intentionally ignores window resize requests.
## Keep the quality-runner path honest by overriding only the physical-window
## query in a test-local subclass; every layout builder, transform and modal
## remains the production CultivationFrontEnd implementation. Native runs use
## the scene's real FrontEnd node and never touch this fallback.
class HeadlessPhoneFrontEnd:
	extends CultivationFrontEnd

	var simulated_window_size := Vector2(844.0, 390.0)

	func _physical_window_size() -> Vector2:
		return simulated_window_size

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var background := BackgroundScript.new() as InkBackground
	add_child(background)
	var wide_region := background.source_region_for_target(Vector2(1600.0, 900.0), Vector2(2100.0, 900.0))
	_expect(is_equal_approx(wide_region.size.x / wide_region.size.y, 2100.0 / 900.0), "21:9 source crop preserves target aspect")
	_expect(is_equal_approx(wide_region.size.x, 1600.0) and wide_region.size.y < 900.0, "ultrawide cover crops vertically instead of stretching")
	_expect(is_equal_approx(wide_region.position.y * 2.0 + wide_region.size.y, 900.0), "ultrawide crop remains centered")
	var portrait_region := background.source_region_for_target(Vector2(1600.0, 900.0), Vector2(900.0, 1600.0))
	_expect(portrait_region.size.x < 1600.0 and is_equal_approx(portrait_region.size.y, 900.0), "portrait cover crops horizontally instead of stretching")
	background.queue_free()

	MetaProfile.auto_save = false
	MetaProfile.reset(false)
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var frontend := game.get_node("FrontEnd") as CultivationFrontEnd
	frontend.root.size = Vector2(2100.0, 900.0)
	frontend._layout_design_canvas()
	_expect(frontend.screen_root.position.is_equal_approx(Vector2(250.0, 0.0)), "16:9 menu canvas centers inside true 21:9 viewport")
	_expect(frontend.screen_root.scale.is_equal_approx(Vector2.ONE), "ultrawide menu avoids nine-slice stretching")
	frontend._show_screen(frontend.SCREEN_SETTINGS)
	frontend._show_reset_confirmation()
	var reset_overlay := frontend.root.get_node_or_null("ResetConfirmation") as Control
	var reset_canvas := frontend.root.get_node_or_null("ResetConfirmation/DialogCanvas") as Control
	_expect(reset_overlay != null and reset_overlay.size.is_equal_approx(Vector2(2100.0, 900.0)), "reset shade covers the full 21:9 viewport")
	_expect(reset_canvas != null and reset_canvas.position.is_equal_approx(Vector2(250.0, 0.0)), "reset dialog canvas centers with the 16:9 menu at 21:9")
	_expect(reset_canvas != null and reset_canvas.scale.is_equal_approx(Vector2.ONE), "reset dialog avoids independent ultrawide stretching")
	reset_overlay.queue_free()
	frontend._show_rank_ascension(&"sword_damage", 1)
	var ascension_overlay := frontend.root.get_node_or_null("RankAscension") as Control
	var ascension_canvas := frontend.root.get_node_or_null("RankAscension/DialogCanvas") as Control
	_expect(ascension_overlay != null and ascension_overlay.size.is_equal_approx(Vector2(2100.0, 900.0)), "rank ascension shade covers the full 21:9 viewport")
	_expect(ascension_canvas != null and ascension_canvas.position.is_equal_approx(Vector2(250.0, 0.0)), "rank ascension ritual centers inside 21:9")
	frontend.root.size = Vector2(1280.0, 720.0)
	frontend._layout_design_canvas()
	_expect(frontend.screen_root.scale.is_equal_approx(Vector2(0.8, 0.8)), "small landscape viewport scales the full menu uniformly")
	_expect(frontend.screen_root.position.is_equal_approx(Vector2.ZERO), "16:9 small viewport remains centered without drift")
	_expect(reset_canvas != null and reset_canvas.scale.is_equal_approx(Vector2(0.8, 0.8)), "reset dialog follows small-landscape scale")
	_expect(reset_canvas != null and reset_canvas.position.is_equal_approx(Vector2.ZERO), "reset dialog remains centered at 1280x720")
	_expect(ascension_canvas != null and ascension_canvas.scale.is_equal_approx(Vector2(0.8, 0.8)), "rank ascension follows small-landscape scale")

	var hud := game.get_node("HUD") as CultivationHUD
	hud.root_control.size = Vector2(1600.0, 900.0)
	var mobile_safe := Rect2(118.0, 45.0, 1380.0, 810.0)
	hud.set_mobile_safe_area(mobile_safe, true)
	var life_rect := Rect2(hud.life_plaque.position, hud.life_plaque.size)
	var time_rect := Rect2(hud.time_plaque.position, hud.time_plaque.size)
	var objective_rect := Rect2(hud.objective_strip.position, hud.objective_strip.size)
	var pulse_rect := Rect2(hud.pulse_plaque.position, hud.pulse_plaque.size)
	_expect(mobile_safe.encloses(life_rect), "mobile safe area encloses life HUD")
	_expect(mobile_safe.encloses(time_rect), "mobile safe area encloses timer HUD with pause reserve")
	_expect(mobile_safe.encloses(objective_rect), "mobile safe area encloses objective HUD outside left thumb zone")
	_expect(mobile_safe.encloses(pulse_rect), "mobile safe area encloses skill cooldown HUD")

	game.player.health = 77.0
	game.player.update_bounds(Rect2(80.0, 54.0, 1790.0, 792.0))
	_expect(is_equal_approx(game.player.health, 77.0), "responsive bounds update never resets player health")
	_expect(str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "disabled", "project renders phone UI at native device resolution")
	_expect(game.get_node_or_null("MobileSupportLayer") != null, "responsive runtime includes mobile lifecycle layer")
	game.queue_free()
	await get_tree().process_frame

	# Validate the real phone-landscape branch through DisplayServer. Native
	# rendering keeps the Control root at 844x390 so text and raster chrome are
	# never downsampled from the old 1947x900 expanded canvas.
	var phone_size := Vector2(844.0, 390.0)
	DisplayServer.window_set_size(Vector2i(phone_size))
	await get_tree().process_frame
	await get_tree().process_frame
	MetaProfile.reset(false)
	MetaProfile.grant_currency(700)
	var display_phone_available := DisplayServer.window_get_size() == Vector2i(844, 390)
	var headless_fallback := DisplayServer.get_name().to_lower() == "headless"
	_expect(display_phone_available or headless_fallback, "phone DisplayServer request is active or uses the explicit headless fallback")
	var phone_owner: Node
	var phone_frontend: CultivationFrontEnd
	if display_phone_available:
		var native_phone_game := packed.instantiate()
		phone_owner = native_phone_game
		get_tree().root.add_child(native_phone_game)
		await get_tree().process_frame
		await get_tree().process_frame
		phone_frontend = native_phone_game.get_node("FrontEnd") as CultivationFrontEnd
	else:
		var harness := HeadlessPhoneFrontEnd.new()
		harness.simulated_window_size = phone_size
		phone_owner = harness
		get_tree().root.add_child(harness)
		await get_tree().process_frame
		await get_tree().process_frame
		harness.root.size = phone_size
		phone_frontend = harness
	phone_frontend._layout_design_canvas()
	_expect(phone_frontend.phone_layout_active, "844x390 activates the dedicated phone meta layout")
	_expect(phone_frontend.screen_root.size.is_equal_approx(phone_size), "phone screen_root uses an 844x390 local canvas")
	var expected_phone_scale := minf(phone_frontend.root.size.x / phone_size.x, phone_frontend.root.size.y / phone_size.y)
	var expected_phone_position := (phone_frontend.root.size - phone_size * expected_phone_scale) * 0.5
	_expect(is_equal_approx(expected_phone_scale, 1.0) and phone_frontend.screen_root.scale.is_equal_approx(Vector2.ONE), "phone screen_root renders one logical pixel per device pixel")
	_expect(phone_frontend.screen_root.position.is_equal_approx(expected_phone_position), "phone screen_root remains centered after compensation")

	phone_frontend.last_victory = true
	phone_frontend.last_result_title = "PHI THĂNG THÀNH CÔNG"
	phone_frontend.last_result_details = "Đạo tâm đã vượt qua ma kiếp."
	phone_frontend.last_result = {"total": 120, "first_clear": true, "new_unlocks": ["huyet_van"]}
	var phone_screens := [
		{"id": "title", "screen": phone_frontend.SCREEN_TITLE},
		{"id": "hub", "screen": phone_frontend.SCREEN_HUB},
		{"id": "stages", "screen": phone_frontend.SCREEN_STAGES},
		{"id": "loadout", "screen": phone_frontend.SCREEN_LOADOUT},
		{"id": "inventory", "screen": phone_frontend.SCREEN_INVENTORY},
		{"id": "spirit-beast", "screen": phone_frontend.SCREEN_SPIRIT_BEAST},
		{"id": "techniques", "screen": phone_frontend.SCREEN_TECHNIQUES},
		{"id": "codex", "screen": phone_frontend.SCREEN_CODEX},
		{"id": "achievements", "screen": phone_frontend.SCREEN_ACHIEVEMENTS},
		{"id": "settings", "screen": phone_frontend.SCREEN_SETTINGS},
		{"id": "results", "screen": phone_frontend.SCREEN_RESULTS},
	]
	for entry: Dictionary in phone_screens:
		var state_id := StringName(str(entry.get("screen", "")))
		var state_label := str(entry.get("id", state_id))
		phone_frontend._show_screen(state_id)
		await get_tree().process_frame
		_expect(phone_frontend.phone_layout_active and phone_frontend.screen_name == state_id, "phone meta screen builds: %s" % state_label)
		_assert_minimum_phone_button_height(phone_frontend.screen_root, state_label)

	# Rebuild the exact surface where the served-Web review found the leading
	# balance digit clipped, then compare the field against the rendered text.
	phone_frontend._show_screen(phone_frontend.SCREEN_INVENTORY)
	await get_tree().process_frame
	var phone_currency := phone_frontend.screen_root.get_node_or_null("PhoneCurrency") as Label
	_expect(phone_currency != null, "phone inventory exposes the shared currency header")
	if phone_currency != null:
		var currency_font := phone_currency.get_theme_font(&"font")
		var currency_text_width := currency_font.get_string_size(phone_currency.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, phone_currency.get_theme_font_size(&"font_size")).x
		var currency_outline := float(phone_currency.get_theme_constant(&"outline_size")) * 2.0
		_expect(phone_currency.size.x + 0.01 >= currency_text_width + currency_outline, "phone currency field fits every rendered balance digit")

	phone_frontend._show_screen(phone_frontend.SCREEN_SETTINGS)
	await get_tree().process_frame
	phone_frontend._show_reset_confirmation()
	var phone_reset_overlay := phone_frontend.root.get_node_or_null("ResetConfirmation") as Control
	var phone_reset_canvas := phone_frontend.root.get_node_or_null("ResetConfirmation/DialogCanvas") as Control
	_expect(phone_reset_canvas != null and phone_reset_canvas.size.is_equal_approx(phone_size), "phone reset DialogCanvas is 844x390")
	if phone_reset_overlay != null:
		phone_reset_overlay.queue_free()
	await get_tree().process_frame

	phone_frontend._show_rank_ascension(&"sword_damage", 1)
	var phone_ascension_overlay := phone_frontend.root.get_node_or_null("RankAscension") as Control
	var phone_ascension_canvas := phone_frontend.root.get_node_or_null("RankAscension/DialogCanvas") as Control
	_expect(phone_ascension_canvas != null and phone_ascension_canvas.size.is_equal_approx(phone_size), "phone rank ascension DialogCanvas is 844x390")
	if phone_ascension_overlay != null:
		phone_ascension_overlay.queue_free()
	phone_owner.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		print("FAIL: ", label)


func _assert_minimum_phone_button_height(node: Node, state_label: String) -> void:
	var buttons: Array[BaseButton] = []
	_collect_base_buttons(node, buttons)
	_expect(not buttons.is_empty(), "phone %s exposes at least one BaseButton" % state_label)
	for button in buttons:
		var button_path := str(node.get_path_to(button))
		_expect(button.size.y + 0.01 >= 64.0, "phone %s target %s is at least 64 local px high" % [state_label, button_path])


func _collect_base_buttons(node: Node, output: Array[BaseButton]) -> void:
	for child in node.get_children():
		if child is BaseButton:
			output.append(child as BaseButton)
		_collect_base_buttons(child, output)


func _finish() -> void:
	if failures.is_empty():
		print("RESPONSIVE LAYOUT RESULT: PASS")
		get_tree().quit(0)
	else:
		print("RESPONSIVE LAYOUT RESULT: FAIL (", failures.size(), ")")
		get_tree().quit(1)
