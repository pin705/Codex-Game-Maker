class_name CultivationPanel
extends PanelContainer

## V3 material frame used by the combat HUD and its ritual overlays.
##
## The frame is intentionally presentation-only. All labels, values, buttons,
## focus and cooldown state remain ordinary runtime Controls owned by the caller.
## UIKIT-007 supplies the physical paper/lacquer/bronze response; the quiet
## centre is the only part allowed to stretch.

enum FrameKind {
	HUD,
	SCROLL,
	PAPER,
	BANNER,
	SEAL,
}

const RITUAL_ATLAS: Texture2D = preload("res://assets/generated/ui/UIKIT-007-ritual-surface-atlas/runtime/atlas-transparent.png")

const RITUAL_REGIONS := {
	"wide_header": Rect2(456.0, 68.0, 596.0, 164.0),
	"status_plaque": Rect2(1092.0, 48.0, 404.0, 168.0),
	"touch_skill": Rect2(1312.0, 788.0, 168.0, 160.0),
	"modal_guard": Rect2(60.0, 716.0, 472.0, 268.0),
	"result_plate": Rect2(560.0, 716.0, 708.0, 256.0),
}

const PATCH_MARGINS := {
	"wide_header": Vector4(76.0, 38.0, 76.0, 38.0),
	"modal_guard": Vector4(66.0, 52.0, 66.0, 52.0),
	"result_plate": Vector4(86.0, 52.0, 86.0, 52.0),
}

var frame_kind: FrameKind = FrameKind.HUD
var fill_color := Color("#0a1718")
var accent_color := Color("#b89043")
var paper_color := Color("#d8cba4")
var ornament_seed := 1

var material_root: Control
var authored_chrome: NinePatchRect
var authored_emblem: TextureRect
var lacquer_veil: ColorRect
var _active_region := ""


func _init() -> void:
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

	# Keep authored material in one non-layout root so its source dimensions can
	# never force a minimum size on compact HUD containers.
	material_root = Control.new()
	material_root.name = "V3MaterialRoot"
	material_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	material_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(material_root)

	authored_chrome = NinePatchRect.new()
	authored_chrome.name = "RitualNinePatch"
	authored_chrome.set_anchors_preset(Control.PRESET_TOP_LEFT)
	authored_chrome.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	authored_chrome.draw_center = true
	authored_chrome.custom_minimum_size = Vector2.ZERO
	material_root.add_child(authored_chrome)

	# HUD and banner text is light. A contained lacquer wash converts only the
	# protected paper field to a readable dark material while leaving the bronze
	# silhouette and jade hardware visible at full value.
	lacquer_veil = ColorRect.new()
	lacquer_veil.name = "LacquerContentField"
	lacquer_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_root.add_child(lacquer_veil)

	# Fixed medallions are never nine-sliced. This layer is used only by SEAL.
	authored_emblem = TextureRect.new()
	authored_emblem.name = "RitualSeal"
	authored_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	authored_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	authored_emblem.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	authored_emblem.custom_minimum_size = Vector2.ZERO
	material_root.add_child(authored_emblem)


func configure(kind: FrameKind, fill: Color, accent: Color, seed: int = 1) -> CultivationPanel:
	frame_kind = kind
	fill_color = fill
	accent_color = accent
	ornament_seed = seed
	_active_region = ""
	_layout_material()
	return self


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		_layout_material()


func _layout_material() -> void:
	if material_root == null or authored_chrome == null:
		return
	if size.x < 8.0 or size.y < 8.0:
		material_root.hide()
		return
	material_root.show()

	if frame_kind == FrameKind.SEAL:
		_layout_seal()
		return

	authored_emblem.hide()
	authored_chrome.show()
	var region_name := _region_for_current_shape()
	if _active_region != region_name:
		_active_region = region_name
		var atlas_region: Rect2 = RITUAL_REGIONS[region_name]
		authored_chrome.texture = _atlas_region(atlas_region)
	var authored_margins: Vector4 = PATCH_MARGINS[region_name]
	_apply_patch_margins(authored_margins)
	# PanelContainer notifications can propagate a full-rect anchor preset while
	# the material is being initialized. Pin this non-layout visual before an
	# explicit size assignment to avoid resize warnings and one-frame drift.
	authored_chrome.anchor_left = 0.0
	authored_chrome.anchor_top = 0.0
	authored_chrome.anchor_right = 0.0
	authored_chrome.anchor_bottom = 0.0
	authored_chrome.position = Vector2.ZERO
	authored_chrome.size = size
	authored_chrome.modulate = Color(1.0, 1.0, 1.0, 0.98)

	var dark_surface := frame_kind == FrameKind.HUD or frame_kind == FrameKind.BANNER
	lacquer_veil.visible = dark_surface
	if dark_surface:
		var inset := _content_inset(region_name)
		lacquer_veil.position = Vector2(inset.x, inset.y)
		lacquer_veil.size = Vector2(
			maxf(1.0, size.x - inset.x - inset.z),
			maxf(1.0, size.y - inset.y - inset.w)
		)
		var veil_alpha := clampf(fill_color.a * 0.94, 0.76, 0.92)
		lacquer_veil.color = Color(fill_color.r, fill_color.g, fill_color.b, veil_alpha)


func _layout_seal() -> void:
	authored_chrome.hide()
	lacquer_veil.hide()
	authored_emblem.show()
	if _active_region != "touch_skill":
		_active_region = "touch_skill"
		var seal_region: Rect2 = RITUAL_REGIONS["touch_skill"]
		authored_emblem.texture = _atlas_region(seal_region)
	var diameter := minf(minf(size.x, size.y) * 0.54, 360.0)
	authored_emblem.position = (size - Vector2.ONE * diameter) * 0.5
	authored_emblem.size = Vector2.ONE * diameter
	# The medallion is a quiet ritual halo, not a second focal control.
	authored_emblem.modulate = Color(1.0, 1.0, 1.0, clampf(accent_color.a * 0.30, 0.12, 0.24))


func _region_for_current_shape() -> String:
	match frame_kind:
		FrameKind.SCROLL:
			return "modal_guard"
		FrameKind.PAPER:
			return "result_plate"
		FrameKind.BANNER:
			return "wide_header"
		FrameKind.HUD:
			# The compact timer island needs a guarded silhouette; the long life
			# island uses the broader result plate whose quiet field is tall enough
			# for identity plus two meters. This prevents a one-frame-fits-all HUD.
			return "modal_guard" if size.x / maxf(size.y, 1.0) < 2.35 else "result_plate"
	return "modal_guard"


func _content_inset(region_name: String) -> Vector4:
	if region_name == "wide_header":
		return Vector4(
			clampf(size.x * 0.055, 18.0, 34.0),
			clampf(size.y * 0.17, 7.0, 24.0),
			clampf(size.x * 0.055, 18.0, 34.0),
			clampf(size.y * 0.22, 9.0, 29.0)
		)
	if region_name == "result_plate":
		return Vector4(
			clampf(size.x * 0.048, 20.0, 34.0),
			clampf(size.y * 0.07, 7.0, 14.0),
			clampf(size.x * 0.048, 20.0, 34.0),
			clampf(size.y * 0.09, 8.0, 18.0)
		)
	return Vector4(
		clampf(size.x * 0.075, 12.0, 28.0),
		clampf(size.y * 0.12, 9.0, 24.0),
		clampf(size.x * 0.075, 12.0, 28.0),
		clampf(size.y * 0.12, 9.0, 24.0)
	)


func _apply_patch_margins(authored: Vector4) -> void:
	# Preserve hardware while still allowing the 52 px objective strip and the
	# 128 px timer plaque to use the same accepted source family safely.
	var horizontal_cap := maxf(8.0, size.x * 0.23)
	var vertical_cap := maxf(5.0, size.y * 0.34)
	authored_chrome.set_patch_margin(SIDE_LEFT, int(round(minf(authored.x, horizontal_cap))))
	authored_chrome.set_patch_margin(SIDE_TOP, int(round(minf(authored.y, vertical_cap))))
	authored_chrome.set_patch_margin(SIDE_RIGHT, int(round(minf(authored.z, horizontal_cap))))
	authored_chrome.set_patch_margin(SIDE_BOTTOM, int(round(minf(authored.w, vertical_cap))))


func _atlas_region(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = RITUAL_ATLAS
	texture.region = region
	return texture
