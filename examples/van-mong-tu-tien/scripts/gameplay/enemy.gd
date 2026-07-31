class_name CultivationEnemy
extends CharacterBody2D

# Resource-backed profiles are configured by the session from game_balance.json.

const RuntimeVisualsScript := preload("res://scripts/gameplay/runtime_visuals.gd")
const BOSS_HUD_CREST: Texture2D = preload("res://assets/generated/ui/UIKIT-011-v4-hud/runtime/boss_crest.png")
const BOSS_HUD_CHANNEL: Texture2D = preload("res://assets/generated/ui/UIKIT-011-v4-hud/runtime/boss_bar_channel.png")
const UI_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")

signal died(enemy: CultivationEnemy, death_position: Vector2, xp_value: float, was_boss: bool)
signal player_contact(damage: float)
signal boss_slam(origin: Vector2, radius: float, damage: float)
signal boss_rift(origin: Vector2, direction: Vector2, length: float, width: float, damage: float)
signal boss_summon(origin: Vector2, count: int, radius: float, damage: float)
signal boss_phase_changed(phase: int)
signal boss_punish_window(duration: float)

enum EnemyKind { WISP, BEAST, DEMON, ELITE, BOSS }

const INK := Color("#0b161b")
const ASH := Color("#71817b")
const JADE := Color("#55c59b")
const CRIMSON := Color("#d65e5e")
const VIOLET := Color("#9f82c9")
const GOLD := Color("#e6b84d")
const PALE := Color("#e5dfc3")

var kind := EnemyKind.WISP
var target: CultivatorPlayer
var max_health := 38.0
var health := 38.0
var move_speed := 86.0
var contact_damage := 12.0
var xp_value := 5.0
var collision_radius := 18.0
var contact_radius := 30.0
var contact_clock := 0.0
var age := 0.0
var knockback_velocity := Vector2.ZERO
var dying := false
var spawn_fade := 0.0
var visual_seed := 0.0
var boss_cast_clock := 4.0
var boss_telegraph := 0.0
var boss_telegraph_total := 0.92
var boss_cast_kind := 0
var boss_skill_index := 0
var boss_phase := 1
var boss_punish_remaining := 0.0
var boss_target_direction := Vector2.DOWN
var elite := false
var boss := false
var body_shape: CircleShape2D
var visual_sprite: Sprite2D
var visual_frames: Array = []
var visual_frame_index := 0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 0
	var collision := CollisionShape2D.new()
	body_shape = CircleShape2D.new()
	body_shape.radius = collision_radius
	collision.shape = body_shape
	add_child(collision)

func setup(enemy_kind: int, player: CultivatorPlayer, difficulty: float, base_config: Dictionary) -> void:
	kind = enemy_kind
	target = player
	var base_health := float(base_config.get("base_health", 38.0))
	var base_speed := float(base_config.get("base_speed", 86.0))
	var base_damage := float(base_config.get("base_damage", 12.0))
	visual_seed = fmod(global_position.x * 0.017 + global_position.y * 0.029, TAU)
	match kind:
		EnemyKind.WISP:
			max_health = base_health * difficulty
			move_speed = base_speed * 1.08
			contact_damage = base_damage
			xp_value = 1.0
			collision_radius = 15.0
		EnemyKind.BEAST:
			max_health = base_health * 1.8 * difficulty
			move_speed = base_speed * 1.32
			contact_damage = base_damage * 1.12
			xp_value = 2.0
			collision_radius = 20.0
		EnemyKind.DEMON:
			max_health = base_health * 2.65 * difficulty
			move_speed = base_speed * 0.78
			contact_damage = base_damage * 1.55
			xp_value = 3.0
			collision_radius = 25.0
		EnemyKind.ELITE:
			elite = true
			max_health = base_health * 10.0 * difficulty
			move_speed = base_speed * 0.82
			contact_damage = base_damage * 1.85
			xp_value = 12.0
			collision_radius = 34.0
		EnemyKind.BOSS:
			elite = true
			boss = true
			max_health = float(base_config.get("boss_health", 900.0))
			move_speed = base_speed * 0.72
			contact_damage = base_damage * 1.83
			xp_value = 0.0
			collision_radius = 52.0
	z_index = 20 if boss else 0
	health = max_health
	contact_radius = collision_radius + 18.0
	if body_shape != null:
		body_shape.radius = collision_radius
	_configure_runtime_sprite()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dying or not is_instance_valid(target) or not target.enabled:
		velocity = Vector2.ZERO
		return
	age += delta
	spawn_fade = minf(1.0, spawn_fade + delta * 3.8)
	contact_clock = maxf(0.0, contact_clock - delta)
	boss_punish_remaining = maxf(0.0, boss_punish_remaining - delta)
	_update_runtime_sprite_feedback()

	if boss:
		_update_boss_cast(delta)
		if boss_telegraph > 0.0:
			velocity = Vector2.ZERO
			move_and_slide()
			queue_redraw()
			return

	var to_player := global_position.direction_to(target.global_position)
	var sway := Vector2(-to_player.y, to_player.x) * sin(age * 1.7 + visual_seed) * (0.18 if not elite else 0.08)
	velocity = (to_player + sway).normalized() * move_speed + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 760.0 * delta)
	move_and_slide()

	if global_position.distance_to(target.global_position) <= contact_radius and contact_clock <= 0.0:
		contact_clock = 0.72 if not boss else 0.95
		player_contact.emit(contact_damage)
	queue_redraw()

func _update_boss_cast(delta: float) -> void:
	if boss_telegraph > 0.0:
		boss_telegraph -= delta
		if boss_telegraph <= 0.0:
			var cast_damage := contact_damage * (1.15 + float(boss_phase - 1) * 0.20)
			match boss_cast_kind:
				0:
					boss_slam.emit(global_position, 230.0 + float(boss_phase - 1) * 24.0, cast_damage)
				1:
					boss_rift.emit(global_position, boss_target_direction, 500.0 + float(boss_phase - 1) * 70.0, 56.0 + float(boss_phase - 1) * 10.0, cast_damage * 1.22)
				_:
					boss_summon.emit(global_position, 3 + boss_phase, 118.0 + float(boss_phase - 1) * 20.0, cast_damage * 0.78)
			boss_punish_remaining = 1.55 if boss_phase == 1 else 1.25
			boss_punish_window.emit(boss_punish_remaining)
			boss_cast_clock = maxf(2.25, 4.6 - float(boss_phase - 1) * 0.72)
		return
	boss_cast_clock -= delta
	if boss_cast_clock <= 0.0:
		boss_skill_index = (boss_skill_index + 1) % 3
		boss_cast_kind = (boss_skill_index + boss_phase - 1) % 3
		boss_target_direction = global_position.direction_to(target.global_position)
		boss_telegraph_total = 0.92 if boss_cast_kind == 0 else (1.05 if boss_cast_kind == 1 else 1.20)
		boss_telegraph = boss_telegraph_total

func take_damage(amount: float, push_origin: Vector2, push_force: float = 110.0) -> bool:
	if dying:
		return false
	if boss and boss_punish_remaining > 0.0:
		amount *= 1.65
	health -= amount
	if not boss:
		knockback_velocity += push_origin.direction_to(global_position) * push_force
	if health <= 0.0:
		dying = true
		died.emit(self, global_position, xp_value, boss)
		queue_free()
		return true
	if boss:
		var next_phase := 1
		if health <= max_health * 0.33:
			next_phase = 3
		elif health <= max_health * 0.66:
			next_phase = 2
		if next_phase != boss_phase:
			boss_phase = next_phase
			boss_cast_clock = minf(boss_cast_clock, 1.4)
			boss_phase_changed.emit(boss_phase)
	queue_redraw()
	return false

func _draw() -> void:
	var alpha := spawn_fade
	var bob := sin(age * 4.0 + visual_seed) * (3.0 if kind == EnemyKind.WISP else 1.5)
	# Runtime sprites are bottom-anchored; ground the shadow at the shared feet
	# pivot so large enemies and the boss do not appear to hover.
	_draw_ink_ellipse(Vector2(0.0, 4.0), Vector2(collision_radius * 0.96, maxf(6.0, collision_radius * 0.26)), Color(0.0, 0.0, 0.0, 0.28 * alpha))
	if visual_sprite != null and visual_sprite.texture != null:
		var aura_color := CRIMSON if boss else (GOLD if elite else VIOLET)
		draw_circle(Vector2.ZERO, collision_radius * 1.22, Color(aura_color, 0.075 * alpha))
		if boss:
			_draw_boss_telegraph(alpha)
	else:
		match kind:
			EnemyKind.WISP:
				_draw_wisp(bob, alpha)
			EnemyKind.BEAST:
				_draw_beast(bob, alpha)
			EnemyKind.DEMON:
				_draw_demon(bob, alpha)
			EnemyKind.ELITE:
				_draw_elite(bob, alpha)
			EnemyKind.BOSS:
				_draw_boss(bob, alpha)
	if elite and health > 0.0:
		_draw_health_bar(alpha)

func _configure_runtime_sprite() -> void:
	if visual_sprite != null:
		return
	var role := _runtime_role()
	var texture := RuntimeVisualsScript.get_texture(role)
	if texture == null:
		return
	visual_sprite = RuntimeVisualsScript.attach(self, role, _runtime_height())
	visual_frames = RuntimeVisualsScript.get_animation_frames(role)
	if not visual_frames.is_empty() and visual_sprite != null:
		RuntimeVisualsScript.configure(visual_sprite, visual_frames[0] as Texture2D, _runtime_height())
	_update_runtime_sprite_feedback()

func _runtime_role() -> StringName:
	match kind:
		EnemyKind.WISP:
			return &"enemy_wisp"
		EnemyKind.BEAST:
			return &"enemy_beast"
		EnemyKind.DEMON:
			return &"enemy_demon"
		EnemyKind.ELITE:
			return &"enemy_elite"
		EnemyKind.BOSS:
			return &"enemy_boss"
	return &"enemy_wisp"

func _runtime_height() -> float:
	match kind:
		EnemyKind.WISP:
			return 48.0
		EnemyKind.BEAST:
			return 64.0
		EnemyKind.DEMON:
			return 82.0
		EnemyKind.ELITE:
			return 106.0
		EnemyKind.BOSS:
			return 150.0
	return collision_radius * 2.5

func _update_runtime_sprite_feedback() -> void:
	if visual_sprite == null:
		return
	if absf(velocity.x) > 2.0:
		visual_sprite.flip_h = velocity.x < 0.0
	if not visual_frames.is_empty():
		var fps := 5.0 if boss else (8.0 if not elite else 6.0)
		var next_frame := int(age * fps) % visual_frames.size()
		if next_frame != visual_frame_index:
			visual_frame_index = next_frame
			RuntimeVisualsScript.configure(visual_sprite, visual_frames[visual_frame_index] as Texture2D, _runtime_height())
	visual_sprite.position.y = sin(age * (3.8 if kind == EnemyKind.WISP else 2.2) + visual_seed) * (3.0 if kind == EnemyKind.WISP else 1.5)
	var tint := Color(1.0, 1.0, 1.0, spawn_fade)
	match kind:
		EnemyKind.BEAST:
			tint = Color(1.12, 0.72, 0.68, spawn_fade)
		EnemyKind.DEMON:
			tint = Color(0.78, 0.68, 1.05, spawn_fade)
		EnemyKind.ELITE:
			tint = Color(1.08, 0.88, 0.58, spawn_fade)
		EnemyKind.BOSS:
			tint = Color(1.0, 0.94, 0.88, spawn_fade)
	visual_sprite.modulate = tint

func _draw_boss_telegraph(alpha: float) -> void:
	if boss_telegraph <= 0.0:
		return
	var warning_progress := 1.0 - boss_telegraph / maxf(boss_telegraph_total, 0.01)
	if boss_cast_kind == 1:
		_draw_rift_telegraph(alpha, warning_progress, boss_target_direction)
		return
	if boss_cast_kind == 2:
		_draw_summon_telegraph(alpha, warning_progress)
		return
	var pulse := 0.72 + sin(age * 18.0) * 0.18
	# The complete danger radius is visible from the first telegraph frame. The
	# advancing inner ring communicates timing without making players guess the
	# final hit area. Broken, unequal brush segments preserve that readability
	# while matching the dry-ink world instead of looking like a debug circle.
	draw_circle(Vector2.ZERO, 230.0, Color(CRIMSON, (0.075 + warning_progress * 0.055) * alpha))
	for segment in 13:
		var base_angle := TAU * float(segment) / 13.0
		var irregular := sin(float(segment) * 2.31 + visual_seed * 4.0) * 0.075
		var span := TAU / 13.0 * (0.42 + 0.34 * absf(sin(float(segment) * 1.73 + visual_seed)))
		var radius := 230.0 + sin(float(segment) * 2.07 + visual_seed) * 7.0
		var width := 2.6 + float((segment * 3) % 5) * 1.05
		draw_arc(Vector2.ZERO, radius, base_angle + irregular, base_angle + irregular + span, 7, Color(CRIMSON, (0.64 + 0.22 * float(segment % 2)) * pulse * alpha), width, true)
	for segment in 8:
		var base_angle := -age * 0.42 + TAU * float(segment) / 8.0
		var span := TAU / 8.0 * (0.24 + 0.13 * float(segment % 3))
		draw_arc(Vector2.ZERO, 214.0 + sin(float(segment) * 2.7) * 5.0, base_angle, base_angle + span, 5, Color(GOLD, 0.48 * alpha), 1.8 + float(segment % 3), true)
	var advancing_radius := lerpf(72.0, 222.0, warning_progress)
	for segment in 9:
		var base_angle := TAU * float(segment) / 9.0 - age * 0.12
		var span := TAU / 9.0 * (0.28 + 0.22 * absf(sin(float(segment) * 2.4 + visual_seed)))
		var brush_radius := advancing_radius + sin(float(segment) * 2.1 + visual_seed) * 4.5
		draw_arc(Vector2.ZERO, brush_radius, base_angle, base_angle + span, 5, Color(PALE, (0.48 + 0.12 * float(segment % 2)) * alpha), 2.6 + float(segment % 3) * 1.2, true)
	for rune_index in 12:
		var angle := TAU * float(rune_index) / 12.0 + age * 0.12
		var rune_center := Vector2.from_angle(angle) * 223.0
		var tangent := Vector2.from_angle(angle + PI * 0.5)
		var normal := Vector2.from_angle(angle)
		draw_line(rune_center - tangent * 8.0, rune_center + tangent * 6.0, Color(GOLD, 0.64 * alpha), 2.4, true)
		draw_line(rune_center - tangent * 4.0 - normal * 4.0, rune_center + tangent * 3.0 + normal * 4.0, Color(CRIMSON, 0.54 * alpha), 1.4, true)

func _draw_rift_telegraph(alpha: float, progress: float, direction: Vector2) -> void:
	var tangent := Vector2(-direction.y, direction.x)
	var length := 500.0 + float(boss_phase - 1) * 70.0
	var width := 56.0 + float(boss_phase - 1) * 10.0
	var pulse := 0.72 + sin(age * 15.0) * 0.16
	var tip := direction * (length * (0.48 + progress * 0.52))
	var left := direction * 22.0 + tangent * width
	var right := direction * 22.0 - tangent * width
	draw_colored_polygon(PackedVector2Array([left, right, tip - tangent * 12.0, tip + tangent * 12.0]), Color(CRIMSON, 0.07 * alpha))
	for side: float in [-1.0, 1.0]:
		var edge := direction * 22.0 + tangent * width * side
		for segment in 8:
			var a := float(segment) / 8.0
			var b := minf(1.0, a + 0.055 + progress * 0.025)
			draw_line(edge.lerp(tip + tangent * 12.0 * side, a), edge.lerp(tip + tangent * 12.0 * side, b), Color(CRIMSON, (0.72 + 0.18 * float(segment % 2)) * pulse * alpha), 3.0 + float(segment % 2), true)
	for mark in 5:
		var mark_pos := direction * (60.0 + float(mark) * length / 6.0)
		draw_line(mark_pos - tangent * 8.0, mark_pos + tangent * 8.0, Color(GOLD, 0.62 * alpha), 2.0, true)

func _draw_summon_telegraph(alpha: float, progress: float) -> void:
	var seal_count := 3 + boss_phase
	var radius := 118.0 + float(boss_phase - 1) * 20.0
	for index in seal_count:
		var angle := TAU * float(index) / float(seal_count) - age * 0.15
		var center := Vector2.from_angle(angle) * radius
		var size := 22.0 + progress * 18.0
		var diamond := PackedVector2Array([center + Vector2.UP * size, center + Vector2.RIGHT * size * 0.72, center + Vector2.DOWN * size, center + Vector2.LEFT * size * 0.72])
		draw_colored_polygon(diamond, Color(VIOLET, 0.08 * alpha))
		for edge in 4:
			var a := diamond[edge]
			var b := diamond[(edge + 1) % 4]
			draw_line(a.lerp(b, 0.08), a.lerp(b, 0.64 + progress * 0.24), Color(VIOLET, 0.72 * alpha), 2.8, true)
		draw_line(center + Vector2(-7.0, 0.0), center + Vector2(7.0, 0.0), Color(GOLD, 0.62 * alpha), 2.0, true)

func _draw_wisp(bob: float, alpha: float) -> void:
	draw_circle(Vector2(0.0, bob), 21.0, Color(VIOLET, 0.10 * alpha))
	draw_circle(Vector2(0.0, bob), 13.0, Color(INK, alpha))
	draw_arc(Vector2(0.0, bob), 16.0, age, age + PI * 1.4, 20, Color(VIOLET, 0.72 * alpha), 3.0, true)
	draw_circle(Vector2(-4.0, -2.0 + bob), 2.4, Color(PALE, alpha))
	draw_circle(Vector2(4.0, -2.0 + bob), 2.4, Color(PALE, alpha))
	var tail := PackedVector2Array([Vector2(-8.0, 9.0 + bob), Vector2(-4.0, 28.0 + bob), Vector2(2.0, 14.0 + bob), Vector2(8.0, 26.0 + bob), Vector2(9.0, 7.0 + bob)])
	draw_colored_polygon(tail, Color(INK, 0.82 * alpha))

func _draw_beast(bob: float, alpha: float) -> void:
	draw_circle(Vector2(0.0, bob), 20.0, Color("#6e3538", alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-17.0, -11.0 + bob), Vector2(-27.0, -25.0 + bob), Vector2(-8.0, -18.0 + bob)]), Color(CRIMSON, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(17.0, -11.0 + bob), Vector2(27.0, -25.0 + bob), Vector2(8.0, -18.0 + bob)]), Color(CRIMSON, alpha))
	draw_circle(Vector2(-6.0, -4.0 + bob), 3.0, Color(GOLD, alpha))
	draw_circle(Vector2(6.0, -4.0 + bob), 3.0, Color(GOLD, alpha))
	draw_line(Vector2(-10.0, 9.0 + bob), Vector2(10.0, 9.0 + bob), Color(INK, alpha), 3.0, true)
	draw_arc(Vector2.ZERO, 27.0, age * 0.4, age * 0.4 + PI, 20, Color(CRIMSON, 0.22 * alpha), 3.0, true)

func _draw_demon(bob: float, alpha: float) -> void:
	var body := PackedVector2Array([Vector2(0.0, -31.0 + bob), Vector2(24.0, -12.0 + bob), Vector2(30.0, 23.0 + bob), Vector2(0.0, 31.0 + bob), Vector2(-30.0, 23.0 + bob), Vector2(-24.0, -12.0 + bob)])
	draw_colored_polygon(body, Color("#28383b", alpha))
	draw_polyline(body, Color(VIOLET, 0.82 * alpha), 2.5, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-13.0, -22.0 + bob), Vector2(-22.0, -42.0 + bob), Vector2(-3.0, -29.0 + bob)]), Color(INK, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(13.0, -22.0 + bob), Vector2(22.0, -42.0 + bob), Vector2(3.0, -29.0 + bob)]), Color(INK, alpha))
	draw_circle(Vector2(-8.0, -7.0 + bob), 3.2, Color(CRIMSON, alpha))
	draw_circle(Vector2(8.0, -7.0 + bob), 3.2, Color(CRIMSON, alpha))

func _draw_elite(bob: float, alpha: float) -> void:
	draw_circle(Vector2.ZERO, 48.0, Color(GOLD, 0.07 * alpha))
	var robe := PackedVector2Array([Vector2(0.0, -43.0 + bob), Vector2(27.0, -18.0 + bob), Vector2(36.0, 33.0 + bob), Vector2(0.0, 25.0 + bob), Vector2(-36.0, 33.0 + bob), Vector2(-27.0, -18.0 + bob)])
	draw_colored_polygon(robe, Color("#332538", alpha))
	draw_polyline(robe, Color(GOLD, 0.8 * alpha), 2.8, true)
	draw_circle(Vector2(0.0, -24.0 + bob), 15.0, Color(INK, alpha))
	draw_circle(Vector2(-6.0, -25.0 + bob), 3.2, Color(CRIMSON, alpha))
	draw_circle(Vector2(6.0, -25.0 + bob), 3.2, Color(CRIMSON, alpha))
	for index in 4:
		var angle := age * 0.7 + TAU * float(index) / 4.0
		draw_circle(Vector2.from_angle(angle) * 40.0, 3.4, Color(GOLD, 0.72 * alpha))

func _draw_boss(bob: float, alpha: float) -> void:
	var aura_radius := 68.0 + sin(age * 2.1) * 4.0
	draw_circle(Vector2.ZERO, aura_radius, Color(CRIMSON, 0.075 * alpha))
	draw_arc(Vector2.ZERO, aura_radius, -age * 0.32, PI * 1.25 - age * 0.32, 42, Color(GOLD, 0.45 * alpha), 4.0, true)
	draw_arc(Vector2.ZERO, aura_radius - 9.0, age * 0.45, age * 0.45 + PI * 1.55, 42, Color(CRIMSON, 0.56 * alpha), 3.0, true)
	var body := PackedVector2Array([Vector2(0.0, -58.0 + bob), Vector2(39.0, -24.0 + bob), Vector2(50.0, 48.0 + bob), Vector2(0.0, 36.0 + bob), Vector2(-50.0, 48.0 + bob), Vector2(-39.0, -24.0 + bob)])
	draw_colored_polygon(body, Color("#241e2b", alpha))
	draw_polyline(body, Color(GOLD, 0.95 * alpha), 3.2, true)
	draw_circle(Vector2(0.0, -38.0 + bob), 19.0, Color(INK, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-15.0, -50.0 + bob), Vector2(-29.0, -74.0 + bob), Vector2(-4.0, -58.0 + bob)]), Color(CRIMSON, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(15.0, -50.0 + bob), Vector2(29.0, -74.0 + bob), Vector2(4.0, -58.0 + bob)]), Color(CRIMSON, alpha))
	draw_circle(Vector2(-7.0, -39.0 + bob), 4.0, Color("#fff0a6", alpha))
	draw_circle(Vector2(7.0, -39.0 + bob), 4.0, Color("#fff0a6", alpha))
	if boss_telegraph > 0.0:
		var warning_progress := 1.0 - boss_telegraph / 0.92
		draw_circle(Vector2.ZERO, 230.0 * warning_progress, Color(CRIMSON, 0.05))
		draw_arc(Vector2.ZERO, 230.0 * warning_progress, 0.0, TAU, 64, Color(CRIMSON, 0.78), 7.0, true)

func _draw_health_bar(alpha: float) -> void:
	var ratio := clampf(health / max_health, 0.0, 1.0)
	if boss:
		_draw_boss_health_bar(alpha, ratio)
		return
	var width := 82.0
	var y := -116.0
	var plate_top := y - 6.0
	var plate_bottom := y + 11.0
	var plate := PackedVector2Array([
		Vector2(-width * 0.5 - 9.0, plate_top), Vector2(width * 0.5 + 5.0, plate_top),
		Vector2(width * 0.5 + 9.0, plate_top + 4.0), Vector2(width * 0.5 + 5.0, plate_bottom),
		Vector2(-width * 0.5 - 5.0, plate_bottom), Vector2(-width * 0.5 - 9.0, plate_bottom - 4.0),
	])
	draw_colored_polygon(plate, Color(INK, 0.88 * alpha))
	draw_polyline(PackedVector2Array([plate[0], plate[1], plate[2], plate[3], plate[4], plate[5], plate[0]]), Color(CRIMSON, 0.68 * alpha), 1.3, true)
	var bar_left := -width * 0.5
	var bar_width := width
	var bar_y := y
	var bar_height := 5.0
	draw_rect(Rect2(bar_left, bar_y, bar_width, bar_height), Color("#332c28", 0.94 * alpha), true)
	draw_rect(Rect2(bar_left, bar_y, bar_width * ratio, bar_height), Color(CRIMSON, alpha), true)
	draw_line(Vector2(bar_left, bar_y), Vector2(bar_left + bar_width * ratio, bar_y), Color("#f2ddb0", 0.46 * alpha), 1.0, true)
	draw_circle(Vector2(bar_left - 4.0, bar_y + bar_height * 0.5), 2.2, Color(GOLD, 0.82 * alpha))


func _draw_boss_health_bar(alpha: float, ratio: float) -> void:
	# The HUD frame is split into an aspect-preserved crest and channel. This
	# keeps the authored pixels intact while the live title and health fill remain
	# readable native content.
	var physical := Vector2(DisplayServer.window_get_size())
	var phone := physical.x > physical.y and physical.x <= 960.0 and physical.y <= 540.0
	var viewport_size := get_viewport_rect().size
	var target_center := Vector2(physical.x * 0.5, 132.0) if phone else Vector2(viewport_size.x * 0.5, 54.0)
	var canvas_transform := get_canvas_transform()
	var canvas_scale := maxf(0.001, canvas_transform.basis_xform(Vector2.RIGHT).length())
	var screen_to_world := 1.0 / canvas_scale
	var canvas_position := canvas_transform.affine_inverse() * target_center
	var center := to_local(canvas_position)
	var desired_width := minf(390.0 if phone else 560.0, (physical.x if phone else viewport_size.x) - (280.0 if phone else 560.0))
	desired_width = maxf(desired_width, 330.0 if phone else 480.0)
	var width := desired_width * screen_to_world
	var channel_height := width * (88.0 / 752.0)
	var channel_rect := Rect2(center - Vector2(width, channel_height) * 0.5, Vector2(width, channel_height))
	draw_texture_rect(BOSS_HUD_CHANNEL, channel_rect, false, Color(1.0, 1.0, 1.0, alpha))

	var crest_size := (62.0 if phone else 82.0) * screen_to_world
	var crest_center := Vector2(channel_rect.position.x + crest_size * 0.42, center.y)
	var crest_rect := Rect2(crest_center - Vector2.ONE * crest_size * 0.5, Vector2.ONE * crest_size)
	draw_texture_rect(BOSS_HUD_CREST, crest_rect, false, Color(1.0, 1.0, 1.0, alpha))
	# The crest's right-hand flare overlaps the channel well beyond its circular
	# core. Start live content after that flare so title and fill never cross it.
	var content_left := channel_rect.position.x + crest_size * 1.14
	var content_width := channel_rect.end.x - content_left - 18.0 * screen_to_world
	var title_size := maxi(12, roundi((12.0 if phone else 14.0) * screen_to_world))
	var title := "THIÊN GIÁC" if phone else "THIÊN GIÁC  ·  MA CHỦ"
	draw_string(UI_FONT, Vector2(content_left, channel_rect.position.y + (18.0 if phone else 22.0) * screen_to_world), title, HORIZONTAL_ALIGNMENT_LEFT, content_width, title_size, Color("#e7ddc4", alpha))
	var bar_rect := Rect2(content_left, channel_rect.end.y - (18.0 if phone else 20.0) * screen_to_world, content_width, (7.0 if phone else 8.0) * screen_to_world)
	draw_rect(bar_rect, Color("#061012", 0.96 * alpha), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), Color("#b43d35", alpha), true)
	draw_line(bar_rect.position, Vector2(bar_rect.position.x + bar_rect.size.x * ratio, bar_rect.position.y), Color("#f0d184", 0.54 * alpha), 1.0 * screen_to_world, true)
	for index in range(1, 5):
		var tick_x := bar_rect.position.x + bar_rect.size.x * float(index) / 5.0
		draw_line(Vector2(tick_x, bar_rect.position.y + 1.0 * screen_to_world), Vector2(tick_x, bar_rect.end.y - 1.0 * screen_to_world), Color("#e7ddc4", 0.16 * alpha), 1.0 * screen_to_world, true)


func _phone_device_scale() -> float:
	var physical := Vector2(DisplayServer.window_get_size())
	if physical.x <= 1.0 or physical.y <= 1.0 or physical.x > 960.0 or physical.y > 540.0 or physical.x <= physical.y:
		return 1.0
	var logical := get_viewport_rect().size
	return maxf(1.0, minf(logical.x / physical.x, logical.y / physical.y))

func _draw_ink_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		var irregular := 1.0 + sin(float(index) * 2.21 + visual_seed) * 0.10
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y) * irregular)
	draw_colored_polygon(points, color)
