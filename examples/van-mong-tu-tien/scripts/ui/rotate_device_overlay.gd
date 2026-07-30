class_name RotateDeviceOverlay
extends Control

## Full-screen portrait guard for a landscape-first combat experience.

signal orientation_block_changed(is_blocking: bool)

const SafeArea := preload("res://scripts/ui/mobile_safe_area.gd")

const REFERENCE_HEIGHT := 900.0
const PANEL_TEXTURE_PATH := "res://assets/generated/ui/UIKIT-005-restrained-controls/runtime/ui_lacquer_panel.png"
const ROTATE_SIGIL_PATH := "res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/sigil_tu_linh.png"

@export var overlay_enabled := true
@export_range(0.0, 0.20, 0.005) var title_safe_margin_ratio := 0.05
@export_range(0.0, 48.0, 1.0) var additional_safe_padding := 12.0

var _viewport_size_override := Vector2.ZERO
var _orientation_size_override := Vector2.ZERO
var _safe_area_override := Rect2()
var _has_safe_area_override := false
var _safe_rect := Rect2()
var _message_rect := Rect2()
var _last_blocking := false
var _last_orientation_probe := Vector2.ZERO

var _shade: ColorRect
var _panel: Panel
var _glyph: TextureRect
var _title: Label
var _message: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_content()
	refresh_orientation()


func _process(_delta: float) -> void:
	var current_probe := _get_orientation_probe_size()
	if not current_probe.is_equal_approx(_last_orientation_probe):
		refresh_orientation()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		refresh_orientation()


func set_overlay_enabled(value: bool) -> void:
	overlay_enabled = value
	refresh_orientation()


func set_viewport_size_override(value: Vector2) -> void:
	_viewport_size_override = value.max(Vector2.ZERO)
	refresh_orientation()


func clear_viewport_size_override() -> void:
	_viewport_size_override = Vector2.ZERO
	refresh_orientation()


func set_orientation_size_override(value: Vector2) -> void:
	_orientation_size_override = value.max(Vector2.ZERO)
	refresh_orientation()


func clear_orientation_size_override() -> void:
	_orientation_size_override = Vector2.ZERO
	refresh_orientation()


func set_safe_area_override(value: Rect2) -> void:
	_safe_area_override = value
	_has_safe_area_override = value.has_area()
	refresh_orientation()


func clear_safe_area_override() -> void:
	_safe_area_override = Rect2()
	_has_safe_area_override = false
	refresh_orientation()


func is_blocking_portrait() -> bool:
	return _last_blocking


func get_safe_area_rect() -> Rect2:
	return _safe_rect


func get_message_rect() -> Rect2:
	return _message_rect


func refresh_orientation() -> bool:
	var viewport_size := _get_layout_viewport_size()
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return false
	var raw_safe := _safe_area_override if _has_safe_area_override else SafeArea.platform_safe_rect(viewport_size)
	var ui_scale := clampf(minf(viewport_size.x, viewport_size.y) / REFERENCE_HEIGHT, 0.72, 1.25)
	_safe_rect = SafeArea.title_safe_rect(
		viewport_size,
		raw_safe,
		title_safe_margin_ratio,
		additional_safe_padding * ui_scale
	)
	var target_size := Vector2(
		minf(720.0 * ui_scale, _safe_rect.size.x),
		minf(390.0 * ui_scale, _safe_rect.size.y)
	)
	_message_rect = SafeArea.centered_rect_inside(_safe_rect, _safe_rect.get_center(), target_size)
	var orientation_size := _get_orientation_probe_size()
	_last_orientation_probe = orientation_size
	var blocking := overlay_enabled and orientation_size.y > orientation_size.x
	var was_blocking := _last_blocking
	_last_blocking = blocking
	visible = blocking
	_layout_content(ui_scale)
	if blocking != was_blocking:
		orientation_block_changed.emit(blocking)
	return blocking


func _get_layout_viewport_size() -> Vector2:
	if _viewport_size_override.x > 0.0 and _viewport_size_override.y > 0.0:
		return _viewport_size_override
	if size.x > 1.0 and size.y > 1.0:
		return size
	if is_inside_tree():
		return get_viewport_rect().size
	return Vector2(1600.0, 900.0)


func _get_orientation_probe_size() -> Vector2:
	if _orientation_size_override.x > 0.0 and _orientation_size_override.y > 0.0:
		return _orientation_size_override
	if _viewport_size_override.x > 0.0 and _viewport_size_override.y > 0.0:
		return _viewport_size_override
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x > 1.0 and window_size.y > 1.0:
		return window_size
	return _get_layout_viewport_size()


func _ensure_content() -> void:
	if _shade != null:
		return
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = Color(0.015, 0.027, 0.031, 0.94)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)

	_panel = Panel.new()
	_panel.name = "OrientationSurface"
	var panel_style := StyleBoxFlat.new()
	var panel_texture: Texture2D
	if ResourceLoader.exists(PANEL_TEXTURE_PATH):
		var loaded_panel: Variant = load(PANEL_TEXTURE_PATH)
		if loaded_panel is Texture2D:
			panel_texture = loaded_panel as Texture2D
	panel_style.bg_color = Color(0.025, 0.058, 0.060, 0.10 if panel_texture != null else 0.98)
	panel_style.border_color = Color("#65d0aa", 0.0 if panel_texture != null else 0.62)
	panel_style.set_border_width_all(0 if panel_texture != null else 2)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.46)
	panel_style.shadow_size = 14
	panel_style.shadow_offset = Vector2(0.0, 8.0)
	_panel.add_theme_stylebox_override(&"panel", panel_style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	if panel_texture != null:
		var chrome := NinePatchRect.new()
		chrome.name = "AuthoredChrome"
		chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		chrome.texture = panel_texture
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			chrome.set_patch_margin(side, 54)
		chrome.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.add_child(chrome)

	_glyph = TextureRect.new()
	_glyph.name = "RotateGlyph"
	if ResourceLoader.exists(ROTATE_SIGIL_PATH):
		var loaded_sigil: Variant = load(ROTATE_SIGIL_PATH)
		if loaded_sigil is Texture2D:
			_glyph.texture = loaded_sigil as Texture2D
	_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_glyph.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glyph)

	_title = Label.new()
	_title.name = "Title"
	_title.text = "XOAY THIẾT BỊ"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_color_override(&"font_color", Color("#fff1bd"))
	_title.add_theme_color_override(&"font_outline_color", Color("#101a1d"))
	_title.add_theme_constant_override(&"outline_size", 5)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	_message = Label.new()
	_message.name = "Message"
	_message.text = "Vân Mộng Tông được thiết kế cho màn hình ngang.\nHãy xoay máy để tiếp tục hành trình tu tiên."
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override(&"font_color", Color("#d7e8df"))
	_message.add_theme_color_override(&"font_outline_color", Color("#101a1d"))
	_message.add_theme_constant_override(&"outline_size", 3)
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message)


func _layout_content(ui_scale: float) -> void:
	if _shade == null:
		return
	_panel.position = _message_rect.position
	_panel.size = _message_rect.size
	var content := _message_rect.grow(-maxf(22.0, 34.0 * ui_scale))
	var glyph_height := minf(content.size.y * 0.34, 112.0 * ui_scale)
	var title_height := maxf(52.0, 64.0 * ui_scale)
	var glyph_size := minf(glyph_height, 104.0 * ui_scale)
	_glyph.position = Vector2(content.get_center().x - glyph_size * 0.5, content.position.y)
	_glyph.size = Vector2(glyph_size, glyph_size)
	_title.position = Vector2(content.position.x, content.position.y + glyph_height)
	_title.size = Vector2(content.size.x, title_height)
	_title.add_theme_font_size_override(&"font_size", maxi(28, int(round(38.0 * ui_scale))))
	_message.position = Vector2(content.position.x, content.position.y + glyph_height + title_height)
	_message.size = Vector2(content.size.x, maxf(64.0, content.size.y - glyph_height - title_height))
	_message.add_theme_font_size_override(&"font_size", maxi(18, int(round(23.0 * ui_scale))))
