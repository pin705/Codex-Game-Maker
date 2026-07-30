class_name VanMongComponentKit
extends RefCounted

## Shared V4 component factory.
##
## The public helpers retain their established arguments. Atlas access remains
## available for isolated legacy art, but interactive panels, tabs and item
## slots now use scalable native RitualSurface geometry by default.

const RitualSurfaceScript := preload("res://scripts/ui/ritual_surface.gd")
const ATLAS_PATH := "res://assets/generated/ui/UIKIT-006-arsenal-plates/runtime/atlas-transparent.png"
const RITUAL_ATLAS_PATH := "res://assets/generated/ui/UIKIT-007-ritual-surface-atlas/runtime/atlas-transparent.png"
const INK := Color("#0b171b")
const INK_RAISED := Color("#17292d")
const INK_LINE := Color("#314248")
const PAPER := Color("#e7ddc4")
const PAPER_MUTED := Color("#c9b995")
const PAPER_INK := Color("#292820")
const BRONZE := Color("#8a6730")
const GOLD := Color("#c69a48")
const GOLD_BRIGHT := Color("#f0d184")
const JADE := Color("#55c9a6")
const VIOLET := Color("#675078")
const CRIMSON := Color("#b43d35")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")

# Compatibility-only atlas coordinates. They are intentionally not used by the
# default component factories below.
const REGIONS := {
	"command": Rect2(34.0, 34.0, 650.0, 194.0),
	"secondary": Rect2(712.0, 58.0, 270.0, 132.0),
	"medallion": Rect2(1010.0, 42.0, 210.0, 190.0),
	"skill_ring": Rect2(34.0, 262.0, 278.0, 258.0),
	"item_jade": Rect2(352.0, 266.0, 244.0, 260.0),
	"item_gold": Rect2(644.0, 266.0, 244.0, 260.0),
	"item_violet": Rect2(936.0, 266.0, 244.0, 260.0),
	"item_crimson": Rect2(34.0, 558.0, 260.0, 268.0),
	"folio": Rect2(350.0, 570.0, 260.0, 356.0),
	"compare": Rect2(642.0, 570.0, 344.0, 276.0),
	"tooltip": Rect2(982.0, 570.0, 250.0, 356.0),
	"tabs": Rect2(30.0, 964.0, 414.0, 92.0),
	"meter": Rect2(34.0, 1070.0, 392.0, 114.0),
	"cooldown": Rect2(462.0, 1064.0, 132.0, 150.0),
	"lock": Rect2(616.0, 1068.0, 136.0, 136.0),
	"focus": Rect2(760.0, 1070.0, 150.0, 136.0),
	"inventory": Rect2(930.0, 950.0, 324.0, 304.0),
}

const RITUAL_REGIONS := {
	"title_scroll": Rect2(20.0, 24.0, 380.0, 684.0),
	"wide_header": Rect2(456.0, 68.0, 596.0, 164.0),
	"status_plaque": Rect2(1092.0, 48.0, 404.0, 168.0),
	"boss_bar": Rect2(424.0, 252.0, 1088.0, 256.0),
	"skill_rail": Rect2(444.0, 500.0, 836.0, 172.0),
	"touch_attack": Rect2(1280.0, 548.0, 232.0, 224.0),
	"touch_skill": Rect2(1312.0, 788.0, 168.0, 160.0),
	"modal_guard": Rect2(60.0, 716.0, 472.0, 268.0),
	"result_plate": Rect2(560.0, 716.0, 708.0, 256.0),
}

static var _atlas: Texture2D
static var _ritual_atlas: Texture2D


static func atlas_texture(region_name: String) -> AtlasTexture:
	if _atlas == null and ResourceLoader.exists(ATLAS_PATH):
		var loaded: Variant = load(ATLAS_PATH)
		if loaded is Texture2D:
			_atlas = loaded as Texture2D
	var texture := AtlasTexture.new()
	texture.atlas = _atlas
	texture.region = REGIONS.get(region_name, REGIONS["secondary"])
	return texture


static func ritual_texture(region_name: String) -> AtlasTexture:
	if _ritual_atlas == null and ResourceLoader.exists(RITUAL_ATLAS_PATH):
		var loaded: Variant = load(RITUAL_ATLAS_PATH)
		if loaded is Texture2D:
			_ritual_atlas = loaded as Texture2D
	var texture := AtlasTexture.new()
	texture.atlas = _ritual_atlas
	texture.region = RITUAL_REGIONS.get(region_name, RITUAL_REGIONS["modal_guard"])
	return texture


# Short aliases retained for older prototyping scripts.
static func atlas(region_name: String) -> AtlasTexture:
	return atlas_texture(region_name)


static func ritual(region_name: String) -> AtlasTexture:
	return ritual_texture(region_name)


static func chrome(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE, fixed_ratio := false) -> TextureRect:
	var visual := TextureRect.new()
	visual.name = "LegacyAtlas_%s" % region_name
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.texture = atlas_texture(region_name)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.modulate = tint
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(visual)
	visual.position = rect.position
	visual.size = rect.size
	return visual


static func ritual_chrome(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE) -> TextureRect:
	var visual := TextureRect.new()
	visual.name = "LegacyRitualAtlas_%s" % region_name
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.texture = ritual_texture(region_name)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.modulate = tint
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(visual)
	visual.position = rect.position
	visual.size = rect.size
	return visual


static func nine_patch(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE) -> NinePatchRect:
	var surface := _native_surface(parent, region_name, rect, tint)
	surface.name = "V4Surface_%s" % region_name
	return surface


static func ritual_nine_patch(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE) -> NinePatchRect:
	var mapped_region := region_name
	match region_name:
		"modal_guard", "result_plate": mapped_region = "tooltip"
		"wide_header", "boss_bar", "skill_rail": mapped_region = "command"
	return nine_patch(parent, mapped_region, rect, tint)


static func panel(parent: Control, rect: Rect2, region_name := "command", tint := Color.WHITE) -> Control:
	return _native_surface(parent, region_name, rect, tint)


static func tab(parent: Control, caption: String, rect: Rect2, selected: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "V4Tab_%s" % caption.replace(" ", "_")
	_prepare_button(button, rect, caption)
	var frame := _native_surface(button, "tabs", Rect2(Vector2.ZERO, rect.size), Color.WHITE, selected)
	frame.name = "TabSurface"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var label := Label.new()
	label.name = "TabCaption"
	label.text = caption
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 18.0
	label.offset_right = -18.0
	label.offset_top = 3.0
	label.offset_bottom = -4.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", ACTION_FONT)
	label.add_theme_font_size_override(&"font_size", _fitted_font_size(label.text, rect.size.x - 40.0, 16, 14))
	label.add_theme_color_override(&"font_color", JADE if selected else PAPER)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)

	_bind_button_surface(button, frame)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


static func item_slot(
	parent: Control,
	item_id: String,
	title: String,
	rarity: String,
	rect: Rect2,
	icon: Texture2D,
	selected: bool,
	callback: Callable,
	text_scale := 1.0,
	show_title := true
) -> Button:
	var button := Button.new()
	button.name = "ItemSlot_%s" % item_id
	_prepare_button(button, rect, "%s · %s" % [title, rarity])
	var rarity_color := _rarity_color(rarity)
	var frame := RitualSurfaceScript.new() as RitualSurface
	frame.name = "ItemSurface"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.configure(
		RitualSurface.SurfaceKind.ITEM_SLOT,
		Color(INK_RAISED, 0.96),
		Color(rarity_color, 0.62),
		rarity_color,
		9.0,
		selected,
		selected
	)
	button.add_child(frame)

	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.name = "ItemIcon"
		icon_rect.z_index = 2
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = icon
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon_rect)
		icon_rect.position = Vector2(rect.size.x * 0.10, rect.size.y * 0.07)
		icon_rect.size = Vector2(rect.size.x * 0.80, rect.size.y * (0.57 if show_title else 0.68))

	var rarity_label := Label.new()
	rarity_label.name = "Rarity"
	rarity_label.z_index = 3
	rarity_label.text = rarity.to_upper()
	rarity_label.position = Vector2(12.0, rect.size.y * (0.77 if not show_title else 0.61))
	rarity_label.size = Vector2(rect.size.x - 24.0, 22.0)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_override(&"font", ACTION_FONT)
	rarity_label.add_theme_font_size_override(&"font_size", maxi(12, int(round(12.0 * text_scale))))
	rarity_label.add_theme_color_override(&"font_color", rarity_color)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(rarity_label)

	if show_title:
		var title_label := Label.new()
		title_label.name = "ItemTitle"
		title_label.z_index = 3
		title_label.text = title
		title_label.position = Vector2(12.0, rect.size.y * 0.73)
		title_label.size = Vector2(rect.size.x - 24.0, rect.size.y * 0.20)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.add_theme_font_override(&"font", ACTION_FONT)
		title_label.add_theme_font_size_override(&"font_size", maxi(14, int(round(14.0 * text_scale))))
		title_label.add_theme_color_override(&"font_color", PAPER)
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(title_label)

	_bind_button_surface(button, frame)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


static func _native_surface(
	parent: Control,
	region_name: String,
	rect: Rect2,
	tint: Color,
	selected := false
) -> RitualSurface:
	var surface := RitualSurfaceScript.new() as RitualSurface
	var kind := RitualSurface.SurfaceKind.PLATE
	var fill := Color(INK, lerpf(0.80, 0.97, tint.a))
	var edge := BRONZE
	var accent := GOLD
	var cut := 12.0
	var is_strong := false
	match region_name:
		"command":
			kind = RitualSurface.SurfaceKind.COMMAND
			fill = Color(INK_RAISED, lerpf(0.78, 0.97, tint.a))
			cut = 14.0
			is_strong = true
		"secondary":
			kind = RitualSurface.SurfaceKind.PLATE
			fill = Color(INK_RAISED, lerpf(0.76, 0.94, tint.a))
		"tooltip", "compare":
			kind = RitualSurface.SurfaceKind.TOOLTIP
			fill = Color(INK, lerpf(0.88, 0.98, tint.a))
			cut = 15.0
			is_strong = true
		"inventory", "folio":
			kind = RitualSurface.SurfaceKind.FOLIO
			fill = Color(PAPER, lerpf(0.88, 0.98, tint.a))
			edge = BRONZE
			accent = GOLD
			cut = 16.0
			is_strong = true
		"tabs":
			kind = RitualSurface.SurfaceKind.TAB
			fill = Color(INK_RAISED, 0.97)
			edge = Color(BRONZE, 0.80)
			accent = JADE
			cut = 10.0
		"meter":
			kind = RitualSurface.SurfaceKind.METER
			fill = Color(INK, 0.94)
			accent = JADE
		"cooldown", "medallion", "skill_ring", "lock", "focus":
			kind = RitualSurface.SurfaceKind.CIRCLE
			fill = Color(INK_RAISED, 0.97)
			edge = Color(BRONZE, 0.86)
			accent = JADE
			is_strong = selected
		"item_jade", "item_gold", "item_violet", "item_crimson":
			kind = RitualSurface.SurfaceKind.ITEM_SLOT
			fill = Color(INK_RAISED, 0.96)
			accent = _region_accent(region_name)
			edge = Color(accent, 0.62)
			cut = 9.0
			is_strong = selected
	# Preserve caller opacity intent without allowing color tints to fragment the
	# locked palette. Hue belongs to state roles, not arbitrary panel instances.
	var minimum_alpha := 0.84 if kind == RitualSurface.SurfaceKind.FOLIO or kind == RitualSurface.SurfaceKind.PAPER else 0.72
	fill.a = maxf(minimum_alpha, fill.a * clampf(tint.a, 0.45, 1.0))
	surface.configure(kind, fill, edge, accent, cut, is_strong, selected)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(surface)
	surface.position = rect.position
	surface.size = rect.size
	return surface


static func _prepare_button(button: Button, rect: Rect2, accessible_caption: String) -> void:
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = Vector2(maxf(64.0, rect.size.x), maxf(64.0, rect.size.y))
	button.clip_contents = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = accessible_caption
	for state_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())


static func _bind_button_surface(button: Button, surface: RitualSurface) -> void:
	var sync := func() -> void:
		surface.set_interaction_state(button.is_hovered(), button.has_focus(), button.is_pressed(), button.disabled)
	button.mouse_entered.connect(sync)
	button.mouse_exited.connect(sync)
	button.focus_entered.connect(sync)
	button.focus_exited.connect(sync)
	button.button_down.connect(sync)
	button.button_up.connect(sync)
	sync.call()


static func _fitted_font_size(value: String, available_width: float, preferred: int, minimum: int) -> int:
	var result := preferred
	while result > minimum and ACTION_FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, result).x > available_width:
		result -= 1
	return result


static func _region_accent(region_name: String) -> Color:
	match region_name:
		"item_crimson": return CRIMSON
		"item_violet": return VIOLET
		"item_gold": return GOLD
	return JADE


static func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Thiên": return CRIMSON
		"Địa": return Color("#9a78a9")
		"Huyền": return GOLD
		"Linh": return JADE
	return PAPER_MUTED
