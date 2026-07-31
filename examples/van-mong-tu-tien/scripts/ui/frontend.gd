class_name CultivationFrontEnd
extends CanvasLayer

## Full commercial-oriented meta loop rendered above the combat scene.
## Authored environment plates and raster UI chrome carry the visual language;
## flat drawing is used only for restrained dimming and readability glazes.

const RasterButtonScript := preload("res://scripts/ui/raster_button.gd")
const TechniquePreviewScript := preload("res://scripts/ui/technique_preview.gd")
const ComponentKitScript := preload("res://scripts/ui/van_mong_component_kit.gd")
const GlobalCultivationTheme := preload("res://resources/ui/cultivation_theme.tres")
const BODY_FONT := preload("res://assets/fonts/BeVietnamPro-Regular.ttf")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")
const DISPLAY_FONT := preload("res://assets/fonts/Literata-Variable.ttf")

const UI_ROOT := "res://assets/generated/ui/UIKIT-002-xuan-ink-commercial/runtime/"
const SCROLL_PANEL_PATH := UI_ROOT + "ui_scroll_panel.png"
const TALISMAN_CARD_PATH := UI_ROOT + "ui_talisman_card.png"
const RESTRAINED_UI_ROOT := "res://assets/generated/ui/UIKIT-005-restrained-controls/runtime/"
const LACQUER_PANEL_PATH := RESTRAINED_UI_ROOT + "ui_lacquer_panel.png"
const TAB_FRAME_PATH := RESTRAINED_UI_ROOT + "ui_command_ink.png"
const PREMIUM_SIGIL_ROOT := "res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/"
const FOLIO_ROOT := "res://assets/generated/ui/UIKIT-004-talisman-folios/runtime/"
const FOLIO_PATHS := [
	FOLIO_ROOT + "folio_sword.png",
	FOLIO_ROOT + "folio_jade.png",
	FOLIO_ROOT + "folio_spirit.png",
]
const ICON_SWORD_PATH := PREMIUM_SIGIL_ROOT + "sigil_phi_kiem.png"
const ICON_QI_PATH := PREMIUM_SIGIL_ROOT + "sigil_tu_linh.png"
const ICON_VITALITY_PATH := PREMIUM_SIGIL_ROOT + "sigil_ho_the_ngoc.png"
const ITEM_ICON_ROOT := "res://assets/generated/ui/UIICON-001-relics/runtime/"
const SKILL_ICON_ROOT := "res://assets/generated/ui/SKILLICON-001-five-formation/runtime/"
const PORTRAIT_ROOT := "res://assets/generated/portraits/PORTRAIT-001-bestiary-companion-atlas/runtime/"
const PLAYER_PORTRAIT_PATH := "res://assets/generated/portraits/PORTRAIT-002-hero-boss/runtime/player.png"
const ACHIEVEMENT_SEAL_ROOT := "res://assets/generated/ui/ACHIEVEICON-001-six-seals/runtime/"
const ITEM_ICON_PATHS := {
	"jade_sword": ITEM_ICON_ROOT + "relic_jade_sword.png",
	"heart_mirror": ITEM_ICON_ROOT + "relic_heart_mirror.png",
	"cloud_robe": ITEM_ICON_ROOT + "relic_cloud_robe.png",
	"wood_ring": ITEM_ICON_ROOT + "relic_wood_ring.png",
	"sun_sword": ITEM_ICON_ROOT + "relic_sun_sword.png",
	"moon_mirror": ITEM_ICON_ROOT + "relic_moon_mirror.png",
	"blood_talisman": ITEM_ICON_ROOT + "relic_blood_talisman.png",
	"ancient_manual": ITEM_ICON_ROOT + "relic_ancient_manual.png",
	"horn_seal": ITEM_ICON_ROOT + "relic_horn_seal.png",
	"sword_crystal": ITEM_ICON_ROOT + "relic_sword_crystal.png",
	"cloud_bracelet": ITEM_ICON_ROOT + "relic_cloud_bracelet.png",
	"spirit_cuirass": ITEM_ICON_ROOT + "relic_spirit_cuirass.png",
}
const SKILL_ICON_PATHS := {
	"phi_kiem": SKILL_ICON_ROOT + "skill_phi_kiem.png",
	"kiem_tran": SKILL_ICON_ROOT + "skill_kiem_tran.png",
	"linh_phu": SKILL_ICON_ROOT + "skill_linh_phu.png",
	"bang_lien": SKILL_ICON_ROOT + "skill_bang_lien.png",
	"thien_loi": SKILL_ICON_ROOT + "skill_thien_loi.png",
	"thanh_van_ho": SKILL_ICON_ROOT + "assist_thanh_van_ho.png",
}

const TITLE_ART_PATH := "res://assets/generated/key-art/KEYART-001-title-1280x720-v001.webp"
const HUB_ART_PATH := "res://assets/generated/environments/HUB-001-van-mong-sect/hub-background-1600x900-v001.webp"
const STAGE_ART := {
	"van_mong": "res://assets/generated/environments/ARENA-001-cloud-ring/arena-ground-1600x900-v001.webp",
	"huyet_van": "res://assets/generated/environments/STAGE-002-huyet-van-dai/stage-huyet-van-dai-1600x900-v001.webp",
	"thien_mon": "res://assets/generated/environments/STAGE-003-thien-mon-tan-canh/stage-thien-mon-tan-canh-1600x900-v001.webp",
}
const DISCIPLINE_ICONS := {
	"van_kiem": SKILL_ICON_PATHS["phi_kiem"],
	"tu_linh": SKILL_ICON_PATHS["linh_phu"],
	"ngoc_the": SKILL_ICON_PATHS["bang_lien"],
}
const TECHNIQUE_ICONS := {
	"sword_damage": SKILL_ICON_PATHS["phi_kiem"],
	"vitality": SKILL_ICON_PATHS["bang_lien"],
	"magnet": SKILL_ICON_PATHS["linh_phu"],
}
const BESTIARY_VISUALS := {
	"mac_linh": PORTRAIT_ROOT + "mac_linh.png",
	"mac_lang": PORTRAIT_ROOT + "mac_lang.png",
	"ta_tu": PORTRAIT_ROOT + "ta_tu.png",
	"huyet_ve": PORTRAIT_ROOT + "huyet_ve.png",
	"thien_giac": PORTRAIT_ROOT + "thien_giac.png",
}
const ACHIEVEMENT_SEALS := {
	"nhap_dao": ACHIEVEMENT_SEAL_ROOT + "nhap_dao.png",
	"pha_van_mong": ACHIEVEMENT_SEAL_ROOT + "pha_van_mong.png",
	"toc_chien": ACHIEVEMENT_SEAL_ROOT + "toc_chien.png",
	"huyet_chien": ACHIEVEMENT_SEAL_ROOT + "huyet_chien.png",
	"tram_yeu_100": ACHIEVEMENT_SEAL_ROOT + "tram_yeu_100.png",
	"thien_mon_chinh_phuc": ACHIEVEMENT_SEAL_ROOT + "thien_mon_chinh_phuc.png",
}

const PAPER := Color("#f1e6c5")
const PAPER_DIM := Color("#c9bea0")
const PAPER_INK := Color("#25251f")
const PAPER_COPY := Color("#514c3e")
const BRONZE_INK := Color("#7b592a")
const INK := Color("#111c1d")
const INK_SOFT := Color("#263534")
const GOLD := Color("#e6bf67")
const JADE := Color("#65d0aa")
const CRIMSON := Color("#d66a61")
const DARK_GLAZE := Color(0.01, 0.025, 0.027, 0.58)
const V4_PAPER := Color("#e7ddc4")
const V4_PAPER_MUTED := Color("#c9b995")
const V4_INK := Color("#0b171b")
const V4_INK_RAISED := Color("#17292d")
const V4_INK_LINE := Color("#314248")
const V4_BRONZE := Color("#8a6730")
const V4_GOLD := Color("#c69a48")
const V4_JADE := Color("#55c9a6")
const V4_CINNABAR := Color("#b43d35")
const V4_MAJOR_PANEL: Texture2D = preload("res://assets/generated/ui/UIKIT-009-v4-structural/runtime/major_lacquer_panel.png")
const V4_PAPER_FOLIO: Texture2D = preload("res://assets/generated/ui/UIKIT-009-v4-structural/runtime/paper_folio.png")
const V4_HEADER_PLAQUE: Texture2D = preload("res://assets/generated/ui/UIKIT-009-v4-structural/runtime/header_plaque.png")
const V4_RESULT_FRAME: Texture2D = preload("res://assets/generated/ui/UIKIT-009-v4-structural/runtime/result_modal_frame.png")
const V5_FOLIO_PRIMARY_PATHS := [
	"res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/sword-formation-folio-a.png",
	"res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/jade-body-folio-a.png",
	"res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/spirit-vortex-folio-a.png",
]
const V5_FOLIO_SECONDARY_PATHS := [
	"res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/sword-formation-folio-b.png",
	"res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/jade-body-folio-b.png",
	"res://assets/generated/ui/UIKIT-014-v5-technique-folios/runtime/spirit-vortex-folio-b.png",
]
const V5_HUB_DOSSIER_PATH := "res://assets/generated/ui/UIKIT-015-v5-ledger-hub/runtime/identity-dossier.png"
const V5_HUB_EXPEDITION_PATH := "res://assets/generated/ui/UIKIT-015-v5-ledger-hub/runtime/expedition-window.png"
const V5_HUB_COMMAND_RAIL_PATH := "res://assets/generated/ui/UIKIT-015-v5-ledger-hub/runtime/command-rail.png"
const V5_ACHIEVEMENT_LEDGER_PATH := "res://assets/generated/ui/UIKIT-015-v5-ledger-hub/runtime/achievement-ledger.png"
const V5_VICTORY_SHRINE_PATH := "res://assets/generated/ui/UIKIT-013-v5-ritual-modals/runtime/victory-ascension-shrine.png"
const V5_DEFEAT_SHRINE_PATH := "res://assets/generated/ui/UIKIT-013-v5-ritual-modals/runtime/defeat-broken-dao-shrine.png"
const V4_ART_GRADE_SHADER := """
shader_type canvas_item;
uniform float saturation : hint_range(0.0, 1.0) = 0.5;
uniform vec4 ink_tint : source_color = vec4(1.0);
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float value = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	tex.rgb = mix(vec3(value), tex.rgb, saturation) * ink_tint.rgb;
	COLOR = tex * COLOR;
}
"""

const SCREEN_TITLE := &"title"
const SCREEN_HUB := &"hub"
const SCREEN_STAGES := &"stages"
const SCREEN_LOADOUT := &"loadout"
const SCREEN_INVENTORY := &"inventory"
const SCREEN_SPIRIT_BEAST := &"spirit_beast"
const SCREEN_TECHNIQUES := &"techniques"
const SCREEN_CODEX := &"codex"
const SCREEN_ACHIEVEMENTS := &"achievements"
const SCREEN_SETTINGS := &"settings"
const SCREEN_RESULTS := &"results"
const DESIGN_SIZE := Vector2(1600.0, 900.0)
const PHONE_MAX_SIZE := Vector2(960.0, 540.0)
const PHONE_EDGE_INSET := 44.0
const PHONE_VERTICAL_INSET := 18.0
const PHONE_CURRENCY_WIDTH := 160.0


## Native V4 plate used by the complete meta shell.  The clipped corners and
## inset rules are generated at runtime, so the silhouette stays crisp at every
## supported size without stretching any raster chrome.
class V4Plate:
	extends Control

	var fill := Color("#0b171b")
	var edge := Color("#8a6730")
	var cut := 12.0
	var paper := false
	var strong := false
	var authored_texture: Texture2D
	var authored_chrome: NinePatchRect

	func configure(fill_color: Color, edge_color: Color, corner_cut: float, is_paper: bool, is_strong: bool = false) -> V4Plate:
		fill = fill_color
		edge = edge_color
		cut = corner_cut
		paper = is_paper
		strong = is_strong
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()
		return self

	func use_authored(texture_value: Texture2D, margins: Vector4) -> V4Plate:
		if texture_value == null:
			return self
		authored_texture = texture_value
		authored_chrome = NinePatchRect.new()
		authored_chrome.name = "V4AuthoredChrome"
		authored_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		authored_chrome.texture = authored_texture
		authored_chrome.set_patch_margin(SIDE_LEFT, roundi(margins.x))
		authored_chrome.set_patch_margin(SIDE_TOP, roundi(margins.y))
		authored_chrome.set_patch_margin(SIDE_RIGHT, roundi(margins.z))
		authored_chrome.set_patch_margin(SIDE_BOTTOM, roundi(margins.w))
		authored_chrome.draw_center = true
		authored_chrome.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		authored_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(authored_chrome)
		queue_redraw()
		return self

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _points(offset := Vector2.ZERO) -> PackedVector2Array:
		var w := size.x
		var h := size.y
		var c := minf(cut, minf(w, h) * 0.18)
		return PackedVector2Array([
			Vector2(c, 0.0) + offset,
			Vector2(w - c * 0.55, 0.0) + offset,
			Vector2(w, c * 0.55) + offset,
			Vector2(w, h - c) + offset,
			Vector2(w - c, h) + offset,
			Vector2(c * 0.55, h) + offset,
			Vector2(0.0, h - c * 0.55) + offset,
			Vector2(0.0, c) + offset,
		])

	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		if authored_texture != null:
			return
		draw_colored_polygon(_points(Vector2(0.0, 6.0)), Color(0.0, 0.0, 0.0, 0.28 if strong else 0.18))
		var points := _points()
		draw_colored_polygon(points, fill)
		var closed := PackedVector2Array(points)
		closed.append(points[0])
		draw_polyline(closed, edge, 2.0 if strong else 1.0, true)
		var inset := 7.0 if strong else 5.0
		var inner_size := size - Vector2(inset * 2.0, inset * 2.0)
		if inner_size.x > 24.0 and inner_size.y > 24.0:
			var inner_cut := maxf(4.0, cut - inset * 0.5)
			var inner := PackedVector2Array([
				Vector2(inset + inner_cut, inset),
				Vector2(size.x - inset - inner_cut * 0.55, inset),
				Vector2(size.x - inset, inset + inner_cut * 0.55),
				Vector2(size.x - inset, size.y - inset - inner_cut),
				Vector2(size.x - inset - inner_cut, size.y - inset),
				Vector2(inset + inner_cut * 0.55, size.y - inset),
				Vector2(inset, size.y - inset - inner_cut * 0.55),
				Vector2(inset, inset + inner_cut),
			])
			inner.append(inner[0])
			draw_polyline(inner, Color(edge, 0.34 if paper else 0.52), 1.0, true)
		var rule_y := 14.0 if size.y > 72.0 else 9.0
		draw_line(Vector2(cut + 10.0, rule_y), Vector2(size.x - cut - 10.0, rule_y), Color(edge, 0.26), 1.0, true)
		if paper and size.y > 96.0:
			draw_line(Vector2(cut + 16.0, size.y - 18.0), Vector2(size.x - cut - 16.0, size.y - 18.0), Color(edge, 0.18), 1.0, true)

var profile: Node
var root: Control
var background: TextureRect
var background_glaze: ColorRect
var background_base: ColorRect
var screen_root: Control
var screen_name := SCREEN_TITLE
var selected_codex := &"mac_linh"
var selected_item_id := "kiem_huyen"
var selected_beast_id := "thanh_van_ho"
var equipped_item_ids := ["kiem_huyen", "ho_tam_ngoc", "dao_bao_van", "linh_gioi_moc"]
var beast_bound := true
var last_result: Dictionary = {}
var last_victory := false
var last_result_title := ""
var last_result_details := ""
var run_elapsed := 0.0
var run_duration := 240.0
var run_kills := 0
var focus_queue: Array[Control] = []
var toast_panel: Control
var toast_label: Label
var toast_time := 0.0
var phone_layout_active := false
var layout_rebuild_queued := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	profile = get_node_or_null("/root/MetaProfile")
	_build_root()
	_connect_events()
	_apply_audio_settings()
	call_deferred("_open_initial_screen")


func _process(delta: float) -> void:
	if toast_time <= 0.0 or toast_panel == null:
		return
	toast_time = maxf(0.0, toast_time - delta)
	toast_panel.modulate.a = clampf(toast_time * 4.0, 0.0, 1.0) if toast_time < 0.25 else 1.0
	if toast_time <= 0.0:
		toast_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		var modal := root.get_node_or_null("ResetConfirmation")
		if modal != null:
			modal.queue_free()
			call_deferred("_focus_first")
			get_viewport().set_input_as_handled()
			return
		_back()
		get_viewport().set_input_as_handled()
		return
	# Keep combat shortcuts from leaking through a visible front-end screen.
	if event.is_action_pressed(&"qi_pulse") or event.is_action_pressed(&"pause_game") or event.is_action_pressed(&"restart_game"):
		get_viewport().set_input_as_handled()


func _connect_events() -> void:
	Events.game_started.connect(_on_game_started)
	Events.game_finished.connect(_on_game_finished)
	Events.run_stats_changed.connect(_on_run_stats_changed)
	if profile != null:
		if profile.has_signal("profile_changed"):
			profile.connect("profile_changed", _on_profile_changed)
		if profile.has_signal("settings_changed"):
			profile.connect("settings_changed", _on_settings_changed)


func _build_root() -> void:
	root = Control.new()
	root.name = "FrontEndRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = GlobalCultivationTheme
	add_child(root)
	root.resized.connect(_layout_design_canvas)

	background_base = ColorRect.new()
	background_base.name = "InkExtensionField"
	background_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_base.color = V4_INK
	background_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background_base)

	background = TextureRect.new()
	background.name = "AuthoredBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)

	background_glaze = ColorRect.new()
	background_glaze.name = "ReadabilityGlaze"
	background_glaze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_glaze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background_glaze)

	screen_root = Control.new()
	screen_root.name = "Screen"
	screen_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen_root.size = DESIGN_SIZE
	screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(screen_root)

	toast_panel = _v4_plate(Rect2(500.0, 28.0, 600.0, 76.0), false, V4_JADE, true)
	toast_panel.name = "Toast"
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_panel)
	toast_label = _label("", 17, PAPER, true)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_label.offset_left = 42.0
	toast_label.offset_right = -42.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)
	toast_panel.hide()
	_layout_design_canvas()


func _layout_design_canvas() -> void:
	if root == null or screen_root == null:
		return
	var available := root.size
	var previous_phone_layout := phone_layout_active
	phone_layout_active = _is_phone_landscape_size(available)
	_apply_design_canvas_transform(screen_root, available)
	var reset_canvas := root.get_node_or_null("ResetConfirmation/DialogCanvas") as Control
	if reset_canvas != null:
		_apply_design_canvas_transform(reset_canvas, available)
	var ascension_canvas := root.get_node_or_null("RankAscension/DialogCanvas") as Control
	if ascension_canvas != null:
		_apply_design_canvas_transform(ascension_canvas, available)
	if toast_panel != null:
		if phone_layout_active:
			var phone_size := _physical_window_size()
			var phone_scale := _phone_canvas_scale(available, phone_size)
			toast_panel.scale = Vector2.ONE * phone_scale
			toast_panel.size = Vector2(minf(560.0, phone_size.x - PHONE_EDGE_INSET * 2.0), 64.0)
			toast_panel.position = Vector2((available.x - toast_panel.size.x * phone_scale) * 0.5, PHONE_VERTICAL_INSET * phone_scale)
		else:
			toast_panel.scale = Vector2.ONE
			toast_panel.size = Vector2(600.0, 76.0)
			toast_panel.position = Vector2((available.x - toast_panel.size.x) * 0.5, maxf(available.y * 0.05, screen_root.position.y + 45.0 * screen_root.scale.y))
	if previous_phone_layout != phone_layout_active and not screen_root.get_children().is_empty() and not layout_rebuild_queued:
		layout_rebuild_queued = true
		call_deferred("_rebuild_after_layout_change")


func _apply_design_canvas_transform(canvas: Control, available: Vector2) -> void:
	if _is_phone_landscape_size(available):
		var phone_size := _physical_window_size()
		var phone_scale := _phone_canvas_scale(available, phone_size)
		canvas.scale = Vector2.ONE * phone_scale
		canvas.size = phone_size
		canvas.position = (available - phone_size * phone_scale) * 0.5
		return
	canvas.size = DESIGN_SIZE
	var scale_factor := minf(1.0, minf(available.x / DESIGN_SIZE.x, available.y / DESIGN_SIZE.y))
	canvas.scale = Vector2.ONE * scale_factor
	var scaled_size := DESIGN_SIZE * scale_factor
	canvas.position = (available - scaled_size) * 0.5


func _is_phone_landscape_size(available: Vector2) -> bool:
	var physical := _physical_window_size()
	# `canvas_items + expand` keeps the logical height near 900 on a phone and
	# exposes a ~1947x900 root at 844x390. The window size is therefore the
	# authoritative device-space signal; the expanded Control size is not.
	return physical.x > physical.y and physical.x <= PHONE_MAX_SIZE.x and physical.y <= PHONE_MAX_SIZE.y and available.x > available.y


func _physical_window_size() -> Vector2:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0:
		return root.size if root != null else DESIGN_SIZE
	return window_size


func _phone_canvas_scale(available: Vector2, phone_size: Vector2) -> float:
	if phone_size.x <= 1.0 or phone_size.y <= 1.0:
		return 1.0
	return minf(available.x / phone_size.x, available.y / phone_size.y)


func _rebuild_after_layout_change() -> void:
	layout_rebuild_queued = false
	if root != null and root.visible and screen_root != null:
		_show_screen(screen_name)


func _open_initial_screen() -> void:
	var pending := SCREEN_TITLE
	if profile != null:
		pending = StringName(str(profile.get("pending_screen")))
		profile.set("pending_screen", SCREEN_TITLE)
	if pending == SCREEN_HUB:
		_show_screen(SCREEN_HUB)
	elif pending == SCREEN_LOADOUT:
		_show_screen(SCREEN_LOADOUT)
	else:
		_show_screen(SCREEN_TITLE)


func _show_screen(next_screen: StringName) -> void:
	var stale_modal := root.get_node_or_null("ResetConfirmation")
	if stale_modal != null:
		stale_modal.queue_free()
	screen_name = next_screen
	root.show()
	phone_layout_active = _is_phone_landscape_size(root.size)
	_apply_design_canvas_transform(screen_root, root.size)
	_set_audio_mode(&"title" if next_screen == SCREEN_TITLE else (&"result" if next_screen == SCREEN_RESULTS else &"hub"))
	focus_queue.clear()
	for child in screen_root.get_children():
		child.queue_free()
	if phone_layout_active:
		_v4_build_phone_screen(next_screen)
	else:
		_v4_build_desktop_screen(next_screen)
	call_deferred("_focus_first")


func _build_phone_screen(next_screen: StringName) -> void:
	match next_screen:
		SCREEN_TITLE:
			_build_phone_title()
		SCREEN_HUB:
			_build_phone_hub()
		SCREEN_STAGES:
			_build_phone_stage_select()
		SCREEN_LOADOUT:
			_build_phone_loadout()
		SCREEN_INVENTORY:
			_build_phone_inventory()
		SCREEN_SPIRIT_BEAST:
			_build_phone_spirit_beast()
		SCREEN_TECHNIQUES:
			_build_phone_techniques()
		SCREEN_CODEX:
			_build_phone_codex()
		SCREEN_ACHIEVEMENTS:
			_build_phone_achievements()
		SCREEN_SETTINGS:
			_build_phone_settings()
		SCREEN_RESULTS:
			_build_phone_results()


func _phone_safe_rect() -> Rect2:
	var available := screen_root.size
	var horizontal_inset := minf(PHONE_EDGE_INSET, maxf(18.0, available.x * 0.052))
	var vertical_inset := minf(PHONE_VERTICAL_INSET, maxf(6.0, available.y * 0.026))
	return Rect2(
		Vector2(horizontal_inset, vertical_inset),
		Vector2(maxf(1.0, available.x - horizontal_inset * 2.0), maxf(1.0, available.y - vertical_inset * 2.0))
	)


func _build_phone_header(title_text: String, subtitle_text: String, show_back: bool = true) -> void:
	var safe := _phone_safe_rect()
	var title_x := safe.position.x
	if show_back:
		var back := _button("TRỞ VỀ", RasterButton.ArtVariant.INK, Vector2(128.0, 64.0), 14, _back)
		back.position = safe.position
		back.size = Vector2(128.0, 64.0)
		screen_root.add_child(back)
		title_x += 144.0
	# Three-digit balances were wider than the former 128 px field, so the
	# right-aligned Label clipped its leading digit at the 844x390 Web viewport.
	var currency_width := PHONE_CURRENCY_WIDTH
	var title_width := safe.end.x - currency_width - title_x - 10.0
	ComponentKitScript.nine_patch(screen_root, "secondary", Rect2(title_x - 10.0, safe.position.y + 2.0, maxf(190.0, title_width + 18.0), 62.0), Color(0.86, 0.96, 0.92, 0.88))
	var heading := _label(title_text, 23, PAPER, true)
	# Keep Vietnamese glyphs below the phone header crest and inside the quiet
	# field of the authored silhouette.
	heading.position = Vector2(title_x, safe.position.y + 10.0)
	heading.size = Vector2(maxf(180.0, title_width), 30.0)
	screen_root.add_child(heading)
	var subtitle := _label(subtitle_text, 15, PAPER_DIM)
	subtitle.position = Vector2(title_x, safe.position.y + 40.0)
	subtitle.size = Vector2(maxf(180.0, title_width), 24.0)
	screen_root.add_child(subtitle)
	var currency := _label("%d LINH NGỌC" % _profile_value("currency", 0), 18, GOLD, true)
	currency.name = "PhoneCurrency"
	currency.position = Vector2(safe.end.x - currency_width, safe.position.y + 17.0)
	currency.size = Vector2(currency_width, 32.0)
	currency.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(currency)
	var baseline := ColorRect.new()
	baseline.position = Vector2(safe.position.x, safe.position.y + 72.0)
	baseline.size = Vector2(safe.size.x, 1.0)
	baseline.color = Color(GOLD, 0.40)
	baseline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(baseline)


func _build_phone_title() -> void:
	_set_background(TITLE_ART_PATH, Color(0.005, 0.014, 0.016, 0.16))
	_add_directional_vignette(true)
	var safe := _phone_safe_rect()
	var frame_width := minf(442.0, safe.size.x * 0.59)
	var frame := _ritual_surface(Rect2(safe.position, Vector2(frame_width, safe.size.y)), "modal_guard", Color(0.98, 0.96, 0.88, 1.0), true)
	screen_root.add_child(frame)
	# The jade crest already carries sect identity. Do not place live copy on top
	# of its narrow phone ornament.
	var title := _label("VÂN MỘNG  ·  TU TIÊN", 31, PAPER_INK, true)
	title.position = Vector2(safe.position.x + 30.0, safe.position.y + 62.0)
	title.size = Vector2(frame_width - 60.0, 46.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(title)
	var subtitle := _label("NHẤT NIỆM NHẬP ĐẠO · VẠN KIẾM HỘ THÂN", 14, Color("#2f7469"), true)
	subtitle.position = Vector2(safe.position.x + 24.0, safe.position.y + 112.0)
	subtitle.size = Vector2(frame_width - 48.0, 26.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(subtitle)
	var lore := _label("Chọn công pháp, vượt ba tầng ma kiếp và định lại đạo đồ trong biển mây thủy mặc.", 16, PAPER_COPY)
	lore.position = Vector2(safe.position.x + 44.0, safe.position.y + 148.0)
	lore.size = Vector2(frame_width - 88.0, 58.0)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(lore)
	var continue_text := "TIẾP TỤC ĐẠO ĐỒ" if _profile_value("runs", 0) > 0 else "NHẬP MÔN"
	var enter := _button(continue_text, RasterButton.ArtVariant.GOLD, Vector2(frame_width - 84.0, 64.0), 18, func() -> void: _show_screen(SCREEN_HUB))
	enter.position = Vector2(safe.position.x + 42.0, safe.position.y + 214.0)
	enter.size = Vector2(frame_width - 84.0, 64.0)
	screen_root.add_child(enter)
	var secondary_width := (frame_width - 92.0) * 0.5
	var settings_button := _button("THIẾT LẬP", RasterButton.ArtVariant.INK, Vector2(secondary_width, 64.0), 14, func() -> void: _show_screen(SCREEN_SETTINGS))
	settings_button.position = Vector2(safe.position.x + 42.0, safe.end.y - 70.0)
	settings_button.size = Vector2(secondary_width, 64.0)
	screen_root.add_child(settings_button)
	var quit := _button("THOÁT", RasterButton.ArtVariant.INK, Vector2(secondary_width, 64.0), 14, _quit_game)
	quit.position = Vector2(settings_button.position.x + secondary_width + 8.0, safe.end.y - 70.0)
	quit.size = Vector2(secondary_width, 64.0)
	screen_root.add_child(quit)


func _build_phone_hub() -> void:
	_set_background(HUB_ART_PATH, Color(0.006, 0.016, 0.018, 0.24))
	_add_directional_vignette(false)
	var safe := _phone_safe_rect()
	var heading := _label("SƠN MÔN VÂN MỘNG", 25, PAPER, true)
	heading.position = Vector2(safe.position.x, safe.position.y)
	heading.size = Vector2(350.0, 34.0)
	screen_root.add_child(heading)
	var record := _label("THẮNG %d  ·  TRẢM %d  ·  CÔNG LỰC %d  ·  %d LINH NGỌC" % [
		_profile_value("victories", 0), _profile_value("kills", 0), _account_power(), _profile_value("currency", 0)
	], 14, Color(PAPER_DIM, 0.90), true)
	record.position = Vector2(safe.position.x, safe.position.y + 34.0)
	record.size = Vector2(480.0, 24.0)
	screen_root.add_child(record)

	var doctrine := _discipline_data(_selected_discipline())
	var discipline_key := _discipline_technique_key(_selected_discipline())
	var ranks: Dictionary = _profile_snapshot().get("technique_ranks", {}) as Dictionary
	var current_rank := int(ranks.get(String(discipline_key), ranks.get(discipline_key, 0)))
	var ritual := TechniquePreviewScript.new() as TechniquePreview
	ritual.position = Vector2(safe.position.x, safe.position.y + 62.0)
	ritual.size = Vector2(214.0, 220.0)
	ritual.configure(discipline_key, current_rank, 5, _load_texture(str(DISCIPLINE_ICONS.get(String(_selected_discipline()), ICON_SWORD_PATH))))
	screen_root.add_child(ritual)
	var doctrine_backing := _surface(Rect2(safe.position.x - 2.0, safe.position.y + 238.0, 218.0, 44.0), Color(INK, 0.68), Color(JADE, 0.22), 1)
	screen_root.add_child(doctrine_backing)
	var doctrine_name := _label(str(doctrine.get("name", "Vạn Kiếm Quy Tông")), 18, PAPER, true)
	doctrine_name.position = Vector2(safe.position.x, safe.position.y + 244.0)
	doctrine_name.size = Vector2(214.0, 34.0)
	doctrine_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(doctrine_name)
	var change := _button("ĐỔI TÂM PHÁP", RasterButton.ArtVariant.INK, Vector2(214.0, 64.0), 14, func() -> void: _show_screen(SCREEN_LOADOUT))
	change.position = Vector2(safe.position.x, safe.end.y - 64.0)
	change.size = Vector2(214.0, 64.0)
	screen_root.add_child(change)

	var selected_stage := _selected_stage()
	var stage := _stage_data(selected_stage)
	var stage_x := safe.position.x + 232.0
	var stage_preview := _texture(str(STAGE_ART.get(String(selected_stage), STAGE_ART["van_mong"])), Rect2(stage_x, safe.position.y + 66.0, 240.0, 122.0))
	screen_root.add_child(stage_preview)
	var stage_info := _surface(Rect2(stage_x - 4.0, safe.position.y + 188.0, 248.0, 68.0), Color(INK, 0.72), Color(GOLD, 0.26), 1)
	screen_root.add_child(stage_info)
	var stage_caption := _label("THÍ LUYỆN ĐANG CHỌN", 13, GOLD, true)
	stage_caption.position = Vector2(stage_x, safe.position.y + 194.0)
	stage_caption.size = Vector2(240.0, 22.0)
	screen_root.add_child(stage_caption)
	var stage_name := _label(str(stage.get("name", "Vân Mộng Cốc")), 21, PAPER, true)
	stage_name.position = Vector2(stage_x, safe.position.y + 220.0)
	stage_name.size = Vector2(240.0, 30.0)
	screen_root.add_child(stage_name)
	var depart := _button("KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(240.0, 64.0), 17, func() -> void: _show_screen(SCREEN_LOADOUT))
	depart.position = Vector2(stage_x, safe.end.y - 64.0)
	depart.size = Vector2(240.0, 64.0)
	screen_root.add_child(depart)

	var command_x := safe.position.x + 490.0
	var command_width := safe.end.x - command_x
	var commands := [
		["HÀNH TRÌNH", RasterButton.ArtVariant.GOLD, func() -> void: _show_screen(SCREEN_STAGES)],
		["CÔNG PHÁP", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_TECHNIQUES)],
		["PHÁP BẢO", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_INVENTORY)],
		["LINH THÚ", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_SPIRIT_BEAST)],
		["VẠN TƯỢNG", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_CODEX)],
		["THÀNH TỰU", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_ACHIEVEMENTS)],
		["THIẾT LẬP", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_SETTINGS)],
	]
	var command_gap := 6.0
	var command_button_width := (command_width - command_gap) * 0.5
	for index in commands.size():
		var command: Array = commands[index]
		var col := index % 2
		var row := index / 2
		var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(command_button_width, 64.0), 12, command[2] as Callable)
		button.position = Vector2(command_x + col * (command_button_width + command_gap), safe.position.y + 50.0 + row * 68.0)
		button.size = Vector2(command_button_width, 64.0)
		screen_root.add_child(button)


func _build_phone_stage_select() -> void:
	var current_id := _selected_stage()
	_set_background(str(STAGE_ART.get(String(current_id), STAGE_ART["van_mong"])), Color(0.006, 0.016, 0.018, 0.56))
	_build_phone_header("CHỌN THÍ LUYỆN", "Ba cảnh giới · chọn đường nhập đạo")
	var safe := _phone_safe_rect()
	var stages := _stages()
	var gap := 8.0
	var card_width := (safe.size.x - gap * 2.0) / 3.0
	for index in mini(stages.size(), 3):
		var stage: Dictionary = stages[index]
		var stage_id := StringName(str(stage.get("id", "van_mong")))
		var unlocked := bool(stage.get("unlocked", false))
		var selected := stage_id == current_id
		var x := safe.position.x + index * (card_width + gap)
		var card := _panel(Rect2(x, safe.position.y + 76.0, card_width, 222.0), LACQUER_PANEL_PATH, 30)
		card.modulate = Color(1.02, 1.02, 0.96, 1.0) if selected else Color.WHITE
		screen_root.add_child(card)
		var preview := _texture(str(STAGE_ART.get(String(stage_id), STAGE_ART["van_mong"])), Rect2(x + 10.0, safe.position.y + 86.0, card_width - 20.0, 78.0))
		preview.modulate = Color.WHITE if unlocked else Color(0.35, 0.34, 0.34, 0.92)
		screen_root.add_child(preview)
		var badge := _label("ĐÃ CHỌN" if selected else ("ĐÃ KHAI MỞ" if unlocked else "PHONG ẤN"), 14, GOLD if unlocked else CRIMSON, true)
		badge.position = Vector2(x + 12.0, safe.position.y + 168.0)
		badge.size = Vector2(card_width - 24.0, 22.0)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(badge)
		var name := _label(str(stage.get("name", "Vân Mộng Cốc")), 18, PAPER, true)
		name.position = Vector2(x + 10.0, safe.position.y + 192.0)
		name.size = Vector2(card_width - 20.0, 28.0)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(name)
		var difficulty := int(stage.get("difficulty", index + 1))
		var risk := _label("HIỂM HỌA %d/3  ·  %d NGỌC" % [difficulty, int((stage.get("rewards", {}) as Dictionary).get("base", 30))], 14, PAPER_DIM, true)
		risk.position = Vector2(x + 8.0, safe.position.y + 218.0)
		risk.size = Vector2(card_width - 16.0, 22.0)
		risk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(risk)
		var button_text := "ĐANG CHỌN" if selected else ("CHỌN CẢNH" if unlocked else "CHƯA KHAI MỞ")
		var choose := _button(button_text, RasterButton.ArtVariant.JADE if selected else RasterButton.ArtVariant.INK, Vector2(card_width - 16.0, 64.0), 14, func() -> void: _select_stage(stage_id))
		choose.position = Vector2(x + 8.0, safe.position.y + 234.0)
		choose.size = Vector2(card_width - 16.0, 64.0)
		choose.disabled = not unlocked
		choose.call_deferred("_refresh_visual_state")
		screen_root.add_child(choose)
	var summary_backing := _surface(Rect2(safe.position.x - 4.0, safe.end.y - 64.0, safe.size.x - 310.0, 64.0), Color(INK, 0.70), Color(JADE, 0.18), 1)
	screen_root.add_child(summary_backing)
	var summary := _label(str(_stage_data(current_id).get("description", "")), 15, PAPER)
	summary.position = Vector2(safe.position.x, safe.end.y - 58.0)
	summary.size = Vector2(safe.size.x - 318.0, 52.0)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(summary)
	var proceed := _button("CHUẨN BỊ", RasterButton.ArtVariant.GOLD, Vector2(300.0, 64.0), 17, func() -> void: _show_screen(SCREEN_LOADOUT))
	proceed.position = Vector2(safe.end.x - 300.0, safe.end.y - 64.0)
	proceed.size = Vector2(300.0, 64.0)
	screen_root.add_child(proceed)


func _build_phone_loadout() -> void:
	var stage := _stage_data(_selected_stage())
	_set_background(str(STAGE_ART.get(String(_selected_stage()), HUB_ART_PATH)), Color(0.006, 0.016, 0.018, 0.58))
	_build_phone_header("CHỌN TÂM PHÁP", str(stage.get("name", "Vân Mộng Cốc")))
	var safe := _phone_safe_rect()
	var disciplines := _disciplines()
	var selected := _selected_discipline()
	var gap := 8.0
	var card_width := (safe.size.x - gap * 2.0) / 3.0
	for index in mini(disciplines.size(), 3):
		var discipline: Dictionary = disciplines[index]
		var discipline_id := StringName(str(discipline.get("id", "van_kiem")))
		var is_selected := discipline_id == selected
		var x := safe.position.x + index * (card_width + gap)
		var card := _panel(Rect2(x, safe.position.y + 76.0, card_width, 222.0), LACQUER_PANEL_PATH, 30)
		card.modulate = Color(1.02, 1.04, 0.96, 1.0) if is_selected else Color.WHITE
		screen_root.add_child(card)
		var icon := _texture(str(DISCIPLINE_ICONS.get(String(discipline_id), ICON_SWORD_PATH)), Rect2(x + (card_width - 78.0) * 0.5, safe.position.y + 83.0, 78.0, 78.0))
		screen_root.add_child(icon)
		var role := _label(str(discipline.get("role", "Công kích")).to_upper(), 14, GOLD, true)
		role.position = Vector2(x + 10.0, safe.position.y + 164.0)
		role.size = Vector2(card_width - 20.0, 22.0)
		role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(role)
		var name := _label(str(discipline.get("name", "Vạn Kiếm Quy Tông")), 18, PAPER, true)
		name.position = Vector2(x + 10.0, safe.position.y + 187.0)
		name.size = Vector2(card_width - 20.0, 31.0)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(name)
		# The full doctrine paragraph belongs to desktop. The phone card needs one
		# deliberate benefit line so copy never runs behind the 64 px equip seal.
		var copy := _label(_phone_discipline_copy(discipline_id), 14, PAPER_DIM, true)
		copy.position = Vector2(x + 14.0, safe.position.y + 216.0)
		copy.size = Vector2(card_width - 28.0, 22.0)
		copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		copy.clip_text = true
		screen_root.add_child(copy)
		var equip := _button("ĐÃ TRANG BỊ" if is_selected else "TRANG BỊ", RasterButton.ArtVariant.JADE if is_selected else RasterButton.ArtVariant.INK, Vector2(card_width - 16.0, 64.0), 14, func() -> void: _select_discipline(discipline_id))
		equip.position = Vector2(x + 8.0, safe.position.y + 234.0)
		equip.size = Vector2(card_width - 16.0, 64.0)
		screen_root.add_child(equip)
	var summary := _label("%s  ·  %s  ·  HIỂM HỌA %d/3" % [
		str(stage.get("name", "Vân Mộng Cốc")),
		str(_discipline_data(_selected_discipline()).get("name", "Vạn Kiếm Quy Tông")),
		int(stage.get("difficulty", 1)),
	], 16, PAPER, true)
	summary.position = Vector2(safe.position.x, safe.end.y - 48.0)
	summary.size = Vector2(safe.size.x - 306.0, 36.0)
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen_root.add_child(summary)
	var start := _button("NHẬP CẢNH", RasterButton.ArtVariant.GOLD, Vector2(288.0, 64.0), 18, _start_selected_run)
	start.position = Vector2(safe.end.x - 288.0, safe.end.y - 64.0)
	start.size = Vector2(288.0, 64.0)
	screen_root.add_child(start)


func _build_phone_inventory() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.014, 0.016, 0.76))
	_build_phone_header("KHO PHÁP BẢO", "Chọn vật phẩm · xem so sánh · trang bị")
	var safe := _phone_safe_rect()
	var body_y := safe.position.y + 76.0
	var body_height := safe.end.y - body_y
	# Give the comparison folio enough width for a real title/stat hierarchy;
	# the phone composition remains three islands, not a crushed desktop grid.
	var equipped_width := safe.size.x * 0.24
	var grid_width := safe.size.x * 0.42
	var detail_x := safe.position.x + equipped_width + grid_width + 16.0
	var detail_width := safe.end.x - detail_x
	var dossier := _panel(Rect2(safe.position.x, body_y, equipped_width - 8.0, body_height), LACQUER_PANEL_PATH, 28)
	screen_root.add_child(dossier)
	var hero := _texture("res://assets/generated/runtime/player_idle.png", Rect2(safe.position.x + 18.0, body_y + 12.0, equipped_width - 44.0, 150.0))
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen_root.add_child(hero)
	var heading := _label("ĐANG TRẤN PHÁP", 14, GOLD, true)
	heading.position = Vector2(safe.position.x + 12.0, body_y + 164.0)
	heading.size = Vector2(equipped_width - 32.0, 22.0)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(heading)
	for index in mini(equipped_item_ids.size(), 4):
		var item_id := str(equipped_item_ids[index])
		var item := _item_by_id(item_id)
		var col := index % 2
		var row := index / 2
		ComponentKitScript.item_slot(screen_root, item_id, str(item.get("name", "Pháp bảo")), str(item.get("rarity", "Linh")), Rect2(safe.position.x + 10.0 + col * ((equipped_width - 26.0) * 0.5), body_y + 196.0 + row * 116.0, (equipped_width - 34.0) * 0.5, 108.0), _load_texture(str(item.get("icon_path", ICON_SWORD_PATH))), item_id == selected_item_id, func() -> void: _select_inventory_item(item_id), 1.35, false)

	var grid_x := safe.position.x + equipped_width
	var grid := _panel(Rect2(grid_x, body_y, grid_width, body_height), LACQUER_PANEL_PATH, 28)
	screen_root.add_child(grid)
	var items := _inventory_items()
	var item_width := (grid_width - 40.0) / 4.0
	var item_height := (body_height - 38.0) / 3.0
	for index in items.size():
		var item: Dictionary = items[index]
		var col := index % 4
		var row := index / 4
		var item_id := str(item.get("id", "item_%d" % index))
		ComponentKitScript.item_slot(screen_root, item_id, str(item.get("name", "Pháp bảo")), str(item.get("rarity", "Linh")), Rect2(grid_x + 8.0 + col * (item_width + 4.0), body_y + 8.0 + row * (item_height + 5.0), item_width, item_height), _load_texture(str(item.get("icon_path", ICON_SWORD_PATH))), item_id == selected_item_id, func() -> void: _select_inventory_item(item_id), 1.35, false)

	ComponentKitScript.panel(screen_root, Rect2(detail_x, body_y, detail_width, body_height), "tooltip", Color(0.80, 0.90, 0.86, 0.92))
	var chosen := _item_by_id(selected_item_id)
	var chosen_icon := _texture(str(chosen.get("icon_path", ICON_SWORD_PATH)), Rect2(detail_x + detail_width * 0.22, body_y + 14.0, detail_width * 0.56, 120.0))
	chosen_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen_root.add_child(chosen_icon)
	var chosen_name := _label(str(chosen.get("name", "Kiếm Huyền")), 26, PAPER, true)
	chosen_name.position = Vector2(detail_x + 18.0, body_y + 136.0)
	chosen_name.size = Vector2(detail_width - 36.0, 30.0)
	chosen_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(chosen_name)
	var chosen_meta := _label("%s · +18%% KIẾM" % str(chosen.get("rarity", "Huyền")).to_upper(), 19, _rarity_color(str(chosen.get("rarity", "Huyền"))), true)
	chosen_meta.position = Vector2(detail_x + 18.0, body_y + 170.0)
	chosen_meta.size = Vector2(detail_width - 36.0, 22.0)
	chosen_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(chosen_meta)
	var stats := _label("Hồi chiêu  -8%\nTụ linh    +12%\nSo sánh  +12 · +8 · +4", 18, PAPER, true)
	stats.position = Vector2(detail_x + 26.0, body_y + 210.0)
	stats.size = Vector2(detail_width - 52.0, 86.0)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(stats)
	var equip := _button("TRANG BỊ", RasterButton.ArtVariant.GOLD, Vector2(detail_width - 36.0, 64.0), 19, func() -> void: _equip_item(selected_item_id))
	equip.position = Vector2(detail_x + 18.0, safe.end.y - 64.0)
	equip.size = Vector2(detail_width - 36.0, 64.0)
	screen_root.add_child(equip)


func _build_phone_spirit_beast() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.014, 0.016, 0.76))
	_build_phone_header("LINH THÚ HỘ ĐẠO", "Thanh Vân Hồ · khế ước tầng 2 / 5")
	var safe := _phone_safe_rect()
	var body_y := safe.position.y + 76.0
	var body_height := safe.end.y - body_y
	var portrait_width := safe.size.x * 0.39
	ComponentKitScript.panel(screen_root, Rect2(safe.position.x, body_y, portrait_width, body_height), "inventory", Color(0.84, 0.94, 0.90, 0.92))
	var visual := _texture(PORTRAIT_ROOT + "thanh_van_ho.png", Rect2(safe.position.x + 24.0, body_y + 12.0, portrait_width - 48.0, body_height - 136.0))
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.modulate = Color(0.90, 1.05, 1.0, 1.0)
	screen_root.add_child(visual)
	var beast_name := _label("THANH VÂN HỒ", 21, INK, true)
	beast_name.position = Vector2(safe.position.x + 18.0, safe.end.y - 124.0)
	beast_name.size = Vector2(portrait_width - 36.0, 30.0)
	beast_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(beast_name)
	var toggle := _button("THU HỒN" if beast_bound else "KẾT KHẾ ƯỚC", RasterButton.ArtVariant.JADE if beast_bound else RasterButton.ArtVariant.GOLD, Vector2(portrait_width - 50.0, 64.0), 15, func() -> void: _toggle_beast())
	toggle.position = Vector2(safe.position.x + 25.0, safe.end.y - 64.0)
	toggle.size = Vector2(portrait_width - 50.0, 64.0)
	screen_root.add_child(toggle)

	var detail_x := safe.position.x + portrait_width + 14.0
	var detail_width := safe.end.x - detail_x
	var detail := _panel(Rect2(detail_x, body_y, detail_width, body_height), LACQUER_PANEL_PATH, 28)
	screen_root.add_child(detail)
	var tabs := ["TRỢ CHIẾN", "NỘI TẠI", "TIẾN HÓA"]
	for index in tabs.size():
		ComponentKitScript.tab(screen_root, tabs[index], Rect2(detail_x + 16.0 + index * ((detail_width - 44.0) / 3.0), body_y + 8.0, (detail_width - 52.0) / 3.0, 64.0), index == 0, func() -> void: _show_toast("Đang xem %s" % tabs[index]))
	ComponentKitScript.panel(screen_root, Rect2(detail_x + 24.0, body_y + 86.0, 190.0, 190.0), "cooldown", Color(0.80, 1.0, 0.94, 0.90))
	var assist_icon := _texture(str(SKILL_ICON_PATHS["thanh_van_ho"]), Rect2(detail_x + 59.0, body_y + 94.0, 120.0, 120.0))
	assist_icon.modulate = Color(0.94, 1.06, 1.02, 0.94)
	screen_root.add_child(assist_icon)
	var ready := _label("SẴN SÀNG", 18, JADE, true)
	ready.position = Vector2(detail_x + 48.0, body_y + 220.0)
	ready.size = Vector2(142.0, 28.0)
	ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(ready)
	var copy := _label("Đánh dấu mục tiêu nguy hiểm nhất.\nBa lần di chuyển: kỹ năng kế tiếp xuyên mục tiêu và hoàn 12% năng lượng.", 21, PAPER)
	copy.position = Vector2(detail_x + 252.0, body_y + 96.0)
	copy.size = Vector2(detail_width - 284.0, 116.0)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(copy)
	var milestones := ["I · THỨC", "II · DẤU", "III · 120"]
	var milestone_y := safe.end.y - 66.0
	for index in milestones.size():
		var marker_x := detail_x + 246.0 + index * ((detail_width - 276.0) / 3.0)
		var marker_width := (detail_width - 292.0) / 3.0
		ComponentKitScript.panel(screen_root, Rect2(marker_x, milestone_y, marker_width, 56.0), "secondary", Color(0.92, 1.0, 0.96, 0.90) if index < 2 else Color(0.55, 0.58, 0.56, 0.76))
		var milestone := _label(milestones[index], 11, GOLD if index <= 1 else PAPER_DIM, true)
		milestone.position = Vector2(marker_x + 4.0, milestone_y + 12.0)
		milestone.size = Vector2(marker_width - 8.0, 30.0)
		milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		milestone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		screen_root.add_child(milestone)


func _build_phone_techniques() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.012, 0.014, 0.72))
	_build_phone_header("CÔNG PHÁP CÁC", "Mỗi tầng đổi trực tiếp VFX và silhouette")
	var safe := _phone_safe_rect()
	var techniques := _techniques()
	var gap := 8.0
	var card_width := (safe.size.x - gap * 2.0) / 3.0
	for index in mini(techniques.size(), 3):
		var technique: Dictionary = techniques[index]
		var technique_id := StringName(str(technique.get("id", "sword_damage")))
		var rank := int(technique.get("rank", 0))
		var max_rank := int(technique.get("max_rank", 5))
		var cost := int(technique.get("next_cost", -1))
		var x := safe.position.x + index * (card_width + gap)
		var card := _panel(Rect2(x, safe.position.y + 76.0, card_width, safe.size.y - 76.0), LACQUER_PANEL_PATH, 30)
		screen_root.add_child(card)
		var preview := TechniquePreviewScript.new() as TechniquePreview
		preview.position = Vector2(x + 12.0, safe.position.y + 80.0)
		preview.size = Vector2(card_width - 24.0, 126.0)
		preview.configure(technique_id, rank, max_rank, _load_texture(str(TECHNIQUE_ICONS.get(String(technique_id), ICON_SWORD_PATH))))
		screen_root.add_child(preview)
		var school := _label(_technique_school(technique_id), 14, _technique_accent(technique_id), true)
		school.position = Vector2(x + 10.0, safe.position.y + 188.0)
		school.size = Vector2(card_width - 20.0, 22.0)
		school.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(school)
		var name := _label(str(technique.get("name", "Kiếm Tâm")), 18, PAPER, true)
		name.position = Vector2(x + 10.0, safe.position.y + 211.0)
		name.size = Vector2(card_width - 20.0, 28.0)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(name)
		var rank_label := _label("TẦNG %d / %d" % [rank, max_rank], 15, GOLD, true)
		rank_label.position = Vector2(x + 10.0, safe.position.y + 238.0)
		rank_label.size = Vector2(card_width - 20.0, 22.0)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(rank_label)
		var evolution := _label(_phone_technique_evolution_copy(technique_id, rank, max_rank), 14, PAPER_DIM, true)
		evolution.position = Vector2(x + 14.0, safe.position.y + 261.0)
		evolution.size = Vector2(card_width - 28.0, 38.0)
		evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		evolution.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(evolution)
		var price_text := "ĐÃ VIÊN MÃN" if rank >= max_rank else "NÂNG TẦNG · %d LINH NGỌC" % cost
		var purchase := _button(price_text, RasterButton.ArtVariant.GOLD if rank < max_rank else RasterButton.ArtVariant.INK, Vector2(card_width - 16.0, 64.0), 14, func() -> void: _purchase_technique(technique_id))
		purchase.position = Vector2(x + 8.0, safe.end.y - 64.0)
		purchase.size = Vector2(card_width - 16.0, 64.0)
		purchase.disabled = rank >= max_rank
		purchase.call_deferred("_refresh_visual_state")
		screen_root.add_child(purchase)


func _build_phone_codex() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.014, 0.016, 0.70))
	_build_phone_header("VẠN TƯỢNG PHỔ", "Yêu vật từng gặp trên đạo đồ")
	var safe := _phone_safe_rect()
	var entries := _bestiary_entries()
	if entries.is_empty():
		return
	var has_selection := false
	for entry: Dictionary in entries:
		if StringName(str(entry.get("id", ""))) == selected_codex:
			has_selection = true
	if not has_selection:
		selected_codex = StringName(str(entries[0].get("id", "mac_linh")))
	var tab_names := ["MẶC LINH", "MẶC LANG", "TÀ TU", "HUYẾT VỆ", "THIÊN GIÁC"]
	var tab_gap := 6.0
	var tab_width := (safe.size.x - tab_gap * 4.0) / 5.0
	for index in mini(entries.size(), 5):
		var entry: Dictionary = entries[index]
		var entry_id := StringName(str(entry.get("id", "mac_linh")))
		var tab := _button(tab_names[index], RasterButton.ArtVariant.JADE if entry_id == selected_codex else RasterButton.ArtVariant.INK, Vector2(tab_width, 64.0), 14, func() -> void: _select_codex_entry(entry_id))
		tab.position = Vector2(safe.position.x + index * (tab_width + tab_gap), safe.position.y + 76.0)
		tab.size = Vector2(tab_width, 64.0)
		screen_root.add_child(tab)
	var chosen := _bestiary_data(selected_codex)
	var discovered := bool(chosen.get("discovered", false))
	var detail_y := safe.position.y + 146.0
	var detail_height := safe.end.y - detail_y
	var detail := _panel(Rect2(safe.position.x, detail_y, safe.size.x, detail_height), LACQUER_PANEL_PATH, 34)
	screen_root.add_child(detail)
	var visual_path := str(BESTIARY_VISUALS.get(String(selected_codex), ""))
	var visual := _texture(visual_path, Rect2(safe.position.x + 24.0, detail_y + 18.0, 176.0, detail_height - 36.0))
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.modulate = Color.WHITE if discovered else Color(0.05, 0.07, 0.07, 0.88)
	screen_root.add_child(visual)
	var text_x := safe.position.x + 226.0
	var heading := _label(str(chosen.get("name", "Chưa ghi nhận")) if discovered else "BÓNG HÌNH CHƯA BIẾT", 24, PAPER, true)
	heading.position = Vector2(text_x, detail_y + 18.0)
	heading.size = Vector2(safe.end.x - text_x - 24.0, 34.0)
	screen_root.add_child(heading)
	var kind := _label(("%s · %s" % [str(chosen.get("kind", "")), str(chosen.get("habitat", ""))]) if discovered else "Tiếp cận thí luyện để khai mở", 15, GOLD, true)
	kind.position = Vector2(text_x, detail_y + 52.0)
	kind.size = Vector2(safe.end.x - text_x - 24.0, 24.0)
	screen_root.add_child(kind)
	var description := _label(str(chosen.get("description", "Dữ liệu còn bị ma vụ che phủ.")) if discovered else "Trang phổ này chưa được khai mở. Vượt thí luyện tương ứng để ghi nhận hình ảnh và tập tính.", 16, PAPER_DIM)
	description.position = Vector2(text_x, detail_y + 82.0)
	description.size = Vector2(safe.end.x - text_x - 24.0, 58.0)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(description)
	var threat := _label("HIỂM HỌA CẤP %d/3  ·  YẾU QUYẾT" % int(chosen.get("threat", 0)) if discovered else "HIỂM HỌA  ? ? ?  ·  YẾU QUYẾT", 14, CRIMSON if discovered else PAPER_DIM, true)
	threat.position = Vector2(text_x, detail_y + detail_height - 72.0)
	threat.size = Vector2(safe.end.x - text_x - 24.0, 22.0)
	screen_root.add_child(threat)
	var combat_tip := _label(str(chosen.get("combat_tip", "???")) if discovered else "Tiếp cận thí luyện để ghi nhận yếu quyết.", 14, PAPER_DIM)
	combat_tip.position = Vector2(text_x, detail_y + detail_height - 49.0)
	combat_tip.size = Vector2(safe.end.x - text_x - 24.0, 38.0)
	combat_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(combat_tip)


func _build_phone_achievements() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.014, 0.016, 0.72))
	_build_phone_header("THIÊN MỆNH LỤC", "Dấu mốc được khắc vào hồ sơ")
	var safe := _phone_safe_rect()
	var achievements := _achievement_entries()
	var gap_x := 8.0
	var gap_y := 8.0
	var card_width := (safe.size.x - gap_x * 2.0) / 3.0
	var card_height := (safe.size.y - 84.0 - gap_y) / 2.0
	for index in mini(achievements.size(), 6):
		var achievement: Dictionary = achievements[index]
		var col := index % 3
		var row := index / 3
		var unlocked := bool(achievement.get("unlocked", false))
		var x := safe.position.x + col * (card_width + gap_x)
		var y := safe.position.y + 76.0 + row * (card_height + gap_y)
		var card := _panel(Rect2(x, y, card_width, card_height), LACQUER_PANEL_PATH, 28)
		card.modulate = Color.WHITE if unlocked else Color(0.68, 0.68, 0.65, 0.96)
		screen_root.add_child(card)
		var achievement_id := str(achievement.get("id", "nhap_dao"))
		var seal_path := str(ACHIEVEMENT_SEALS.get(achievement_id, ICON_SWORD_PATH))
		var seal := _texture(seal_path, Rect2(x + 14.0, y + 36.0, 60.0, 60.0))
		seal.modulate = Color.WHITE if unlocked else Color(0.26, 0.29, 0.28, 0.72)
		screen_root.add_child(seal)
		var state := _label("ĐÃ KHẮC ẤN" if unlocked else "CHƯA KHẮC ẤN", 14, GOLD if unlocked else PAPER_DIM, true)
		state.position = Vector2(x + 80.0, y + 22.0)
		state.size = Vector2(card_width - 92.0, 22.0)
		screen_root.add_child(state)
		var title := _label(str(achievement.get("name", "Thiên mệnh")), 15, PAPER, true)
		title.position = Vector2(x + 80.0, y + 49.0)
		title.size = Vector2(card_width - 92.0, 42.0)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		screen_root.add_child(title)
		var progress_data: Dictionary = achievement.get("progress", {}) as Dictionary
		var current := int(float(progress_data.get("current", 0.0)))
		var target := int(float(progress_data.get("target", 1.0)))
		var progress_text := "HOÀN TẤT" if unlocked else "%d / %d" % [current, target]
		var progress_label := _label(progress_text, 15, JADE if unlocked else PAPER_DIM, true)
		progress_label.position = Vector2(x + 80.0, y + card_height - 35.0)
		progress_label.size = Vector2(card_width - 92.0, 24.0)
		screen_root.add_child(progress_label)


func _build_phone_settings() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.014, 0.016, 0.72))
	_build_phone_header("THIẾT LẬP", "ÂM THANH · TRỢ NĂNG · HỒ SƠ")
	var safe := _phone_safe_rect()
	var body := Rect2(safe.position.x, safe.position.y + 76.0, safe.size.x, safe.size.y - 76.0)
	var backdrop := _panel(body, LACQUER_PANEL_PATH, 34)
	screen_root.add_child(backdrop)
	# Phone settings use one authored lacquer folio with two editorial columns.
	# Every action remains visible at 844x390; there is no hidden footer or
	# screenshot-only scroll state to confuse touch users.
	var audio_width := floorf(body.size.x * 0.57)
	var divider := ColorRect.new()
	divider.position = Vector2(body.position.x + audio_width, body.position.y + 14.0)
	divider.size = Vector2(1.0, body.size.y - 92.0)
	divider.color = Color(GOLD, 0.30)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(divider)
	var settings := _settings()
	var rows := [
		{"id": &"master", "name": "ÂM LƯỢNG TỔNG"},
		{"id": &"music", "name": "NHẠC NỀN"},
		{"id": &"sfx", "name": "HIỆU ỨNG"},
	]
	for index in rows.size():
		var row: Dictionary = rows[index]
		var y := body.position.y + 8.0 + index * 70.0
		var title := _label(str(row.get("name", "Âm lượng")), 16, PAPER, true)
		title.position = Vector2(body.position.x + 24.0, y + 17.0)
		title.size = Vector2(176.0, 28.0)
		screen_root.add_child(title)
		var setting_id := StringName(str(row.get("id", "master")))
		var minus := _button("−", RasterButton.ArtVariant.INK, Vector2(64.0, 64.0), 24, func() -> void: _nudge_volume(setting_id, -0.10))
		minus.position = Vector2(body.position.x + 202.0, y)
		minus.size = Vector2(64.0, 64.0)
		screen_root.add_child(minus)
		var value := int(round(float(settings.get(setting_id, 0.8)) * 100.0))
		var value_label := _label("%d%%" % value, 17, GOLD, true)
		value_label.position = Vector2(body.position.x + 266.0, y)
		value_label.size = Vector2(70.0, 64.0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		screen_root.add_child(value_label)
		var plus := _button("+", RasterButton.ArtVariant.JADE, Vector2(64.0, 64.0), 24, func() -> void: _nudge_volume(setting_id, 0.10))
		plus.position = Vector2(body.position.x + 336.0, y)
		plus.size = Vector2(64.0, 64.0)
		screen_root.add_child(plus)
	var toggle_rows := [
		{"id": &"reduced_motion", "name": "GIẢM CHUYỂN ĐỘNG", "enabled": bool(settings.get("reduced_motion", false))},
		{"id": &"screen_shake", "name": "RUNG MÀN HÌNH", "enabled": bool(settings.get("screen_shake", true))},
	]
	var right_x := body.position.x + audio_width + 18.0
	var right_width := body.end.x - right_x - 18.0
	for index in toggle_rows.size():
		var row: Dictionary = toggle_rows[index]
		var y := body.position.y + 8.0 + index * 70.0
		var title := _label(str(row.get("name", "Tùy chọn")), 13, PAPER, true)
		title.position = Vector2(right_x, y + 17.0)
		title.size = Vector2(145.0, 28.0)
		screen_root.add_child(title)
		var enabled := bool(row.get("enabled", false))
		var setting_id := StringName(str(row.get("id", "reduced_motion")))
		var toggle := _button("ĐANG BẬT" if enabled else "ĐANG TẮT", RasterButton.ArtVariant.JADE if enabled else RasterButton.ArtVariant.INK, Vector2(right_width - 150.0, 64.0), 14, func() -> void: _toggle_setting(setting_id, not enabled))
		toggle.position = Vector2(right_x + 150.0, y)
		toggle.size = Vector2(right_width - 150.0, 64.0)
		screen_root.add_child(toggle)
	var profile_caption := _label("HỒ SƠ ĐẠO ĐỒ", 13, GOLD, true)
	profile_caption.position = Vector2(right_x, body.position.y + 154.0)
	profile_caption.size = Vector2(right_width, 22.0)
	screen_root.add_child(profile_caption)
	var profile_copy := _label("%d lần nhập thế · %d chiến thắng\nCông lực %d · %d Linh Ngọc" % [_profile_value("runs", 0), _profile_value("victories", 0), _account_power(), _profile_value("currency", 0)], 13, PAPER_DIM)
	profile_copy.position = Vector2(right_x, body.position.y + 178.0)
	profile_copy.size = Vector2(right_width, 44.0)
	profile_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(profile_copy)
	var footer_y := body.end.y - 64.0
	var footer_width := (body.size.x - 32.0) / 3.0
	var title_button := _button("MÀN HÌNH CHÍNH", RasterButton.ArtVariant.INK, Vector2(footer_width, 64.0), 14, func() -> void: _show_screen(SCREEN_TITLE))
	title_button.position = Vector2(body.position.x + 8.0, footer_y)
	title_button.size = Vector2(footer_width, 64.0)
	screen_root.add_child(title_button)
	var reset_button := _button("XÓA HỒ SƠ", RasterButton.ArtVariant.CRIMSON, Vector2(footer_width, 64.0), 14, _show_reset_confirmation)
	reset_button.position = Vector2(body.position.x + 16.0 + footer_width, footer_y)
	reset_button.size = Vector2(footer_width, 64.0)
	screen_root.add_child(reset_button)
	var back_button := _button("VỀ SƠN MÔN", RasterButton.ArtVariant.GOLD, Vector2(footer_width, 64.0), 14, func() -> void: _show_screen(SCREEN_HUB))
	back_button.position = Vector2(body.position.x + 24.0 + footer_width * 2.0, footer_y)
	back_button.size = Vector2(footer_width, 64.0)
	screen_root.add_child(back_button)


func _build_phone_results() -> void:
	var result_glaze := Color(0.015, 0.008, 0.008, 0.78) if not last_victory else Color(0.006, 0.016, 0.014, 0.70)
	_set_background(str(STAGE_ART.get(String(_selected_stage()), STAGE_ART["van_mong"])), result_glaze)
	var safe := _phone_safe_rect()
	var panel := _panel(safe, LACQUER_PANEL_PATH, 38)
	panel.modulate = Color.WHITE if last_victory else Color(0.92, 0.72, 0.70, 1.0)
	screen_root.add_child(panel)
	var result_color := GOLD if last_victory else CRIMSON
	var eyebrow := _label("THÍ LUYỆN KẾT THÚC", 15, result_color, true)
	eyebrow.position = Vector2(safe.position.x + 40.0, safe.position.y + 25.0)
	eyebrow.size = Vector2(safe.size.x - 80.0, 24.0)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(eyebrow)
	var heading := _label(last_result_title, 29, result_color, true)
	heading.position = Vector2(safe.position.x + 30.0, safe.position.y + 44.0)
	heading.size = Vector2(safe.size.x - 60.0, 42.0)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(heading)
	var stage := _stage_data(_selected_stage())
	var stage_name := _label(str(stage.get("name", "Vân Mộng Cốc")), 16, JADE if last_victory else PAPER_DIM, true)
	stage_name.position = Vector2(safe.position.x + 40.0, safe.position.y + 88.0)
	stage_name.size = Vector2(safe.size.x - 80.0, 24.0)
	stage_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(stage_name)
	var stat_captions := ["THỜI GIAN", "TRẢM YÊU", "LINH NGỌC"]
	var stat_values := [_format_time(run_elapsed), str(run_kills), "+%d LINH NGỌC" % int(last_result.get("total", 0))]
	var stat_width := (safe.size.x - 84.0) / 3.0
	for index in 3:
		var x := safe.position.x + 34.0 + index * (stat_width + 8.0)
		var stat := _surface(Rect2(x, safe.position.y + 120.0, stat_width, 78.0), Color(0.01, 0.025, 0.027, 0.78), Color(result_color, 0.44), 1)
		screen_root.add_child(stat)
		var caption := _label(stat_captions[index], 14, PAPER_DIM, true)
		caption.position = Vector2(x + 8.0, safe.position.y + 128.0)
		caption.size = Vector2(stat_width - 16.0, 22.0)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(caption)
		var value := _label(stat_values[index], 22, result_color, true)
		value.position = Vector2(x + 8.0, safe.position.y + 151.0)
		value.size = Vector2(stat_width - 16.0, 34.0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(value)
	var reward_lines: Array[String] = []
	if bool(last_result.get("first_clear", false)):
		reward_lines.append("PHÁ CẢNH LẦN ĐẦU +%d" % int(last_result.get("first_clear_bonus", 0)))
	if not (last_result.get("new_unlocks", []) as Array).is_empty():
		reward_lines.append("CẢNH GIỚI MỚI ĐÃ KHAI MỞ")
	if reward_lines.is_empty():
		reward_lines.append("CĂN CƠ ĐÃ ĐƯỢC GHI VÀO HỒ SƠ")
	var reward := _label("  ·  ".join(reward_lines), 15, result_color, true)
	reward.position = Vector2(safe.position.x + 40.0, safe.position.y + 210.0)
	reward.size = Vector2(safe.size.x - 80.0, 26.0)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(reward)
	var details := _label(last_result_details, 15, PAPER_DIM)
	details.position = Vector2(safe.position.x + 70.0, safe.position.y + 240.0)
	details.size = Vector2(safe.size.x - 140.0, 46.0)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(details)
	var hub := _button("TRỞ VỀ SƠN MÔN", RasterButton.ArtVariant.GOLD if last_victory else RasterButton.ArtVariant.INK, Vector2(320.0, 64.0), 16, _return_to_hub)
	hub.position = Vector2(safe.position.x + 74.0, safe.end.y - 70.0)
	hub.size = Vector2(320.0, 64.0)
	screen_root.add_child(hub)
	var retry := _button("THỬ LẠI", RasterButton.ArtVariant.JADE if last_victory else RasterButton.ArtVariant.CRIMSON, Vector2(250.0, 64.0), 16, _retry_run)
	retry.position = Vector2(safe.end.x - 324.0, safe.end.y - 70.0)
	retry.size = Vector2(250.0, 64.0)
	screen_root.add_child(retry)


func _build_title() -> void:
	_set_background(TITLE_ART_PATH, Color(0.01, 0.02, 0.02, 0.08))
	var vignette_gradient := Gradient.new()
	vignette_gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	vignette_gradient.colors = PackedColorArray([
		Color(0.015, 0.025, 0.026, 0.30),
		Color(0.015, 0.025, 0.026, 0.26),
		Color(0.015, 0.025, 0.026, 0.0),
	])
	var vignette_texture := GradientTexture2D.new()
	vignette_texture.gradient = vignette_gradient
	vignette_texture.width = 900
	vignette_texture.height = 1
	vignette_texture.fill_from = Vector2(0.0, 0.5)
	vignette_texture.fill_to = Vector2(1.0, 0.5)
	var left_vignette := TextureRect.new()
	left_vignette.position = Vector2.ZERO
	left_vignette.size = Vector2(900.0, 900.0)
	left_vignette.texture = vignette_texture
	left_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	left_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(left_vignette)

	# This is a fixed-ratio ritual object, not a stretchable dashboard panel.
	# Keep the complete scroll silhouette and constrain live text to its quiet
	# paper field so no label or control collides with rollers and tassels.
	var frame := _ritual_surface(Rect2(40.0, 30.0, 500.0, 840.0), "title_scroll", Color(0.98, 0.96, 0.88, 1.0), false)
	screen_root.add_child(frame)
	# The authored top roller and jade crest occupy the first ~120 px. Keep live
	# copy below that hardware instead of placing the eyebrow on the ornament.
	var content := _margin(frame, 102, 102, 132, 84)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 7)
	content.add_child(column)

	# The scroll crest is the sect signature; reserve this band as breathing room
	# rather than duplicating a label across the authored hardware.
	column.add_child(_space(28.0))
	var title := _label("VÂN MỘNG\nTU TIÊN", 44, PAPER_INK, true)
	title.custom_minimum_size = Vector2(286.0, 112.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := _label("NHẤT NIỆM NHẬP ĐẠO\nVẠN KIẾM HỘ THÂN", 14, Color("#2f7469"), true)
	subtitle.custom_minimum_size = Vector2(286.0, 42.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	column.add_child(_space(10.0))
	var lore := _label("Tà khí tràn khỏi thiên môn. Trở về sơn môn, chọn công pháp và bước qua ba tầng thí luyện để định lại đạo đồ.", 15, PAPER_COPY)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore.custom_minimum_size = Vector2(286.0, 78.0)
	column.add_child(lore)
	column.add_child(_space(2.0))

	var continue_text := "TIẾP TỤC ĐẠO ĐỒ" if _profile_value("runs", 0) > 0 else "NHẬP MÔN"
	column.add_child(_button(continue_text, RasterButton.ArtVariant.GOLD, Vector2(286.0, 64.0), 18, func() -> void: _show_screen(SCREEN_HUB)))
	column.add_child(_button("THIẾT LẬP", RasterButton.ArtVariant.INK, Vector2(286.0, 64.0), 15, func() -> void: _show_screen(SCREEN_SETTINGS)))
	column.add_child(_button("RỜI KHỎI SƠN MÔN", RasterButton.ArtVariant.INK, Vector2(286.0, 64.0), 15, _quit_game))
	var foot := _label("WASD / MŨI TÊN · DI CHUYỂN\nENTER / A · XÁC NHẬN    ESC / B · QUAY LẠI", 14, Color(PAPER_COPY, 0.82))
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.custom_minimum_size = Vector2(286.0, 40.0)
	# Keep input help live-rendered but outside the scroll's lower bronze roller;
	# the roller is authored hardware and must never compete with critical copy.
	foot.position = Vector2(600.0, 824.0)
	foot.size = Vector2(520.0, 42.0)
	foot.z_index = 3
	foot.add_theme_color_override("font_color", Color("#253536"))
	foot.add_theme_color_override("font_outline_color", Color(0.91, 0.88, 0.78, 0.72))
	foot.add_theme_constant_override("outline_size", 2)
	screen_root.add_child(foot)

	var edition := _label("BẢN HÀNH TRÌNH · GODOT 4.4", 11, Color(INK, 0.68), true)
	edition.position = Vector2(1275.0, 848.0)
	edition.size = Vector2(280.0, 28.0)
	edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(edition)


func _build_hub() -> void:
	_set_background(HUB_ART_PATH, Color(0.006, 0.016, 0.018, 0.28))
	_add_directional_vignette(false)
	# Open editorial type, one expedition dossier and an unboxed ritual replace
	# the former web-dashboard header/rail/slab composition.
	var heading := _label("SƠN MÔN VÂN MỘNG", 31, PAPER, true)
	heading.position = Vector2(72.0, 46.0)
	heading.size = Vector2(620.0, 44.0)
	screen_root.add_child(heading)
	var record := _label("NGOẠI VIỆN · NGÀY %d     THẮNG %d · TRẢM %d · CÔNG LỰC %d" % [
		maxi(1, _profile_value("runs", 0) + 1), _profile_value("victories", 0), _profile_value("kills", 0), _account_power()
	], 14, PAPER_DIM, true)
	record.position = Vector2(74.0, 92.0)
	record.size = Vector2(740.0, 28.0)
	screen_root.add_child(record)
	var currency := _label("%d  LINH NGỌC" % _profile_value("currency", 0), 20, GOLD, true)
	currency.position = Vector2(1260.0, 54.0)
	currency.size = Vector2(270.0, 34.0)
	currency.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(currency)
	var title_rule := ColorRect.new()
	title_rule.position = Vector2(74.0, 124.0)
	title_rule.size = Vector2(1452.0, 1.0)
	title_rule.color = Color(GOLD, 0.38)
	title_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(title_rule)

	var doctrine := _discipline_data(_selected_discipline())
	var discipline_key := _discipline_technique_key(_selected_discipline())
	var ranks: Dictionary = _profile_snapshot().get("technique_ranks", {}) as Dictionary
	var current_rank := int(ranks.get(String(discipline_key), ranks.get(discipline_key, 0)))
	var ritual := TechniquePreviewScript.new() as TechniquePreview
	ritual.position = Vector2(52.0, 150.0)
	ritual.size = Vector2(420.0, 404.0)
	ritual.configure(discipline_key, current_rank, 5, _load_texture(str(DISCIPLINE_ICONS.get(String(_selected_discipline()), ICON_SWORD_PATH))))
	screen_root.add_child(ritual)
	var equipped_caption := _label("—  TÂM PHÁP HỘ THÂN  —", 13, Color(JADE, 0.90), true)
	equipped_caption.position = Vector2(94.0, 490.0)
	equipped_caption.size = Vector2(336.0, 28.0)
	equipped_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(equipped_caption)
	var equipped_name := _label(str(doctrine.get("name", "Vạn Kiếm Quy Tông")), 24, PAPER, true)
	equipped_name.position = Vector2(72.0, 530.0)
	equipped_name.size = Vector2(380.0, 42.0)
	equipped_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(equipped_name)
	var doctrine_copy := _label(str(doctrine.get("description", "")), 15, PAPER_DIM)
	doctrine_copy.position = Vector2(92.0, 582.0)
	doctrine_copy.size = Vector2(340.0, 72.0)
	doctrine_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	doctrine_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(doctrine_copy)
	var change_loadout := _button("ĐỔI TÂM PHÁP", RasterButton.ArtVariant.INK, Vector2(318.0, 64.0), 15, func() -> void: _show_screen(SCREEN_LOADOUT))
	change_loadout.position = Vector2(103.0, 688.0)
	change_loadout.size = Vector2(318.0, 64.0)
	screen_root.add_child(change_loadout)

	var selected_stage := _selected_stage()
	var stage := _stage_data(selected_stage)
	var expedition := _panel(Rect2(492.0, 148.0, 626.0, 668.0), LACQUER_PANEL_PATH, 52)
	screen_root.add_child(expedition)
	var stage_preview := _texture(str(STAGE_ART.get(String(selected_stage), STAGE_ART["van_mong"])), Rect2(530.0, 186.0, 550.0, 308.0))
	stage_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	screen_root.add_child(stage_preview)
	var eyebrow := _label("THÍ LUYỆN ĐANG CHỌN", 12, GOLD, true)
	eyebrow.position = Vector2(550.0, 522.0)
	eyebrow.size = Vector2(510.0, 26.0)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(eyebrow)
	var stage_name := _label(str(stage.get("name", "Vân Mộng Cốc")), 29, PAPER, true)
	stage_name.position = Vector2(550.0, 558.0)
	stage_name.size = Vector2(510.0, 44.0)
	stage_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(stage_name)
	var stage_copy := _label(str(stage.get("description", "")), 15, PAPER_DIM)
	stage_copy.position = Vector2(558.0, 612.0)
	stage_copy.size = Vector2(494.0, 64.0)
	stage_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(stage_copy)
	var depart := _button("KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(286.0, 66.0), 18, func() -> void: _show_screen(SCREEN_LOADOUT))
	depart.position = Vector2(548.0, 720.0)
	depart.size = Vector2(286.0, 64.0)
	screen_root.add_child(depart)
	var choose_stage := _button("ĐỔI CẢNH", RasterButton.ArtVariant.INK, Vector2(202.0, 66.0), 15, func() -> void: _show_screen(SCREEN_STAGES))
	choose_stage.position = Vector2(862.0, 720.0)
	choose_stage.size = Vector2(202.0, 64.0)
	screen_root.add_child(choose_stage)

	var command_caption := _label("—  ĐẠO LỆNH SƠN MÔN  —", 13, GOLD, true)
	command_caption.position = Vector2(1180.0, 158.0)
	command_caption.size = Vector2(346.0, 28.0)
	command_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(command_caption)
	var commands := [
		["01   HÀNH TRÌNH", RasterButton.ArtVariant.GOLD, func() -> void: _show_screen(SCREEN_STAGES)],
		["02   CÔNG PHÁP", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_TECHNIQUES)],
		["03   PHÁP BẢO", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_INVENTORY)],
		["04   LINH THÚ", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_SPIRIT_BEAST)],
		["05   VẠN TƯỢNG PHỔ", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_CODEX)],
		["06   THÀNH TỰU", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_ACHIEVEMENTS)],
		["07   THIẾT LẬP", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_SETTINGS)],
	]
	for index in commands.size():
		var command: Array = commands[index]
		var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(346.0, 64.0), 16, command[2] as Callable)
		button.position = Vector2(1180.0, 202.0 + index * 76.0)
		button.size = Vector2(346.0, 64.0)
		screen_root.add_child(button)
	var guidance := _label("Trang bị, công pháp và linh thú đều nối vào cùng một loadout trước khi nhập cảnh.", 13, Color(PAPER_DIM, 0.74))
	guidance.position = Vector2(1202.0, 748.0)
	guidance.size = Vector2(302.0, 54.0)
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(guidance)


func _build_stage_select() -> void:
	var current_id := _selected_stage()
	_set_background(str(STAGE_ART.get(String(current_id), STAGE_ART["van_mong"])), Color(0.01, 0.02, 0.02, 0.40))
	_build_top_bar("CHỌN THÍ LUYỆN", "Ba cảnh giới · Ba tầng ma kiếp", true)
	var stages := _stages()
	var xs := [54.0, 544.0, 1034.0]
	for index in mini(stages.size(), 3):
		var stage: Dictionary = stages[index]
		var stage_id := StringName(str(stage.get("id", "van_mong")))
		var unlocked := bool(stage.get("unlocked", false))
		var selected := stage_id == current_id
		var card := _panel(Rect2(xs[index], 126.0, 456.0, 640.0), TALISMAN_CARD_PATH, 54)
		card.modulate = Color(1.08, 1.05, 0.92, 1.0) if selected else (Color.WHITE if unlocked else Color(0.80, 0.80, 0.76, 0.96))
		screen_root.add_child(card)

		var art_path := str(STAGE_ART.get(String(stage_id), STAGE_ART["van_mong"]))
		var preview := _texture(art_path, Rect2(xs[index] + 64.0, 188.0, 328.0, 176.0))
		preview.modulate = Color.WHITE if unlocked else Color(0.46, 0.43, 0.42, 0.90)
		screen_root.add_child(preview)
		var badge := _label("ĐÃ CHỌN" if selected else str(stage.get("eyebrow", "THÍ LUYỆN")).to_upper(), 12, Color("#f5dfaa") if unlocked else Color("#a9473e"), true)
		badge.position = Vector2(xs[index] + 77.0, 151.0)
		badge.size = Vector2(302.0, 28.0)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(badge)
		var title := _label(str(stage.get("name", "Vân Mộng Cốc")), 25, Color("#382719"), true)
		title.position = Vector2(xs[index] + 55.0, 382.0)
		title.size = Vector2(346.0, 42.0)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(title)
		var difficulty := int(stage.get("difficulty", index + 1))
		var threat := _label("HIỂM HỌA  CẤP %d/3" % difficulty, 15, Color("#8d3f32"), true)
		threat.position = Vector2(xs[index] + 73.0, 430.0)
		threat.size = Vector2(310.0, 30.0)
		threat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(threat)
		var description := _label(str(stage.get("description", "")), 15, Color("#504235"))
		description.position = Vector2(xs[index] + 62.0, 472.0)
		description.size = Vector2(332.0, 92.0)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size = Vector2(332.0, 92.0)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(description)
		var reward_data: Dictionary = stage.get("rewards", {}) as Dictionary
		var reward := _label("THƯỞNG  %d+ LINH NGỌC" % int(reward_data.get("base", 30)), 13, Color("#765326"), true)
		reward.position = Vector2(xs[index] + 80.0, 566.0)
		reward.size = Vector2(296.0, 26.0)
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(reward)

		var button_text := "ĐANG CHỌN" if selected else ("CHỌN CẢNH" if unlocked else "CHƯA KHAI MỞ")
		var choose := _button(button_text, RasterButton.ArtVariant.JADE if selected else RasterButton.ArtVariant.INK, Vector2(292.0, 56.0), 15, func() -> void: _select_stage(stage_id))
		choose.position = Vector2(xs[index] + 82.0, 625.0)
		choose.size = Vector2(292.0, 56.0)
		choose.disabled = not unlocked
		choose.call_deferred("_refresh_visual_state")
		screen_root.add_child(choose)
		if not unlocked:
			var unlock_data: Dictionary = stage.get("unlock", {}) as Dictionary
			var lock_copy := _label(str(unlock_data.get("description", "Cần hoàn thành cảnh trước")), 12, Color("#6c3b34"), true)
			lock_copy.position = Vector2(xs[index] + 78.0, 690.0)
			lock_copy.size = Vector2(300.0, 38.0)
			lock_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lock_copy.size = Vector2(300.0, 38.0)
			screen_root.add_child(lock_copy)

	var proceed := _button("CHUẨN BỊ CÔNG PHÁP", RasterButton.ArtVariant.GOLD, Vector2(420.0, 70.0), 18, func() -> void: _show_screen(SCREEN_LOADOUT))
	proceed.position = Vector2(590.0, 782.0)
	proceed.size = Vector2(420.0, 70.0)
	screen_root.add_child(proceed)


func _build_loadout() -> void:
	var stage := _stage_data(_selected_stage())
	_set_background(str(STAGE_ART.get(String(_selected_stage()), HUB_ART_PATH)), Color(0.01, 0.02, 0.02, 0.46))
	_build_top_bar("CHỌN TÂM PHÁP", "%s · Công lực tài khoản %d" % [str(stage.get("name", "Vân Mộng Cốc")), _account_power()], true)
	var disciplines := _disciplines()
	var selected := _selected_discipline()
	var xs := [112.0, 594.0, 1076.0]
	for index in mini(disciplines.size(), 3):
		var discipline: Dictionary = disciplines[index]
		var discipline_id := StringName(str(discipline.get("id", "van_kiem")))
		var is_selected := discipline_id == selected
		var card := _panel(Rect2(xs[index], 150.0, 412.0, 568.0), TALISMAN_CARD_PATH, 54)
		card.modulate = Color(1.10, 1.06, 0.90, 1.0) if is_selected else Color.WHITE
		screen_root.add_child(card)
		var icon := _texture(str(DISCIPLINE_ICONS.get(String(discipline_id), ICON_SWORD_PATH)), Rect2(xs[index] + 106.0, 187.0, 200.0, 200.0))
		screen_root.add_child(icon)
		var role := _label(str(discipline.get("role", "Công kích")).to_upper(), 13, Color("#8c5b2e"), true)
		role.position = Vector2(xs[index] + 74.0, 390.0)
		role.size = Vector2(264.0, 26.0)
		role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(role)
		var name_label := _label(str(discipline.get("name", "Vạn Kiếm Quy Tông")), 23, Color("#382719"), true)
		name_label.position = Vector2(xs[index] + 48.0, 422.0)
		name_label.size = Vector2(316.0, 60.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.size = Vector2(316.0, 60.0)
		screen_root.add_child(name_label)
		var description := _label(str(discipline.get("description", "")), 15, Color("#55483a"))
		description.position = Vector2(xs[index] + 58.0, 492.0)
		description.size = Vector2(296.0, 104.0)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size = Vector2(296.0, 104.0)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(description)
		var state_label := "ĐÃ TRANG BỊ" if is_selected else "TRANG BỊ"
		var equip := _button(state_label, RasterButton.ArtVariant.JADE if is_selected else RasterButton.ArtVariant.INK, Vector2(270.0, 58.0), 15, func() -> void: _select_discipline(discipline_id))
		equip.position = Vector2(xs[index] + 71.0, 620.0)
		equip.size = Vector2(270.0, 58.0)
		screen_root.add_child(equip)

	var summary := _panel(Rect2(332.0, 734.0, 936.0, 104.0), TAB_FRAME_PATH, 44)
	screen_root.add_child(summary)
	var summary_text := _label("%s  ·  %s  ·  Hiểm họa %d/3" % [
		str(stage.get("name", "Vân Mộng Cốc")),
		str(_discipline_data(_selected_discipline()).get("name", "Vạn Kiếm Quy Tông")),
		int(stage.get("difficulty", 1)),
	], 17, PAPER, true)
	summary_text.position = Vector2(402.0, 750.0)
	summary_text.size = Vector2(508.0, 68.0)
	summary_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen_root.add_child(summary_text)
	var start := _button("NHẬP CẢNH", RasterButton.ArtVariant.GOLD, Vector2(292.0, 62.0), 19, _start_selected_run)
	start.position = Vector2(934.0, 755.0)
	start.size = Vector2(292.0, 62.0)
	screen_root.add_child(start)


func _build_inventory() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.014, 0.016, 0.70))
	_add_directional_vignette(false)
	_build_top_bar("KHO PHÁP BẢO", "Trang bị · so sánh · khóa vật phẩm · Huyền Thiết", true)

	# Left: a quiet character dossier. The arsenal atlas supplies the material
	# family while the hero and stats remain live nodes.
	var dossier := _panel(Rect2(48.0, 142.0, 360.0, 694.0), LACQUER_PANEL_PATH, 44)
	screen_root.add_child(dossier)
	ComponentKitScript.panel(screen_root, Rect2(62.0, 156.0, 332.0, 110.0), "command", Color(0.78, 0.88, 0.84, 0.40))
	var dossier_title := _label("ĐẠO ĐỒ HIỆN TẠI", 13, GOLD, true)
	dossier_title.position = Vector2(84.0, 174.0)
	dossier_title.size = Vector2(284.0, 24.0)
	dossier_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(dossier_title)
	var hero := _texture("res://assets/generated/runtime/player_idle.png", Rect2(122.0, 220.0, 210.0, 250.0))
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.modulate = Color(0.95, 1.0, 0.97, 1.0)
	screen_root.add_child(hero)
	var hero_name := _label("KIẾM TU VÂN MỘNG", 21, PAPER, true)
	hero_name.position = Vector2(80.0, 480.0)
	hero_name.size = Vector2(296.0, 32.0)
	hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(hero_name)
	var hero_meta := _label("Công lực %d  ·  %s" % [_account_power(), str(_discipline_data(_selected_discipline()).get("short_name", "Vạn Kiếm"))], 14, JADE, true)
	hero_meta.position = Vector2(80.0, 514.0)
	hero_meta.size = Vector2(296.0, 24.0)
	hero_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(hero_meta)
	var slots_caption := _label("BỐN VỊ TRÍ TRẤN PHÁP", 11, PAPER_DIM, true)
	slots_caption.position = Vector2(80.0, 558.0)
	slots_caption.size = Vector2(296.0, 22.0)
	slots_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(slots_caption)
	var equipped := _inventory_items()
	for index in mini(equipped_item_ids.size(), 4):
		var item_id := str(equipped_item_ids[index])
		var item := _item_by_id(item_id)
		var col := index % 2
		var row := index / 2
		var icon := _load_texture(str(item.get("icon_path", ICON_SWORD_PATH)))
		ComponentKitScript.item_slot(screen_root, item_id, str(item.get("name", "Pháp bảo")), str(item.get("rarity", "Linh")), Rect2(76.0 + col * 150.0, 590.0 + row * 118.0, 136.0, 108.0), icon, item_id == selected_item_id, func() -> void: _select_inventory_item(item_id))

	# Middle: the actual inventory grid, dense like the reference but with a
	# readable 4-column rhythm and explicit empty space around each item.
	var inventory_panel := _panel(Rect2(426.0, 142.0, 650.0, 694.0), LACQUER_PANEL_PATH, 44)
	screen_root.add_child(inventory_panel)
	ComponentKitScript.panel(screen_root, Rect2(450.0, 156.0, 602.0, 76.0), "secondary", Color(0.88, 0.96, 0.92, 0.55))
	var inventory_caption := _label("TÚI CÀN KHÔN", 16, PAPER, true)
	inventory_caption.position = Vector2(478.0, 176.0)
	inventory_caption.size = Vector2(280.0, 28.0)
	screen_root.add_child(inventory_caption)
	var inventory_meta := _label("12 / 36  ·  SẮP XẾP: RARITY", 12, JADE, true)
	inventory_meta.position = Vector2(760.0, 180.0)
	inventory_meta.size = Vector2(250.0, 24.0)
	inventory_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(inventory_meta)
	var tabs := ["TẤT CẢ", "PHÁP KIẾM", "HỘ THÂN", "TẠP VẬT"]
	for index in tabs.size():
		ComponentKitScript.tab(screen_root, tabs[index], Rect2(468.0 + index * 139.0, 246.0, 132.0, 48.0), index == 0, func() -> void: _show_toast("Bộ lọc %s" % tabs[index]))
	var items := _inventory_items()
	for index in items.size():
		var item: Dictionary = items[index]
		var col := index % 4
		var row := index / 4
		var item_id := str(item.get("id", "item_%d" % index))
		ComponentKitScript.item_slot(screen_root, item_id, str(item.get("name", "Pháp bảo")), str(item.get("rarity", "Linh")), Rect2(468.0 + col * 142.0, 310.0 + row * 156.0, 132.0, 146.0), _load_texture(str(item.get("icon_path", ICON_SWORD_PATH))), item_id == selected_item_id, func() -> void: _select_inventory_item(item_id))
	var sort_label := _label("KÉO CHỌN · CLICK ĐỂ SO SÁNH · SHIFT KHÓA", 11, PAPER_DIM, true)
	sort_label.position = Vector2(474.0, 790.0)
	sort_label.size = Vector2(560.0, 24.0)
	sort_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(sort_label)

	# Right: comparison tooltip with before/after bars and one deliberate action.
	var detail := ComponentKitScript.panel(screen_root, Rect2(1104.0, 142.0, 448.0, 694.0), "tooltip", Color(0.82, 0.90, 0.86, 0.88))
	detail.name = "ItemComparisonSurface"
	var chosen := _item_by_id(selected_item_id)
	var detail_title := _label("GIÁM ĐỊNH PHÁP BẢO", 13, GOLD, true)
	detail_title.position = Vector2(1140.0, 180.0)
	detail_title.size = Vector2(376.0, 24.0)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(detail_title)
	var chosen_icon := _texture(str(chosen.get("icon_path", "res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/sigil_phi_kiem.png")), Rect2(1195.0, 224.0, 266.0, 196.0))
	chosen_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen_root.add_child(chosen_icon)
	var chosen_name := _label(str(chosen.get("name", "Kiếm Huyền")), 26, PAPER, true)
	chosen_name.position = Vector2(1142.0, 430.0)
	chosen_name.size = Vector2(372.0, 38.0)
	chosen_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chosen_name.add_theme_color_override("font_outline_color", Color(INK, 0.82))
	chosen_name.add_theme_constant_override("outline_size", 1)
	screen_root.add_child(chosen_name)
	var chosen_rarity := _label("%s  ·  CẤP %d" % [str(chosen.get("rarity", "Huyền")).to_upper(), int(chosen.get("level", 8))], 14, _rarity_color(str(chosen.get("rarity", "Huyền"))), true)
	chosen_rarity.position = Vector2(1142.0, 470.0)
	chosen_rarity.size = Vector2(372.0, 24.0)
	chosen_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(chosen_rarity)
	var stat_copy := _label("THUỘC TÍNH THỰC CHIẾN", 11, PAPER_DIM, true)
	stat_copy.position = Vector2(1150.0, 520.0)
	stat_copy.size = Vector2(360.0, 22.0)
	screen_root.add_child(stat_copy)
	var stat_lines := ["Sát thương phi kiếm     +18%", "Hồi chiêu kỹ năng        -8%", "Tụ linh khi di chuyển    +12%"]
	for index in stat_lines.size():
		var line := _label(stat_lines[index], 15, PAPER, true)
		line.position = Vector2(1150.0, 550.0 + index * 34.0)
		line.size = Vector2(360.0, 26.0)
		screen_root.add_child(line)
	var delta := _label("SO VỚI ĐANG TRANG BỊ     +12  ·  +8  ·  +4", 12, JADE, true)
	delta.position = Vector2(1150.0, 662.0)
	delta.size = Vector2(360.0, 22.0)
	screen_root.add_child(delta)
	var equip := _button("TRẤN VÀO LOADOUT", RasterButton.ArtVariant.GOLD, Vector2(320.0, 64.0), 15, func() -> void: _equip_item(selected_item_id))
	equip.position = Vector2(1168.0, 722.0)
	equip.size = Vector2(320.0, 64.0)
	screen_root.add_child(equip)


func _build_spirit_beast() -> void:
	_set_background(HUB_ART_PATH, Color(0.004, 0.014, 0.016, 0.72))
	_add_directional_vignette(false)
	_build_top_bar("LINH THÚ HỘ ĐẠO", "Một khế ước · một trợ chiến · ba mốc tiến hóa", true)
	var beast := ComponentKitScript.panel(screen_root, Rect2(54.0, 142.0, 520.0, 694.0), "inventory", Color(0.84, 0.94, 0.90, 0.90))
	var beast_title := _label("THANH VÂN HỒ", 27, INK, true)
	beast_title.position = Vector2(112.0, 174.0)
	beast_title.size = Vector2(404.0, 36.0)
	beast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	beast_title.add_theme_color_override("font_outline_color", Color(PAPER, 0.30))
	beast_title.add_theme_constant_override("outline_size", 1)
	screen_root.add_child(beast_title)
	var beast_visual := _texture(PORTRAIT_ROOT + "thanh_van_ho.png", Rect2(112.0, 224.0, 404.0, 318.0))
	beast_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	beast_visual.modulate = Color(0.90, 1.05, 1.0, 1.0)
	screen_root.add_child(beast_visual)
	var bond := _label("KHẾ ƯỚC  ·  TẦNG 2 / 5", 14, JADE, true)
	bond.position = Vector2(116.0, 548.0)
	bond.size = Vector2(396.0, 24.0)
	bond.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(bond)
	var bond_copy := _label("Sau mỗi lần lướt né thành công, trợ chiến kế tiếp đánh dấu mục tiêu nguy hiểm nhất và kéo dài Kiếm Vực.", 15, INK)
	bond_copy.position = Vector2(112.0, 582.0)
	bond_copy.size = Vector2(404.0, 66.0)
	bond_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bond_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(bond_copy)
	var summon := _button("THU HỒN" if beast_bound else "KẾT KHẾ ƯỚC", RasterButton.ArtVariant.JADE if beast_bound else RasterButton.ArtVariant.GOLD, Vector2(284.0, 64.0), 16, func() -> void: _toggle_beast())
	summon.position = Vector2(172.0, 722.0)
	summon.size = Vector2(284.0, 64.0)
	screen_root.add_child(summon)

	var detail := _panel(Rect2(610.0, 142.0, 942.0, 694.0), LACQUER_PANEL_PATH, 44)
	screen_root.add_child(detail)
	ComponentKitScript.panel(screen_root, Rect2(636.0, 166.0, 890.0, 94.0), "command", Color(0.72, 0.84, 0.80, 0.45))
	var detail_title := _label("HỒ SƠ TRỢ CHIẾN", 15, GOLD, true)
	detail_title.position = Vector2(672.0, 190.0)
	detail_title.size = Vector2(370.0, 24.0)
	screen_root.add_child(detail_title)
	var detail_copy := _label("Thanh Vân Hồ không chiếm chỗ của telegraph; nó đứng ở quỹ đạo mềm và chỉ xuất hiện khi luật nhắm mục tiêu hợp lệ.", 14, PAPER_DIM)
	detail_copy.position = Vector2(672.0, 218.0)
	detail_copy.size = Vector2(800.0, 30.0)
	screen_root.add_child(detail_copy)
	var beast_tabs := ["TỔNG QUAN", "TRỢ CHIẾN", "TIẾN HÓA"]
	for index in beast_tabs.size():
		ComponentKitScript.tab(screen_root, beast_tabs[index], Rect2(668.0 + index * 186.0, 286.0, 178.0, 50.0), index == 0, func() -> void: _show_toast("Đang xem %s" % beast_tabs[index]))
	var cooldown_panel := ComponentKitScript.panel(screen_root, Rect2(672.0, 370.0, 190.0, 190.0), "cooldown", Color(0.80, 1.0, 0.94, 0.88))
	var assist_icon := _texture(str(SKILL_ICON_PATHS["thanh_van_ho"]), Rect2(707.0, 382.0, 120.0, 120.0))
	assist_icon.modulate = Color(0.94, 1.06, 1.02, 0.96)
	screen_root.add_child(assist_icon)
	var cooldown_label := _label("TRỢ CHIẾN · SẴN SÀNG", 13, JADE, true)
	cooldown_label.position = Vector2(686.0, 504.0)
	cooldown_label.size = Vector2(162.0, 30.0)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen_root.add_child(cooldown_label)
	var passive := _label("NỘI TẠI KHẾ ƯỚC", 13, GOLD, true)
	passive.position = Vector2(918.0, 374.0)
	passive.size = Vector2(520.0, 24.0)
	screen_root.add_child(passive)
	var passive_copy := _label("Mỗi ba lần di chuyển liên tục, Thanh Vân Hồ tạo một dấu ấn jade lên kẻ có cấp nguy hiểm cao nhất. Dấu ấn làm kỹ năng kế tiếp xuyên mục tiêu và hoàn lại 12% năng lượng.", 17, PAPER)
	passive_copy.position = Vector2(918.0, 410.0)
	passive_copy.size = Vector2(520.0, 92.0)
	passive_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(passive_copy)
	var evolution := _label("MỐC TIẾN HÓA", 13, JADE, true)
	evolution.position = Vector2(918.0, 548.0)
	evolution.size = Vector2(520.0, 24.0)
	screen_root.add_child(evolution)
	for index in 3:
		var marker := ComponentKitScript.panel(screen_root, Rect2(918.0 + index * 174.0, 588.0, 150.0, 104.0), "item_jade" if index < 2 else "item_violet", Color.WHITE if index <= 1 else Color(0.55, 0.58, 0.56, 0.80))
		var marker_label := _label("TẦNG %d" % (index + 1), 14, GOLD if index <= 1 else PAPER_DIM, true)
		marker_label.position = Vector2(918.0 + index * 174.0, 618.0)
		marker_label.size = Vector2(150.0, 22.0)
		marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(marker_label)
		var marker_copy := _label(["Đã thức tỉnh", "Mở dấu ấn", "Cần 120 tinh phách"][index], 12, PAPER_DIM)
		marker_copy.position = Vector2(926.0 + index * 174.0, 648.0)
		marker_copy.size = Vector2(134.0, 32.0)
		marker_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		screen_root.add_child(marker_copy)


func _build_techniques() -> void:
	_set_background(HUB_ART_PATH, Color(0.005, 0.014, 0.016, 0.68))
	_add_directional_vignette(false)
	_build_top_bar("CÔNG PHÁP CÁC", "Mỗi tầng thay đổi trực tiếp hình thái chiến đấu", true)

	# Keep the account summary as open editorial typography over the world. The
	# technique tracks carry the actual folio assets, avoiding a fourth equal box.
	var ledger_rule := ColorRect.new()
	ledger_rule.position = Vector2(360.0, 170.0)
	ledger_rule.size = Vector2(1.0, 622.0)
	ledger_rule.color = Color(GOLD, 0.42)
	ledger_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(ledger_rule)
	var ledger_caption := _label("KINH MẠCH VĨNH VIỄN", 12, GOLD, true)
	ledger_caption.position = Vector2(78.0, 180.0)
	ledger_caption.size = Vector2(252.0, 26.0)
	screen_root.add_child(ledger_caption)
	var ledger_title := _label("CĂN CƠ\nĐẠO THỂ", 32, PAPER, true)
	ledger_title.position = Vector2(78.0, 224.0)
	ledger_title.size = Vector2(252.0, 92.0)
	screen_root.add_child(ledger_title)
	var ledger_copy := _label("Không còn là nâng số liệu thụ động. Kiếm, hộ thể và tụ linh vực sẽ mở thêm lớp hiệu ứng, mật độ và silhouette ngay trong trận.", 15, PAPER_DIM)
	ledger_copy.position = Vector2(78.0, 338.0)
	ledger_copy.size = Vector2(244.0, 126.0)
	ledger_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(ledger_copy)
	var power_caption := _label("CÔNG LỰC TÀI KHOẢN", 12, Color(JADE, 0.82), true)
	power_caption.position = Vector2(78.0, 518.0)
	power_caption.size = Vector2(244.0, 24.0)
	screen_root.add_child(power_caption)
	var power_value := _label("%d" % _account_power(), 54, PAPER, true)
	power_value.position = Vector2(76.0, 548.0)
	power_value.size = Vector2(244.0, 70.0)
	screen_root.add_child(power_value)
	var currency_label := _label("%d  LINH NGỌC" % _profile_value("currency", 0), 17, GOLD, true)
	currency_label.position = Vector2(78.0, 644.0)
	currency_label.size = Vector2(244.0, 32.0)
	screen_root.add_child(currency_label)
	var ledger_hint := _label("Mỗi lần nâng tầng đều có nghi thức phản hồi và preview hình thái mới.", 14, Color(PAPER_DIM, 0.76))
	ledger_hint.position = Vector2(78.0, 706.0)
	ledger_hint.size = Vector2(244.0, 72.0)
	ledger_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_root.add_child(ledger_hint)

	var techniques := _techniques()
	var xs := [390.0, 784.0, 1178.0]
	for index in mini(techniques.size(), 3):
		var technique: Dictionary = techniques[index]
		var technique_id := StringName(str(technique.get("id", "sword_damage")))
		var rank := int(technique.get("rank", 0))
		var max_rank := int(technique.get("max_rank", 5))
		var cost := int(technique.get("next_cost", -1))
		var accent := _technique_accent(technique_id)
		var folio_rect := Rect2(xs[index], 140.0, 366.0, 704.0)
		screen_root.add_child(_folio_texture(str(FOLIO_PATHS[index]), Rect2(folio_rect.position + Vector2(6.0, 9.0), folio_rect.size), true))
		screen_root.add_child(_folio_texture(str(FOLIO_PATHS[index]), folio_rect))
		var preview := TechniquePreviewScript.new() as TechniquePreview
		preview.position = Vector2(xs[index] + 24.0, 158.0)
		preview.size = Vector2(318.0, 278.0)
		preview.configure(technique_id, rank, max_rank, _load_texture(str(TECHNIQUE_ICONS.get(String(technique_id), ICON_SWORD_PATH))))
		screen_root.add_child(preview)
		var paper_accent := accent.darkened(0.28)
		var school := _label(_technique_school(technique_id), 11, Color(paper_accent, 0.96), true)
		school.position = Vector2(xs[index] + 30.0, 440.0)
		school.size = Vector2(306.0, 24.0)
		school.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(school)
		var name_label := _label(str(technique.get("name", "Kiếm Tâm")), 24, INK, true)
		name_label.position = Vector2(xs[index] + 28.0, 474.0)
		name_label.size = Vector2(310.0, 40.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(name_label)
		var rank_label := _label("TẦNG %d / %d" % [rank, max_rank], 14, paper_accent, true)
		rank_label.position = Vector2(xs[index] + 28.0, 520.0)
		rank_label.size = Vector2(310.0, 28.0)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(rank_label)
		var description := _label(str(technique.get("description", "")), 14, Color("#4f5a51"))
		description.position = Vector2(xs[index] + 34.0, 562.0)
		description.size = Vector2(298.0, 50.0)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(description)
		var evolution := _label(_technique_evolution_copy(technique_id, rank, max_rank), 14, Color(paper_accent, 0.96), true)
		evolution.position = Vector2(xs[index] + 32.0, 622.0)
		evolution.size = Vector2(302.0, 58.0)
		evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		evolution.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(evolution)
		var price_text := "ĐÃ VIÊN MÃN" if rank >= max_rank else "NÂNG TẦNG  ·  %d LINH NGỌC" % cost
		var purchase := _button(price_text, RasterButton.ArtVariant.GOLD if rank < max_rank else RasterButton.ArtVariant.INK, Vector2(292.0, 62.0), 15, func() -> void: _purchase_technique(technique_id))
		purchase.position = Vector2(xs[index] + 37.0, 742.0)
		purchase.size = Vector2(292.0, 62.0)
		purchase.disabled = rank >= max_rank
		purchase.call_deferred("_refresh_visual_state")
		screen_root.add_child(purchase)


func _build_codex() -> void:
	_set_background(HUB_ART_PATH, Color(0.01, 0.02, 0.02, 0.55))
	_build_top_bar("VẠN TƯỢNG PHỔ", "Yêu vật từng gặp trên đạo đồ", true)
	var entries := _bestiary_entries()
	if entries.is_empty():
		return
	var has_selection := false
	for entry: Dictionary in entries:
		if StringName(str(entry.get("id", ""))) == selected_codex:
			has_selection = true
	if not has_selection:
		selected_codex = StringName(str(entries[0].get("id", "mac_linh")))

	var list_panel := _panel(Rect2(54.0, 130.0, 420.0, 704.0), LACQUER_PANEL_PATH, 52)
	screen_root.add_child(list_panel)
	var list_margin := _margin(list_panel, 50, 48, 50, 44)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 11)
	list_margin.add_child(list)
	var count_discovered := 0
	for entry: Dictionary in entries:
		if bool(entry.get("discovered", false)):
			count_discovered += 1
	var progress := _label("ĐÃ GHI NHẬN  %d / %d" % [count_discovered, entries.size()], 15, GOLD, true)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(progress)
	list.add_child(_space(8.0))
	for entry: Dictionary in entries:
		var entry_id := StringName(str(entry.get("id", "mac_linh")))
		var discovered := bool(entry.get("discovered", false))
		var entry_name := str(entry.get("name", "Vô danh")) if discovered else "CHƯA GHI NHẬN"
		var tab := _button(entry_name, RasterButton.ArtVariant.JADE if entry_id == selected_codex else RasterButton.ArtVariant.INK, Vector2(320.0, 62.0), 15, func() -> void: _select_codex_entry(entry_id))
		list.add_child(tab)

	var chosen := _bestiary_data(selected_codex)
	var discovered := bool(chosen.get("discovered", false))
	var detail_panel := _panel(Rect2(512.0, 130.0, 1034.0, 704.0), SCROLL_PANEL_PATH, 68)
	screen_root.add_child(detail_panel)
	var visual_frame := _panel(Rect2(572.0, 195.0, 388.0, 510.0), TALISMAN_CARD_PATH, 48)
	visual_frame.modulate = Color(0.92, 0.88, 0.78, 1.0)
	screen_root.add_child(visual_frame)
	var visual_path := str(BESTIARY_VISUALS.get(String(selected_codex), ""))
	var visual := _texture(visual_path, Rect2(635.0, 270.0, 262.0, 300.0))
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.modulate = Color.WHITE if discovered else Color(0.05, 0.07, 0.07, 0.88)
	screen_root.add_child(visual)
	var threat_value := int(chosen.get("threat", 0))
	var threat := _label("HIỂM HỌA  CẤP %d/3" % threat_value if discovered else "HIỂM HỌA  ? ? ?", 15, Color("#8e463b"), true)
	threat.position = Vector2(625.0, 606.0)
	threat.size = Vector2(282.0, 34.0)
	threat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(threat)

	var heading := _label(str(chosen.get("name", "Chưa ghi nhận")) if discovered else "BÓNG HÌNH CHƯA BIẾT", 31, Color("#382719"), true)
	heading.position = Vector2(1000.0, 208.0)
	heading.size = Vector2(452.0, 52.0)
	screen_root.add_child(heading)
	var kind := _label(("%s  ·  %s" % [str(chosen.get("kind", "")), str(chosen.get("habitat", ""))]) if discovered else "Tiếp cận thí luyện tương ứng để ghi nhận", 15, Color("#86603a"), true)
	kind.position = Vector2(1000.0, 270.0)
	kind.size = Vector2(450.0, 32.0)
	screen_root.add_child(kind)
	var description := _label(str(chosen.get("description", "Dữ liệu còn bị ma vụ che phủ.")) if discovered else "Trang phổ này chưa được khai mở. Mỗi cảnh giới sẽ bổ sung hình ảnh, tập tính và phương pháp ứng chiến của địch nhân.", 18, Color("#4a4035"))
	description.position = Vector2(1000.0, 330.0)
	description.size = Vector2(446.0, 150.0)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size = Vector2(446.0, 150.0)
	screen_root.add_child(description)
	var divider := HSeparator.new()
	divider.position = Vector2(1000.0, 498.0)
	divider.size = Vector2(430.0, 2.0)
	screen_root.add_child(divider)
	var tip_title := _label("YẾU QUYẾT ỨNG CHIẾN", 14, Color("#8d4c2d"), true)
	tip_title.position = Vector2(1000.0, 526.0)
	tip_title.size = Vector2(430.0, 30.0)
	screen_root.add_child(tip_title)
	var tip := _label(str(chosen.get("combat_tip", "Chưa có ghi chép.")) if discovered else "???", 18, Color("#3d534b"), true)
	tip.position = Vector2(1000.0, 570.0)
	tip.size = Vector2(430.0, 120.0)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.size = Vector2(430.0, 120.0)
	screen_root.add_child(tip)


func _build_achievements() -> void:
	_set_background(HUB_ART_PATH, Color(0.01, 0.02, 0.02, 0.58))
	_build_top_bar("THIÊN MỆNH LỤC", "Dấu mốc được khắc vào hồ sơ vĩnh viễn", true)
	var achievements := _achievement_entries()
	var unlocked_count := 0
	for achievement: Dictionary in achievements:
		if bool(achievement.get("unlocked", false)):
			unlocked_count += 1
	var summary := _label("HOÀN THÀNH  %d / %d" % [unlocked_count, achievements.size()], 15, GOLD, true)
	summary.position = Vector2(1210.0, 92.0)
	summary.size = Vector2(300.0, 28.0)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(summary)
	var xs := [74.0, 564.0, 1054.0]
	var ys := [150.0, 490.0]
	for index in mini(achievements.size(), 6):
		var achievement: Dictionary = achievements[index]
		var col := index % 3
		var row := index / 3
		var unlocked := bool(achievement.get("unlocked", false))
		var card := _panel(Rect2(xs[col], ys[row], 438.0, 286.0), LACQUER_PANEL_PATH, 48)
		card.modulate = Color(1.0, 1.0, 1.0, 1.0) if unlocked else Color(0.62, 0.64, 0.62, 0.94)
		screen_root.add_child(card)
		var achievement_id := str(achievement.get("id", "nhap_dao"))
		var seal_path := str(ACHIEVEMENT_SEALS.get(achievement_id, ICON_SWORD_PATH))
		var seal := _texture(seal_path, Rect2(xs[col] + 28.0, ys[row] + 52.0, 116.0, 116.0))
		seal.modulate = Color.WHITE if unlocked else Color(0.24, 0.28, 0.27, 0.75)
		screen_root.add_child(seal)
		var state := _label("ĐÃ KHẮC ẤN" if unlocked else "CHƯA HOÀN THÀNH", 12, GOLD if unlocked else PAPER_DIM, true)
		state.position = Vector2(xs[col] + 166.0, ys[row] + 43.0)
		state.size = Vector2(222.0, 28.0)
		screen_root.add_child(state)
		var title := _label(str(achievement.get("name", "Thiên mệnh")), 18, PAPER, true)
		title.position = Vector2(xs[col] + 166.0, ys[row] + 77.0)
		title.size = Vector2(224.0, 54.0)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.size = Vector2(224.0, 54.0)
		screen_root.add_child(title)
		var description := _label(str(achievement.get("description", "")), 14, PAPER_DIM)
		description.position = Vector2(xs[col] + 166.0, ys[row] + 137.0)
		description.size = Vector2(220.0, 64.0)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size = Vector2(220.0, 64.0)
		screen_root.add_child(description)
		var progress_data: Dictionary = achievement.get("progress", {}) as Dictionary
		var current := float(progress_data.get("current", 0.0))
		var target := float(progress_data.get("target", 1.0))
		var progress_text := "HOÀN TẤT" if unlocked else ("TIẾN ĐỘ  %d / %d" % [int(current), int(target)])
		if bool(progress_data.get("lower_is_better", false)) and current <= 0.0:
			progress_text = "CHƯA CÓ KỶ LỤC"
		var progress_label := _label(progress_text, 13, JADE if unlocked else PAPER_DIM, true)
		progress_label.position = Vector2(xs[col] + 46.0, ys[row] + 224.0)
		progress_label.size = Vector2(346.0, 30.0)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen_root.add_child(progress_label)


func _build_settings() -> void:
	_set_background(TITLE_ART_PATH if screen_name == SCREEN_TITLE else HUB_ART_PATH, Color(0.01, 0.02, 0.02, 0.60))
	_build_top_bar("THIẾT LẬP", "Âm thanh · Khả năng tiếp cận · Phản hồi hình ảnh", true)
	var panel := _panel(Rect2(312.0, 142.0, 976.0, 652.0), SCROLL_PANEL_PATH, 66)
	screen_root.add_child(panel)
	var settings := _settings()
	var rows := [
		{"id": &"master", "name": "ÂM LƯỢNG TỔNG", "description": "Điều chỉnh toàn bộ âm thanh trong game."},
		{"id": &"music", "name": "NHẠC NỀN", "description": "Âm lượng nhạc nền và không khí sơn môn."},
		{"id": &"sfx", "name": "HIỆU ỨNG", "description": "Phi kiếm, va chạm, đột phá và giao diện."},
	]
	for index in rows.size():
		var row: Dictionary = rows[index]
		var y := 226.0 + index * 108.0
		var title := _label(str(row.name), 17, Color("#4a321d"), true)
		title.position = Vector2(398.0, y)
		title.size = Vector2(300.0, 30.0)
		screen_root.add_child(title)
		var copy := _label(str(row.description), 14, Color("#65584a"))
		copy.position = Vector2(398.0, y + 36.0)
		copy.size = Vector2(410.0, 28.0)
		screen_root.add_child(copy)
		var minus := _button("−", RasterButton.ArtVariant.INK, Vector2(112.0, 54.0), 24, func() -> void: _nudge_volume(row.id, -0.10))
		minus.tooltip_text = "Giảm %s" % str(row.name).to_lower()
		minus.position = Vector2(844.0, y + 4.0)
		minus.size = Vector2(112.0, 54.0)
		screen_root.add_child(minus)
		var value := int(round(float(settings.get(row.id, 0.8)) * 100.0))
		var value_label := _label("%d%%" % value, 20, Color("#3c3023"), true)
		value_label.position = Vector2(964.0, y + 4.0)
		value_label.size = Vector2(116.0, 54.0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		screen_root.add_child(value_label)
		var plus := _button("+", RasterButton.ArtVariant.JADE, Vector2(112.0, 54.0), 24, func() -> void: _nudge_volume(row.id, 0.10))
		plus.tooltip_text = "Tăng %s" % str(row.name).to_lower()
		plus.position = Vector2(1084.0, y + 4.0)
		plus.size = Vector2(112.0, 54.0)
		screen_root.add_child(plus)

	_build_setting_toggle(&"reduced_motion", "GIẢM CHUYỂN ĐỘNG", "Giảm nhấp nháy, rung và chuyển động trang trí.", bool(settings.get("reduced_motion", false)), 538.0)
	_build_setting_toggle(&"screen_shake", "RUNG MÀN HÌNH", "Phản hồi lực khi trúng đòn và tung đại chiêu.", bool(settings.get("screen_shake", true)), 616.0)

	var title_button := _button("VỀ MÀN HÌNH CHÍNH", RasterButton.ArtVariant.INK, Vector2(300.0, 58.0), 14, func() -> void: _show_screen(SCREEN_TITLE))
	title_button.position = Vector2(310.0, 792.0)
	title_button.size = Vector2(300.0, 58.0)
	screen_root.add_child(title_button)
	var reset_button := _button("XÓA HỒ SƠ", RasterButton.ArtVariant.INK, Vector2(250.0, 58.0), 14, _show_reset_confirmation)
	reset_button.position = Vector2(675.0, 792.0)
	reset_button.size = Vector2(250.0, 58.0)
	screen_root.add_child(reset_button)
	var back_button := _button("TRỞ LẠI SƠN MÔN", RasterButton.ArtVariant.GOLD, Vector2(300.0, 58.0), 14, func() -> void: _show_screen(SCREEN_HUB))
	back_button.position = Vector2(990.0, 792.0)
	back_button.size = Vector2(300.0, 58.0)
	screen_root.add_child(back_button)


func _build_results() -> void:
	var result_glaze := Color(0.015, 0.008, 0.009, 0.76) if not last_victory else Color(0.006, 0.018, 0.016, 0.68)
	_set_background(str(STAGE_ART.get(String(_selected_stage()), STAGE_ART["van_mong"])), result_glaze)
	var panel := _panel(Rect2(298.0, 78.0, 1004.0, 744.0), LACQUER_PANEL_PATH, 78)
	panel.modulate = Color.WHITE if last_victory else Color(0.90, 0.70, 0.68, 1.0)
	screen_root.add_child(panel)
	var result_color := GOLD if last_victory else CRIMSON
	var eyebrow := _label("—  THÍ LUYỆN KẾT THÚC  —", 15, result_color, true)
	eyebrow.position = Vector2(470.0, 136.0)
	eyebrow.size = Vector2(660.0, 30.0)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(eyebrow)
	var heading := _label(last_result_title, 38, result_color, true)
	heading.position = Vector2(420.0, 180.0)
	heading.size = Vector2(760.0, 64.0)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(heading)
	var stage := _stage_data(_selected_stage())
	var stage_name := _label(str(stage.get("name", "Vân Mộng Cốc")), 17, JADE, true)
	stage_name.position = Vector2(500.0, 250.0)
	stage_name.size = Vector2(600.0, 32.0)
	stage_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(stage_name)

	var stats_panel := _ritual_surface(Rect2(388.0, 308.0, 824.0, 172.0), "result_plate", Color(0.98, 0.95, 0.86, 1.0), true)
	stats_panel.modulate = Color.WHITE if last_victory else Color(0.90, 0.78, 0.72, 1.0)
	screen_root.add_child(stats_panel)
	# Three dedicated columns avoid relying on color alone and remain legible at
	# controller-viewing distance.
	_build_result_stat("THỜI GIAN", _format_time(run_elapsed), 438.0)
	_build_result_stat("TRẢM YÊU", str(run_kills), 686.0)
	_build_result_stat("LINH NGỌC", "+%d" % int(last_result.get("total", 0)), 934.0)

	var reward_lines: Array[String] = []
	if bool(last_result.get("first_clear", false)):
		reward_lines.append("Thưởng phá cảnh lần đầu  +%d" % int(last_result.get("first_clear_bonus", 0)))
	var unlocks: Array = last_result.get("new_unlocks", []) as Array
	if not unlocks.is_empty():
		reward_lines.append("Cảnh giới mới đã khai mở")
	var achievements: Array = last_result.get("new_achievements", []) as Array
	if not achievements.is_empty():
		reward_lines.append("Khắc ấn %d thành tựu mới" % achievements.size())
	if reward_lines.is_empty():
		reward_lines.append("Căn cơ đã được ghi vào hồ sơ")
	var reward_copy := _label("\n".join(reward_lines), 16, PAPER_DIM, true)
	reward_copy.position = Vector2(432.0, 508.0)
	reward_copy.size = Vector2(736.0, 76.0)
	reward_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(reward_copy)
	var details := _label(last_result_details, 14, Color(PAPER_DIM, 0.82))
	details.position = Vector2(420.0, 582.0)
	details.size = Vector2(760.0, 58.0)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size = Vector2(760.0, 58.0)
	screen_root.add_child(details)

	var hub := _button("TRỞ VỀ SƠN MÔN", RasterButton.ArtVariant.GOLD if last_victory else RasterButton.ArtVariant.INK, Vector2(316.0, 64.0), 17, _return_to_hub)
	hub.position = Vector2(444.0, 692.0)
	hub.size = Vector2(316.0, 64.0)
	screen_root.add_child(hub)
	var retry := _button("THỬ LẠI", RasterButton.ArtVariant.INK if last_victory else RasterButton.ArtVariant.CRIMSON, Vector2(270.0, 60.0), 16, _retry_run)
	retry.position = Vector2(836.0, 694.0)
	retry.size = Vector2(270.0, 60.0)
	screen_root.add_child(retry)


func _build_top_bar(title_text: String, subtitle_text: String, show_back: bool) -> void:
	var bar := _surface(Rect2(0.0, 0.0, 1600.0, 112.0), Color(0.008, 0.021, 0.023, 0.91), Color(GOLD, 0.26), 0)
	screen_root.add_child(bar)
	var header_rect := Rect2(244.0 if show_back else 34.0, 12.0, 820.0 if show_back else 900.0, 92.0)
	ComponentKitScript.ritual_nine_patch(screen_root, "wide_header", header_rect, Color(0.96, 0.94, 0.86, 0.98))
	var baseline := ColorRect.new()
	baseline.position = Vector2(80.0, 110.0)
	baseline.size = Vector2(1440.0, 1.0)
	baseline.color = Color(GOLD, 0.42)
	baseline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(baseline)
	# Protect text from the authored clasps, center crest and right tassel.
	var title_x := header_rect.position.x + 104.0
	var title_width := header_rect.size.x - 208.0
	if show_back:
		var back := _button("QUAY LẠI", RasterButton.ArtVariant.INK, Vector2(184.0, 64.0), 14, _back)
		back.position = Vector2(80.0, 40.0)
		back.size = Vector2(184.0, 64.0)
		screen_root.add_child(back)
	var heading := _label(title_text, 23, PAPER_INK, true)
	heading.position = Vector2(title_x, 44.0)
	heading.size = Vector2(title_width, 32.0)
	screen_root.add_child(heading)
	var subtitle := _label(subtitle_text, 14, PAPER_COPY)
	subtitle.position = Vector2(title_x, 74.0)
	subtitle.size = Vector2(title_width, 23.0)
	screen_root.add_child(subtitle)
	var currency := _label("%d  LINH NGỌC" % _profile_value("currency", 0), 22, GOLD, true)
	currency.position = Vector2(1238.0, 38.0)
	currency.size = Vector2(282.0, 32.0)
	currency.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(currency)
	var record := _label("LINH NGỌC   ·   THẮNG %d   ·   CÔNG LỰC %d" % [_profile_value("victories", 0), _account_power()], 12, JADE, true)
	record.position = Vector2(1090.0, 76.0)
	record.size = Vector2(430.0, 22.0)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(record)


func _surface(rect: Rect2, fill: Color, accent: Color, border_width: int = 1) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = accent
	style.set_border_width_all(maxi(border_width, 0))
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 12 if rect.size.y > 180.0 else 5
	style.shadow_offset = Vector2(0.0, 7.0 if rect.size.y > 180.0 else 3.0)
	panel.add_theme_stylebox_override(&"panel", style)
	return panel


func _ritual_surface(rect: Rect2, region_name: String, tint: Color = Color.WHITE, scalable: bool = true) -> Panel:
	var panel := Panel.new()
	panel.name = "RitualSurface_%s" % region_name
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	if scalable:
		ComponentKitScript.ritual_nine_patch(panel, region_name, Rect2(Vector2.ZERO, rect.size), tint)
	else:
		ComponentKitScript.ritual_chrome(panel, region_name, Rect2(Vector2.ZERO, rect.size), tint)
	return panel


func _add_directional_vignette(dark_left: bool) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.38, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.0, 0.012, 0.014, 0.58 if dark_left else 0.30),
		Color(0.0, 0.012, 0.014, 0.18),
		Color(0.0, 0.012, 0.014, 0.10),
		Color(0.0, 0.012, 0.014, 0.46 if dark_left else 0.34),
	])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 1600
	gradient_texture.height = 1
	gradient_texture.fill_from = Vector2(0.0, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	var vignette := TextureRect.new()
	vignette.name = "CinematicVignette"
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.texture = gradient_texture
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(vignette)


func _discipline_technique_key(discipline_id: StringName) -> StringName:
	match discipline_id:
		&"tu_linh":
			return &"magnet"
		&"ngoc_the":
			return &"vitality"
		_:
			return &"sword_damage"


func _phone_discipline_copy(discipline_id: StringName) -> String:
	match discipline_id:
		&"tu_linh":
			return "HÚT LINH · PHÁ CẢNH"
		&"ngoc_the":
			return "SINH MỆNH · HỒI PHỤC"
		_:
			return "KIẾM · XUẤT CHIÊU"


func _phone_discipline_title(discipline_id: StringName) -> String:
	match discipline_id:
		&"tu_linh":
			return "TỤ LINH"
		&"ngoc_the":
			return "NGỌC THỂ"
		_:
			return "VẠN KIẾM"


func _technique_accent(technique_id: StringName) -> Color:
	match technique_id:
		&"vitality":
			return JADE
		&"magnet":
			return Color("#78d4dc")
		_:
			return GOLD


func _technique_school(technique_id: StringName) -> String:
	match technique_id:
		&"vitality":
			return "NGỌC THỂ · HỘ MỆNH"
		&"magnet":
			return "TỤ LINH · DẪN KHÍ"
		_:
			return "KIẾM ĐẠO · SÁT PHẠT"


func _phone_technique_title(technique_id: StringName) -> String:
	match technique_id:
		&"vitality":
			return "NGỌC CỐT"
		&"magnet":
			return "TỤ LINH"
		_:
			return "KIẾM TÂM"


func _technique_evolution_copy(technique_id: StringName, rank: int, max_rank: int) -> String:
	if rank >= max_rank:
		match technique_id:
			&"vitality":
				return "VIÊN MÃN · Ngọc giáp và lục phù cùng hiển hiện"
			&"magnet":
				return "VIÊN MÃN · Tụ linh vực kết thành ba luồng dẫn khí"
			_:
				return "VIÊN MÃN · Kiếm trận mở thế vạn kiếm đồng quy"
	match technique_id:
		&"vitality":
			return "TẦNG KẾ · Thêm lớp ngọc thuẫn và hộ mệnh phù"
		&"magnet":
			return "TẦNG KẾ · Mở thêm linh tuyến và luồng hút hữu hình"
		_:
			return "TẦNG KẾ · Thêm kiếm hộ thân và mật độ kiếm quang"


func _phone_technique_evolution_copy(technique_id: StringName, rank: int, max_rank: int) -> String:
	if rank >= max_rank:
		match technique_id:
			&"vitality":
				return "VIÊN MÃN · NGỌC GIÁP"
			&"magnet":
				return "VIÊN MÃN · TỤ LINH VỰC"
			_:
				return "VIÊN MÃN · VẠN KIẾM"
	match technique_id:
		&"vitality":
			return "TẦNG KẾ · THÊM NGỌC"
		&"magnet":
			return "TẦNG KẾ · THÊM LINH"
		_:
			return "TẦNG KẾ · THÊM KIẾM"


func _build_setting_toggle(setting_id: StringName, title_text: String, copy_text: String, enabled: bool, y: float) -> void:
	var title := _label(title_text, 17, Color("#4a321d"), true)
	title.position = Vector2(398.0, y)
	title.size = Vector2(320.0, 30.0)
	screen_root.add_child(title)
	var copy := _label(copy_text, 14, Color("#65584a"))
	copy.position = Vector2(398.0, y + 34.0)
	copy.size = Vector2(480.0, 28.0)
	screen_root.add_child(copy)
	var state_text := "ĐANG BẬT" if enabled else "ĐANG TẮT"
	var toggle := _button(state_text, RasterButton.ArtVariant.JADE if enabled else RasterButton.ArtVariant.INK, Vector2(254.0, 56.0), 15, func() -> void: _toggle_setting(setting_id, not enabled))
	toggle.position = Vector2(916.0, y + 4.0)
	toggle.size = Vector2(254.0, 56.0)
	screen_root.add_child(toggle)


func _build_result_stat(caption: String, value: String, x: float) -> void:
	var caption_label := _label(caption, 12, Color("#79552e"), true)
	caption_label.position = Vector2(x, 354.0)
	caption_label.size = Vector2(228.0, 28.0)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(caption_label)
	var value_label := _label(value, 26, Color("#34271b"), true)
	value_label.position = Vector2(x, 392.0)
	value_label.size = Vector2(228.0, 46.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen_root.add_child(value_label)


func _panel(rect: Rect2, texture_path: String, _patch: int) -> Panel:
	# Generated chrome is presented as a real nine-slice. Corners, scroll rollers
	# and clasps retain their source pixels while only the quiet center bands
	# stretch to the requested surface. This keeps authored material on every
	# major screen without the deformation caused by a plain TextureRect.
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := Color(0.012, 0.030, 0.033, 0.95)
	var accent := Color(GOLD, 0.36)
	if texture_path == SCROLL_PANEL_PATH:
		fill = Color("#d3c5a0")
		accent = Color("#765326", 0.62)
	elif texture_path == TALISMAN_CARD_PATH:
		fill = Color("#cbbd98")
		accent = Color("#6b4b2d", 0.66)
	var authored_texture: Texture2D
	# UIKIT-005 lacquer, UIKIT-002 scrolls and talismans are all dedicated
	# nine-slice components. Atlas crops with fixed silhouettes are never chosen
	# heuristically from a panel's aspect ratio.
	authored_texture = _load_texture(texture_path)
	var has_authored_texture := authored_texture != null
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill, 0.0) if has_authored_texture else fill
	style.border_color = Color(accent, 0.0) if has_authored_texture else accent
	style.set_border_width_all(0 if has_authored_texture else 1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 0 if has_authored_texture else 10
	style.shadow_offset = Vector2(0.0, 6.0)
	panel.add_theme_stylebox_override(&"panel", style)
	if has_authored_texture:
		var chrome_shadow := NinePatchRect.new()
		chrome_shadow.name = "AuthoredChromeShadow"
		chrome_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		chrome_shadow.offset_top += 7.0
		chrome_shadow.offset_bottom += 7.0
		chrome_shadow.texture = authored_texture
		var chrome := NinePatchRect.new()
		chrome.name = "AuthoredChrome"
		chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		chrome.texture = authored_texture
		var horizontal_patch := mini(_patch, maxi(12, int(authored_texture.get_width() * 0.34)))
		var vertical_patch := mini(_patch, maxi(12, int(authored_texture.get_height() * 0.34)))
		chrome.set_patch_margin(SIDE_LEFT, horizontal_patch)
		chrome.set_patch_margin(SIDE_TOP, vertical_patch)
		chrome.set_patch_margin(SIDE_RIGHT, horizontal_patch)
		chrome.set_patch_margin(SIDE_BOTTOM, vertical_patch)
		chrome.draw_center = true
		chrome.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chrome_shadow.set_patch_margin(SIDE_LEFT, horizontal_patch)
		chrome_shadow.set_patch_margin(SIDE_TOP, vertical_patch)
		chrome_shadow.set_patch_margin(SIDE_RIGHT, horizontal_patch)
		chrome_shadow.set_patch_margin(SIDE_BOTTOM, vertical_patch)
		chrome_shadow.draw_center = true
		chrome_shadow.modulate = Color(0.0, 0.0, 0.0, 0.30)
		chrome_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		chrome_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(chrome_shadow)
		panel.add_child(chrome)
	return panel


func _margin(parent: Control, left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	parent.add_child(margin)
	return margin


func _button(caption: String, variant: RasterButton.ArtVariant, minimum: Vector2, font_size: int, callback: Callable) -> RasterButton:
	var button := RasterButtonScript.new() as RasterButton
	button.configure(caption, variant, minimum, font_size)
	if phone_layout_active:
		# Preserve the 64 px action target while letting the authored ornament read
		# as a compact command plaque on 390 px-tall landscape phones.
		button.set_visual_inset(6.0, 9.0)
	button.pressed.connect(callback)
	button.tooltip_text = caption.capitalize()
	focus_queue.append(button)
	return button


func _texture(path: String, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.position = rect.position
	image.size = rect.size
	image.texture = _load_texture(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _folio_texture(path: String, rect: Rect2, shadow: bool = false) -> TextureRect:
	var image := TextureRect.new()
	image.position = rect.position
	image.size = rect.size
	image.texture = _load_texture(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.modulate = Color(0.0, 0.0, 0.0, 0.42) if shadow else Color.WHITE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _label(text_value: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.clip_text = true
	label.add_theme_font_override("font", DISPLAY_FONT if bold and font_size >= 25 else (ACTION_FONT if bold else BODY_FONT))
	label.add_theme_font_size_override("font_size", maxi(font_size, 14))
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.42))
		label.add_theme_constant_override("outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _space(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1.0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded: Variant = load(path)
	return loaded as Texture2D if loaded is Texture2D else null


func _set_background(path: String, glaze: Color) -> void:
	background.texture = _load_texture(path)
	# The dedicated phone composition keeps the complete authored painting and
	# lets the blue-black extension field absorb the wider landscape ratio.
	# Desktop remains a native 16:9 fit, so neither path stretches the source.
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if phone_layout_active else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_glaze.color = glaze


func _focus_first() -> void:
	for control in focus_queue:
		if is_instance_valid(control) and control.is_visible_in_tree() and not (control is BaseButton and (control as BaseButton).disabled):
			control.grab_focus()
			return


func _inventory_items() -> Array[Dictionary]:
	return [
		{"id": "kiem_huyen", "name": "Huyền Vân Kiếm", "rarity": "Huyền", "level": 8, "slot": "phap_kiem", "icon": "jade_sword", "icon_path": ITEM_ICON_PATHS["jade_sword"]},
		{"id": "ho_tam_ngoc", "name": "Hộ Tâm Ngọc", "rarity": "Linh", "level": 7, "slot": "ho_tam", "icon": "heart_mirror", "icon_path": ITEM_ICON_PATHS["heart_mirror"]},
		{"id": "dao_bao_van", "name": "Đạo Bào Tụ Vân", "rarity": "Địa", "level": 9, "slot": "dao_bao", "icon": "cloud_robe", "icon_path": ITEM_ICON_PATHS["cloud_robe"]},
		{"id": "linh_gioi_moc", "name": "Linh Giới Mộc", "rarity": "Linh", "level": 6, "slot": "linh_gioi", "icon": "wood_ring", "icon_path": ITEM_ICON_PATHS["wood_ring"]},
		{"id": "kiem_thien_quang", "name": "Thiên Quang Kiếm", "rarity": "Thiên", "level": 12, "slot": "phap_kiem", "icon": "sun_sword", "icon_path": ITEM_ICON_PATHS["sun_sword"]},
		{"id": "minh_ngoc_kinh", "name": "Minh Ngọc Kính", "rarity": "Huyền", "level": 10, "slot": "ho_tam", "icon": "moon_mirror", "icon_path": ITEM_ICON_PATHS["moon_mirror"]},
		{"id": "huyet_van_phu", "name": "Huyết Vân Phù", "rarity": "Địa", "level": 9, "slot": "linh_gioi", "icon": "blood_talisman", "icon_path": ITEM_ICON_PATHS["blood_talisman"]},
		{"id": "tu_linh_quyen", "name": "Tụ Linh Tàn Quyển", "rarity": "Huyền", "level": 8, "slot": "dao_bao", "icon": "ancient_manual", "icon_path": ITEM_ICON_PATHS["ancient_manual"]},
		{"id": "thien_giac_an", "name": "Thiên Giác Ấn", "rarity": "Thiên", "level": 13, "slot": "ho_tam", "icon": "horn_seal", "icon_path": ITEM_ICON_PATHS["horn_seal"]},
		{"id": "kiem_tam_thach", "name": "Kiếm Tâm Thạch", "rarity": "Linh", "level": 5, "slot": "linh_gioi", "icon": "sword_crystal", "icon_path": ITEM_ICON_PATHS["sword_crystal"]},
		{"id": "van_linh_hoan", "name": "Vân Linh Hoàn", "rarity": "Địa", "level": 11, "slot": "linh_gioi", "icon": "cloud_bracelet", "icon_path": ITEM_ICON_PATHS["cloud_bracelet"]},
		{"id": "ngoc_the_giap", "name": "Ngọc Thể Giáp", "rarity": "Huyền", "level": 10, "slot": "dao_bao", "icon": "spirit_cuirass", "icon_path": ITEM_ICON_PATHS["spirit_cuirass"]},
	]


func _item_by_id(item_id: String) -> Dictionary:
	for item: Dictionary in _inventory_items():
		if str(item.get("id", "")) == item_id:
			return item
	return _inventory_items()[0]


func _item_icon(kind: String) -> Texture2D:
	if ITEM_ICON_PATHS.has(kind):
		return _load_texture(str(ITEM_ICON_PATHS[kind]))
	return _load_texture(ICON_SWORD_PATH)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Thiên": return CRIMSON
		"Địa": return Color("#a58ac8")
		"Huyền": return GOLD
		"Linh": return JADE
	return PAPER_DIM


func _select_inventory_item(item_id: String) -> void:
	selected_item_id = item_id
	_show_screen(SCREEN_INVENTORY)


func _equip_item(item_id: String) -> void:
	var item := _item_by_id(item_id)
	var slot := str(item.get("slot", "linh_gioi"))
	var replaced := false
	for index in equipped_item_ids.size():
		if str(_item_by_id(str(equipped_item_ids[index])).get("slot", "")) == slot:
			equipped_item_ids[index] = item_id
			replaced = true
			break
	if not replaced:
		equipped_item_ids.append(item_id)
	selected_item_id = item_id
	_show_screen(SCREEN_INVENTORY)
	_show_toast("Đã trấn %s vào loadout" % str(item.get("name", "pháp bảo")))


func _toggle_beast() -> void:
	beast_bound = not beast_bound
	_show_screen(SCREEN_SPIRIT_BEAST)
	_show_toast("Thanh Vân Hồ đã xuất trận" if beast_bound else "Thanh Vân Hồ đã thu hồn")


func _profile_snapshot() -> Dictionary:
	if profile != null and profile.has_method("get_profile"):
		var value: Variant = profile.call("get_profile")
		if value is Dictionary:
			return value as Dictionary
	return {}


func _profile_value(key: String, fallback: int) -> int:
	return int(_profile_snapshot().get(key, fallback))


func _selected_stage() -> StringName:
	return StringName(str(_profile_snapshot().get("selected_stage", "van_mong")))


func _selected_discipline() -> StringName:
	return StringName(str(_profile_snapshot().get("selected_discipline", "van_kiem")))


func _stages() -> Array[Dictionary]:
	if profile != null and profile.has_method("get_stages"):
		return profile.call("get_stages") as Array[Dictionary]
	return []


func _stage_data(stage_id: StringName) -> Dictionary:
	if profile != null and profile.has_method("get_stage_data"):
		return profile.call("get_stage_data", stage_id) as Dictionary
	return {"id": "van_mong", "name": "Vân Mộng Cốc", "difficulty": 1, "description": ""}


func _disciplines() -> Array[Dictionary]:
	if profile != null and profile.has_method("get_disciplines"):
		return profile.call("get_disciplines") as Array[Dictionary]
	return []


func _discipline_data(discipline_id: StringName) -> Dictionary:
	if profile != null and profile.has_method("get_discipline_data"):
		return profile.call("get_discipline_data", discipline_id) as Dictionary
	return {"id": "van_kiem", "name": "Vạn Kiếm Quy Tông"}


func _techniques() -> Array[Dictionary]:
	if profile != null and profile.has_method("get_techniques"):
		return profile.call("get_techniques") as Array[Dictionary]
	return []


func _technique_data(technique_id: StringName) -> Dictionary:
	if profile != null and profile.has_method("get_upgrade_data"):
		return profile.call("get_upgrade_data", technique_id) as Dictionary
	for technique: Dictionary in _techniques():
		if StringName(str(technique.get("id", ""))) == technique_id:
			return technique
	return {"id": technique_id, "name": "Công pháp"}


func _bestiary_entries() -> Array[Dictionary]:
	if profile != null and profile.has_method("get_bestiary_entries"):
		return profile.call("get_bestiary_entries") as Array[Dictionary]
	return []


func _bestiary_data(entry_id: StringName) -> Dictionary:
	if profile != null and profile.has_method("get_bestiary_data"):
		return profile.call("get_bestiary_data", entry_id) as Dictionary
	return {}


func _achievement_entries() -> Array[Dictionary]:
	if profile != null and profile.has_method("get_achievements"):
		return profile.call("get_achievements") as Array[Dictionary]
	return []


func _settings() -> Dictionary:
	return _profile_snapshot().get("settings", {}) as Dictionary


func _account_power() -> int:
	var ranks: Dictionary = _profile_snapshot().get("technique_ranks", {}) as Dictionary
	var result := 0
	for value: Variant in ranks.values():
		result += int(value)
	return result


func _select_stage(stage_id: StringName) -> void:
	if profile != null and bool(profile.call("select_stage", stage_id)):
		_show_toast("Đã chọn %s" % str(_stage_data(stage_id).get("name", "thí luyện")))
		_show_screen(SCREEN_STAGES)


func _select_discipline(discipline_id: StringName) -> void:
	if profile != null and bool(profile.call("select_discipline", discipline_id)):
		_show_toast("Đã trang bị %s" % str(_discipline_data(discipline_id).get("name", "tâm pháp")))
		_show_screen(SCREEN_LOADOUT)


func _select_codex_entry(entry_id: StringName) -> void:
	selected_codex = entry_id
	_show_screen(SCREEN_CODEX)


func _purchase_technique(technique_id: StringName) -> void:
	if profile == null:
		return
	var receipt: Dictionary = profile.call("purchase_upgrade", technique_id) as Dictionary
	if bool(receipt.get("success", false)):
		var next_rank := int(receipt.get("rank", 1))
		_show_screen(SCREEN_TECHNIQUES)
		_show_rank_ascension(technique_id, next_rank)
	else:
		var reason := str(receipt.get("error", ""))
		_show_toast("Linh Ngọc chưa đủ" if reason == "insufficient_currency" else "Công pháp đã viên mãn")
		_show_screen(SCREEN_TECHNIQUES)


func _show_rank_ascension_v3(technique_id: StringName, next_rank: int) -> void:
	if phone_layout_active:
		_show_phone_rank_ascension(technique_id, next_rank)
		return
	var overlay := Control.new()
	overlay.name = "RankAscension"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.012, 0.014, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var dialog_canvas := Control.new()
	dialog_canvas.name = "DialogCanvas"
	dialog_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dialog_canvas.size = DESIGN_SIZE
	dialog_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dialog_canvas)
	var accent := _technique_accent(technique_id)
	# The ritual sits on bright parchment; push the discipline tint into an ink
	# value so the caption/evolution copy stays readable at phone scale.
	var paper_accent := accent.darkened(0.56)
	var focus_surface := _ritual_surface(Rect2(500.0, 164.0, 600.0, 572.0), "modal_guard", Color(0.98, 0.95, 0.86, 1.0), true)
	dialog_canvas.add_child(focus_surface)
	var preview := TechniquePreviewScript.new() as TechniquePreview
	preview.position = Vector2(610.0, 192.0)
	preview.size = Vector2(380.0, 350.0)
	preview.configure(technique_id, next_rank, 5, _load_texture(str(TECHNIQUE_ICONS.get(String(technique_id), ICON_SWORD_PATH))))
	dialog_canvas.add_child(preview)
	var caption := _label("—  CĂN CƠ TIẾN HÓA  —", 14, paper_accent, true)
	caption.position = Vector2(610.0, 520.0)
	caption.size = Vector2(380.0, 28.0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(caption)
	var name := str(_technique_data(technique_id).get("name", "Công pháp"))
	var title := _label("%s  ·  TẦNG %d" % [name.to_upper(), next_rank], 27, INK, true)
	title.position = Vector2(548.0, 558.0)
	title.size = Vector2(504.0, 48.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(title)
	var change := _label(_technique_evolution_copy(technique_id, next_rank, 5), 15, Color(paper_accent, 0.96), true)
	change.position = Vector2(568.0, 622.0)
	change.size = Vector2(464.0, 56.0)
	change.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	change.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_canvas.add_child(change)
	root.add_child(overlay)
	_apply_design_canvas_transform(dialog_canvas, root.size)
	if toast_panel != null:
		root.move_child(overlay, toast_panel.get_index())
	overlay.modulate.a = 0.0
	var reduced := bool(_settings().get("reduced_motion", false))
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.12 if reduced else 0.18)
	tween.tween_interval(0.72 if reduced else 1.05)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
	tween.tween_callback(overlay.queue_free)


func _show_phone_rank_ascension(technique_id: StringName, next_rank: int) -> void:
	var overlay := Control.new()
	overlay.name = "RankAscension"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.010, 0.012, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var dialog_canvas := Control.new()
	dialog_canvas.name = "DialogCanvas"
	dialog_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dialog_canvas.size = _physical_window_size()
	dialog_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dialog_canvas)
	var safe := Rect2(Vector2(92.0, 28.0), Vector2(660.0, 334.0))
	var panel := _ritual_surface(safe, "modal_guard", Color(0.98, 0.95, 0.86, 1.0), true)
	dialog_canvas.add_child(panel)
	var preview := TechniquePreviewScript.new() as TechniquePreview
	preview.position = Vector2(safe.position.x + 18.0, safe.position.y + 12.0)
	preview.size = Vector2(252.0, safe.size.y - 24.0)
	preview.configure(technique_id, next_rank, 5, _load_texture(str(TECHNIQUE_ICONS.get(String(technique_id), ICON_SWORD_PATH))))
	dialog_canvas.add_child(preview)
	var accent := _technique_accent(technique_id)
	var text_x := safe.position.x + 288.0
	var text_width := safe.end.x - text_x - 28.0
	var caption := _label("—  CĂN CƠ TIẾN HÓA  —", 15, accent, true)
	caption.position = Vector2(text_x, safe.position.y + 42.0)
	caption.size = Vector2(text_width, 26.0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(caption)
	var name := str(_technique_data(technique_id).get("name", "Công pháp"))
	var title := _label("%s\nTẦNG %d" % [name.to_upper(), next_rank], 26, PAPER_INK, true)
	title.position = Vector2(text_x, safe.position.y + 82.0)
	title.size = Vector2(text_width, 78.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(title)
	var divider := ColorRect.new()
	divider.position = Vector2(text_x + 28.0, safe.position.y + 174.0)
	divider.size = Vector2(text_width - 56.0, 1.0)
	divider.color = Color(accent, 0.66)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_canvas.add_child(divider)
	var change := _label(_technique_evolution_copy(technique_id, next_rank, 5), 17, PAPER_COPY, true)
	change.position = Vector2(text_x + 18.0, safe.position.y + 194.0)
	change.size = Vector2(text_width - 36.0, 64.0)
	change.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	change.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_canvas.add_child(change)
	var seal := _label("+", 28, GOLD, true)
	seal.position = Vector2(text_x, safe.end.y - 58.0)
	seal.size = Vector2(text_width, 40.0)
	seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(seal)
	root.add_child(overlay)
	_apply_design_canvas_transform(dialog_canvas, root.size)
	if toast_panel != null:
		root.move_child(overlay, toast_panel.get_index())
	overlay.modulate.a = 0.0
	var reduced := bool(_settings().get("reduced_motion", false))
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.12 if reduced else 0.18)
	tween.tween_interval(0.72 if reduced else 1.05)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
	tween.tween_callback(overlay.queue_free)


func _nudge_volume(setting_id: StringName, delta: float) -> void:
	if profile == null:
		return
	var value := clampf(float(_settings().get(setting_id, 0.8)) + delta, 0.0, 1.0)
	profile.call("set_setting", setting_id, value)
	_apply_audio_settings()
	_show_screen(SCREEN_SETTINGS)


func _toggle_setting(setting_id: StringName, value: bool) -> void:
	if profile == null:
		return
	profile.call("set_setting", setting_id, value)
	_show_screen(SCREEN_SETTINGS)


func _show_reset_confirmation_v3() -> void:
	if phone_layout_active:
		_show_phone_reset_confirmation()
		return
	var overlay := Control.new()
	overlay.name = "ResetConfirmation"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.012, 0.013, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var dialog_canvas := Control.new()
	dialog_canvas.name = "DialogCanvas"
	dialog_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dialog_canvas.size = DESIGN_SIZE
	dialog_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dialog_canvas)
	var panel := _ritual_surface(Rect2(420.0, 238.0, 760.0, 424.0), "modal_guard", Color(0.96, 0.92, 0.82, 1.0), true)
	dialog_canvas.add_child(panel)
	var eyebrow := _label("—  CẢNH BÁO HỒ SƠ  —", 15, CRIMSON, true)
	eyebrow.position = Vector2(550.0, 306.0)
	eyebrow.size = Vector2(500.0, 30.0)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(eyebrow)
	var heading := _label("LUÂN HỒI TỪ ĐẦU?", 31, PAPER_INK, true)
	heading.position = Vector2(520.0, 354.0)
	heading.size = Vector2(560.0, 54.0)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(heading)
	var warning := _label("Toàn bộ Linh Ngọc, công pháp, thành tựu, bestiary và tiến độ mở ải sẽ bị xóa vĩnh viễn.", 17, PAPER_COPY)
	warning.position = Vector2(545.0, 430.0)
	warning.size = Vector2(510.0, 82.0)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(warning)
	var cancel := _button("GIỮ HỒ SƠ", RasterButton.ArtVariant.JADE, Vector2(240.0, 58.0), 15, func() -> void: _close_reset_confirmation(overlay))
	cancel.position = Vector2(515.0, 552.0)
	cancel.size = Vector2(240.0, 58.0)
	dialog_canvas.add_child(cancel)
	var confirm := _button("XÁC NHẬN XÓA", RasterButton.ArtVariant.CRIMSON, Vector2(260.0, 64.0), 15, func() -> void: _reset_profile(overlay))
	confirm.position = Vector2(825.0, 552.0)
	confirm.size = Vector2(260.0, 58.0)
	dialog_canvas.add_child(confirm)
	root.add_child(overlay)
	_apply_design_canvas_transform(dialog_canvas, root.size)
	cancel.call_deferred("grab_focus")


func _show_phone_reset_confirmation() -> void:
	var overlay := Control.new()
	overlay.name = "ResetConfirmation"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.010, 0.012, 0.84)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var dialog_canvas := Control.new()
	dialog_canvas.name = "DialogCanvas"
	dialog_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dialog_canvas.size = _physical_window_size()
	dialog_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dialog_canvas)
	var panel_rect := Rect2(92.0, 38.0, 660.0, 314.0)
	var panel := _ritual_surface(panel_rect, "modal_guard", Color(0.96, 0.92, 0.82, 1.0), true)
	dialog_canvas.add_child(panel)
	var eyebrow := _label("—  CẢNH BÁO HỒ SƠ  —", 15, CRIMSON, true)
	eyebrow.position = Vector2(168.0, 70.0)
	eyebrow.size = Vector2(508.0, 26.0)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(eyebrow)
	var heading := _label("LUÂN HỒI TỪ ĐẦU?", 29, PAPER_INK, true)
	heading.position = Vector2(148.0, 104.0)
	heading.size = Vector2(548.0, 44.0)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(heading)
	var warning := _label("Toàn bộ Linh Ngọc, công pháp, thành tựu, vạn tượng phổ và tiến độ mở ải sẽ bị xóa vĩnh viễn.", 17, PAPER_COPY)
	warning.position = Vector2(170.0, 160.0)
	warning.size = Vector2(504.0, 64.0)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_canvas.add_child(warning)
	var cancel := _button("GIỮ HỒ SƠ", RasterButton.ArtVariant.JADE, Vector2(250.0, 64.0), 16, func() -> void: _close_reset_confirmation(overlay))
	cancel.position = Vector2(146.0, 262.0)
	cancel.size = Vector2(250.0, 64.0)
	dialog_canvas.add_child(cancel)
	var confirm := _button("XÁC NHẬN XÓA", RasterButton.ArtVariant.CRIMSON, Vector2(270.0, 64.0), 16, func() -> void: _reset_profile(overlay))
	confirm.position = Vector2(448.0, 262.0)
	confirm.size = Vector2(270.0, 64.0)
	dialog_canvas.add_child(confirm)
	root.add_child(overlay)
	_apply_design_canvas_transform(dialog_canvas, root.size)
	cancel.call_deferred("grab_focus")


func _reset_profile(overlay: Control) -> void:
	if profile != null and profile.has_method("reset_profile"):
		profile.call("reset_profile", true)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_screen(SCREEN_TITLE)
	_show_toast("Hồ sơ đã trở về điểm khởi đầu")


func _close_reset_confirmation(overlay: Control) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	call_deferred("_focus_first")


func _start_selected_run() -> void:
	root.hide()
	get_tree().paused = false
	Events.start_requested.emit()


func _return_to_hub() -> void:
	if profile != null:
		profile.set("pending_screen", SCREEN_HUB)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _retry_run() -> void:
	get_tree().set_meta("van_mong_restart_into_run", true)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _quit_game() -> void:
	get_tree().quit()


func _back() -> void:
	match screen_name:
		SCREEN_HUB:
			_show_screen(SCREEN_TITLE)
		SCREEN_LOADOUT:
			_show_screen(SCREEN_STAGES)
		SCREEN_TITLE:
			pass
		_:
			_show_screen(SCREEN_HUB)


func _on_game_started() -> void:
	root.hide()


func _on_game_finished(victory: bool, title: String, details: String) -> void:
	last_victory = victory
	last_result_title = title
	last_result_details = details
	last_result = {}
	if profile != null and profile.has_method("record_run"):
		last_result = profile.call("record_run", victory, run_kills, run_elapsed) as Dictionary
	_show_screen(SCREEN_RESULTS)


func _on_run_stats_changed(elapsed: float, duration: float, kills: int) -> void:
	run_elapsed = elapsed
	run_duration = duration
	run_kills = kills


func _on_profile_changed(_snapshot: Dictionary) -> void:
	pass


func _on_settings_changed(_current_settings: Dictionary) -> void:
	_apply_audio_settings()


func _apply_audio_settings() -> void:
	var settings := _settings()
	var buses := {
		"Master": float(settings.get("master", 0.8)),
		"Music": float(settings.get("music", 0.65)),
		"SFX": float(settings.get("sfx", 0.85)),
	}
	for bus_name: String in buses:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var value := clampf(float(buses[bus_name]), 0.0, 1.0)
		AudioServer.set_bus_mute(bus_index, value <= 0.001)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))


func _show_toast(message: String) -> void:
	toast_label.text = message
	toast_panel.modulate.a = 1.0
	toast_panel.show()
	toast_time = 2.2


func _set_audio_mode(mode: StringName) -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("set_music_mode"):
		audio.call("set_music_mode", mode)


func _format_time(seconds: float) -> String:
	var total := maxi(0, floori(seconds))
	return "%02d:%02d" % [total / 60, total % 60]


# -----------------------------------------------------------------------------
# V4 commercial UI reset
# -----------------------------------------------------------------------------

func _v4_build_desktop_screen(next_screen: StringName) -> void:
	match next_screen:
		SCREEN_TITLE: _v4_build_title(false)
		SCREEN_HUB: _v5_build_hub(false)
		SCREEN_STAGES: _v4_build_stages(false)
		SCREEN_LOADOUT: _v5_build_loadout(false)
		SCREEN_INVENTORY: _v4_build_inventory(false)
		SCREEN_SPIRIT_BEAST: _v4_build_spirit_beast(false)
		SCREEN_TECHNIQUES: _v5_build_techniques(false)
		SCREEN_CODEX: _v4_build_codex(false)
		SCREEN_ACHIEVEMENTS: _v5_build_achievements(false)
		SCREEN_SETTINGS: _v4_build_settings(false)
		SCREEN_RESULTS: _v5_build_results(false)


func _v4_build_phone_screen(next_screen: StringName) -> void:
	match next_screen:
		SCREEN_TITLE: _v4_build_title(true)
		SCREEN_HUB: _v5_build_hub(true)
		SCREEN_STAGES: _v4_build_stages(true)
		SCREEN_LOADOUT: _v5_build_loadout(true)
		SCREEN_INVENTORY: _v4_build_inventory(true)
		SCREEN_SPIRIT_BEAST: _v4_build_spirit_beast(true)
		SCREEN_TECHNIQUES: _v5_build_techniques(true)
		SCREEN_CODEX: _v4_build_codex(true)
		SCREEN_ACHIEVEMENTS: _v5_build_achievements(true)
		SCREEN_SETTINGS: _v4_build_settings(true)
		SCREEN_RESULTS: _v5_build_results(true)


func _v4_plate(rect: Rect2, paper := false, accent: Color = V4_BRONZE, strong := false) -> Control:
	var plate := V4Plate.new()
	plate.position = rect.position
	plate.size = rect.size
	plate.configure(Color(V4_PAPER, 0.97) if paper else Color(V4_INK, 0.94), Color(accent, 0.86 if strong else 0.58), 16.0 if strong else 10.0, paper, strong)
	# Keep tiny badges/stat cells native; the authored frames have deliberately
	# substantial hardware and are only nine-sliced inside their verified range.
	if rect.size.x >= 300.0 and rect.size.y >= 180.0:
		if paper:
			plate.use_authored(V4_PAPER_FOLIO, Vector4(64.0, 62.0, 64.0, 62.0))
		elif strong:
			plate.use_authored(V4_RESULT_FRAME, Vector4(68.0, 58.0, 68.0, 58.0))
		else:
			plate.use_authored(V4_MAJOR_PANEL, Vector4(86.0, 78.0, 86.0, 78.0))
	return plate


func _v4_add_plate(rect: Rect2, paper := false, accent: Color = V4_BRONZE, strong := false) -> Control:
	var plate := _v4_plate(rect, paper, accent, strong)
	screen_root.add_child(plate)
	return plate


func _v4_add_rule(rect: Rect2, color: Color = V4_BRONZE) -> void:
	var rule := ColorRect.new()
	rule.position = rect.position
	rule.size = rect.size
	rule.color = color
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(rule)


func _v4_add_art(path: String, rect: Rect2, tint: Color = Color.WHITE) -> TextureRect:
	var art := _texture(path, rect)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.modulate = tint
	screen_root.add_child(art)
	return art


func _v4_grade_art(art: TextureRect, saturation: float, tint: Color) -> void:
	var shader := Shader.new()
	shader.code = V4_ART_GRADE_SHADER
	var grade := ShaderMaterial.new()
	grade.shader = shader
	grade.set_shader_parameter(&"saturation", clampf(saturation, 0.0, 1.0))
	grade.set_shader_parameter(&"ink_tint", tint)
	art.material = grade


func _v4_add_text(text_value: String, rect: Rect2, size_px: int, color: Color, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return _v4_text_to(screen_root, text_value, rect, size_px, color, bold, align)


func _v4_text_to(parent: Control, text_value: String, rect: Rect2, size_px: int, color: Color, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var text_node := _label(text_value, size_px, color, bold)
	if phone_layout_active:
		# Small captions were previously clamped back to 14 px, which made compact
		# mobile folios print through their title and action cartouches.
		text_node.add_theme_font_size_override(&"font_size", maxi(10, size_px))
	text_node.position = rect.position
	text_node.size = rect.size
	text_node.horizontal_alignment = align
	parent.add_child(text_node)
	return text_node


func _v4_meta_background(glaze_alpha := 0.48) -> void:
	_set_background(HUB_ART_PATH, Color(V4_INK, glaze_alpha))


func _v4_header(title_text: String, subtitle_text: String, phone: bool, show_back := true) -> Rect2:
	if phone:
		var safe := _phone_safe_rect()
		var left := safe.position.x
		if show_back:
			var back := _button("TRỞ VỀ", RasterButton.ArtVariant.INK, Vector2(116.0, 64.0), 14, _back)
			back.position = Vector2(left, safe.position.y)
			back.size = Vector2(116.0, 64.0)
			screen_root.add_child(back)
			left += 130.0
		var title_width := maxf(176.0, safe.end.x - left - PHONE_CURRENCY_WIDTH - 12.0)
		_v4_add_text(title_text, Rect2(left, safe.position.y + 5.0, title_width, 27.0), 20, V4_PAPER, true)
		_v4_add_text(subtitle_text, Rect2(left, safe.position.y + 33.0, title_width, 21.0), 13, V4_PAPER_MUTED)
		var currency := _v4_add_text("%d LINH NGỌC" % _profile_value("currency", 0), Rect2(safe.end.x - PHONE_CURRENCY_WIDTH, safe.position.y + 15.0, PHONE_CURRENCY_WIDTH, 28.0), 15, V4_GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
		currency.name = "PhoneCurrency"
		_v4_add_rule(Rect2(safe.position.x, safe.position.y + 67.0, safe.size.x, 1.0), Color(V4_BRONZE, 0.66))
		return Rect2(safe.position.x, safe.position.y + 76.0, safe.size.x, safe.size.y - 76.0)
	if show_back:
		var back := _button("TRỞ VỀ", RasterButton.ArtVariant.INK, Vector2(164.0, 64.0), 16, _back)
		back.position = Vector2(54.0, 28.0)
		back.size = Vector2(164.0, 64.0)
		screen_root.add_child(back)
	var title_x := 246.0 if show_back else 66.0
	_v4_add_text(title_text, Rect2(title_x, 28.0, 710.0, 42.0), 32, V4_PAPER, true)
	_v4_add_text(subtitle_text, Rect2(title_x, 72.0, 720.0, 24.0), 16, V4_PAPER_MUTED)
	var header_ornament := TextureRect.new()
	header_ornament.name = "V4AuthoredHeaderPlaque"
	header_ornament.position = Vector2(1006.0, 35.0)
	header_ornament.size = Vector2(214.0, 46.0)
	header_ornament.texture = V4_HEADER_PLAQUE
	header_ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_ornament.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_ornament.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	header_ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(header_ornament)
	_v4_add_text("%d LINH NGỌC" % _profile_value("currency", 0), Rect2(1270.0, 39.0, 270.0, 34.0), 20, V4_GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	_v4_add_rule(Rect2(54.0, 108.0, 1492.0, 1.0), Color(V4_BRONZE, 0.64))
	return Rect2(54.0, 126.0, 1492.0, 720.0)


func _v4_build_title(phone: bool) -> void:
	_set_background(TITLE_ART_PATH, Color(V4_PAPER, 0.10 if not phone else 0.04))
	if phone:
		var safe := _phone_safe_rect()
		var panel_rect := Rect2(safe.position.x, safe.position.y, 354.0, safe.size.y)
		_v4_add_plate(panel_rect, true, V4_BRONZE, true)
		_v4_add_text("VÂN MỘNG\nTU TIÊN", Rect2(panel_rect.position.x + 30.0, panel_rect.position.y + 38.0, panel_rect.size.x - 60.0, 82.0), 30, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_rule(Rect2(panel_rect.position.x + 110.0, panel_rect.position.y + 132.0, panel_rect.size.x - 220.0, 2.0), Color(V4_JADE, 0.82))
		_v4_add_text("NHẤT NIỆM NHẬP ĐẠO", Rect2(panel_rect.position.x + 24.0, panel_rect.position.y + 146.0, panel_rect.size.x - 48.0, 24.0), 14, Color("#2f7469"), true, HORIZONTAL_ALIGNMENT_CENTER)
		var lore := _v4_add_text("Chọn công pháp, vượt ma kiếp và định lại đạo đồ.", Rect2(panel_rect.position.x + 36.0, panel_rect.position.y + 176.0, panel_rect.size.x - 72.0, 46.0), 15, PAPER_COPY, false, HORIZONTAL_ALIGNMENT_CENTER)
		lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var enter := _button("TIẾP TỤC ĐẠO ĐỒ" if _profile_value("runs", 0) > 0 else "KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(294.0, 64.0), 17, func() -> void: _show_screen(SCREEN_HUB))
		enter.position = Vector2(panel_rect.position.x + 30.0, panel_rect.position.y + 226.0)
		enter.size = Vector2(294.0, 64.0)
		screen_root.add_child(enter)
		var settings_button := _button("TĨNH TÂM", RasterButton.ArtVariant.INK, Vector2(143.0, 64.0), 14, func() -> void: _show_screen(SCREEN_SETTINGS))
		settings_button.position = Vector2(panel_rect.position.x + 30.0, panel_rect.end.y - 70.0)
		settings_button.size = Vector2(143.0, 64.0)
		screen_root.add_child(settings_button)
		var quit := _button("THOÁT", RasterButton.ArtVariant.INK, Vector2(143.0, 64.0), 14, _quit_game)
		quit.position = Vector2(panel_rect.position.x + 181.0, panel_rect.end.y - 70.0)
		quit.size = Vector2(143.0, 64.0)
		screen_root.add_child(quit)
		return
	_v4_add_text("VÂN MỘNG\nTU TIÊN", Rect2(104.0, 250.0, 410.0, 132.0), 47, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_rule(Rect2(235.0, 402.0, 148.0, 2.0), Color(V4_JADE, 0.78))
	_v4_add_text("MỘT NIỆM NHẬP ĐẠO", Rect2(112.0, 422.0, 394.0, 30.0), 16, Color("#315e58"), true, HORIZONTAL_ALIGNMENT_CENTER)
	var enter := _button("TIẾP TỤC ĐẠO ĐỒ" if _profile_value("runs", 0) > 0 else "KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(324.0, 66.0), 19, func() -> void: _show_screen(SCREEN_HUB))
	enter.position = Vector2(146.0, 492.0)
	enter.size = Vector2(324.0, 66.0)
	screen_root.add_child(enter)
	var settings_button := _button("TĨNH TÂM", RasterButton.ArtVariant.INK, Vector2(324.0, 64.0), 17, func() -> void: _show_screen(SCREEN_SETTINGS))
	settings_button.position = Vector2(146.0, 574.0)
	settings_button.size = Vector2(324.0, 64.0)
	screen_root.add_child(settings_button)
	_v4_add_text("ENTER · XÁC NHẬN     ESC · QUAY LẠI", Rect2(116.0, 824.0, 430.0, 24.0), 14, Color(PAPER_INK, 0.72), false, HORIZONTAL_ALIGNMENT_CENTER)


func _v4_build_hub(phone: bool) -> void:
	_v4_meta_background(0.30 if not phone else 0.25)
	var doctrine := _discipline_data(_selected_discipline())
	var stage := _stage_data(_selected_stage())
	var discipline_key := _discipline_technique_key(_selected_discipline())
	var ranks: Dictionary = _profile_snapshot().get("technique_ranks", {}) as Dictionary
	var rank := int(ranks.get(String(discipline_key), 0))
	if phone:
		var safe := _phone_safe_rect()
		_v4_add_text("SƠN MÔN VÂN MỘNG", Rect2(safe.position.x, safe.position.y, 350.0, 30.0), 23, V4_PAPER, true)
		_v4_add_text("THẮNG %d · CÔNG LỰC %d" % [_profile_value("victories", 0), _account_power()], Rect2(safe.position.x, safe.position.y + 30.0, 290.0, 22.0), 14, V4_PAPER_MUTED)
		_v4_add_text("%d LINH NGỌC" % _profile_value("currency", 0), Rect2(safe.end.x - 170.0, safe.position.y + 10.0, 170.0, 26.0), 16, V4_GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
		var top_y := safe.position.y + 54.0
		var identity := Rect2(safe.position.x, top_y, 184.0, 164.0)
		var identity_plate := _v4_add_plate(identity, true, V4_BRONZE, true)
		identity_plate.name = "HubIdentityPlate"
		# The approved hub hierarchy starts with the cultivator, not a floating
		# ability icon. The smaller discipline seal overlaps the portrait as a
		# secondary identity cue and reuses the already accepted portrait family.
		_v4_add_art(PLAYER_PORTRAIT_PATH, Rect2(identity.position.x + 8.0, identity.position.y + 8.0, 112.0, 104.0), Color(0.92, 0.95, 0.91, 0.96))
		_v4_add_art(str(DISCIPLINE_ICONS.get(String(_selected_discipline()), ICON_SWORD_PATH)), Rect2(identity.position.x + 112.0, identity.position.y + 28.0, 58.0, 58.0), Color(0.88, 0.96, 0.92, 0.94))
		_v4_add_text(str(doctrine.get("name", "Vạn Kiếm Quy Tông")), Rect2(identity.position.x + 10.0, identity.position.y + 108.0, identity.size.x - 20.0, 26.0), 16, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text("TÂM PHÁP · TẦNG %d" % rank, Rect2(identity.position.x + 10.0, identity.position.y + 136.0, identity.size.x - 20.0, 18.0), 13, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		var change := _button("ĐỔI TÂM PHÁP", RasterButton.ArtVariant.INK, Vector2(identity.size.x, 64.0), 13, func() -> void: _show_screen(SCREEN_LOADOUT))
		change.position = Vector2(identity.position.x, identity.end.y + 4.0)
		change.size = Vector2(identity.size.x, 64.0)
		screen_root.add_child(change)
		var expedition := Rect2(identity.end.x + 10.0, top_y, 278.0, 164.0)
		var expedition_plate := _v4_add_plate(expedition, false, V4_GOLD, true)
		expedition_plate.name = "HubExpeditionPlate"
		_v4_add_art(str(STAGE_ART.get(String(_selected_stage()), STAGE_ART["van_mong"])), Rect2(expedition.position.x + 10.0, expedition.position.y + 10.0, expedition.size.x - 20.0, 88.0))
		_v4_add_text("THÍ LUYỆN ĐANG CHỌN", Rect2(expedition.position.x + 14.0, expedition.position.y + 102.0, expedition.size.x - 28.0, 18.0), 12, V4_GOLD, true)
		_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(expedition.position.x + 14.0, expedition.position.y + 124.0, expedition.size.x - 28.0, 26.0), 18, V4_PAPER, true)
		var depart := _button("KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(expedition.size.x, 64.0), 16, func() -> void: _show_screen(SCREEN_LOADOUT))
		depart.position = Vector2(expedition.position.x, expedition.end.y + 4.0)
		depart.size = Vector2(expedition.size.x, 64.0)
		screen_root.add_child(depart)
		var rail_x := expedition.end.x + 10.0
		var rail_width := safe.end.x - rail_x
		var rail_commands := [
			["HÀNH TRÌNH", RasterButton.ArtVariant.GOLD, func() -> void: _show_screen(SCREEN_STAGES)],
			["VẠN TƯỢNG", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_CODEX)],
			["THÀNH TỰU", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_ACHIEVEMENTS)],
			["THIẾT LẬP", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_SETTINGS)],
		]
		for index in rail_commands.size():
			var command: Array = rail_commands[index]
			var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(rail_width, 64.0), 13, command[2] as Callable)
			button.position = Vector2(rail_x, top_y + index * 66.0)
			button.size = Vector2(rail_width, 64.0)
			screen_root.add_child(button)
		var bottom_commands := [
			["CÔNG PHÁP", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_TECHNIQUES)],
			["PHÁP BẢO", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_INVENTORY)],
			["LINH THÚ", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_SPIRIT_BEAST)],
		]
		var bottom_width := (expedition.end.x - safe.position.x - 12.0) / 3.0
		for index in bottom_commands.size():
			var command: Array = bottom_commands[index]
			var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(bottom_width, 64.0), 13, command[2] as Callable)
			button.position = Vector2(safe.position.x + index * (bottom_width + 6.0), safe.end.y - 64.0)
			button.size = Vector2(bottom_width, 64.0)
			screen_root.add_child(button)
		return
	_v4_add_text("SƠN MÔN", Rect2(64.0, 28.0, 360.0, 48.0), 36, V4_PAPER, true)
	_v4_add_text("VÂN MỘNG ĐẠO TÔNG · NGOẠI VIỆN", Rect2(66.0, 74.0, 460.0, 24.0), 14, V4_PAPER_MUTED, true)
	_v4_add_text("%d LINH NGỌC" % _profile_value("currency", 0), Rect2(1262.0, 44.0, 274.0, 32.0), 20, V4_GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	_v4_add_rule(Rect2(62.0, 108.0, 1476.0, 1.0), Color(V4_BRONZE, 0.62))
	var identity := Rect2(64.0, 132.0, 338.0, 692.0)
	var identity_plate := _v4_add_plate(identity, true, V4_BRONZE, true)
	identity_plate.name = "HubIdentityPlate"
	_v4_add_art(PLAYER_PORTRAIT_PATH, Rect2(94.0, 154.0, 274.0, 246.0), Color(0.92, 0.95, 0.91, 0.97))
	_v4_add_art(str(DISCIPLINE_ICONS.get(String(_selected_discipline()), ICON_SWORD_PATH)), Rect2(276.0, 308.0, 92.0, 92.0), Color(0.88, 0.96, 0.92, 0.96))
	_v4_add_text("KIẾM TU VÂN MỘNG", Rect2(98.0, 414.0, 270.0, 24.0), 14, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text(str(doctrine.get("name", "Vạn Kiếm Quy Tông")), Rect2(88.0, 450.0, 290.0, 58.0), 24, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var doctrine_copy := _v4_add_text(str(doctrine.get("description", "")), Rect2(100.0, 522.0, 266.0, 90.0), 17, PAPER_COPY, false, HORIZONTAL_ALIGNMENT_CENTER)
	doctrine_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v4_add_text("TẦNG %d / 5  ·  CÔNG LỰC %d" % [rank, _account_power()], Rect2(98.0, 632.0, 270.0, 26.0), 15, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var change := _button("ĐỔI TÂM PHÁP", RasterButton.ArtVariant.INK, Vector2(270.0, 64.0), 16, func() -> void: _show_screen(SCREEN_LOADOUT))
	change.position = Vector2(98.0, 724.0)
	change.size = Vector2(270.0, 64.0)
	screen_root.add_child(change)
	var expedition := Rect2(426.0, 132.0, 760.0, 590.0)
	var expedition_plate := _v4_add_plate(expedition, false, V4_GOLD, true)
	expedition_plate.name = "HubExpeditionPlate"
	_v4_add_art(str(STAGE_ART.get(String(_selected_stage()), STAGE_ART["van_mong"])), Rect2(448.0, 154.0, 716.0, 402.0))
	_v4_add_text("THÍ LUYỆN ĐANG CHỌN", Rect2(468.0, 574.0, 330.0, 24.0), 14, V4_GOLD, true)
	_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(468.0, 604.0, 430.0, 42.0), 29, V4_PAPER, true)
	_v4_add_text("HIỂM HỌA %d/3 · %d+ NGỌC" % [int(stage.get("difficulty", 1)), int((stage.get("rewards", {}) as Dictionary).get("base", 30))], Rect2(900.0, 612.0, 232.0, 30.0), 15, V4_PAPER_MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)
	var depart := _button("KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(276.0, 66.0), 18, func() -> void: _show_screen(SCREEN_LOADOUT))
	depart.position = Vector2(878.0, 648.0)
	depart.size = Vector2(276.0, 66.0)
	screen_root.add_child(depart)
	var command_rect := Rect2(1210.0, 132.0, 326.0, 692.0)
	_v4_add_plate(command_rect, false, V4_BRONZE, false)
	_v4_add_text("ĐẠO LỆNH", Rect2(1236.0, 162.0, 274.0, 30.0), 19, V4_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	var rail_commands := [
		["HÀNH TRÌNH", RasterButton.ArtVariant.GOLD, func() -> void: _show_screen(SCREEN_STAGES)],
		["VẠN TƯỢNG PHỔ", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_CODEX)],
		["THÀNH TỰU", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_ACHIEVEMENTS)],
		["THIẾT LẬP", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_SETTINGS)],
	]
	for index in rail_commands.size():
		var command: Array = rail_commands[index]
		var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(274.0, 64.0), 15, command[2] as Callable)
		button.position = Vector2(1236.0, 216.0 + index * 82.0)
		button.size = Vector2(274.0, 64.0)
		screen_root.add_child(button)
	_v4_add_text("HỒ SƠ ĐẠO ĐỒ", Rect2(1236.0, 572.0, 274.0, 22.0), 13, V4_GOLD, true)
	_v4_add_text("THẮNG %d\nTRẢM YÊU %d\nCÔNG LỰC %d" % [_profile_value("victories", 0), _profile_value("kills", 0), _account_power()], Rect2(1236.0, 606.0, 274.0, 84.0), 16, V4_PAPER_MUTED)
	var bottom_commands := [
		["CÔNG PHÁP", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_TECHNIQUES)],
		["PHÁP BẢO", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_INVENTORY)],
		["LINH THÚ", RasterButton.ArtVariant.JADE, func() -> void: _show_screen(SCREEN_SPIRIT_BEAST)],
	]
	for index in bottom_commands.size():
		var command: Array = bottom_commands[index]
		var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(244.0, 72.0), 16, command[2] as Callable)
		button.position = Vector2(426.0 + index * 254.0, 744.0)
		button.size = Vector2(244.0, 72.0)
		screen_root.add_child(button)


func _v4_build_stages(phone: bool) -> void:
	_v4_meta_background(0.62 if not phone else 0.56)
	var body := _v4_header("CHỌN THÍ LUYỆN", "Ba cảnh giới · chọn đường nhập đạo", phone)
	var stages := _stages()
	var current_id := _selected_stage()
	if phone:
		var gap := 8.0
		var card_width := (body.size.x - gap * 2.0) / 3.0
		var card_height := body.size.y - 70.0
		for index in mini(3, stages.size()):
			var stage: Dictionary = stages[index]
			var stage_id := StringName(str(stage.get("id", "van_mong")))
			var unlocked := bool(stage.get("unlocked", false))
			var selected := stage_id == current_id
			var rect := Rect2(body.position.x + index * (card_width + gap), body.position.y, card_width, card_height)
			_v4_add_plate(rect, true, V4_JADE if selected else (V4_BRONZE if unlocked else V4_CINNABAR), selected)
			_v4_add_art(str(STAGE_ART.get(String(stage_id), STAGE_ART["van_mong"])), Rect2(rect.position.x + 9.0, rect.position.y + 9.0, rect.size.x - 18.0, 72.0), Color.WHITE if unlocked else Color(0.34, 0.34, 0.33, 0.92))
			_v4_add_text("ĐÃ CHỌN" if selected else ("ĐÃ KHAI MỞ" if unlocked else "PHONG ẤN"), Rect2(rect.position.x + 10.0, rect.position.y + 84.0, rect.size.x - 20.0, 19.0), 11, Color("#2f7469") if unlocked else V4_CINNABAR, true, HORIZONTAL_ALIGNMENT_CENTER)
			_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(rect.position.x + 10.0, rect.position.y + 106.0, rect.size.x - 20.0, 26.0), 15, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
			_v4_add_text("HIỂM HỌA %d/3 · %d NGỌC" % [int(stage.get("difficulty", 1)), int((stage.get("rewards", {}) as Dictionary).get("base", 30))], Rect2(rect.position.x + 8.0, rect.position.y + 136.0, rect.size.x - 16.0, 20.0), 12, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
			var choose := _button("ĐANG CHỌN" if selected else ("CHỌN CẢNH" if unlocked else "CHƯA MỞ"), RasterButton.ArtVariant.JADE if selected else RasterButton.ArtVariant.INK, Vector2(rect.size.x - 16.0, 64.0), 12, func() -> void: _select_stage(stage_id))
			choose.position = Vector2(rect.position.x + 8.0, rect.end.y - 66.0)
			choose.size = Vector2(rect.size.x - 16.0, 64.0)
			choose.disabled = not unlocked
			choose.call_deferred("_refresh_visual_state")
			screen_root.add_child(choose)
		var description := _v4_add_text(str(_stage_data(current_id).get("description", "")), Rect2(body.position.x, body.end.y - 64.0, body.size.x - 306.0, 58.0), 13, V4_PAPER_MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var proceed := _button("CHUẨN BỊ", RasterButton.ArtVariant.GOLD, Vector2(296.0, 64.0), 17, func() -> void: _show_screen(SCREEN_LOADOUT))
		proceed.position = Vector2(body.end.x - 296.0, body.end.y - 64.0)
		proceed.size = Vector2(296.0, 64.0)
		screen_root.add_child(proceed)
		return
	var gap := 24.0
	var card_width := (body.size.x - gap * 2.0) / 3.0
	for index in mini(3, stages.size()):
		var stage: Dictionary = stages[index]
		var stage_id := StringName(str(stage.get("id", "van_mong")))
		var unlocked := bool(stage.get("unlocked", false))
		var selected := stage_id == current_id
		var rect := Rect2(body.position.x + index * (card_width + gap), body.position.y, card_width, 620.0)
		_v4_add_plate(rect, true, V4_JADE if selected else (V4_BRONZE if unlocked else V4_CINNABAR), selected)
		_v4_add_art(str(STAGE_ART.get(String(stage_id), STAGE_ART["van_mong"])), Rect2(rect.position.x + 24.0, rect.position.y + 28.0, rect.size.x - 48.0, 226.0), Color.WHITE if unlocked else Color(0.34, 0.34, 0.33, 0.92))
		_v4_add_text("ĐÃ CHỌN" if selected else ("ĐÃ KHAI MỞ" if unlocked else "PHONG ẤN"), Rect2(rect.position.x + 30.0, rect.position.y + 274.0, rect.size.x - 60.0, 24.0), 14, Color("#2f7469") if unlocked else V4_CINNABAR, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(rect.position.x + 30.0, rect.position.y + 310.0, rect.size.x - 60.0, 42.0), 27, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text("HIỂM HỌA %d / 3" % int(stage.get("difficulty", 1)), Rect2(rect.position.x + 32.0, rect.position.y + 362.0, rect.size.x - 64.0, 28.0), 16, V4_CINNABAR if unlocked else PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
		var description := _v4_add_text(str(stage.get("description", "")), Rect2(rect.position.x + 42.0, rect.position.y + 406.0, rect.size.x - 84.0, 86.0), 17, PAPER_COPY, false, HORIZONTAL_ALIGNMENT_CENTER)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_v4_add_text("THƯỞNG %d+ LINH NGỌC" % int((stage.get("rewards", {}) as Dictionary).get("base", 30)), Rect2(rect.position.x + 34.0, rect.position.y + 500.0, rect.size.x - 68.0, 24.0), 14, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		var choose := _button("ĐANG CHỌN" if selected else ("CHỌN CẢNH" if unlocked else "CHƯA KHAI MỞ"), RasterButton.ArtVariant.JADE if selected else RasterButton.ArtVariant.INK, Vector2(rect.size.x - 92.0, 64.0), 16, func() -> void: _select_stage(stage_id))
		choose.position = Vector2(rect.position.x + 46.0, rect.end.y - 82.0)
		choose.size = Vector2(rect.size.x - 92.0, 64.0)
		choose.disabled = not unlocked
		choose.call_deferred("_refresh_visual_state")
		screen_root.add_child(choose)
	var proceed := _button("CHUẨN BỊ CÔNG PHÁP", RasterButton.ArtVariant.GOLD, Vector2(408.0, 70.0), 18, func() -> void: _show_screen(SCREEN_LOADOUT))
	proceed.position = Vector2(596.0, 766.0)
	proceed.size = Vector2(408.0, 70.0)
	screen_root.add_child(proceed)


func _v4_build_loadout(phone: bool) -> void:
	_v4_meta_background(0.64 if not phone else 0.58)
	var stage := _stage_data(_selected_stage())
	var body := _v4_header("CHỌN TÂM PHÁP", str(stage.get("name", "Vân Mộng Cốc")), phone)
	var disciplines := _disciplines()
	var selected := _selected_discipline()
	var gap := 8.0 if phone else 24.0
	var card_width := (body.size.x - gap * 2.0) / 3.0
	var card_height := body.size.y - (70.0 if phone else 102.0)
	for index in mini(3, disciplines.size()):
		var discipline: Dictionary = disciplines[index]
		var discipline_id := StringName(str(discipline.get("id", "van_kiem")))
		var is_selected := discipline_id == selected
		var rect := Rect2(body.position.x + index * (card_width + gap), body.position.y, card_width, card_height)
		_v4_add_plate(rect, true, V4_JADE if is_selected else V4_BRONZE, is_selected)
		var icon_size := 76.0 if phone else 210.0
		_v4_add_art(str(DISCIPLINE_ICONS.get(String(discipline_id), ICON_SWORD_PATH)), Rect2(rect.position.x + (rect.size.x - icon_size) * 0.5, rect.position.y + (10.0 if phone else 32.0), icon_size, icon_size), Color(0.90, 0.96, 0.92, 0.96))
		var title_y := rect.position.y + (90.0 if phone else 266.0)
		_v4_add_text(str(discipline.get("role", "Công kích")).to_upper(), Rect2(rect.position.x + 20.0, title_y, rect.size.x - 40.0, 22.0), 13 if phone else 15, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(str(discipline.get("name", "Vạn Kiếm Quy Tông")), Rect2(rect.position.x + 18.0, title_y + (24.0 if phone else 26.0), rect.size.x - 36.0, 28.0 if phone else 46.0), 17 if phone else 27, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		if not phone:
			var description := _v4_add_text(str(discipline.get("description", "")), Rect2(rect.position.x + 46.0, title_y + 90.0, rect.size.x - 92.0, 120.0), 17, PAPER_COPY, false, HORIZONTAL_ALIGNMENT_CENTER)
			description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			_v4_add_text(_phone_discipline_copy(discipline_id), Rect2(rect.position.x + 10.0, title_y + 52.0, rect.size.x - 20.0, 16.0), 13, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
		var equip := _button("ĐÃ TRANG BỊ" if is_selected else "TRANG BỊ", RasterButton.ArtVariant.JADE if is_selected else RasterButton.ArtVariant.INK, Vector2(rect.size.x - (16.0 if phone else 84.0), 64.0), 14 if phone else 16, func() -> void: _select_discipline(discipline_id))
		equip.position = Vector2(rect.position.x + (8.0 if phone else 42.0), rect.end.y - (66.0 if phone else 82.0))
		equip.size = Vector2(rect.size.x - (16.0 if phone else 84.0), 64.0)
		screen_root.add_child(equip)
	if phone:
		_v4_add_text("%s · HIỂM HỌA %d/3" % [str(_discipline_data(selected).get("name", "Vạn Kiếm Quy Tông")), int(stage.get("difficulty", 1))], Rect2(body.position.x, body.end.y - 58.0, body.size.x - 296.0, 50.0), 15, V4_PAPER_MUTED, true)
		var start := _button("NHẬP CẢNH", RasterButton.ArtVariant.GOLD, Vector2(288.0, 64.0), 18, _start_selected_run)
		start.position = Vector2(body.end.x - 288.0, body.end.y - 64.0)
		start.size = Vector2(288.0, 64.0)
		screen_root.add_child(start)
		return
	var footer := Rect2(330.0, 754.0, 940.0, 84.0)
	_v4_add_plate(footer, false, V4_BRONZE, false)
	_v4_add_text("%s · %s · HIỂM HỌA %d/3" % [str(stage.get("name", "Vân Mộng Cốc")), str(_discipline_data(selected).get("name", "Vạn Kiếm Quy Tông")), int(stage.get("difficulty", 1))], Rect2(362.0, 774.0, 560.0, 40.0), 17, V4_PAPER, true)
	var start := _button("NHẬP CẢNH", RasterButton.ArtVariant.GOLD, Vector2(292.0, 64.0), 19, _start_selected_run)
	start.position = Vector2(950.0, 764.0)
	start.size = Vector2(292.0, 64.0)
	screen_root.add_child(start)


func _v4_build_inventory(phone: bool) -> void:
	_v4_meta_background(0.70 if not phone else 0.66)
	var body := _v4_header("KHO PHÁP BẢO", "Trang bị · so sánh · trấn pháp", phone)
	var items := _inventory_items()
	var chosen := _item_by_id(selected_item_id)
	if phone:
		var identity_width := 174.0
		var grid_width := 356.0
		var detail_x := body.position.x + identity_width + grid_width + 14.0
		var detail_width := body.end.x - detail_x
		_v4_add_plate(Rect2(body.position.x, body.position.y, identity_width - 8.0, body.size.y), true, V4_BRONZE, true)
		_v4_add_art("res://assets/generated/runtime/player_idle.png", Rect2(body.position.x + 20.0, body.position.y + 16.0, identity_width - 48.0, 142.0))
		_v4_add_text("KIẾM TU\nVÂN MỘNG", Rect2(body.position.x + 12.0, body.position.y + 160.0, identity_width - 32.0, 52.0), 16, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text("CÔNG LỰC %d" % _account_power(), Rect2(body.position.x + 12.0, body.position.y + 216.0, identity_width - 32.0, 22.0), 13, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_plate(Rect2(body.position.x + identity_width, body.position.y, grid_width, body.size.y), false, V4_BRONZE, false)
		var slot_width := (grid_width - 24.0) / 4.0
		var slot_height := (body.size.y - 18.0) / 3.0
		for index in mini(12, items.size()):
			var item: Dictionary = items[index]
			var col := index % 4
			var row := index / 4
			var item_id := str(item.get("id", "item_%d" % index))
			ComponentKitScript.item_slot(screen_root, item_id, str(item.get("name", "Pháp bảo")), str(item.get("rarity", "Linh")), Rect2(body.position.x + identity_width + 6.0 + col * (slot_width + 4.0), body.position.y + 5.0 + row * (slot_height + 4.0), slot_width, slot_height), _load_texture(str(item.get("icon_path", ICON_SWORD_PATH))), item_id == selected_item_id, func() -> void: _select_inventory_item(item_id), 1.1, false)
		_v4_add_plate(Rect2(detail_x, body.position.y, detail_width, body.size.y), false, _rarity_color(str(chosen.get("rarity", "Huyền"))), true)
		_v4_add_art(str(chosen.get("icon_path", ICON_SWORD_PATH)), Rect2(detail_x + 38.0, body.position.y + 12.0, detail_width - 76.0, 96.0))
		_v4_add_text(str(chosen.get("name", "Huyền Vân Kiếm")), Rect2(detail_x + 14.0, body.position.y + 110.0, detail_width - 28.0, 54.0), 20, V4_PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text("%s · CẤP %d" % [str(chosen.get("rarity", "Huyền")).to_upper(), int(chosen.get("level", 1))], Rect2(detail_x + 14.0, body.position.y + 164.0, detail_width - 28.0, 24.0), 14, _rarity_color(str(chosen.get("rarity", "Huyền"))), true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text("KIẾM +18% · HỒI -8%", Rect2(detail_x + 18.0, body.position.y + 198.0, detail_width - 36.0, 26.0), 14, V4_PAPER_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
		var equip := _button("TRANG BỊ", RasterButton.ArtVariant.GOLD, Vector2(detail_width - 20.0, 64.0), 16, func() -> void: _equip_item(selected_item_id))
		equip.position = Vector2(detail_x + 10.0, body.end.y - 64.0)
		equip.size = Vector2(detail_width - 20.0, 64.0)
		screen_root.add_child(equip)
		return
	var identity := Rect2(body.position.x, body.position.y, 360.0, body.size.y)
	var grid := Rect2(identity.end.x + 20.0, body.position.y, 690.0, body.size.y)
	var detail := Rect2(grid.end.x + 20.0, body.position.y, body.end.x - grid.end.x - 20.0, body.size.y)
	_v4_add_plate(identity, true, V4_BRONZE, true)
	_v4_add_art("res://assets/generated/runtime/player_idle.png", Rect2(identity.position.x + 78.0, identity.position.y + 32.0, 204.0, 300.0))
	_v4_add_text("KIẾM TU VÂN MỘNG", Rect2(identity.position.x + 30.0, identity.position.y + 350.0, identity.size.x - 60.0, 40.0), 24, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("CÔNG LỰC %d · %s" % [_account_power(), str(_discipline_data(_selected_discipline()).get("name", "Vạn Kiếm"))], Rect2(identity.position.x + 28.0, identity.position.y + 398.0, identity.size.x - 56.0, 30.0), 15, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_rule(Rect2(identity.position.x + 46.0, identity.position.y + 454.0, identity.size.x - 92.0, 1.0), Color(V4_BRONZE, 0.44))
	_v4_add_text("ĐANG TRẤN PHÁP", Rect2(identity.position.x + 42.0, identity.position.y + 486.0, identity.size.x - 84.0, 24.0), 14, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var equipped_copy := _v4_add_text("KIẾM · HỘ TÂM\nĐẠO BÀO · LINH GIỚI", Rect2(identity.position.x + 52.0, identity.position.y + 520.0, identity.size.x - 104.0, 54.0), 15, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
	equipped_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_v4_add_plate(grid, true, V4_BRONZE, false)
	# Keep one paper folio, not a dark header panel stacked on top of it.
	var slot_width := (grid.size.x - 68.0) / 4.0
	var slot_height := (grid.size.y - 126.0) / 3.0
	for index in mini(12, items.size()):
		var item: Dictionary = items[index]
		var col := index % 4
		var row := index / 4
		var item_id := str(item.get("id", "item_%d" % index))
		ComponentKitScript.item_slot(screen_root, item_id, str(item.get("name", "Pháp bảo")), str(item.get("rarity", "Linh")), Rect2(grid.position.x + 16.0 + col * (slot_width + 12.0), grid.position.y + 92.0 + row * (slot_height + 10.0), slot_width, slot_height), _load_texture(str(item.get("icon_path", ICON_SWORD_PATH))), item_id == selected_item_id, func() -> void: _select_inventory_item(item_id), 1.0, true)
	_v4_add_plate(detail, false, _rarity_color(str(chosen.get("rarity", "Huyền"))), true)
	_v4_add_text("SO SÁNH PHÁP BẢO", Rect2(detail.position.x + 28.0, detail.position.y + 26.0, detail.size.x - 56.0, 28.0), 16, V4_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_art(str(chosen.get("icon_path", ICON_SWORD_PATH)), Rect2(detail.position.x + 68.0, detail.position.y + 70.0, detail.size.x - 136.0, 220.0))
	_v4_add_text(str(chosen.get("name", "Huyền Vân Kiếm")), Rect2(detail.position.x + 30.0, detail.position.y + 310.0, detail.size.x - 60.0, 54.0), 27, V4_PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("%s · CẤP %d" % [str(chosen.get("rarity", "Huyền")).to_upper(), int(chosen.get("level", 1))], Rect2(detail.position.x + 30.0, detail.position.y + 370.0, detail.size.x - 60.0, 28.0), 15, _rarity_color(str(chosen.get("rarity", "Huyền"))), true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_rule(Rect2(detail.position.x + 38.0, detail.position.y + 426.0, detail.size.x - 76.0, 1.0), Color(V4_BRONZE, 0.46))
	_v4_add_text("KIẾM Ý\nHỒI CHIÊU\nTỤ LINH\nSINH MỆNH", Rect2(detail.position.x + 44.0, detail.position.y + 458.0, 140.0, 150.0), 16, V4_PAPER_MUTED, true)
	_v4_add_text("+18%\n-8%\n+12%\n+6%", Rect2(detail.end.x - 142.0, detail.position.y + 458.0, 96.0, 150.0), 17, V4_JADE, true, HORIZONTAL_ALIGNMENT_RIGHT)
	var equip := _button("TRANG BỊ", RasterButton.ArtVariant.GOLD, Vector2(detail.size.x - 72.0, 66.0), 18, func() -> void: _equip_item(selected_item_id))
	equip.position = Vector2(detail.position.x + 36.0, detail.end.y - 84.0)
	equip.size = Vector2(detail.size.x - 72.0, 66.0)
	screen_root.add_child(equip)


func _v4_build_spirit_beast(phone: bool) -> void:
	_v4_meta_background(0.66 if not phone else 0.60)
	var body := _v4_header("LINH THÚ HỘ ĐẠO", "Thanh Vân Hồ · khế ước tầng 2 / 5", phone)
	if phone:
		var portrait := Rect2(body.position.x, body.position.y, 272.0, body.size.y)
		var detail := Rect2(portrait.end.x + 12.0, body.position.y, body.end.x - portrait.end.x - 12.0, body.size.y)
		_v4_add_plate(portrait, true, V4_BRONZE, true)
		var beast_portrait := _v4_add_art(PORTRAIT_ROOT + "thanh_van_ho.png", Rect2(portrait.position.x + 28.0, portrait.position.y + 8.0, portrait.size.x - 56.0, 178.0))
		_v4_grade_art(beast_portrait, 0.46, Color("#ded2b7"))
		_v4_add_text("THANH VÂN HỒ", Rect2(portrait.position.x + 18.0, portrait.position.y + 186.0, portrait.size.x - 36.0, 30.0), 19, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		var bind := _button("THU HỒN" if beast_bound else "XUẤT TRẬN", RasterButton.ArtVariant.JADE if beast_bound else RasterButton.ArtVariant.GOLD, Vector2(portrait.size.x - 20.0, 64.0), 15, _toggle_beast)
		bind.position = Vector2(portrait.position.x + 10.0, portrait.end.y - 64.0)
		bind.size = Vector2(portrait.size.x - 20.0, 64.0)
		screen_root.add_child(bind)
		_v4_add_plate(detail, false, V4_JADE, true)
		var tabs := ["TRỢ CHIẾN", "NỘI TẠI", "TIẾN HÓA"]
		var tab_width := (detail.size.x - 32.0) / 3.0
		for index in tabs.size():
			var tab := _button(tabs[index], RasterButton.ArtVariant.JADE if index == 0 else RasterButton.ArtVariant.INK, Vector2(tab_width, 64.0), 13, func() -> void: _show_toast("Đang xem %s" % tabs[index]))
			tab.position = Vector2(detail.position.x + 8.0 + index * (tab_width + 8.0), detail.position.y)
			tab.size = Vector2(tab_width, 64.0)
			screen_root.add_child(tab)
		_v4_add_art(str(SKILL_ICON_PATHS["thanh_van_ho"]), Rect2(detail.position.x + 30.0, detail.position.y + 86.0, 142.0, 142.0))
		_v4_add_text("SẴN SÀNG", Rect2(detail.position.x + 24.0, detail.position.y + 58.0, 154.0, 24.0), 15, V4_JADE, true, HORIZONTAL_ALIGNMENT_CENTER)
		var copy := _v4_add_text("Đánh dấu mục tiêu nguy hiểm nhất. Ba lần di chuyển: kỹ năng kế tiếp xuyên mục tiêu và hoàn 12% năng lượng.", Rect2(detail.position.x + 198.0, detail.position.y + 94.0, detail.size.x - 224.0, 106.0), 16, V4_PAPER, false)
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var milestone_width := (detail.size.x - 52.0) / 3.0
		var milestones := ["I · THỨC TỈNH", "II · DẤU ẤN", "III · 120 PHÁCH"]
		for index in milestones.size():
			_v4_add_text(milestones[index], Rect2(detail.position.x + 18.0 + index * (milestone_width + 8.0), detail.end.y - 62.0, milestone_width, 22.0), 11, V4_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var portrait := Rect2(body.position.x, body.position.y, 500.0, body.size.y)
	var detail := Rect2(portrait.end.x + 26.0, body.position.y, body.end.x - portrait.end.x - 26.0, body.size.y)
	_v4_add_plate(portrait, true, V4_BRONZE, true)
	var beast_portrait := _v4_add_art(PORTRAIT_ROOT + "thanh_van_ho.png", Rect2(portrait.position.x + 70.0, portrait.position.y + 36.0, portrait.size.x - 140.0, 430.0))
	_v4_grade_art(beast_portrait, 0.46, Color("#ded2b7"))
	_v4_add_text("THANH VÂN HỒ", Rect2(portrait.position.x + 36.0, portrait.position.y + 490.0, portrait.size.x - 72.0, 46.0), 30, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("LINH THÚ HỘ ĐẠO · KHẾ ƯỚC TẦNG 2", Rect2(portrait.position.x + 38.0, portrait.position.y + 546.0, portrait.size.x - 76.0, 28.0), 15, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var bind := _button("THU HỒN" if beast_bound else "XUẤT TRẬN", RasterButton.ArtVariant.JADE if beast_bound else RasterButton.ArtVariant.GOLD, Vector2(300.0, 66.0), 17, _toggle_beast)
	bind.position = Vector2(portrait.position.x + 100.0, portrait.end.y - 92.0)
	bind.size = Vector2(300.0, 66.0)
	screen_root.add_child(bind)
	_v4_add_plate(detail, false, V4_JADE, true)
	_v4_add_text("HỒ SƠ TRỢ CHIẾN", Rect2(detail.position.x + 42.0, detail.position.y + 34.0, 400.0, 34.0), 24, V4_PAPER, true)
	_v4_add_rule(Rect2(detail.position.x + 42.0, detail.position.y + 84.0, detail.size.x - 84.0, 1.0), Color(V4_JADE, 0.42))
	_v4_add_art(str(SKILL_ICON_PATHS["thanh_van_ho"]), Rect2(detail.position.x + 64.0, detail.position.y + 132.0, 220.0, 220.0))
	_v4_add_text("TRỢ CHIẾN · SẴN SÀNG", Rect2(detail.position.x + 70.0, detail.position.y + 356.0, 208.0, 26.0), 15, V4_JADE, true, HORIZONTAL_ALIGNMENT_CENTER)
	var copy := _v4_add_text("Đánh dấu mục tiêu nguy hiểm nhất. Sau ba lần di chuyển liên tục, kỹ năng kế tiếp xuyên mục tiêu và hoàn 12% năng lượng.", Rect2(detail.position.x + 330.0, detail.position.y + 148.0, detail.size.x - 382.0, 142.0), 19, V4_PAPER, false)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v4_add_text("NỘI TẠI KHẾ ƯỚC", Rect2(detail.position.x + 330.0, detail.position.y + 326.0, 300.0, 26.0), 15, V4_GOLD, true)
	_v4_add_text("Kỹ năng kế tiếp xuyên mục tiêu\nHoàn 12% năng lượng\nDấu ấn tồn tại 5 giây", Rect2(detail.position.x + 330.0, detail.position.y + 366.0, detail.size.x - 382.0, 110.0), 17, V4_PAPER_MUTED)
	_v4_add_rule(Rect2(detail.position.x + 54.0, detail.position.y + 520.0, detail.size.x - 108.0, 1.0), Color(V4_BRONZE, 0.42))
	_v4_add_text("I · THỨC TỈNH", Rect2(detail.position.x + 62.0, detail.position.y + 558.0, 220.0, 34.0), 16, V4_JADE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("II · DẤU ẤN", Rect2(detail.position.x + 310.0, detail.position.y + 558.0, 220.0, 34.0), 16, V4_JADE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("III · 120 TINH PHÁCH", Rect2(detail.position.x + 558.0, detail.position.y + 558.0, 250.0, 34.0), 16, V4_PAPER_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)


func _v4_build_techniques(phone: bool) -> void:
	_v4_meta_background(0.70 if not phone else 0.64)
	var body := _v4_header("CÔNG PHÁP CÁC", "Mỗi tầng đổi silhouette và hiệu ứng chiến đấu", phone)
	var techniques := _techniques()
	var gap := 8.0 if phone else 24.0
	var card_width := (body.size.x - gap * 2.0) / 3.0
	var card_height := body.size.y
	for index in mini(3, techniques.size()):
		var technique: Dictionary = techniques[index]
		var technique_id := StringName(str(technique.get("id", "sword_damage")))
		var rank := int(technique.get("rank", 0))
		var max_rank := int(technique.get("max_rank", 5))
		var cost := int(technique.get("next_cost", -1))
		var rect := Rect2(body.position.x + index * (card_width + gap), body.position.y, card_width, card_height)
		_v4_add_plate(rect, true, _technique_accent(technique_id), index == 1)
		var preview_size := 96.0 if phone else 286.0
		var preview := TechniquePreviewScript.new() as TechniquePreview
		preview.position = Vector2(rect.position.x + (rect.size.x - preview_size) * 0.5, rect.position.y + (8.0 if phone else 32.0))
		preview.size = Vector2(preview_size, preview_size)
		preview.configure(technique_id, rank, max_rank, _load_texture(str(TECHNIQUE_ICONS.get(String(technique_id), ICON_SWORD_PATH))))
		screen_root.add_child(preview)
		var title_y := rect.position.y + (105.0 if phone else 340.0)
		_v4_add_text(_technique_school(technique_id), Rect2(rect.position.x + 22.0, title_y, rect.size.x - 44.0, 24.0), 13 if phone else 15, _technique_accent(technique_id).darkened(0.36), true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(str(technique.get("name", "Kiếm Tâm")), Rect2(rect.position.x + 20.0, title_y + 28.0, rect.size.x - 40.0, 42.0), 19 if phone else 29, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text("TẦNG %d / %d" % [rank, max_rank], Rect2(rect.position.x + 20.0, title_y + 72.0, rect.size.x - 40.0, 26.0), 14 if phone else 17, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		if not phone:
			var evolution := _v4_add_text(_technique_evolution_copy(technique_id, rank, max_rank), Rect2(rect.position.x + 48.0, title_y + 126.0, rect.size.x - 96.0, 86.0), 17, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
			evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			_v4_add_text(_phone_technique_evolution_copy(technique_id, rank, max_rank), Rect2(rect.position.x + 12.0, title_y + 100.0, rect.size.x - 24.0, 24.0), 13, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
		var price_text := "ĐÃ VIÊN MÃN" if rank >= max_rank else ("NÂNG TẦNG · %d" % cost if phone else "NÂNG TẦNG · %d LINH NGỌC" % cost)
		var purchase := _button(price_text, RasterButton.ArtVariant.GOLD if rank < max_rank else RasterButton.ArtVariant.INK, Vector2(rect.size.x - (16.0 if phone else 88.0), 64.0), 14 if phone else 17, func() -> void: _purchase_technique(technique_id))
		purchase.position = Vector2(rect.position.x + (8.0 if phone else 44.0), rect.end.y - (64.0 if phone else 84.0))
		purchase.size = Vector2(rect.size.x - (16.0 if phone else 88.0), 64.0)
		purchase.disabled = rank >= max_rank
		purchase.call_deferred("_refresh_visual_state")
		screen_root.add_child(purchase)


func _v4_build_codex(phone: bool) -> void:
	_v4_meta_background(0.70 if not phone else 0.64)
	var body := _v4_header("VẠN TƯỢNG PHỔ", "Yêu vật từng gặp trên đạo đồ", phone)
	var entries := _bestiary_entries()
	if entries.is_empty():
		return
	var chosen := _bestiary_data(selected_codex)
	var discovered := bool(chosen.get("discovered", false))
	if phone:
		var tab_gap := 6.0
		var tab_width := (body.size.x - tab_gap * 4.0) / 5.0
		for index in mini(5, entries.size()):
			var entry: Dictionary = entries[index]
			var entry_id := StringName(str(entry.get("id", "mac_linh")))
			var tab := _button(str(entry.get("name", "Yêu vật")).to_upper(), RasterButton.ArtVariant.JADE if entry_id == selected_codex else RasterButton.ArtVariant.INK, Vector2(tab_width, 64.0), 12, func() -> void: _select_codex_entry(entry_id))
			tab.position = Vector2(body.position.x + index * (tab_width + tab_gap), body.position.y)
			tab.size = Vector2(tab_width, 64.0)
			screen_root.add_child(tab)
		var detail := Rect2(body.position.x, body.position.y + 68.0, body.size.x, body.size.y - 68.0)
		_v4_add_plate(detail, true, V4_BRONZE, true)
		# The frame's bronze crest and foot occupy the outer 28 px. Keep portrait and
		# copy in independent columns inside that protected rectangle.
		_v4_add_art(str(BESTIARY_VISUALS.get(String(selected_codex), "")), Rect2(detail.position.x + 30.0, detail.position.y + 30.0, 176.0, detail.size.y - 58.0), Color.WHITE if discovered else Color(0.08, 0.09, 0.09, 0.88))
		var text_x := detail.position.x + 226.0
		var text_width := detail.end.x - text_x - 34.0
		_v4_add_text(str(chosen.get("name", "Chưa ghi nhận")) if discovered else "BÓNG HÌNH CHƯA BIẾT", Rect2(text_x, detail.position.y + 50.0, text_width, 28.0), 19, PAPER_INK, true)
		_v4_add_text(("%s · %s" % [str(chosen.get("kind", "")), str(chosen.get("habitat", ""))]) if discovered else "Chưa khai mở", Rect2(text_x, detail.position.y + 80.0, text_width, 19.0), 12, BRONZE_INK, true)
		var description := _v4_add_text(str(chosen.get("description", "Dữ liệu còn bị ma vụ che phủ.")) if discovered else "Vượt thí luyện tương ứng để ghi nhận hình ảnh và tập tính.", Rect2(text_x, detail.position.y + 106.0, text_width, 40.0), 13, PAPER_COPY)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_v4_add_text("HIỂM HỌA %d/3 · YẾU QUYẾT" % int(chosen.get("threat", 0)) if discovered else "HIỂM HỌA ?/3", Rect2(text_x, detail.end.y - 50.0, text_width, 18.0), 11, V4_CINNABAR, true)
		return
	var index_rect := Rect2(body.position.x, body.position.y, 306.0, body.size.y)
	var dossier := Rect2(index_rect.end.x + 24.0, body.position.y, body.end.x - index_rect.end.x - 24.0, body.size.y)
	_v4_add_plate(index_rect, false, V4_BRONZE, false)
	_v4_add_text("ĐÃ GHI NHẬN %d / %d" % [_profile_value("bestiary_count", 1), entries.size()], Rect2(index_rect.position.x + 24.0, index_rect.position.y + 28.0, index_rect.size.x - 48.0, 26.0), 14, V4_GOLD, true)
	for index in mini(5, entries.size()):
		var entry: Dictionary = entries[index]
		var entry_id := StringName(str(entry.get("id", "mac_linh")))
		var tab := _button(str(entry.get("name", "Yêu vật")).to_upper(), RasterButton.ArtVariant.JADE if entry_id == selected_codex else RasterButton.ArtVariant.INK, Vector2(index_rect.size.x - 40.0, 64.0), 15, func() -> void: _select_codex_entry(entry_id))
		tab.position = Vector2(index_rect.position.x + 20.0, index_rect.position.y + 78.0 + index * 82.0)
		tab.size = Vector2(index_rect.size.x - 40.0, 64.0)
		screen_root.add_child(tab)
	_v4_add_plate(dossier, true, V4_BRONZE, true)
	_v4_add_art(str(BESTIARY_VISUALS.get(String(selected_codex), "")), Rect2(dossier.position.x + 50.0, dossier.position.y + 54.0, 360.0, 430.0), Color.WHITE if discovered else Color(0.08, 0.09, 0.09, 0.88))
	var text_x := dossier.position.x + 468.0
	_v4_add_text("VẠN TƯỢNG · QUYỂN %02d" % (entries.find(chosen) + 1), Rect2(text_x, dossier.position.y + 54.0, dossier.end.x - text_x - 46.0, 26.0), 14, BRONZE_INK, true)
	_v4_add_text(str(chosen.get("name", "Chưa ghi nhận")) if discovered else "BÓNG HÌNH CHƯA BIẾT", Rect2(text_x, dossier.position.y + 98.0, dossier.end.x - text_x - 46.0, 52.0), 34, PAPER_INK, true)
	_v4_add_text(("%s · %s" % [str(chosen.get("kind", "")), str(chosen.get("habitat", ""))]) if discovered else "TRANG PHỔ CHƯA KHAI MỞ", Rect2(text_x, dossier.position.y + 158.0, dossier.end.x - text_x - 46.0, 28.0), 16, BRONZE_INK, true)
	_v4_add_rule(Rect2(text_x, dossier.position.y + 210.0, dossier.end.x - text_x - 54.0, 1.0), Color(V4_BRONZE, 0.46))
	var description := _v4_add_text(str(chosen.get("description", "Dữ liệu còn bị ma vụ che phủ.")) if discovered else "Vượt thí luyện tương ứng để ghi nhận hình ảnh, tập tính và yếu quyết chiến đấu.", Rect2(text_x, dossier.position.y + 244.0, dossier.end.x - text_x - 54.0, 122.0), 18, PAPER_COPY)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v4_add_text("HIỂM HỌA CẤP %d / 3" % int(chosen.get("threat", 0)) if discovered else "HIỂM HỌA  ? / 3", Rect2(text_x, dossier.position.y + 406.0, dossier.end.x - text_x - 54.0, 30.0), 16, V4_CINNABAR, true)
	_v4_add_text("YẾU QUYẾT", Rect2(text_x, dossier.position.y + 462.0, dossier.end.x - text_x - 54.0, 26.0), 15, BRONZE_INK, true)
	var tip := _v4_add_text(str(chosen.get("combat_tip", "???")) if discovered else "Tiếp cận thí luyện để khai mở.", Rect2(text_x, dossier.position.y + 500.0, dossier.end.x - text_x - 54.0, 96.0), 18, PAPER_COPY)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _v4_build_achievements(phone: bool) -> void:
	_v4_meta_background(0.72 if not phone else 0.66)
	var body := _v4_header("THIÊN MỆNH LỤC", "Dấu mốc được khắc vào hồ sơ", phone)
	var achievements := _achievement_entries()
	var unlocked_count := 0
	for achievement: Dictionary in achievements:
		if bool(achievement.get("unlocked", false)):
			unlocked_count += 1
	if phone:
		_v4_add_plate(body, false, V4_BRONZE, true)
		var gap_x := 8.0
		var gap_y := 8.0
		var cell_width := (body.size.x - 34.0 - gap_x * 2.0) / 3.0
		var cell_height := (body.size.y - 26.0 - gap_y) / 2.0
		for index in mini(6, achievements.size()):
			var achievement: Dictionary = achievements[index]
			var col := index % 3
			var row := index / 3
			var unlocked := bool(achievement.get("unlocked", false))
			var x := body.position.x + 16.0 + col * (cell_width + gap_x)
			var y := body.position.y + 12.0 + row * (cell_height + gap_y)
			_v4_add_art(str(ACHIEVEMENT_SEALS.get(str(achievement.get("id", "nhap_dao")), ICON_SWORD_PATH)), Rect2(x + 10.0, y + 18.0, 66.0, 66.0), Color.WHITE if unlocked else Color(0.24, 0.26, 0.25, 0.70))
			_v4_add_text("ĐÃ KHẮC" if unlocked else "CHƯA KHẮC", Rect2(x + 84.0, y + 12.0, cell_width - 94.0, 20.0), 13, V4_JADE if unlocked else V4_PAPER_MUTED, true)
			var title := _v4_add_text(str(achievement.get("name", "Thiên mệnh")), Rect2(x + 84.0, y + 36.0, cell_width - 94.0, 44.0), 15, V4_PAPER, true)
			title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var progress_data: Dictionary = achievement.get("progress", {}) as Dictionary
			_v4_add_text("HOÀN TẤT" if unlocked else "%d / %d" % [int(progress_data.get("current", 0)), int(progress_data.get("target", 1))], Rect2(x + 84.0, y + cell_height - 34.0, cell_width - 94.0, 22.0), 14, V4_GOLD, true)
		return
	var ledger := Rect2(body.position.x + 118.0, body.position.y, body.size.x - 236.0, body.size.y)
	_v4_add_plate(ledger, false, V4_BRONZE, true)
	_v4_add_text("THIÊN MỆNH ĐẠO ĐỒ", Rect2(ledger.position.x + 54.0, ledger.position.y + 34.0, ledger.size.x - 108.0, 40.0), 27, V4_PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("%d / %d DẤU ẤN ĐÃ HOÀN THÀNH" % [unlocked_count, achievements.size()], Rect2(ledger.position.x + 54.0, ledger.position.y + 82.0, ledger.size.x - 108.0, 26.0), 15, V4_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_rule(Rect2(ledger.position.x + ledger.size.x * 0.5, ledger.position.y + 132.0, 1.0, ledger.size.y - 176.0), Color(V4_BRONZE, 0.32))
	var cell_width := (ledger.size.x - 126.0) * 0.5
	var cell_height := 170.0
	for index in mini(6, achievements.size()):
		var achievement: Dictionary = achievements[index]
		var col := index % 2
		var row := index / 2
		var unlocked := bool(achievement.get("unlocked", false))
		var x := ledger.position.x + 48.0 + col * (cell_width + 30.0)
		var y := ledger.position.y + 142.0 + row * cell_height
		_v4_add_art(str(ACHIEVEMENT_SEALS.get(str(achievement.get("id", "nhap_dao")), ICON_SWORD_PATH)), Rect2(x, y + 12.0, 92.0, 92.0), Color.WHITE if unlocked else Color(0.24, 0.26, 0.25, 0.70))
		_v4_add_text("ĐÃ KHẮC ẤN" if unlocked else "CHƯA KHẮC ẤN", Rect2(x + 116.0, y + 6.0, cell_width - 126.0, 24.0), 14, V4_JADE if unlocked else V4_PAPER_MUTED, true)
		_v4_add_text(str(achievement.get("name", "Thiên mệnh")), Rect2(x + 116.0, y + 38.0, cell_width - 126.0, 50.0), 19, V4_PAPER, true)
		var progress_data: Dictionary = achievement.get("progress", {}) as Dictionary
		_v4_add_text("HOÀN TẤT" if unlocked else "%d / %d" % [int(progress_data.get("current", 0)), int(progress_data.get("target", 1))], Rect2(x + 116.0, y + 98.0, cell_width - 126.0, 24.0), 15, V4_GOLD, true)
		_v4_add_rule(Rect2(x, y + 142.0, cell_width, 1.0), Color(V4_BRONZE, 0.24))


func _v4_build_settings(phone: bool) -> void:
	_v4_meta_background(0.66 if not phone else 0.60)
	var body := _v4_header("THIẾT LẬP", "Âm thanh · trợ năng · hồ sơ", phone)
	var settings := _settings()
	if phone:
		_v4_add_plate(body, true, V4_BRONZE, true)
		var audio_width := 424.0
		var rows := [
			{ "id": &"master", "name": "ÂM LƯỢNG TỔNG" },
			{ "id": &"music", "name": "NHẠC NỀN" },
			{ "id": &"sfx", "name": "HIỆU ỨNG" },
		]
		for index in rows.size():
			var row: Dictionary = rows[index]
			var setting_id := StringName(str(row.get("id", "master")))
			# The authored folio has a top clamp that occupies the first 30 px. Keep
			# the 64 px touch controls below that hardware and leave a clean gap above
			# the footer command rail.
			var y := body.position.y + 30.0 + index * 62.0
			_v4_add_text(str(row.get("name", "Âm lượng")), Rect2(body.position.x + 38.0, y + 18.0, 132.0, 28.0), 14, PAPER_INK, true)
			var minus := _button("−", RasterButton.ArtVariant.INK, Vector2(64.0, 64.0), 24, func() -> void: _nudge_volume(setting_id, -0.10))
			minus.position = Vector2(body.position.x + 176.0, y)
			minus.size = Vector2(64.0, 64.0)
			screen_root.add_child(minus)
			_v4_add_text("%d%%" % int(round(float(settings.get(setting_id, 0.8)) * 100.0)), Rect2(body.position.x + 244.0, y, 72.0, 64.0), 16, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var plus := _button("+", RasterButton.ArtVariant.JADE, Vector2(64.0, 64.0), 24, func() -> void: _nudge_volume(setting_id, 0.10))
			plus.position = Vector2(body.position.x + 318.0, y)
			plus.size = Vector2(64.0, 64.0)
			screen_root.add_child(plus)
		_v4_add_rule(Rect2(body.position.x + audio_width, body.position.y + 10.0, 1.0, body.size.y - 84.0), Color(V4_BRONZE, 0.34))
		var right_x := body.position.x + audio_width + 18.0
		var right_width := body.end.x - right_x - 18.0
		var toggle_rows := [
			{ "id": &"reduced_motion", "name": "GIẢM CHUYỂN ĐỘNG", "enabled": bool(settings.get("reduced_motion", false)) },
			{ "id": &"screen_shake", "name": "RUNG MÀN HÌNH", "enabled": bool(settings.get("screen_shake", true)) },
		]
		for index in toggle_rows.size():
			var row: Dictionary = toggle_rows[index]
			var setting_id := StringName(str(row.get("id", "reduced_motion")))
			var enabled := bool(row.get("enabled", false))
			var y := body.position.y + 30.0 + index * 62.0
			_v4_add_text(str(row.get("name", "Tùy chọn")), Rect2(right_x, y + 18.0, 138.0, 26.0), 13, PAPER_INK, true)
			var toggle := _button("ĐANG BẬT" if enabled else "ĐANG TẮT", RasterButton.ArtVariant.JADE if enabled else RasterButton.ArtVariant.INK, Vector2(right_width - 142.0, 64.0), 13, func() -> void: _toggle_setting(setting_id, not enabled))
			toggle.position = Vector2(right_x + 142.0, y)
			toggle.size = Vector2(right_width - 142.0, 64.0)
			screen_root.add_child(toggle)
		_v4_add_text("HỒ SƠ ĐẠO ĐỒ", Rect2(right_x, body.position.y + 160.0, right_width, 20.0), 13, BRONZE_INK, true)
		_v4_add_text("%d lần nhập thế · %d chiến thắng\nCông lực %d · %d Linh Ngọc" % [_profile_value("runs", 0), _profile_value("victories", 0), _account_power(), _profile_value("currency", 0)], Rect2(right_x, body.position.y + 184.0, right_width, 30.0), 12, PAPER_COPY)
		var footer_width := (body.size.x - 24.0) / 3.0
		var footer := [
			["MÀN HÌNH CHÍNH", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_TITLE)],
			["XÓA HỒ SƠ", RasterButton.ArtVariant.CRIMSON, _show_reset_confirmation],
			["VỀ SƠN MÔN", RasterButton.ArtVariant.GOLD, func() -> void: _show_screen(SCREEN_HUB)],
		]
		for index in footer.size():
			var command: Array = footer[index]
			var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(footer_width, 64.0), 13, command[2] as Callable)
			button.position = Vector2(body.position.x + index * (footer_width + 8.0), body.end.y - 64.0)
			button.size = Vector2(footer_width, 64.0)
			screen_root.add_child(button)
		return
	var page := Rect2(body.position.x + 246.0, body.position.y, body.size.x - 492.0, body.size.y)
	_v4_add_plate(page, true, V4_BRONZE, true)
	_v4_add_text("ÂM THANH", Rect2(page.position.x + 68.0, page.position.y + 42.0, 390.0, 32.0), 21, PAPER_INK, true)
	var rows := [
		{ "id": &"master", "name": "ÂM LƯỢNG TỔNG", "copy": "Điều chỉnh toàn bộ âm thanh trong game." },
		{ "id": &"music", "name": "NHẠC NỀN", "copy": "Âm nhạc nền của sơn môn và thí luyện." },
		{ "id": &"sfx", "name": "HIỆU ỨNG", "copy": "Kiếm, linh khí, đột phá và giao diện." },
	]
	for index in rows.size():
		var row: Dictionary = rows[index]
		var setting_id := StringName(str(row.get("id", "master")))
		var y := page.position.y + 92.0 + index * 100.0
		_v4_add_text(str(row.get("name", "Âm lượng")), Rect2(page.position.x + 70.0, y, 300.0, 28.0), 17, PAPER_INK, true)
		_v4_add_text(str(row.get("copy", "")), Rect2(page.position.x + 70.0, y + 32.0, 430.0, 24.0), 14, PAPER_COPY)
		var minus := _button("−", RasterButton.ArtVariant.INK, Vector2(64.0, 64.0), 24, func() -> void: _nudge_volume(setting_id, -0.10))
		minus.position = Vector2(page.end.x - 344.0, y)
		minus.size = Vector2(64.0, 64.0)
		screen_root.add_child(minus)
		_v4_add_text("%d%%" % int(round(float(settings.get(setting_id, 0.8)) * 100.0)), Rect2(page.end.x - 272.0, y, 92.0, 64.0), 18, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var plus := _button("+", RasterButton.ArtVariant.JADE, Vector2(64.0, 64.0), 24, func() -> void: _nudge_volume(setting_id, 0.10))
		plus.position = Vector2(page.end.x - 174.0, y)
		plus.size = Vector2(64.0, 64.0)
		screen_root.add_child(plus)
	_v4_add_rule(Rect2(page.position.x + 64.0, page.position.y + 402.0, page.size.x - 128.0, 1.0), Color(V4_BRONZE, 0.40))
	_v4_add_text("TRỢ NĂNG", Rect2(page.position.x + 68.0, page.position.y + 428.0, 390.0, 32.0), 21, PAPER_INK, true)
	var toggles := [
		{ "id": &"reduced_motion", "name": "GIẢM CHUYỂN ĐỘNG", "enabled": bool(settings.get("reduced_motion", false)) },
		{ "id": &"screen_shake", "name": "RUNG MÀN HÌNH", "enabled": bool(settings.get("screen_shake", true)) },
	]
	for index in toggles.size():
		var row: Dictionary = toggles[index]
		var setting_id := StringName(str(row.get("id", "reduced_motion")))
		var enabled := bool(row.get("enabled", false))
		var y := page.position.y + 476.0 + index * 86.0
		_v4_add_text(str(row.get("name", "Tùy chọn")), Rect2(page.position.x + 70.0, y + 16.0, 360.0, 28.0), 17, PAPER_INK, true)
		var toggle := _button("ĐANG BẬT" if enabled else "ĐANG TẮT", RasterButton.ArtVariant.JADE if enabled else RasterButton.ArtVariant.INK, Vector2(240.0, 64.0), 15, func() -> void: _toggle_setting(setting_id, not enabled))
		toggle.position = Vector2(page.end.x - 310.0, y)
		toggle.size = Vector2(240.0, 64.0)
		screen_root.add_child(toggle)
	var footer := [
		["MÀN HÌNH CHÍNH", RasterButton.ArtVariant.INK, func() -> void: _show_screen(SCREEN_TITLE)],
		["XÓA HỒ SƠ", RasterButton.ArtVariant.CRIMSON, _show_reset_confirmation],
		["VỀ SƠN MÔN", RasterButton.ArtVariant.GOLD, func() -> void: _show_screen(SCREEN_HUB)],
	]
	for index in footer.size():
		var command: Array = footer[index]
		var button := _button(str(command[0]), command[1] as RasterButton.ArtVariant, Vector2(250.0, 64.0), 15, command[2] as Callable)
		button.position = Vector2(page.position.x + 90.0 + index * 292.0, page.end.y - 76.0)
		button.size = Vector2(250.0, 64.0)
		screen_root.add_child(button)


func _v4_build_results(phone: bool) -> void:
	_v4_meta_background(0.58 if not phone else 0.52)
	var result_color := V4_GOLD if last_victory else V4_CINNABAR
	var panel_rect := _phone_safe_rect() if phone else Rect2(388.0, 90.0, 824.0, 720.0)
	_v4_add_plate(panel_rect, false, result_color, true)
	var top := panel_rect.position.y + (22.0 if phone else 54.0)
	_v4_add_text("THÍ LUYỆN KẾT THÚC", Rect2(panel_rect.position.x + 44.0, top, panel_rect.size.x - 88.0, 24.0), 14 if phone else 16, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text(last_result_title, Rect2(panel_rect.position.x + 38.0, top + 30.0, panel_rect.size.x - 76.0, 48.0), 28 if phone else 38, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	var stage := _stage_data(_selected_stage())
	_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(panel_rect.position.x + 44.0, top + 78.0, panel_rect.size.x - 88.0, 26.0), 15 if phone else 17, V4_JADE if last_victory else V4_PAPER_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	if not phone:
		_v4_add_art(str(DISCIPLINE_ICONS.get(String(_selected_discipline()), ICON_SWORD_PATH)), Rect2(panel_rect.position.x + 294.0, top + 118.0, 236.0, 236.0), Color(0.80, 0.94, 0.88, 0.92))
	var stat_y := panel_rect.position.y + (126.0 if phone else 454.0)
	var stat_width := (panel_rect.size.x - (52.0 if phone else 112.0)) / 3.0
	var stat_labels := ["THỜI GIAN", "TRẢM YÊU", "LINH NGỌC"]
	var stat_values := [_format_time(run_elapsed), str(run_kills), "+%d" % int(last_result.get("total", 0))]
	for index in 3:
		var x := panel_rect.position.x + (20.0 if phone else 44.0) + index * (stat_width + (6.0 if phone else 12.0))
		_v4_add_plate(Rect2(x, stat_y, stat_width, 78.0 if phone else 94.0), false, result_color, false)
		_v4_add_text(stat_labels[index], Rect2(x + 8.0, stat_y + 12.0, stat_width - 16.0, 20.0), 13 if phone else 14, V4_PAPER_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(stat_values[index], Rect2(x + 8.0, stat_y + 36.0, stat_width - 16.0, 36.0), 21 if phone else 27, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	var reward_text := "CĂN CƠ ĐÃ ĐƯỢC GHI VÀO HỒ SƠ"
	if bool(last_result.get("first_clear", false)):
		reward_text = "PHÁ CẢNH LẦN ĐẦU · CẢNH GIỚI MỚI ĐÃ KHAI MỞ"
	_v4_add_text(reward_text, Rect2(panel_rect.position.x + 50.0, stat_y + (92.0 if phone else 106.0), panel_rect.size.x - 100.0, 26.0), 14 if phone else 16, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	if not phone:
		var detail_copy := _v4_add_text(last_result_details, Rect2(panel_rect.position.x + 98.0, stat_y + 136.0, panel_rect.size.x - 196.0, 44.0), 15, V4_PAPER_MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
		detail_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var button_y := panel_rect.end.y - (64.0 if phone else 76.0)
	var hub_width := 320.0 if phone else 310.0
	var retry_width := 250.0 if phone else 260.0
	var hub := _button("TRỞ VỀ SƠN MÔN", RasterButton.ArtVariant.GOLD if last_victory else RasterButton.ArtVariant.INK, Vector2(hub_width, 64.0), 15 if phone else 17, _return_to_hub)
	hub.position = Vector2(panel_rect.position.x + (52.0 if phone else 104.0), button_y)
	hub.size = Vector2(hub_width, 64.0)
	screen_root.add_child(hub)
	var retry := _button("THỬ LẠI", RasterButton.ArtVariant.JADE if last_victory else RasterButton.ArtVariant.CRIMSON, Vector2(retry_width, 64.0), 15 if phone else 17, _retry_run)
	retry.position = Vector2(panel_rect.end.x - retry_width - (52.0 if phone else 104.0), button_y)
	retry.size = Vector2(retry_width, 64.0)
	screen_root.add_child(retry)


# -----------------------------------------------------------------------------
# V5 authored component integration inside the locked V4.1 direction
# -----------------------------------------------------------------------------

func _v5_fit_art(path: String, bounds: Rect2) -> Rect2:
	var texture := _load_texture(path)
	if texture == null:
		return bounds
	var source := Vector2(texture.get_size())
	if source.x <= 1.0 or source.y <= 1.0:
		return bounds
	var scale := minf(bounds.size.x / source.x, bounds.size.y / source.y)
	var fitted := source * scale
	return Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted)


func _v5_add_fitted_art(path: String, bounds: Rect2, tint := Color.WHITE) -> Rect2:
	var fitted := _v5_fit_art(path, bounds)
	_v4_add_art(path, fitted, tint)
	return fitted


func _v5_art_slot_button(caption: String, rect: Rect2, font_size: int, font_color: Color, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "V5ArtSlot_%s" % caption.replace(" ", "_")
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = Vector2(maxf(64.0, rect.size.x), maxf(64.0, rect.size.y))
	button.text = caption
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override(&"font", ACTION_FONT)
	button.add_theme_font_size_override(&"font_size", font_size)
	button.add_theme_color_override(&"font_color", font_color)
	button.add_theme_color_override(&"font_hover_color", font_color.lightened(0.16))
	button.add_theme_color_override(&"font_pressed_color", font_color.darkened(0.12))
	button.add_theme_color_override(&"font_focus_color", font_color.lightened(0.12))
	button.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.56))
	button.add_theme_constant_override(&"outline_size", 1)
	for state_name in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(V4_JADE, 0.08)
	focus_style.border_color = Color(V4_JADE, 0.90)
	focus_style.set_border_width_all(2)
	focus_style.corner_radius_top_left = 5
	focus_style.corner_radius_top_right = 5
	focus_style.corner_radius_bottom_left = 5
	focus_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override(&"focus", focus_style)
	button.pressed.connect(callback)
	button.tooltip_text = caption.capitalize()
	focus_queue.append(button)
	screen_root.add_child(button)
	return button


func _v5_result_art_button(caption: String, rect: Rect2, font_size: int, callback: Callable) -> Button:
	var button := _v5_art_slot_button(caption, rect, font_size, V4_PAPER, callback)
	# Result art already contains its own shaped plaque. A full rectangular focus
	# border reads as a misaligned extra button, so focus is expressed by a live
	# diamond marker inside the authored caption field.
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.focus_entered.connect(func() -> void: button.text = "◆  %s" % caption)
	button.focus_exited.connect(func() -> void: button.text = caption)
	return button


func _v5_build_hub(phone: bool) -> void:
	_v4_meta_background(0.26 if not phone else 0.22)
	var doctrine := _discipline_data(_selected_discipline())
	var stage := _stage_data(_selected_stage())
	var discipline_key := _discipline_technique_key(_selected_discipline())
	var ranks: Dictionary = _profile_snapshot().get("technique_ranks", {}) as Dictionary
	var rank := int(ranks.get(String(discipline_key), 0))
	var commands := [
		["HÀNH TRÌNH", func() -> void: _show_screen(SCREEN_STAGES)],
		["CÔNG PHÁP", func() -> void: _show_screen(SCREEN_TECHNIQUES)],
		["PHÁP BẢO", func() -> void: _show_screen(SCREEN_INVENTORY)],
		["LINH THÚ", func() -> void: _show_screen(SCREEN_SPIRIT_BEAST)],
		["VẠN TƯỢNG", func() -> void: _show_screen(SCREEN_CODEX)],
		["THÀNH TỰU", func() -> void: _show_screen(SCREEN_ACHIEVEMENTS)],
		["THIẾT LẬP", func() -> void: _show_screen(SCREEN_SETTINGS)],
	]
	if phone:
		var safe := _phone_safe_rect()
		_v4_add_text("SƠN MÔN VÂN MỘNG", Rect2(safe.position.x, safe.position.y + 1.0, 360.0, 28.0), 21, V4_PAPER, true)
		_v4_add_text("THẮNG %d · CÔNG LỰC %d" % [_profile_value("victories", 0), _account_power()], Rect2(safe.position.x, safe.position.y + 28.0, 300.0, 19.0), 12, V4_PAPER_MUTED)
		_v4_add_text("%d LINH NGỌC" % _profile_value("currency", 0), Rect2(safe.end.x - 168.0, safe.position.y + 10.0, 168.0, 26.0), 15, V4_GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
		var top_y := safe.position.y + 54.0
		# Phone hub uses compact editorial artifacts. Their art is visually small,
		# while the separate actions below retain the full 64 px touch height.
		var dossier := _v5_fit_art(V5_HUB_DOSSIER_PATH, Rect2(safe.position.x, top_y, 120.0, 164.0))
		var dossier_art := _v4_add_art(V5_HUB_DOSSIER_PATH, dossier)
		dossier_art.name = "HubIdentityPlate"
		_v4_add_art(PLAYER_PORTRAIT_PATH, Rect2(dossier.position.x + 32.0, dossier.position.y + 23.0, 56.0, 56.0), Color(0.92, 0.94, 0.90, 0.96))
		# The small dossier sockets are ornament, not text fields. Identity is carried
		# by the portrait and the explicit Tâm Pháp action below at this scale.
		var change := _button("TÂM PHÁP", RasterButton.ArtVariant.INK, Vector2(dossier.size.x, 64.0), 12, func() -> void: _show_screen(SCREEN_LOADOUT))
		change.position = Vector2(dossier.position.x, safe.end.y - 64.0)
		change.size = Vector2(dossier.size.x, 64.0)
		screen_root.add_child(change)
		var expedition := _v5_fit_art(V5_HUB_EXPEDITION_PATH, Rect2(dossier.end.x + 10.0, top_y, 278.0, 164.0))
		var expedition_art := _v4_add_art(V5_HUB_EXPEDITION_PATH, expedition)
		expedition_art.name = "HubExpeditionPlate"
		# The authored expedition object already contains its own landscape. A second
		# stage bitmap created the conspicuous rectangle-within-a-rectangle layer.
		_v4_add_text("THÍ LUYỆN ĐANG CHỌN", Rect2(expedition.position.x + 28.0, expedition.position.y + 34.0, expedition.size.x - 56.0, 18.0), 10, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(expedition.position.x + 30.0, expedition.position.y + 55.0, expedition.size.x - 60.0, 28.0), 18, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text("HIỂM HỌA %d/3 · %d+ NGỌC" % [int(stage.get("difficulty", 1)), int((stage.get("rewards", {}) as Dictionary).get("base", 30))], Rect2(expedition.position.x + 36.0, expedition.end.y - 38.0, expedition.size.x - 72.0, 20.0), 11, V4_PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
		var depart := _button("KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(expedition.size.x, 64.0), 15, func() -> void: _show_screen(SCREEN_LOADOUT))
		depart.position = Vector2(expedition.position.x, safe.end.y - 64.0)
		depart.size = Vector2(expedition.size.x, 64.0)
		screen_root.add_child(depart)
		var rail_x := expedition.end.x + 10.0
		var rail_width := safe.end.x - rail_x
		var gap := 4.0
		var command_width := (rail_width - gap) * 0.5
		for index in commands.size():
			var command: Array = commands[index]
			var col := index % 2
			var row := index / 2
			var button := _button(str(command[0]), RasterButton.ArtVariant.JADE if index == 1 else RasterButton.ArtVariant.INK, Vector2(command_width, 64.0), 12, command[1] as Callable)
			button.position = Vector2(rail_x + col * (command_width + gap), top_y + row * 67.0)
			button.size = Vector2(command_width, 64.0)
			screen_root.add_child(button)
		return

	_v4_add_text("SƠN MÔN", Rect2(64.0, 28.0, 360.0, 48.0), 36, V4_PAPER, true)
	_v4_add_text("VÂN MỘNG ĐẠO TÔNG · NGOẠI VIỆN", Rect2(66.0, 74.0, 460.0, 24.0), 14, V4_PAPER_MUTED, true)
	_v4_add_text("%d LINH NGỌC" % _profile_value("currency", 0), Rect2(1262.0, 44.0, 274.0, 32.0), 20, V4_GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	_v4_add_rule(Rect2(62.0, 108.0, 1476.0, 1.0), Color(V4_BRONZE, 0.62))
	var dossier := _v5_add_fitted_art(V5_HUB_DOSSIER_PATH, Rect2(54.0, 126.0, 380.0, 620.0))
	_v4_add_art(PLAYER_PORTRAIT_PATH, Rect2(dossier.position.x + 92.0, dossier.position.y + 38.0, 196.0, 196.0), Color(0.92, 0.95, 0.91, 0.98))
	_v4_add_text("KIẾM TU VÂN MỘNG", Rect2(dossier.position.x + 52.0, dossier.position.y + dossier.size.y * 0.45, dossier.size.x - 104.0, 24.0), 14, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	# Keep the decorative socket row unobstructed. Runtime data belongs in the two
	# long authored status channels near the foot of the dossier.
	_v4_add_text("TÂM PHÁP · TẦNG %d / 5" % rank, Rect2(dossier.position.x + 92.0, dossier.end.y - 110.0, dossier.size.x - 154.0, 25.0), 14, V4_PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("CÔNG LỰC %d" % _account_power(), Rect2(dossier.position.x + 92.0, dossier.end.y - 72.0, dossier.size.x - 154.0, 25.0), 14, V4_PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	var change := _button("ĐỔI TÂM PHÁP", RasterButton.ArtVariant.INK, Vector2(280.0, 64.0), 16, func() -> void: _show_screen(SCREEN_LOADOUT))
	change.position = Vector2(dossier.position.x + 50.0, 748.0)
	change.size = Vector2(280.0, 64.0)
	screen_root.add_child(change)
	var expedition := _v5_add_fitted_art(V5_HUB_EXPEDITION_PATH, Rect2(448.0, 126.0, 750.0, 520.0))
	_v4_add_text("THÍ LUYỆN ĐANG CHỌN", Rect2(expedition.position.x + 112.0, expedition.position.y + 128.0, expedition.size.x - 224.0, 25.0), 14, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(expedition.position.x + 96.0, expedition.position.y + 164.0, expedition.size.x - 192.0, 48.0), 31, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_add_text("HIỂM HỌA %d / 3   ·   THƯỞNG %d+ LINH NGỌC" % [int(stage.get("difficulty", 1)), int((stage.get("rewards", {}) as Dictionary).get("base", 30))], Rect2(expedition.position.x + 128.0, expedition.end.y - 82.0, expedition.size.x - 256.0, 28.0), 15, V4_PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	var depart := _button("KHỞI HÀNH", RasterButton.ArtVariant.GOLD, Vector2(292.0, 66.0), 18, func() -> void: _show_screen(SCREEN_LOADOUT))
	depart.position = Vector2(expedition.end.x - 316.0, 658.0)
	depart.size = Vector2(292.0, 66.0)
	screen_root.add_child(depart)
	var rail := _v5_add_fitted_art(V5_HUB_COMMAND_RAIL_PATH, Rect2(1244.0, 130.0, 244.0, 650.0))
	for index in commands.size():
		var command: Array = commands[index]
		_v5_art_slot_button(str(command[0]), Rect2(rail.position.x + 24.0, rail.position.y + 44.0 + index * 78.0, rail.size.x - 48.0, 64.0), 13, V4_PAPER, command[1] as Callable)


func _v5_build_loadout(phone: bool) -> void:
	_v4_meta_background(0.58 if not phone else 0.52)
	var stage := _stage_data(_selected_stage())
	var body := _v4_header("CHỌN TÂM PHÁP", str(stage.get("name", "Vân Mộng Cốc")), phone)
	var disciplines := _disciplines()
	var selected := _selected_discipline()
	var gap := 8.0 if phone else 22.0
	var card_width := (body.size.x - gap * 2.0) / 3.0
	var card_height := body.size.y - (70.0 if phone else 96.0)
	for index in mini(3, disciplines.size()):
		var discipline: Dictionary = disciplines[index]
		var discipline_id := StringName(str(discipline.get("id", "van_kiem")))
		var is_selected := discipline_id == selected
		var slot := Rect2(body.position.x + index * (card_width + gap), body.position.y, card_width, card_height)
		var folio := _v5_add_fitted_art(str(V5_FOLIO_PRIMARY_PATHS[index]), slot, Color(1.04, 1.06, 0.98, 1.0) if is_selected else Color.WHITE)
		var title_size := 13 if phone else 25
		var discipline_title := _phone_discipline_title(discipline_id) if phone else str(discipline.get("name", "Vạn Kiếm Quy Tông"))
		_v4_add_text(discipline_title, Rect2(folio.position.x + 20.0, folio.position.y + (7.0 if phone else 18.0), folio.size.x - 40.0, 26.0 if phone else 56.0), title_size, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(str(discipline.get("role", "Công kích")).to_upper(), Rect2(folio.position.x + 22.0, folio.position.y + (31.0 if phone else 72.0), folio.size.x - 44.0, 18.0), 10 if phone else 13, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		if not phone:
			var copy_y := folio.position.y + folio.size.y * 0.70
			var copy := _v4_add_text(str(discipline.get("description", "")), Rect2(folio.position.x + 30.0, copy_y, folio.size.x - 60.0, folio.size.y * 0.17), 16, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
			copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var equip_y := folio.end.y - (48.0 if phone else 64.0)
		_v5_art_slot_button("ĐÃ TRANG BỊ" if is_selected else "TRANG BỊ", Rect2(folio.position.x + 28.0, equip_y, folio.size.x - 56.0, 64.0), 12 if phone else 15, V4_PAPER, func() -> void: _select_discipline(discipline_id))
	if phone:
		_v4_add_text("%s · HIỂM HỌA %d/3" % [str(_discipline_data(selected).get("name", "Vạn Kiếm Quy Tông")), int(stage.get("difficulty", 1))], Rect2(body.position.x, body.end.y - 54.0, body.size.x - 294.0, 46.0), 14, V4_PAPER_MUTED, true)
		var start_phone := _button("NHẬP CẢNH", RasterButton.ArtVariant.GOLD, Vector2(286.0, 64.0), 17, _start_selected_run)
		start_phone.position = Vector2(body.end.x - 286.0, body.end.y - 64.0)
		start_phone.size = Vector2(286.0, 64.0)
		screen_root.add_child(start_phone)
		return
	_v4_add_text("%s · %s · HIỂM HỌA %d/3" % [str(stage.get("name", "Vân Mộng Cốc")), str(_discipline_data(selected).get("name", "Vạn Kiếm Quy Tông")), int(stage.get("difficulty", 1))], Rect2(390.0, 780.0, 560.0, 36.0), 16, V4_PAPER, true)
	var start := _button("NHẬP CẢNH", RasterButton.ArtVariant.GOLD, Vector2(292.0, 64.0), 18, _start_selected_run)
	start.position = Vector2(970.0, 764.0)
	start.size = Vector2(292.0, 64.0)
	screen_root.add_child(start)


func _v5_build_techniques(phone: bool) -> void:
	_v4_meta_background(0.62 if not phone else 0.56)
	var body := _v4_header("CÔNG PHÁP CÁC", "Mỗi tầng đổi silhouette và hiệu ứng chiến đấu", phone)
	var techniques := _techniques()
	var gap := 8.0 if phone else 22.0
	var card_width := (body.size.x - gap * 2.0) / 3.0
	for index in mini(3, techniques.size()):
		var technique: Dictionary = techniques[index]
		var technique_id := StringName(str(technique.get("id", "sword_damage")))
		var rank := int(technique.get("rank", 0))
		var max_rank := int(technique.get("max_rank", 5))
		var cost := int(technique.get("next_cost", -1))
		var slot := Rect2(body.position.x + index * (card_width + gap), body.position.y, card_width, body.size.y)
		var folio := _v5_add_fitted_art(str(V5_FOLIO_SECONDARY_PATHS[index]), slot)
		var technique_title := _phone_technique_title(technique_id) if phone else str(technique.get("name", "Kiếm Tâm"))
		_v4_add_text(technique_title, Rect2(folio.position.x + 22.0, folio.position.y + (7.0 if phone else 18.0), folio.size.x - 44.0, 27.0 if phone else 54.0), 12 if phone else 26, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(_technique_school(technique_id), Rect2(folio.position.x + 22.0, folio.position.y + (40.0 if phone else 70.0), folio.size.x - 44.0, 20.0), 11 if phone else 13, _technique_accent(technique_id).darkened(0.34), true, HORIZONTAL_ALIGNMENT_CENTER)
		var info_y := folio.position.y + folio.size.y * (0.69 if phone else 0.70)
		_v4_add_text("TẦNG %d / %d" % [rank, max_rank], Rect2(folio.position.x + 28.0, info_y, folio.size.x - 56.0, 24.0), 12 if phone else 15, BRONZE_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		if not phone:
			var evolution := _v4_add_text(_technique_evolution_copy(technique_id, rank, max_rank), Rect2(folio.position.x + 30.0, info_y + 26.0, folio.size.x - 60.0, folio.size.y * 0.12), 15, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
			evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var price := "ĐÃ VIÊN MÃN" if rank >= max_rank else ("NÂNG · %d" % cost if phone else "NÂNG TẦNG · %d LINH NGỌC" % cost)
		var purchase_y := folio.end.y - (48.0 if phone else 64.0)
		var purchase := _v5_art_slot_button(price, Rect2(folio.position.x + 28.0, purchase_y, folio.size.x - 56.0, 64.0), 11 if phone else 14, V4_PAPER, func() -> void: _purchase_technique(technique_id))
		purchase.disabled = rank >= max_rank


func _v5_build_achievements(phone: bool) -> void:
	_v4_meta_background(0.50 if not phone else 0.44)
	var body := _v4_header("THIÊN MỆNH LỤC", "Dấu mốc được khắc vào hồ sơ", phone)
	var achievements := _achievement_entries()
	var ledger := _v5_add_fitted_art(V5_ACHIEVEMENT_LEDGER_PATH, body.grow(-6.0 if phone else -28.0))
	var icon_size := 40.0 if phone else 66.0
	for index in mini(6, achievements.size()):
		var achievement: Dictionary = achievements[index]
		var col := index % 2
		var row := index / 2
		var unlocked := bool(achievement.get("unlocked", false))
		var center_x := ledger.position.x + ledger.size.x * (0.18 if col == 0 else 0.60)
		var center_y := ledger.position.y + ledger.size.y * (0.245 + row * 0.275)
		_v4_add_art(str(ACHIEVEMENT_SEALS.get(str(achievement.get("id", "nhap_dao")), ICON_SWORD_PATH)), Rect2(center_x - icon_size * 0.5, center_y - icon_size * 0.5, icon_size, icon_size), Color.WHITE if unlocked else Color(0.26, 0.27, 0.24, 0.66))
		var text_x := center_x + icon_size * 0.70
		var text_width := ledger.size.x * 0.27
		_v4_add_text(str(achievement.get("name", "Thiên mệnh")), Rect2(text_x, center_y - (24.0 if phone else 34.0), text_width, 30.0 if phone else 42.0), 12 if phone else 17, PAPER_INK, true)
		var progress_data: Dictionary = achievement.get("progress", {}) as Dictionary
		var progress := "HOÀN TẤT" if unlocked else "%d / %d" % [int(progress_data.get("current", 0)), int(progress_data.get("target", 1))]
		_v4_add_text(progress, Rect2(text_x, center_y + (8.0 if phone else 14.0), text_width, 22.0), 11 if phone else 14, Color("#6f5a31"), true)


func _v5_build_results(phone: bool) -> void:
	var stage_path := str(STAGE_ART.get(String(_selected_stage()), STAGE_ART["van_mong"]))
	_set_background(stage_path, Color(V4_INK, 0.56 if not phone else 0.50))
	var shrine_path := V5_VICTORY_SHRINE_PATH if last_victory else V5_DEFEAT_SHRINE_PATH
	var bounds := _phone_safe_rect() if phone else Rect2(274.0, 94.0, 1052.0, 712.0)
	var shrine := _v5_add_fitted_art(shrine_path, bounds)
	var result_color := V4_GOLD if last_victory else V4_CINNABAR
	# Victory art keeps its ascent illustration completely clean; its lower paper
	# field carries the live result copy. Defeat copy sits below the broken crest,
	# inside the broad central field instead of crossing the top silhouette.
	var title_y := shrine.position.y + shrine.size.y * (0.60 if last_victory and phone else 0.54 if last_victory else 0.25)
	if not (phone and last_victory):
		_v4_add_text("THÍ LUYỆN KẾT THÚC", Rect2(shrine.position.x + 56.0, title_y - (14.0 if phone and last_victory else 0.0), shrine.size.x - 112.0, 18.0), 9 if phone else 13, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	var main_title_y := title_y if phone and last_victory else title_y + 20.0
	_v4_add_text(last_result_title, Rect2(shrine.position.x + 44.0, main_title_y, shrine.size.x - 88.0, 34.0), 20 if phone else 32, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	var stage := _stage_data(_selected_stage())
	if not (phone and last_victory):
		_v4_add_text(str(stage.get("name", "Vân Mộng Cốc")), Rect2(shrine.position.x + 60.0, main_title_y + 42.0, shrine.size.x - 120.0, 22.0), 12 if phone else 15, PAPER_INK if last_victory else V4_PAPER_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	var button_y := shrine.end.y - 68.0
	var stat_y := title_y + (40.0 if phone else 96.0) if last_victory else shrine.position.y + shrine.size.y * (0.56 if phone else 0.58)
	if phone:
		stat_y = minf(stat_y, button_y - 60.0)
	var stat_left := shrine.position.x + shrine.size.x * 0.13
	var stat_total := shrine.size.x * 0.74
	var stat_width := stat_total / 3.0
	var stat_labels := ["THỜI GIAN", "TRẢM YÊU", "LINH NGỌC"]
	var stat_values := [_format_time(run_elapsed), str(run_kills), "+%d" % int(last_result.get("total", 0))]
	for index in 3:
		var x := stat_left + index * stat_width
		_v4_add_text(stat_labels[index], Rect2(x, stat_y, stat_width, 20.0), 11 if phone else 13, PAPER_COPY if last_victory else V4_PAPER_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
		_v4_add_text(stat_values[index], Rect2(x, stat_y + 22.0, stat_width, 32.0), 19 if phone else 25, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	var reward := "PHÁ CẢNH LẦN ĐẦU · CẢNH GIỚI MỚI ĐÃ KHAI MỞ" if bool(last_result.get("first_clear", false)) else "CĂN CƠ ĐÃ ĐƯỢC GHI VÀO HỒ SƠ"
	if not phone:
		_v4_add_text(reward, Rect2(shrine.position.x + 68.0, stat_y + 62.0, shrine.size.x - 136.0, 24.0), 14, result_color, true, HORIZONTAL_ALIGNMENT_CENTER)
	var hub_width := 224.0 if phone else 300.0
	var retry_width := 170.0 if phone else 250.0
	_v5_result_art_button("TRỞ VỀ SƠN MÔN", Rect2(shrine.position.x + shrine.size.x * 0.16, button_y, hub_width, 64.0), 13 if phone else 16, _return_to_hub)
	_v5_result_art_button("THỬ LẠI", Rect2(shrine.end.x - shrine.size.x * 0.16 - retry_width, button_y, retry_width, 64.0), 13 if phone else 16, _retry_run)


func _v4_modal_canvas(overlay_name: String) -> Array:
	var overlay := Control.new()
	overlay.name = overlay_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP if overlay_name == "ResetConfirmation" else Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.01, 0.012, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var canvas := Control.new()
	canvas.name = "DialogCanvas"
	canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	canvas.size = _physical_window_size() if phone_layout_active else DESIGN_SIZE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(canvas)
	root.add_child(overlay)
	_apply_design_canvas_transform(canvas, root.size)
	if toast_panel != null:
		root.move_child(overlay, toast_panel.get_index())
	return [overlay, canvas]


func _show_rank_ascension(technique_id: StringName, next_rank: int) -> void:
	var modal := _v4_modal_canvas("RankAscension")
	var overlay := modal[0] as Control
	var canvas := modal[1] as Control
	var phone := phone_layout_active
	var rect := Rect2(90.0, 34.0, 664.0, 322.0) if phone else Rect2(430.0, 176.0, 740.0, 548.0)
	var plate := _v4_plate(rect, true, _technique_accent(technique_id), true)
	canvas.add_child(plate)
	var preview_width := 248.0 if phone else 340.0
	var preview := TechniquePreviewScript.new() as TechniquePreview
	preview.position = Vector2(rect.position.x + 24.0, rect.position.y + 22.0)
	preview.size = Vector2(preview_width, rect.size.y - 44.0)
	preview.configure(technique_id, next_rank, 5, _load_texture(str(TECHNIQUE_ICONS.get(String(technique_id), ICON_SWORD_PATH))))
	canvas.add_child(preview)
	var text_x := rect.position.x + preview_width + (42.0 if phone else 58.0)
	var text_width := rect.end.x - text_x - 34.0
	_v4_text_to(canvas, "CĂN CƠ TIẾN HÓA", Rect2(text_x, rect.position.y + (42.0 if phone else 74.0), text_width, 26.0), 14 if phone else 16, _technique_accent(technique_id).darkened(0.40), true, HORIZONTAL_ALIGNMENT_CENTER)
	var name := str(_technique_data(technique_id).get("name", "Công pháp"))
	_v4_text_to(canvas, "%s\nTẦNG %d" % [name.to_upper(), next_rank], Rect2(text_x, rect.position.y + (86.0 if phone else 132.0), text_width, 82.0), 25 if phone else 32, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var change := _v4_text_to(canvas, _technique_evolution_copy(technique_id, next_rank, 5), Rect2(text_x + 12.0, rect.position.y + (190.0 if phone else 260.0), text_width - 24.0, 90.0), 16 if phone else 18, PAPER_COPY, true, HORIZONTAL_ALIGNMENT_CENTER)
	change.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.modulate.a = 0.0
	var reduced := bool(_settings().get("reduced_motion", false))
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.10 if reduced else 0.16)
	tween.tween_interval(0.74 if reduced else 1.08)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.16)
	tween.tween_callback(overlay.queue_free)


func _show_reset_confirmation() -> void:
	var modal := _v4_modal_canvas("ResetConfirmation")
	var overlay := modal[0] as Control
	var canvas := modal[1] as Control
	var phone := phone_layout_active
	var rect := Rect2(90.0, 36.0, 664.0, 318.0) if phone else Rect2(438.0, 242.0, 724.0, 416.0)
	var plate := _v4_plate(rect, true, V4_CINNABAR, true)
	canvas.add_child(plate)
	_v4_text_to(canvas, "CẢNH BÁO HỒ SƠ", Rect2(rect.position.x + 48.0, rect.position.y + (28.0 if phone else 54.0), rect.size.x - 96.0, 26.0), 14 if phone else 16, V4_CINNABAR, true, HORIZONTAL_ALIGNMENT_CENTER)
	_v4_text_to(canvas, "LUÂN HỒI TỪ ĐẦU?", Rect2(rect.position.x + 48.0, rect.position.y + (66.0 if phone else 100.0), rect.size.x - 96.0, 48.0), 28 if phone else 34, PAPER_INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var warning := _v4_text_to(canvas, "Toàn bộ Linh Ngọc, công pháp, thành tựu, vạn tượng phổ và tiến độ mở ải sẽ bị xóa vĩnh viễn.", Rect2(rect.position.x + 74.0, rect.position.y + (126.0 if phone else 172.0), rect.size.x - 148.0, 70.0), 16 if phone else 18, PAPER_COPY, false, HORIZONTAL_ALIGNMENT_CENTER)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var cancel_width := 250.0 if phone else 240.0
	var confirm_width := 270.0 if phone else 260.0
	var button_y := rect.end.y - (74.0 if phone else 86.0)
	var cancel := _button("GIỮ HỒ SƠ", RasterButton.ArtVariant.JADE, Vector2(cancel_width, 64.0), 15 if phone else 17, func() -> void: _close_reset_confirmation(overlay))
	cancel.position = Vector2(rect.position.x + (54.0 if phone else 78.0), button_y)
	cancel.size = Vector2(cancel_width, 64.0)
	canvas.add_child(cancel)
	var confirm := _button("XÁC NHẬN XÓA", RasterButton.ArtVariant.CRIMSON, Vector2(confirm_width, 64.0), 15 if phone else 17, func() -> void: _reset_profile(overlay))
	confirm.position = Vector2(rect.end.x - confirm_width - (54.0 if phone else 78.0), button_y)
	confirm.size = Vector2(confirm_width, 64.0)
	canvas.add_child(confirm)
	cancel.call_deferred("grab_focus")
