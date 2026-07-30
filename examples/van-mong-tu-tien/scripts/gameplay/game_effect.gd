class_name GameEffect
extends Node2D

# Resource-backed tuning belongs to the session; these values are presentation geometry.

const RuntimeVisualsScript := preload("res://scripts/gameplay/runtime_visuals.gd")

enum EffectKind { RING, BURST, HIT, PORTAL }

var kind := EffectKind.RING
var effect_color := Color("#6ee7bf")
var max_radius := 100.0
var lifetime := 0.45
var age := 0.0
var rays := 12
var visual_sprite: Sprite2D
var visual_base_scale := Vector2.ONE
var reduced_motion := false

func setup(effect_kind: int, color: Color, radius: float, duration: float = 0.45) -> GameEffect:
	kind = effect_kind
	effect_color = color
	max_radius = radius
	lifetime = maxf(duration, 0.05)
	var meta := get_node_or_null("/root/MetaProfile")
	if meta != null:
		var settings_value: Variant = meta.get("settings")
		if settings_value is Dictionary:
			reduced_motion = bool((settings_value as Dictionary).get("reduced_motion", false))
	_configure_runtime_sprite()
	_update_runtime_sprite()
	return self

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	_update_runtime_sprite()
	queue_redraw()

func _draw() -> void:
	var progress := clampf(age / lifetime, 0.0, 1.0)
	var fade := 1.0 - progress
	if visual_sprite != null and visual_sprite.texture != null:
		if kind == EffectKind.RING:
			var radius := lerpf(max_radius * 0.12, max_radius, ease(progress, -1.8))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(effect_color, fade * 0.82), 3.0 * fade + 1.0, true)
		elif kind == EffectKind.PORTAL:
			draw_arc(Vector2.ZERO, max_radius * 0.72, age * 2.0, age * 2.0 + PI * 1.2, 30, Color(effect_color, fade * 0.56), 2.0, true)
		return
	match kind:
		EffectKind.RING:
			var radius := lerpf(max_radius * 0.12, max_radius, ease(progress, -1.8))
			draw_circle(Vector2.ZERO, radius, Color(effect_color, fade * 0.055))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(effect_color, fade * 0.92), 6.0 * fade + 1.0, true)
			draw_arc(Vector2.ZERO, radius * 0.78, 0.0, TAU, 48, Color("#f3d98a", fade * 0.42), 2.0, true)
		EffectKind.BURST:
			for index in rays:
				var angle := TAU * float(index) / float(rays) + float(index % 2) * 0.11
				var start := Vector2.from_angle(angle) * max_radius * progress * 0.22
				var finish := Vector2.from_angle(angle) * max_radius * progress
				draw_line(start, finish, Color(effect_color, fade * 0.85), 4.0 * fade + 1.0, true)
			draw_circle(Vector2.ZERO, max_radius * (1.0 - progress) * 0.22, Color(effect_color, fade * 0.38))
		EffectKind.HIT:
			var size := max_radius * (0.35 + progress * 0.65)
			draw_line(Vector2(-size, 0.0), Vector2(size, 0.0), Color(effect_color, fade), 3.0, true)
			draw_line(Vector2(0.0, -size), Vector2(0.0, size), Color(effect_color, fade), 3.0, true)
			draw_circle(Vector2.ZERO, size * 0.24, Color(effect_color, fade * 0.45))
		EffectKind.PORTAL:
			var spin := age * 3.4
			for index in 3:
				var radius := max_radius * (0.45 + float(index) * 0.2) * (0.75 + progress * 0.25)
				var begin := spin + float(index) * 2.1
				draw_arc(Vector2.ZERO, radius, begin, begin + PI * 1.35, 30, Color(effect_color, fade * (0.8 - index * 0.14)), 4.0 - index, true)

func _configure_runtime_sprite() -> void:
	if visual_sprite != null:
		return
	var role := _runtime_role()
	if RuntimeVisualsScript.get_texture(role) == null:
		return
	visual_sprite = RuntimeVisualsScript.attach(self, role, max_radius * 2.0)
	if visual_sprite != null:
		visual_base_scale = visual_sprite.scale

func _runtime_role() -> StringName:
	match kind:
		EffectKind.RING:
			return &"effect_ring"
		EffectKind.BURST:
			return &"effect_burst"
		EffectKind.HIT:
			return &"effect_hit"
		EffectKind.PORTAL:
			return &"effect_portal"
	return &"effect_burst"

func _update_runtime_sprite() -> void:
	if visual_sprite == null:
		return
	var progress := clampf(age / maxf(lifetime, 0.01), 0.0, 1.0)
	var fade := 1.0 - progress
	var scale_factor := 1.0
	match kind:
		EffectKind.RING:
			scale_factor = lerpf(0.58 if reduced_motion else 0.12, 1.0, ease(progress, -1.8))
		EffectKind.BURST:
			scale_factor = lerpf(0.35, 1.0, progress)
		EffectKind.HIT:
			scale_factor = lerpf(0.45, 0.95, progress)
		EffectKind.PORTAL:
			scale_factor = 0.72 if reduced_motion else 0.72 + sin(age * 5.0) * 0.04
			visual_sprite.rotation = 0.0 if reduced_motion else age * 1.8
	visual_sprite.scale = visual_base_scale * scale_factor
	visual_sprite.modulate = Color(effect_color, fade)
