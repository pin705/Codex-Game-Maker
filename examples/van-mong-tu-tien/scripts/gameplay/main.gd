extends Node2D

# Resource-backed tuning is loaded from resources/tuning/game_balance.json.

enum GameState { START, RUNNING, LEVEL_UP, PAUSED, VICTORY, DEFEAT }

const EnemyScript := preload("res://scripts/gameplay/enemy.gd")
const ProjectileScript := preload("res://scripts/gameplay/projectile.gd")
const OrbScript := preload("res://scripts/gameplay/qi_orb.gd")
const EffectScript := preload("res://scripts/gameplay/game_effect.gd")
const CultivationVFXScript := preload("res://scripts/gameplay/cultivation_vfx.gd")

const JADE := Color("#63dfb4")
const GOLD := Color("#f1c75b")
const CRIMSON := Color("#d65e62")
const VIOLET := Color("#a28ace")
const PAPER := Color("#eee7ce")

const UPGRADE_CATALOG := [
	{
		"id": &"sword_damage",
		"glyph": "K",
		"title": "Vạn Kiếm Quy Tông",
		"description": "Phi kiếm gây thêm 32% sát thương.",
		"max_rank": 6
	},
	{
		"id": &"attack_speed",
		"glyph": "S",
		"title": "Kiếm Tâm Thông Minh",
		"description": "Tốc độ xuất kiếm tăng 18%.",
		"max_rank": 5
	},
	{
		"id": &"extra_sword",
		"glyph": "P",
		"title": "Phân Quang Kiếm Ảnh",
		"description": "Mỗi lần ngự kiếm phóng thêm một phi kiếm.",
		"max_rank": 3
	},
	{
		"id": &"piercing_sword",
		"glyph": "X",
		"title": "Phá Vọng Kiếm Ý",
		"description": "Phi kiếm xuyên thêm một mục tiêu.",
		"max_rank": 3
	},
	{
		"id": &"cloud_step",
		"glyph": "B",
		"title": "Lăng Vân Bộ",
		"description": "Tốc độ di chuyển tăng 12%. Phạm vi hút linh khí tăng nhẹ.",
		"max_rank": 4
	},
	{
		"id": &"jade_body",
		"glyph": "N",
		"title": "Thanh Ngọc Đạo Thể",
		"description": "Tăng 25 sinh mệnh tối đa và hồi ngay 25.",
		"max_rank": 5
	},
	{
		"id": &"spirit_well",
		"glyph": "Q",
		"title": "Tụ Linh Quyết",
		"description": "Phạm vi hút tăng 34% và nhận thêm 12% linh khí.",
		"max_rank": 4
	},
	{
		"id": &"qi_pulse",
		"glyph": "O",
		"title": "Thái Hư Chấn Khí",
		"description": "Chấn khí rộng hơn 15% và mạnh hơn 28%.",
		"max_rank": 4
	},
	{
		"id": &"life_stream",
		"glyph": "H",
		"title": "Trường Sinh Khí",
		"description": "Hồi sinh mệnh mỗi giây tăng thêm 0.65.",
		"max_rank": 4
	},
	{
		"id": &"phoenix_blade",
		"glyph": "F",
		"title": "Phượng Hoàng Kiếm Hỏa",
		"description": "Định kỳ luyện hóa phi kiếm thành kiếm hỏa, gây gấp đôi sát thương.",
		"max_rank": 2
	}
]

@onready var world: Node2D = $World
@onready var background: InkBackground = $World/Background
@onready var effects: Node2D = $World/Effects
@onready var orbs: Node2D = $World/Orbs
@onready var enemies: Node2D = $World/Enemies
@onready var projectiles: Node2D = $World/Projectiles
@onready var player: CultivatorPlayer = $World/Player

var balance: Dictionary = {}
var arena_config: Dictionary = {}
var run_config: Dictionary = {}
var player_config: Dictionary = {}
var enemy_config: Dictionary = {}
var xp_config: Dictionary = {}
var realms: Array = []
var meta_modifiers: Dictionary = {}
var selected_stage_data: Dictionary = {}
var selected_discipline: StringName = &"van_kiem"
var permanent_technique_ranks: Dictionary = {}
var cultivation_vfx: CultivationVFX

var state := GameState.START
var elapsed := 0.0
var duration := 240.0
var kills := 0
var spawn_clock := 0.6
var attack_clock := 0.25
var pulse_remaining := 0.0
var pulse_cooldown := 5.5
var pulse_damage := 48.0
var pulse_radius := 190.0

var level := 1
var xp_current := 0.0
var xp_required := 8.0
var pending_level_ups := 0
var realm_index := -1
var upgrade_ranks: Dictionary = {}
var shot_counter := 0

var first_event_triggered := false
var second_event_triggered := false
var boss_spawned := false
var stats_emit_clock := 0.0
var pulse_emit_clock := 0.0
var random := RandomNumberGenerator.new()
var visual_random := RandomNumberGenerator.new()
var screen_shake_remaining := 0.0
var screen_shake_duration := 0.0
var screen_shake_strength := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	InputBootstrap.ensure_actions()
	random.seed = 20260729
	visual_random.seed = 44027
	_load_balance()
	_configure_world()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_connect_events()
	Events.experience_changed.emit(xp_current, xp_required, level)
	_update_realm(true)
	Events.run_stats_changed.emit(elapsed, duration, kills)
	Events.pulse_state_changed.emit(0.0, pulse_cooldown)
	if get_tree().has_meta("van_mong_restart_into_run"):
		get_tree().remove_meta("van_mong_restart_into_run")
		call_deferred("_start_run")

func _load_balance() -> void:
	balance = GameConfig.load_balance()
	arena_config = GameConfig.section(balance, &"arena")
	run_config = GameConfig.section(balance, &"run")
	player_config = GameConfig.section(balance, &"player")
	enemy_config = GameConfig.section(balance, &"enemy")
	xp_config = GameConfig.section(balance, &"xp")
	var realm_value: Variant = balance.get("realms", [])
	realms = realm_value as Array if realm_value is Array else []
	duration = float(run_config.get("duration_seconds", duration))
	pulse_cooldown = float(player_config.get("pulse_cooldown", pulse_cooldown))
	pulse_damage = float(player_config.get("pulse_damage", pulse_damage))
	pulse_radius = float(player_config.get("pulse_radius", pulse_radius))
	xp_required = float(xp_config.get("first_level", xp_required))
	_apply_meta_loadout()

func _apply_meta_loadout() -> void:
	var meta := get_node_or_null("/root/MetaProfile")
	if meta == null or not meta.has_method("get_run_modifiers"):
		return
	meta_modifiers = meta.call("get_run_modifiers") as Dictionary
	var profile_snapshot: Dictionary = {}
	if meta.has_method("get_profile"):
		profile_snapshot = meta.call("get_profile") as Dictionary
	selected_discipline = StringName(str(profile_snapshot.get("selected_discipline", "van_kiem")))
	permanent_technique_ranks = (profile_snapshot.get("technique_ranks", {}) as Dictionary).duplicate(true)
	selected_stage_data = meta.call("get_stage_data", StringName(str(meta_modifiers.get("stage_id", "van_mong")))) as Dictionary
	player_config = player_config.duplicate(true)
	enemy_config = enemy_config.duplicate(true)
	player_config["base_damage"] = float(player_config.get("base_damage", 18.0)) * float(meta_modifiers.get("damage_mult", 1.0))
	player_config["attack_interval"] = float(player_config.get("attack_interval", 0.70)) * float(meta_modifiers.get("attack_interval_mult", 1.0))
	player_config["max_health"] = float(player_config.get("max_health", 120.0)) * float(meta_modifiers.get("max_health_mult", 1.0))
	player_config["move_speed"] = float(player_config.get("move_speed", 305.0)) * float(meta_modifiers.get("movement_speed_mult", 1.0))
	player_config["pickup_radius"] = float(player_config.get("pickup_radius", 22.0)) * float(meta_modifiers.get("pickup_range_mult", 1.0))
	player_config["magnet_radius"] = float(player_config.get("magnet_radius", 120.0)) * float(meta_modifiers.get("pickup_range_mult", 1.0))
	player_config["xp_multiplier"] = float(meta_modifiers.get("xp_mult", 1.0))
	player_config["damage_taken_multiplier"] = float(meta_modifiers.get("damage_taken_mult", 1.0))
	enemy_config["base_health"] = float(enemy_config.get("base_health", 30.0)) * float(meta_modifiers.get("enemy_health_mult", 1.0))
	enemy_config["base_damage"] = float(enemy_config.get("base_damage", 12.0)) * float(meta_modifiers.get("enemy_damage_mult", 1.0))
	enemy_config["boss_health"] = float(enemy_config.get("boss_health", 900.0)) * float(meta_modifiers.get("boss_health_mult", 1.0))
	enemy_config["spawn_interval_start"] = float(enemy_config.get("spawn_interval_start", 1.05)) * float(meta_modifiers.get("spawn_interval_mult", 1.0))
	enemy_config["spawn_interval_end"] = float(enemy_config.get("spawn_interval_end", 0.34)) * float(meta_modifiers.get("spawn_interval_mult", 1.0))

func _configure_world() -> void:
	var arena_size := _runtime_arena_size()
	_store_runtime_arena_size(arena_size)
	var margin := float(arena_config.get("margin", 54.0))
	var bounds := Rect2(Vector2.ONE * margin, arena_size - Vector2.ONE * margin * 2.0)
	background.configure(arena_size)
	player.global_position = arena_size * 0.5
	player.setup(bounds, player_config)
	player.enabled = false
	player.died.connect(_on_player_died)
	cultivation_vfx = CultivationVFXScript.new() as CultivationVFX
	cultivation_vfx.name = "CultivationVFX"
	world.add_child(cultivation_vfx)
	cultivation_vfx.z_index = 7
	cultivation_vfx.follow_actor(player)
	_refresh_cultivation_vfx()

func _refresh_meta_loadout_for_run() -> void:
	# Stage and discipline are chosen while this scene is already alive behind
	# the front end, so rebuild the mutable configs immediately before combat.
	player_config = GameConfig.section(balance, &"player")
	enemy_config = GameConfig.section(balance, &"enemy")
	_apply_meta_loadout()
	var arena_size := _runtime_arena_size()
	_store_runtime_arena_size(arena_size)
	var margin := float(arena_config.get("margin", 54.0))
	player.setup(Rect2(Vector2.ONE * margin, arena_size - Vector2.ONE * margin * 2.0), player_config)
	background.refresh_selected_stage()
	_refresh_cultivation_vfx()


func _on_viewport_size_changed() -> void:
	var arena_size := _runtime_arena_size()
	var current_size := Vector2(
		float(arena_config.get("width", 1600.0)),
		float(arena_config.get("height", 900.0))
	)
	if current_size.is_equal_approx(arena_size):
		return
	_store_runtime_arena_size(arena_size)
	background.configure(arena_size)
	var margin := float(arena_config.get("margin", 54.0))
	player.update_bounds(Rect2(Vector2.ONE * margin, arena_size - Vector2.ONE * margin * 2.0))


func _runtime_arena_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	return Vector2(maxf(viewport_size.x, 1600.0), maxf(viewport_size.y, 900.0))


func _store_runtime_arena_size(arena_size: Vector2) -> void:
	arena_config["width"] = arena_size.x
	arena_config["height"] = arena_size.y

func _connect_events() -> void:
	Events.start_requested.connect(_start_run)
	Events.restart_requested.connect(_restart_run)
	Events.resume_requested.connect(_resume_run)
	Events.upgrade_selected.connect(_on_upgrade_selected)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart_game"):
		_restart_run()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"qi_pulse") and state == GameState.START and get_node_or_null("FrontEnd") == null:
		_start_run()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"pause_game"):
		if state == GameState.RUNNING:
			_pause_run()
		elif state == GameState.PAUSED:
			_resume_run()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"qi_pulse") and state == GameState.RUNNING:
		_activate_qi_pulse()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_update_screen_shake(delta)
	if state != GameState.RUNNING:
		return
	elapsed += delta
	spawn_clock -= delta
	attack_clock -= delta
	pulse_remaining = maxf(0.0, pulse_remaining - delta)
	stats_emit_clock -= delta
	pulse_emit_clock -= delta

	if spawn_clock <= 0.0:
		_spawn_wave_tick()
		spawn_clock = _current_spawn_interval()
	if attack_clock <= 0.0:
		_fire_auto_swords()
		attack_clock = float(player_config.get("attack_interval", 0.70)) / maxf(player.attack_speed_multiplier, 0.1)

	_resolve_projectile_hits()
	_update_timed_events()

	if stats_emit_clock <= 0.0:
		stats_emit_clock = 0.12
		Events.run_stats_changed.emit(elapsed, duration, kills)
	if pulse_emit_clock <= 0.0:
		pulse_emit_clock = 0.08
		Events.pulse_state_changed.emit(pulse_remaining, pulse_cooldown)

	# Surviving the full tribulation is a valid win even while the boss lives.
	if elapsed >= duration:
		_finish_run(true)

func _start_run() -> void:
	if state != GameState.START:
		return
	_refresh_meta_loadout_for_run()
	state = GameState.RUNNING
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	player.enabled = true
	Events.game_started.emit()
	var stage_name := str(selected_stage_data.get("name", "Vân Mộng Cốc"))
	Events.banner_requested.emit("NHẤT NIỆM NHẬP ĐẠO", "%s · Thu linh khí để khai ngộ" % stage_name, 2.8)

func _restart_run() -> void:
	if state != GameState.START:
		get_tree().set_meta("van_mong_restart_into_run", true)
	get_tree().paused = false
	get_tree().reload_current_scene()

func _pause_run() -> void:
	if state != GameState.RUNNING:
		return
	state = GameState.PAUSED
	get_tree().paused = true
	Events.game_paused.emit(true)

func _resume_run() -> void:
	if state != GameState.PAUSED:
		return
	state = GameState.RUNNING
	get_tree().paused = false
	Events.game_paused.emit(false)

func _spawn_wave_tick() -> void:
	var max_living := int(enemy_config.get("max_living", 125))
	if enemies.get_child_count() >= max_living:
		return
	var progress := clampf(elapsed / maxf(duration, 1.0), 0.0, 1.0)
	var count := 1
	if progress > 0.35 and random.randf() < 0.34:
		count += 1
	if progress > 0.72 and random.randf() < 0.26:
		count += 1
	for _index in count:
		_spawn_enemy(_choose_enemy_kind(progress))

func _choose_enemy_kind(progress: float) -> int:
	var roll := random.randf()
	var elite_chance := float(meta_modifiers.get("elite_chance_add", 0.0))
	if progress > 0.38 and roll < elite_chance:
		return CultivationEnemy.EnemyKind.ELITE
	if progress > 0.62 and roll < 0.22:
		return CultivationEnemy.EnemyKind.DEMON
	if progress > 0.20 and roll < 0.52:
		return CultivationEnemy.EnemyKind.BEAST
	return CultivationEnemy.EnemyKind.WISP

func _spawn_enemy(enemy_kind: int, forced_position: Vector2 = Vector2.INF) -> CultivationEnemy:
	var enemy := EnemyScript.new() as CultivationEnemy
	enemies.add_child(enemy)
	enemy.global_position = forced_position if forced_position != Vector2.INF else _random_edge_position()
	var minutes := elapsed / 60.0
	var health_scale := float(enemy_config.get("health_scale_per_minute", 0.42))
	var damage_scale := float(enemy_config.get("damage_scale_per_minute", 0.18))
	var difficulty := 1.0 + minutes * health_scale
	var scaled_config := enemy_config.duplicate(true)
	scaled_config["base_damage"] = float(enemy_config.get("base_damage", 12.0)) * (1.0 + minutes * damage_scale)
	enemy.setup(enemy_kind, player, difficulty, scaled_config)
	enemy.died.connect(_on_enemy_died)
	enemy.player_contact.connect(_on_enemy_contact)
	enemy.boss_slam.connect(_on_boss_slam)
	_spawn_effect(enemy.global_position, GameEffect.EffectKind.PORTAL, VIOLET if enemy_kind != CultivationEnemy.EnemyKind.BOSS else CRIMSON, enemy.collision_radius * 1.8, 0.55)
	return enemy

func _random_edge_position() -> Vector2:
	var width := float(arena_config.get("width", 1600.0))
	var height := float(arena_config.get("height", 900.0))
	var pad := float(arena_config.get("margin", 54.0)) + 12.0
	var best_candidate := Vector2(pad, pad)
	var best_distance := -1.0
	for _attempt in 8:
		var candidate := Vector2.ZERO
		match random.randi_range(0, 3):
			0:
				candidate = Vector2(random.randf_range(pad, width - pad), pad)
			1:
				candidate = Vector2(width - pad, random.randf_range(pad, height - pad))
			2:
				candidate = Vector2(random.randf_range(pad, width - pad), height - pad)
			_:
				candidate = Vector2(pad, random.randf_range(pad, height - pad))
		var distance := candidate.distance_squared_to(player.global_position)
		if distance > best_distance:
			best_distance = distance
			best_candidate = candidate
		if distance >= 300.0 * 300.0:
			return candidate
	return best_candidate

func _current_spawn_interval() -> float:
	var start_interval := float(enemy_config.get("spawn_interval_start", 1.05))
	var end_interval := float(enemy_config.get("spawn_interval_end", 0.34))
	var progress := clampf(elapsed / maxf(duration, 1.0), 0.0, 1.0)
	return lerpf(start_interval, end_interval, pow(progress, 0.72))

func _fire_auto_swords() -> void:
	var nearest := _nearest_enemy()
	if nearest == null:
		return
	shot_counter += 1
	var phoenix_rank := int(upgrade_ranks.get(&"phoenix_blade", 0))
	var phoenix_frequency := 4 if phoenix_rank == 1 else 2
	var empowered := phoenix_rank > 0 and shot_counter % phoenix_frequency == 0
	var amount := 1 + player.extra_projectiles
	var base_direction := player.global_position.direction_to(nearest.global_position)
	if cultivation_vfx != null:
		cultivation_vfx.trigger_attack(base_direction)
	var spread := deg_to_rad(10.0)
	for index in amount:
		var centered_index := float(index) - float(amount - 1) * 0.5
		var direction := base_direction.rotated(centered_index * spread)
		var target_position := player.global_position + direction * 900.0
		var projectile := ProjectileScript.new() as JadeProjectile
		projectiles.add_child(projectile)
		var shot_damage := float(player_config.get("base_damage", 18.0)) * player.damage_multiplier
		if empowered:
			shot_damage *= 2.0 + float(phoenix_rank - 1) * 0.35
		projectile.setup(
			player.global_position + direction * 24.0,
			target_position,
			shot_damage,
			float(player_config.get("projectile_speed", 780.0)) * player.projectile_speed_multiplier,
			float(player_config.get("projectile_lifetime", 0.90)),
			player.projectile_pierce,
			empowered
		)
	if empowered:
		_spawn_effect(player.global_position, GameEffect.EffectKind.BURST, GOLD, 72.0, 0.34)
	Events.sword_fired.emit(empowered)

func _nearest_enemy() -> CultivationEnemy:
	var nearest: CultivationEnemy = null
	var nearest_distance := INF
	var target_range := float(player_config.get("target_range", 520.0))
	for node in enemies.get_children():
		var enemy := node as CultivationEnemy
		if enemy == null or enemy.dying:
			continue
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance > target_range * target_range:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func _resolve_projectile_hits() -> void:
	var enemy_nodes := enemies.get_children()
	for projectile_node in projectiles.get_children():
		var projectile := projectile_node as JadeProjectile
		if projectile == null or projectile.is_queued_for_deletion():
			continue
		for enemy_node in enemy_nodes:
			var enemy := enemy_node as CultivationEnemy
			if enemy == null or enemy.dying or not is_instance_valid(enemy):
				continue
			if not projectile.can_hit(enemy.get_instance_id()):
				continue
			var combined_radius := projectile.radius + enemy.collision_radius
			if projectile.global_position.distance_squared_to(enemy.global_position) <= combined_radius * combined_radius:
				enemy.take_damage(projectile.damage, projectile.global_position, 82.0)
				_spawn_effect(projectile.global_position, GameEffect.EffectKind.HIT, GOLD if projectile.empowered else JADE, 24.0, 0.22)
				projectile.register_hit(enemy.get_instance_id())
				if projectile.is_queued_for_deletion():
					break

func _activate_qi_pulse() -> void:
	if pulse_remaining > 0.0:
		return
	pulse_remaining = pulse_cooldown
	var radius := pulse_radius * player.pulse_radius_multiplier
	var damage := pulse_damage * player.pulse_power_multiplier * player.damage_multiplier
	_spawn_effect(player.global_position, GameEffect.EffectKind.RING, JADE, radius, 0.62)
	_spawn_effect(player.global_position, GameEffect.EffectKind.BURST, GOLD, radius * 0.68, 0.44)
	_request_screen_shake(4.0, 0.16)
	for node in enemies.get_children():
		var enemy := node as CultivationEnemy
		if enemy == null or enemy.dying:
			continue
		if enemy.global_position.distance_to(player.global_position) <= radius + enemy.collision_radius:
			enemy.take_damage(damage, player.global_position, 360.0)
	Events.pulse_state_changed.emit(pulse_remaining, pulse_cooldown)

func _on_enemy_contact(damage: float) -> void:
	if state != GameState.RUNNING:
		return
	if player.take_damage(damage):
		if cultivation_vfx != null:
			cultivation_vfx.trigger_hit(-player.last_move)
		_spawn_effect(player.global_position, GameEffect.EffectKind.HIT, CRIMSON, 35.0, 0.28)
		_request_screen_shake(7.0, 0.20)

func _on_boss_slam(origin: Vector2, radius: float, damage: float) -> void:
	_spawn_effect(origin, GameEffect.EffectKind.RING, CRIMSON, radius, 0.52)
	if state == GameState.RUNNING and player.global_position.distance_to(origin) <= radius:
		if player.take_damage(damage):
			_spawn_effect(player.global_position, GameEffect.EffectKind.BURST, CRIMSON, 50.0, 0.34)
			_request_screen_shake(12.0, 0.28)

func _on_enemy_died(_enemy: CultivationEnemy, death_position: Vector2, value: float, was_boss: bool) -> void:
	kills += 1
	Events.enemy_defeated.emit(was_boss)
	_spawn_effect(death_position, GameEffect.EffectKind.BURST, GOLD if was_boss else VIOLET, 94.0 if was_boss else 38.0, 0.48)
	if was_boss:
		_request_screen_shake(16.0, 0.34)
		_finish_run(true)
		return
	_spawn_qi_orb(death_position, value)

func _spawn_qi_orb(origin: Vector2, value: float) -> void:
	var orb := OrbScript.new() as QiOrb
	orbs.add_child(orb)
	orb.setup(origin, value, player)
	orb.collected.connect(func(collected_value: float) -> void:
		_on_qi_collected(collected_value, orb.global_position)
	)

func _on_qi_collected(value: float, source_global_position: Vector2 = Vector2.INF) -> void:
	if state != GameState.RUNNING:
		return
	if cultivation_vfx != null:
		cultivation_vfx.trigger_pickup(source_global_position)
	Events.qi_collected.emit(value)
	xp_current += value * player.xp_multiplier
	while xp_current >= xp_required:
		xp_current -= xp_required
		level += 1
		var linear_step := float(xp_config.get("linear_step", 3.0))
		xp_required = float(xp_config.get("first_level", 8.0)) + linear_step * float(level - 1)
		pending_level_ups += 1
		_update_realm(false)
	Events.experience_changed.emit(xp_current, xp_required, level)
	if pending_level_ups > 0 and state == GameState.RUNNING:
		_open_upgrade_choice()

func _open_upgrade_choice() -> void:
	state = GameState.LEVEL_UP
	get_tree().paused = true
	var options := _roll_upgrade_options()
	Events.upgrade_options_presented.emit(options)

func _roll_upgrade_options() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for value: Dictionary in UPGRADE_CATALOG:
		var upgrade_id: StringName = value["id"]
		if int(upgrade_ranks.get(upgrade_id, 0)) < int(value.get("max_rank", 1)):
			available.append(value)
	var result: Array[Dictionary] = []
	while not available.is_empty() and result.size() < 3:
		var index := random.randi_range(0, available.size() - 1)
		var option := available[index].duplicate(true) as Dictionary
		available.remove_at(index)
		var option_id: StringName = option["id"]
		var next_rank := int(upgrade_ranks.get(option_id, 0)) + 1
		option["title"] = "%s  ·  Tầng %d" % [str(option["title"]), next_rank]
		result.append(option)
	if result.size() < 3:
		var fallback: Array[Dictionary] = [
			{"id": &"fallback_damage", "glyph": "K", "title": "Kiếm Ý · Tái Ngộ", "description": "Sát thương phi kiếm tăng 10%."},
			{"id": &"fallback_vitality", "glyph": "N", "title": "Linh Thể · Tái Ngộ", "description": "Tăng 15 sinh mệnh tối đa và hồi 15."},
			{"id": &"fallback_regen", "glyph": "H", "title": "Trường Sinh · Tái Ngộ", "description": "Hồi phục thêm 0.4 sinh mệnh mỗi giây."}
		]
		for fallback_option: Dictionary in fallback:
			if result.size() >= 3:
				break
			var fallback_id: StringName = fallback_option["id"]
			var already_present := false
			for existing: Dictionary in result:
				if existing.get("id") == fallback_id:
					already_present = true
					break
			if not already_present:
				result.append(fallback_option)
	return result

func _on_upgrade_selected(upgrade_id: StringName) -> void:
	if state != GameState.LEVEL_UP:
		return
	_apply_upgrade(upgrade_id)
	pending_level_ups = maxi(0, pending_level_ups - 1)
	Events.experience_changed.emit(xp_current, xp_required, level)
	if pending_level_ups > 0:
		_open_upgrade_choice()
	else:
		state = GameState.RUNNING
		get_tree().paused = false

func _apply_upgrade(upgrade_id: StringName) -> void:
	upgrade_ranks[upgrade_id] = int(upgrade_ranks.get(upgrade_id, 0)) + 1
	match upgrade_id:
		&"sword_damage":
			player.damage_multiplier *= 1.32
		&"attack_speed":
			player.attack_speed_multiplier *= 1.18
		&"extra_sword":
			player.extra_projectiles += 1
		&"piercing_sword":
			player.projectile_pierce += 1
		&"cloud_step":
			player.move_speed *= 1.12
			player.magnet_radius *= 1.08
		&"jade_body":
			player.increase_max_health(25.0)
		&"spirit_well":
			player.magnet_radius *= 1.34
			player.xp_multiplier *= 1.12
		&"qi_pulse":
			player.pulse_radius_multiplier *= 1.15
			player.pulse_power_multiplier *= 1.28
		&"life_stream":
			player.health_regen += 0.65
		&"phoenix_blade":
			pass
		&"emergency_heal":
			player.heal(player.max_health)
		&"fallback_damage":
			player.damage_multiplier *= 1.10
		&"fallback_vitality":
			player.increase_max_health(15.0)
		&"fallback_regen":
			player.health_regen += 0.40
	_refresh_cultivation_vfx()
	_spawn_effect(player.global_position, GameEffect.EffectKind.RING, GOLD, 98.0, 0.55)

func _update_realm(initial: bool) -> void:
	if realms.is_empty():
		return
	var new_index := 0
	for index in realms.size():
		var realm_data: Dictionary = realms[index]
		if level >= int(realm_data.get("level", 1)):
			new_index = index
	if new_index == realm_index:
		return
	realm_index = new_index
	var realm_data: Dictionary = realms[realm_index]
	var realm_name := str(realm_data.get("name", "Phàm Nhân"))
	var subtitle := str(realm_data.get("subtitle", "Một niệm nhập đạo"))
	Events.realm_changed.emit(realm_name, subtitle)
	if not initial and realm_index > 0:
		player.damage_multiplier *= 1.10
		player.move_speed *= 1.035
		player.increase_max_health(12.0)
		Events.banner_requested.emit("ĐỘT PHÁ · %s" % realm_name.to_upper(), subtitle, 3.0)
		_spawn_effect(player.global_position, GameEffect.EffectKind.RING, GOLD, 145.0, 0.8)

func _update_timed_events() -> void:
	var first_event_second := float(run_config.get("first_event_second", 75.0))
	var second_event_second := float(run_config.get("second_event_second", 115.0))
	var boss_second := float(run_config.get("boss_spawn_second", 150.0))
	if not first_event_triggered and elapsed >= first_event_second:
		first_event_triggered = true
		Events.banner_requested.emit("MA TRIỀU DẬY SÓNG", "Yêu vật đồng loạt tràn vào %s" % str(selected_stage_data.get("name", "Vân Mộng Cốc")), 2.8)
		_spawn_ambush(9, CultivationEnemy.EnemyKind.BEAST)
	if not second_event_triggered and elapsed >= second_event_second:
		second_event_triggered = true
		Events.banner_requested.emit("TÀ TU HIỆN THẾ", "Một ma tu tinh anh đã khóa định khí tức của ngươi", 2.8)
		_spawn_enemy(CultivationEnemy.EnemyKind.ELITE)
	if not boss_spawned and elapsed >= boss_second:
		boss_spawned = true
		Events.banner_requested.emit("THIÊN MA GIÁNG THẾ", "Né huyết trận · Phá ma thân trước giờ phi thăng", 3.6)
		_spawn_enemy(CultivationEnemy.EnemyKind.BOSS, Vector2(float(arena_config.get("width", 1600.0)) * 0.5, 110.0))

func _spawn_ambush(count: int, enemy_kind: int) -> void:
	for index in count:
		var angle := TAU * float(index) / float(count)
		var radius := 360.0 + float(index % 2) * 55.0
		var position := player.global_position + Vector2.from_angle(angle) * radius
		position.x = clampf(position.x, 72.0, float(arena_config.get("width", 1600.0)) - 72.0)
		position.y = clampf(position.y, 72.0, float(arena_config.get("height", 900.0)) - 72.0)
		_spawn_enemy(enemy_kind, position)

func _finish_run(victory: bool) -> void:
	if state == GameState.VICTORY or state == GameState.DEFEAT:
		return
	get_tree().paused = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	player.enabled = false
	world.position = Vector2.ZERO
	if victory:
		state = GameState.VICTORY
		var detail := "Ngươi đã vượt qua ma kiếp, đạt %s ở cấp tu vi %d.\n%d yêu vật bị trảm — đạo đồ vẫn còn phía trước." % [_current_realm_name(), level, kills]
		Events.game_finished.emit(true, "PHI THĂNG THÀNH CÔNG", detail)
	else:
		state = GameState.DEFEAT
		var detail := "Đạo tâm tan vỡ sau %s.\nĐạt %s · Cấp %d · Trảm %d yêu vật." % [_format_elapsed(), _current_realm_name(), level, kills]
		Events.game_finished.emit(false, "ĐẠO TIÊU THÂN TỬ", detail)

func _on_player_died() -> void:
	_finish_run(false)

func _current_realm_name() -> String:
	if realm_index >= 0 and realm_index < realms.size():
		var realm_data: Dictionary = realms[realm_index]
		return str(realm_data.get("name", "Phàm Nhân"))
	return "Phàm Nhân"

func _format_elapsed() -> String:
	var total_seconds := floori(elapsed)
	return "%02d:%02d" % [int(total_seconds / 60.0), total_seconds % 60]

func _request_screen_shake(strength: float, duration_seconds: float) -> void:
	var meta := get_node_or_null("/root/MetaProfile")
	if meta != null:
		var settings_value: Variant = meta.get("settings")
		if settings_value is Dictionary:
			var settings := settings_value as Dictionary
			if not bool(settings.get("screen_shake", true)) or bool(settings.get("reduced_motion", false)):
				return
	screen_shake_strength = maxf(screen_shake_strength, strength)
	screen_shake_duration = maxf(screen_shake_duration, duration_seconds)
	screen_shake_remaining = maxf(screen_shake_remaining, duration_seconds)

func _update_screen_shake(delta: float) -> void:
	if screen_shake_remaining <= 0.0:
		world.position = Vector2.ZERO
		return
	screen_shake_remaining = maxf(0.0, screen_shake_remaining - delta)
	var ratio := screen_shake_remaining / maxf(screen_shake_duration, 0.001)
	world.position = Vector2(visual_random.randf_range(-1.0, 1.0), visual_random.randf_range(-1.0, 1.0)) * screen_shake_strength * ratio
	if screen_shake_remaining <= 0.0:
		world.position = Vector2.ZERO
		screen_shake_strength = 0.0


func _refresh_cultivation_vfx() -> void:
	if cultivation_vfx == null:
		return
	var visual_ranks := {
		"sword_damage": _combined_visual_rank("sword_damage", [&"sword_damage", &"extra_sword", &"piercing_sword", &"phoenix_blade"]),
		"vitality": _combined_visual_rank("vitality", [&"jade_body", &"life_stream"]),
		"magnet": _combined_visual_rank("magnet", [&"spirit_well", &"cloud_step", &"qi_pulse"]),
	}
	cultivation_vfx.configure(selected_discipline, visual_ranks)
	cultivation_vfx.follow_actor(player)


func _combined_visual_rank(permanent_key: String, runtime_keys: Array[StringName]) -> int:
	var result := int(permanent_technique_ranks.get(permanent_key, permanent_technique_ranks.get(StringName(permanent_key), 0)))
	for runtime_key: StringName in runtime_keys:
		result += int(upgrade_ranks.get(runtime_key, 0))
	return clampi(result, 0, 5)

func _spawn_effect(origin: Vector2, effect_kind: int, color: Color, radius: float, lifetime: float) -> void:
	var effect := EffectScript.new() as GameEffect
	effects.add_child(effect)
	effect.global_position = origin
	effect.setup(effect_kind, color, radius, lifetime)
