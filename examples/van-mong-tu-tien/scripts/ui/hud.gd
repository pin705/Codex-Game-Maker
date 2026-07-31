class_name CultivationHUD
extends CanvasLayer


class SkillMedallion:
	extends Control

	var active := true

	func configure(is_active: bool) -> void:
		active = is_active
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.44
		var center := size * 0.5
		draw_circle(center + Vector2(2.0, 3.0), radius + 2.0, Color(0.0, 0.0, 0.0, 0.34))
		draw_circle(center, radius, Color("#071416", 0.94))
		draw_arc(center, radius - 1.0, 0.0, TAU, 48, Color("#c69a48", 0.82 if active else 0.38), 1.6, true)
		draw_arc(center, radius - 6.0, 0.18, 4.4, 40, Color("#55c9a6", 0.34 if active else 0.12), 1.0, true)

const INK := Color("#0b171c")
const PAPER := Color("#e9e2c7")
const PAPER_DIM := Color("#aaa991")
const JADE := Color("#57d2a7")
const GOLD := Color("#e6bb55")
const CRIMSON := Color("#cf5f62")
const PAPER_INK := Color("#17282a")
const PAPER_COPY := Color("#46514b")
const BRONZE_INK := Color("#765326")
const KEY_ART_PATH := "res://assets/generated/key-art/KEYART-001-title-1280x720-v001.webp"
const CULTIVATION_PANEL := preload("res://scripts/ui/cultivation_panel.gd")
const CULTIVATION_CHOICE := preload("res://scripts/ui/cultivation_choice_button.gd")
const CULTIVATION_ACTION := preload("res://scripts/ui/cultivation_action_button.gd")
const CULTIVATION_METER := preload("res://scripts/ui/cultivation_meter.gd")
const RASTER_BUTTON := preload("res://scripts/ui/raster_button.gd")
const COMPONENT_KIT := preload("res://scripts/ui/van_mong_component_kit.gd")
const SKILL_ICON_ROOT := "res://assets/generated/ui/SKILLICON-001-five-formation/runtime/"
const PLAYER_PORTRAIT_PATH := "res://assets/generated/portraits/PORTRAIT-002-hero-boss/runtime/player.png"
const HUD_PLAYER_FRAME: Texture2D = preload("res://assets/generated/ui/UIKIT-016-v5-combat-hud/runtime/player-status-island.png")
const HUD_TIMER_FRAME: Texture2D = preload("res://assets/generated/ui/UIKIT-016-v5-combat-hud/runtime/timer-plaque.png")
const HUD_SKILL_RAIL: Texture2D = preload("res://assets/generated/ui/UIKIT-016-v5-combat-hud/runtime/five-skill-rail.png")
const UPGRADE_VEIL: Texture2D = preload("res://assets/generated/ui/UIKIT-013-v5-ritual-modals/runtime/breakthrough-veil.png")
const PAUSE_SHRINE: Texture2D = preload("res://assets/generated/ui/UIKIT-013-v5-ritual-modals/runtime/pause-meditation-wide.png")
const BODY_FONT := preload("res://assets/fonts/BeVietnamPro-Regular.ttf")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")
const DISPLAY_FONT := preload("res://assets/fonts/Literata-Variable.ttf")

var root_control: Control
var health_bar: ProgressBar
var health_label: Label
var health_name_label: Label
var xp_bar: ProgressBar
var xp_name_label: Label
var level_label: Label
var realm_label: Label
var timer_label: Label
var kills_label: Label
var clock_caption_label: Label
var pulse_bar: ProgressBar
var pulse_label: Label
var objective_label: Label
var top_hud: Control
var life_plaque: Control
var time_plaque: Control
var objective_strip: Control
var pulse_plaque: Control
var skill_strip: Control
var life_content: Control
var player_portrait_frame: TextureRect
var player_portrait: TextureRect
var time_content: Control
var skill_rail_chrome: Control
var skill_slots: Array[Control] = []
var skill_frames: Array[Control] = []
var skill_icons: Array[TextureRect] = []
var skill_key_labels: Array[Label] = []
var skill_name_labels: Array[Label] = []
var skill_lock_labels: Array[Label] = []
var _touch_layout_enabled := false
var _mobile_safe_area := Rect2()

var start_overlay: Control
var upgrade_overlay: Control
var upgrade_cards: HBoxContainer
var upgrade_column: VBoxContainer
var upgrade_halo: Control
var upgrade_eyebrow: Label
var upgrade_title: Label
var upgrade_hint: Label
var pause_overlay: Control
var pause_card: Control
var pause_text: Label
var end_overlay: Control
var end_title: Label
var end_details: Label
var banner_panel: PanelContainer
var banner_title: Label
var banner_subtitle: Label
var banner_remaining := 0.0
var banner_duration := 1.0
var visible_upgrade_ids: Array[StringName] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	_connect_events()
	# The full front end owns title, hub and loadout. Preserve the legacy title
	# card only for isolated HUD scenes that do not load MetaProfile.
	if get_node_or_null("../FrontEnd") != null:
		start_overlay.hide()

func _process(delta: float) -> void:
	if banner_remaining > 0.0:
		banner_remaining = maxf(0.0, banner_remaining - delta)
		var progress := 1.0 - banner_remaining / maxf(banner_duration, 0.01)
		var alpha := 1.0
		if progress < 0.15:
			alpha = progress / 0.15
		elif progress > 0.78:
			alpha = (1.0 - progress) / 0.22
		banner_panel.modulate.a = clampf(alpha, 0.0, 1.0)
		if banner_remaining <= 0.0:
			banner_panel.hide()

func _input(event: InputEvent) -> void:
	# Focused upgrade Buttons otherwise treat Space as a click. Consume it while
	# a modal is open so the active skill never fires or selects a card by echo.
	if start_overlay == null:
		return
	if not start_overlay.visible and (upgrade_overlay.visible or pause_overlay.visible or end_overlay.visible) and event.is_action_pressed(&"qi_pulse"):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"confirm") and start_overlay.visible:
		Events.start_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if not upgrade_overlay.visible:
		return
	if event.is_action_pressed(&"upgrade_1"):
		_select_upgrade_index(0)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"upgrade_2"):
		_select_upgrade_index(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"upgrade_3"):
		_select_upgrade_index(2)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"confirm"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and focused.get_parent() == upgrade_cards:
			(focused as Button).pressed.emit()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var choice_index := -1
		if key_event.keycode == KEY_1 or key_event.physical_keycode == KEY_1:
			choice_index = 0
		elif key_event.keycode == KEY_2 or key_event.physical_keycode == KEY_2:
			choice_index = 1
		elif key_event.keycode == KEY_3 or key_event.physical_keycode == KEY_3:
			choice_index = 2
		if choice_index >= 0 and choice_index < upgrade_cards.get_child_count():
			(upgrade_cards.get_child(choice_index) as Button).pressed.emit()
			get_viewport().set_input_as_handled()

func _connect_events() -> void:
	Events.player_health_changed.connect(_on_health_changed)
	Events.experience_changed.connect(_on_experience_changed)
	Events.realm_changed.connect(_on_realm_changed)
	Events.run_stats_changed.connect(_on_run_stats_changed)
	Events.pulse_state_changed.connect(_on_pulse_state_changed)
	Events.upgrade_options_presented.connect(_on_upgrade_options_presented)
	Events.banner_requested.connect(_on_banner_requested)
	Events.game_started.connect(_on_game_started)
	Events.game_paused.connect(_on_game_paused)
	Events.game_finished.connect(_on_game_finished)

func _build_interface() -> void:
	root_control = Control.new()
	root_control.name = "HUDRoot"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.resized.connect(_apply_safe_layout)
	_build_top_hud()
	_build_objective_strip()
	_build_skill_strip()
	_build_start_overlay()
	_build_upgrade_overlay()
	_build_pause_overlay()
	_build_end_overlay()
	_build_banner()
	_apply_safe_layout()
	top_hud.hide()
	objective_strip.hide()

func _build_top_hud() -> void:
	# V4 keeps the arena as the hero. Identity, time and cooldown are compact edge
	# islands with unequal weight; no island spans enough width to read as a web
	# dashboard header.
	top_hud = Control.new()
	top_hud.name = "TopHUD"
	top_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(top_hud)

	var life_panel: CultivationPanel = CULTIVATION_PANEL.new()
	life_plaque = life_panel
	life_plaque.name = "LifePlaque"
	life_panel.configure(CultivationPanel.FrameKind.HUD, Color("#081719", 0.91), Color(JADE, 0.48), 2)
	life_panel.use_authored_fixed(HUD_PLAYER_FRAME)
	life_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
	life_plaque.offset_left = 32.0
	life_plaque.offset_top = 24.0
	life_plaque.offset_right = 422.0
	life_plaque.offset_bottom = 206.0
	top_hud.add_child(life_plaque)

	# The generated plaque already owns the jade/bronze portrait socket. Runtime
	# portrait, labels and meters remain separate so localization and values stay
	# live while the authored material is never stretched out of proportion.
	# UIKIT-016 owns the compact portrait/status illustration as one optical
	# island. A second portrait layer would duplicate the face and cheapen the
	# composition, so identity remains inside the authored fixed asset here.
	player_portrait_frame = null
	player_portrait = null

	# The authored plaque has two deliberately narrow lacquer troughs. Keep every
	# live field in explicit protected rectangles instead of asking a VBox to
	# redistribute them across the crest, portrait ring and ornamental end caps.
	life_content = Control.new()
	life_content.name = "LifePlaqueLiveContent"
	life_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	life_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_panel.material_root.add_child(life_content)
	realm_label = _label("PHÀM NHÂN", 17, PAPER, true)
	realm_label.clip_text = true
	life_content.add_child(realm_label)
	level_label = _label("TU VI 01", 12, Color(GOLD, 0.82), true)
	level_label.clip_text = true
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	life_content.add_child(level_label)

	health_name_label = _label("MỆNH", 11, Color(CRIMSON, 0.92), true)
	health_name_label.clip_text = true
	life_content.add_child(health_name_label)
	health_bar = _progress_bar(CRIMSON, 120.0)
	life_content.add_child(health_bar)
	health_label = _label("120/120", 11, PAPER)
	health_label.clip_text = true
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	life_content.add_child(health_label)

	xp_name_label = _label("KHÍ", 11, Color(JADE, 0.92), true)
	xp_name_label.clip_text = true
	life_content.add_child(xp_name_label)
	xp_bar = _progress_bar(JADE, 18.0)
	life_content.add_child(xp_bar)
	_layout_life_plaque_content(false)

	var time_panel: CultivationPanel = CULTIVATION_PANEL.new()
	time_plaque = time_panel
	time_plaque.name = "TimePlaque"
	time_panel.configure(CultivationPanel.FrameKind.HUD, Color("#081719", 0.89), Color(GOLD, 0.48), 5)
	time_panel.use_authored_fixed(HUD_TIMER_FRAME)
	time_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	time_plaque.offset_left = -272.0
	time_plaque.offset_top = 24.0
	time_plaque.offset_right = -32.0
	time_plaque.offset_bottom = 99.0
	top_hud.add_child(time_plaque)
	time_content = Control.new()
	time_content.name = "TimePlaqueLiveContent"
	time_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	time_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_panel.material_root.add_child(time_content)
	clock_caption_label = _label("THIÊN KIẾP", 10, Color(GOLD, 0.80), true)
	clock_caption_label.clip_text = true
	clock_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_content.add_child(clock_caption_label)
	timer_label = _label("04:00", 21, PAPER, true)
	timer_label.clip_text = true
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_content.add_child(timer_label)
	kills_label = _label("0 YÊU VẬT", 10, PAPER_DIM)
	kills_label.clip_text = true
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_content.add_child(kills_label)
	_layout_time_plaque_content(false)

	var pulse_panel: CultivationPanel = CULTIVATION_PANEL.new()
	pulse_plaque = pulse_panel
	pulse_plaque.name = "PulsePlaque"
	pulse_panel.configure(CultivationPanel.FrameKind.BANNER, Color("#081719", 0.87), Color(JADE, 0.52), 8)
	pulse_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pulse_plaque.offset_left = -212.0
	pulse_plaque.offset_top = 106.0
	pulse_plaque.offset_right = -32.0
	pulse_plaque.offset_bottom = 150.0
	top_hud.add_child(pulse_plaque)
	var pulse_margin := MarginContainer.new()
	pulse_margin.add_theme_constant_override("margin_left", 14)
	pulse_margin.add_theme_constant_override("margin_right", 14)
	pulse_margin.add_theme_constant_override("margin_top", 4)
	pulse_margin.add_theme_constant_override("margin_bottom", 5)
	pulse_plaque.add_child(pulse_margin)
	var pulse_column := VBoxContainer.new()
	pulse_column.add_theme_constant_override("separation", 0)
	pulse_margin.add_child(pulse_column)
	pulse_label = _label("[2] KIẾM TRẬN", 11, JADE, true)
	pulse_column.add_child(pulse_label)
	pulse_bar = _progress_bar(GOLD, 1.0)
	pulse_bar.custom_minimum_size = Vector2(148.0, 8.0)
	pulse_bar.value = 1.0
	pulse_column.add_child(pulse_bar)


func set_touch_layout(enabled: bool) -> void:
	_touch_layout_enabled = enabled
	if not enabled:
		_mobile_safe_area = Rect2()
	_apply_safe_layout()


func set_mobile_safe_area(safe_area: Rect2, enabled: bool) -> void:
	_touch_layout_enabled = enabled
	_mobile_safe_area = safe_area if enabled else Rect2()
	_apply_safe_layout()


func _apply_safe_layout() -> void:
	if root_control == null or root_control.size.x <= 1.0 or root_control.size.y <= 1.0:
		return
	var viewport_rect := Rect2(Vector2.ZERO, root_control.size)
	var safe := _mobile_safe_area.intersection(viewport_rect) if _touch_layout_enabled and _mobile_safe_area.has_area() else Rect2(root_control.size * 0.05, root_control.size * 0.90)
	if not safe.has_area():
		safe = viewport_rect
	if _touch_layout_enabled and _is_phone_landscape_window():
		_apply_phone_hud_layout(safe)
		return
	_restore_desktop_hud_layout()
	var right_outset := root_control.size.x - safe.end.x
	var bottom_outset := root_control.size.y - safe.end.y
	var top := safe.position.y
	if life_plaque != null:
		life_plaque.offset_left = safe.position.x
		life_plaque.offset_top = top
		life_plaque.offset_right = safe.position.x + 360.0
		life_plaque.offset_bottom = top + 124.0
		_layout_life_plaque_content(false)
	var pause_reserve := 96.0 if _touch_layout_enabled else 0.0
	if time_plaque != null:
		time_plaque.offset_right = -(right_outset + pause_reserve)
		time_plaque.offset_left = time_plaque.offset_right - 180.0
		time_plaque.offset_top = top
		time_plaque.offset_bottom = top + 84.0
		_layout_time_plaque_content(false)
	if pulse_plaque != null:
		pulse_plaque.offset_right = -(right_outset + pause_reserve)
		pulse_plaque.offset_left = pulse_plaque.offset_right - 180.0
		pulse_plaque.offset_top = top + 82.0
		pulse_plaque.offset_bottom = top + 126.0
	if objective_strip != null:
		var objective_left := safe.position.x + (200.0 if _touch_layout_enabled else 0.0)
		objective_strip.offset_left = objective_left
		objective_strip.offset_right = objective_left + 300.0
		objective_strip.offset_bottom = -(bottom_outset + 70.0)
		objective_strip.offset_top = objective_strip.offset_bottom - 34.0
	if skill_strip != null:
		skill_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		skill_strip.offset_left = -250.0
		skill_strip.offset_top = -138.0
		skill_strip.offset_right = 250.0
		skill_strip.offset_bottom = -24.0


func _is_phone_landscape_window() -> bool:
	var physical := Vector2(DisplayServer.window_get_size())
	return physical.x > physical.y and physical.x <= 960.0 and physical.y <= 540.0


func _hud_device_scale() -> float:
	var physical := Vector2(DisplayServer.window_get_size())
	if physical.x <= 1.0 or physical.y <= 1.0:
		return 1.0
	return maxf(1.0, minf(root_control.size.x / physical.x, root_control.size.y / physical.y))


func _apply_phone_hud_layout(logical_safe: Rect2) -> void:
	var physical := Vector2(DisplayServer.window_get_size())
	var device_scale := _hud_device_scale()
	var safe := Rect2(logical_safe.position / device_scale, logical_safe.size / device_scale)
	top_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_hud.position = Vector2.ZERO
	top_hud.size = physical
	top_hud.scale = Vector2.ONE * device_scale
	health_bar.custom_minimum_size = Vector2(90.0, 10.0)
	xp_bar.custom_minimum_size = Vector2(124.0, 8.0)
	pulse_bar.custom_minimum_size = Vector2(100.0, 7.0)
	if pulse_label != null and pulse_label.text.begins_with("["):
		pulse_label.text = "KIẾM TRẬN"
	if life_plaque != null:
		life_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
		life_plaque.position = Vector2(safe.position.x, safe.position.y)
		life_plaque.size = Vector2(210.0, 82.0)
		_layout_life_plaque_content(true)
	if player_portrait_frame != null:
		player_portrait_frame.show()
		player_portrait_frame.position = Vector2(4.0, 5.0)
		player_portrait_frame.size = Vector2(48.0, 48.0)
	if player_portrait != null:
		player_portrait.show()
		player_portrait.position = Vector2(15.0, 15.0)
		player_portrait.size = Vector2(43.0, 53.0)
	if time_plaque != null:
		time_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
		# Keep the fixed 368:115 timer art at source aspect and leave a clean lane
		# for the 64 px pause medallion to its right.
		time_plaque.position = Vector2(safe.end.x - 182.0, safe.position.y)
		time_plaque.size = Vector2(112.0, 52.0)
		_layout_time_plaque_content(true)
	if pulse_plaque != null:
		pulse_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
		pulse_plaque.position = Vector2(safe.get_center().x - 50.0, safe.position.y)
		pulse_plaque.size = Vector2(100.0, 34.0)
	if objective_strip != null:
		# The touch layout already explains movement and active skill state through
		# the controls/rail.  A second sentence under the rail only muddies combat.
		objective_strip.hide()
	if skill_strip != null:
		skill_strip.set_anchors_preset(Control.PRESET_TOP_LEFT)
		skill_strip.scale = Vector2.ONE * device_scale
		skill_strip.position = Vector2(safe.get_center().x - 130.0, safe.end.y - 62.0) * device_scale
		_layout_phone_skill_strip()
	_apply_upgrade_layout_for_viewport(device_scale, physical)
	_apply_pause_layout_for_viewport(device_scale, physical)


func _restore_desktop_hud_layout() -> void:
	if top_hud == null:
		return
	top_hud.scale = Vector2.ONE
	top_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_bar.custom_minimum_size = Vector2(130.0, 12.0)
	xp_bar.custom_minimum_size = Vector2(190.0, 9.0)
	pulse_bar.custom_minimum_size = Vector2(148.0, 8.0)
	if life_plaque != null:
		life_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_layout_life_plaque_content(false)
	if player_portrait_frame != null:
		player_portrait_frame.show()
		player_portrait_frame.position = Vector2(8.0, 11.0)
		player_portrait_frame.size = Vector2(78.0, 78.0)
	if player_portrait != null:
		player_portrait.show()
		player_portrait.position = Vector2(27.0, 27.0)
		player_portrait.size = Vector2(76.0, 94.0)
	if time_plaque != null:
		time_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_layout_time_plaque_content(false)
	if pulse_plaque != null:
		pulse_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	if objective_strip != null:
		objective_strip.hide()
		objective_strip.scale = Vector2.ONE
		objective_strip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	if skill_strip != null:
		skill_strip.scale = Vector2.ONE
		skill_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_layout_desktop_skill_strip()
	_apply_upgrade_layout_for_viewport(1.0, root_control.size)
	_apply_pause_layout_for_viewport(1.0, root_control.size)


func _layout_life_plaque_content(phone: bool) -> void:
	if life_content == null or life_plaque == null:
		return
	if phone:
		_set_hud_rect(realm_label, Vector2(70.0, 15.0), Vector2(78.0, 17.0), 11)
		_set_hud_rect(level_label, Vector2(150.0, 16.0), Vector2(42.0, 16.0), 8)
		_set_hud_rect(health_name_label, Vector2(70.0, 34.0), Vector2(30.0, 14.0), 9)
		_set_hud_rect(health_bar, Vector2(100.0, 37.0), Vector2(90.0, 8.0))
		_set_hud_rect(xp_name_label, Vector2(70.0, 51.0), Vector2(26.0, 14.0), 9)
		_set_hud_rect(xp_bar, Vector2(96.0, 54.0), Vector2(94.0, 7.0))
		health_label.hide()
	else:
		_set_hud_rect(realm_label, Vector2(134.0, 24.0), Vector2(116.0, 22.0), 15)
		_set_hud_rect(level_label, Vector2(252.0, 25.0), Vector2(70.0, 20.0), 11)
		_set_hud_rect(health_name_label, Vector2(134.0, 51.0), Vector2(42.0, 18.0), 12)
		_set_hud_rect(health_bar, Vector2(176.0, 54.0), Vector2(88.0, 11.0))
		_set_hud_rect(health_label, Vector2(268.0, 51.0), Vector2(58.0, 18.0), 11)
		_set_hud_rect(xp_name_label, Vector2(134.0, 79.0), Vector2(36.0, 18.0), 12)
		_set_hud_rect(xp_bar, Vector2(170.0, 82.0), Vector2(156.0, 9.0))
		health_label.show()


func _layout_time_plaque_content(phone: bool) -> void:
	if time_content == null or time_plaque == null:
		return
	if phone:
		_set_hud_rect(clock_caption_label, Vector2(42.0, 8.0), Vector2(62.0, 10.0), 7)
		_set_hud_rect(timer_label, Vector2(40.0, 18.0), Vector2(66.0, 26.0), 16)
		kills_label.hide()
	else:
		_set_hud_rect(clock_caption_label, Vector2(66.0, 14.0), Vector2(102.0, 10.0), 8)
		_set_hud_rect(timer_label, Vector2(64.0, 25.0), Vector2(106.0, 28.0), 19)
		_set_hud_rect(kills_label, Vector2(64.0, 54.0), Vector2(106.0, 11.0), 8)
		kills_label.show()


func _set_hud_rect(control: Control, position_value: Vector2, size_value: Vector2, font_size: int = 0) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.custom_minimum_size = size_value
	control.position = position_value
	control.size = size_value
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)


func _apply_upgrade_layout_for_viewport(device_scale: float, viewport_size: Vector2) -> void:
	if upgrade_column == null or upgrade_cards == null or upgrade_halo == null:
		return
	var phone_layout := _touch_layout_enabled and _is_phone_landscape_window()
	if phone_layout:
		upgrade_halo.hide()
		upgrade_column.scale = Vector2.ONE * device_scale
		upgrade_column.set_anchors_preset(Control.PRESET_TOP_LEFT)
		upgrade_column.position = Vector2(22.0, 6.0) * device_scale
		upgrade_column.size = Vector2(viewport_size.x - 44.0, viewport_size.y - 12.0)
		upgrade_column.add_theme_constant_override("separation", 2)
		upgrade_cards.custom_minimum_size = Vector2(viewport_size.x - 44.0, 226.0)
		upgrade_cards.add_theme_constant_override("separation", 8)
		if upgrade_eyebrow != null:
			upgrade_eyebrow.add_theme_font_size_override("font_size", 12)
		if upgrade_title != null:
			upgrade_title.add_theme_font_size_override("font_size", 25)
		if upgrade_hint != null:
			upgrade_hint.add_theme_font_size_override("font_size", 11)
			upgrade_hint.text = "THỜI GIAN NGƯNG ĐỌNG  ·  CHẠM MỘT PHÙ LỤC ĐỂ LĨNH NGỘ"
		for child in upgrade_cards.get_children():
			if child is Control:
				(child as Control).custom_minimum_size = Vector2(206.0, 226.0)
				(child as Control).pivot_offset = Vector2(103.0, 113.0)
			if child.has_method("set_touch_mode"):
				child.call("set_touch_mode", true)
		return
	upgrade_halo.show()
	upgrade_halo.set_anchors_preset(Control.PRESET_CENTER)
	# UIKIT-013 is a complete fixed-aspect ritual veil, not a scalable panel.
	# Keep its 726:482 silhouette intact behind the three illustrated folios.
	upgrade_halo.offset_left = -540.0
	upgrade_halo.offset_top = -359.0
	upgrade_halo.offset_right = 540.0
	upgrade_halo.offset_bottom = 359.0
	upgrade_column.scale = Vector2.ONE
	upgrade_column.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_column.offset_left = -480.0
	upgrade_column.offset_top = -270.0
	upgrade_column.offset_right = 480.0
	upgrade_column.offset_bottom = 270.0
	upgrade_column.add_theme_constant_override("separation", 10)
	upgrade_cards.custom_minimum_size = Vector2(860.0, 350.0)
	upgrade_cards.add_theme_constant_override("separation", 18)
	if upgrade_eyebrow != null:
		upgrade_eyebrow.add_theme_font_size_override("font_size", 15)
	if upgrade_title != null:
		upgrade_title.add_theme_font_size_override("font_size", 30)
	if upgrade_hint != null:
		upgrade_hint.add_theme_font_size_override("font_size", 12)
		upgrade_hint.text = "THỜI GIAN NGƯNG ĐỌNG   ·   CHỌN BẰNG CHUỘT HOẶC PHÍM 1 / 2 / 3"
	for child in upgrade_cards.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(270.0, 340.0)
			(child as Control).pivot_offset = Vector2(135.0, 170.0)
		if child.has_method("set_touch_mode"):
			child.call("set_touch_mode", false)


func _apply_pause_layout_for_viewport(device_scale: float, viewport_size: Vector2) -> void:
	if pause_card == null:
		return
	# The shrine is authored at 1324:964. Keep one logical composition and scale
	# the whole object uniformly on phones so text, artwork and action plaques do
	# not drift independently.
	var card_size := Vector2(460.0, 335.0)
	if _touch_layout_enabled and _is_phone_landscape_window():
		var visible_size := Vector2(356.0, 259.0)
		var authored_scale := minf(visible_size.x / card_size.x, visible_size.y / card_size.y)
		pause_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
		pause_card.scale = Vector2.ONE * device_scale * authored_scale
		pause_card.position = (viewport_size - card_size * authored_scale) * 0.5 * device_scale
		pause_card.size = card_size
		if pause_text != null:
			pause_text.text = "Hành trình đã tạm dừng"
		for node in pause_card.find_children("*", "Button", true, false):
			# 84 logical px becomes ~65 physical px after the authored phone scale.
			(node as Button).custom_minimum_size.y = 84.0
			if node.has_method("set_visual_inset"):
				node.call("set_visual_inset", 3.0, 5.0)
		return
	var desktop_scale := 1.24
	pause_card.scale = Vector2.ONE * desktop_scale
	pause_card.set_anchors_preset(Control.PRESET_CENTER)
	pause_card.offset_left = -card_size.x * desktop_scale * 0.5
	pause_card.offset_top = -card_size.y * desktop_scale * 0.5
	pause_card.offset_right = pause_card.offset_left + card_size.x
	pause_card.offset_bottom = pause_card.offset_top + card_size.y
	if pause_text != null:
		pause_text.text = "Dòng thời gian đã dừng lại"
	for node in pause_card.find_children("*", "Button", true, false):
		(node as Button).custom_minimum_size.y = 84.0

func _build_objective_strip() -> void:
	var strip: CultivationPanel = CULTIVATION_PANEL.new()
	objective_strip = strip
	objective_strip.name = "ObjectivePlaque"
	strip.configure(CultivationPanel.FrameKind.BANNER, Color("#081719", 0.83), Color(JADE, 0.42), 10)
	strip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	strip.offset_left = 32.0
	strip.offset_top = -72.0
	strip.offset_right = 332.0
	strip.offset_bottom = -38.0
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(strip)
	objective_label = _label("THU LINH KHÍ  ·  PHÁ CẢNH", 11, PAPER_DIM, true)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strip.add_child(objective_label)


func _build_skill_strip() -> void:
	# Reduced five-medallion rail from the approved V4 board. It is intentionally
	# narrower than the player's movement lane and uses icon state before copy.
	skill_strip = Control.new()
	skill_strip.name = "FiveSkillRail"
	skill_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	skill_strip.offset_left = -250.0
	skill_strip.offset_top = -138.0
	skill_strip.offset_right = 250.0
	skill_strip.offset_bottom = -24.0
	skill_strip.clip_contents = false
	skill_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(skill_strip)
	var rail_panel := TextureRect.new()
	rail_panel.name = "AuthoredFiveSkillRail"
	rail_panel.texture = HUD_SKILL_RAIL
	rail_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rail_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rail_panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rail_panel.position = Vector2.ZERO
	rail_panel.size = Vector2(500.0, 114.0)
	rail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_strip.add_child(rail_panel)
	skill_rail_chrome = rail_panel
	skill_slots.clear()
	skill_frames.clear()
	skill_icons.clear()
	skill_key_labels.clear()
	skill_name_labels.clear()
	skill_lock_labels.clear()
	var skill_names := ["PHI KIẾM", "KIẾM TRẬN", "TỤ LINH", "NGỌC THỂ", "LINH THÚ"]
	var keys := ["1", "2", "3", "4", "5"]
	var slot_centers := [58.0, 159.0, 261.0, 362.0, 464.0]
	var icons := [
		SKILL_ICON_ROOT + "skill_phi_kiem.png",
		SKILL_ICON_ROOT + "skill_kiem_tran.png",
		SKILL_ICON_ROOT + "skill_linh_phu.png",
		SKILL_ICON_ROOT + "skill_bang_lien.png",
		SKILL_ICON_ROOT + "skill_thien_loi.png",
	]
	for index in skill_names.size():
		var slot := Control.new()
		slot.name = "SkillSlot_%02d" % (index + 1)
		slot.position = Vector2(slot_centers[index] - 42.0, 5.0)
		slot.size = Vector2(84.0, 91.0)
		slot.clip_contents = false
		skill_strip.add_child(slot)
		skill_slots.append(slot)
		var active := index < 2
		var frame := SkillMedallion.new()
		frame.configure(active)
		frame.position = Vector2(5.0, 0.0)
		frame.size = Vector2(74.0, 74.0)
		slot.add_child(frame)
		frame.visible = false
		skill_frames.append(frame)
		if ResourceLoader.exists(icons[index]):
			var icon_loaded: Variant = load(icons[index])
			if icon_loaded is Texture2D:
				var icon := TextureRect.new()
				icon.z_index = 2
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.texture = icon_loaded as Texture2D
				icon.custom_minimum_size = Vector2.ZERO
				icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(0.48, 0.56, 0.54, 0.62)
				icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(icon)
				skill_icons.append(icon)
				icon.position = Vector2(12.0, 1.0)
				icon.size = Vector2(60.0, 60.0)
		var key_label := _label(keys[index], 14, GOLD if active else PAPER_DIM, true)
		key_label.z_index = 3
		key_label.position = Vector2(1.0, 0.0)
		key_label.size = Vector2(20.0, 20.0)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(key_label)
		skill_key_labels.append(key_label)
		var name_label := _label(skill_names[index], 10, PAPER if active else PAPER_DIM, true)
		name_label.z_index = 3
		name_label.position = Vector2(-6.0, 65.0)
		name_label.size = Vector2(96.0, 18.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(name_label)
		skill_name_labels.append(name_label)
		if not active:
			var lock_label := _label("CẤP %d" % (index + 3), 10, CRIMSON, true)
			lock_label.z_index = 3
			lock_label.position = Vector2(-6.0, 50.0)
			lock_label.size = Vector2(96.0, 16.0)
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.add_child(lock_label)
			skill_lock_labels.append(lock_label)


func _layout_phone_skill_strip() -> void:
	if skill_strip == null:
		return
	skill_strip.size = Vector2(260.0, 58.0)
	if skill_rail_chrome != null:
		skill_rail_chrome.position = Vector2.ZERO
		skill_rail_chrome.size = Vector2(260.0, 58.0)
	var centres := [29.0, 79.5, 130.0, 180.5, 231.0]
	for index in mini(skill_slots.size(), centres.size()):
		var slot := skill_slots[index]
		slot.position = Vector2(centres[index] - 23.0, 1.0)
		slot.size = Vector2(46.0, 52.0)
		if index < skill_frames.size():
			skill_frames[index].position = Vector2(3.0, 0.0)
			skill_frames[index].size = Vector2(40.0, 40.0)
		if index < skill_icons.size():
			var icon := skill_icons[index]
			icon.position = Vector2(5.0, 2.0)
			icon.size = Vector2(36.0, 36.0)
		if index < skill_key_labels.size():
			skill_key_labels[index].hide()
		if index < skill_name_labels.size():
			skill_name_labels[index].hide()
	for lock_label in skill_lock_labels:
		lock_label.hide()


func _layout_desktop_skill_strip() -> void:
	if skill_strip == null:
		return
	skill_strip.size = Vector2(500.0, 114.0)
	if skill_rail_chrome != null:
		skill_rail_chrome.position = Vector2.ZERO
		skill_rail_chrome.size = Vector2(500.0, 114.0)
	var centres := [58.0, 159.0, 261.0, 362.0, 464.0]
	var names := ["PHI KIẾM", "KIẾM TRẬN", "TỤ LINH", "NGỌC THỂ", "LINH THÚ"]
	for index in mini(skill_slots.size(), centres.size()):
		var slot := skill_slots[index]
		slot.position = Vector2(centres[index] - 42.0, 5.0)
		slot.size = Vector2(84.0, 91.0)
		if index < skill_frames.size():
			skill_frames[index].position = Vector2(5.0, 0.0)
			skill_frames[index].size = Vector2(74.0, 74.0)
		if index < skill_icons.size():
			var icon := skill_icons[index]
			icon.position = Vector2(12.0, 1.0)
			icon.size = Vector2(60.0, 60.0)
		if index < skill_key_labels.size():
			var key_label := skill_key_labels[index]
			key_label.show()
			key_label.position = Vector2(0.0, 73.0)
			key_label.size = Vector2(84.0, 18.0)
			key_label.add_theme_font_size_override("font_size", 14)
		if index < skill_name_labels.size():
			skill_name_labels[index].text = names[index]
			skill_name_labels[index].hide()
	for lock_label in skill_lock_labels:
		lock_label.hide()

func _build_start_overlay() -> void:
	start_overlay = _full_overlay(Color(0.015, 0.035, 0.038, 0.58))
	root_control.add_child(start_overlay)
	var key_art := _load_key_art()
	if key_art != null:
		start_overlay.add_child(key_art)
		start_overlay.move_child(key_art, 0)
	var card := _title_card(Vector2(700.0, 616.0), Color("#d2c39e", 0.965), Color("#9a7133", 0.92))
	start_overlay.add_child(card)
	var content := _card_content(card, 38)
	content.alignment = BoxContainer.ALIGNMENT_CENTER

	var sigil := _label("—  VÂN MỘNG ĐẠO TÔNG  —", 16, BRONZE_INK, true)
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(sigil)
	var title := _label("VÂN MỘNG\nTU TIÊN", 47, PAPER_INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(580.0, 116.0)
	content.add_child(title)
	var subtitle := _label("NHẤT NIỆM NHẬP ĐẠO  ·  VẠN KIẾM HỘ THÂN", 14, Color("#276f65"), true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)
	content.add_child(_spacer(8.0))

	var lore := _label("Ma khí tràn khỏi Vân Mộng Cốc. Hãy gom linh khí, lĩnh ngộ công pháp\nvà sống sót cho đến khi Thiên Ma giáng thế.", 18, PAPER_COPY)
	lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size = Vector2(600.0, 64.0)
	content.add_child(lore)
	content.add_child(_spacer(5.0))

	var controls := _label("WASD / MŨI TÊN   DI CHUYỂN     ·     SPACE   KIẾM TRẬN\nP   TĨNH TÂM                         R   LUÂN HỒI", 14, Color(PAPER_INK, 0.92), true)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.custom_minimum_size = Vector2(600.0, 58.0)
	content.add_child(controls)
	content.add_child(_spacer(6.0))

	var start_button := _button("KHAI MỞ THIÊN KIẾP", 19, Vector2(356.0, 58.0))
	start_button.pressed.connect(func() -> void: Events.start_requested.emit())
	content.add_child(start_button)
	var hint := _label("NHẤN SPACE / ENTER", 11, Color(PAPER_COPY, 0.82))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

func _load_key_art() -> TextureRect:
	if not ResourceLoader.exists(KEY_ART_PATH):
		return null
	var loaded: Variant = load(KEY_ART_PATH)
	if not loaded is Texture2D:
		return null
	var art := TextureRect.new()
	art.texture = loaded as Texture2D
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(1.0, 1.0, 1.0, 0.82)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art

func _build_upgrade_overlay() -> void:
	upgrade_overlay = _full_overlay(Color(0.01, 0.025, 0.027, 0.80))
	upgrade_overlay.hide()
	root_control.add_child(upgrade_overlay)
	var ritual_halo: CultivationPanel = CULTIVATION_PANEL.new()
	upgrade_halo = ritual_halo
	ritual_halo.configure(CultivationPanel.FrameKind.SEAL, Color(0.0, 0.0, 0.0, 0.0), Color(GOLD, 0.60), 12)
	ritual_halo.use_authored_fixed(UPGRADE_VEIL)
	ritual_halo.set_anchors_preset(Control.PRESET_CENTER)
	ritual_halo.offset_left = -540.0
	ritual_halo.offset_top = -359.0
	ritual_halo.offset_right = 540.0
	ritual_halo.offset_bottom = 359.0
	ritual_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_overlay.add_child(ritual_halo)
	var column := VBoxContainer.new()
	upgrade_column = column
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -480.0
	column.offset_top = -270.0
	column.offset_right = 480.0
	column.offset_bottom = 270.0
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	upgrade_overlay.add_child(column)
	var eyebrow := _label("—  ĐẠO TÂM KHAI NGỘ  —", 15, GOLD, true)
	upgrade_eyebrow = eyebrow
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	var title := _label("LĨNH NGỘ CÔNG PHÁP", 30, PAPER, true)
	upgrade_title = title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var hint := _label("THỜI GIAN NGƯNG ĐỌNG   ·   CHỌN BẰNG CHUỘT HOẶC PHÍM 1 / 2 / 3", 12, PAPER_DIM)
	upgrade_hint = hint
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	upgrade_cards = HBoxContainer.new()
	upgrade_cards.custom_minimum_size = Vector2(860.0, 350.0)
	upgrade_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_cards.add_theme_constant_override("separation", 18)
	column.add_child(upgrade_cards)

func _build_pause_overlay() -> void:
	pause_overlay = _full_overlay(Color(0.01, 0.03, 0.035, 0.76))
	pause_overlay.hide()
	root_control.add_child(pause_overlay)
	var shrine: CultivationPanel = CULTIVATION_PANEL.new()
	shrine.name = "AuthoredPauseMeditationShrine"
	shrine.configure(CultivationPanel.FrameKind.SCROLL, Color.TRANSPARENT, Color(GOLD, 0.78), 27)
	shrine.use_authored_fixed(PAUSE_SHRINE)
	shrine.set_anchors_preset(Control.PRESET_CENTER)
	shrine.offset_left = -230.0
	shrine.offset_top = -167.5
	shrine.offset_right = 230.0
	shrine.offset_bottom = 167.5
	pause_card = shrine
	pause_overlay.add_child(shrine)

	var content := Control.new()
	content.name = "PauseLiveContent"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shrine.material_root.add_child(content)

	var eyebrow := _label("—  NHẤT NIỆM VÔ TRẦN  —", 14, BRONZE_INK, true)
	eyebrow.position = Vector2(80.0, 180.0)
	eyebrow.size = Vector2(300.0, 19.0)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	var title := _label("TĨNH TÂM", 28, PAPER_INK, true)
	title.position = Vector2(80.0, 197.0)
	title.size = Vector2(300.0, 38.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var text := _label("Dòng thời gian đã dừng lại\nP  tiếp tục   ·   R  nhập thế lại", 16, PAPER_COPY)
	pause_text = text
	text.position = Vector2(67.0, 231.0)
	text.size = Vector2(326.0, 26.0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(text)

	# The lower plaques are part of the authored shrine. Native buttons cover a
	# much larger invisible target while their live captions stay optically
	# centered inside those plaques.
	var resume_button := _art_target_button("TIẾP TỤC", 16, Rect2(54.0, 251.0, 151.0, 84.0))
	resume_button.pressed.connect(func() -> void: Events.resume_requested.emit())
	content.add_child(resume_button)
	var restart_button := _art_target_button("NHẬP THẾ LẠI", 15, Rect2(255.0, 251.0, 151.0, 84.0))
	restart_button.pressed.connect(func() -> void: Events.restart_requested.emit())
	content.add_child(restart_button)

func _build_end_overlay() -> void:
	end_overlay = _full_overlay(Color(0.01, 0.025, 0.03, 0.82))
	end_overlay.hide()
	root_control.add_child(end_overlay)
	var card := _center_card(Vector2(560.0, 340.0), Color("#0b191b", 0.98), Color("#9a7133", 0.90))
	end_overlay.add_child(card)
	var content := _card_content(card, 34)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var seal := _label("—  ĐẠO QUẢ  —", 15, GOLD, true)
	seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(seal)
	end_title = _label("PHI THĂNG", 38, PAPER, true)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(end_title)
	end_details = _label("", 17, PAPER_DIM)
	end_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_details.custom_minimum_size = Vector2(470.0, 76.0)
	content.add_child(end_details)
	var restart_button := _button("NHẬP THẾ LẠI  [R]", 17, Vector2(250.0, 54.0))
	restart_button.pressed.connect(func() -> void: Events.restart_requested.emit())
	content.add_child(restart_button)

func _build_banner() -> void:
	var banner: CultivationPanel = CULTIVATION_PANEL.new()
	banner_panel = banner
	banner.configure(CultivationPanel.FrameKind.BANNER, Color(INK, 0.89), Color(GOLD, 0.66), 14)
	banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_panel.offset_left = -230.0
	banner_panel.offset_top = 104.0
	banner_panel.offset_right = 230.0
	banner_panel.offset_bottom = 172.0
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.hide()
	root_control.add_child(banner_panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_panel.add_child(column)
	banner_title = _label("CẢNH GIỚI ĐỘT PHÁ", 19, GOLD, true)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(banner_title)
	banner_subtitle = _label("Đạo cơ sơ thành", 14, PAPER)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(banner_subtitle)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d/%d" % [ceili(current), ceili(maximum)]

func _on_experience_changed(current: float, required: float, level: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current
	level_label.text = "TU VI · %02d" % level

func _on_realm_changed(realm_name: String, _subtitle: String) -> void:
	realm_label.text = realm_name.to_upper()

func _on_run_stats_changed(elapsed: float, duration: float, kills: int) -> void:
	var remaining := maxi(0, ceili(duration - elapsed))
	var minutes := int(remaining / 60.0)
	var seconds := remaining % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	kills_label.text = "%d YÊU VẬT" % kills
	if remaining <= 0:
		objective_label.text = "THIÊN MA GIÁNG THẾ"

func _on_pulse_state_changed(remaining: float, cooldown: float) -> void:
	pulse_bar.max_value = cooldown
	pulse_bar.value = cooldown - remaining
	var compact_phone := _touch_layout_enabled and _is_phone_landscape_window()
	if remaining <= 0.01:
		pulse_label.text = "KIẾM TRẬN" if compact_phone else "[2] KIẾM TRẬN · SẴN SÀNG"
		pulse_label.add_theme_color_override("font_color", JADE)
	else:
		pulse_label.text = ("KIẾM · %.1fs" if compact_phone else "[2] KIẾM TRẬN · %.1fs") % remaining
		pulse_label.add_theme_color_override("font_color", PAPER_DIM)
	if compact_phone and pulse_plaque != null:
		pulse_plaque.size = Vector2(116.0, 40.0)

func _on_upgrade_options_presented(options: Array[Dictionary]) -> void:
	visible_upgrade_ids.clear()
	for child in upgrade_cards.get_children():
		upgrade_cards.remove_child(child)
		child.queue_free()
	for option_index in options.size():
		var option: Dictionary = options[option_index]
		visible_upgrade_ids.append(StringName(str(option.get("id", ""))))
		var card := _upgrade_button(option, option_index)
		upgrade_cards.add_child(card)
	_apply_safe_layout()
	if _touch_layout_enabled and _is_phone_landscape_window():
		_set_combat_chrome_visible(false)
	upgrade_overlay.show()
	if upgrade_cards.get_child_count() > 0:
		(upgrade_cards.get_child(0) as Button).call_deferred("grab_focus")

func _upgrade_button(option: Dictionary, card_index: int = 0) -> Button:
	var card: CultivationChoiceButton = CULTIVATION_CHOICE.new()
	card.custom_minimum_size = Vector2(270.0, 340.0)
	card.pivot_offset = Vector2(135.0, 170.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var option_id := StringName(str(option.get("id", "")))
	var accent := _upgrade_accent(str(option.get("id", "")), card_index)
	var icon_texture := _upgrade_icon(option_id)
	card.configure(
		card_index,
		str(option.get("glyph", "+")),
		str(option.get("title", "Công pháp")),
		str(option.get("description", "")),
		accent,
		icon_texture,
		_upgrade_folio_family(option_id)
	)
	card.pressed.connect(_on_upgrade_pressed.bind(option_id))
	return card


func _upgrade_folio_family(upgrade_id: StringName) -> int:
	match upgrade_id:
		&"sword_damage", &"attack_speed", &"extra_sword", &"piercing_sword", &"phoenix_blade", &"fallback_damage":
			return 0
		&"spirit_well", &"qi_pulse", &"cloud_step":
			return 1
		&"jade_body", &"life_stream", &"emergency_heal", &"fallback_vitality", &"fallback_regen":
			return 2
	return 1

func _upgrade_icon(upgrade_id: StringName) -> Texture2D:
	var path := ""
	match upgrade_id:
		&"sword_damage", &"attack_speed", &"extra_sword", &"piercing_sword", &"phoenix_blade", &"fallback_damage":
			path = "res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/sigil_phi_kiem.png"
		&"spirit_well", &"qi_pulse", &"cloud_step":
			path = "res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/sigil_tu_linh.png"
		&"jade_body", &"life_stream", &"emergency_heal", &"fallback_vitality", &"fallback_regen":
			path = "res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/sigil_ho_the_ngoc.png"
		_:
			path = "res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/sigil_tu_linh.png"
	if not ResourceLoader.exists(path):
		return null
	var loaded: Variant = load(path)
	if loaded is Texture2D:
		return loaded as Texture2D
	return null

func _upgrade_accent(upgrade_id: String, card_index: int) -> Color:
	if upgrade_id.contains("sword") or upgrade_id.contains("kiếm"):
		return Color("#d59c62")
	if upgrade_id.contains("qi") or upgrade_id.contains("linh") or upgrade_id.contains("aura"):
		return Color("#62c9a5")
	if upgrade_id.contains("life") or upgrade_id.contains("regen") or upgrade_id.contains("sinh"):
		return Color("#d46b67")
	var fallback := [Color("#b89043"), Color("#65b8c1"), Color("#9c84c5")]
	return fallback[mini(card_index, fallback.size() - 1)]

func _on_upgrade_pressed(upgrade_id: StringName) -> void:
	upgrade_overlay.hide()
	_set_combat_chrome_visible(true)
	Events.upgrade_selected.emit(upgrade_id)

func _select_upgrade_index(index: int) -> void:
	if index < 0 or index >= visible_upgrade_ids.size():
		return
	_on_upgrade_pressed(visible_upgrade_ids[index])

func _on_banner_requested(title: String, subtitle: String, duration: float) -> void:
	banner_title.text = title
	banner_subtitle.text = subtitle
	banner_duration = maxf(duration, 0.2)
	banner_remaining = banner_duration
	banner_panel.modulate.a = 0.0
	banner_panel.show()

func _on_game_started() -> void:
	start_overlay.hide()
	_set_combat_chrome_visible(true)
	upgrade_overlay.hide()
	pause_overlay.hide()
	end_overlay.hide()

func _on_game_paused(is_paused: bool) -> void:
	if upgrade_overlay.visible or end_overlay.visible:
		pause_overlay.hide()
	else:
		pause_overlay.visible = is_paused
	if _touch_layout_enabled and _is_phone_landscape_window() and not upgrade_overlay.visible and not end_overlay.visible:
		_set_combat_chrome_visible(not is_paused)

func _on_game_finished(victory: bool, title: String, details: String) -> void:
	upgrade_overlay.hide()
	pause_overlay.hide()
	_set_combat_chrome_visible(false)
	# FrontEnd presents authored results, rewards and hub navigation. The old
	# modal remains a fallback for focused HUD tests.
	if get_node_or_null("../FrontEnd") != null:
		end_overlay.hide()
		return
	end_title.text = title
	end_title.add_theme_color_override("font_color", GOLD if victory else Color("#e06b52"))
	end_details.text = details
	end_overlay.show()


func _set_combat_chrome_visible(value: bool) -> void:
	if top_hud != null:
		top_hud.visible = value
	if objective_strip != null:
		# V4 removes the redundant mission sentence from live combat. The object is
		# retained for compatibility and boss-state updates, but the world art and
		# enemy telegraphs own the lower-left lane.
		objective_strip.visible = false
	if skill_strip != null:
		skill_strip.visible = value

func _full_overlay(color: Color) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = color
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	return overlay

func _center_card(card_size: Vector2, fill: Color, border: Color) -> PanelContainer:
	var panel: CultivationPanel = CULTIVATION_PANEL.new()
	panel.configure(CultivationPanel.FrameKind.SCROLL, fill, border, 18)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -card_size.x * 0.5
	panel.offset_top = -card_size.y * 0.5
	panel.offset_right = card_size.x * 0.5
	panel.offset_bottom = card_size.y * 0.5
	return panel

func _title_card(card_size: Vector2, fill: Color, border: Color) -> PanelContainer:
	var panel: CultivationPanel = CULTIVATION_PANEL.new()
	panel.configure(CultivationPanel.FrameKind.SCROLL, fill, border, 21)
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 58.0
	panel.offset_top = -card_size.y * 0.5
	panel.offset_right = 58.0 + card_size.x
	panel.offset_bottom = card_size.y * 0.5
	return panel

func _card_content(card: PanelContainer, margin_size: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, margin_size)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	return content

func _label(text_value: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", DISPLAY_FONT if bold and font_size >= 25 else (ACTION_FONT if bold else BODY_FONT))
	label.add_theme_font_size_override("font_size", maxi(font_size, 14))
	label.add_theme_color_override("font_color", color)
	if bold:
		if color.get_luminance() > 0.48:
			label.add_theme_constant_override("outline_size", 3 if font_size >= 28 else 2)
			label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.52))
		else:
			label.add_theme_constant_override("outline_size", 1)
			label.add_theme_color_override("font_outline_color", Color(0.93, 0.87, 0.68, 0.24))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _progress_bar(fill_color: Color, maximum: float) -> ProgressBar:
	var bar: CultivationMeter = CULTIVATION_METER.new()
	bar.configure(fill_color, maximum, 1)
	bar.custom_minimum_size = Vector2(280.0, 19.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return bar

func _button(text_value: String, font_size: int, minimum: Vector2, variant: RasterButton.ArtVariant = RasterButton.ArtVariant.GOLD) -> Button:
	var button: RasterButton = RASTER_BUTTON.new()
	button.configure(text_value, variant, minimum, font_size)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button


func _art_target_button(text_value: String, font_size: int, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override(&"font", ACTION_FONT)
	button.add_theme_font_size_override(&"font_size", font_size)
	button.add_theme_color_override(&"font_color", PAPER_INK)
	button.add_theme_color_override(&"font_hover_color", Color("#0b4a40"))
	button.add_theme_color_override(&"font_focus_color", Color("#0b4a40"))
	button.add_theme_color_override(&"font_pressed_color", Color("#163b35"))
	button.add_theme_constant_override(&"outline_size", 1)
	button.add_theme_color_override(&"font_outline_color", Color(0.93, 0.87, 0.68, 0.18))
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override(&"normal", empty)
	button.add_theme_stylebox_override(&"pressed", empty)
	button.add_theme_stylebox_override(&"disabled", empty)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(JADE, 0.06)
	hover.border_color = Color(GOLD, 0.48)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		hover.set_border_width(side, 1)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"focus", hover)
	return button

func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1.0, height)
	return spacer
