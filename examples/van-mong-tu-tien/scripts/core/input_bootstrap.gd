class_name InputBootstrap
extends RefCounted

const ACTION_KEYS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"qi_pulse": [KEY_SPACE],
	&"pause_game": [KEY_P],
	&"restart_game": [KEY_R],
	&"confirm": [KEY_ENTER, KEY_KP_ENTER],
	&"upgrade_1": [KEY_1],
	&"upgrade_2": [KEY_2],
	&"upgrade_3": [KEY_3]
}

const ACTION_JOY_BUTTONS := {
	&"qi_pulse": [JOY_BUTTON_A],
	&"pause_game": [JOY_BUTTON_START],
	&"restart_game": [JOY_BUTTON_Y],
	&"confirm": [JOY_BUTTON_A],
}

const ACTION_JOY_MOTIONS := {
	&"move_left": [[JOY_AXIS_LEFT_X, -1.0]],
	&"move_right": [[JOY_AXIS_LEFT_X, 1.0]],
	&"move_up": [[JOY_AXIS_LEFT_Y, -1.0]],
	&"move_down": [[JOY_AXIS_LEFT_Y, 1.0]],
}

static func ensure_actions() -> void:
	for action in ACTION_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var keys: Array = ACTION_KEYS[action]
		for key_value in keys:
			_add_key_if_missing(action, key_value)
	for action in ACTION_JOY_BUTTONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for button_value: JoyButton in ACTION_JOY_BUTTONS[action]:
			_add_joy_button_if_missing(action, button_value)
	for action in ACTION_JOY_MOTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for motion: Array in ACTION_JOY_MOTIONS[action]:
			_add_joy_motion_if_missing(action, motion[0] as JoyAxis, float(motion[1]))

static func _add_key_if_missing(action: StringName, key_value: Key) -> void:
	for existing: InputEvent in InputMap.action_get_events(action):
		if existing is InputEventKey:
			var existing_key := existing as InputEventKey
			if existing_key.keycode == key_value or existing_key.physical_keycode == key_value:
				return
	var event := InputEventKey.new()
	event.keycode = key_value
	InputMap.action_add_event(action, event)

static func _add_joy_button_if_missing(action: StringName, button_value: JoyButton) -> void:
	for existing: InputEvent in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and (existing as InputEventJoypadButton).button_index == button_value:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button_value
	InputMap.action_add_event(action, event)

static func _add_joy_motion_if_missing(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	for existing: InputEvent in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion:
			var motion := existing as InputEventJoypadMotion
			if motion.axis == axis and signf(motion.axis_value) == signf(axis_value):
				return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
