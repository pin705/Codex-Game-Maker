class_name VanMongComponentKit
extends RefCounted

## Shared presentation primitives for the arsenal-style UI direction.
##
## The atlas is deliberately used as material/chrome only. Every label, stat,
## item name and input prompt remains runtime-rendered so localization and
## accessibility never depend on generated pixels.

const ATLAS_PATH := "res://assets/generated/ui/UIKIT-006-arsenal-plates/source/atlas-transparent.png"
const INK := Color("#0b1418")
const PAPER := Color("#e6dcc3")
const PAPER_DIM := Color("#b6ad98")
const GOLD := Color("#d4aa5b")
const JADE := Color("#69d2b1")
const VIOLET := Color("#9b82bd")
const CRIMSON := Color("#d56b5f")

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

static var _atlas: Texture2D

static func atlas_texture(region_name: String) -> AtlasTexture:
	if _atlas == null and ResourceLoader.exists(ATLAS_PATH):
		var loaded: Variant = load(ATLAS_PATH)
		if loaded is Texture2D:
			_atlas = loaded as Texture2D
	var texture := AtlasTexture.new()
	texture.atlas = _atlas
	texture.region = REGIONS.get(region_name, REGIONS["secondary"])
	return texture

static func chrome(parent: Control, region_name: String, rect: Rect2, tint: Color = Color.WHITE, fixed_ratio := false) -> TextureRect:
	var visual := TextureRect.new()
	visual.name = "ArsenalChrome_%s" % region_name
	visual.texture = atlas_texture(region_name)
	visual.position = rect.position
	visual.size = rect.size
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if fixed_ratio else TextureRect.STRETCH_SCALE
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.modulate = tint
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(visual)
	return visual

static func panel(parent: Control, rect: Rect2, region_name := "command", tint := Color.WHITE) -> TextureRect:
	return chrome(parent, region_name, rect, tint, false)

static func tab(parent: Control, caption: String, rect: Rect2, selected: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "ArsenalTab_%s" % caption.replace(" ", "_")
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var frame := chrome(button, "tabs", Rect2(Vector2.ZERO, rect.size), Color(0.92, 1.0, 0.96, 1.0) if selected else Color(0.62, 0.68, 0.66, 0.92), false)
	frame.name = "TabFrame"
	var label := Label.new()
	label.name = "TabCaption"
	label.text = caption
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", JADE if selected else PAPER)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.78))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void: frame.modulate = Color(1.08, 1.08, 1.0, 1.0))
	button.mouse_exited.connect(func() -> void: frame.modulate = Color(0.92, 1.0, 0.96, 1.0) if selected else Color(0.62, 0.68, 0.66, 0.92))
	parent.add_child(button)
	return button

static func item_slot(parent: Control, item_id: String, title: String, rarity: String, rect: Rect2, icon: Texture2D, selected: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "ItemSlot_%s" % item_id
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var region_name := "item_jade"
	match rarity:
		"Thiên": region_name = "item_crimson"
		"Địa": region_name = "item_violet"
		"Huyền": region_name = "item_gold"
	var frame := chrome(button, region_name, Rect2(Vector2.ZERO, rect.size), Color(1.08, 1.08, 1.0, 1.0) if selected else Color.WHITE, true)
	frame.name = "RarityFrame"
	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.name = "ItemIcon"
		icon_rect.texture = icon
		icon_rect.position = Vector2(rect.size.x * 0.18, rect.size.y * 0.14)
		icon_rect.size = Vector2(rect.size.x * 0.64, rect.size.y * 0.48)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon_rect)
	var rarity_label := Label.new()
	rarity_label.name = "Rarity"
	rarity_label.text = rarity.to_upper()
	rarity_label.position = Vector2(14.0, rect.size.y * 0.62)
	rarity_label.size = Vector2(rect.size.x - 28.0, 20.0)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", _rarity_color(rarity))
	rarity_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.82))
	rarity_label.add_theme_constant_override("outline_size", 2)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(rarity_label)
	var title_label := Label.new()
	title_label.name = "ItemTitle"
	title_label.text = title
	title_label.position = Vector2(12.0, rect.size.y * 0.72)
	title_label.size = Vector2(rect.size.x - 24.0, rect.size.y * 0.18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", PAPER)
	title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title_label)
	button.tooltip_text = "%s · %s" % [title, rarity]
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void: frame.modulate = Color(1.16, 1.16, 1.08, 1.0))
	button.mouse_exited.connect(func() -> void: frame.modulate = Color(1.08, 1.08, 1.0, 1.0) if selected else Color.WHITE)
	parent.add_child(button)
	return button

static func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Thiên": return CRIMSON
		"Địa": return VIOLET
		"Huyền": return GOLD
		"Linh": return JADE
	return PAPER_DIM
