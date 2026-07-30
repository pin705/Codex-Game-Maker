class_name CultivationEnemy
extends CharacterBody2D

# Resource-backed profiles are configured by the session from game_balance.json.

const RuntimeVisualsScript := preload("res://scripts/gameplay/runtime_visuals.gd")

signal died(enemy: CultivationEnemy, death_position: Vector2, xp_value: float, was_boss: bool)
signal player_contact(damage: float)
signal boss_slam(origin: Vector2, radius: float, damage: float)

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
			boss_slam.emit(global_position, 230.0, contact_damage * 1.15)
			boss_cast_clock = 4.6
		return
	boss_cast_clock -= delta
	if boss_cast_clock <= 0.0:
		boss_telegraph = 0.92

func take_damage(amount: float, push_origin: Vector2, push_force: float = 110.0) -> bool:
	if dying:
		return false
	health -= amount
	if not boss:
		knockback_velocity += push_origin.direction_to(global_position) * push_force
	if health <= 0.0:
		dying = true
		died.emit(self, global_position, xp_value, boss)
		queue_free()
		return true
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
	var warning_progress := 1.0 - boss_telegraph / 0.92
	var pulse := 0.72 + sin(age * 18.0) * 0.18
	# The complete danger radius is visible from the first telegraph frame. The
	# advancing inner ring communicates timing without making players guess the
	# final hit area. Broken, unequal brush segments preserve that readability
	# while matching the dry-ink world instead of looking like a debug circle.
	draw_circle(Vector2.ZERO, 230.0, Color(CRIMSON, (0.075 + warning_progress * 0.055) * alpha))
	for segment in 18:
		var base_angle := TAU * float(segment) / 18.0
		var irregular := sin(float(segment) * 2.31 + visual_seed * 4.0) * 0.035
		var span := TAU / 18.0 * (0.70 + 0.10 * sin(float(segment) * 1.73))
		var radius := 230.0 + sin(float(segment) * 2.07 + visual_seed) * 2.8
		var width := 3.2 + float(segment % 4) * 0.65
		draw_arc(Vector2.ZERO, radius, base_angle + irregular, base_angle + irregular + span, 7, Color(CRIMSON, pulse * alpha), width, true)
	for segment in 10:
		var base_angle := -age * 0.42 + TAU * float(segment) / 10.0
		var span := TAU / 10.0 * (0.42 + 0.10 * float(segment % 3))
		draw_arc(Vector2.ZERO, 216.0 + float(segment % 2) * 2.0, base_angle, base_angle + span, 6, Color(GOLD, 0.54 * alpha), 2.0 + float(segment % 2), true)
	var advancing_radius := lerpf(72.0, 222.0, warning_progress)
	for segment in 14:
		var base_angle := TAU * float(segment) / 14.0 - age * 0.12
		var span := TAU / 14.0 * (0.62 + 0.08 * sin(float(segment) * 3.0))
		draw_arc(Vector2.ZERO, advancing_radius + float(segment % 3) * 1.4, base_angle, base_angle + span, 6, Color(PALE, 0.80 * alpha), 3.0 + float(segment % 2) * 1.5, true)
	for rune_index in 12:
		var angle := TAU * float(rune_index) / 12.0 + age * 0.12
		var rune_center := Vector2.from_angle(angle) * 223.0
		var tangent := Vector2.from_angle(angle + PI * 0.5)
		var normal := Vector2.from_angle(angle)
		draw_line(rune_center - tangent * 8.0, rune_center + tangent * 6.0, Color(GOLD, 0.64 * alpha), 2.4, true)
		draw_line(rune_center - tangent * 4.0 - normal * 4.0, rune_center + tangent * 3.0 + normal * 4.0, Color(CRIMSON, 0.54 * alpha), 1.4, true)

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
	var device_scale := _phone_device_scale() if boss else 1.0
	var phone_boss := boss and device_scale > 1.0
	var plaque_scale := minf(device_scale, 1.45 if phone_boss else 1.90)
	var width := 174.0 * plaque_scale if boss else 82.0
	# The desktop plaque lives above the boss. On a short phone viewport that
	# position collides with the device-space timer/pause islands whenever the
	# boss enters the upper-right fight lane, so the compact phone plaque is
	# grounded below the boss instead.
	var y := (106.0 if phone_boss else -180.0) if boss else -116.0
	var ratio := clampf(health / max_health, 0.0, 1.0)
	var plate_top := y - 17.0 * device_scale if boss else y - 6.0
	var plate_bottom := y + 16.0 * device_scale if boss else y + 11.0
	var plate := PackedVector2Array([
		Vector2(-width * 0.5 - 9.0, plate_top), Vector2(width * 0.5 + 5.0, plate_top),
		Vector2(width * 0.5 + 9.0, plate_top + 4.0), Vector2(width * 0.5 + 5.0, plate_bottom),
		Vector2(-width * 0.5 - 5.0, plate_bottom), Vector2(-width * 0.5 - 9.0, plate_bottom - 4.0),
	])
	draw_colored_polygon(plate, Color(INK, 0.88 * alpha))
	draw_polyline(PackedVector2Array([plate[0], plate[1], plate[2], plate[3], plate[4], plate[5], plate[0]]), Color(GOLD if boss else CRIMSON, 0.68 * alpha), 1.3 * device_scale if boss else 1.3, true)
	if boss:
		# The phone HUD is rendered from the expanded world canvas and then
		# compensated back into device space. Keep the plaque title short there so
		# the boss identity remains fully readable at the real 844x390 scale.
		var boss_label := "THIÊN GIÁC" if phone_boss else "THIÊN GIÁC  ·  MA CHỦ"
		draw_string(ThemeDB.fallback_font, Vector2(-width * 0.5, y - 3.0 * device_scale), boss_label, HORIZONTAL_ALIGNMENT_CENTER, width, maxi(12, roundi(12.0 * device_scale)), Color(PALE, 0.96 * alpha))
	var bar_y := y + 4.0 * device_scale if boss else y
	var bar_height := 7.0 * device_scale if boss else 5.0
	draw_rect(Rect2(-width * 0.5, bar_y, width, bar_height), Color("#332c28", 0.92 * alpha), true)
	draw_rect(Rect2(-width * 0.5, bar_y, width * ratio, bar_height), Color(CRIMSON if boss else CRIMSON, alpha), true)
	draw_line(Vector2(-width * 0.5, bar_y), Vector2(-width * 0.5 + width * ratio, bar_y), Color("#f2ddb0", 0.46 * alpha), device_scale if boss else 1.0, true)
	draw_circle(Vector2(-width * 0.5 - 4.0 * device_scale, bar_y + bar_height * 0.5), 2.2 * device_scale if boss else 2.2, Color(GOLD, 0.82 * alpha))


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
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
