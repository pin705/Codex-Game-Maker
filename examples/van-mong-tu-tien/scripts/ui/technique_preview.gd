class_name TechniquePreview
extends Control

## Live rank preview used by the permanent-technique screen.
## Rank changes alter silhouette, layer count and motion—not only a number.

const GOLD := Color("#e3b95e")
const JADE := Color("#63d8b1")
const CYAN := Color("#82d9dd")
const PAPER := Color("#efe5c9")
const INK := Color("#071315")

var technique_id: StringName = &"sword_damage"
var rank := 0
var max_rank := 5
var icon_texture: Texture2D
var time := 0.0
var reduced_motion := false


func configure(id: StringName, current_rank: int, rank_cap: int, icon: Texture2D = null) -> TechniquePreview:
	technique_id = id
	rank = clampi(current_rank, 0, maxi(rank_cap, 1))
	max_rank = maxi(rank_cap, 1)
	icon_texture = icon
	if is_inside_tree():
		_sync_reduced_motion()
	queue_redraw()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_reduced_motion()
	set_process(true)


func _process(delta: float) -> void:
	if not reduced_motion:
		time += delta
	queue_redraw()


func _draw() -> void:
	if size.x < 32.0 or size.y < 32.0:
		return
	var center := size * 0.5
	var base_radius := minf(size.x, size.y) * 0.31
	var power := float(rank) / float(max_rank)
	_draw_well(center, base_radius, power)
	match technique_id:
		&"vitality":
			_draw_vitality(center, base_radius, power)
		&"magnet":
			_draw_magnet(center, base_radius, power)
		_:
			_draw_swords(center, base_radius, power)
	_draw_center_icon(center, base_radius, power)


func _draw_well(center: Vector2, radius: float, power: float) -> void:
	draw_circle(center + Vector2(0.0, 8.0), radius * 1.02, Color(0.0, 0.0, 0.0, 0.32))
	draw_circle(center, radius, Color(INK, 0.86))
	for ring_index in 3:
		var ring_radius := radius * (0.56 + float(ring_index) * 0.20)
		var alpha := 0.10 + power * 0.11 - float(ring_index) * 0.018
		draw_arc(center, ring_radius, -2.70 + float(ring_index) * 0.34, 2.35 + float(ring_index) * 0.17, 54, Color(PAPER, alpha), 1.0, true)
	var sweep := 0.0 if reduced_motion else sin(time * 1.35) * 0.06
	draw_arc(center, radius * 0.92, -1.5 + sweep, 0.52 + sweep, 42, Color(_accent(), 0.24 + power * 0.34), 2.0, true)


func _draw_swords(center: Vector2, radius: float, power: float) -> void:
	var count := 1 if rank <= 0 else mini(7, rank + 2)
	var orbit := radius * (0.78 + power * 0.16)
	var rotation := -0.55 if reduced_motion else time * (0.28 + power * 0.22) - 0.55
	for index in count:
		var angle := rotation + TAU * float(index) / float(count)
		var origin := center + Vector2.from_angle(angle) * orbit
		var direction := Vector2.from_angle(angle + PI * 0.5)
		_draw_blade(origin, direction, 18.0 + power * 7.0, Color(_accent(), 0.56 + power * 0.38))
		if rank >= 3:
			var trail_end := origin - direction * (18.0 + power * 10.0)
			draw_line(trail_end, origin, Color(JADE, 0.08 + power * 0.14), 4.0, true)
	if rank >= max_rank:
		for fan_index in 5:
			var fan_angle := -PI * 0.82 + float(fan_index) * PI * 0.41
			var fan_origin := center + Vector2.from_angle(fan_angle) * radius * 0.52
			_draw_blade(fan_origin, Vector2.from_angle(fan_angle), 17.0, Color(GOLD, 0.76))


func _draw_vitality(center: Vector2, radius: float, power: float) -> void:
	var shells := 1 + int(ceil(float(rank) / 2.0))
	for shell_index in shells:
		var shell_radius := radius * (0.51 + float(shell_index) * 0.13)
		var points := PackedVector2Array()
		var rotation := PI / 6.0 + (0.0 if reduced_motion else time * 0.07 * (-1.0 if shell_index % 2 else 1.0))
		for index in 6:
			points.append(center + Vector2.from_angle(rotation + TAU * float(index) / 6.0) * shell_radius)
		points.append(points[0])
		draw_polyline(points, Color(JADE, 0.35 + power * 0.38 - shell_index * 0.07), 2.0 if shell_index == 0 else 1.2, true)
	if rank >= 2:
		for glyph_index in 6:
			var angle := TAU * float(glyph_index) / 6.0
			var glyph_center := center + Vector2.from_angle(angle) * radius * 0.69
			draw_circle(glyph_center, 2.2 + power * 1.4, Color(PAPER, 0.42 + power * 0.36))
			draw_line(glyph_center - Vector2.from_angle(angle) * 5.0, glyph_center + Vector2.from_angle(angle) * 5.0, Color(JADE, 0.36), 1.0, true)
	if rank >= 4:
		draw_circle(center, radius * 0.46, Color(JADE, 0.045 + power * 0.055))


func _draw_magnet(center: Vector2, radius: float, power: float) -> void:
	var tendrils := 3 + rank
	for index in tendrils:
		var phase := TAU * float(index) / float(tendrils) + (0.0 if reduced_motion else time * 0.34)
		var from := center + Vector2.from_angle(phase) * radius * 0.24
		var middle := center + Vector2.from_angle(phase + 0.48) * radius * (0.54 + power * 0.08)
		var finish := center + Vector2.from_angle(phase + 0.88) * radius * (0.80 + power * 0.10)
		var curve := PackedVector2Array()
		for step in 12:
			var t := float(step) / 11.0
			var point := from.lerp(middle, t * 2.0) if t < 0.5 else middle.lerp(finish, (t - 0.5) * 2.0)
			curve.append(point)
		draw_polyline(curve, Color(CYAN, 0.20 + power * 0.36), 1.2 + power, true)
		draw_circle(finish, 2.2 + power * 2.0, Color(PAPER, 0.58 + power * 0.30))
	if rank >= 3:
		var beam_angle := -1.1 if reduced_motion else -time * 0.46
		for beam_index in 3:
			var end := center + Vector2.from_angle(beam_angle + TAU * float(beam_index) / 3.0) * radius * 0.92
			draw_line(end, center, Color(JADE, 0.08 + power * 0.14), 2.0, true)


func _draw_center_icon(center: Vector2, radius: float, power: float) -> void:
	var icon_size := radius * (0.62 + power * 0.08)
	draw_circle(center, icon_size * 0.57, Color("#102326", 0.96))
	draw_circle(center, icon_size * 0.51, Color(_accent(), 0.08 + power * 0.08))
	if icon_texture != null:
		var rect := Rect2(center - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size)
		draw_texture_rect(icon_texture, rect, false, Color(0.72, 0.75, 0.72, 0.68) if rank == 0 else Color.WHITE)
	else:
		draw_circle(center, icon_size * 0.16, Color(_accent(), 0.82))
	var node_count := max_rank
	var start_x := center.x - float(node_count - 1) * 7.0
	for index in node_count:
		var lit := index < rank
		draw_circle(Vector2(start_x + index * 14.0, center.y + radius * 0.70), 3.2, Color(_accent(), 0.92) if lit else Color(PAPER, 0.16))


func _draw_blade(origin: Vector2, direction: Vector2, length: float, color: Color) -> void:
	var normal := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		origin + direction * length * 0.62,
		origin - direction * length * 0.42 + normal * 3.0,
		origin - direction * length * 0.58,
		origin - direction * length * 0.42 - normal * 3.0,
	])
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, Color(PAPER, 0.74), 0.9, true)


func _accent() -> Color:
	match technique_id:
		&"vitality":
			return JADE
		&"magnet":
			return CYAN
		_:
			return GOLD


func _sync_reduced_motion() -> void:
	var profile := get_node_or_null("/root/MetaProfile")
	if profile == null:
		return
	var settings_value: Variant = profile.get("settings")
	if settings_value is Dictionary:
		reduced_motion = bool((settings_value as Dictionary).get("reduced_motion", false))
