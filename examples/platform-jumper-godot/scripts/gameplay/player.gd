extends CharacterBody2D
class_name PlatformPlayer

signal died

@export var tuning: MovementTuning = preload("res://resources/tuning/player_movement.tres")

var _spawn_position: Vector2
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _air_jumps_used: int = 0

func _ready() -> void:
	_spawn_position = global_position


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	var horizontal_axis := Input.get_axis("ui_left", "ui_right")
	var target_velocity_x := horizontal_axis * tuning.max_speed
	var acceleration := tuning.ground_acceleration if was_on_floor else tuning.air_acceleration

	velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
	if is_zero_approx(horizontal_axis) and was_on_floor:
		velocity.x = move_toward(velocity.x, 0.0, tuning.ground_friction * delta)

	if was_on_floor:
		_coyote_timer = tuning.coyote_time
		_air_jumps_used = 0
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
		velocity.y += tuning.gravity * delta

	if Input.is_action_just_pressed("ui_accept"):
		_jump_buffer_timer = tuning.jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0 and _can_jump(was_on_floor):
		_jump()

	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= tuning.jump_cut_multiplier

	move_and_slide()

	if global_position.y > 760.0:
		died.emit()


func reset_to_spawn(spawn_position: Vector2) -> void:
	_spawn_position = spawn_position
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_air_jumps_used = 0


func _can_jump(was_on_floor: bool) -> bool:
	if was_on_floor or _coyote_timer > 0.0:
		return true
	return _air_jumps_used < tuning.extra_jumps


func _jump() -> void:
	if not is_on_floor() and _coyote_timer <= 0.0:
		_air_jumps_used += 1

	velocity.y = tuning.jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
