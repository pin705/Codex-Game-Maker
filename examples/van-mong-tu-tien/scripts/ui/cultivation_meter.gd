class_name CultivationMeter
extends ProgressBar

var meter_color := Color("#57d2a7")
var track_color := Color("#061113")
var edge_color := Color("#d8cba4")
var meter_seed := 1

func _init() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for state in [&"background", &"fill"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	value_changed.connect(func(_value: float) -> void: queue_redraw())

func configure(fill: Color, maximum_value: float, seed: int = 1) -> CultivationMeter:
	meter_color = fill
	meter_seed = seed
	max_value = maximum_value
	value = maximum_value
	queue_redraw()
	return self

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func _draw() -> void:
	if size.x < 10.0 or size.y < 4.0:
		return
	var h := minf(size.y, 16.0)
	var y := (size.y - h) * 0.5
	var channel := Rect2(0.0, y, size.x, h)
	var cut := minf(5.0, h * 0.42)
	var channel_shape := _bar_shape(channel, cut)
	draw_colored_polygon(_offset(channel_shape, Vector2(2.0, 2.0)), Color(0.0, 0.0, 0.0, 0.32))
	draw_colored_polygon(channel_shape, track_color)
	draw_polyline(_closed(channel_shape), Color(edge_color, 0.28), 1.0, true)

	var ratio := clampf(value / maxf(max_value, 0.0001), 0.0, 1.0)
	if ratio > 0.001:
		var fill_rect := Rect2(2.0, y + 2.0, maxf(4.0, (size.x - 4.0) * ratio), maxf(1.0, h - 4.0))
		var fill_shape := _bar_shape(fill_rect, minf(3.0, h * 0.30))
		draw_colored_polygon(fill_shape, Color(meter_color, 0.96))
		# Dry-brush highlight and a few etched ticks imply a physical channel.
		if fill_rect.size.x > 8.0:
			draw_line(Vector2(fill_rect.position.x + 4.0, fill_rect.position.y + 1.0), Vector2(fill_rect.end.x - 3.0, fill_rect.position.y + 1.0), Color.WHITE, 1.0, true)
			for tick in range(1, 5):
				var tx := fill_rect.position.x + fill_rect.size.x * float(tick) / 5.0
				if tx < fill_rect.end.x - 3.0:
					draw_line(Vector2(tx, fill_rect.position.y + 2.0), Vector2(tx, fill_rect.end.y - 2.0), Color(0.0, 0.0, 0.0, 0.20), 1.0, true)
	# A small marker at the current edge makes partial Qi immediately legible.
	var marker_x := clampf(2.0 + (size.x - 4.0) * ratio, 3.0, size.x - 3.0)
	draw_line(Vector2(marker_x, y - 2.0), Vector2(marker_x, y + h + 2.0), Color(edge_color, 0.52), 1.0, true)

func _bar_shape(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	cut = minf(cut, minf(rect.size.x * 0.24, rect.size.y * 0.48))
	return PackedVector2Array([
		Vector2(p.x + cut, p.y), Vector2(e.x - cut, p.y),
		Vector2(e.x, p.y + cut), Vector2(e.x - cut, e.y),
		Vector2(p.x + cut, e.y), Vector2(p.x, e.y - cut),
	])

func _offset(points: PackedVector2Array, delta: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + delta)
	return result

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
