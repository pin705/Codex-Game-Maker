extends Node

const MainScript := preload("res://scripts/gameplay/main.gd")

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	MetaProfile.auto_save = false
	MetaProfile.reset(false)
	MetaProfile.grant_currency(700)
	var packed: PackedScene = load("res://scenes/main.tscn")
	_expect(packed != null, "main scene loads")
	if packed == null:
		_finish()
		return
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var frontend := game.get_node("FrontEnd") as CultivationFrontEnd
	_expect(frontend != null, "front end exists")
	_expect(frontend.screen_name == frontend.SCREEN_TITLE and frontend.root.visible, "flow begins at title")

	frontend._show_screen(frontend.SCREEN_HUB)
	await get_tree().process_frame
	_expect(frontend.screen_name == frontend.SCREEN_HUB, "title enters hub")
	_expect(_count_focusable(frontend.screen_root) >= 6, "hub exposes focusable navigation")
	_expect(_all_targets_are_large(frontend.screen_root), "hub targets meet 48px minimum")

	frontend._show_screen(frontend.SCREEN_STAGES)
	await get_tree().process_frame
	_expect(MetaProfile.get_stages().size() == 3, "stage select presents three stages")
	_expect(not MetaProfile.select_stage(&"huyet_van"), "locked second stage cannot be selected")

	frontend._show_screen(frontend.SCREEN_LOADOUT)
	await get_tree().process_frame
	_expect(MetaProfile.select_discipline(&"tu_linh"), "loadout changes discipline")
	_expect(MetaProfile.selected_discipline == &"tu_linh", "discipline selection persists")

	frontend._show_screen(frontend.SCREEN_TECHNIQUES)
	await get_tree().process_frame
	var before_rank := int(MetaProfile.technique_ranks.get("sword_damage", 0))
	_expect(MetaProfile.purchase_technique(&"sword_damage"), "permanent technique can be purchased")
	_expect(int(MetaProfile.technique_ranks.get("sword_damage", 0)) == before_rank + 1, "purchase increments rank")

	for screen_id: StringName in [frontend.SCREEN_INVENTORY, frontend.SCREEN_SPIRIT_BEAST, frontend.SCREEN_CODEX, frontend.SCREEN_ACHIEVEMENTS, frontend.SCREEN_SETTINGS]:
		frontend._show_screen(screen_id)
		await get_tree().process_frame
		_expect(frontend.screen_root.get_child_count() > 4, "%s screen has authored content" % screen_id)
	frontend._show_reset_confirmation()
	await get_tree().process_frame
	var reset_modal := frontend.root.get_node_or_null("ResetConfirmation") as Control
	_expect(reset_modal != null and _all_targets_are_large(reset_modal), "profile reset uses a guarded accessible confirmation")
	frontend._close_reset_confirmation(reset_modal)
	await get_tree().process_frame
	_expect(frontend.root.get_node_or_null("ResetConfirmation") == null, "reset confirmation can be canceled safely")

	frontend._show_screen(frontend.SCREEN_LOADOUT)
	frontend._start_selected_run()
	await get_tree().process_frame
	_expect(game.state == MainScript.GameState.RUNNING, "loadout starts combat")
	_expect(not frontend.root.visible, "front end clears the combat playfield")
	_expect(game.player.xp_multiplier > 1.0, "selected discipline modifies combat")
	game.elapsed = 125.0
	game.kills = 42
	Events.run_stats_changed.emit(game.elapsed, game.duration, game.kills)
	game._finish_run(true)
	await get_tree().process_frame
	_expect(frontend.screen_name == frontend.SCREEN_RESULTS and frontend.root.visible, "combat ends on results")
	_expect(int(frontend.last_result.get("total", 0)) > 0, "results grant a structured reward")
	_expect(MetaProfile.runs == 1 and MetaProfile.victories == 1, "run is recorded exactly once")
	_expect(MetaProfile.is_stage_unlocked(&"huyet_van"), "first victory unlocks second stage")

	game.queue_free()
	await get_tree().process_frame
	for cycle in 3:
		MetaProfile.pending_screen = &"hub"
		var reload_game := packed.instantiate()
		get_tree().root.add_child(reload_game)
		await get_tree().process_frame
		await get_tree().process_frame
		var reload_frontend := reload_game.get_node("FrontEnd") as CultivationFrontEnd
		_expect(reload_frontend.screen_name == reload_frontend.SCREEN_HUB, "reload %d restores hub" % (cycle + 1))
		reload_game.queue_free()
		await get_tree().process_frame
	_finish()


func _count_focusable(node: Node) -> int:
	var count := 0
	if node is Control and (node as Control).focus_mode == Control.FOCUS_ALL:
		count += 1
	for child in node.get_children():
		count += _count_focusable(child)
	return count


func _all_targets_are_large(node: Node) -> bool:
	if node is BaseButton:
		var button := node as BaseButton
		if button.size.x < 48.0 or button.size.y < 48.0:
			return false
	for child in node.get_children():
		if not _all_targets_are_large(child):
			return false
	return true


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("FRONTEND FLOW RESULT: PASS")
		get_tree().quit(0)
	else:
		print("FRONTEND FLOW RESULT: FAIL (", failures.size(), ")")
		get_tree().quit(1)
