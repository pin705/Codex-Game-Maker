class_name CultivationMeter
extends ProgressBar

## Thin V4 ink channel. Values stay native and dynamic; the silhouette is
## custom-drawn so every compact HUD meter remains crisp at desktop and phone
## scale without stretching an atlas crop.

const BRONZE := Color("#8a6730")
const PAPER := Color("#e7ddc4")
const TRACK := Color("#071316")
const AUTHORED_METER_FRAME: Texture2D = preload("res://assets/generated/ui/UIKIT-010-v4-controls/runtime/meter-frame-slim-nineslice.png")

var meter_color := Color("#57d2a7")
var track_color := TRACK
var edge_color := PAPER
var meter_seed := 1
var authored_frame: NinePatchRect


func _init() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for state in [&"background", &"fill"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	value_changed.connect(func(_new_value: float) -> void: queue_redraw())
	authored_frame = NinePatchRect.new()
	authored_frame.name = "V4AuthoredMeterFrame"
	authored_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	authored_frame.texture = AUTHORED_METER_FRAME
	authored_frame.set_patch_margin(SIDE_LEFT, 20)
	authored_frame.set_patch_margin(SIDE_TOP, 6)
	authored_frame.set_patch_margin(SIDE_RIGHT, 20)
	authored_frame.set_patch_margin(SIDE_BOTTOM, 6)
	authored_frame.draw_center = false
	authored_frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(authored_frame)


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
	if size.x < 8.0 or size.y < 4.0:
		return
	var channel_height := clampf(size.y * 0.62, 6.0, 13.0)
	var y := (size.y - channel_height) * 0.5
	var cut := minf(channel_height * 0.46, 5.0)
	var track_shape := _channel(Rect2(Vector2(0.0, y), Vector2(size.x, channel_height)), cut)
	draw_colored_polygon(track_shape, Color(track_color, 0.94))
	draw_polyline(_closed(track_shape), Color(BRONZE, 0.88), 1.0, true)

	var ratio := clampf(value / maxf(max_value, 0.0001), 0.0, 1.0)
	var inset := maxf(2.0, channel_height * 0.18)
	var available := maxf(1.0, size.x - inset * 2.0)
	var fill_width := available * ratio
	if fill_width > 1.0:
		var fill_rect := Rect2(Vector2(inset, y + inset), Vector2(fill_width, maxf(2.0, channel_height - inset * 2.0)))
		var fill_shape := _channel(fill_rect, minf(cut * 0.52, fill_width * 0.2))
		draw_colored_polygon(fill_shape, Color(meter_color.darkened(0.18), 0.98))
		var highlight_y := fill_rect.position.y + maxf(1.0, fill_rect.size.y * 0.24)
		draw_line(
			Vector2(fill_rect.position.x + 2.0, highlight_y),
			Vector2(maxf(fill_rect.position.x + 2.0, fill_rect.end.x - 2.0), highlight_y),
			Color(meter_color.lightened(0.38), 0.50),
			1.0,
			true
		)

	# Four quiet etches provide state rhythm without turning a HUD meter into a
	# decorative ruler.
	for index in range(1, 5):
		var tick_x := inset + available * float(index) / 5.0
		draw_line(Vector2(tick_x, y + 2.0), Vector2(tick_x, y + channel_height - 2.0), Color(PAPER, 0.16), 1.0, true)

	if ratio > 0.025 and ratio < 0.985:
		var edge := Vector2(inset + available * ratio, y + channel_height * 0.5)
		var radius := clampf(channel_height * 0.28, 2.0, 4.0)
		var diamond := PackedVector2Array([
			edge + Vector2(0.0, -radius), edge + Vector2(radius, 0.0),
			edge + Vector2(0.0, radius), edge + Vector2(-radius, 0.0),
		])
		draw_colored_polygon(diamond, Color(edge_color, 0.92))
		draw_polyline(_closed(diamond), Color(BRONZE, 0.94), 1.0, true)


func _channel(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([
		Vector2(p.x + cut, p.y), Vector2(e.x - cut, p.y),
		Vector2(e.x, p.y + cut), Vector2(e.x - cut, e.y),
		Vector2(p.x + cut, e.y), Vector2(p.x, e.y - cut),
	])


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
