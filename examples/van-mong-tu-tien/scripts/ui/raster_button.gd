class_name RasterButton
extends Button

## Restrained cinematic command control.
##
## The previous implementation stretched the same ornate raster frame over every
## target.  That made corners, clasps and highlights deform at different aspect
## ratios.  This control keeps input/accessibility on a native Button, builds its
## material from stable edge geometry, and reserves authored raster art for small
## non-stretched brush accents when those assets are available.

enum ArtVariant { GOLD, JADE, INK, CRIMSON }

const PAPER := Color("#f3ead0")
const PAPER_DIM := Color("#b9b39f")
const INK := Color("#071113")
const GOLD := Color("#d8ad55")
const JADE := Color("#5fd0ac")
const CRIMSON := Color("#d76a61")

const BUTTON_ROOT := "res://assets/generated/ui/UIKIT-005-restrained-controls/runtime/"
const BUTTON_PATHS := {
	ArtVariant.GOLD: BUTTON_ROOT + "ui_command_ink.png",
	ArtVariant.JADE: BUTTON_ROOT + "ui_command_ink.png",
	ArtVariant.INK: BUTTON_ROOT + "ui_command_ink.png",
	ArtVariant.CRIMSON: BUTTON_ROOT + "ui_command_ink.png",
}

var art_variant := ArtVariant.GOLD
var caption := ""
var caption_size := 17
var _configured := false

var surface: Panel
var authored_accent: NinePatchRect
var edge: ColorRect
var caption_label: Label
var chevron_label: Label


func configure(
	text_value: String,
	variant: ArtVariant = ArtVariant.GOLD,
	minimum: Vector2 = Vector2(280.0, 64.0),
	font_size: int = 17
) -> RasterButton:
	caption = text_value
	art_variant = variant
	caption_size = maxi(font_size, 14)
	# 64 logical pixels keeps the global target above 48 px at the supported
	# 1280x720 (0.8x) presentation scale.
	custom_minimum_size = Vector2(maxf(minimum.x, 96.0), maxf(minimum.y, 64.0))
	_build_visuals()
	return self


func _ready() -> void:
	if not _configured:
		_build_visuals()
	_layout_caption()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_caption()


func _build_visuals() -> void:
	_configured = true
	text = ""
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	for child in get_children():
		child.queue_free()

	surface = Panel.new()
	surface.name = "MaterialSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)

	authored_accent = NinePatchRect.new()
	authored_accent.name = "AuthoredCommandFrame"
	authored_accent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var compact_frame := _uses_compact_native_material()
	var horizontal_margin := 40 if compact_frame else 56
	var vertical_margin := 26 if compact_frame else 30
	authored_accent.set_patch_margin(SIDE_LEFT, horizontal_margin)
	authored_accent.set_patch_margin(SIDE_TOP, vertical_margin)
	authored_accent.set_patch_margin(SIDE_RIGHT, horizontal_margin)
	authored_accent.set_patch_margin(SIDE_BOTTOM, vertical_margin)
	authored_accent.draw_center = true
	authored_accent.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Square symbol controls use a crisp native material treatment. Cropping the
	# wide painted plaque into a square destroys its corners and was the source
	# of the former ragged fragments on Settings. Short text controls still use
	# the authored plaque so phone navigation never falls back to web-form boxes.
	var accent_path := "" if compact_frame else str(BUTTON_PATHS.get(art_variant, ""))
	if not accent_path.is_empty() and ResourceLoader.exists(accent_path):
		var loaded: Variant = load(accent_path)
		if loaded is Texture2D:
			authored_accent.texture = loaded as Texture2D
			authored_accent.modulate = _variant_texture_tint(0.96)
			surface.add_child(authored_accent)

	edge = ColorRect.new()
	edge.name = "CommandEdge"
	edge.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	edge.offset_right = 4.0
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(edge)

	caption_label = Label.new()
	caption_label.name = "Caption"
	caption_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption_label.offset_left = 26.0
	caption_label.offset_right = -42.0
	caption_label.text = caption
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_label.add_theme_font_size_override(&"font_size", caption_size)
	caption_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.72))
	caption_label.add_theme_constant_override(&"outline_size", 2)
	add_child(caption_label)

	chevron_label = Label.new()
	chevron_label.name = "DirectionMark"
	chevron_label.text = ">"
	chevron_label.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	chevron_label.offset_left = -42.0
	chevron_label.offset_right = -16.0
	chevron_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chevron_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron_label.add_theme_font_size_override(&"font_size", 11)
	chevron_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chevron_label)

	if not mouse_entered.is_connected(_refresh_visual_state):
		mouse_entered.connect(_refresh_visual_state)
		mouse_exited.connect(_refresh_visual_state)
		focus_entered.connect(_refresh_visual_state)
		focus_exited.connect(_refresh_visual_state)
		button_down.connect(_refresh_visual_state)
		button_up.connect(_refresh_visual_state)
		pressed.connect(_play_press_audio)
	_refresh_visual_state()
	_layout_caption()


func set_caption(text_value: String) -> void:
	caption = text_value
	if caption_label != null:
		caption_label.text = caption


func _layout_caption() -> void:
	if caption_label == null or chevron_label == null or size.x <= 1.0:
		return
	if _uses_compact_native_material():
		caption_label.offset_left = 12.0
		caption_label.offset_right = -12.0
		chevron_label.hide()
		return
	var authored := authored_accent != null and authored_accent.texture != null
	if not authored:
		caption_label.offset_left = 26.0
		caption_label.offset_right = -42.0
		chevron_label.show()
		return
	var safe_margin := 56.0
	if size.x < 150.0:
		safe_margin = 15.0
	elif size.x < 220.0:
		safe_margin = 34.0
	elif size.x < 300.0:
		safe_margin = 48.0
	caption_label.offset_left = safe_margin
	caption_label.offset_right = -safe_margin
	# Authored corner flourishes already provide direction and hierarchy. The
	# generic web chevron only crowds narrow controls.
	chevron_label.hide()


func _refresh_visual_state() -> void:
	if surface == null or caption_label == null:
		return
	var active := has_focus() or is_hovered()
	var pressed_now := is_pressed()
	var accent := _accent_color()
	var has_authored_frame := authored_accent != null and authored_accent.texture != null
	var fill := Color("#0a1517")
	var border := Color(PAPER, 0.12)
	if art_variant == ArtVariant.JADE:
		fill = Color("#09201d")
		border = Color(JADE, 0.26)
	elif art_variant == ArtVariant.GOLD:
		fill = Color("#20190e")
		border = Color(GOLD, 0.34)
	elif art_variant == ArtVariant.CRIMSON:
		fill = Color("#281211")
		border = Color(CRIMSON, 0.42)
	if active:
		fill = fill.lightened(0.075)
		border = Color(accent, 0.92)
	if pressed_now:
		fill = fill.darkened(0.10)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill, 0.08) if has_authored_frame else Color(fill, 0.94 if art_variant != ArtVariant.INK else 0.82)
	style.border_color = Color(border, 0.0) if has_authored_frame else border
	style.set_border_width_all(0 if has_authored_frame else 1)
	style.border_width_left = 0 if has_authored_frame else 4
	style.corner_radius_top_left = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 5 if active else 3
	style.shadow_offset = Vector2(0.0, 3.0)
	surface.add_theme_stylebox_override(&"panel", style)
	edge.visible = not has_authored_frame
	edge.color = accent
	var authored_caption_color := PAPER
	match art_variant:
		ArtVariant.GOLD:
			authored_caption_color = Color("#f2d28a")
		ArtVariant.JADE:
			authored_caption_color = Color("#bff4df")
		ArtVariant.CRIMSON:
			authored_caption_color = Color("#f0b8ad")
	caption_label.add_theme_color_override(&"font_color", authored_caption_color if not disabled else Color(PAPER_DIM, 0.52))
	caption_label.add_theme_color_override(&"font_outline_color", Color(PAPER, 0.30) if art_variant == ArtVariant.GOLD else Color(0.0, 0.0, 0.0, 0.72))
	caption_label.add_theme_constant_override(&"outline_size", 1 if art_variant == ArtVariant.GOLD else 2)
	chevron_label.add_theme_color_override(&"font_color", Color(accent, 0.92 if active else 0.52))
	var target_scale := Vector2(0.985, 0.985) if pressed_now else Vector2.ONE
	scale = target_scale
	pivot_offset = size * 0.5
	if authored_accent != null:
		authored_accent.modulate = _variant_texture_tint(1.0 if active else 0.93)
	if disabled:
		surface.modulate = Color(0.55, 0.55, 0.55, 0.58)
		chevron_label.text = "—"
	else:
		surface.modulate = Color.WHITE
		chevron_label.text = ">"
	if _uses_compact_native_material():
		chevron_label.hide()


func _uses_compact_native_material() -> bool:
	return caption in ["+", "−"] or custom_minimum_size.x <= 80.0


func _accent_color() -> Color:
	match art_variant:
		ArtVariant.JADE:
			return JADE
		ArtVariant.INK:
			return Color(PAPER_DIM, 0.74)
		ArtVariant.CRIMSON:
			return CRIMSON
		_:
			return GOLD


func _variant_texture_tint(alpha: float) -> Color:
	match art_variant:
		ArtVariant.GOLD:
			return Color(1.04, 0.99, 0.88, alpha)
		ArtVariant.JADE:
			return Color(0.88, 1.03, 0.98, alpha)
		ArtVariant.CRIMSON:
			return Color(1.02, 0.84, 0.82, alpha)
		_:
			return Color(0.94, 0.97, 0.98, alpha)


func _play_press_audio() -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui")
