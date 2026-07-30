class_name JadeProjectile
extends Node2D

# Resource-backed damage/speed values are supplied by the session at setup time.

const RuntimeVisualsScript := preload("res://scripts/gameplay/runtime_visuals.gd")

const JADE := Color("#63dfb4")
const PALE := Color("#e7ffe9")
const GOLD := Color("#f2c75c")
const INK := Color("#10262a")

var direction := Vector2.RIGHT
var speed := 690.0
var damage := 22.0
var lifetime := 1.45
var pierce_remaining := 0
var age := 0.0
var radius := 13.0
var hit_instances: Dictionary = {}
var empowered := false
var visual_sprite: Sprite2D
var visual_frames: Array = []
var visual_frame_index := 0

func setup(origin: Vector2, target_position: Vector2, shot_damage: float, shot_speed: float, shot_lifetime: float, pierce: int, is_empowered: bool = false) -> void:
	global_position = origin
	direction = origin.direction_to(target_position)
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	speed = shot_speed
	damage = shot_damage
	lifetime = shot_lifetime
	pierce_remaining = pierce
	empowered = is_empowered
	rotation = direction.angle()
	_configure_runtime_sprite()
	_update_runtime_sprite_feedback()
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	global_position += direction * speed * delta
	if age >= lifetime:
		queue_free()
		return
	_update_runtime_animation()
	_update_runtime_sprite_feedback()
	queue_redraw()

func can_hit(instance_id: int) -> bool:
	return not hit_instances.has(instance_id)

func register_hit(instance_id: int) -> void:
	hit_instances[instance_id] = true
	if pierce_remaining <= 0:
		queue_free()
	else:
		pierce_remaining -= 1

func _draw() -> void:
	var fade := clampf((lifetime - age) * 5.0, 0.0, 1.0)
	var trail_color := GOLD if empowered else JADE
	for index in 4:
		var trail_x := -22.0 - float(index) * 11.0
		draw_line(Vector2(trail_x, 0.0), Vector2(trail_x - 15.0, 0.0), Color(trail_color, fade * (0.32 - index * 0.055)), 7.0 - index, true)
	if empowered:
		draw_circle(Vector2(-6.0, 0.0), 18.0 + sin(age * 18.0) * 2.0, Color(GOLD, 0.11 * fade))
	if visual_sprite != null and visual_sprite.texture != null:
		return
	# A compact flying sword silhouette.
	var blade := PackedVector2Array([
		Vector2(24.0, 0.0), Vector2(7.0, -5.0), Vector2(-13.0, -3.0),
		Vector2(-13.0, 3.0), Vector2(7.0, 5.0)
	])
	draw_colored_polygon(blade, Color(PALE, fade))
	draw_polyline(blade, Color(INK, fade), 1.8, true)
	draw_line(Vector2(-12.0, -8.0), Vector2(-12.0, 8.0), Color(GOLD, fade), 3.0, true)
	draw_line(Vector2(-16.0, 0.0), Vector2(-23.0, 0.0), Color(INK, fade), 4.0, true)
	draw_circle(Vector2(3.0, 0.0), 2.4, Color(trail_color, fade))

func _configure_runtime_sprite() -> void:
	if visual_sprite != null:
		return
	var role := &"projectile_phoenix" if empowered else &"projectile_sword"
	var texture := RuntimeVisualsScript.get_texture(role)
	if texture == null and empowered:
		role = &"projectile_sword"
		texture = RuntimeVisualsScript.get_texture(role)
	if texture == null:
		return
	# Authored sword art is a wide 58x20 px silhouette; scale from its visible
	# height so the blade does not become a 200 px billboard in combat.
	visual_sprite = RuntimeVisualsScript.attach(self, role, 20.0 if not empowered else 24.0)
	visual_frames = RuntimeVisualsScript.get_animation_frames(role)
	if not visual_frames.is_empty() and visual_sprite != null:
		RuntimeVisualsScript.configure(visual_sprite, visual_frames[0] as Texture2D, 20.0 if not empowered else 24.0)

func _update_runtime_animation() -> void:
	if visual_sprite == null or visual_frames.size() <= 1:
		return
	var next_frame := int(age * 12.0) % visual_frames.size()
	if next_frame == visual_frame_index:
		return
	visual_frame_index = next_frame
	RuntimeVisualsScript.configure(visual_sprite, visual_frames[visual_frame_index] as Texture2D, 20.0 if not empowered else 24.0)

func _update_runtime_sprite_feedback() -> void:
	if visual_sprite == null:
		return
	var fade := clampf((lifetime - age) * 5.0, 0.0, 1.0)
	visual_sprite.modulate = Color(1.0, 0.96, 0.78, fade) if empowered else Color(1.0, 1.0, 1.0, fade)
