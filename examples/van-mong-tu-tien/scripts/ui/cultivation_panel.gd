class_name CultivationPanel
extends PanelContainer

## Stable material frame for the combat HUD and overlays. Decorative nine-slice
## atlases were removed because clasps/corners visibly deformed across the HUD's
## radically different aspect ratios. Purpose-built sprites and sigils now carry
## the art; this frame only protects readability.

enum FrameKind {
	HUD,
	SCROLL,
	PAPER,
	BANNER,
	SEAL,
}

const AUTHORED_SCROLL := preload("res://assets/generated/ui/UIKIT-002-xuan-ink-commercial/runtime/ui_scroll_panel.png")

var frame_kind: FrameKind = FrameKind.HUD
var fill_color := Color("#0a1718")
var accent_color := Color("#b89043")
var paper_color := Color("#d8cba4")
var ornament_seed := 1
var authored_chrome: NinePatchRect

func _init() -> void:
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override(&"panel", empty)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	authored_chrome = NinePatchRect.new()
	authored_chrome.name = "AuthoredChrome"
	authored_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	authored_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(authored_chrome)

func configure(kind: FrameKind, fill: Color, accent: Color, seed: int = 1) -> CultivationPanel:
	frame_kind = kind
	fill_color = fill
	accent_color = accent
	ornament_seed = seed
	_configure_authored_chrome()
	queue_redraw()
	return self

func _configure_authored_chrome() -> void:
	if authored_chrome == null:
		return
	if frame_kind == FrameKind.SCROLL:
		authored_chrome.texture = AUTHORED_SCROLL
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			authored_chrome.set_patch_margin(side, 58)
		authored_chrome.draw_center = true
		authored_chrome.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		authored_chrome.show()
	else:
		authored_chrome.texture = null
		authored_chrome.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	if authored_chrome != null and authored_chrome.visible and authored_chrome.texture != null:
		return
	match frame_kind:
		FrameKind.SCROLL:
			_draw_scroll()
		FrameKind.PAPER:
			_draw_paper()
		FrameKind.BANNER:
			_draw_banner()
		FrameKind.SEAL:
			_draw_seal_frame()
		_:
			_draw_hud_frame()

func _draw_hud_frame() -> void:
	var cut := minf(15.0, size.y * 0.18)
	var shape := _notched_shape(Rect2(Vector2.ZERO, size), cut, false)
	var shadow := _offset_points(shape, Vector2(4.0, 7.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.34))
	draw_colored_polygon(shape, fill_color)
	_draw_ink_wash(shape, 8, 0.022)
	draw_polyline(_closed(shape), Color(accent_color, 0.78), 1.5, true)
	var inner := _notched_shape(Rect2(Vector2(5.0, 5.0), size - Vector2(10.0, 10.0)), maxf(5.0, cut - 4.0), false)
	draw_polyline(_closed(inner), Color(paper_color, 0.12), 1.0, true)

	# Bronze pins and short hand-engraved edge strokes keep the frame from
	# reading as a browser card, even when it is only a few pixels tall.
	for corner in [Vector2(10.0, 10.0), Vector2(size.x - 10.0, size.y - 10.0)]:
		draw_circle(corner, 3.2, Color("#432d18"))
		draw_circle(corner, 1.5, accent_color)
	var stroke_length := minf(68.0, size.x * 0.22)
	draw_line(Vector2(cut + 8.0, 6.0), Vector2(cut + 8.0 + stroke_length, 6.0), Color(accent_color, 0.72), 2.0, true)
	draw_line(Vector2(size.x - cut - 8.0 - stroke_length, size.y - 6.0), Vector2(size.x - cut - 8.0, size.y - 6.0), Color(accent_color, 0.40), 1.0, true)

func _draw_scroll() -> void:
	var cut := minf(28.0, size.x * 0.045)
	var shape := _notched_shape(Rect2(Vector2.ZERO, size), cut, true)
	draw_colored_polygon(_offset_points(shape, Vector2(8.0, 10.0)), Color(0.0, 0.0, 0.0, 0.42))
	draw_colored_polygon(shape, fill_color)
	_draw_ink_wash(shape, 17, 0.032)
	draw_polyline(_closed(shape), Color(accent_color, 0.88), 2.0, true)
	# Slim wooden/bronze rollers make the modal read as a hanging scroll rather
	# than a clipped web panel. They remain inside the nine-slice-safe edge.
	var roller_left := cut * 0.62
	var roller_width := size.x - roller_left * 2.0
	var roller_color := Color("#6e4c27", 0.92)
	draw_rect(Rect2(roller_left, 4.0, roller_width, 6.0), roller_color, true)
	draw_rect(Rect2(roller_left, size.y - 10.0, roller_width, 6.0), roller_color, true)
	draw_circle(Vector2(roller_left, 7.0), 5.0, Color(accent_color, 0.86))
	draw_circle(Vector2(size.x - roller_left, 7.0), 5.0, Color(accent_color, 0.86))
	draw_circle(Vector2(roller_left, size.y - 7.0), 5.0, Color(accent_color, 0.74))
	draw_circle(Vector2(size.x - roller_left, size.y - 7.0), 5.0, Color(accent_color, 0.74))

	var inner := _notched_shape(Rect2(Vector2(7.0, 7.0), size - Vector2(14.0, 14.0)), maxf(8.0, cut - 7.0), true)
	draw_polyline(_closed(inner), Color(paper_color, 0.16), 1.0, true)
	_draw_corner_flourish(Vector2(cut + 16.0, 18.0), 1.0, 1.0)
	_draw_corner_flourish(Vector2(size.x - cut - 16.0, size.y - 18.0), -1.0, -1.0)

	# A vermilion maker's seal gives large modal surfaces an asymmetric focal
	# point and leaves the center clear for type.
	var seal_center := Vector2(size.x - 34.0, size.y - 38.0)
	draw_rect(Rect2(seal_center - Vector2(13.0, 13.0), Vector2(26.0, 26.0)), Color("#7d2f29", 0.76), true)
	draw_rect(Rect2(seal_center - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), Color("#d28664", 0.48), false, 1.3)
	draw_line(seal_center + Vector2(-6.0, -2.0), seal_center + Vector2(6.0, -2.0), Color("#e9c8a2", 0.66), 1.0)
	draw_line(seal_center + Vector2(1.0, -7.0), seal_center + Vector2(1.0, 7.0), Color("#e9c8a2", 0.66), 1.0)

func _draw_paper() -> void:
	var shape := _notched_shape(Rect2(Vector2.ZERO, size), 20.0, true)
	draw_colored_polygon(_offset_points(shape, Vector2(7.0, 9.0)), Color(0.0, 0.0, 0.0, 0.40))
	draw_colored_polygon(shape, Color(fill_color, 0.985))
	_draw_ink_wash(shape, 22, 0.045)
	draw_polyline(_closed(shape), Color(accent_color, 0.90), 2.0, true)
	draw_polyline(_closed(_notched_shape(Rect2(Vector2(7.0, 7.0), size - Vector2(14.0, 14.0)), 13.0, true)), Color(accent_color, 0.26), 1.0, true)
	_draw_corner_flourish(Vector2(22.0, 22.0), 1.0, 1.0)
	_draw_corner_flourish(Vector2(size.x - 22.0, 22.0), -1.0, 1.0)

func _draw_banner() -> void:
	var mid_y := size.y * 0.5
	var points := PackedVector2Array([
		Vector2(24.0, 0.0), Vector2(size.x - 24.0, 0.0),
		Vector2(size.x, mid_y), Vector2(size.x - 24.0, size.y),
		Vector2(24.0, size.y), Vector2(0.0, mid_y),
	])
	draw_colored_polygon(_offset_points(points, Vector2(3.0, 6.0)), Color(0.0, 0.0, 0.0, 0.36))
	draw_colored_polygon(points, fill_color)
	_draw_ink_wash(points, 10, 0.028)
	draw_polyline(_closed(points), Color(accent_color, 0.82), 1.5, true)
	draw_line(Vector2(40.0, 7.0), Vector2(size.x - 40.0, 7.0), Color(paper_color, 0.13), 1.0, true)
	draw_circle(Vector2(20.0, mid_y), 3.0, accent_color)
	draw_circle(Vector2(size.x - 20.0, mid_y), 3.0, accent_color)

func _draw_seal_frame() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	if fill_color.a > 0.001:
		draw_circle(center, radius, fill_color)
	for i in range(3):
		draw_arc(center, radius - float(i) * 7.0, -2.92 + float(i) * 0.12, 2.42 - float(i) * 0.08, 56, Color(accent_color, 0.42 - float(i) * 0.09), 1.5, true)
	for spoke in range(8):
		var angle := TAU * float(spoke) / 8.0 + 0.19
		var outer := center + Vector2.from_angle(angle) * radius
		var inner := center + Vector2.from_angle(angle) * (radius - 9.0)
		draw_line(inner, outer, Color(accent_color, 0.28), 1.0, true)

func _draw_ink_wash(mask_shape: PackedVector2Array, count: int, alpha: float) -> void:
	# Deterministic fibers and dry-brush marks. They are clipped visually by
	# keeping them comfortably inside the panel's bounding rectangle.
	if mask_shape.is_empty():
		return
	for i in range(count):
		var seed := float((i + 1) * (ornament_seed * 17 + 31))
		var y := 12.0 + fposmod(sin(seed * 0.73) * 923.7, maxf(1.0, size.y - 24.0))
		var x := 16.0 + fposmod(cos(seed * 1.19) * 627.1, maxf(1.0, size.x * 0.58))
		var length := 38.0 + fposmod(seed * 13.7, maxf(42.0, size.x * 0.30))
		length = minf(length, size.x - x - 16.0)
		if length > 2.0:
			var fiber_color := Color("#17292d", alpha * 1.45) if (fill_color.r + fill_color.g + fill_color.b) / 3.0 > 0.38 else Color(paper_color, alpha)
			draw_line(Vector2(x, y), Vector2(x + length, y + sin(seed) * 1.8), fiber_color, 1.0, true)

func _draw_corner_flourish(origin: Vector2, x_dir: float, y_dir: float) -> void:
	var c := Color(accent_color, 0.58)
	draw_line(origin, origin + Vector2(42.0 * x_dir, 0.0), c, 1.5, true)
	draw_line(origin, origin + Vector2(0.0, 42.0 * y_dir), c, 1.5, true)
	draw_arc(origin + Vector2(14.0 * x_dir, 14.0 * y_dir), 10.0, 0.0, TAU, 18, Color(accent_color, 0.24), 1.0, true)
	draw_circle(origin, 2.7, accent_color)

func _notched_shape(rect: Rect2, cut: float, asymmetric: bool) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	if asymmetric:
		return PackedVector2Array([
			Vector2(p.x + cut, p.y),
			Vector2(e.x - cut * 1.55, p.y),
			Vector2(e.x, p.y + cut * 0.72),
			Vector2(e.x - cut * 0.25, e.y - cut * 1.20),
			Vector2(e.x - cut, e.y),
			Vector2(p.x + cut * 1.35, e.y),
			Vector2(p.x, e.y - cut * 0.65),
			Vector2(p.x + cut * 0.20, p.y + cut),
		])
	return PackedVector2Array([
		Vector2(p.x + cut, p.y), Vector2(e.x - cut, p.y),
		Vector2(e.x, p.y + cut), Vector2(e.x, e.y - cut),
		Vector2(e.x - cut, e.y), Vector2(p.x + cut, e.y),
		Vector2(p.x, e.y - cut), Vector2(p.x, p.y + cut),
	])

func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
