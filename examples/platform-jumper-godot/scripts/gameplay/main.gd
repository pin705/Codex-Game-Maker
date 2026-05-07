extends Node2D

const PLAYER_SCENE := preload("res://scenes/gameplay/Player.tscn")

var _player: PlatformPlayer
var _hud_label: Label
var _spawn_position := Vector2(80, 398)
var _coins_collected := 0
var _coins_total := 0
var _deaths := 0
var _level_complete := false
var _elapsed := 0.0

func _ready() -> void:
	_ensure_input_map()
	_build_background()
	_build_level()
	_spawn_player()
	_build_hud()
	_update_hud()


func _process(delta: float) -> void:
	if not _level_complete:
		_elapsed += delta

	if Input.is_action_just_pressed("restart"):
		_restart_level()

	_update_hud()


func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color("#101820")
	background.size = Vector2(1600, 900)
	background.position = Vector2(-200, -140)
	add_child(background)

	for i in range(10):
		var star := Polygon2D.new()
		var x := 70.0 + i * 145.0
		var y := 44.0 + float((i * 37) % 140)
		star.color = Color("#2D4652")
		star.polygon = PackedVector2Array(Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(0, 3))
		star.position = Vector2(x, y)
		add_child(star)


func _build_level() -> void:
	_add_platform("Ground", Vector2(480, 456), Vector2(960, 40))
	_add_platform("StepA", Vector2(210, 368), Vector2(160, 24))
	_add_platform("StepB", Vector2(410, 316), Vector2(132, 24))
	_add_platform("StepC", Vector2(620, 264), Vector2(132, 24))
	_add_platform("HighBridge", Vector2(820, 206), Vector2(180, 24))
	_add_platform("FinalLedge", Vector2(1030, 330), Vector2(210, 24))
	_add_platform("ExitBase", Vector2(1210, 456), Vector2(190, 40))

	_add_hazard(Vector2(324, 430), 38)
	_add_hazard(Vector2(356, 430), 38)
	_add_hazard(Vector2(704, 430), 38)
	_add_hazard(Vector2(736, 430), 38)
	_add_hazard(Vector2(980, 304), 32)

	_add_coin(Vector2(210, 328))
	_add_coin(Vector2(410, 276))
	_add_coin(Vector2(620, 224))
	_add_coin(Vector2(820, 166))
	_add_coin(Vector2(1030, 290))

	_add_goal(Vector2(1210, 392))


func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate() as PlatformPlayer
	add_child(_player)
	_player.reset_to_spawn(_spawn_position)
	_player.died.connect(_on_player_died)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1320
	camera.limit_bottom = 540
	camera.zoom = Vector2(1.0, 1.0)
	_player.add_child(camera)
	camera.make_current()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_hud_label = Label.new()
	_hud_label.position = Vector2(18, 16)
	_hud_label.add_theme_font_size_override("font_size", 22)
	_hud_label.add_theme_color_override("font_color", Color("#FFFFFF"))
	layer.add_child(_hud_label)


func _ensure_input_map() -> void:
	_add_key_to_action(&"ui_left", KEY_A)
	_add_key_to_action(&"ui_right", KEY_D)
	_add_key_to_action(&"ui_accept", KEY_SPACE)
	_add_key_to_action(&"restart", KEY_R)


func _add_key_to_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.physical_keycode == keycode or key_event.keycode == keycode:
				return

	var new_event := InputEventKey.new()
	new_event.physical_keycode = keycode
	InputMap.action_add_event(action, new_event)


func _add_platform(platform_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = center
	add_child(body)

	var visual := Polygon2D.new()
	visual.color = Color("#87E3FF")
	visual.polygon = _rect_polygon(size)
	body.add_child(visual)

	var lip := Polygon2D.new()
	lip.color = Color("#C8F5FF")
	lip.position = Vector2(0, -size.y * 0.5 + 3)
	lip.polygon = _rect_polygon(Vector2(size.x, 6))
	body.add_child(lip)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)


func _add_hazard(center: Vector2, width: float) -> void:
	var hazard := Area2D.new()
	hazard.name = "Spike"
	hazard.position = center
	hazard.body_entered.connect(_on_hazard_body_entered)
	add_child(hazard)

	var visual := Polygon2D.new()
	visual.color = Color("#FF5C7A")
	visual.polygon = PackedVector2Array(
		Vector2(-width * 0.5, 18),
		Vector2(0, -18),
		Vector2(width * 0.5, 18)
	)
	hazard.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := ConvexPolygonShape2D.new()
	shape.points = visual.polygon
	collision.shape = shape
	hazard.add_child(collision)


func _add_coin(center: Vector2) -> void:
	var coin := Area2D.new()
	coin.name = "Crystal"
	coin.position = center
	coin.body_entered.connect(_on_coin_body_entered.bind(coin))
	add_child(coin)
	_coins_total += 1

	var visual := Polygon2D.new()
	visual.color = Color("#F7F06D")
	visual.polygon = PackedVector2Array(Vector2(0, -14), Vector2(12, 0), Vector2(0, 14), Vector2(-12, 0))
	coin.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18
	collision.shape = shape
	coin.add_child(collision)


func _add_goal(center: Vector2) -> void:
	var goal := Area2D.new()
	goal.name = "Beacon"
	goal.position = center
	goal.body_entered.connect(_on_goal_body_entered)
	add_child(goal)

	var pole := Polygon2D.new()
	pole.color = Color("#C8FFE1")
	pole.polygon = _rect_polygon(Vector2(8, 72))
	goal.add_child(pole)

	var flag := Polygon2D.new()
	flag.color = Color("#35D07F")
	flag.position = Vector2(22, -24)
	flag.polygon = PackedVector2Array(Vector2(-18, -18), Vector2(24, -6), Vector2(-18, 8))
	goal.add_child(flag)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(68, 90)
	collision.shape = shape
	goal.add_child(collision)


func _rect_polygon(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array(
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	)


func _on_hazard_body_entered(body: Node2D) -> void:
	if body == _player and not _level_complete:
		_on_player_died()


func _on_coin_body_entered(body: Node2D, coin: Area2D) -> void:
	if body != _player or not coin.visible:
		return

	coin.visible = false
	coin.set_deferred("monitoring", false)
	_coins_collected += 1


func _on_goal_body_entered(body: Node2D) -> void:
	if body == _player and _coins_collected >= _coins_total:
		_level_complete = true
		_player.velocity = Vector2.ZERO


func _on_player_died() -> void:
	_deaths += 1
	_player.reset_to_spawn(_spawn_position)


func _restart_level() -> void:
	get_tree().reload_current_scene()


func _update_hud() -> void:
	if _hud_label == null:
		return

	var seconds := snappedf(_elapsed, 0.1)
	var status := "Reach the green beacon"
	if _coins_collected < _coins_total:
		status = "Collect every crystal"
	elif _level_complete:
		status = "Course clear"

	_hud_label.text = "Crystals %d/%d   Deaths %d   Time %.1f   %s" % [
		_coins_collected,
		_coins_total,
		_deaths,
		seconds,
		status
	]
