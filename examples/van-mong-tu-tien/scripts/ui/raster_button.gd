class_name RasterButton
extends Button

## Compatibility-named V4 command control.
##
## Callers keep the established configure()/set_caption() API. V5 uses one
## complete fixed-aspect authored component per role inside the native Button;
## it never reconstructs a control from independently scaled caps or clasps.

enum ArtVariant { GOLD, JADE, INK, CRIMSON }

const RitualSurfaceScript := preload("res://scripts/ui/ritual_surface.gd")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")
const PAPER := Color("#e7ddc4")
const PAPER_DIM := Color("#c9b995")
const INK := Color("#0b171b")
const INK_RAISED := Color("#17292d")
const BRONZE := Color("#8a6730")
const GOLD := Color("#c69a48")
const JADE := Color("#55c9a6")
const CRIMSON := Color("#b43d35")
const BUTTON_GOLD: Texture2D = preload("res://assets/generated/ui/UIKIT-012-v5-command-tabs/runtime/button-primary-ink.png")
const BUTTON_PAPER: Texture2D = preload("res://assets/generated/ui/UIKIT-012-v5-command-tabs/runtime/button-secondary-paper.png")
const BUTTON_JADE: Texture2D = preload("res://assets/generated/ui/UIKIT-012-v5-command-tabs/runtime/button-confirm-jade.png")
const BUTTON_CRIMSON: Texture2D = preload("res://assets/generated/ui/UIKIT-012-v5-command-tabs/runtime/button-destructive-cinnabar.png")
const BUTTON_SEAL: Texture2D = preload("res://assets/generated/ui/UIKIT-012-v5-command-tabs/runtime/seal-action.png")

var art_variant := ArtVariant.GOLD
var caption := ""
var caption_size := 17
var control_role := "secondary"
var _configured := false
var _last_hovered := false
var _last_focused := false
var _last_pressed := false
var _last_disabled := false
var visual_inset := Vector2.ZERO

var surface: RitualSurface
var authored_layer: Control
var authored_texture: Texture2D
var authored_body: TextureRect
var caption_label: Label
var direction_mark: Label


func configure(
	text_value: String,
	variant: ArtVariant = ArtVariant.GOLD,
	minimum: Vector2 = Vector2(280.0, 64.0),
	font_size: int = 17
) -> RasterButton:
	caption = text_value
	art_variant = variant
	caption_size = clampi(font_size, 15, 22)
	# 64 logical pixels is the V4 shared touch target. Narrow stepper controls
	# retain the same square target instead of shrinking to their visible glyph.
	custom_minimum_size = Vector2(maxf(minimum.x, 64.0), maxf(minimum.y, 64.0))
	_build_visuals()
	return self


## Keeps the full accessible hit target while reducing only the visible chrome.
## This is used by the dedicated phone composition so 64 px targets do not read
## as a wall of oversized buttons on a 390 px-tall landscape screen.
func set_visual_inset(horizontal: float, vertical: float) -> RasterButton:
	visual_inset = Vector2(maxf(0.0, horizontal), maxf(0.0, vertical))
	_apply_visual_inset()
	_layout_caption()
	_layout_authored_parts()
	return self


func _ready() -> void:
	if not _configured:
		_build_visuals()
	_layout_caption()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_caption()
		_layout_authored_parts()
		if surface != null:
			surface.queue_redraw()


func _process(_delta: float) -> void:
	# BaseButton has no disabled-changed signal. Keep state drawing synchronized
	# when callers lock an action immediately after configure().
	if authored_layer != null and authored_layer.visible and authored_body != null and authored_body.size.x <= 1.0 and size.x > 1.0:
		_layout_authored_parts()
	if is_hovered() != _last_hovered or has_focus() != _last_focused or is_pressed() != _last_pressed or disabled != _last_disabled:
		_refresh_visual_state()


func _build_visuals() -> void:
	_configured = true
	text = ""
	flat = true
	set_process(true)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state_name, StyleBoxEmpty.new())

	for child in get_children():
		remove_child(child)
		child.queue_free()

	control_role = _resolve_control_role()
	surface = RitualSurfaceScript.new() as RitualSurface
	surface.name = "V4CommandSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_surface_material()
	add_child(surface)

	authored_layer = Control.new()
	authored_layer.name = "V4AuthoredButtonChrome"
	authored_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	authored_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(authored_layer)
	authored_body = _make_authored_part("CompleteAuthoredControl")
	_refresh_authored_texture()

	caption_label = Label.new()
	caption_label.name = "Caption"
	caption_label.text = caption
	caption_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.add_theme_font_override(&"font", ACTION_FONT)
	caption_label.add_theme_font_size_override(&"font_size", caption_size)
	caption_label.add_theme_color_override(&"font_color", _caption_color())
	caption_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.76))
	caption_label.add_theme_constant_override(&"outline_size", 1)
	caption_label.clip_text = true
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption_label)

	direction_mark = Label.new()
	direction_mark.name = "DirectionMark"
	# Keep the marker inside the bundled font's guaranteed Web glyph set.
	# Material/silhouette still communicates role; this is only a direction cue.
	direction_mark.text = ">"
	direction_mark.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	direction_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	direction_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	direction_mark.add_theme_font_override(&"font", ACTION_FONT)
	direction_mark.add_theme_font_size_override(&"font_size", 10)
	direction_mark.add_theme_color_override(&"font_color", Color(_accent_color(), 0.70))
	direction_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(direction_mark)

	if not mouse_entered.is_connected(_refresh_visual_state):
		mouse_entered.connect(_refresh_visual_state)
		mouse_exited.connect(_refresh_visual_state)
		focus_entered.connect(_refresh_visual_state)
		focus_exited.connect(_refresh_visual_state)
		button_down.connect(_refresh_visual_state)
		button_up.connect(_refresh_visual_state)
		pressed.connect(_play_press_audio)
	_refresh_visual_state()
	_apply_visual_inset()
	_layout_caption()
	call_deferred("_layout_authored_parts")


func set_caption(text_value: String) -> void:
	caption = text_value
	control_role = _resolve_control_role()
	_update_surface_material()
	_refresh_authored_texture()
	if caption_label != null:
		caption_label.text = caption
	if direction_mark != null:
		direction_mark.text = ">"
	_layout_caption()
	_refresh_visual_state()


func _layout_caption() -> void:
	if caption_label == null or direction_mark == null:
		return
	var compact := _uses_compact_material()
	var inset_left := 18.0 if compact else 28.0
	var inset_right := 18.0 if compact else 40.0
	if control_role == "back":
		inset_left = 28.0
		inset_right = 20.0
	elif control_role == "destructive":
		inset_left = 26.0
		inset_right = 34.0
	caption_label.offset_left = inset_left
	caption_label.offset_top = visual_inset.y
	caption_label.offset_right = -inset_right
	caption_label.offset_bottom = -visual_inset.y
	direction_mark.offset_left = -34.0
	direction_mark.offset_right = -12.0
	direction_mark.offset_top = visual_inset.y
	direction_mark.offset_bottom = -visual_inset.y
	# The complete V5 silhouettes already communicate direction and role. The
	# generic chevron read as a stray, misaligned glyph beside almost every phone
	# action, so captions now own the full protected field.
	direction_mark.visible = false
	if not compact and control_role != "destructive":
		caption_label.offset_right = -28.0
	_fit_caption_to_field()


func _fit_caption_to_field() -> void:
	if caption_label == null or size.x <= 1.0:
		return
	var available_width := maxf(24.0, size.x + caption_label.offset_right - caption_label.offset_left - 4.0)
	var fitted_size := caption_size
	var minimum_size := 14 if size.x < 148.0 else 15
	while fitted_size > minimum_size:
		var measured := ACTION_FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted_size).x
		if measured <= available_width:
			break
		fitted_size -= 1
	caption_label.add_theme_font_size_override(&"font_size", fitted_size)
	tooltip_text = caption if ACTION_FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted_size).x > available_width else ""


func _refresh_visual_state() -> void:
	if surface == null or caption_label == null:
		return
	var active := has_focus() or is_hovered()
	_last_hovered = is_hovered()
	_last_focused = has_focus()
	_last_pressed = is_pressed()
	_last_disabled = disabled
	surface.set_interaction_state(is_hovered(), has_focus(), is_pressed(), disabled)
	if authored_layer != null and authored_layer.visible:
		surface.visible = has_focus()
		surface.modulate = Color(1.0, 1.0, 1.0, 0.18)
		var authored_tint := Color.WHITE
		if disabled:
			authored_tint = Color(0.52, 0.55, 0.53, 0.48)
		elif is_pressed():
			authored_tint = Color(0.78, 0.86, 0.82, 0.96)
		elif has_focus() or is_hovered():
			authored_tint = Color(1.0, 1.0, 0.97, 1.0)
		authored_layer.modulate = authored_tint
		authored_layer.position.y = 2.0 if is_pressed() else 0.0
	else:
		surface.visible = true
		surface.modulate = Color.WHITE
	caption_label.position.y = 2.0 if is_pressed() else 0.0
	direction_mark.position.y = caption_label.position.y
	caption_label.add_theme_color_override(&"font_color", Color(_caption_color(), 0.44) if disabled else _caption_color())
	caption_label.add_theme_constant_override(&"outline_size", 2 if active and not _uses_paper_caption() else (0 if _uses_paper_caption() else 1))
	direction_mark.add_theme_color_override(&"font_color", Color(_accent_color(), 1.0 if active else 0.64))
	if disabled:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _resolve_control_role() -> String:
	if caption in ["+", "−"] or custom_minimum_size.x <= 80.0:
		return "stepper"
	var normalized := caption.to_upper()
	if normalized.contains("QUAY LẠI") or normalized.begins_with("VỀ ") or normalized.begins_with("TRỞ LẠI") or normalized.begins_with("TRỞ VỀ"):
		return "back"
	if art_variant == ArtVariant.CRIMSON:
		return "destructive"
	if art_variant == ArtVariant.GOLD:
		return "primary"
	return "secondary"


func _uses_compact_material() -> bool:
	return control_role == "stepper" or custom_minimum_size.x < 150.0


func _uses_paper_caption() -> bool:
	return control_role == "back"


func _surface_fill() -> Color:
	if control_role == "back":
		return Color("#d8c9a6")
	match art_variant:
		ArtVariant.GOLD:
			return Color("#111d1e")
		ArtVariant.JADE:
			return Color("#102824")
		ArtVariant.CRIMSON:
			return Color("#281515")
		_:
			return INK_RAISED


func _surface_edge() -> Color:
	match art_variant:
		ArtVariant.JADE:
			return Color(JADE, 0.72)
		ArtVariant.CRIMSON:
			return Color(CRIMSON, 0.84)
		_:
			return BRONZE


func _accent_color() -> Color:
	match art_variant:
		ArtVariant.JADE:
			return JADE
		ArtVariant.CRIMSON:
			return CRIMSON
		ArtVariant.INK:
			return PAPER_DIM
		_:
			return GOLD


func _caption_color() -> Color:
	return Color("#28251e") if _uses_paper_caption() else PAPER


func _update_surface_material() -> void:
	if surface == null:
		return
	surface.configure(
		RitualSurface.SurfaceKind.COMMAND,
		_surface_fill(),
		_surface_edge(),
		_accent_color(),
		10.0 if _uses_compact_material() else 14.0,
		art_variant == ArtVariant.GOLD or art_variant == ArtVariant.CRIMSON,
		false
	)


func _apply_visual_inset() -> void:
	for layer: Control in [surface, authored_layer]:
		if layer == null:
			continue
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.offset_left = visual_inset.x
		layer.offset_top = visual_inset.y
		layer.offset_right = -visual_inset.x
		layer.offset_bottom = -visual_inset.y


func _refresh_authored_texture() -> void:
	if authored_layer == null:
		return
	match control_role:
		"stepper": authored_texture = BUTTON_SEAL
		"back": authored_texture = BUTTON_PAPER
		"destructive": authored_texture = BUTTON_CRIMSON
		_:
			match art_variant:
				ArtVariant.JADE: authored_texture = BUTTON_JADE
				ArtVariant.CRIMSON: authored_texture = BUTTON_CRIMSON
				_: authored_texture = BUTTON_GOLD
	authored_layer.visible = authored_texture != null
	_layout_authored_parts()
	if surface != null:
		surface.visible = not authored_layer.visible


func _make_authored_part(part_name: String) -> TextureRect:
	var part := TextureRect.new()
	part.name = part_name
	part.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	part.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	part.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	authored_layer.add_child(part)
	return part


func _layout_authored_parts() -> void:
	if authored_layer == null or authored_texture == null or not authored_layer.visible:
		return
	var target_size := authored_layer.size.max(Vector2.ZERO)
	if target_size.x <= 1.0 or target_size.y <= 1.0:
		return
	authored_body.texture = authored_texture
	authored_body.position = Vector2.ZERO
	authored_body.size = target_size
	authored_body.visible = true


func _play_press_audio() -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui")
