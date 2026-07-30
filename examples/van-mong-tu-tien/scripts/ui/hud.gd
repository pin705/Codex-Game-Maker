class_name CultivationHUD
extends CanvasLayer

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
const BODY_FONT := preload("res://assets/fonts/BeVietnamPro-Regular.ttf")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")
const DISPLAY_FONT := preload("res://assets/fonts/Literata-Variable.ttf")

var root_control: Control
var health_bar: ProgressBar
var health_label: Label
var xp_bar: ProgressBar
var level_label: Label
var realm_label: Label
var timer_label: Label
var kills_label: Label
var pulse_bar: ProgressBar
var pulse_label: Label
var objective_label: Label
var top_hud: Control
var life_plaque: Control
var time_plaque: Control
var objective_strip: Control
var pulse_plaque: Control
var skill_strip: Control
var life_margin: MarginContainer
var player_portrait_frame: TextureRect
var player_portrait: TextureRect
var skill_rail_chrome: TextureRect
var skill_slots: Array[Control] = []
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
	# Combat HUD is intentionally split into three compact ritual objects.  The
	# old full-width dashboard hid a large slice of the arena and made every
	# statistic feel equally important.
	top_hud = Control.new()
	top_hud.name = "TopHUD"
	top_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(top_hud)

	var life_panel: CultivationPanel = CULTIVATION_PANEL.new()
	life_plaque = life_panel
	life_plaque.name = "LifePlaque"
	life_panel.configure(CultivationPanel.FrameKind.HUD, Color("#081719", 0.93), Color(GOLD, 0.64), 2)
	life_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
	life_plaque.offset_left = 64.0
	life_plaque.offset_top = 20.0
	life_plaque.offset_right = 664.0
	life_plaque.offset_bottom = 170.0
	top_hud.add_child(life_plaque)

	# PanelContainer owns the layout of direct children. Keep portrait chrome in
	# the panel's non-layout material root so it cannot be expanded over meters.
	player_portrait_frame = COMPONENT_KIT.ritual_chrome(life_panel.material_root, "touch_skill", Rect2(18.0, 23.0, 100.0, 100.0), Color(0.90, 1.0, 0.96, 0.92))
	if ResourceLoader.exists(PLAYER_PORTRAIT_PATH):
		var portrait_loaded: Variant = load(PLAYER_PORTRAIT_PATH)
		if portrait_loaded is Texture2D:
			player_portrait = TextureRect.new()
			player_portrait.name = "PlayerPortrait"
			player_portrait.position = Vector2(24.0, 22.0)
			player_portrait.size = Vector2(88.0, 106.0)
			player_portrait.texture = portrait_loaded as Texture2D
			player_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			player_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			player_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			player_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			life_panel.material_root.add_child(player_portrait)

	life_margin = MarginContainer.new()
	life_margin.add_theme_constant_override("margin_left", 126)
	life_margin.add_theme_constant_override("margin_right", 24)
	life_margin.add_theme_constant_override("margin_top", 15)
	life_margin.add_theme_constant_override("margin_bottom", 13)
	life_plaque.add_child(life_margin)
	var life_column := VBoxContainer.new()
	life_column.add_theme_constant_override("separation", 6)
	life_margin.add_child(life_column)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 12)
	life_column.add_child(identity_row)
	realm_label = _label("PHÀM NHÂN", 23, GOLD, true)
	realm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(realm_label)
	level_label = _label("TU VI · 01", 13, PAPER_DIM)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity_row.add_child(level_label)

	var health_row := HBoxContainer.new()
	health_row.add_theme_constant_override("separation", 9)
	life_column.add_child(health_row)
	var health_name := _label("MỆNH", 11, Color(CRIMSON, 0.92), true)
	health_name.custom_minimum_size = Vector2(48.0, 18.0)
	health_row.add_child(health_name)
	health_bar = _progress_bar(CRIMSON, 120.0)
	health_bar.custom_minimum_size = Vector2(255.0, 14.0)
	health_row.add_child(health_bar)
	health_label = _label("120 / 120", 12, PAPER)
	health_label.custom_minimum_size = Vector2(74.0, 18.0)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_row.add_child(health_label)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 9)
	life_column.add_child(xp_row)
	var xp_name := _label("KHÍ", 11, Color(JADE, 0.92), true)
	xp_name.custom_minimum_size = Vector2(48.0, 18.0)
	xp_row.add_child(xp_name)
	xp_bar = _progress_bar(JADE, 18.0)
	xp_bar.custom_minimum_size = Vector2(338.0, 10.0)
	xp_row.add_child(xp_bar)

	var time_panel: CultivationPanel = CULTIVATION_PANEL.new()
	time_plaque = time_panel
	time_plaque.name = "TimePlaque"
	time_panel.configure(CultivationPanel.FrameKind.HUD, Color("#081719", 0.90), Color(GOLD, 0.55), 5)
	time_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	time_plaque.offset_left = -292.0
	time_plaque.offset_top = 20.0
	time_plaque.offset_right = -64.0
	time_plaque.offset_bottom = 148.0
	top_hud.add_child(time_plaque)
	var time_margin := MarginContainer.new()
	time_margin.add_theme_constant_override("margin_left", 20)
	time_margin.add_theme_constant_override("margin_right", 20)
	time_margin.add_theme_constant_override("margin_top", 20)
	time_margin.add_theme_constant_override("margin_bottom", 16)
	time_plaque.add_child(time_margin)
	var stats := VBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", -1)
	time_margin.add_child(stats)
	var clock_caption := _label("THIÊN KIẾP", 10, Color(GOLD, 0.74), true)
	clock_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(clock_caption)
	timer_label = _label("04:00", 28, PAPER, true)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(timer_label)
	kills_label = _label("0 YÊU VẬT", 11, PAPER_DIM)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(kills_label)

	var pulse_panel: CultivationPanel = CULTIVATION_PANEL.new()
	pulse_plaque = pulse_panel
	pulse_plaque.name = "PulsePlaque"
	pulse_panel.configure(CultivationPanel.FrameKind.BANNER, Color("#081719", 0.91), Color(JADE, 0.62), 8)
	pulse_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pulse_plaque.offset_left = -478.0
	pulse_plaque.offset_top = -112.0
	pulse_plaque.offset_right = -64.0
	pulse_plaque.offset_bottom = -48.0
	top_hud.add_child(pulse_plaque)
	var pulse_margin := MarginContainer.new()
	pulse_margin.add_theme_constant_override("margin_left", 22)
	pulse_margin.add_theme_constant_override("margin_right", 22)
	pulse_margin.add_theme_constant_override("margin_top", 18)
	pulse_margin.add_theme_constant_override("margin_bottom", 11)
	pulse_plaque.add_child(pulse_margin)
	var pulse_column := VBoxContainer.new()
	pulse_column.add_theme_constant_override("separation", 5)
	pulse_margin.add_child(pulse_column)
	pulse_label = _label("SPACE  ·  KIẾM TRẬN", 14, JADE, true)
	pulse_column.add_child(pulse_label)
	pulse_bar = _progress_bar(GOLD, 1.0)
	pulse_bar.custom_minimum_size = Vector2(320.0, 11.0)
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
		life_plaque.offset_right = safe.position.x + 600.0
		life_plaque.offset_bottom = top + 150.0
	var pause_reserve := 96.0 if _touch_layout_enabled else 0.0
	if time_plaque != null:
		time_plaque.offset_right = -(right_outset + pause_reserve)
		time_plaque.offset_left = time_plaque.offset_right - 228.0
		time_plaque.offset_top = top
		time_plaque.offset_bottom = top + 128.0
	if pulse_plaque != null:
		pulse_plaque.offset_right = -(right_outset + pause_reserve)
		pulse_plaque.offset_left = pulse_plaque.offset_right - 414.0
		pulse_plaque.offset_top = top + 138.0
		pulse_plaque.offset_bottom = top + 202.0
	if objective_strip != null:
		var objective_left := safe.position.x + (220.0 if _touch_layout_enabled else 0.0)
		objective_strip.offset_left = objective_left
		objective_strip.offset_right = objective_left + 470.0
		objective_strip.offset_bottom = -(bottom_outset + 118.0)
		objective_strip.offset_top = objective_strip.offset_bottom - 52.0
	if skill_strip != null:
		skill_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		skill_strip.offset_left = -400.0
		skill_strip.offset_top = -196.0
		skill_strip.offset_right = 400.0
		skill_strip.offset_bottom = -32.0


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
	health_bar.custom_minimum_size = Vector2(140.0, 14.0)
	xp_bar.custom_minimum_size = Vector2(230.0, 10.0)
	pulse_bar.custom_minimum_size = Vector2(120.0, 11.0)
	if pulse_label != null and pulse_label.text.begins_with("SPACE"):
		pulse_label.text = "KIẾM TRẬN"
	if life_plaque != null:
		life_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
		life_plaque.position = Vector2(safe.position.x, safe.position.y)
		life_plaque.size = Vector2(360.0, 112.0)
	if life_margin != null:
		life_margin.add_theme_constant_override("margin_left", 20)
	if player_portrait_frame != null:
		player_portrait_frame.hide()
	if player_portrait != null:
		player_portrait.hide()
	if time_plaque != null:
		time_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
		time_plaque.position = Vector2(safe.end.x - 210.0, safe.position.y)
		time_plaque.size = Vector2(130.0, 94.0)
	if pulse_plaque != null:
		pulse_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
		pulse_plaque.position = Vector2(safe.position.x + 368.0, safe.position.y)
		pulse_plaque.size = Vector2(168.0, 64.0)
	if objective_strip != null:
		# The touch layout already explains movement and active skill state through
		# the controls/rail.  A second sentence under the rail only muddies combat.
		objective_strip.hide()
	if skill_strip != null:
		skill_strip.set_anchors_preset(Control.PRESET_TOP_LEFT)
		skill_strip.scale = Vector2.ONE * device_scale
		skill_strip.position = Vector2(safe.get_center().x - 240.0, safe.end.y - 104.0) * device_scale
		_layout_phone_skill_strip()
	_apply_upgrade_layout_for_viewport(device_scale, physical)
	_apply_pause_layout_for_viewport(device_scale, physical)


func _restore_desktop_hud_layout() -> void:
	if top_hud == null:
		return
	top_hud.scale = Vector2.ONE
	top_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_bar.custom_minimum_size = Vector2(255.0, 14.0)
	xp_bar.custom_minimum_size = Vector2(338.0, 10.0)
	pulse_bar.custom_minimum_size = Vector2(320.0, 11.0)
	if life_plaque != null:
		life_plaque.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if life_margin != null:
		life_margin.add_theme_constant_override("margin_left", 126)
	if player_portrait_frame != null:
		player_portrait_frame.show()
	if player_portrait != null:
		player_portrait.show()
	if time_plaque != null:
		time_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	if pulse_plaque != null:
		pulse_plaque.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	if objective_strip != null:
		objective_strip.show()
		objective_strip.scale = Vector2.ONE
		objective_strip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	if skill_strip != null:
		skill_strip.scale = Vector2.ONE
		skill_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_layout_desktop_skill_strip()
	_apply_upgrade_layout_for_viewport(1.0, root_control.size)
	_apply_pause_layout_for_viewport(1.0, root_control.size)


func _apply_upgrade_layout_for_viewport(device_scale: float, viewport_size: Vector2) -> void:
	if upgrade_column == null or upgrade_cards == null or upgrade_halo == null:
		return
	var phone_layout := _touch_layout_enabled and _is_phone_landscape_window()
	if phone_layout:
		upgrade_halo.hide()
		upgrade_column.scale = Vector2.ONE * device_scale
		upgrade_column.set_anchors_preset(Control.PRESET_TOP_LEFT)
		upgrade_column.position = Vector2(22.0, 4.0) * device_scale
		upgrade_column.size = Vector2(viewport_size.x - 44.0, viewport_size.y - 8.0)
		upgrade_column.add_theme_constant_override("separation", 4)
		upgrade_cards.custom_minimum_size = Vector2(viewport_size.x - 44.0, 260.0)
		upgrade_cards.add_theme_constant_override("separation", 8)
		if upgrade_hint != null:
			upgrade_hint.text = "THỜI GIAN NGƯNG ĐỌNG  ·  CHẠM MỘT PHÙ LỤC ĐỂ LĨNH NGỘ"
		for child in upgrade_cards.get_children():
			if child is Control:
				(child as Control).custom_minimum_size = Vector2(250.0, 260.0)
				(child as Control).pivot_offset = Vector2(125.0, 130.0)
			if child.has_method("set_touch_mode"):
				child.call("set_touch_mode", true)
		return
	upgrade_halo.show()
	upgrade_column.scale = Vector2.ONE
	upgrade_column.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_column.offset_left = -670.0
	upgrade_column.offset_top = -330.0
	upgrade_column.offset_right = 670.0
	upgrade_column.offset_bottom = 330.0
	upgrade_column.add_theme_constant_override("separation", 15)
	upgrade_cards.custom_minimum_size = Vector2(1260.0, 430.0)
	upgrade_cards.add_theme_constant_override("separation", 28)
	if upgrade_hint != null:
		upgrade_hint.text = "THỜI GIAN NGƯNG ĐỌNG   ·   CHỌN BẰNG CHUỘT HOẶC PHÍM 1 / 2 / 3"
	for child in upgrade_cards.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(330.0, 390.0)
			(child as Control).pivot_offset = Vector2(165.0, 195.0)
		if child.has_method("set_touch_mode"):
			child.call("set_touch_mode", false)


func _apply_pause_layout_for_viewport(device_scale: float, viewport_size: Vector2) -> void:
	if pause_card == null:
		return
	var card_size := Vector2(620.0, 360.0)
	if _touch_layout_enabled and _is_phone_landscape_window():
		pause_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
		pause_card.scale = Vector2.ONE * device_scale
		pause_card.position = (viewport_size - card_size) * 0.5 * device_scale
		pause_card.size = card_size
		if pause_text != null:
			pause_text.text = "Hành trình đã tạm dừng\nChạm TIẾP TỤC để trở lại chiến trận"
		return
	pause_card.scale = Vector2.ONE
	pause_card.set_anchors_preset(Control.PRESET_CENTER)
	pause_card.offset_left = -card_size.x * 0.5
	pause_card.offset_top = -card_size.y * 0.5
	pause_card.offset_right = card_size.x * 0.5
	pause_card.offset_bottom = card_size.y * 0.5
	if pause_text != null:
		pause_text.text = "Dòng thời gian đã dừng lại\nP  tiếp tục hành trình   ·   R  nhập thế lại"

func _build_objective_strip() -> void:
	var strip: CultivationPanel = CULTIVATION_PANEL.new()
	objective_strip = strip
	objective_strip.name = "ObjectivePlaque"
	strip.configure(CultivationPanel.FrameKind.BANNER, Color("#081719", 0.83), Color(JADE, 0.42), 10)
	strip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	strip.offset_left = 64.0
	strip.offset_top = -100.0
	strip.offset_right = 534.0
	strip.offset_bottom = -48.0
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(strip)
	COMPONENT_KIT.nine_patch(strip, "secondary", Rect2(0.0, 0.0, 470.0, 52.0), Color(0.76, 0.90, 0.84, 0.94))
	objective_label = _label("SINH TỒN  ·  THU LINH KHÍ  ·  PHÁ CẢNH", 12, PAPER_DIM, true)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strip.add_child(objective_label)


func _build_skill_strip() -> void:
	# Five-slot combat rail follows the selected arsenal direction. The first two
	# slots mirror currently playable actions; the remaining slots communicate
	# loadout capacity and progression without pretending locked skills are live.
	skill_strip = Control.new()
	skill_strip.name = "FiveSkillRail"
	skill_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	skill_strip.offset_left = -400.0
	skill_strip.offset_top = -196.0
	skill_strip.offset_right = 400.0
	skill_strip.offset_bottom = -32.0
	skill_strip.clip_contents = false
	skill_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(skill_strip)
	skill_rail_chrome = COMPONENT_KIT.ritual_chrome(skill_strip, "skill_rail", Rect2(0.0, 0.0, 800.0, 164.0), Color(0.92, 0.98, 0.94, 0.98))
	skill_slots.clear()
	skill_icons.clear()
	skill_key_labels.clear()
	skill_name_labels.clear()
	skill_lock_labels.clear()
	var skill_names := ["PHI KIẾM", "KIẾM TRẬN", "TỤ LINH", "NGỌC THỂ", "LINH THÚ"]
	var keys := ["1", "2", "3", "4", "5"]
	var slot_centers := [132.0, 269.0, 403.0, 540.0, 675.0]
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
		slot.position = Vector2(slot_centers[index] - 58.0, 17.0)
		slot.size = Vector2(116.0, 140.0)
		slot.clip_contents = false
		skill_strip.add_child(slot)
		skill_slots.append(slot)
		var active := index < 2
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
				icon.position = Vector2(14.0, 3.0)
				icon.size = Vector2(88.0, 88.0)
		var key_label := _label(keys[index], 14, GOLD if active else PAPER_DIM, true)
		key_label.z_index = 3
		key_label.position = Vector2(-3.0, -4.0)
		key_label.size = Vector2(24.0, 24.0)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(key_label)
		skill_key_labels.append(key_label)
		var name_label := _label(skill_names[index], 10, PAPER if active else PAPER_DIM, true)
		name_label.z_index = 3
		name_label.position = Vector2(-8.0, 102.0)
		name_label.size = Vector2(132.0, 20.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(name_label)
		skill_name_labels.append(name_label)
		if not active:
			var lock_label := _label("CẤP %d" % (index + 3), 10, CRIMSON, true)
			lock_label.z_index = 3
			lock_label.position = Vector2(-8.0, 82.0)
			lock_label.size = Vector2(132.0, 16.0)
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.add_child(lock_label)
			skill_lock_labels.append(lock_label)


func _layout_phone_skill_strip() -> void:
	if skill_strip == null:
		return
	skill_strip.size = Vector2(480.0, 104.0)
	if skill_rail_chrome != null:
		skill_rail_chrome.position = Vector2.ZERO
		skill_rail_chrome.size = Vector2(480.0, 99.0)
	var centres := [79.0, 160.0, 241.0, 322.0, 403.0]
	for index in mini(skill_slots.size(), centres.size()):
		var slot := skill_slots[index]
		slot.position = Vector2(centres[index] - 38.0, 3.0)
		slot.size = Vector2(76.0, 96.0)
		if index < skill_icons.size():
			var icon := skill_icons[index]
			icon.position = Vector2(10.0, 4.0)
			icon.size = Vector2(56.0, 56.0)
		if index < skill_key_labels.size():
			skill_key_labels[index].hide()
		if index < skill_name_labels.size():
			var name_label := skill_name_labels[index]
			name_label.position = Vector2(-7.0, 68.0)
			name_label.size = Vector2(90.0, 18.0)
			name_label.add_theme_font_size_override("font_size", 10)
			name_label.text = ["PHI KIẾM", "KIẾM TRẬN", "KHÓA", "KHÓA", "KHÓA"][index]
	for lock_label in skill_lock_labels:
		lock_label.hide()


func _layout_desktop_skill_strip() -> void:
	if skill_strip == null:
		return
	skill_strip.size = Vector2(800.0, 164.0)
	if skill_rail_chrome != null:
		skill_rail_chrome.position = Vector2.ZERO
		skill_rail_chrome.size = Vector2(800.0, 164.0)
	var centres := [132.0, 269.0, 403.0, 540.0, 675.0]
	var names := ["PHI KIẾM", "KIẾM TRẬN", "TỤ LINH", "NGỌC THỂ", "LINH THÚ"]
	for index in mini(skill_slots.size(), centres.size()):
		var slot := skill_slots[index]
		slot.position = Vector2(centres[index] - 58.0, 17.0)
		slot.size = Vector2(116.0, 140.0)
		if index < skill_icons.size():
			var icon := skill_icons[index]
			icon.position = Vector2(14.0, 3.0)
			icon.size = Vector2(88.0, 88.0)
		if index < skill_key_labels.size():
			var key_label := skill_key_labels[index]
			key_label.show()
			key_label.position = Vector2(-3.0, -4.0)
			key_label.size = Vector2(24.0, 24.0)
		if index < skill_name_labels.size():
			var name_label := skill_name_labels[index]
			name_label.position = Vector2(-8.0, 102.0)
			name_label.size = Vector2(132.0, 20.0)
			name_label.add_theme_font_size_override("font_size", 10)
			name_label.text = names[index]
	for lock_label in skill_lock_labels:
		lock_label.show()

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
	upgrade_overlay = _full_overlay(Color(0.01, 0.025, 0.027, 0.88))
	upgrade_overlay.hide()
	root_control.add_child(upgrade_overlay)
	var ritual_halo: CultivationPanel = CULTIVATION_PANEL.new()
	upgrade_halo = ritual_halo
	ritual_halo.configure(CultivationPanel.FrameKind.SEAL, Color(0.0, 0.0, 0.0, 0.0), Color(GOLD, 0.60), 12)
	ritual_halo.set_anchors_preset(Control.PRESET_CENTER)
	ritual_halo.offset_left = -330.0
	ritual_halo.offset_top = -330.0
	ritual_halo.offset_right = 330.0
	ritual_halo.offset_bottom = 330.0
	ritual_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_overlay.add_child(ritual_halo)
	var column := VBoxContainer.new()
	upgrade_column = column
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -670.0
	column.offset_top = -330.0
	column.offset_right = 670.0
	column.offset_bottom = 330.0
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 15)
	upgrade_overlay.add_child(column)
	var eyebrow := _label("—  ĐẠO TÂM KHAI NGỘ  —", 15, GOLD, true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	var title := _label("LĨNH NGỘ CÔNG PHÁP", 34, PAPER, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var hint := _label("THỜI GIAN NGƯNG ĐỌNG   ·   CHỌN BẰNG CHUỘT HOẶC PHÍM 1 / 2 / 3", 12, PAPER_DIM)
	upgrade_hint = hint
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	upgrade_cards = HBoxContainer.new()
	upgrade_cards.custom_minimum_size = Vector2(1260.0, 430.0)
	upgrade_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_cards.add_theme_constant_override("separation", 28)
	column.add_child(upgrade_cards)

func _build_pause_overlay() -> void:
	pause_overlay = _full_overlay(Color(0.01, 0.03, 0.035, 0.72))
	pause_overlay.hide()
	root_control.add_child(pause_overlay)
	var card := _center_card(Vector2(620.0, 360.0), Color("#d2c39e", 0.975), Color("#427d6f", 0.82))
	pause_card = card
	pause_overlay.add_child(card)
	var content := _card_content(card, 34)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var eyebrow := _label("—  NHẤT NIỆM VÔ TRẦN  —", 13, Color("#276f65"), true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	var title := _label("TĨNH TÂM", 38, PAPER_INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var text := _label("Dòng thời gian đã dừng lại\nP  tiếp tục hành trình   ·   R  nhập thế lại", 16, PAPER_COPY)
	pause_text = text
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(text)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	content.add_child(actions)
	var resume_button := _button("TIẾP TỤC", 17, Vector2(230.0, 64.0), RasterButton.ArtVariant.JADE)
	resume_button.pressed.connect(func() -> void: Events.resume_requested.emit())
	actions.add_child(resume_button)
	var restart_button := _button("NHẬP THẾ LẠI", 16, Vector2(230.0, 64.0), RasterButton.ArtVariant.CRIMSON)
	restart_button.pressed.connect(func() -> void: Events.restart_requested.emit())
	actions.add_child(restart_button)

func _build_end_overlay() -> void:
	end_overlay = _full_overlay(Color(0.01, 0.025, 0.03, 0.88))
	end_overlay.hide()
	root_control.add_child(end_overlay)
	var card := _center_card(Vector2(700.0, 462.0), Color("#d2c39e", 0.98), Color("#9a7133", 0.90))
	end_overlay.add_child(card)
	var content := _card_content(card, 42)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var seal := _label("—  ĐẠO QUẢ  —", 15, BRONZE_INK, true)
	seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(seal)
	end_title = _label("PHI THĂNG", 46, PAPER_INK, true)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(end_title)
	end_details = _label("", 18, PAPER_COPY)
	end_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_details.custom_minimum_size = Vector2(600.0, 100.0)
	content.add_child(end_details)
	var restart_button := _button("NHẬP THẾ LẠI  [R]", 18, Vector2(310.0, 56.0))
	restart_button.pressed.connect(func() -> void: Events.restart_requested.emit())
	content.add_child(restart_button)

func _build_banner() -> void:
	var banner: CultivationPanel = CULTIVATION_PANEL.new()
	banner_panel = banner
	banner.configure(CultivationPanel.FrameKind.BANNER, Color(INK, 0.89), Color(GOLD, 0.66), 14)
	banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_panel.offset_left = -340.0
	banner_panel.offset_top = 132.0
	banner_panel.offset_right = 340.0
	banner_panel.offset_bottom = 224.0
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.hide()
	root_control.add_child(banner_panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_panel.add_child(column)
	banner_title = _label("CẢNH GIỚI ĐỘT PHÁ", 22, GOLD, true)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(banner_title)
	banner_subtitle = _label("Đạo cơ sơ thành", 16, PAPER)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(banner_subtitle)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [ceili(current), ceili(maximum)]

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
		objective_label.text = "THIÊN MA GIÁNG THẾ  ·  ĐÁNH BẠI ĐỂ PHI THĂNG"

func _on_pulse_state_changed(remaining: float, cooldown: float) -> void:
	pulse_bar.max_value = cooldown
	pulse_bar.value = cooldown - remaining
	var compact_phone := _touch_layout_enabled and _is_phone_landscape_window()
	if remaining <= 0.01:
		pulse_label.text = "KIẾM TRẬN" if compact_phone else ("KIẾM TRẬN — SẴN SÀNG" if _touch_layout_enabled else "SPACE  ·  KIẾM TRẬN — SẴN SÀNG")
		pulse_label.add_theme_color_override("font_color", JADE)
	else:
		pulse_label.text = ("KIẾM · %.1fs" if compact_phone else "KIẾM TRẬN  ·  %.1fs") % remaining
		pulse_label.add_theme_color_override("font_color", PAPER_DIM)
	if compact_phone and pulse_plaque != null:
		pulse_plaque.size = Vector2(168.0, 64.0)

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
	card.custom_minimum_size = Vector2(330.0, 390.0)
	card.pivot_offset = Vector2(165.0, 195.0)
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
		icon_texture
	)
	card.pressed.connect(_on_upgrade_pressed.bind(option_id))
	return card

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
	end_title.add_theme_color_override("font_color", BRONZE_INK if victory else Color("#8e312f"))
	end_details.text = details
	end_overlay.show()


func _set_combat_chrome_visible(value: bool) -> void:
	if top_hud != null:
		top_hud.visible = value
	if objective_strip != null:
		objective_strip.visible = value and not (_touch_layout_enabled and _is_phone_landscape_window())
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
			label.add_theme_constant_override("outline_size", 4)
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

func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1.0, height)
	return spacer
