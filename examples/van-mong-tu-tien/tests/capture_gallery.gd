extends Node

## Deterministic still-capture harness for the visual acceptance pass.
## Usage: Godot ... tests/capture_gallery.tscn -- gameplay|boss|upgrade|pause|victory|defeat|title

const CAPTURE_DIR := "res://production/playtests/overhaul"
const EnemyScript := preload("res://scripts/gameplay/enemy.gd")
const EffectScript := preload("res://scripts/gameplay/game_effect.gd")

func _ready() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var requested_state := "gameplay"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		requested_state = str(args[0]).to_lower()
	DisplayServer.window_set_size(Vector2i(1600, 900))
	await get_tree().process_frame
	await get_tree().process_frame

	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	if requested_state != "title":
		game._start_run()
		await get_tree().process_frame
		var helper: Node = load("res://tests/capture_state.gd").new()
		match requested_state:
			"gameplay":
				helper._populate_gameplay(game)
			"boss":
				helper._populate_boss(game)
			"upgrade":
				game._on_qi_collected(game.xp_required)
			"pause":
				game._pause_run()
			"victory":
				game.elapsed = 226.0
				game.kills = 118
				Events.run_stats_changed.emit(game.elapsed, game.duration, game.kills)
				game._finish_run(true)
			"defeat":
				game.elapsed = 74.0
				game.kills = 19
				Events.run_stats_changed.emit(game.elapsed, game.duration, game.kills)
				game._finish_run(false)
			_:
				helper._populate_gameplay(game)
		helper.free()

		# Remove the transient event banner from evidence frames, while leaving
		# the authored arena, sprites and persistent HUD visible.
		game.get_node("HUD").banner_panel.hide()
		game.get_node("HUD").banner_remaining = 0.0

	# Let the scene settle, then remove only transient spawn portals from the
	# evidence frame and place one readable authored sword/hit beat on running
	# states. This keeps the screenshot composed without changing game rules.
	await get_tree().create_timer(0.72, true, false, true).timeout
	_clear_portal_effects(game)
	if requested_state == "gameplay" or requested_state == "boss":
		game._fire_auto_swords()
		var nearest: Node2D = game._nearest_enemy() as Node2D
		if nearest != null:
			game._spawn_effect(nearest.global_position, EffectScript.EffectKind.HIT, Color("#63dfb4"), 30.0, 0.5)
		await get_tree().process_frame
	var viewport_image := get_viewport().get_texture().get_image()
	if viewport_image != null and not viewport_image.is_empty():
		var output := viewport_image
		if output.get_width() != 1600 or output.get_height() != 900:
			output = output.duplicate()
			output.resize(1600, 900, Image.INTERPOLATE_LANCZOS)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
		var output_path := "%s/%s-final.png" % [CAPTURE_DIR, requested_state]
		output.save_png(output_path)
		print("CAPTURED: ", output_path, " ", output.get_width(), "x", output.get_height())
	else:
		print("CAPTURE FAILED: viewport image unavailable")
	AudioDirector.shutdown()
	await get_tree().create_timer(0.08, true, false, true).timeout
	get_tree().quit(0)

func _clear_portal_effects(game: Node) -> void:
	for child in game.get_node("World/Effects").get_children():
		var effect := child as GameEffect
		if effect != null and effect.kind == GameEffect.EffectKind.PORTAL:
			effect.queue_free()
