class_name CultivationChoiceButton
extends Button

## CanvasItem drawing on a parent happens before its child textures.  Keep the
## interaction frame in a dedicated last child so the folio artwork can never
## cover the focus rim or seal.
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

const INK := Color("#091413")
const PAPER := Color("#e6dcc0")
const PAPER_DIM := Color("#aaa88e")
const GOLD := Color("#d7aa4f")
const VERMILION := Color("#a9463c")
const TEXT_INK := Color("#1a2b2a")
const TEXT_DIM := Color("#4f5a51")
const FOLIO_TEXTURES := [
	preload("res://assets/generated/ui/UIKIT-004-talisman-folios/runtime/folio_sword.png"),
	preload("res://assets/generated/ui/UIKIT-004-talisman-folios/runtime/folio_jade.png"),
	preload("res://assets/generated/ui/UIKIT-004-talisman-folios/runtime/folio_spirit.png"),
]

var card_index := 0
var glyph_text := "+"
var title_text := "Công pháp"
var rank_text := ""
var description_text := ""
var accent_color := Color("#4cad8f")
var icon_texture: Texture2D

var number_label: Label
var glyph_label: Label
var title_label: Label
var description_label: Label
var choice_label: Label
var icon_rect: TextureRect
var folio_shadow: TextureRect
var folio_rect: TextureRect
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
	pressed.connect(_queue_visual_state)
	button_down.connect(_queue_visual_state)
	button_up.connect(_queue_visual_state)
	mouse_entered.connect(_queue_visual_state)
	mouse_exited.connect(_queue_visual_state)
	focus_entered.connect(_queue_visual_state)
	focus_exited.connect(_queue_visual_state)

func configure(index: int, glyph: String, title_value: String, description: String, accent: Color, texture: Texture2D = null) -> void:
	card_index = index
	glyph_text = glyph
	# Runtime option titles append "· Tầng N". Keep that useful hierarchy in
	# the small folio eyebrow instead of forcing one long line through the paper
	# silhouette.
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
		number_label.visible = not value
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 14 if value else 18)
	if description_label != null:
		description_label.add_theme_font_size_override("font_size", 14 if value else 15)
		description_label.text = _touch_description(description_text) if value else description_text
	if choice_label != null:
		choice_label.visible = not value
	_layout_content()
	_queue_visual_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		_layout_content()
		_queue_visual_state()

func _draw() -> void:
	if size.x < 24.0 or size.y < 24.0:
		return
	var hovered := is_hovered() or has_focus()
	var pressed_now := is_pressed()
	var edge := GOLD if hovered else accent_color
	var lift := -3.0 if hovered and not pressed_now else 1.0 if pressed_now else 0.0
	if folio_rect != null:
		folio_rect.position.y = lift
		folio_rect.modulate = Color(1.03, 1.02, 0.96, 1.0) if hovered else Color.WHITE
	if folio_shadow != null:
		folio_shadow.position = Vector2(0.0, 8.0 + lift)

	# Authored folio texture carries the material and silhouette. Custom drawing
	# is now limited to focus, icon containment and the selected gold seal.
	var layout_scale := clampf(size.y / 450.0, 0.58, 1.12)
	var seal_radius := 58.0 * layout_scale
	var seal_center := Vector2(size.x * 0.5, 112.0 * layout_scale + lift)
	draw_circle(seal_center, seal_radius + 3.0, Color("#071315", 0.88))
	draw_arc(seal_center, seal_radius, -2.8, 1.4, 44, Color(edge, 0.46 if not hovered else 0.86), 2.0, true)
	draw_arc(seal_center, seal_radius - 10.0, -0.3, 3.9, 36, Color(PAPER, 0.12), 1.0, true)
	for ray in range(4):
		var angle := PI * 0.25 + float(ray) * PI * 0.5
		draw_line(seal_center + Vector2.from_angle(angle) * (seal_radius + 2.0), seal_center + Vector2.from_angle(angle) * (seal_radius + 7.0), Color(edge, 0.58), 1.2, true)
	if icon_texture == null:
		_draw_discipline_icon(seal_center, edge)
	var divider_y := 184.0 * layout_scale + lift
	draw_line(Vector2(56.0, divider_y), Vector2(size.x - 56.0, divider_y), Color(edge, 0.46), 1.2, true)
	draw_circle(Vector2(size.x * 0.5, divider_y), 2.2, Color(edge, 0.72))


func draw_focus_overlay(canvas: Control) -> void:
	if canvas == null or not (is_hovered() or has_focus()):
		return
	var layout_scale := clampf(size.y / 450.0, 0.58, 1.12)
	var pressed_offset := 1.0 if is_pressed() else -3.0
	var visual_width := _folio_visual_width()
	var half_width := visual_width * 0.5
	var focus_inset := 12.0 * layout_scale if touch_mode else 5.0 * layout_scale
	var left := size.x * 0.5 - half_width + focus_inset
	var right := size.x * 0.5 + half_width - focus_inset
	var top := (14.0 if touch_mode else 8.0) * layout_scale + pressed_offset
	var bottom := size.y - (15.0 if touch_mode else 9.0) * layout_scale + pressed_offset
	var arm := (26.0 if touch_mode else 38.0) * layout_scale
	var corner_paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(left, top + arm), Vector2(left, top), Vector2(left + arm, top)]),
		PackedVector2Array([Vector2(right - arm, top), Vector2(right, top), Vector2(right, top + arm)]),
		PackedVector2Array([Vector2(left, bottom - arm), Vector2(left, bottom), Vector2(left + arm, bottom)]),
		PackedVector2Array([Vector2(right - arm, bottom), Vector2(right, bottom), Vector2(right, bottom - arm)]),
	]
	# An ink under-stroke keeps the gold cue readable over every paper value.
	for path in corner_paths:
		canvas.draw_polyline(path, Color(INK, 0.94), 7.0 * layout_scale, true)
		canvas.draw_polyline(path, Color(GOLD, 0.98), 3.0 * layout_scale, true)

	# Opposed diamonds change the card silhouette even in grayscale, while the
	# seal and explicit copy below provide redundant controller/pointer feedback.
	var top_mark := Vector2(size.x * 0.5, top + 1.0)
	var bottom_mark := Vector2(size.x * 0.5, bottom - 1.0)
	for mark in [top_mark, bottom_mark]:
		var diamond := PackedVector2Array([
			mark + Vector2(0.0, -7.0),
			mark + Vector2(7.0, 0.0),
			mark + Vector2(0.0, 7.0),
			mark + Vector2(-7.0, 0.0),
		])
		canvas.draw_colored_polygon(diamond, Color(INK, 0.96))
		canvas.draw_polyline(_closed(diamond), Color(GOLD, 1.0), 2.2, true)

	var seal_center := Vector2(minf(right - 8.0, size.x - 27.0), bottom - 34.0 * layout_scale)
	canvas.draw_circle(seal_center + Vector2(2.0, 3.0), 25.0 * layout_scale, Color(INK, 0.82))
	canvas.draw_circle(seal_center, 23.0 * layout_scale, Color(GOLD, 0.98))
	canvas.draw_circle(seal_center, 18.5 * layout_scale, Color(VERMILION, 0.98))
	canvas.draw_arc(seal_center, 13.5 * layout_scale, 0.0, TAU, 32, Color(PAPER, 0.88), 1.8 * layout_scale, true)
	var check := PackedVector2Array([
		seal_center + Vector2(-7.0, 0.0) * layout_scale,
		seal_center + Vector2(-2.0, 6.0) * layout_scale,
		seal_center + Vector2(9.0, -7.0) * layout_scale,
	])
	canvas.draw_polyline(check, Color(PAPER, 0.96), 3.0 * layout_scale, true)

func _build_content() -> void:
	for child in get_children():
		if child is Label or child is TextureRect:
			remove_child(child)
			child.queue_free()
	glyph_label = null
	icon_rect = null
	folio_shadow = TextureRect.new()
	folio_shadow.texture = FOLIO_TEXTURES[card_index % FOLIO_TEXTURES.size()]
	folio_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	folio_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	folio_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	folio_shadow.modulate = Color(0.0, 0.0, 0.0, 0.46)
	folio_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(folio_shadow)
	folio_rect = TextureRect.new()
	folio_rect.texture = folio_shadow.texture
	folio_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	folio_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	folio_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	folio_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(folio_rect)

	var eyebrow_copy := "ĐẠO DUYÊN  %02d" % (card_index + 1)
	if not rank_text.is_empty():
		eyebrow_copy += "  ·  " + rank_text
	number_label = _label(eyebrow_copy, 12, Color("#765326"))
	number_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	number_label.offset_left = 56.0
	number_label.offset_top = 28.0
	number_label.offset_right = -56.0
	number_label.offset_bottom = 52.0
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(number_label)

	if icon_texture != null:
		icon_rect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.set_anchors_preset(Control.PRESET_CENTER_TOP)
		icon_rect.offset_left = -59.0
		icon_rect.offset_top = 57.0
		icon_rect.offset_right = 59.0
		icon_rect.offset_bottom = 175.0
		add_child(icon_rect)
	else:
		glyph_label = _label(glyph_text, 28, PAPER)
		glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		glyph_label.offset_left = 40.0
		glyph_label.offset_top = 43.0
		glyph_label.offset_right = -40.0
		glyph_label.offset_bottom = 91.0
		add_child(glyph_label)

	title_label = _label(title_text, 18, TEXT_INK)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_left = 48.0
	title_label.offset_top = 202.0
	title_label.offset_right = -48.0
	title_label.offset_bottom = 260.0
	add_child(title_label)

	description_label = _label(description_text, 15, Color("#354640"))
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	description_label.offset_left = 52.0
	description_label.offset_top = 270.0
	description_label.offset_right = -52.0
	description_label.offset_bottom = 350.0
	add_child(description_label)

	choice_label = _label("LĨNH NGỘ  ·  PHÍM %d" % (card_index + 1), 12, Color("#765326"))
	choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	choice_label.offset_left = 58.0
	choice_label.offset_top = -68.0
	choice_label.offset_right = -58.0
	choice_label.offset_bottom = -36.0
	add_child(choice_label)
	# The glyph remains in the scene tree as a text fallback for accessibility,
	# while the hand-drawn discipline mark above carries the visual identity.
	if glyph_label != null:
		glyph_label.visible = false
	# Content is rebuilt when the offer changes; keep the focus canvas last so
	# it remains visibly above every raster and runtime-rendered label.
	move_child(focus_overlay, get_child_count() - 1)
	_layout_content()
	_queue_visual_state()


func _layout_content() -> void:
	if size.x < 24.0 or size.y < 24.0 or number_label == null:
		return
	var layout_scale := clampf(size.y / 450.0, 0.58, 1.12)
	var visual_width := _folio_visual_width()
	# Folio edges are irregular and vary per generated asset. Restrict type to
	# the quiet inner paper instead of assuming the full Button rectangle is safe.
	var minimum_text_width := 120.0 if size.y < 360.0 else 148.0
	var text_width := clampf(visual_width * 0.70, minimum_text_width, size.x - 72.0)
	var text_margin := (size.x - text_width) * 0.5
	for label in [number_label, title_label, description_label, choice_label]:
		label.offset_left = text_margin
		label.offset_right = -text_margin
	number_label.offset_top = 24.0 * layout_scale
	number_label.offset_bottom = 50.0 * layout_scale
	if icon_rect != null:
		icon_rect.offset_left = -56.0 * layout_scale
		icon_rect.offset_top = 57.0 * layout_scale
		icon_rect.offset_right = 56.0 * layout_scale
		icon_rect.offset_bottom = 169.0 * layout_scale
	if size.y < 360.0:
		title_label.offset_top = 120.0
		title_label.offset_bottom = 161.0
		description_label.offset_top = 168.0
		description_label.offset_bottom = 224.0
	else:
		title_label.offset_top = 198.0 * layout_scale
		title_label.offset_bottom = 254.0 * layout_scale
		description_label.offset_top = 263.0 * layout_scale
		description_label.offset_bottom = 346.0 * layout_scale
	choice_label.offset_top = -67.0 * layout_scale
	choice_label.offset_bottom = -35.0 * layout_scale


func _touch_description(value: String) -> String:
	match value:
		"Phi kiếm gây thêm 32% sát thương.":
			return "PHI KIẾM +32%"
		"Tốc độ xuất kiếm tăng 18%.":
			return "XUẤT KIẾM +18%"
		"Mỗi lần ngự kiếm phóng thêm một phi kiếm.":
			return "PHÓNG THÊM 1 KIẾM"
		"Phi kiếm xuyên thêm một mục tiêu.":
			return "XUYÊN +1 MỤC TIÊU"
		"Tốc độ di chuyển tăng 12%. Phạm vi hút linh khí tăng nhẹ.":
			return "DI CHUYỂN +12%"
		"Tăng 25 sinh mệnh tối đa và hồi ngay 25.":
			return "+25 SINH MỆNH"
		"Phạm vi hút tăng 34% và nhận thêm 12% linh khí.":
			return "HÚT +34% · KHÍ +12%"
		"Chấn khí rộng hơn 15% và mạnh hơn 28%.":
			return "CHẤN KHÍ +15% · +28%"
		"Hồi sinh mệnh mỗi giây tăng thêm 0.65.":
			return "HỒI +0.65 / GIÂY"
		"Định kỳ luyện hóa phi kiếm thành kiếm hỏa, gây gấp đôi sát thương.":
			return "KIẾM HỎA · X2 SÁT THƯƠNG"
		_:
			return value


func _folio_visual_width() -> float:
	var texture: Texture2D = FOLIO_TEXTURES[card_index % FOLIO_TEXTURES.size()] as Texture2D
	if texture == null or texture.get_height() <= 0:
		return size.x
	return minf(size.x, size.y * float(texture.get_width()) / float(texture.get_height()))


func _queue_visual_state() -> void:
	if choice_label != null:
		if touch_mode:
			choice_label.text = "CHẠM ĐỂ LĨNH NGỘ"
		else:
			choice_label.text = "ĐANG CHỌN  >  ENTER" if is_hovered() or has_focus() else "LĨNH NGỘ  ·  PHÍM %d" % (card_index + 1)
	queue_redraw()
	if focus_overlay != null:
		focus_overlay.queue_redraw()

func _draw_discipline_icon(center: Vector2, edge: Color) -> void:
	var ink := Color(PAPER, 0.82)
	match card_index % 3:
		0:
			# Trường sinh: a paired leaf/knot growing from one brush stem.
			draw_line(center + Vector2(0.0, 14.0), center + Vector2(0.0, -11.0), ink, 1.8, true)
			draw_arc(center + Vector2(-7.0, -5.0), 8.0, -2.8, 0.45, 18, Color(edge, 0.92), 2.0, true)
			draw_arc(center + Vector2(7.0, 1.0), 8.0, 0.45, 3.7, 18, Color(edge, 0.92), 2.0, true)
			draw_circle(center + Vector2(0.0, 15.0), 2.4, Color(edge, 0.90))
		1:
			# Tụ linh: a pearl with a quiet orbit and three qi motes.
			draw_circle(center, 9.0, Color("#d9c78c", 0.22))
			draw_circle(center, 6.0, Color("#f0e0a7", 0.84))
			draw_circle(center + Vector2(-2.0, -2.0), 2.0, Color.WHITE)
			draw_arc(center, 17.0, -2.7, 0.85, 24, Color(edge, 0.88), 1.5, true)
			draw_circle(center + Vector2(14.0, -8.0), 2.2, Color(edge, 0.90))
			draw_circle(center + Vector2(-15.0, 7.0), 2.0, Color(edge, 0.72))
		2:
			# Phá vọng kiếm: a flying jade blade over a broken ward.
			var blade := PackedVector2Array([
				center + Vector2(-3.0, -18.0), center + Vector2(5.0, 6.0),
				center + Vector2(0.0, 15.0), center + Vector2(-5.0, 6.0),
			])
			draw_colored_polygon(blade, Color(edge, 0.90))
			draw_polyline(_closed(blade), ink, 1.0, true)
			draw_line(center + Vector2(-12.0, 4.0), center + Vector2(12.0, 4.0), ink, 2.0, true)
			draw_line(center + Vector2(-14.0, 12.0), center + Vector2(-4.0, 12.0), Color(edge, 0.72), 1.0, true)
			draw_line(center + Vector2(5.0, 14.0), center + Vector2(14.0, 14.0), Color(edge, 0.52), 1.0, true)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.clip_text = true
	label.add_theme_font_size_override(&"font_size", maxi(font_size, 14))
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _card_shape(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([
		Vector2(p.x + cut, p.y),
		Vector2(e.x - cut * 1.4, p.y),
		Vector2(e.x, p.y + cut * 0.7),
		Vector2(e.x - cut * 0.18, e.y - cut * 1.25),
		Vector2(e.x - cut, e.y),
		Vector2(p.x + cut * 1.2, e.y),
		Vector2(p.x, e.y - cut * 0.72),
		Vector2(p.x + cut * 0.18, p.y + cut),
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
