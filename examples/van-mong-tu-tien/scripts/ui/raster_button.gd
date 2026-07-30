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
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")
const CONTROL_ROOT := "res://assets/generated/ui/UIKIT-008-control-silhouettes/runtime/"
const CONTROL_PATHS := {
	"primary": CONTROL_ROOT + "primary.png",
	"secondary": CONTROL_ROOT + "secondary.png",
	"back": CONTROL_ROOT + "back.png",
	"stepper": CONTROL_ROOT + "stepper.png",
	"destructive": CONTROL_ROOT + "destructive.png",
	"confirm": CONTROL_ROOT + "confirm.png",
}

var art_variant := ArtVariant.GOLD
var caption := ""
var caption_size := 17
var _configured := false
var control_role := "secondary"

var surface: Panel
var authored_accent: NinePatchRect
var fixed_accent: TextureRect
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

	control_role = _resolve_control_role()
	authored_accent = NinePatchRect.new()
	authored_accent.name = "AuthoredCommandFrame"
	authored_accent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var compact_frame := _uses_stepper_material()
	var quiet_compact := _uses_quiet_compact_material()
	var margins := _patch_margins(control_role)
	var horizontal_margin := int(margins.x)
	var vertical_margin := int(margins.y)
	authored_accent.set_patch_margin(SIDE_LEFT, horizontal_margin)
	authored_accent.set_patch_margin(SIDE_TOP, vertical_margin)
	authored_accent.set_patch_margin(SIDE_RIGHT, int(margins.z))
	authored_accent.set_patch_margin(SIDE_BOTTOM, int(margins.w))
	authored_accent.draw_center = true
	authored_accent.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var control_path := str(CONTROL_PATHS.get(control_role, ""))
	if not compact_frame and not quiet_compact and ResourceLoader.exists(control_path):
		var loaded: Variant = load(control_path)
		if loaded is Texture2D:
			authored_accent.texture = loaded as Texture2D
		authored_accent.modulate = _variant_texture_tint(0.96)
		if authored_accent.texture != null:
			surface.add_child(authored_accent)
	elif compact_frame and ResourceLoader.exists(control_path):
		var compact_loaded: Variant = load(control_path)
		if compact_loaded is Texture2D:
			fixed_accent = TextureRect.new()
			fixed_accent.name = "AuthoredStepperFrame"
			fixed_accent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			fixed_accent.texture = compact_loaded as Texture2D
			fixed_accent.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fixed_accent.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			fixed_accent.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			fixed_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fixed_accent.modulate = _variant_texture_tint(0.96)
			surface.add_child(fixed_accent)

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
	caption_label.add_theme_font_override(&"font", ACTION_FONT)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_label.add_theme_font_size_override(&"font_size", caption_size)
	caption_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.72))
	caption_label.add_theme_constant_override(&"outline_size", 2)
	caption_label.clip_text = true
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
		_fit_caption_to_field()
		return
	var authored := authored_accent != null and authored_accent.texture != null
	if not authored:
		caption_label.offset_left = 26.0
		caption_label.offset_right = -42.0
		chevron_label.show()
		_fit_caption_to_field()
		return
	# Each silhouette has a measured quiet center. Keep the live caption inside
	# that center instead of letting a seal/tassel decide the visual baseline.
	match control_role:
		"primary":
			caption_label.offset_left = 48.0
			caption_label.offset_right = -70.0
		"back":
			caption_label.offset_left = 42.0 if size.x < 150.0 else 50.0
			caption_label.offset_right = -20.0 if size.x < 150.0 else -24.0
		"destructive":
			caption_label.offset_left = 34.0
			caption_label.offset_right = -86.0
		_:
			caption_label.offset_left = 30.0
			caption_label.offset_right = -36.0
	# Authored corner flourishes already provide direction and hierarchy. The
	# generic web chevron only crowds narrow controls.
	chevron_label.hide()
	_fit_caption_to_field()


func _fit_caption_to_field() -> void:
	if caption_label == null or size.x <= 1.0:
		return
	var available_width := maxf(24.0, size.x + caption_label.offset_right - caption_label.offset_left - 4.0)
	var measured := ACTION_FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, caption_size).x
	var fitted_size := caption_size
	if measured > available_width and measured > 0.0:
		fitted_size = maxi(13, int(floor(float(caption_size) * available_width / measured)))
	caption_label.add_theme_font_size_override(&"font_size", fitted_size)


func _refresh_visual_state() -> void:
	if surface == null or caption_label == null:
		return
	var active := has_focus() or is_hovered()
	var pressed_now := is_pressed()
	var accent := _accent_color()
	var has_authored_frame := (authored_accent != null and authored_accent.texture != null) or (fixed_accent != null and fixed_accent.texture != null)
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
	var quiet_compact := _uses_quiet_compact_material()
	style.bg_color = Color(fill, 0.0) if has_authored_frame else Color(fill, 0.96 if quiet_compact else (0.94 if art_variant != ArtVariant.INK else 0.82))
	style.border_color = Color(border, 0.0) if has_authored_frame else border
	style.set_border_width_all(0 if has_authored_frame else (2 if quiet_compact else 1))
	style.border_width_left = 0 if has_authored_frame else (3 if quiet_compact else 4)
	style.corner_radius_top_left = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 0 if has_authored_frame else (5 if active else 3)
	style.shadow_offset = Vector2(0.0, 3.0)
	surface.add_theme_stylebox_override(&"panel", style)
	edge.visible = not has_authored_frame
	edge.color = accent
	var paper_control := has_authored_frame and control_role != "destructive"
	var authored_caption_color := Color("#332b20") if paper_control else PAPER
	if control_role == "destructive":
		authored_caption_color = Color("#f0d8c5")
	caption_label.add_theme_color_override(&"font_color", authored_caption_color if not disabled else Color(PAPER_DIM, 0.52))
	# Paper controls already have a dark ink field. A pale outline made live
	# Vietnamese captions look fuzzy and cheap at phone scale, so use a clean
	# ink baseline and reserve outlines for dark lacquer/destructive controls.
	caption_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.80) if not paper_control else Color.TRANSPARENT)
	caption_label.add_theme_constant_override(&"outline_size", 2 if not paper_control else 0)
	chevron_label.add_theme_color_override(&"font_color", Color(accent, 0.92 if active else 0.52))
	var target_scale := Vector2(0.985, 0.985) if pressed_now else Vector2.ONE
	scale = target_scale
	pivot_offset = size * 0.5
	if authored_accent != null:
		authored_accent.modulate = _variant_texture_tint(1.0 if active else 0.93)
	if fixed_accent != null:
		fixed_accent.modulate = _variant_texture_tint(1.0 if active else 0.93)
	if disabled:
		surface.modulate = Color(0.55, 0.55, 0.55, 0.58)
		chevron_label.text = "—"
	else:
		surface.modulate = Color.WHITE
		chevron_label.text = ">"
	if _uses_compact_native_material():
		chevron_label.hide()


func _uses_compact_native_material() -> bool:
	return _uses_stepper_material() or _uses_quiet_compact_material()


func _uses_stepper_material() -> bool:
	return caption in ["+", "−"] or custom_minimum_size.x <= 80.0


func _uses_quiet_compact_material() -> bool:
	# Below this width the authored paper silhouettes lose their protected text
	# field. Use a crisp lacquer/jade control instead of crushing seals and folds.
	var normalized := caption.to_upper()
	var authored_back := normalized.contains("QUAY LẠI") or normalized.begins_with("VỀ ") or normalized.begins_with("TRỞ LẠI")
	return not _uses_stepper_material() and not authored_back and custom_minimum_size.x < 164.0


func _resolve_control_role() -> String:
	if _uses_stepper_material():
		return "stepper"
	# The long primary and wax-seal destructive crops are only safe inside their
	# recorded test ranges. Narrower buttons use the cleaner folded-paper crop so
	# hardware never crushes the live caption or hangs off the control.
	if art_variant == ArtVariant.CRIMSON and custom_minimum_size.x >= 250.0:
		return "destructive"
	var normalized := caption.to_upper()
	if normalized.contains("QUAY LẠI") or normalized.begins_with("VỀ ") or normalized.begins_with("TRỞ LẠI"):
		return "back"
	if art_variant == ArtVariant.GOLD and custom_minimum_size.x >= 286.0:
		return "primary"
	return "secondary"


func _patch_margins(role: String) -> Vector4:
	match role:
		"primary":
			return Vector4(70.0, 22.0, 84.0, 22.0)
		"back":
			return Vector4(58.0, 22.0, 26.0, 22.0)
		"destructive":
			return Vector4(48.0, 24.0, 130.0, 24.0)
	return Vector4(38.0, 22.0, 54.0, 22.0)


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
