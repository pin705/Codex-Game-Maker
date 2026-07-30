class_name InkBackground
extends Node2D

# Resource-backed gameplay values are intentionally absent from this presentation layer.

const INK := Color("#10262a")
const DEEP_INK := Color("#071419")
const JADE_DARK := Color("#174f4c")
const JADE := Color("#52c7a5")
const PAPER := Color("#d8d4bd")
const GOLD := Color("#d6aa4c")
const ARENA_ART_PATHS := {
	"van_mong": "res://assets/generated/environments/ARENA-001-cloud-ring/arena-ground-1600x900-v001.webp",
	"huyet_van": "res://assets/generated/environments/STAGE-002-huyet-van-dai/stage-huyet-van-dai-1600x900-v001.webp",
	"thien_mon": "res://assets/generated/environments/STAGE-003-thien-mon-tan-canh/stage-thien-mon-tan-canh-1600x900-v001.webp",
}

var arena_size := Vector2(1600.0, 900.0)
var arena_texture: Texture2D
var stones: Array[Dictionary] = []
var wisps: Array[Dictionary] = []
var time := 0.0
var redraw_clock := 0.0

func _ready() -> void:
	z_index = -100
	_load_arena_art()
	_build_decorations()
	queue_redraw()

func _load_arena_art() -> void:
	var stage_id := "van_mong"
	var meta := get_node_or_null("/root/MetaProfile")
	if meta != null:
		stage_id = str(meta.get("selected_stage"))
	var arena_art_path := str(ARENA_ART_PATHS.get(stage_id, ARENA_ART_PATHS["van_mong"]))
	if not ResourceLoader.exists(arena_art_path):
		return
	var loaded: Variant = load(arena_art_path)
	if loaded is Texture2D:
		arena_texture = loaded as Texture2D

func refresh_selected_stage() -> void:
	arena_texture = null
	_load_arena_art()
	queue_redraw()

func configure(size: Vector2) -> void:
	arena_size = size
	_build_decorations()
	queue_redraw()

func _build_decorations() -> void:
	stones.clear()
	wisps.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 884211
	for index in 28:
		var edge := index % 4
		var point := Vector2.ZERO
		match edge:
			0:
				point = Vector2(rng.randf_range(70.0, arena_size.x - 70.0), rng.randf_range(55.0, 155.0))
			1:
				point = Vector2(rng.randf_range(arena_size.x - 185.0, arena_size.x - 55.0), rng.randf_range(80.0, arena_size.y - 80.0))
			2:
				point = Vector2(rng.randf_range(70.0, arena_size.x - 70.0), rng.randf_range(arena_size.y - 150.0, arena_size.y - 48.0))
			_:
				point = Vector2(rng.randf_range(55.0, 175.0), rng.randf_range(80.0, arena_size.y - 80.0))
		stones.append({
			"position": point,
			"radius": rng.randf_range(12.0, 34.0),
			"rotation": rng.randf_range(-0.6, 0.6),
			"shade": rng.randf_range(0.12, 0.28)
		})
	for index in 18:
		wisps.append({
			"position": Vector2(rng.randf_range(120.0, arena_size.x - 120.0), rng.randf_range(120.0, arena_size.y - 120.0)),
			"phase": rng.randf_range(0.0, TAU),
			"size": rng.randf_range(1.4, 3.8)
		})

func _process(delta: float) -> void:
	var reduced_motion := false
	var meta := get_node_or_null("/root/MetaProfile")
	if meta != null:
		var settings_value: Variant = meta.get("settings")
		if settings_value is Dictionary:
			reduced_motion = bool((settings_value as Dictionary).get("reduced_motion", false))
	if not reduced_motion:
		time += delta
	redraw_clock += delta
	if redraw_clock >= 0.05:
		redraw_clock = 0.0
		queue_redraw()

func _draw() -> void:
	var has_authored_arena := arena_texture != null
	if has_authored_arena:
		var source_region := source_region_for_target(arena_texture.get_size(), arena_size)
		draw_texture_rect_region(arena_texture, Rect2(Vector2.ZERO, arena_size), source_region)
		# A restrained blue-black glaze unifies sprites with the warm paper plate
		# while retaining the authored cliff, cloud and stone detail.
		draw_rect(Rect2(Vector2.ZERO, arena_size), Color(0.025, 0.065, 0.07, 0.13), true)
	else:
		draw_rect(Rect2(Vector2.ZERO, arena_size), DEEP_INK)
		for band in 9:
			var inset := float(band) * 52.0
			var alpha := 0.035 + float(band % 3) * 0.012
			draw_rect(Rect2(inset, inset * 0.45, arena_size.x - inset * 2.0, arena_size.y - inset * 0.9), Color(0.14, 0.34, 0.32, alpha), true)

	# Quiet gameplay rings sit on the plate as ward marks rather than a glowing
	# sci-fi target. The authored image already carries the main central seal.
	draw_circle(arena_size * 0.5, 355.0, Color(0.72, 0.74, 0.64, 0.018 if has_authored_arena else 0.035))
	draw_circle(arena_size * 0.5, 260.0, Color(0.40, 0.72, 0.61, 0.012 if has_authored_arena else 0.025))
	draw_arc(arena_size * 0.5, 356.0, 0.0, TAU, 96, Color(JADE, 0.075 if has_authored_arena else 0.10), 1.5, true)
	draw_arc(arena_size * 0.5, 263.0, 0.0, TAU, 96, Color(GOLD, 0.05 if has_authored_arena else 0.07), 1.2, true)

	if not has_authored_arena:
		# Procedural decoration remains a portable fallback when the optional
		# arena plate is absent from a minimal export.
		var top_mountains := PackedVector2Array([
			Vector2(0.0, 175.0), Vector2(105.0, 88.0), Vector2(190.0, 166.0),
			Vector2(320.0, 52.0), Vector2(465.0, 176.0), Vector2(610.0, 92.0),
			Vector2(750.0, 174.0), Vector2(880.0, 74.0), Vector2(1010.0, 168.0),
			Vector2(1170.0, 48.0), Vector2(1320.0, 164.0), Vector2(1470.0, 82.0),
			Vector2(arena_size.x, 176.0), Vector2(arena_size.x, 0.0), Vector2.ZERO
		])
		draw_colored_polygon(top_mountains, Color(0.03, 0.10, 0.12, 0.68))

		for stone_data: Dictionary in stones:
			var point: Vector2 = stone_data["position"]
			var radius: float = stone_data["radius"]
			var shade: float = stone_data["shade"]
			var rot: float = stone_data["rotation"]
			draw_set_transform(point, rot, Vector2.ONE)
			_draw_ink_ellipse(Vector2.ZERO, Vector2(radius, radius * 0.56), Color(0.18, 0.29, 0.27, shade))
			draw_arc(Vector2.ZERO, radius, PI * 1.1, PI * 1.85, 12, Color(PAPER, shade * 0.38), 1.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Slowly drifting spirit motes.
	for wisp_data: Dictionary in wisps:
		var origin: Vector2 = wisp_data["position"]
		var phase: float = wisp_data["phase"]
		var size: float = wisp_data["size"]
		var drift := Vector2(sin(time * 0.42 + phase) * 22.0, cos(time * 0.31 + phase) * 14.0)
		var shimmer := 0.42 + sin(time * 1.7 + phase) * 0.18
		draw_circle(origin + drift, size * 3.6, Color(JADE, shimmer * 0.08))
		draw_circle(origin + drift, size, Color(PAPER, shimmer))

	# A physical bronze inlay quietly communicates the playable boundary.
	draw_rect(Rect2(28.0, 28.0, arena_size.x - 56.0, arena_size.y - 56.0), Color(GOLD, 0.18 if has_authored_arena else 0.24), false, 2.0)
	for corner in [Vector2(44.0, 44.0), Vector2(arena_size.x - 44.0, 44.0), Vector2(44.0, arena_size.y - 44.0), Vector2(arena_size.x - 44.0, arena_size.y - 44.0)]:
		draw_circle(corner, 6.0, Color(GOLD, 0.75))
		draw_arc(corner, 14.0, 0.0, TAU, 16, Color(GOLD, 0.36), 2.0, true)


func source_region_for_target(texture_size: Vector2, target_size: Vector2) -> Rect2:
	# Center-crop like TextureRect KEEP_ASPECT_COVERED, but directly in the
	# Node2D draw pass so a 16:9 plate never stretches on 18:9–21:9 phones.
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or target_size.x <= 0.0 or target_size.y <= 0.0:
		return Rect2(Vector2.ZERO, texture_size.max(Vector2.ONE))
	var source_aspect := texture_size.x / texture_size.y
	var target_aspect := target_size.x / target_size.y
	if target_aspect > source_aspect:
		var source_height := texture_size.x / target_aspect
		return Rect2(Vector2(0.0, (texture_size.y - source_height) * 0.5), Vector2(texture_size.x, source_height))
	var source_width := texture_size.y * target_aspect
	return Rect2(Vector2((texture_size.x - source_width) * 0.5, 0.0), Vector2(source_width, texture_size.y))

func _draw_ink_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
