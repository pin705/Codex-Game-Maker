class_name VanMongComponentKit
extends RefCounted

## Shared presentation primitives for the arsenal-style UI direction.
##
## The atlas is deliberately used as material/chrome only. Every label, stat,
## item name and input prompt remains runtime-rendered so localization and
## accessibility never depend on generated pixels.

const ATLAS_PATH := "res://assets/generated/ui/UIKIT-006-arsenal-plates/runtime/atlas-transparent.png"
const RITUAL_ATLAS_PATH := "res://assets/generated/ui/UIKIT-007-ritual-surface-atlas/runtime/atlas-transparent.png"
const INK := Color("#0b1418")
const PAPER := Color("#e6dcc3")
const PAPER_DIM := Color("#b6ad98")
const GOLD := Color("#d4aa5b")
const JADE := Color("#69d2b1")
const VIOLET := Color("#9b82bd")
const CRIMSON := Color("#d56b5f")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")

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

# Only dedicated quiet-center components are scalable. Fixed-shape medallions,
# item frames and folios must remain aspect fitted.
const NINE_SLICE_MARGINS := {
	"command": Vector4(82.0, 28.0, 82.0, 28.0),
	"secondary": Vector4(44.0, 24.0, 44.0, 24.0),
	"tooltip": Vector4(46.0, 46.0, 46.0, 46.0),
	"compare": Vector4(52.0, 44.0, 52.0, 44.0),
	"inventory": Vector4(48.0, 48.0, 48.0, 48.0),
	"tabs": Vector4(56.0, 20.0, 56.0, 20.0),
	"meter": Vector4(60.0, 24.0, 60.0, 24.0),
}

const RITUAL_NINE_SLICE_MARGINS := {
	"wide_header": Vector4(76.0, 38.0, 76.0, 38.0),
	"modal_guard": Vector4(66.0, 52.0, 66.0, 52.0),
	"result_plate": Vector4(86.0, 52.0, 86.0, 52.0),
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

static func chrome(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE, fixed_ratio := false) -> TextureRect:
	var visual := TextureRect.new()
	visual.name = "ArsenalChrome_%s" % region_name
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Atlas regions are authored silhouettes. Never non-uniformly scale them.
	# Scalable quiet-center surfaces use nine_patch() below.
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.texture = atlas_texture(region_name)
	visual.custom_minimum_size = Vector2.ZERO
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.modulate = tint
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(visual)
	# Set the authored rect after parenting so the atlas region's native source
	# size cannot expand and clip a compact slot/tab/rail.
	visual.position = rect.position
	visual.size = rect.size
	return visual


static func nine_patch(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE) -> NinePatchRect:
	var visual := NinePatchRect.new()
	visual.name = "ArsenalNinePatch_%s" % region_name
	visual.texture = atlas_texture(region_name)
	visual.position = rect.position
	visual.size = rect.size
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.modulate = tint
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.draw_center = true
	var margins: Vector4 = NINE_SLICE_MARGINS.get(region_name, Vector4(36.0, 36.0, 36.0, 36.0))
	visual.set_patch_margin(SIDE_LEFT, int(margins.x))
	visual.set_patch_margin(SIDE_TOP, int(margins.y))
	visual.set_patch_margin(SIDE_RIGHT, int(margins.z))
	visual.set_patch_margin(SIDE_BOTTOM, int(margins.w))
	parent.add_child(visual)
	return visual


static func ritual_chrome(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE) -> TextureRect:
	var visual := TextureRect.new()
	visual.name = "RitualChrome_%s" % region_name
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.texture = ritual_texture(region_name)
	visual.custom_minimum_size = Vector2.ZERO
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.modulate = tint
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(visual)
	visual.position = rect.position
	visual.size = rect.size
	return visual


static func ritual_nine_patch(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE) -> NinePatchRect:
	var visual := NinePatchRect.new()
	visual.name = "RitualNinePatch_%s" % region_name
	visual.texture = ritual_texture(region_name)
	visual.position = rect.position
	visual.size = rect.size
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.modulate = tint
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.draw_center = true
	var margins: Vector4 = RITUAL_NINE_SLICE_MARGINS.get(region_name, Vector4(56.0, 44.0, 56.0, 44.0))
	visual.set_patch_margin(SIDE_LEFT, int(margins.x))
	visual.set_patch_margin(SIDE_TOP, int(margins.y))
	visual.set_patch_margin(SIDE_RIGHT, int(margins.z))
	visual.set_patch_margin(SIDE_BOTTOM, int(margins.w))
	parent.add_child(visual)
	return visual


static func panel(parent: Control, rect: Rect2, region_name := "command", tint := Color.WHITE) -> Control:
	if NINE_SLICE_MARGINS.has(region_name):
		return nine_patch(parent, region_name, rect, tint)
	return chrome(parent, region_name, rect, tint, true)

static func tab(parent: Control, caption: String, rect: Rect2, selected: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "ArsenalTab_%s" % caption.replace(" ", "_")
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.clip_contents = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var frame := nine_patch(button, "tabs", Rect2(Vector2.ZERO, rect.size), Color(0.92, 1.0, 0.96, 1.0) if selected else Color(0.62, 0.68, 0.66, 0.92))
	frame.name = "TabFrame"
	var label := Label.new()
	label.name = "TabCaption"
	label.text = caption
	button.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The atlas tab has dense knots at both ends.  Keep localized text in the
	# measured quiet centre instead of centring across the complete ornament.
	var horizontal_inset := clampf(rect.size.x * 0.17, 18.0, 34.0)
	label.offset_left = horizontal_inset
	label.offset_right = -horizontal_inset
	label.offset_top = 4.0
	label.offset_bottom = -5.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ACTION_FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", JADE if selected else PAPER)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void: frame.modulate = Color(1.08, 1.08, 1.0, 1.0))
	button.mouse_exited.connect(func() -> void: frame.modulate = Color(0.92, 1.0, 0.96, 1.0) if selected else Color(0.62, 0.68, 0.66, 0.92))
	parent.add_child(button)
	return button

static func item_slot(parent: Control, item_id: String, title: String, rarity: String, rect: Rect2, icon: Texture2D, selected: bool, callback: Callable, text_scale := 1.0, show_title := true) -> Button:
	var button := Button.new()
	button.name = "ItemSlot_%s" % item_id
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.clip_contents = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var region_name := "item_jade"
	match rarity:
		"Thiên": region_name = "item_crimson"
		"Địa": region_name = "item_violet"
		"Huyền": region_name = "item_gold"
	var idle_frame_tint := Color(0.88, 0.92, 0.90, 0.74)
	var selected_frame_tint := Color(1.08, 1.08, 1.0, 0.96)
	var frame := chrome(button, region_name, Rect2(Vector2.ZERO, rect.size), selected_frame_tint if selected else idle_frame_tint, true)
	frame.name = "RarityFrame"
	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.name = "ItemIcon"
		icon_rect.z_index = 2
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2.ZERO
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon_rect)
		# Apply the protected field after parenting. This prevents TextureRect's
		# source-size minimum from expanding a 362/512 px icon inside a 132 px slot.
		icon_rect.position = Vector2(rect.size.x * 0.08, rect.size.y * 0.03)
		icon_rect.size = Vector2(rect.size.x * 0.84, rect.size.y * 0.66)
	var rarity_label := Label.new()
	rarity_label.name = "Rarity"
	rarity_label.z_index = 3
	rarity_label.text = rarity.to_upper()
	rarity_label.position = Vector2(14.0, rect.size.y * (0.78 if not show_title else 0.62))
	rarity_label.size = Vector2(rect.size.x - 28.0, 20.0)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", maxi(11, int(round(11.0 * text_scale))))
	rarity_label.add_theme_color_override("font_color", _rarity_color(rarity))
	rarity_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.82))
	rarity_label.add_theme_constant_override("outline_size", 2)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(rarity_label)
	if show_title:
		var title_label := Label.new()
		title_label.name = "ItemTitle"
		title_label.z_index = 3
		title_label.text = title
		title_label.position = Vector2(12.0, rect.size.y * 0.72)
		title_label.size = Vector2(rect.size.x - 24.0, rect.size.y * 0.18)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.add_theme_font_size_override("font_size", maxi(13, int(round(13.0 * text_scale))))
		title_label.add_theme_color_override("font_color", PAPER)
		title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
		title_label.add_theme_constant_override("outline_size", 2)
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(title_label)
	button.tooltip_text = "%s · %s" % [title, rarity]
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void: frame.modulate = Color(1.16, 1.16, 1.08, 1.0))
	button.mouse_exited.connect(func() -> void: frame.modulate = selected_frame_tint if selected else idle_frame_tint)
	parent.add_child(button)
	return button

static func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Thiên": return CRIMSON
		"Địa": return VIOLET
		"Huyền": return GOLD
		"Linh": return JADE
	return PAPER_DIM
