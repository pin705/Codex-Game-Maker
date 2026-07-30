class_name CultivationPanel
extends PanelContainer

## V4 scalable presentation surface.
##
## The approved direction uses matte lacquer, quiet paper and thin bronze
## structure.  This component intentionally draws those materials natively so
## compact HUD islands and large modal plates never inherit a stretched raster
## frame.  `material_root`, `authored_chrome` and `authored_emblem` remain public
## for callers that attach portraits or isolated emblems.

enum FrameKind {
	HUD,
	SCROLL,
	PAPER,
	BANNER,
	SEAL,
}

const DEEP_INK := Color("#091517")
const BRONZE := Color("#8a6730")
const BRONZE_LIGHT := Color("#c39a54")
const PAPER_FIBRE := Color("#d8caa7")

var frame_kind: FrameKind = FrameKind.HUD
var fill_color := Color("#0a1718")
var accent_color := Color("#b89043")
var paper_color := Color("#d8cba4")
var ornament_seed := 1

var material_root: Control
var authored_chrome: NinePatchRect
var authored_emblem: TextureRect
var authored_fixed: TextureRect
var lacquer_veil: ColorRect
var suppress_native_material := false


func _init() -> void:
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

	material_root = Control.new()
	material_root.name = "V4MaterialRoot"
	material_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	material_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(material_root)

	# Compatibility presentation handles. V4 draws scalable chrome in `_draw`;
	# these remain available to callers without introducing raster distortion.
	authored_chrome = NinePatchRect.new()
	authored_chrome.name = "V4NativeChromeHandle"
	authored_chrome.visible = false
	authored_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_root.add_child(authored_chrome)
	authored_fixed = TextureRect.new()
	authored_fixed.name = "V4AuthoredFixedArt"
	authored_fixed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	authored_fixed.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	authored_fixed.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	authored_fixed.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_fixed.visible = false
	authored_fixed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_root.add_child(authored_fixed)
	authored_emblem = TextureRect.new()
	authored_emblem.name = "V4EmblemHandle"
	authored_emblem.visible = false
	authored_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_root.add_child(authored_emblem)
	lacquer_veil = ColorRect.new()
	lacquer_veil.name = "V4ContentFieldHandle"
	lacquer_veil.visible = false
	lacquer_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_root.add_child(lacquer_veil)


func configure(kind: FrameKind, fill: Color, accent: Color, seed: int = 1) -> CultivationPanel:
	frame_kind = kind
	fill_color = fill
	accent_color = accent
	ornament_seed = seed
	queue_redraw()
	return self


func use_authored_fixed(texture_value: Texture2D) -> CultivationPanel:
	if texture_value == null:
		return self
	suppress_native_material = true
	authored_fixed.texture = texture_value
	authored_fixed.visible = true
	authored_fixed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	authored_chrome.visible = false
	queue_redraw()
	return self


func use_authored_nine_patch(texture_value: Texture2D, margins: Vector4) -> CultivationPanel:
	if texture_value == null:
		return self
	suppress_native_material = true
	authored_chrome.texture = texture_value
	authored_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	authored_chrome.set_patch_margin(SIDE_LEFT, roundi(margins.x))
	authored_chrome.set_patch_margin(SIDE_TOP, roundi(margins.y))
	authored_chrome.set_patch_margin(SIDE_RIGHT, roundi(margins.z))
	authored_chrome.set_patch_margin(SIDE_BOTTOM, roundi(margins.w))
	authored_chrome.draw_center = true
	authored_chrome.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_chrome.visible = true
	authored_fixed.visible = false
	queue_redraw()
	return self


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	if suppress_native_material:
		return
	match frame_kind:
		FrameKind.SEAL:
			_draw_seal()
		FrameKind.PAPER:
			_draw_plate(true)
		FrameKind.SCROLL:
			_draw_plate(fill_color.get_luminance() > 0.42)
		FrameKind.BANNER:
			_draw_banner()
		_:
			_draw_hud_island()


func _draw_hud_island() -> void:
	var cut := clampf(minf(size.x, size.y) * 0.13, 7.0, 15.0)
	var outer := _clipped_rect(Rect2(Vector2.ZERO, size), cut)
	draw_colored_polygon(_offset(outer, Vector2(3.0, 5.0)), Color(0.0, 0.0, 0.0, 0.36))
	draw_colored_polygon(outer, Color(fill_color.r, fill_color.g, fill_color.b, clampf(fill_color.a, 0.84, 0.96)))
	draw_polyline(_closed(outer), Color(BRONZE, 0.86), 1.4, true)
	var inner_rect := Rect2(Vector2(5.0, 5.0), size - Vector2(10.0, 10.0))
	var inner := _clipped_rect(inner_rect, maxf(3.0, cut - 4.0))
	draw_polyline(_closed(inner), Color(accent_color, 0.26), 1.0, true)
	_draw_corner_hardware(cut, false)


func _draw_banner() -> void:
	var cut := clampf(size.y * 0.28, 8.0, 19.0)
	var outer := _banner_shape(Rect2(Vector2.ZERO, size), cut)
	draw_colored_polygon(_offset(outer, Vector2(2.0, 4.0)), Color(0.0, 0.0, 0.0, 0.34))
	draw_colored_polygon(outer, Color(fill_color.r, fill_color.g, fill_color.b, clampf(fill_color.a, 0.80, 0.94)))
	draw_polyline(_closed(outer), Color(BRONZE, 0.80), 1.25, true)
	var y := size.y - clampf(size.y * 0.19, 5.0, 10.0)
	draw_line(Vector2(cut * 1.6, y), Vector2(size.x - cut * 1.6, y), Color(accent_color, 0.42), 1.0, true)


func _draw_plate(light_surface: bool) -> void:
	var cut := clampf(minf(size.x, size.y) * 0.055, 10.0, 24.0)
	var outer := _clipped_rect(Rect2(Vector2.ZERO, size), cut)
	draw_colored_polygon(_offset(outer, Vector2(7.0, 9.0)), Color(0.0, 0.0, 0.0, 0.42))
	var surface := Color(fill_color.r, fill_color.g, fill_color.b, clampf(fill_color.a, 0.94, 1.0))
	if light_surface:
		surface = Color(PAPER_FIBRE, clampf(fill_color.a, 0.94, 1.0))
	draw_colored_polygon(outer, surface)
	draw_polyline(_closed(outer), Color(DEEP_INK, 0.92), 4.0, true)
	draw_polyline(_closed(outer), Color(BRONZE_LIGHT, 0.78), 1.35, true)
	var inset := clampf(cut * 0.62, 7.0, 13.0)
	var inner_rect := Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0)
	var inner := _clipped_rect(inner_rect, maxf(4.0, cut - inset))
	draw_polyline(_closed(inner), Color(BRONZE if light_surface else accent_color, 0.34), 1.0, true)
	_draw_corner_hardware(cut, light_surface)


func _draw_seal() -> void:
	var radius := minf(size.x, size.y) * 0.28
	var center := size * 0.5
	draw_circle(center, radius + 8.0, Color(0.0, 0.0, 0.0, 0.12))
	draw_arc(center, radius, -2.75, 1.05, 56, Color(accent_color, 0.24), 2.0, true)
	draw_arc(center, radius - 11.0, 0.25, 4.35, 48, Color(BRONZE_LIGHT, 0.18), 1.0, true)
	for index in 4:
		var angle := PI * 0.25 + float(index) * PI * 0.5
		var point := center + Vector2.from_angle(angle) * radius
		var diamond := PackedVector2Array([
			point + Vector2(0.0, -4.0), point + Vector2(4.0, 0.0),
			point + Vector2(0.0, 4.0), point + Vector2(-4.0, 0.0),
		])
		draw_colored_polygon(diamond, Color(accent_color, 0.34))


func _draw_corner_hardware(cut: float, light_surface: bool) -> void:
	var hardware := Color(BRONZE_LIGHT if not light_surface else BRONZE, 0.72)
	var arm := clampf(cut * 0.82, 7.0, 13.0)
	var inset := 3.0
	var corners := [
		[Vector2(inset, inset + arm), Vector2(inset, inset), Vector2(inset + arm, inset)],
		[Vector2(size.x - inset - arm, inset), Vector2(size.x - inset, inset), Vector2(size.x - inset, inset + arm)],
		[Vector2(inset, size.y - inset - arm), Vector2(inset, size.y - inset), Vector2(inset + arm, size.y - inset)],
		[Vector2(size.x - inset - arm, size.y - inset), Vector2(size.x - inset, size.y - inset), Vector2(size.x - inset, size.y - inset - arm)],
	]
	for path: Array in corners:
		draw_polyline(PackedVector2Array(path), hardware, 2.0, true)


func _clipped_rect(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([
		Vector2(p.x + cut, p.y), Vector2(e.x - cut * 0.65, p.y),
		Vector2(e.x, p.y + cut * 0.65), Vector2(e.x, e.y - cut),
		Vector2(e.x - cut, e.y), Vector2(p.x + cut * 0.65, e.y),
		Vector2(p.x, e.y - cut * 0.65), Vector2(p.x, p.y + cut),
	])


func _banner_shape(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([
		Vector2(p.x, p.y + cut * 0.52), Vector2(p.x + cut, p.y),
		Vector2(e.x - cut, p.y), Vector2(e.x, p.y + cut * 0.52),
		Vector2(e.x - cut * 0.72, e.y), Vector2(p.x + cut * 0.72, e.y),
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
