class_name MobileSupportLayer
extends Node

## Drop-in integration wrapper. It keeps touch controls synchronized with the
## existing Events lifecycle and isolates the portrait guard on a higher canvas.

signal combat_controls_active_changed(is_active: bool)

@onready var touch_controls: Variant = $TouchLayer/MobileTouchControls
@onready var rotate_overlay: Variant = $OrientationLayer/RotateDeviceOverlay

var _combat_requested := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_controls.set_controls_enabled(false)
	_connect_event_lifecycle()
	rotate_overlay.orientation_block_changed.connect(_on_orientation_block_changed)
	if touch_controls.has_signal("controls_visibility_changed"):
		touch_controls.controls_visibility_changed.connect(_on_controls_visibility_changed)
	if touch_controls.has_signal("layout_changed"):
		touch_controls.layout_changed.connect(_on_touch_layout_changed)
	_apply_controls_state()


func set_combat_active(value: bool) -> void:
	_combat_requested = value
	_apply_controls_state()


func get_touch_controls() -> Control:
	return touch_controls as Control


func get_rotate_overlay() -> Control:
	return rotate_overlay as Control


func set_safe_area_override(value: Rect2) -> void:
	touch_controls.set_safe_area_override(value)
	rotate_overlay.set_safe_area_override(value)
	_sync_hud_touch_layout()


func clear_safe_area_override() -> void:
	touch_controls.clear_safe_area_override()
	rotate_overlay.clear_safe_area_override()
	_sync_hud_touch_layout()


func set_force_mobile_preview(value: bool) -> void:
	touch_controls.set_force_visible_for_test(value)
	_sync_hud_touch_layout()


func _connect_event_lifecycle() -> void:
	if not Events.game_started.is_connected(_on_game_started):
		Events.game_started.connect(_on_game_started)
	if not Events.game_paused.is_connected(_on_game_paused):
		Events.game_paused.connect(_on_game_paused)
	if not Events.game_finished.is_connected(_on_game_finished):
		Events.game_finished.connect(_on_game_finished)
	if not Events.upgrade_options_presented.is_connected(_on_upgrade_options_presented):
		Events.upgrade_options_presented.connect(_on_upgrade_options_presented)
	if not Events.upgrade_selected.is_connected(_on_upgrade_selected):
		Events.upgrade_selected.connect(_on_upgrade_selected)


func _on_game_started() -> void:
	set_combat_active(true)


func _on_game_paused(is_paused: bool) -> void:
	set_combat_active(not is_paused)


func _on_game_finished(_victory: bool, _title: String, _details: String) -> void:
	set_combat_active(false)


func _on_upgrade_options_presented(_options: Array) -> void:
	set_combat_active(false)


func _on_upgrade_selected(_upgrade_id: StringName) -> void:
	set_combat_active(true)


func _on_orientation_block_changed(_is_blocking: bool) -> void:
	_apply_controls_state()


func _on_controls_visibility_changed(_is_visible: bool) -> void:
	_sync_hud_touch_layout()


func _on_touch_layout_changed(_safe_area: Rect2) -> void:
	_sync_hud_touch_layout()


func _apply_controls_state() -> void:
	if touch_controls == null or rotate_overlay == null:
		return
	var should_enable: bool = _combat_requested and not bool(rotate_overlay.is_blocking_portrait())
	var changed: bool = touch_controls.controls_enabled != should_enable
	touch_controls.set_controls_enabled(should_enable)
	_sync_hud_touch_layout()
	if changed:
		combat_controls_active_changed.emit(should_enable)


func _sync_hud_touch_layout() -> void:
	var hud := get_node_or_null("../HUD")
	if hud == null:
		return
	var touch_visible := bool(touch_controls.visible)
	if hud.has_method("set_mobile_safe_area"):
		hud.call("set_mobile_safe_area", touch_controls.get_safe_area_rect(), touch_visible)
	elif hud.has_method("set_touch_layout"):
		hud.call("set_touch_layout", touch_visible)
