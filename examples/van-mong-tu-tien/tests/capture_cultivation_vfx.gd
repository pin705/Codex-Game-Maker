extends Node

## Renderer-backed evidence for the three permanent cultivation silhouettes.
## Usage: Godot ... capture_cultivation_vfx.tscn -- sword|jade|qi rank1|rank5

const CAPTURE_DIR := "res://production/playtests/vfx"
const EnemyScript := preload("res://scripts/gameplay/enemy.gd")


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var requested := "sword"
	var requested_rank := 5
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		requested = str(args[0]).to_lower()
		# Also accept the compact `sword-rank1` spelling for local evidence work.
		if requested.ends_with("-rank1") or requested.ends_with("-rank5"):
			requested_rank = 1 if requested.ends_with("-rank1") else 5
			requested = requested.trim_suffix("-rank%d" % requested_rank)
	if args.size() >= 2:
		var rank_arg := str(args[1]).to_lower().trim_prefix("rank")
		if rank_arg.is_valid_int() and int(rank_arg) in [1, 5]:
			requested_rank = int(rank_arg)
	if requested not in ["sword", "jade", "qi"]:
		requested = "sword"

	DisplayServer.window_set_size(Vector2i(1600, 900))
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

	game.elapsed = 96.0
	game.kills = 27
	game.first_event_triggered = true
	game.spawn_clock = 9999.0
	game.xp_required = 9999.0
	Events.run_stats_changed.emit(game.elapsed, game.duration, game.kills)
	game.get_node("HUD").banner_panel.hide()
	game.get_node("HUD").banner_remaining = 0.0

	var center: Vector2 = game.player.global_position
	var kinds := [
		EnemyScript.EnemyKind.WISP,
		EnemyScript.EnemyKind.BEAST,
		EnemyScript.EnemyKind.DEMON,
	]
	for index in 9:
		var angle := TAU * float(index) / 9.0 + 0.18
		var radius := 190.0 + float(index % 2) * 72.0
		game._spawn_enemy(kinds[index % kinds.size()], center + Vector2.from_angle(angle) * radius)
	for index in 5:
		var angle := TAU * float(index) / 5.0 + 0.36
		game._spawn_qi_orb(center + Vector2.from_angle(angle) * 108.0, 5.0)
	# Let actor spawn ink settle before firing the technique beat. This keeps the
	# comparison honest: full-opacity threats around a branch-specific effect.
	await get_tree().create_timer(0.62, true, false, true).timeout

	match requested:
		"jade":
			game.cultivation_vfx.configure(&"ngoc_the", {"sword_damage": 0, "vitality": requested_rank, "magnet": 0})
			game.cultivation_vfx.trigger_hit(Vector2.LEFT)
		"qi":
			game.cultivation_vfx.configure(&"tu_linh", {"sword_damage": 0, "vitality": 0, "magnet": requested_rank})
			game.cultivation_vfx.trigger_pickup(center + Vector2(250.0, -145.0))
		_:
			game.cultivation_vfx.configure(&"van_kiem", {"sword_damage": requested_rank, "vitality": 0, "magnet": 0})
			game.cultivation_vfx.trigger_attack(Vector2.RIGHT)

	# Capture close to the transient peak while retaining the persistent rank
	# silhouette and the real HUD/world scale around it.
	await get_tree().create_timer(0.10, true, false, true).timeout
	await get_tree().process_frame
	var viewport_image := get_viewport().get_texture().get_image()
	if viewport_image != null and not viewport_image.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
		var output_path := "%s/%s-rank%d.png" % [CAPTURE_DIR, requested, requested_rank]
		viewport_image.save_png(output_path)
		print("CAPTURED: ", output_path, " ", viewport_image.get_width(), "x", viewport_image.get_height())
	else:
		push_error("Cultivation VFX capture failed")

	AudioDirector.shutdown()
	await get_tree().create_timer(0.08, true, false, true).timeout
	get_tree().quit(0)
