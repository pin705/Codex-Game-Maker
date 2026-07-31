class_name CultivationVFX
extends Node2D

## Rank-aware cultivation presentation that can be attached without coupling it
## to the combat simulation. Add this node anywhere in the gameplay scene, call
## configure(), then either follow_actor() once or update_actor()/move_to() from
## the owning actor. Trigger methods are intentionally fire-and-forget.

signal configuration_changed(discipline: StringName, technique_ranks: Dictionary)
signal effect_triggered(kind: StringName, intensity: int)

const DISCIPLINE_SWORD := &"van_kiem"
const DISCIPLINE_QI := &"tu_linh"
const DISCIPLINE_VITALITY := &"ngoc_the"

const MAX_TECHNIQUE_RANK := 5
const DESKTOP_PARTICLE_BUDGET := 72
const MOBILE_PARTICLE_BUDGET := 38
const REDUCED_MOTION_PARTICLE_BUDGET := 22
const DESKTOP_TRANSIENT_CAP := 10
const MOBILE_TRANSIENT_CAP := 6
const REDUCED_MOTION_TRANSIENT_CAP := 4

const INK := Color("#10262a")
const DEEP_INK := Color("#081719")
const PAPER := Color("#f2e5bd")
const PALE_JADE := Color("#c8ffe5")
const JADE := Color("#63dfb4")
const JADE_DARK := Color("#236b5f")
const QI_BLUE := Color("#70d9d4")
const GOLD := Color("#f1c75b")
const GOLD_PALE := Color("#fff0a6")
const VERMILION := Color("#b94d3d")

var discipline: StringName = DISCIPLINE_SWORD
var technique_ranks: Dictionary = {
	"sword_damage": 0,
	"vitality": 0,
	"magnet": 0,
}
var reduced_motion := false

var _actor: Node2D
var _facing := Vector2.RIGHT
var _actor_velocity := Vector2.ZERO
var _phase_time := 0.0
var _lifetime_time := 0.0
var _redraw_clock := 0.0
var _sequence := 0
var _mobile_mode := false
var _motion_override := false

var _sword_rank := 0
var _vitality_rank := 0
var _magnet_rank := 0
var _sword_count := 0
var _ward_facets := 0
var _ward_glyphs := 0
var _qi_tendrils := 0
var _particle_budget := DESKTOP_PARTICLE_BUDGET
var _transient_cap := DESKTOP_TRANSIENT_CAP
var _draw_budget_remaining := DESKTOP_PARTICLE_BUDGET

var _attack_events: Array[Dictionary] = []
var _hit_events: Array[Dictionary] = []
var _pickup_events: Array[Dictionary] = []
var _skill_events: Array[Dictionary] = []


func _ready() -> void:
	top_level = true
	z_index = 4
	_mobile_mode = (
		OS.has_feature("mobile")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)
	if not _motion_override:
		_read_profile_motion_setting()
	_refresh_visual_tuning()
	queue_redraw()


## Configures all three permanent ranks. Unknown disciplines safely fall back
## to Vạn Kiếm and rank values are clamped to the progression contract (0..5).
func configure(next_discipline: StringName, next_technique_ranks: Dictionary) -> CultivationVFX:
	if next_discipline in [DISCIPLINE_SWORD, DISCIPLINE_QI, DISCIPLINE_VITALITY]:
		discipline = next_discipline
	else:
		discipline = DISCIPLINE_SWORD
	technique_ranks = {
		"sword_damage": _rank_from(next_technique_ranks, "sword_damage"),
		"vitality": _rank_from(next_technique_ranks, "vitality"),
		"magnet": _rank_from(next_technique_ranks, "magnet"),
	}
	if not _motion_override:
		_read_profile_motion_setting()
	_refresh_visual_tuning()
	configuration_changed.emit(discipline, technique_ranks.duplicate(true))
	queue_redraw()
	return self


## Bind once when the VFX node is owned by main rather than by the actor.
func follow_actor(actor: Node2D) -> CultivationVFX:
	_actor = actor
	update_actor(actor)
	return self


func stop_following() -> void:
	_actor = null
	_actor_velocity = Vector2.ZERO


## Safe to call every physics tick. A facing hint is optional; CharacterBody2D
## velocity is used automatically and the last non-zero direction is retained.
func update_actor(actor: Node2D, facing_hint: Vector2 = Vector2.ZERO) -> void:
	if actor == null or not is_instance_valid(actor):
		stop_following()
		return
	_actor = actor
	var velocity_hint := Vector2.ZERO
	if actor is CharacterBody2D:
		velocity_hint = (actor as CharacterBody2D).velocity
	var resolved_facing := facing_hint
	if resolved_facing.length_squared() <= 0.0001:
		resolved_facing = velocity_hint
	move_to(actor.global_position, resolved_facing, velocity_hint)


## Position-only integration for actors that do not expose a Node2D reference.
func move_to(
	world_position: Vector2,
	facing_hint: Vector2 = Vector2.ZERO,
	actor_velocity: Vector2 = Vector2.ZERO
) -> void:
	global_position = world_position
	global_rotation = 0.0
	_actor_velocity = actor_velocity
	if facing_hint.length_squared() > 0.0001:
		_facing = facing_hint.normalized()


## Explicit accessibility override for previews/tests or games without the
## MetaProfile autoload. configure() otherwise reads settings.reduced_motion.
func set_reduced_motion(enabled: bool) -> void:
	_motion_override = true
	reduced_motion = enabled
	_refresh_visual_tuning()
	queue_redraw()


func use_profile_motion_setting() -> void:
	_motion_override = false
	_read_profile_motion_setting()
	_refresh_visual_tuning()
	queue_redraw()


## Outward sword fan. The argument may be omitted; the last actor facing wins.
func trigger_attack(direction: Vector2 = Vector2.ZERO) -> void:
	var resolved_direction := _normalized_or(direction, _facing)
	var blades := _attack_blade_count()
	_push_transient(_attack_events, {
		"age": 0.0,
		"lifetime": 0.26 if reduced_motion else 0.44,
		"direction": resolved_direction,
		"blades": blades,
		"rank": _sword_rank,
		"sequence": _next_sequence(),
	})
	effect_triggered.emit(&"attack", blades)
	queue_redraw()


## Jade shell flare and faceted impact shards. Works for all disciplines, but
## Ngọc Thể/vitality ranks visibly increase the shell and shard density.
func trigger_hit(impact_direction: Vector2 = Vector2.ZERO) -> void:
	var resolved_direction := _normalized_or(impact_direction, -_facing)
	var shards := clampi(4 + _vitality_rank * 2 + (2 if discipline == DISCIPLINE_VITALITY else 0), 4, 14)
	if reduced_motion:
		shards = mini(shards, 6)
	elif _mobile_mode:
		shards = mini(shards, 10)
	_push_transient(_hit_events, {
		"age": 0.0,
		"lifetime": 0.30 if reduced_motion else 0.55,
		"direction": resolved_direction,
		"shards": shards,
		"rank": _vitality_rank,
		"sequence": _next_sequence(),
	})
	effect_triggered.emit(&"hit", shards)
	queue_redraw()


## Curved gathering beam from a world-space pickup into the actor. Omitting the
## source creates a short representative beam from the edge of the qi field.
func trigger_pickup(source_global_position: Vector2 = Vector2(1.0e20, 1.0e20)) -> void:
	var source := source_global_position
	if not _is_finite_vector(source) or source.length_squared() > 1.0e30:
		var angle := float(_sequence % 7) * 0.83 + 0.35
		source = global_position + Vector2.from_angle(angle) * _qi_field_radius() * 1.35
	var motes := clampi(2 + _magnet_rank, 2, 7)
	if reduced_motion:
		motes = mini(motes, 3)
	elif _mobile_mode:
		motes = mini(motes, 5)
	_push_transient(_pickup_events, {
		"age": 0.0,
		"lifetime": 0.34 if reduced_motion else 0.62,
		"source_global": source,
		"motes": motes,
		"rank": _magnet_rank,
		"sequence": _next_sequence(),
	})
	effect_triggered.emit(&"pickup", motes)
	queue_redraw()


## Player-facing skill VFX contract. Every learned skill can now express a
## distinct cast, travel and impact beat without asking the simulation to own
## drawing state. Positions are world-space so projectile/pet/boss callers can
## share the same top-level presentation node.
func trigger_skill_cast(skill_id: StringName, rank: int, direction: Vector2 = Vector2.ZERO) -> void:
	_push_skill_event(&"cast", skill_id, rank, global_position, direction)


func trigger_skill_travel(skill_id: StringName, rank: int, world_position: Vector2, direction: Vector2) -> void:
	_push_skill_event(&"travel", skill_id, rank, world_position, direction)


func trigger_skill_impact(skill_id: StringName, rank: int, world_position: Vector2) -> void:
	_push_skill_event(&"impact", skill_id, rank, world_position, _facing)


func _push_skill_event(phase: StringName, skill_id: StringName, rank: int, world_position: Vector2, direction: Vector2) -> void:
	var safe_skill := _canonical_skill_id(skill_id)
	var lifetime := 0.46
	match phase:
		&"cast":
			lifetime = 0.30 if reduced_motion else 0.48
		&"travel":
			lifetime = 0.24 if reduced_motion else 0.38
		&"impact":
			lifetime = 0.28 if reduced_motion else 0.46
	_push_transient(_skill_events, {
		"age": 0.0,
		"lifetime": lifetime,
		"phase": phase,
		"skill_id": safe_skill,
		"rank": clampi(rank, 0, 6),
		"position_global": world_position if _is_finite_vector(world_position) else global_position,
		"direction": _normalized_or(direction, _facing),
		"sequence": _next_sequence(),
	})
	effect_triggered.emit(StringName("skill_%s_%s" % [String(safe_skill), String(phase)]), clampi(rank, 0, 6))
	queue_redraw()


## Deterministic inspection contract used by headless tests and an optional
## in-game performance HUD. No rendering internals need to be reached directly.
func debug_snapshot() -> Dictionary:
	return {
		"discipline": String(discipline),
		"technique_ranks": technique_ranks.duplicate(true),
		"reduced_motion": reduced_motion,
		"mobile_mode": _mobile_mode,
		"particle_budget": _particle_budget,
		"transient_cap": _transient_cap,
		"sword_count": _sword_count,
		"attack_blades": _attack_blade_count(),
		"ward_facets": _ward_facets,
		"ward_glyphs": _ward_glyphs,
		"qi_tendrils": _qi_tendrils,
		"trail_samples": _trail_samples(),
		"active_attacks": _attack_events.size(),
		"active_hits": _hit_events.size(),
		"active_pickups": _pickup_events.size(),
		"active_skill_events": _skill_events.size(),
		"active_skill_casts": _skill_phase_count(&"cast"),
		"active_skill_travels": _skill_phase_count(&"travel"),
		"active_skill_impacts": _skill_phase_count(&"impact"),
		"active_transients": _active_transient_count(),
		"following_actor": _actor != null and is_instance_valid(_actor),
		"facing": _facing,
	}


func clear_transients() -> void:
	_attack_events.clear()
	_hit_events.clear()
	_pickup_events.clear()
	_skill_events.clear()
	queue_redraw()


func _process(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	_lifetime_time += safe_delta
	_phase_time += safe_delta * (0.18 if reduced_motion else 1.0)
	if _actor != null:
		if is_instance_valid(_actor):
			update_actor(_actor)
		else:
			stop_following()
	_tick_events(_attack_events, safe_delta)
	_tick_events(_hit_events, safe_delta)
	_tick_events(_pickup_events, safe_delta)
	_tick_events(_skill_events, safe_delta)
	_redraw_clock += safe_delta
	var redraw_interval := 1.0 / (12.0 if reduced_motion else (30.0 if _mobile_mode else 60.0))
	if _redraw_clock >= redraw_interval:
		_redraw_clock = fmod(_redraw_clock, redraw_interval)
		queue_redraw()


func _draw() -> void:
	_draw_budget_remaining = _particle_budget
	if _magnet_rank > 0 or discipline == DISCIPLINE_QI:
		_draw_qi_field()
	if _vitality_rank > 0 or discipline == DISCIPLINE_VITALITY:
		_draw_ward_shell()
	if _sword_rank > 0 or discipline == DISCIPLINE_SWORD:
		_draw_orbiting_swords()
	for event: Dictionary in _pickup_events:
		_draw_pickup_event(event)
	for event: Dictionary in _attack_events:
		_draw_attack_event(event)
	for event: Dictionary in _hit_events:
		_draw_hit_event(event)
	for event: Dictionary in _skill_events:
		_draw_skill_event(event)


func _draw_orbiting_swords() -> void:
	if _sword_count <= 0:
		return
	var orbit_x := 48.0 + float(_sword_rank) * 5.5
	var orbit_y := 22.0 + float(_sword_rank) * 2.3
	var movement_lean := clampf(_actor_velocity.length() / 500.0, 0.0, 0.22)
	var orbit_phase := 0.30 if reduced_motion else _phase_time * (0.72 + float(_sword_rank) * 0.035)
	for index in _sword_count:
		if not _take_draw_budget():
			break
		var angle := orbit_phase + TAU * float(index) / float(maxi(_sword_count, 1))
		var position := Vector2(cos(angle) * orbit_x, sin(angle) * orbit_y - 7.0)
		position += _facing * movement_lean * 14.0
		var tangent := Vector2(-sin(angle) * orbit_x, cos(angle) * orbit_y).normalized()
		var trail := PackedVector2Array()
		for sample in _trail_samples():
			var sample_angle := angle - float(sample + 1) * 0.075
			trail.append(Vector2(cos(sample_angle) * orbit_x, sin(sample_angle) * orbit_y - 7.0))
		if trail.size() >= 2:
			draw_polyline(trail, Color(INK, 0.18), 5.0, true)
			draw_polyline(trail, Color(JADE, 0.34 + float(_sword_rank) * 0.025), 1.6, true)
		_draw_sword(position, tangent, 0.72 + float(_sword_rank) * 0.025, 0.90)


func _draw_attack_event(event: Dictionary) -> void:
	var progress := _event_progress(event)
	var fade := 1.0 - progress
	var direction: Vector2 = event.get("direction", _facing)
	var blades := int(event.get("blades", 3))
	var rank := int(event.get("rank", 0))
	var spread := 0.68 + float(mini(rank, 3)) * 0.05
	var travel := lerpf(26.0, 142.0 + float(rank) * 13.0, ease(progress, -1.65))

	# The fan seal anchors the burst so it reads as a sword technique rather than
	# an anonymous radial particle spray.
	var base_angle := direction.angle()
	for band in 2:
		var radius := 24.0 + float(band) * 10.0 + progress * 16.0
		draw_arc(Vector2.ZERO, radius, base_angle - spread * 0.72, base_angle + spread * 0.72, 24, Color(GOLD if band == 0 else JADE, fade * (0.42 - float(band) * 0.10)), 2.2 - float(band) * 0.5, true)
	for index in blades:
		if not _take_draw_budget():
			break
		var ratio := 0.5 if blades <= 1 else float(index) / float(blades - 1)
		var angle_offset := lerpf(-spread, spread, ratio)
		var blade_direction := direction.rotated(angle_offset)
		var stagger := float(index % 2) * 9.0
		var blade_position := blade_direction * (travel - stagger)
		var trail_start := blade_direction * maxf(12.0, travel - 54.0 - float(rank) * 4.0)
		draw_line(trail_start, blade_position, Color(INK, fade * 0.30), 8.0, true)
		draw_line(trail_start, blade_position, Color(JADE, fade * 0.68), 2.4, true)
		if rank >= 3 and not reduced_motion:
			var side := blade_direction.orthogonal() * (3.0 + float(index % 3))
			draw_line(trail_start + side, blade_position + side * 0.3, Color(GOLD, fade * 0.34), 1.2, true)
		_draw_sword(blade_position, blade_direction, 0.78 + float(rank) * 0.035, fade)


func _draw_ward_shell() -> void:
	if _ward_facets <= 0:
		return
	var radius := 42.0 + float(_vitality_rank) * 5.0 + (5.0 if discipline == DISCIPLINE_VITALITY else 0.0)
	var pulse := 0.0 if reduced_motion else sin(_phase_time * 1.75) * 1.8
	var phase := 0.10 if reduced_motion else _phase_time * 0.11
	var outer := Vector2(radius + pulse, (radius + pulse) * 0.78)
	var inner := outer * 0.83
	for index in _ward_facets:
		var a0 := phase + TAU * float(index) / float(_ward_facets)
		var a1 := phase + TAU * float(index + 1) / float(_ward_facets)
		var facet := PackedVector2Array([
			_ellipse_point(a0, outer) + Vector2(0.0, -8.0),
			_ellipse_point(a1, outer) + Vector2(0.0, -8.0),
			_ellipse_point(a1, inner) + Vector2(0.0, -8.0),
			_ellipse_point(a0, inner) + Vector2(0.0, -8.0),
		])
		var facet_alpha := 0.065 + float((index + _vitality_rank) % 3) * 0.018
		draw_colored_polygon(facet, Color(JADE, facet_alpha))
		draw_polyline(_closed(facet), Color(GOLD if index % 3 == 0 else PALE_JADE, 0.24 + float(_vitality_rank) * 0.025), 1.1, true)

	# Partial shell seams keep the silhouette faceted instead of a plain circle.
	for seam in 3:
		var start := phase + float(seam) * TAU / 3.0 + 0.12
		var points := _ellipse_arc_points(outer * (0.92 - float(seam) * 0.025), start, start + 0.72, 14, Vector2(0.0, -8.0))
		draw_polyline(points, Color(PALE_JADE, 0.44), 1.6, true)

	for glyph_index in _ward_glyphs:
		if not _take_draw_budget():
			break
		var glyph_angle := phase * -1.4 + TAU * float(glyph_index) / float(maxi(_ward_glyphs, 1))
		var glyph_position := _ellipse_point(glyph_angle, inner * 0.88) + Vector2(0.0, -8.0)
		_draw_ward_glyph(glyph_position, glyph_angle + PI * 0.5, 0.48 + float(_vitality_rank) * 0.055, 0.52)


func _draw_hit_event(event: Dictionary) -> void:
	var progress := _event_progress(event)
	var fade := 1.0 - progress
	var direction: Vector2 = event.get("direction", -_facing)
	var rank := int(event.get("rank", 0))
	var shards := int(event.get("shards", 4))
	var radius := lerpf(32.0, 82.0 + float(rank) * 6.0, ease(progress, -1.35))

	# Re-forming shell flare.
	for segment in 6:
		var segment_angle := direction.angle() - 1.08 + float(segment) * 0.36
		var shell_points := _ellipse_arc_points(Vector2(radius, radius * 0.76), segment_angle, segment_angle + 0.22, 6, Vector2(0.0, -7.0))
		draw_polyline(shell_points, Color(PALE_JADE, fade * 0.78), 3.4, true)
	_draw_ward_glyph(direction * minf(radius * 0.46, 34.0) + Vector2(0.0, -7.0), direction.angle(), 0.72 + float(rank) * 0.06, fade)

	for index in shards:
		if not _take_draw_budget():
			break
		var fan := lerpf(-1.18, 1.18, float(index) / float(maxi(shards - 1, 1)))
		var shard_direction := direction.rotated(fan + sin(float(index) * 2.17) * 0.10)
		var distance := radius * (0.48 + float(index % 3) * 0.12)
		var shard_position := shard_direction * distance + Vector2(0.0, -7.0)
		_draw_kite(shard_position, shard_direction, 8.0 + float(index % 2) * 3.0, 3.2, Color(JADE if index % 3 else GOLD, fade * 0.82), Color(PALE_JADE, fade * 0.90))


func _draw_skill_event(event: Dictionary) -> void:
	if not _take_draw_budget():
		return
	var phase := StringName(str(event.get("phase", "cast")))
	var skill_id := StringName(str(event.get("skill_id", "sword_damage")))
	var rank := int(event.get("rank", 0))
	var progress := _event_progress(event)
	var fade := 1.0 - progress
	var center := to_local(event.get("position_global", global_position) as Vector2)
	var direction: Vector2 = event.get("direction", _facing)
	match phase:
		&"cast":
			_draw_skill_cast(skill_id, rank, center, direction, progress, fade)
		&"travel":
			_draw_skill_travel(skill_id, rank, center, direction, progress, fade)
		&"impact":
			_draw_skill_impact(skill_id, rank, center, direction, progress, fade)


func _draw_skill_cast(skill_id: StringName, rank: int, center: Vector2, direction: Vector2, progress: float, fade: float) -> void:
	var forward := _normalized_or(direction, _facing)
	var side := forward.orthogonal()
	match skill_id:
		&"sword_damage", &"attack_speed", &"extra_sword", &"piercing_sword":
			var blade_count := clampi(2 + int(ceil(float(rank) * 0.5)), 2, 5)
			for index in blade_count:
				var ratio := 0.5 if blade_count <= 1 else float(index) / float(blade_count - 1)
				var blade_direction := forward.rotated(lerpf(-0.56, 0.56, ratio))
				var blade_origin := center + blade_direction * (10.0 + progress * 8.0)
				var blade_finish := blade_origin + blade_direction * (28.0 + float(rank) * 5.0) * progress
				draw_line(blade_origin - blade_direction * 14.0, blade_finish, Color(DEEP_INK, fade * 0.44), 7.0, true)
				draw_line(blade_origin, blade_finish, Color(JADE, fade * 0.68), 2.0, true)
				_draw_sword(blade_finish, blade_direction, 0.58 + float(rank) * 0.035, fade)
			_draw_ink_seal(center, forward, 24.0 + float(rank) * 3.0, Color(GOLD, fade * 0.54), Color(PALE_JADE, fade * 0.60))
		&"phoenix_blade":
			_draw_ink_seal(center, forward, 28.0 + float(rank) * 4.0, Color(GOLD, fade * 0.84), Color(VERMILION, fade * 0.58))
			for index in 3 + mini(rank, 2):
				var offset := (float(index) - 1.5) * 8.0
				var flame_start := center + side * offset - forward * 12.0
				var flame_end := flame_start + forward * (32.0 + progress * 14.0)
				draw_line(flame_start, flame_end, Color(GOLD, fade * 0.70), 3.2, true)
				draw_line(flame_start + side * 3.0, flame_end + side * 2.0, Color(VERMILION, fade * 0.45), 1.2, true)
		&"qi_pulse":
			var radius := 22.0 + float(rank) * 6.0 + progress * (28.0 + float(rank) * 5.0)
			for band in 3:
				for arc_index in 4:
					var start := float(arc_index) * TAU / 4.0 + float(band) * 0.19 + progress * 0.35
					var arc := _ellipse_arc_points(Vector2(radius - float(band) * 5.0, radius * 0.58), start, start + 0.62, 8, center + Vector2(0.0, 6.0))
					draw_polyline(arc, Color(QI_BLUE if band == 0 else JADE, fade * (0.62 - float(band) * 0.12)), 2.4 - float(band) * 0.4, true)
			_draw_ink_seal(center, forward, 16.0 + float(rank) * 2.0, Color(GOLD, fade * 0.58), Color(PALE_JADE, fade * 0.72))
		&"cloud_step":
			for index in 3:
				var trail_center := center - forward * (18.0 + float(index) * 16.0) * (1.0 - progress * 0.35)
				draw_line(trail_center - side * 10.0, trail_center + forward * 18.0 + side * 10.0, Color(DEEP_INK, fade * 0.46), 5.0, true)
				draw_line(trail_center - side * 7.0, trail_center + forward * 14.0 + side * 7.0, Color(JADE, fade * (0.62 - float(index) * 0.12)), 1.8, true)
		&"jade_body", &"life_stream":
			for index in 6:
				var angle := TAU * float(index) / 6.0 + progress * 0.4
				var mote := center + Vector2.from_angle(angle) * (18.0 + progress * 20.0)
				_draw_kite(mote, Vector2.from_angle(angle), 5.0 + float(rank) * 0.6, 2.2, Color(PALE_JADE, fade * 0.62), Color(GOLD, fade * 0.54))
			_draw_ink_seal(center, forward, 24.0 + float(rank) * 3.0, Color(JADE, fade * 0.46), Color(PALE_JADE, fade * 0.68))
		&"spirit_well":
			for index in 4:
				var start_angle := TAU * float(index) / 4.0 + progress * 0.35
				var start := center + Vector2.from_angle(start_angle) * (48.0 + float(rank) * 8.0)
				var control := center + Vector2.from_angle(start_angle + 0.52) * 34.0
				var points := PackedVector2Array()
				for sample in 9:
					var t := float(sample) / 8.0
					points.append(_quadratic_bezier(start, control, center, t))
				draw_polyline(points, Color(QI_BLUE, fade * 0.64), 2.0, true)
		&"pet_assist":
			for index in 3:
				var slash_offset := side * (float(index) - 1.0) * 10.0
				draw_line(center + slash_offset - forward * 12.0, center + slash_offset + forward * 25.0, Color(JADE, fade * 0.72), 2.8, true)
			_draw_ink_seal(center, forward, 18.0 + float(rank) * 2.0, Color(GOLD, fade * 0.52), Color(JADE, fade * 0.58))


func _draw_skill_travel(skill_id: StringName, rank: int, origin: Vector2, direction: Vector2, progress: float, fade: float) -> void:
	var forward := _normalized_or(direction, _facing)
	var side := forward.orthogonal()
	var distance := lerpf(8.0, 156.0 + float(rank) * 18.0, ease(progress, -1.25))
	var center := origin + forward * distance
	var trail_points := PackedVector2Array()
	for index in 6:
		var t := float(index) / 5.0
		var point := center - forward * (distance * t * 0.72)
		point += side * sin(t * PI + float(rank)) * (3.0 + float(rank))
		trail_points.append(point)
	if trail_points.size() >= 2:
		draw_polyline(trail_points, Color(DEEP_INK, fade * 0.54), 8.0, true)
		draw_polyline(trail_points, Color(JADE if skill_id != &"phoenix_blade" else GOLD, fade * 0.76), 2.0, true)
	match skill_id:
		&"phoenix_blade":
			_draw_sword(center, forward, 0.92 + float(rank) * 0.05, fade)
			for index in 3:
				var flame := PackedVector2Array([center - forward * (6.0 + index * 5.0), center - forward * (26.0 + index * 8.0) + side * 8.0, center - forward * (18.0 + index * 6.0) - side * 5.0])
				draw_colored_polygon(flame, Color(VERMILION, fade * 0.30))
		&"pet_assist":
			for index in 3:
				var claw := center + side * (float(index) - 1.0) * 9.0
				draw_line(claw - forward * 18.0, claw + forward * 15.0, Color(JADE, fade * 0.70), 3.0, true)
		&"qi_pulse":
			_draw_ink_seal(center, forward, 15.0 + float(rank) * 2.0, Color(QI_BLUE, fade * 0.72), Color(GOLD, fade * 0.46))
		_:
			_draw_sword(center, forward, 0.74 + float(rank) * 0.03, fade)


func _draw_skill_impact(skill_id: StringName, rank: int, center: Vector2, direction: Vector2, progress: float, fade: float) -> void:
	var forward := _normalized_or(direction, _facing)
	var side := forward.orthogonal()
	var radius := lerpf(10.0, 38.0 + float(rank) * 9.0, ease(progress, -1.1))
	match skill_id:
		&"qi_pulse":
			for arc_index in 5:
				var start := float(arc_index) * 0.88 + progress * 0.24
				var arc := _ellipse_arc_points(Vector2(radius, radius * 0.60), start, start + 0.44, 7, center + Vector2(0.0, 5.0))
				draw_polyline(arc, Color(JADE if arc_index % 2 else GOLD, fade * 0.72), 2.8 - float(arc_index % 2) * 0.6, true)
			_draw_skill_shards(center, forward, radius, 6 + mini(rank, 4), fade, JADE)
		&"jade_body", &"life_stream":
			_draw_ink_seal(center, forward, radius * 0.78, Color(JADE, fade * 0.70), Color(PALE_JADE, fade * 0.82))
			for index in 5:
				var mote := center - Vector2(0.0, radius * 0.8) + Vector2(float(index - 2) * 8.0, -progress * 18.0)
				draw_line(mote, mote + Vector2(0.0, -8.0), Color(PALE_JADE, fade * 0.64), 2.0, true)
		&"pet_assist":
			_draw_skill_shards(center, forward, radius, 5, fade, GOLD)
			for index in 3:
				var claw_start := center + side * (float(index) - 1.0) * 10.0 - forward * 16.0
				draw_line(claw_start, claw_start + forward * 30.0, Color(JADE, fade * 0.82), 3.4, true)
		&"cloud_step":
			for index in 3:
				var streak := center + side * (float(index) - 1.0) * 11.0
				draw_line(streak - forward * 20.0, streak + forward * 20.0, Color(JADE, fade * 0.58), 2.0, true)
		_:
			_draw_skill_shards(center, forward, radius, 5 + mini(rank, 5), fade, GOLD if skill_id == &"phoenix_blade" else JADE)
			_draw_ink_seal(center, forward, radius * 0.72, Color(GOLD, fade * 0.54), Color(PALE_JADE, fade * 0.72))


func _draw_skill_shards(center: Vector2, direction: Vector2, radius: float, count: int, fade: float, color: Color) -> void:
	var safe_count := maxi(count, 3)
	for index in safe_count:
		var angle := direction.angle() + lerpf(-1.16, 1.16, float(index) / float(safe_count - 1))
		var shard_direction := Vector2.from_angle(angle)
		var shard_center := center + shard_direction * radius * (0.58 + float(index % 3) * 0.13)
		_draw_kite(shard_center, shard_direction, 7.0 + float(index % 2) * 2.0, 2.8, Color(color, fade * 0.58), Color(PALE_JADE if color == JADE else GOLD, fade * 0.78))


func _draw_ink_seal(center: Vector2, direction: Vector2, radius: float, edge: Color, inner: Color) -> void:
	var phase := direction.angle() - 0.36
	for index in 3:
		var start := phase + float(index) * 2.1
		var arc := _ellipse_arc_points(Vector2(radius, radius * 0.56), start, start + 0.72, 9, center + Vector2(0.0, 4.0))
		draw_polyline(arc, edge if index == 0 else inner, 1.8 if index == 0 else 1.1, true)
	var mark := center + direction * (radius * 0.34)
	draw_line(mark - direction.orthogonal() * radius * 0.20, mark + direction.orthogonal() * radius * 0.20, inner, 1.5, true)


func _draw_qi_field() -> void:
	if _qi_tendrils <= 0:
		return
	var radius := _qi_field_radius()
	var ellipse := Vector2(radius, radius * 0.54)
	var phase := 0.28 if reduced_motion else -_phase_time * (0.18 + float(_magnet_rank) * 0.012)

	# Broken gathering-ring calligraphy, intentionally not a generic circle.
	for band in 3:
		var band_scale := 1.0 - float(band) * 0.12
		for quarter in 4:
			var start := phase + float(quarter) * TAU / 4.0 + 0.13 + float(band) * 0.05
			var finish := start + 0.92 - float(band) * 0.08
			var arc_points := _ellipse_arc_points(ellipse * band_scale, start, finish, 13, Vector2(0.0, 8.0))
			draw_polyline(arc_points, Color(QI_BLUE if band == 0 else JADE, 0.22 - float(band) * 0.045), 1.8 - float(band) * 0.28, true)

	for tendril in _qi_tendrils:
		if not _take_draw_budget():
			break
		var points := PackedVector2Array()
		var start_angle := phase * 2.2 + TAU * float(tendril) / float(maxi(_qi_tendrils, 1))
		var samples := 9 if reduced_motion else (13 if _mobile_mode else 18)
		for sample in samples:
			var t := float(sample) / float(maxi(samples - 1, 1))
			var spiral_radius := radius * lerpf(0.94, 0.18, t)
			var spiral_angle := start_angle + t * (1.05 + float(_magnet_rank) * 0.12)
			points.append(Vector2(cos(spiral_angle) * spiral_radius, sin(spiral_angle) * spiral_radius * 0.54 + 8.0))
		draw_polyline(points, Color(DEEP_INK, 0.25), 5.0, true)
		draw_polyline(points, Color(QI_BLUE if tendril % 2 == 0 else JADE, 0.34 + float(_magnet_rank) * 0.025), 1.35, true)
		var tip := points[points.size() - 1]
		var tangent := (tip - points[points.size() - 2]).normalized()
		_draw_kite(tip, tangent, 5.0, 2.2, Color(PALE_JADE, 0.62), Color(GOLD, 0.52))


func _draw_pickup_event(event: Dictionary) -> void:
	var progress := _event_progress(event)
	var fade := 1.0 - progress
	var source_global: Vector2 = event.get("source_global", global_position)
	var source := to_local(source_global)
	var maximum_distance := 360.0 + float(int(event.get("rank", 0))) * 24.0
	if source.length() > maximum_distance:
		source = source.normalized() * maximum_distance
	var perpendicular := source.orthogonal().normalized()
	var curve_sign := -1.0 if int(event.get("sequence", 0)) % 2 == 0 else 1.0
	var control := source * 0.52 + perpendicular * minf(source.length() * 0.22, 64.0) * curve_sign
	var start_t := clampf(progress * 0.76, 0.0, 0.82)
	var beam := PackedVector2Array()
	for sample in 18:
		var t := lerpf(start_t, 1.0, float(sample) / 17.0)
		beam.append(_quadratic_bezier(source, control, Vector2.ZERO, t))
	draw_polyline(beam, Color(DEEP_INK, fade * 0.38), 10.0, true)
	draw_polyline(beam, Color(QI_BLUE, fade * 0.78), 3.6, true)
	draw_polyline(beam, Color(GOLD_PALE, fade * 0.72), 1.1, true)

	var motes := int(event.get("motes", 2))
	for index in motes:
		if not _take_draw_budget():
			break
		var mote_t := clampf(start_t + (float(index) + 0.35) / float(motes + 1) * (1.0 - start_t), 0.0, 1.0)
		var point := _quadratic_bezier(source, control, Vector2.ZERO, mote_t)
		var tangent := (_quadratic_bezier(source, control, Vector2.ZERO, minf(mote_t + 0.025, 1.0)) - point).normalized()
		_draw_kite(point, tangent, 6.0 + float(index % 2) * 2.0, 2.4, Color(PALE_JADE, fade * 0.88), Color(GOLD, fade * 0.66))

	var collapse_radius := _qi_field_radius() * lerpf(0.86, 0.28, progress)
	for quarter in 3:
		var start := _phase_time * 0.2 + float(quarter) * TAU / 3.0
		var points := _ellipse_arc_points(Vector2(collapse_radius, collapse_radius * 0.54), start, start + 0.72, 12, Vector2(0.0, 8.0))
		draw_polyline(points, Color(JADE, fade * 0.48), 2.1, true)


func _draw_sword(center: Vector2, direction: Vector2, scale_factor: float, alpha: float) -> void:
	var forward := _normalized_or(direction, Vector2.RIGHT)
	var side := forward.orthogonal()
	var blade_tip := center + forward * 18.0 * scale_factor
	var blade_neck := center - forward * 5.5 * scale_factor
	var blade := PackedVector2Array([
		blade_tip,
		center + forward * 5.0 * scale_factor + side * 3.5 * scale_factor,
		blade_neck + side * 2.2 * scale_factor,
		blade_neck - side * 2.2 * scale_factor,
		center + forward * 5.0 * scale_factor - side * 3.5 * scale_factor,
	])
	var glow := PackedVector2Array([
		blade_tip + forward * 4.0 * scale_factor,
		center + side * 8.0 * scale_factor,
		blade_neck - forward * 5.0 * scale_factor,
		center - side * 8.0 * scale_factor,
	])
	draw_colored_polygon(glow, Color(JADE, 0.075 * alpha))
	draw_colored_polygon(blade, Color(PAPER, 0.96 * alpha))
	draw_polyline(_closed(blade), Color(INK, 0.92 * alpha), 1.35, true)
	draw_line(blade_neck - side * 5.0 * scale_factor, blade_neck + side * 5.0 * scale_factor, Color(GOLD, 0.92 * alpha), 2.2, true)
	var hilt_end := blade_neck - forward * 8.0 * scale_factor
	draw_line(blade_neck, hilt_end, Color(INK, 0.96 * alpha), 3.0, true)
	_draw_kite(hilt_end - forward * 1.8 * scale_factor, forward, 3.4 * scale_factor, 2.5 * scale_factor, Color(VERMILION, 0.80 * alpha), Color(GOLD, 0.72 * alpha))


func _draw_ward_glyph(center: Vector2, rotation_angle: float, scale_factor: float, alpha: float) -> void:
	var forward := Vector2.from_angle(rotation_angle)
	var side := forward.orthogonal()
	var diamond := PackedVector2Array([
		center + forward * 10.0 * scale_factor,
		center + side * 7.0 * scale_factor,
		center - forward * 10.0 * scale_factor,
		center - side * 7.0 * scale_factor,
	])
	draw_colored_polygon(diamond, Color(JADE_DARK, 0.34 * alpha))
	draw_polyline(_closed(diamond), Color(GOLD, 0.78 * alpha), 1.3, true)
	for bar in 3:
		var offset := (float(bar) - 1.0) * 3.1 * scale_factor
		var half_width := (4.5 - float(bar % 2) * 1.2) * scale_factor
		var bar_center := center + forward * offset
		draw_line(bar_center - side * half_width, bar_center + side * half_width, Color(PALE_JADE, 0.88 * alpha), 1.2, true)
	if _vitality_rank >= 3:
		draw_line(center - forward * 5.0 * scale_factor, center + forward * 5.0 * scale_factor, Color(JADE, 0.62 * alpha), 1.0, true)


func _draw_kite(
	center: Vector2,
	direction: Vector2,
	length: float,
	width: float,
	fill_color: Color,
	edge_color: Color
) -> void:
	var forward := _normalized_or(direction, Vector2.RIGHT)
	var side := forward.orthogonal()
	var points := PackedVector2Array([
		center + forward * length,
		center + side * width,
		center - forward * length * 0.62,
		center - side * width,
	])
	draw_colored_polygon(points, fill_color)
	draw_polyline(_closed(points), edge_color, 1.0, true)


func _refresh_visual_tuning() -> void:
	_sword_rank = int(technique_ranks.get("sword_damage", 0))
	_vitality_rank = int(technique_ranks.get("vitality", 0))
	_magnet_rank = int(technique_ranks.get("magnet", 0))

	if _sword_rank > 0 or discipline == DISCIPLINE_SWORD:
		_sword_count = 1 + _sword_rank + (1 if discipline == DISCIPLINE_SWORD else 0)
		_sword_count = mini(_sword_count, 6 if _mobile_mode else 7)
	else:
		_sword_count = 0
	if _vitality_rank > 0 or discipline == DISCIPLINE_VITALITY:
		_ward_facets = clampi(6 + _vitality_rank + (2 if discipline == DISCIPLINE_VITALITY else 0), 6, 12)
		_ward_glyphs = clampi(1 + int(ceil(float(_vitality_rank) * 0.5)) + (1 if discipline == DISCIPLINE_VITALITY else 0), 1, 5)
	else:
		_ward_facets = 0
		_ward_glyphs = 0
	if _magnet_rank > 0 or discipline == DISCIPLINE_QI:
		_qi_tendrils = clampi(2 + _magnet_rank + (1 if discipline == DISCIPLINE_QI else 0), 2, 8)
		if reduced_motion:
			_qi_tendrils = mini(_qi_tendrils, 4)
		elif _mobile_mode:
			_qi_tendrils = mini(_qi_tendrils, 6)
	else:
		_qi_tendrils = 0

	if reduced_motion:
		_particle_budget = REDUCED_MOTION_PARTICLE_BUDGET
		_transient_cap = REDUCED_MOTION_TRANSIENT_CAP
	elif _mobile_mode:
		_particle_budget = MOBILE_PARTICLE_BUDGET
		_transient_cap = MOBILE_TRANSIENT_CAP
	else:
		_particle_budget = DESKTOP_PARTICLE_BUDGET
		_transient_cap = DESKTOP_TRANSIENT_CAP
	_trim_transients_to_cap()


func _read_profile_motion_setting() -> void:
	if not is_inside_tree():
		return
	var profile := get_node_or_null("/root/MetaProfile")
	if profile == null:
		return
	var settings_value: Variant = profile.get("settings")
	if settings_value is Dictionary:
		reduced_motion = bool((settings_value as Dictionary).get("reduced_motion", false))


func _attack_blade_count() -> int:
	var count := 3 + _sword_rank + (1 if discipline == DISCIPLINE_SWORD else 0)
	if reduced_motion:
		return mini(count, 5)
	if _mobile_mode:
		return mini(count, 7)
	return mini(count, 9)


func _qi_field_radius() -> float:
	return 70.0 + float(_magnet_rank) * 14.0 + (14.0 if discipline == DISCIPLINE_QI else 0.0)


func _trail_samples() -> int:
	if reduced_motion:
		return 2
	return 4 if _mobile_mode else 7


func _rank_from(ranks: Dictionary, key: String) -> int:
	var value: Variant = ranks.get(key, ranks.get(StringName(key), 0))
	if value is int or value is float:
		return clampi(int(value), 0, MAX_TECHNIQUE_RANK)
	return 0


func _next_sequence() -> int:
	_sequence += 1
	return _sequence


func _canonical_skill_id(skill_id: StringName) -> StringName:
	match skill_id:
		&"sword_damage", &"attack_speed", &"extra_sword", &"piercing_sword", &"cloud_step", &"jade_body", &"spirit_well", &"qi_pulse", &"life_stream", &"phoenix_blade", &"pet_assist":
			return skill_id
	return &"sword_damage"


func _push_transient(target: Array[Dictionary], event: Dictionary) -> void:
	while _active_transient_count() >= _transient_cap:
		_remove_oldest_transient()
	target.append(event)


func _remove_oldest_transient() -> void:
	var oldest_kind := -1
	var oldest_sequence := 2147483647
	var pools: Array = [_attack_events, _hit_events, _pickup_events, _skill_events]
	for kind_index in pools.size():
		var pool: Array = pools[kind_index]
		if pool.is_empty():
			continue
		var candidate := int((pool[0] as Dictionary).get("sequence", oldest_sequence))
		if candidate < oldest_sequence:
			oldest_sequence = candidate
			oldest_kind = kind_index
	match oldest_kind:
		0:
			_attack_events.remove_at(0)
		1:
			_hit_events.remove_at(0)
		2:
			_pickup_events.remove_at(0)
		3:
			_skill_events.remove_at(0)


func _trim_transients_to_cap() -> void:
	while _active_transient_count() > _transient_cap:
		_remove_oldest_transient()


func _active_transient_count() -> int:
	return _attack_events.size() + _hit_events.size() + _pickup_events.size() + _skill_events.size()


func _skill_phase_count(phase: StringName) -> int:
	var count := 0
	for event: Dictionary in _skill_events:
		if StringName(str(event.get("phase", ""))) == phase:
			count += 1
	return count


func _tick_events(events: Array[Dictionary], delta: float) -> void:
	for index in range(events.size() - 1, -1, -1):
		var event := events[index]
		event["age"] = float(event.get("age", 0.0)) + delta
		events[index] = event
		if float(event.get("age", 0.0)) >= maxf(float(event.get("lifetime", 0.01)), 0.01):
			events.remove_at(index)


func _event_progress(event: Dictionary) -> float:
	return clampf(float(event.get("age", 0.0)) / maxf(float(event.get("lifetime", 0.01)), 0.01), 0.0, 1.0)


func _take_draw_budget(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if _draw_budget_remaining < amount:
		return false
	_draw_budget_remaining -= amount
	return true


func _ellipse_point(angle: float, radii: Vector2) -> Vector2:
	return Vector2(cos(angle) * radii.x, sin(angle) * radii.y)


func _ellipse_arc_points(
	radii: Vector2,
	start_angle: float,
	end_angle: float,
	samples: int,
	offset: Vector2 = Vector2.ZERO
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_samples := maxi(samples, 2)
	for index in safe_samples:
		var t := float(index) / float(safe_samples - 1)
		points.append(offset + _ellipse_point(lerpf(start_angle, end_angle, t), radii))
	return points


func _quadratic_bezier(start: Vector2, control: Vector2, finish: Vector2, t: float) -> Vector2:
	var inverse := 1.0 - t
	return start * inverse * inverse + control * 2.0 * inverse * t + finish * t * t


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not points.is_empty():
		result.append(points[0])
	return result


func _normalized_or(value: Vector2, fallback: Vector2) -> Vector2:
	if value.length_squared() > 0.0001:
		return value.normalized()
	if fallback.length_squared() > 0.0001:
		return fallback.normalized()
	return Vector2.RIGHT


func _is_finite_vector(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)
