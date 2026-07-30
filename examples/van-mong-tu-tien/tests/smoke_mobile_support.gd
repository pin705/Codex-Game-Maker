extends Node

const ControlsScene := preload("res://scenes/ui/mobile_touch_controls.tscn")
const RotateScene := preload("res://scenes/ui/rotate_device_overlay.tscn")
const SupportScene := preload("res://scenes/ui/mobile_support_layer.tscn")

var failures: Array[String] = []
var pulse_presses := 0
var pulse_releases := 0
var pause_presses := 0
var dispatched_pulse_presses := 0
var dispatched_pause_presses := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var controls: Variant = ControlsScene.instantiate()
	get_tree().root.add_child(controls)
	controls.set_force_visible_for_test(true)
	controls.set_viewport_size_override(Vector2(1600.0, 900.0))
	controls.set_safe_area_override(Rect2(34.0, 22.0, 1532.0, 856.0))
	controls.pulse_pressed.connect(func() -> void: pulse_presses += 1)
	controls.pulse_released.connect(func() -> void: pulse_releases += 1)
	controls.pause_requested.connect(func() -> void: pause_presses += 1)
	await get_tree().process_frame

	var safe: Rect2 = controls.get_safe_area_rect()
	var joystick_rect: Rect2 = controls.get_joystick_hit_rect()
	var pulse_rect: Rect2 = controls.get_pulse_hit_rect()
	var pause_rect: Rect2 = controls.get_pause_hit_rect()
	_expect(safe.encloses(joystick_rect), "joystick stays inside title/device safe area")
	_expect(safe.encloses(pulse_rect), "pulse stays inside title/device safe area")
	_expect(safe.encloses(pause_rect), "pause stays inside title/device safe area")
	_expect(joystick_rect.size.x >= 64.0 and joystick_rect.size.y >= 64.0, "joystick target is at least 64x64")
	_expect(pulse_rect.size.x >= 64.0 and pulse_rect.size.y >= 64.0, "pulse target is at least 64x64")
	_expect(pause_rect.size.x >= 64.0 and pause_rect.size.y >= 64.0, "pause target is at least 64x64")
	_expect(pause_rect.get_center().x > safe.get_center().x, "pause remains in the upper-right reach zone instead of blocking center sightline")
	_expect(not pause_rect.intersects(pulse_rect), "pause and pulse targets never overlap")

	var joystick_center: Vector2 = controls.get_joystick_center()
	_press(controls, 3, joystick_center + Vector2(80.0, -40.0))
	_expect(controls.movement_vector.x > 0.55 and controls.movement_vector.y < -0.20, "touch direction resolves up-right")
	_expect(Input.get_action_strength(&"move_right") > 0.5, "joystick mirrors move_right InputMap strength")
	_expect(Input.get_action_strength(&"move_up") > 0.15, "joystick mirrors move_up InputMap strength")

	# A second finger activates the skill without stealing the movement finger.
	_press(controls, 9, pulse_rect.get_center())
	await get_tree().process_frame
	_expect(pulse_presses == 1, "second touch presses pulse exactly once")
	_expect(Input.is_action_pressed(&"qi_pulse"), "pulse mirrors qi_pulse InputMap state")
	_expect(dispatched_pulse_presses == 1, "pulse dispatch reaches existing _unhandled_input consumers")
	_expect(controls.movement_vector.length() > 0.5, "pulse multi-touch preserves joystick direction")
	_drag(controls, 3, joystick_center + Vector2(-120.0, 0.0))
	_expect(controls.movement_vector.x < -0.90, "drag updates joystick direction deterministically")
	_release(controls, 9, pulse_rect.get_center())
	_expect(pulse_releases == 1 and not Input.is_action_pressed(&"qi_pulse"), "pulse release clears action exactly once")
	_release(controls, 3, joystick_center)
	_expect(controls.movement_vector.is_zero_approx(), "joystick release returns to neutral")
	_expect(not Input.is_action_pressed(&"move_left") and not Input.is_action_pressed(&"move_right"), "movement actions clear on release")

	_press(controls, 12, pause_rect.get_center())
	await get_tree().process_frame
	_expect(pause_presses == 1, "pause target dispatches once")
	_expect(dispatched_pause_presses == 1, "pause dispatch reaches existing _unhandled_input consumers")
	_expect(not Input.is_action_pressed(&"pause_game"), "pause action auto-releases after dispatch")

	# Phone-size landscape simulation verifies the minimum target after the
	# adaptive scale clamps, not only on the 1600x900 authoring canvas.
	controls.set_viewport_size_override(Vector2(844.0, 390.0))
	controls.set_safe_area_override(Rect2(44.0, 10.0, 756.0, 370.0))
	controls.refresh_mobile_layout()
	safe = controls.get_safe_area_rect()
	joystick_rect = controls.get_joystick_hit_rect()
	pulse_rect = controls.get_pulse_hit_rect()
	pause_rect = controls.get_pause_hit_rect()
	_expect(joystick_rect.size.x >= 64.0 and pulse_rect.size.x >= 64.0 and pause_rect.size.x >= 64.0, "phone landscape preserves every 64 px touch target")
	var phone_safe_tolerance := safe.grow(0.5)
	_expect(phone_safe_tolerance.encloses(joystick_rect) and phone_safe_tolerance.encloses(pulse_rect) and phone_safe_tolerance.encloses(pause_rect), "phone landscape keeps all controls inside notch-safe bounds")
	_expect(not joystick_rect.intersects(pulse_rect) and not pause_rect.intersects(pulse_rect), "phone landscape touch zones remain disjoint")

	# Re-layout against a strongly asymmetric notch/cutout safe area.
	controls.set_viewport_size_override(Vector2(1600.0, 900.0))
	controls.set_safe_area_override(Rect2(118.0, 42.0, 1380.0, 806.0))
	controls.refresh_mobile_layout()
	safe = controls.get_safe_area_rect()
	_expect(safe.encloses(controls.get_joystick_hit_rect()), "joystick survives asymmetric safe-area relayout")
	_expect(safe.encloses(controls.get_pulse_hit_rect()), "pulse survives asymmetric safe-area relayout")
	_expect(safe.encloses(controls.get_pause_hit_rect()), "pause survives asymmetric safe-area relayout")

	var rotate: Variant = RotateScene.instantiate()
	get_tree().root.add_child(rotate)
	rotate.set_viewport_size_override(Vector2(1600.0, 900.0))
	rotate.set_orientation_size_override(Vector2(900.0, 1600.0))
	rotate.set_safe_area_override(Rect2(42.0, 26.0, 1516.0, 848.0))
	await get_tree().process_frame
	_expect(rotate.is_blocking_portrait() and rotate.visible, "portrait device orientation shows rotate-device overlay")
	_expect(rotate.get_safe_area_rect().encloses(rotate.get_message_rect()), "rotate message stays inside safe area")
	rotate.set_viewport_size_override(Vector2(900.0, 1600.0))
	rotate.set_safe_area_override(Rect2(44.0, 82.0, 812.0, 1432.0))
	rotate.refresh_orientation()
	var portrait_message: Rect2 = rotate.get_message_rect()
	_expect(portrait_message.get_center().distance_to(rotate.get_safe_area_rect().get_center()) < 1.0, "real portrait message is centered in the 900x1600 safe composition")
	_expect(rotate.get_safe_area_rect().encloses(portrait_message), "real portrait message remains inside notch and home-indicator safe area")
	rotate.set_viewport_size_override(Vector2(1600.0, 900.0))
	rotate.set_orientation_size_override(Vector2(1600.0, 900.0))
	rotate.set_safe_area_override(Rect2(40.0, 24.0, 1520.0, 852.0))
	_expect(not rotate.refresh_orientation() and not rotate.visible, "landscape device orientation hides rotate-device overlay")

	controls.release_all_inputs()
	controls.queue_free()
	rotate.queue_free()
	await get_tree().process_frame

	var support: Variant = SupportScene.instantiate()
	get_tree().root.add_child(support)
	var integrated_controls: Variant = support.get_touch_controls()
	var integrated_rotate: Variant = support.get_rotate_overlay()
	integrated_controls.set_force_visible_for_test(true)
	integrated_controls.set_viewport_size_override(Vector2(1600.0, 900.0))
	integrated_rotate.set_viewport_size_override(Vector2(1600.0, 900.0))
	_expect(not integrated_controls.controls_enabled, "drop-in layer starts with combat controls disabled")
	Events.game_started.emit()
	_expect(integrated_controls.controls_enabled, "game_started enables drop-in combat controls")
	Events.game_paused.emit(true)
	_expect(not integrated_controls.controls_enabled, "pause lifecycle disables drop-in combat controls")
	Events.game_paused.emit(false)
	_expect(integrated_controls.controls_enabled, "resume lifecycle restores drop-in combat controls")
	var empty_upgrade_options: Array[Dictionary] = []
	Events.upgrade_options_presented.emit(empty_upgrade_options)
	_expect(not integrated_controls.controls_enabled, "breakthrough modal disables drop-in combat controls")
	Events.upgrade_selected.emit(&"sword_damage")
	_expect(integrated_controls.controls_enabled, "upgrade selection restores drop-in combat controls")
	integrated_rotate.set_orientation_size_override(Vector2(900.0, 1600.0))
	integrated_rotate.refresh_orientation()
	_expect(not integrated_controls.controls_enabled, "portrait guard prevents touches reaching combat")
	Events.game_finished.emit(true, "", "")
	_expect(not integrated_controls.controls_enabled, "game result leaves drop-in controls disabled")
	support.queue_free()
	await get_tree().process_frame
	_quit_with_report()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"qi_pulse"):
		dispatched_pulse_presses += 1
	elif event.is_action_pressed(&"pause_game"):
		dispatched_pause_presses += 1


func _press(controls: Variant, index: int, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = true
	controls.handle_touch_event(event)


func _drag(controls: Variant, index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	controls.handle_touch_event(event)


func _release(controls: Variant, index: int, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = false
	controls.handle_touch_event(event)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		print("FAIL: ", label)


func _quit_with_report() -> void:
	if failures.is_empty():
		print("MOBILE SUPPORT RESULT: PASS")
		get_tree().quit(0)
	else:
		print("MOBILE SUPPORT RESULT: FAIL (", failures.size(), " failures)")
		get_tree().quit(1)
