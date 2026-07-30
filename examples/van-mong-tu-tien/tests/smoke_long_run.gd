extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game._start_run()
	# The harness advances the session clock explicitly; disable the automatic
	# per-frame callback so the seeded director result stays deterministic.
	game.set_process(false)
	# Keep the simulation alive so this test exercises timed events rather than a
	# contact-death branch. XP is disabled to keep the modal paused state out of
	# this focused director/clock test.
	game.player.max_health = 1000000.0
	game.player.health = 1000000.0
	game.player.xp_multiplier = 0.0
	for _second in 240:
		if game.state != game.GameState.RUNNING:
			break
		game._process(1.0)
		await get_tree().process_frame
	var ok := true
	if not game.first_event_triggered:
		print("FAIL: first timed event did not trigger")
		ok = false
	if not game.second_event_triggered:
		print("FAIL: second timed event did not trigger")
		ok = false
	if not game.boss_spawned:
		print("FAIL: boss did not spawn once")
		ok = false
	if game.enemies.get_child_count() > int(game.enemy_config.get("max_living", 125)) + 1:
		print("FAIL: enemy cap exceeded: ", game.enemies.get_child_count())
		ok = false
	if game.state != game.GameState.VICTORY:
		print("FAIL: timeout did not produce victory; state=", game.state)
		ok = false
	if ok:
		print("LONG RUN RESULT: PASS; enemies=", game.enemies.get_child_count(), " boss_spawned=", game.boss_spawned)
		get_tree().quit(0)
	else:
		print("LONG RUN RESULT: FAIL")
		get_tree().quit(1)
