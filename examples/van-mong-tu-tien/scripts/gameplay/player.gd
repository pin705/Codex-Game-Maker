class_name CultivatorPlayer
extends CharacterBody2D

# Resource-backed movement and survival tuning arrives through setup().

const RuntimeVisualsScript := preload("res://scripts/gameplay/runtime_visuals.gd")

signal died

const JADE := Color("#63dfb4")
const JADE_BRIGHT := Color("#bbffe3")
const JADE_DARK := Color("#236b5f")
const GOLD := Color("#f1c75b")
const INK := Color("#10262a")
const ROBE := Color("#d6d3bd")
const RUNTIME_BODY_HEIGHT := 76.0

var arena_rect := Rect2(54.0, 54.0, 1492.0, 792.0)
var max_health := 120.0
var health := 120.0
var move_speed := 305.0
var health_regen := 0.45
var contact_invulnerability := 0.55
var pickup_radius := 42.0
var magnet_radius := 180.0

var damage_multiplier := 1.0
var attack_speed_multiplier := 1.0
var projectile_speed_multiplier := 1.0
var extra_projectiles := 0
var projectile_pierce := 0
var pulse_power_multiplier := 1.0
var pulse_radius_multiplier := 1.0
var xp_multiplier := 1.0
var damage_taken_multiplier := 1.0

var invulnerability_remaining := 0.0
var visual_time := 0.0
var hit_flash := 0.0
var last_move := Vector2.DOWN
var enabled := false
var visual_state: StringName = &"idle"
var visual_sprite: Sprite2D
var visual_frames: Array = []
var visual_frame_index := 0
var visual_frame_clock := 0.0

func _ready() -> void:
	_configure_runtime_sprite()

func setup(bounds: Rect2, config: Dictionary) -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	arena_rect = bounds
	max_health = float(config.get("max_health", max_health))
	health = max_health
	move_speed = float(config.get("move_speed", move_speed))
	health_regen = float(config.get("health_regen", health_regen))
	contact_invulnerability = float(config.get("contact_invulnerability", contact_invulnerability))
	pickup_radius = float(config.get("pickup_radius", pickup_radius))
	magnet_radius = float(config.get("magnet_radius", magnet_radius))
	xp_multiplier = float(config.get("xp_multiplier", xp_multiplier))
	damage_taken_multiplier = float(config.get("damage_taken_multiplier", damage_taken_multiplier))
	Events.player_health_changed.emit(health, max_health)
	queue_redraw()


func update_bounds(bounds: Rect2) -> void:
	# Runtime viewport changes (rotation/window resize/ultrawide) must not reset
	# health or progression. Only the playable clamp rectangle changes here.
	arena_rect = bounds
	global_position.x = clampf(global_position.x, arena_rect.position.x, arena_rect.end.x)
	global_position.y = clampf(global_position.y, arena_rect.position.y, arena_rect.end.y)

func _physics_process(delta: float) -> void:
	visual_time += delta
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	if not enabled:
		velocity = Vector2.ZERO
		_set_visual_state(&"idle")
		_update_runtime_sprite_feedback()
		queue_redraw()
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = direction * move_speed
	if direction.length_squared() > 0.01:
		last_move = direction.normalized()
	_set_visual_state(&"move" if direction.length_squared() > 0.01 else &"idle")
	_update_runtime_animation(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, arena_rect.position.x, arena_rect.end.x)
	global_position.y = clampf(global_position.y, arena_rect.position.y, arena_rect.end.y)
	if health < max_health and health_regen > 0.0:
		heal(health_regen * delta, false)
	_update_runtime_sprite_feedback()
	queue_redraw()

func take_damage(amount: float) -> bool:
	if not enabled or invulnerability_remaining > 0.0 or health <= 0.0:
		return false
	health = maxf(0.0, health - amount * damage_taken_multiplier)
	invulnerability_remaining = contact_invulnerability
	hit_flash = 0.16
	_update_runtime_sprite_feedback()
	Events.player_health_changed.emit(health, max_health)
	if health <= 0.0:
		enabled = false
		died.emit()
	return true

func heal(amount: float, announce: bool = true) -> void:
	var previous := health
	health = minf(max_health, health + amount)
	if announce and not is_equal_approx(previous, health):
		Events.player_health_changed.emit(health, max_health)
	elif int(previous) != int(health):
		Events.player_health_changed.emit(health, max_health)

func increase_max_health(amount: float) -> void:
	max_health += amount
	health = minf(max_health, health + amount)
	Events.player_health_changed.emit(health, max_health)

func _draw() -> void:
	var moving := velocity.length_squared() > 1.0
	var bob := sin(visual_time * (9.0 if moving else 3.0)) * (1.8 if moving else 1.1)
	var breathe := 1.0 + sin(visual_time * 2.4) * 0.025
	var alpha := 0.38 if invulnerability_remaining > 0.0 and int(invulnerability_remaining * 18.0) % 2 == 0 else 1.0
	var flash_color := Color.WHITE if hit_flash > 0.0 else ROBE

	# Shadow and cultivation aura.
	# Authored frames use a feet pivot, so the contact shadow belongs at the
	# node origin rather than floating a body-height below the cultivator.
	_draw_ink_ellipse(Vector2(0.0, 3.0), Vector2(27.0, 9.0), Color(0.0, 0.0, 0.0, 0.30 * alpha))
	draw_circle(Vector2.ZERO, 34.0 + sin(visual_time * 2.0) * 2.0, Color(JADE, 0.035 * alpha))
	draw_arc(Vector2.ZERO, 31.0 + sin(visual_time * 1.8), -PI * 0.15 + visual_time * 0.18, PI * 1.25 + visual_time * 0.18, 30, Color(JADE, 0.26 * alpha), 2.0, true)
	if visual_sprite != null and visual_sprite.texture != null:
		return

	# Ink-wash robe, kept centered so locomotion does not jitter.
	var robe_points := PackedVector2Array([
		Vector2(-17.0, -7.0 + bob), Vector2(-25.0, 23.0 + bob),
		Vector2(-8.0, 27.0 + bob), Vector2(0.0, 21.0 + bob),
		Vector2(9.0, 27.0 + bob), Vector2(25.0, 23.0 + bob),
		Vector2(17.0, -7.0 + bob)
	])
	draw_colored_polygon(robe_points, Color(flash_color, alpha))
	draw_polyline(robe_points, Color(INK, 0.78 * alpha), 2.2, true)
	draw_line(Vector2(0.0, -5.0 + bob), Vector2(0.0, 22.0 + bob), Color(JADE_DARK, 0.82 * alpha), 3.0, true)
	draw_line(Vector2(-18.0, 7.0 + bob), Vector2(18.0, 7.0 + bob), Color(GOLD, 0.86 * alpha), 3.0, true)

	# Head, hair knot, and jade focus.
	draw_circle(Vector2(0.0, -19.0 + bob) * Vector2(1.0, breathe), 11.5, Color("#d8b08c", alpha))
	draw_arc(Vector2(0.0, -20.0 + bob), 11.5, PI, TAU, 18, Color(INK, alpha), 6.0, true)
	draw_circle(Vector2(0.0, -34.0 + bob), 4.8, Color(INK, alpha))
	draw_circle(Vector2(0.0, -35.5 + bob), 2.1, Color(GOLD, alpha))
	draw_circle(Vector2(0.0, 8.0 + bob), 4.2, Color(JADE_BRIGHT, 0.95 * alpha))
	draw_circle(Vector2(0.0, 8.0 + bob), 9.0, Color(JADE, 0.11 * alpha))

	# Restrained alternating feet/hand accents communicate movement.
	var stride := sin(visual_time * 10.0) * 3.0 if moving else 0.0
	draw_line(Vector2(-8.0, 24.0 + bob), Vector2(-8.0 + stride, 30.0 + bob), Color(INK, alpha), 4.0, true)
	draw_line(Vector2(8.0, 24.0 + bob), Vector2(8.0 - stride, 30.0 + bob), Color(INK, alpha), 4.0, true)

func _configure_runtime_sprite() -> void:
	var idle_texture := RuntimeVisualsScript.get_texture(&"player_idle")
	var move_texture := RuntimeVisualsScript.get_texture(&"player_move")
	if idle_texture == null and move_texture == null:
		return
	var initial_role := &"player_idle" if idle_texture != null else &"player_move"
	visual_sprite = RuntimeVisualsScript.attach(self, initial_role, RUNTIME_BODY_HEIGHT)
	_set_visual_state(&"idle", true)
	_update_runtime_sprite_feedback()

func _set_visual_state(next_state: StringName, force: bool = false) -> void:
	if not force and visual_state == next_state:
		return
	visual_state = next_state
	if visual_sprite == null:
		return
	var preferred_role := &"player_move" if visual_state == &"move" else &"player_idle"
	visual_frames = RuntimeVisualsScript.get_animation_frames(preferred_role)
	visual_frame_index = 0
	visual_frame_clock = 0.0
	if not visual_frames.is_empty():
		RuntimeVisualsScript.configure(visual_sprite, visual_frames[0] as Texture2D, RUNTIME_BODY_HEIGHT)
	elif not RuntimeVisualsScript.swap(visual_sprite, preferred_role, RUNTIME_BODY_HEIGHT):
		var fallback_role := &"player_idle" if preferred_role == &"player_move" else &"player_move"
		visual_frames = RuntimeVisualsScript.get_animation_frames(fallback_role)
		if not visual_frames.is_empty():
			RuntimeVisualsScript.configure(visual_sprite, visual_frames[0] as Texture2D, RUNTIME_BODY_HEIGHT)
		else:
			RuntimeVisualsScript.swap(visual_sprite, fallback_role, RUNTIME_BODY_HEIGHT)

func _update_runtime_animation(delta: float) -> void:
	if visual_sprite == null or visual_frames.size() <= 1:
		return
	visual_frame_clock += delta
	var frame_duration := 1.0 / (7.0 if visual_state == &"move" else 6.0)
	while visual_frame_clock >= frame_duration:
		visual_frame_clock -= frame_duration
		visual_frame_index = (visual_frame_index + 1) % visual_frames.size()
		RuntimeVisualsScript.configure(visual_sprite, visual_frames[visual_frame_index] as Texture2D, RUNTIME_BODY_HEIGHT)

func _update_runtime_sprite_feedback() -> void:
	if visual_sprite == null:
		return
	if absf(last_move.x) > 0.05:
		visual_sprite.flip_h = last_move.x < 0.0
	var alpha := 0.38 if invulnerability_remaining > 0.0 and int(invulnerability_remaining * 18.0) % 2 == 0 else 1.0
	var tint := Color(1.35, 0.82, 0.82, alpha) if hit_flash > 0.0 else Color(1.0, 1.0, 1.0, alpha)
	visual_sprite.modulate = tint

func _draw_ink_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
