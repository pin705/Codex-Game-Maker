class_name QiOrb
extends Node2D

# Resource-backed XP tuning is supplied by the enemy/session contract.

const RuntimeVisualsScript := preload("res://scripts/gameplay/runtime_visuals.gd")

signal collected(value: float)

const JADE := Color("#62e2b2")
const PALE := Color("#e9ffdc")
const GOLD := Color("#f2c75c")

var xp_value := 5.0
var target: CultivatorPlayer
var age := 0.0
var pull_speed := 0.0
var phase := 0.0
var visual_sprite: Sprite2D
var visual_frames: Array = []
var visual_frame_index := 0

func _ready() -> void:
	visual_sprite = RuntimeVisualsScript.attach(self, &"qi_orb", 24.0)
	visual_frames = RuntimeVisualsScript.get_animation_frames(&"qi_orb")
	if not visual_frames.is_empty() and visual_sprite != null:
		RuntimeVisualsScript.configure(visual_sprite, visual_frames[0] as Texture2D, 24.0)

func setup(origin: Vector2, value: float, player: CultivatorPlayer) -> void:
	global_position = origin
	xp_value = value
	target = player
	phase = fmod(origin.x * 0.017 + origin.y * 0.031, TAU)
	if visual_sprite != null and visual_sprite.texture != null:
		RuntimeVisualsScript.configure(visual_sprite, visual_sprite.texture, 29.0 if xp_value >= 20.0 else 24.0)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if not is_instance_valid(target) or not target.enabled:
		_update_runtime_sprite()
		queue_redraw()
		return
	var distance := global_position.distance_to(target.global_position)
	var attraction_radius := target.magnet_radius
	if distance < attraction_radius or age > 12.0:
		pull_speed = minf(pull_speed + 720.0 * delta, 780.0)
		global_position = global_position.move_toward(target.global_position, pull_speed * delta)
	if distance <= target.pickup_radius:
		collected.emit(xp_value)
		queue_free()
		return
	_update_runtime_sprite()
	queue_redraw()

func _draw() -> void:
	var bob := sin(age * 4.2 + phase) * 3.0
	var pulse := 1.0 + sin(age * 5.4 + phase) * 0.12
	var tint := GOLD if xp_value >= 20.0 else JADE
	draw_circle(Vector2(0.0, bob), 14.0 * pulse, Color(tint, 0.08))
	if visual_sprite != null and visual_sprite.texture != null:
		draw_arc(Vector2(0.0, bob), 11.0 * pulse, age * 1.7, age * 1.7 + PI * 1.25, 18, Color(tint, 0.58), 1.5, true)
		return
	draw_circle(Vector2(0.0, bob), 7.0 * pulse, Color(tint, 0.52))
	draw_circle(Vector2(-1.5, -1.5 + bob), 3.2, PALE)
	draw_arc(Vector2(0.0, bob), 10.0 * pulse, age * 1.7, age * 1.7 + PI * 1.25, 18, Color(tint, 0.72), 1.5, true)

func _update_runtime_sprite() -> void:
	if visual_sprite == null:
		return
	if not visual_frames.is_empty():
		var next_frame := int(age * 8.0 + phase) % visual_frames.size()
		if next_frame != visual_frame_index:
			visual_frame_index = next_frame
			RuntimeVisualsScript.configure(visual_sprite, visual_frames[visual_frame_index] as Texture2D, 29.0 if xp_value >= 20.0 else 24.0)
	visual_sprite.position = Vector2(0.0, sin(age * 4.2 + phase) * 3.0)
	visual_sprite.rotation = sin(age * 1.6 + phase) * 0.08
