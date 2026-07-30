class_name CultivationActionButton
extends Button

const INK := Color("#091719")
const INK_LIT := Color("#14292b")
const PAPER := Color("#e7ddc4")
const GOLD := Color("#8a6730")
const GOLD_LIT := Color("#c69a48")
const JADE := Color("#55c9a6")

func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x < 20.0 or size.y < 14.0:
		return
	var active := is_hovered() or has_focus()
	var down := is_pressed()
	var y_offset := -1.0 if active and not down else 1.0 if down else 0.0
	var shape := _shape(Rect2(Vector2(0.0, y_offset), Vector2(size.x, size.y - y_offset)), clampf(size.y * 0.18, 7.0, 11.0))
	draw_colored_polygon(_offset(shape, Vector2(3.0, 4.0)), Color(0.0, 0.0, 0.0, 0.38))
	var fill := Color(JADE.darkened(0.48), 0.98) if down else (INK_LIT if active else INK)
	draw_colored_polygon(shape, fill)
	draw_polyline(_closed(shape), Color(JADE if active or down else GOLD_LIT, 0.98 if active else 0.78), 2.0 if active else 1.2, true)
	var inner := _shape(Rect2(Vector2(5.0, 5.0 + y_offset), Vector2(size.x - 10.0, size.y - 10.0 - y_offset)), 6.0)
	draw_polyline(_closed(inner), Color(PAPER, 0.18), 1.0, true)
	# Small jade/ink talisman marks make a CTA feel authored rather than a
	# stock rounded button, while leaving the label's center uncluttered.
	var center := Vector2(16.0, size.y * 0.5 + y_offset)
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -5.0), center + Vector2(5.0, 0.0),
		center + Vector2(0.0, 5.0), center + Vector2(-5.0, 0.0),
	])
	draw_colored_polygon(diamond, Color(JADE if active else GOLD_LIT, 0.82))
	draw_polyline(_closed(diamond), Color(PAPER, 0.58), 1.0, true)
	var right := Vector2(size.x - 16.0, size.y * 0.5 + y_offset)
	draw_line(right + Vector2(-5.0, 0.0), right + Vector2(5.0, 0.0), Color(GOLD_LIT, 0.62), 1.0, true)
	draw_line(right + Vector2(0.0, -5.0), right + Vector2(0.0, 5.0), Color(GOLD_LIT, 0.62), 1.0, true)
	# Button's built-in renderer is replaced because an empty StyleBox suppresses
	# the parent draw pass. Draw the localized label ourselves while retaining
	# Button.text for accessibility and keyboard automation.
	var font := get_theme_font(&"font")
	var font_size := get_theme_font_size(&"font_size")
	var label_color := get_theme_color(&"font_pressed_color") if down else (get_theme_color(&"font_hover_color") if active else get_theme_color(&"font_color"))
	var baseline := size.y * 0.5 + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5 + y_offset
	draw_string(font, Vector2(0.0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, label_color)

func _shape(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([
		Vector2(p.x + cut, p.y), Vector2(e.x - cut * 1.4, p.y),
		Vector2(e.x, p.y + cut * 0.7), Vector2(e.x - cut * 0.18, e.y - cut),
		Vector2(e.x - cut, e.y), Vector2(p.x + cut * 1.2, e.y),
		Vector2(p.x, e.y - cut * 0.7), Vector2(p.x + cut * 0.18, p.y + cut),
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
