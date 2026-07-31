class_name SpiritBeastCompanion
extends Node2D

## A non-blocking combat companion. The beast contributes one readable active
## assist every few seconds and a soft jade mark, while the player remains the
## only collision/movement authority.

signal assist_cast(target: CultivationEnemy, damage: float, origin: Vector2)

const PORTRAIT_PATH := "res://assets/generated/portraits/PORTRAIT-001-bestiary-companion-atlas/runtime/thanh_van_ho.png"
const JADE := Color("#63dfb4")
const GOLD := Color("#efd07a")
const INK := Color("#0c2021")

var player: CultivatorPlayer
var enemy_root: Node2D
var enabled := false
var cooldown_remaining := 2.8
var cooldown_duration := 6.0
var damage := 34.0
var elapsed := 0.0
var visual_sprite: Sprite2D
var last_target: CultivationEnemy

func setup(owner: CultivatorPlayer, enemies: Node2D, config: Dictionary = {}) -> void:
	player = owner
	enemy_root = enemies
	cooldown_duration = float(config.get("cooldown", cooldown_duration))
	damage = float(config.get("damage", damage))
	global_position = player.global_position + Vector2(54.0, 28.0)
	_set_sprite()
	queue_redraw()

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	if not value:
		last_target = null

func _process(delta: float) -> void:
	if not enabled or not is_instance_valid(player) or not player.enabled:
		return
	elapsed += delta
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	var offset := Vector2(52.0, 34.0).rotated(sin(elapsed * 0.7) * 0.12)
	var desired := player.global_position + offset
	global_position = global_position.lerp(desired, 1.0 - exp(-7.5 * delta))
	last_target = _highest_threat_target()
	if cooldown_remaining <= 0.0 and last_target != null:
		cooldown_remaining = cooldown_duration
		assist_cast.emit(last_target, damage, global_position)
	queue_redraw()

func _highest_threat_target() -> CultivationEnemy:
	if enemy_root == null:
		return null
	var best: CultivationEnemy = null
	var best_score := -INF
	for node in enemy_root.get_children():
		var enemy := node as CultivationEnemy
		if enemy == null or enemy.dying:
			continue
		var score := (100000.0 if enemy.boss else (5000.0 if enemy.elite else 0.0)) - global_position.distance_squared_to(enemy.global_position)
		if score > best_score:
			best_score = score
			best = enemy
	return best

func cooldown_ratio() -> float:
	return 1.0 - cooldown_remaining / maxf(cooldown_duration, 0.01)

func _set_sprite() -> void:
	if visual_sprite != null:
		return
	if not ResourceLoader.exists(PORTRAIT_PATH):
		return
	var loaded: Variant = load(PORTRAIT_PATH)
	if loaded is not Texture2D:
		return
	visual_sprite = Sprite2D.new()
	visual_sprite.texture = loaded as Texture2D
	visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual_sprite.centered = true
	visual_sprite.scale = Vector2.ONE * 0.16
	visual_sprite.position = Vector2(0.0, -20.0)
	add_child(visual_sprite)

func _draw() -> void:
	var pulse := 0.82 + sin(elapsed * 2.5) * 0.12
	# Low, uneven ink grounding keeps the portrait from floating over the arena.
	var shadow := PackedVector2Array([Vector2(-23.0, 10.0), Vector2(-14.0, 5.0), Vector2(2.0, 4.0), Vector2(24.0, 9.0), Vector2(15.0, 14.0), Vector2(-11.0, 14.0)])
	draw_colored_polygon(shadow, Color(0.01, 0.035, 0.035, 0.30))
	draw_arc(Vector2.ZERO, 22.0, PI * 0.1, PI * 0.9, 12, Color(JADE, 0.25), 2.0, true)
	if visual_sprite == null:
		var body := PackedVector2Array([Vector2(0.0, -25.0), Vector2(15.0, -8.0), Vector2(20.0, 9.0), Vector2(0.0, 5.0), Vector2(-20.0, 9.0), Vector2(-15.0, -8.0)])
		draw_colored_polygon(body, Color(INK, 0.94))
		draw_polyline(body, Color(JADE, 0.72), 2.0, true)
	if last_target != null and cooldown_remaining <= 0.0:
		var aim := global_position.direction_to(last_target.global_position)
		for segment in 3:
			var start := aim * (30.0 + float(segment) * 8.0)
			var finish := aim * (45.0 + float(segment) * 8.0)
			draw_line(start, finish, Color(GOLD, (0.40 - segment * 0.08) * pulse), 2.0, true)
