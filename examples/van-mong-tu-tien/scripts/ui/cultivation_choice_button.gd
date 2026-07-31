class_name CultivationChoiceButton
extends Button

## V5 breakthrough folio inside the locked V4.1 direction. The complete
## illustrated manual stays fixed-aspect; all Vietnamese copy and focus remain
## live native nodes in the authored protected fields.

class FocusOverlay:
	extends Control

	var choice: CultivationChoiceButton

	func setup(owner: CultivationChoiceButton) -> void:
		choice = owner
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if choice != null:
			choice.draw_focus_overlay(self)


const INK := Color("#0b171b")
const PAPER := Color("#e7ddc4")
const PAPER_WARM := Color("#d9caa4")
const PAPER_COOL := Color("#cdd5ca")
const GOLD := Color("#9b7437")
const GOLD_LIGHT := Color("#c69a48")
const JADE := Color("#55c9a6")
const VERMILION := Color("#a9463c")
const TEXT_INK := Color("#17282a")
const TEXT_DIM := Color("#46514b")
const BODY_FONT := preload("res://assets/fonts/BeVietnamPro-Regular.ttf")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")
const FOLIO_TEXTURES: Array[Texture2D] = [
	preload("res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/sword-formation-folio-a.png"),
	preload("res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/spirit-vortex-folio-a.png"),
	preload("res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/jade-body-folio-a.png"),
]

var card_index := 0
var glyph_text := "+"
var title_text := "Công pháp"
var rank_text := ""
var description_text := ""
var accent_color := JADE
var icon_texture: Texture2D
var folio_index := 0

var number_label: Label
var glyph_label: Label
var title_label: Label
var description_label: Label
var choice_label: Label
var icon_rect: TextureRect
var folio_art: TextureRect
var focus_overlay: FocusOverlay
var touch_mode := false


func _init() -> void:
	flat = true
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	focus_overlay = FocusOverlay.new()
	focus_overlay.setup(self)
	add_child(focus_overlay)
	button_down.connect(_queue_visual_state)
	button_up.connect(_queue_visual_state)
	mouse_entered.connect(_queue_visual_state)
	mouse_exited.connect(_queue_visual_state)
	focus_entered.connect(_queue_visual_state)
	focus_exited.connect(_queue_visual_state)


func configure(index: int, glyph: String, title_value: String, description: String, accent: Color, texture: Texture2D = null, folio_family: int = -1) -> void:
	card_index = index
	folio_index = index if folio_family < 0 else clampi(folio_family, 0, FOLIO_TEXTURES.size() - 1)
	glyph_text = glyph
	var rank_marker := title_value.find("Tầng")
	var divider := title_value.rfind("·", rank_marker) if rank_marker >= 0 else -1
	if rank_marker >= 0 and divider >= 0:
		title_text = title_value.substr(0, divider).strip_edges()
		rank_text = title_value.substr(rank_marker).strip_edges().to_upper()
	else:
		title_text = title_value
		rank_text = ""
	description_text = description
	accent_color = accent
	icon_texture = texture
	tooltip_text = "%s — %s" % [title_text, description_text]
	_build_content()
	queue_redraw()


func set_touch_mode(value: bool) -> void:
	touch_mode = value
	if number_label != null:
		# One protected title cartouche cannot carry both a title and an eyebrow.
		# The key prompt already communicates ordering, so keep this hidden at all
		# sizes instead of printing through the authored ornament.
		number_label.hide()
	if description_label != null:
		description_label.text = _touch_description(description_text) if value else description_text
	if choice_label != null:
		choice_label.text = "CHẠM ĐỂ LĨNH NGỘ" if value else "LĨNH NGỘ  ·  PHÍM %d" % (card_index + 1)
	_layout_content()
	_queue_visual_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		_layout_content()
		_queue_visual_state()


func _draw() -> void:
	if size.x < 24.0 or size.y < 24.0:
		return
	# The V5 manual is a complete silhouette. Drawing the legacy native paper
	# card behind it creates the pale rectangular box visible in the rejected
	# desktop/phone captures.
	if folio_art != null:
		return
	var active := is_hovered() or has_focus()
	var down := is_pressed()
	var lift := -2.0 if active and not down else 1.0 if down else 0.0
	var visual_rect := _visual_rect(lift)
	var cut := clampf(visual_rect.size.x * 0.055, 8.0, 15.0)
	var card := _card_shape(visual_rect, cut)
	draw_colored_polygon(_offset_points(card, Vector2(5.0, 7.0)), Color(0.0, 0.0, 0.0, 0.40))
	draw_colored_polygon(card, _paper_tone())
	draw_polyline(_closed(card), Color(INK, 0.92), 3.0, true)
	draw_polyline(_closed(card), Color(GOLD_LIGHT if active else GOLD, 0.90), 1.2 if active else 0.9, true)

	var inner := visual_rect.grow(-7.0)
	draw_polyline(_closed(_card_shape(inner, maxf(4.0, cut - 4.0))), Color(GOLD, 0.26), 1.0, true)
	var seal_center := Vector2(visual_rect.get_center().x, visual_rect.position.y + (52.0 if touch_mode else 78.0))
	var seal_radius := 26.0 if touch_mode else 39.0
	draw_circle(seal_center, seal_radius + 4.0, Color(INK, 0.91))
	draw_arc(seal_center, seal_radius, -2.7, 1.05, 44, Color(accent_color, 0.72 if active else 0.46), 2.0, true)
	draw_arc(seal_center, seal_radius - 7.0, 0.15, 4.35, 40, Color(PAPER, 0.19), 1.0, true)
	var divider_y := visual_rect.position.y + (98.0 if touch_mode else 142.0)
	draw_line(Vector2(visual_rect.position.x + 28.0, divider_y), Vector2(visual_rect.end.x - 28.0, divider_y), Color(GOLD, 0.40), 1.0, true)
	_draw_bottom_seal(visual_rect, active)


func draw_focus_overlay(canvas: Control) -> void:
	if canvas == null or not (is_hovered() or has_focus()):
		return
	var rect := _fitted_folio_rect(-2.0).grow(-3.0)
	var arm := 20.0 if touch_mode else 28.0
	var paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(rect.position.x, rect.position.y + arm), rect.position, Vector2(rect.position.x + arm, rect.position.y)]),
		PackedVector2Array([Vector2(rect.end.x - arm, rect.position.y), Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + arm)]),
		PackedVector2Array([Vector2(rect.position.x, rect.end.y - arm), Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + arm, rect.end.y)]),
		PackedVector2Array([Vector2(rect.end.x - arm, rect.end.y), rect.end, Vector2(rect.end.x, rect.end.y - arm)]),
	]
	for path in paths:
		canvas.draw_polyline(path, Color(INK, 0.96), 5.0, true)
		canvas.draw_polyline(path, Color(GOLD_LIGHT, 1.0), 2.0, true)


func _build_content() -> void:
	for child in get_children():
		if child != focus_overlay:
			remove_child(child)
			child.queue_free()

	folio_art = TextureRect.new()
	folio_art.name = "AuthoredFolioTexture"
	folio_art.texture = FOLIO_TEXTURES[folio_index % FOLIO_TEXTURES.size()]
	folio_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	folio_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	folio_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	folio_art.modulate = Color.WHITE
	folio_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(folio_art)

	var eyebrow := "ĐẠO DUYÊN %02d" % (card_index + 1)
	if not rank_text.is_empty():
		eyebrow += "  ·  " + rank_text
	number_label = _label(eyebrow, 12, Color("#765326"), true)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.hide()
	add_child(number_label)

	# The manual illustration itself carries school identity. Avoid pasting a
	# second medallion over the painting; this was one of the cheap/boxy signals
	# in the rejected runtime capture.
	icon_rect = null
	glyph_label = null

	title_label = _label(title_text, 17, TEXT_INK, true)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(title_label)
	description_label = _label(description_text, 15, TEXT_DIM)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description_label)
	choice_label = _label("LĨNH NGỘ  ·  PHÍM %d" % (card_index + 1), 12, PAPER, true)
	choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(choice_label)
	move_child(focus_overlay, get_child_count() - 1)
	_layout_content()


func _layout_content() -> void:
	if size.x < 24.0 or size.y < 24.0 or number_label == null:
		return
	var rect := _fitted_folio_rect(0.0)
	var margin := clampf(rect.size.x * 0.14, 25.0, 42.0)
	var left := rect.position.x + margin
	var right := rect.end.x - margin
	if folio_art != null:
		_set_rect(folio_art, rect)
	_set_rect(number_label, Rect2(left, rect.position.y + (5.0 if touch_mode else 10.0), right - left, 18.0 if touch_mode else 22.0))
	if touch_mode:
		_set_rect(title_label, Rect2(left, rect.position.y + rect.size.y * 0.055, right - left, rect.size.y * 0.105))
		_set_rect(description_label, Rect2(left, rect.position.y + rect.size.y * 0.70, right - left, rect.size.y * 0.145))
		_set_rect(choice_label, Rect2(left, rect.end.y - 22.0, right - left, 15.0))
		title_label.add_theme_font_size_override(&"font_size", 12)
		description_label.add_theme_font_size_override(&"font_size", 10)
		choice_label.add_theme_font_size_override(&"font_size", 10)
	else:
		_set_rect(title_label, Rect2(left, rect.position.y + rect.size.y * 0.055, right - left, rect.size.y * 0.105))
		_set_rect(description_label, Rect2(left, rect.position.y + rect.size.y * 0.70, right - left, rect.size.y * 0.145))
		_set_rect(choice_label, Rect2(left, rect.end.y - 29.0, right - left, 18.0))
		title_label.add_theme_font_size_override(&"font_size", 14)
		description_label.add_theme_font_size_override(&"font_size", 12)
		choice_label.add_theme_font_size_override(&"font_size", 11)


func _visual_rect(y_offset: float) -> Rect2:
	var horizontal := clampf(size.x * 0.035, 5.0, 11.0)
	return Rect2(Vector2(horizontal, 3.0 + y_offset), Vector2(size.x - horizontal * 2.0, size.y - 10.0))


func _fitted_folio_rect(y_offset: float) -> Rect2:
	var bounds := _visual_rect(y_offset).grow(-4.0)
	if folio_art == null or folio_art.texture == null:
		return bounds
	var source := Vector2(folio_art.texture.get_size())
	if source.x <= 1.0 or source.y <= 1.0:
		return bounds
	var scale_value := minf(bounds.size.x / source.x, bounds.size.y / source.y)
	var fitted := source * scale_value
	return Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted)


func _paper_tone() -> Color:
	match card_index % 3:
		0:
			return PAPER_WARM
		1:
			return PAPER
		_:
			return PAPER_COOL


func _draw_bottom_seal(rect: Rect2, active: bool) -> void:
	var center := Vector2(rect.get_center().x, rect.end.y - 9.0)
	var radius := 5.0
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius), center + Vector2(-radius, 0.0),
	])
	draw_colored_polygon(diamond, Color(VERMILION if active else GOLD, 0.90))


func _touch_description(value: String) -> String:
	match value:
		"Phi kiếm gây thêm 32% sát thương.": return "PHI KIẾM +32%"
		"Tốc độ xuất kiếm tăng 18%.": return "XUẤT KIẾM +18%"
		"Mỗi lần ngự kiếm phóng thêm một phi kiếm.": return "PHÓNG THÊM 1 KIẾM"
		"Phi kiếm xuyên thêm một mục tiêu.": return "XUYÊN +1 MỤC TIÊU"
		"Tốc độ di chuyển tăng 12%. Phạm vi hút linh khí tăng nhẹ.": return "DI CHUYỂN +12%"
		"Tăng 25 sinh mệnh tối đa và hồi ngay 25.": return "+25 SINH MỆNH"
		"Phạm vi hút tăng 34% và nhận thêm 12% linh khí.": return "HÚT +34% · KHÍ +12%"
		"Chấn khí rộng hơn 15% và mạnh hơn 28%.": return "CHẤN KHÍ +15% · +28%"
		"Hồi sinh mệnh mỗi giây tăng thêm 0.65.": return "HỒI +0.65 / GIÂY"
		"Định kỳ luyện hóa phi kiếm thành kiếm hỏa, gây gấp đôi sát thương.": return "KIẾM HỎA · X2 SÁT THƯƠNG"
		_: return value


func _label(value: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.clip_text = true
	label.add_theme_font_override(&"font", ACTION_FONT if bold else BODY_FONT)
	label.add_theme_font_size_override(&"font_size", maxi(font_size, 10))
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _set_rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size


func _card_shape(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([
		Vector2(p.x + cut, p.y), Vector2(e.x - cut * 1.25, p.y),
		Vector2(e.x, p.y + cut * 0.75), Vector2(e.x - cut * 0.16, e.y - cut),
		Vector2(e.x - cut, e.y), Vector2(p.x + cut * 0.72, e.y),
		Vector2(p.x, e.y - cut * 0.72), Vector2(p.x + cut * 0.18, p.y + cut),
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


func _queue_visual_state() -> void:
	if choice_label != null and not touch_mode:
		choice_label.text = "ĐANG CHỌN  ·  ENTER" if is_hovered() or has_focus() else "LĨNH NGỘ  ·  PHÍM %d" % (card_index + 1)
	queue_redraw()
	if focus_overlay != null:
		focus_overlay.queue_redraw()
