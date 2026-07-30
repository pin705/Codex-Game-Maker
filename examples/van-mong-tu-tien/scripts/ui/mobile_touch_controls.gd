class_name MobileTouchControls
extends Control

## Landscape multi-touch controls for the combat scene.
##
## Movement is mirrored to the existing move_* InputMap actions so the player
## controller needs no mobile-specific branch. Pulse and pause are dispatched as
## InputEventAction instances, allowing existing _unhandled_input code to react.

signal movement_changed(direction: Vector2)
signal pulse_pressed
signal pulse_released
signal pause_requested
signal controls_visibility_changed(is_visible: bool)
signal layout_changed(safe_area: Rect2)

const SafeArea := preload("res://scripts/ui/mobile_safe_area.gd")
const PULSE_TEXTURE: Texture2D = preload("res://assets/generated/vfx/PREMIUM-001-cultivation-sigils/runtime/sigil_tu_linh.png")
const JOYSTICK_FRAME_TEXTURE: Texture2D = preload("res://assets/generated/ui/UIKIT-011-v4-hud/runtime/joystick_medallion.png")
const ATTACK_FRAME_TEXTURE: Texture2D = preload("res://assets/generated/ui/UIKIT-011-v4-hud/runtime/attack_medallion.png")
const ACTION_FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const PULSE_ACTION := &"qi_pulse"
const PAUSE_ACTION := &"pause_game"

const MIN_TARGET_SIZE := 64.0
const REFERENCE_HEIGHT := 900.0
const JOYSTICK_TARGET_SIZE := 192.0
const PULSE_TARGET_SIZE := 128.0
const PAUSE_TARGET_SIZE := 64.0
const JOYSTICK_VISUAL_RADIUS_RATIO := 0.30
const KNOB_RADIUS_RATIO := 0.15

const INK := Color("#0b171b")
const JADE := Color("#55c9a6")
const JADE_LIGHT := Color("#dffff2")
const GOLD := Color("#c69a48")
const PAPER := Color("#e7ddc4")

@export var touchscreen_only := true
@export_range(0.0, 0.20, 0.005) var title_safe_margin_ratio := 0.05
@export_range(0.0, 48.0, 1.0) var additional_safe_padding := 8.0
@export_range(0.0, 0.75, 0.01) var joystick_dead_zone := 0.16
@export var consume_touch_events := true

var movement_vector := Vector2.ZERO
var controls_enabled := true

var _joystick_touch := -1
var _pulse_touch := -1
var _joystick_hit_rect := Rect2()
var _pulse_hit_rect := Rect2()
var _pause_hit_rect := Rect2()
var _joystick_center := Vector2.ZERO
var _joystick_radius := 72.0
var _knob_radius := 36.0
var _safe_rect := Rect2()
var _viewport_size_override := Vector2.ZERO
var _safe_area_override := Rect2()
var _has_safe_area_override := false
var _force_visible_for_test := false
var _device_pixel_scale := 1.0
var _attack_frame: Texture2D
var _joystick_frame: Texture2D


func _ready() -> void:
	# Authored medallions sit inside the independently tested hit rectangles.
	# Input geometry remains native and larger than the visible ornament.
	_attack_frame = ATTACK_FRAME_TEXTURE
	_joystick_frame = JOYSTICK_FRAME_TEXTURE
	set_process_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_refresh_visibility()
	_refresh_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_layout()
	elif what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			release_all_inputs()
	elif what == NOTIFICATION_PREDELETE:
		release_all_inputs()


func _input(event: InputEvent) -> void:
	if not visible or not controls_enabled:
		return
	if handle_touch_event(event) and consume_touch_events and is_inside_tree():
		get_viewport().set_input_as_handled()


## Deterministic entry point used both by _input and the headless harness.
func handle_touch_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			return _handle_touch_pressed(touch.index, touch.position)
		return _handle_touch_released(touch.index)
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joystick_touch:
			_update_joystick(drag.position)
			return true
		return drag.index == _pulse_touch
	return false


func set_controls_enabled(value: bool) -> void:
	if controls_enabled == value:
		return
	controls_enabled = value
	if not value:
		release_all_inputs()
	queue_redraw()


func set_force_visible_for_test(value: bool) -> void:
	_force_visible_for_test = value
	_refresh_visibility()


func set_viewport_size_override(value: Vector2) -> void:
	_viewport_size_override = value.max(Vector2.ZERO)
	_refresh_layout()


func clear_viewport_size_override() -> void:
	_viewport_size_override = Vector2.ZERO
	_refresh_layout()


func set_safe_area_override(value: Rect2) -> void:
	_safe_area_override = value
	_has_safe_area_override = value.has_area()
	_refresh_layout()


func clear_safe_area_override() -> void:
	_safe_area_override = Rect2()
	_has_safe_area_override = false
	_refresh_layout()


func refresh_mobile_layout() -> void:
	_refresh_visibility()
	_refresh_layout()


func get_safe_area_rect() -> Rect2:
	return _safe_rect


func get_joystick_hit_rect() -> Rect2:
	return _joystick_hit_rect


func get_pulse_hit_rect() -> Rect2:
	return _pulse_hit_rect


func get_pause_hit_rect() -> Rect2:
	return _pause_hit_rect


func get_joystick_center() -> Vector2:
	return _joystick_center


func get_layout_snapshot() -> Dictionary:
	return {
		"safe_area": _safe_rect,
		"joystick": _joystick_hit_rect,
		"pulse": _pulse_hit_rect,
		"pause": _pause_hit_rect,
		"movement": movement_vector,
		"logical_pixels_per_device_pixel": _device_pixel_scale,
	}


func release_all_inputs() -> void:
	var pulse_was_active := _pulse_touch >= 0
	_joystick_touch = -1
	_pulse_touch = -1
	_set_movement(Vector2.ZERO)
	_dispatch_action(PULSE_ACTION, false, 0.0)
	if pulse_was_active:
		pulse_released.emit()
	queue_redraw()


func _handle_touch_pressed(touch_index: int, position: Vector2) -> bool:
	if _pause_hit_rect.has_point(position):
		pause_requested.emit()
		_dispatch_action(PAUSE_ACTION, true, 1.0)
		call_deferred("_release_pause_action")
		queue_redraw()
		return true
	if _pulse_hit_rect.has_point(position) and _pulse_touch < 0:
		_pulse_touch = touch_index
		_dispatch_action(PULSE_ACTION, true, 1.0)
		pulse_pressed.emit()
		queue_redraw()
		return true
	if _joystick_hit_rect.has_point(position) and _joystick_touch < 0:
		_joystick_touch = touch_index
		_update_joystick(position)
		return true
	return false


func _handle_touch_released(touch_index: int) -> bool:
	if touch_index == _joystick_touch:
		_joystick_touch = -1
		_set_movement(Vector2.ZERO)
		queue_redraw()
		return true
	if touch_index == _pulse_touch:
		_pulse_touch = -1
		_dispatch_action(PULSE_ACTION, false, 0.0)
		pulse_released.emit()
		queue_redraw()
		return true
	return false


func _update_joystick(position: Vector2) -> void:
	var raw := (position - _joystick_center) / maxf(1.0, _joystick_radius)
	if raw.length() > 1.0:
		raw = raw.normalized()
	var magnitude := raw.length()
	var direction := Vector2.ZERO
	if magnitude > joystick_dead_zone:
		var remapped := inverse_lerp(joystick_dead_zone, 1.0, magnitude)
		direction = raw.normalized() * clampf(remapped, 0.0, 1.0)
	_set_movement(direction)
	queue_redraw()


func _set_movement(direction: Vector2) -> void:
	if direction.length() > 1.0:
		direction = direction.normalized()
	if movement_vector.is_equal_approx(direction):
		return
	movement_vector = direction
	_dispatch_action(MOVE_LEFT, direction.x < 0.0, maxf(0.0, -direction.x))
	_dispatch_action(MOVE_RIGHT, direction.x > 0.0, maxf(0.0, direction.x))
	_dispatch_action(MOVE_UP, direction.y < 0.0, maxf(0.0, -direction.y))
	_dispatch_action(MOVE_DOWN, direction.y > 0.0, maxf(0.0, direction.y))
	movement_changed.emit(movement_vector)


func _dispatch_action(action: StringName, pressed: bool, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if pressed:
		Input.action_press(action, clampf(strength, 0.0, 1.0))
	else:
		Input.action_release(action)
	var action_event := InputEventAction.new()
	action_event.action = action
	action_event.pressed = pressed
	action_event.strength = clampf(strength, 0.0, 1.0)
	Input.parse_input_event(action_event)


func _release_pause_action() -> void:
	_dispatch_action(PAUSE_ACTION, false, 0.0)


func _refresh_visibility() -> void:
	var should_show := controls_enabled and (
		_force_visible_for_test
		or not touchscreen_only
		or DisplayServer.is_touchscreen_available()
	)
	if visible != should_show:
		visible = should_show
		controls_visibility_changed.emit(should_show)


func _refresh_layout() -> void:
	var viewport_size := _get_layout_viewport_size()
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	_device_pixel_scale = _logical_pixels_per_device_pixel(viewport_size)
	var raw_safe := _safe_area_override if _has_safe_area_override else SafeArea.platform_safe_rect(viewport_size)
	var ui_scale := clampf(viewport_size.y / REFERENCE_HEIGHT, 0.72, 1.35)
	_safe_rect = SafeArea.title_safe_rect(
		viewport_size,
		raw_safe,
		title_safe_margin_ratio,
		additional_safe_padding * ui_scale
	)
	var minimum_target := MIN_TARGET_SIZE * _device_pixel_scale
	var joystick_target := maxf(minimum_target, JOYSTICK_TARGET_SIZE * ui_scale)
	var pulse_target := maxf(minimum_target, PULSE_TARGET_SIZE * ui_scale)
	var pause_target := maxf(minimum_target, PAUSE_TARGET_SIZE * ui_scale)
	var joystick_center := Vector2(
		_safe_rect.position.x + joystick_target * 0.5,
		_safe_rect.end.y - joystick_target * 0.5
	)
	var pulse_center := Vector2(
		_safe_rect.end.x - pulse_target * 0.5,
		_safe_rect.end.y - pulse_target * 0.5
	)
	var pause_center := Vector2(
		_safe_rect.end.x - pause_target * 0.5,
		_safe_rect.position.y + pause_target * 0.5
	)
	_joystick_hit_rect = SafeArea.centered_rect_inside(
		_safe_rect, joystick_center, Vector2.ONE * joystick_target
	)
	_pulse_hit_rect = SafeArea.centered_rect_inside(
		_safe_rect, pulse_center, Vector2.ONE * pulse_target
	)
	_pause_hit_rect = SafeArea.centered_rect_inside(
		_safe_rect, pause_center, Vector2.ONE * pause_target
	)
	_joystick_center = _joystick_hit_rect.get_center()
	_joystick_radius = minf(_joystick_hit_rect.size.x, _joystick_hit_rect.size.y) * JOYSTICK_VISUAL_RADIUS_RATIO
	_knob_radius = minf(_joystick_hit_rect.size.x, _joystick_hit_rect.size.y) * KNOB_RADIUS_RATIO
	layout_changed.emit(_safe_rect)
	queue_redraw()


func _logical_pixels_per_device_pixel(viewport_size: Vector2) -> float:
	# Deterministic overrides already describe the coordinate space under test.
	if _viewport_size_override.x > 0.0 and _viewport_size_override.y > 0.0:
		return 1.0
	var physical := Vector2(DisplayServer.window_get_size())
	if physical.x <= 1.0 or physical.y <= 1.0:
		return 1.0
	# On canvas_items + expand, an 844x390 device exposes roughly 1947x900
	# logical units. Convert the 64 px accessibility floor into those units.
	if physical.x <= 960.0 and physical.y <= 540.0 and physical.x > physical.y:
		return maxf(1.0, minf(viewport_size.x / physical.x, viewport_size.y / physical.y))
	return 1.0


func _get_layout_viewport_size() -> Vector2:
	if _viewport_size_override.x > 0.0 and _viewport_size_override.y > 0.0:
		return _viewport_size_override
	if size.x > 1.0 and size.y > 1.0:
		return size
	if is_inside_tree():
		return get_viewport_rect().size
	return Vector2(1600.0, 900.0)


func _draw() -> void:
	if not controls_enabled:
		return
	_draw_joystick()
	_draw_pulse_button()
	_draw_pause_button()


func _draw_joystick() -> void:
	draw_circle(_joystick_center + Vector2(3.0, 5.0), _joystick_radius + 5.0, Color(0.0, 0.0, 0.0, 0.28))
	if _joystick_frame != null:
		var frame_size := Vector2.ONE * (_joystick_radius + 9.0) * 2.0
		draw_texture_rect(_joystick_frame, _fit_texture_at_center(_joystick_frame, _joystick_center, frame_size), false, Color(1.0, 1.0, 1.0, 0.92))
	else:
		draw_circle(_joystick_center, _joystick_radius + 3.0, Color(INK, 0.54))
		draw_arc(_joystick_center, _joystick_radius + 1.0, 0.0, TAU, 56, Color(GOLD, 0.72), 2.0, true)
		draw_arc(_joystick_center, _joystick_radius * 0.72, 0.0, TAU, 48, Color(JADE, 0.34), 1.2, true)
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var start := _joystick_center + direction * _joystick_radius * 0.76
		var finish := _joystick_center + direction * _joystick_radius * 0.91
		draw_line(start, finish, Color(PAPER, 0.42), 2.0, true)
	var knob_travel := maxf(0.0, _joystick_radius - _knob_radius - 6.0)
	var knob_center := _joystick_center + movement_vector * knob_travel
	draw_circle(knob_center + Vector2(2.0, 3.0), _knob_radius + 2.0, Color(0.0, 0.0, 0.0, 0.36))
	draw_circle(knob_center, _knob_radius, Color(JADE.darkened(0.24), 0.92 if _joystick_touch >= 0 else 0.76))
	draw_arc(knob_center, _knob_radius - 2.0, 0.0, TAU, 36, Color(JADE_LIGHT, 0.70), 1.5, true)


func _draw_pulse_button() -> void:
	var center := _pulse_hit_rect.get_center()
	var radius := minf(_pulse_hit_rect.size.x, _pulse_hit_rect.size.y) * 0.30
	var pressed := _pulse_touch >= 0
	draw_circle(center + Vector2(3.0, 5.0), radius + 5.0, Color(0.0, 0.0, 0.0, 0.34))
	if _attack_frame != null:
		var frame_size := Vector2.ONE * (radius + 9.0) * 2.0
		var frame_tint := Color(0.82, 1.0, 0.91, 0.98) if pressed else Color(1.0, 1.0, 1.0, 0.96)
		draw_texture_rect(_attack_frame, _fit_texture_at_center(_attack_frame, center, frame_size), false, frame_tint)
	else:
		draw_circle(center, radius + 3.0, Color("#30191a", 0.92))
		draw_arc(center, radius + 1.0, 0.0, TAU, 56, Color(GOLD if not pressed else JADE, 0.94), 2.5, true)
		draw_arc(center, radius - 5.0, 0.2, 4.5, 44, Color(PAPER, 0.22), 1.0, true)
	var icon_extent := radius * (1.28 if pressed else 1.42)
	var icon_rect := Rect2(center - Vector2.ONE * icon_extent * 0.5, Vector2.ONE * icon_extent)
	draw_texture_rect(PULSE_TEXTURE, icon_rect, false, Color(1.0, 1.0, 1.0, 0.78 if pressed else 0.94))
	var label_size := maxi(15, int(round(16.0 * _device_pixel_scale * clampf((_pulse_hit_rect.size.y / _device_pixel_scale) / PULSE_TARGET_SIZE, 0.8, 1.15))))
	var label_width := _pulse_hit_rect.size.x
	var label_position := Vector2(_pulse_hit_rect.position.x, _pulse_hit_rect.end.y - 4.0)
	draw_string(ACTION_FONT, label_position, "KIẾM", HORIZONTAL_ALIGNMENT_CENTER, label_width, label_size, PAPER)


func _fit_texture_at_center(texture_value: Texture2D, center: Vector2, maximum_size: Vector2) -> Rect2:
	if texture_value == null:
		return Rect2(center - maximum_size * 0.5, maximum_size)
	var source := Vector2(texture_value.get_size())
	if source.x <= 1.0 or source.y <= 1.0:
		return Rect2(center - maximum_size * 0.5, maximum_size)
	var scale_value := minf(maximum_size.x / source.x, maximum_size.y / source.y)
	var fitted := source * scale_value
	return Rect2(center - fitted * 0.5, fitted)


func _draw_pause_button() -> void:
	var center := _pause_hit_rect.get_center()
	var radius := minf(_pause_hit_rect.size.x, _pause_hit_rect.size.y) * 0.36
	draw_circle(center + Vector2(2.0, 3.0), radius + 3.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_circle(center, radius + 1.0, Color(INK, 0.82))
	draw_arc(center, radius, 0.0, TAU, 40, Color(GOLD, 0.82), 2.0, true)
	var bar_width := maxf(5.0, radius * 0.18)
	var bar_height := radius * 0.90
	for offset_x: float in [-radius * 0.25, radius * 0.25]:
		draw_rect(
			Rect2(center + Vector2(offset_x - bar_width * 0.5, -bar_height * 0.5), Vector2(bar_width, bar_height)),
			PAPER,
			true
		)
