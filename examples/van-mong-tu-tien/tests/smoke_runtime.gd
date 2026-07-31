extends Node

## Headless smoke harness for the smallest player-visible loop.
## Run with:
## godot --headless --audio-driver Dummy --path . tests/smoke_runtime.tscn

var game: Variant
var failures: Array[String] = []
const MainScript := preload("res://scripts/gameplay/main.gd")
const EnemyScript := preload("res://scripts/gameplay/enemy.gd")
const RuntimeVisualsScript := preload("res://scripts/gameplay/runtime_visuals.gd")

func _ready() -> void:
	call_deferred("_run_smoke")

func _run_smoke() -> void:
	_prime_runtime_visual_test_textures()
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("main scene could not be loaded")
		_quit_with_report()
		return
	game = packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	_expect(game.state == MainScript.GameState.START, "scene starts at TITLE/START")
	var hud := game.get_node("HUD") as CultivationHUD
	var frontend := game.get_node("FrontEnd") as CultivationFrontEnd
	var mobile_support: Variant = game.get_node_or_null("MobileSupportLayer")
	_expect(frontend.root.visible and frontend.screen_name == frontend.SCREEN_TITLE, "authored front end opens on TITLE")
	_expect(mobile_support != null, "mobile support layer ships in the main scene")
	if mobile_support != null:
		_expect(not bool(mobile_support.get_touch_controls().controls_enabled), "touch controls stay inactive behind the front end")
	_expect(not hud.start_overlay.visible, "legacy combat title is suppressed behind front end")
	_expect(hud.start_overlay.get_child_count() >= 2, "title overlay has art/fallback plus shade")

	game._start_run()
	await get_tree().process_frame
	_expect(game.state == MainScript.GameState.RUNNING, "start request enters RUNNING")
	_expect(game.player.enabled, "player is enabled after start")
	_expect(game.cultivation_vfx != null and bool(game.cultivation_vfx.debug_snapshot().get("following_actor", false)), "rank VFX follows the player in live combat")
	if mobile_support != null:
		_expect(bool(mobile_support.get_touch_controls().controls_enabled), "combat lifecycle enables mobile controls")
	_expect(game.spirit_beast != null and game.spirit_beast.enabled, "Thanh Van Ho companion enables with combat")
	_expect(game.player.visual_sprite != null, "player uses a sprite when runtime art is available")
	_expect(game.player.visual_state == &"idle", "player runtime visual starts in idle state")
	var idle_texture: Texture2D = game.player.visual_sprite.texture if game.player.visual_sprite != null else null
	Input.action_press(&"move_right")
	await get_tree().physics_frame
	_expect(game.player.move_acceleration > 0.0 and game.player.move_deceleration > 0.0, "player uses acceleration/deceleration movement tuning")
	await get_tree().physics_frame
	_expect(game.player.visual_state == &"move", "player runtime visual changes idle -> move")
	if game.player.visual_sprite != null:
		_expect(game.player.visual_sprite.texture != idle_texture, "move state swaps to the move texture")
	Input.action_release(&"move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(game.player.visual_state == &"idle", "player runtime visual changes move -> idle")
	_expect(is_zero_approx(game.player.visual_sprite.rotation) == false or game.player.velocity.length() < 1.0, "movement feedback keeps a stable optical lean")
	if game.player.visual_sprite != null:
		_expect(game.player.visual_sprite.texture == idle_texture, "idle state restores the idle texture")

	var auto_enemy: CultivationEnemy = game._spawn_enemy(EnemyScript.EnemyKind.WISP, game.player.global_position + Vector2(500.0, 0.0)) as CultivationEnemy
	_expect(auto_enemy.visual_sprite != null, "enemy uses a sprite when runtime art is available")
	var auto_health := auto_enemy.health
	game._fire_auto_swords()
	_expect(int(game.cultivation_vfx.debug_snapshot().get("active_attacks", 0)) > 0, "auto attack triggers the discipline sword fan VFX")
	var projectile := game.projectiles.get_child(0) as JadeProjectile
	if projectile != null:
		_expect(projectile.visual_sprite != null, "projectile uses a sprite when runtime art is available")
		projectile.global_position = auto_enemy.global_position
	game._resolve_projectile_hits()
	_expect(auto_enemy.health < auto_health, "auto sword damages the nearest enemy")
	auto_enemy.take_damage(99999.0, game.player.global_position)
	var pulse_enemy: CultivationEnemy = game._spawn_enemy(EnemyScript.EnemyKind.WISP, game.player.global_position + Vector2(140.0, 0.0)) as CultivationEnemy
	var pulse_health := pulse_enemy.health
	game._activate_qi_pulse()
	if game.effects.get_child_count() > 0:
		var pulse_effect := game.effects.get_child(0) as GameEffect
		_expect(pulse_effect != null and pulse_effect.visual_sprite != null, "effect uses a sprite when runtime art is available")
	_expect(pulse_enemy.health < pulse_health, "qi pulse damages an enemy inside its radius")
	pulse_enemy.take_damage(99999.0, game.player.global_position)
	# Pet assist is deterministic and targets the highest-threat living enemy.
	var pet_enemy: CultivationEnemy = game._spawn_enemy(EnemyScript.EnemyKind.WISP, game.player.global_position + Vector2(190.0, 0.0)) as CultivationEnemy
	var pet_health := pet_enemy.health
	game._on_spirit_beast_assist(pet_enemy, 12.0, game.spirit_beast.global_position)
	_expect(pet_enemy.health < pet_health, "companion active skill damages a target")
	await get_tree().process_frame
	_expect(game.kills == 2, "two enemy deaths increment kills exactly once each")
	_expect(game.orbs.get_child_count() == 2, "each enemy death creates one qi orb")
	if game.orbs.get_child_count() > 0:
		var first_orb := game.orbs.get_child(0) as QiOrb
		_expect(first_orb != null and first_orb.visual_sprite != null, "qi orb uses a sprite when runtime art is available")

	# Add exactly one threshold so the test can assert a single card closes the modal.
	game._on_qi_collected(game.xp_required)
	_expect(int(game.cultivation_vfx.debug_snapshot().get("active_pickups", 0)) > 0, "qi collection triggers a visible gathering beam")
	await get_tree().process_frame
	_expect(game.state == MainScript.GameState.LEVEL_UP, "xp threshold opens breakthrough state")
	_expect(get_tree().paused, "breakthrough pauses the world")
	_expect(hud.upgrade_cards.get_child_count() == 3, "breakthrough presents three cards")
	var first_card := hud.upgrade_cards.get_child(0) as Button
	_expect(first_card != null, "first breakthrough card is a Button")
	if first_card != null:
		first_card.pressed.emit()
	await get_tree().process_frame
	_expect(game.state == MainScript.GameState.RUNNING, "one card selection resumes RUNNING")
	_expect(not get_tree().paused, "card selection unpauses the world")

	game._pause_run()
	_expect(game.state == MainScript.GameState.PAUSED, "pause enters PAUSED")
	_expect(get_tree().paused, "pause freezes the world")
	Events.resume_requested.emit()
	_expect(game.state == MainScript.GameState.RUNNING, "resume returns to RUNNING")
	_expect(not get_tree().paused, "resume unpauses the world")

	# Timeout is a victory even when the boss has not spawned or is still alive.
	game.duration = 0.01
	game.elapsed = 0.0
	game._process(0.02)
	await get_tree().process_frame
	_expect(game.state == MainScript.GameState.VICTORY, "timeout produces victory without a boss kill")
	_expect(not game.player.enabled, "player is disabled after timeout victory")

	game.queue_free()
	await get_tree().process_frame
	var boss_game: Variant = packed.instantiate()
	get_tree().root.add_child(boss_game)
	await get_tree().process_frame
	boss_game._start_run()
	var boss: CultivationEnemy = boss_game._spawn_enemy(EnemyScript.EnemyKind.BOSS, boss_game.player.global_position + Vector2(180.0, 0.0)) as CultivationEnemy
	boss.boss_cast_clock = 0.0
	boss._update_boss_cast(0.1)
	_expect(boss.boss_telegraph > 0.0, "boss exposes a readable cast telegraph")
	boss.take_damage(boss.max_health * 0.40, boss_game.player.global_position)
	_expect(boss.boss_phase == 2, "boss enters phase two at health threshold")
	boss.take_damage(999999.0, boss_game.player.global_position)
	await get_tree().process_frame
	_expect(boss_game.state == MainScript.GameState.VICTORY, "boss defeat produces immediate victory")

	boss_game.queue_free()
	await get_tree().process_frame
	var defeat_game: Variant = packed.instantiate()
	get_tree().root.add_child(defeat_game)
	await get_tree().process_frame
	defeat_game._start_run()
	defeat_game.player.take_damage(999999.0)
	await get_tree().process_frame
	_expect(defeat_game.state == MainScript.GameState.DEFEAT, "lethal damage produces defeat")
	_quit_with_report()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		_fail(label)

func _prime_runtime_visual_test_textures() -> void:
	RuntimeVisualsScript.clear_cache()
	var idle_texture := _make_test_texture(Color("#62e2b2"))
	var move_texture := _make_test_texture(Color("#f2c75c"))
	RuntimeVisualsScript.prime_texture(&"player_idle", idle_texture)
	RuntimeVisualsScript.prime_texture(&"player_move", move_texture)
	for role: StringName in [
		&"enemy_wisp", &"enemy_beast", &"enemy_demon", &"enemy_elite", &"enemy_boss",
		&"projectile_sword", &"projectile_phoenix", &"qi_orb",
		&"effect_ring", &"effect_burst", &"effect_hit", &"effect_portal"
	]:
		RuntimeVisualsScript.prime_texture(role, idle_texture)

func _make_test_texture(color: Color) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _fail(label: String) -> void:
	failures.append(label)
	print("FAIL: ", label)

func _quit_with_report() -> void:
	if failures.is_empty():
		print("SMOKE RESULT: PASS")
		get_tree().quit(0)
	else:
		print("SMOKE RESULT: FAIL (", failures.size(), " failures)")
		get_tree().quit(1)
