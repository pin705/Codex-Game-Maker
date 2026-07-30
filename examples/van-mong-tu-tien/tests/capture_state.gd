extends Node

const EnemyScript := preload("res://scripts/gameplay/enemy.gd")

func _ready() -> void:
	call_deferred("_setup_capture")

func _setup_capture() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game._start_run()
	await get_tree().process_frame
	game.get_node("HUD").banner_panel.hide()
	game.get_node("HUD").banner_remaining = 0.0

	var requested_state := "gameplay"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		requested_state = str(args[0])
	match requested_state:
		"upgrade":
			game._on_qi_collected(game.xp_required)
		"boss":
			_populate_boss(game)
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
			_populate_gameplay(game)
	# The start banner is useful in the live game but would obscure the visual
	# audit frames; keep all capture states focused on the authored playfield.
	game.get_node("HUD").banner_panel.hide()
	game.get_node("HUD").banner_remaining = 0.0

func _populate_gameplay(game: Node) -> void:
	game.elapsed = 96.0
	game.kills = 27
	game.first_event_triggered = true
	game.spawn_clock = 9999.0
	# Keep the deterministic showcase in combat long enough for Movie Maker to
	# capture animation; nearby art-pickup samples must not open a level-up card.
	game.xp_required = 9999.0
	# Visual acceptance frame demonstrates the max-rank silhouette; runtime
	# progression still reaches this state only through real upgrades.
	if game.cultivation_vfx != null:
		game.cultivation_vfx.configure(&"van_kiem", {"sword_damage": 5, "vitality": 0, "magnet": 0})
	Events.run_stats_changed.emit(game.elapsed, game.duration, game.kills)
	var center: Vector2 = game.player.global_position
	var kinds := [
		EnemyScript.EnemyKind.WISP,
		EnemyScript.EnemyKind.BEAST,
		EnemyScript.EnemyKind.DEMON
	]
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var radius := 170.0 + float(index % 3) * 80.0
		game._spawn_enemy(kinds[index % kinds.size()], center + Vector2.from_angle(angle) * radius)
	for index in 7:
		var angle := TAU * float(index) / 7.0 + 0.25
		game._spawn_qi_orb(center + Vector2.from_angle(angle) * (80.0 + float(index % 2) * 45.0), 5.0)
	game._activate_qi_pulse()

func _populate_boss(game: Node) -> void:
	game.elapsed = 162.0
	game.kills = 86
	game.xp_required = 9999.0
	game.spawn_clock = 9999.0
	game.boss_spawned = true
	game.first_event_triggered = true
	game.second_event_triggered = true
	Events.run_stats_changed.emit(game.elapsed, game.duration, game.kills)
	var center: Vector2 = game.player.global_position
	var boss: CultivationEnemy = game._spawn_enemy(EnemyScript.EnemyKind.BOSS, center + Vector2(330.0, 40.0))
	# Capture the readable attack-warning state rather than a neutral boss idle.
	# The live fight reaches this exact phase every cast cycle.
	boss.boss_telegraph = 0.90
	for index in 7:
		var angle := TAU * float(index) / 7.0 + 0.35
		game._spawn_enemy(EnemyScript.EnemyKind.WISP, center + Vector2.from_angle(angle) * 245.0)
	for index in 5:
		var angle := TAU * float(index) / 5.0
		game._spawn_qi_orb(center + Vector2.from_angle(angle) * 105.0, 5.0)
