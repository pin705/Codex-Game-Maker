class_name TechniquePreview
extends Control

## Live permanent-technique preview built from authored medallion materials.
## Rank still changes the silhouette, layer count and restrained motion, but the
## old procedural circles/blades are no longer the visible component family.

const RITUAL_ATLAS: Texture2D = preload("res://assets/generated/ui/UIKIT-007-ritual-surface-atlas/runtime/atlas-transparent.png")
const ARSENAL_ATLAS: Texture2D = preload("res://assets/generated/ui/UIKIT-006-arsenal-plates/runtime/atlas-transparent.png")

const MEDALLION_REGION := Rect2(1312.0, 788.0, 168.0, 160.0)
const CONSTELLATION_REGION := Rect2(34.0, 262.0, 278.0, 258.0)
const FOCUS_RING_REGION := Rect2(760.0, 1070.0, 150.0, 136.0)
const PINNACLE_RING_REGION := Rect2(462.0, 1064.0, 132.0, 150.0)
const MAX_VISIBLE_RANK := 5

const GOLD := Color("#e3b95e")
const JADE := Color("#63d8b1")
const CYAN := Color("#82d9dd")

var technique_id: StringName = &"sword_damage"
var rank := 0
var max_rank := 5
var icon_texture: Texture2D
var time := 0.0
var reduced_motion := false

var material_root: Control
var focus_ring: TextureRect
var pinnacle_ring: TextureRect
var constellation: TextureRect
var medallion_shadow: TextureRect
var medallion: TextureRect
var center_icon: TextureRect
var satellite_icons: Array[TextureRect] = []
var rank_sockets: Array[TextureRect] = []

var _visual_center := Vector2.ZERO
var _outer_diameter := 0.0
var _satellite_size := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

	material_root = Control.new()
	material_root.name = "V3TechniqueMaterial"
	material_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	material_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(material_root)

	pinnacle_ring = _texture_layer(material_root, "PinnacleRing", _atlas_region(ARSENAL_ATLAS, PINNACLE_RING_REGION))
	focus_ring = _texture_layer(material_root, "FocusRing", _atlas_region(ARSENAL_ATLAS, FOCUS_RING_REGION))
	constellation = _texture_layer(material_root, "FiveRankConstellation", _atlas_region(ARSENAL_ATLAS, CONSTELLATION_REGION))

	for index in MAX_VISIBLE_RANK:
		var satellite := _texture_layer(material_root, "RankGlyph%02d" % (index + 1), null)
		satellite_icons.append(satellite)

	medallion_shadow = _texture_layer(material_root, "MedallionShadow", _atlas_region(RITUAL_ATLAS, MEDALLION_REGION))
	medallion = _texture_layer(material_root, "RitualMedallion", _atlas_region(RITUAL_ATLAS, MEDALLION_REGION))
	center_icon = _texture_layer(material_root, "TechniqueGlyph", null)

	for index in MAX_VISIBLE_RANK:
		# Reuse the transparent medallion at pip scale. Cropping the sockets out
		# of the status plaque would also crop its opaque lacquer field and read
		# as square HTML chips at 10–16 px.
		var socket := _texture_layer(material_root, "RankSeal%02d" % (index + 1), _atlas_region(RITUAL_ATLAS, MEDALLION_REGION))
		rank_sockets.append(socket)


func configure(id: StringName, current_rank: int, rank_cap: int, icon: Texture2D = null) -> TechniquePreview:
	technique_id = id
	rank = clampi(current_rank, 0, maxi(rank_cap, 1))
	max_rank = maxi(rank_cap, 1)
	icon_texture = icon
	if is_inside_tree():
		_sync_reduced_motion()
	_apply_state()
	_layout_material()
	return self


func _ready() -> void:
	_sync_reduced_motion()
	_apply_state()
	_layout_material()
	_apply_motion()


func _process(delta: float) -> void:
	if reduced_motion:
		return
	time = fmod(time + delta, 1000.0)
	_apply_motion()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		_layout_material()
		_apply_motion()


func _apply_state() -> void:
	if medallion == null:
		return
	var power := float(rank) / float(maxi(max_rank, 1))
	var dormant := rank <= 0
	medallion.modulate = Color(0.62, 0.66, 0.64, 0.78) if dormant else Color(1.0, 1.0, 1.0, 0.96)
	medallion_shadow.modulate = Color(0.0, 0.0, 0.0, 0.34 + power * 0.10)
	center_icon.texture = icon_texture
	center_icon.visible = icon_texture != null
	center_icon.modulate = Color(0.58, 0.61, 0.59, 0.66) if dormant else Color(1.0, 1.0, 1.0, 0.96)

	focus_ring.visible = rank >= 1
	focus_ring.modulate = Color(1.0, 1.0, 1.0, 0.24 + power * 0.34)
	constellation.visible = rank >= 2
	constellation.modulate = Color(1.0, 1.0, 1.0, 0.34 + power * 0.34)
	pinnacle_ring.visible = rank >= max_rank and rank > 0
	pinnacle_ring.modulate = Color(1.0, 1.0, 1.0, 0.72)

	for index in satellite_icons.size():
		var satellite := satellite_icons[index]
		satellite.texture = icon_texture
		satellite.visible = icon_texture != null and index < mini(rank, MAX_VISIBLE_RANK)
		satellite.modulate = Color(1.0, 1.0, 1.0, 0.48 + power * 0.34)

	for index in rank_sockets.size():
		var socket := rank_sockets[index]
		socket.visible = index < mini(max_rank, MAX_VISIBLE_RANK)
		var lit := index < rank
		socket.modulate = Color(1.0, 1.0, 1.0, 0.98) if lit else Color(0.38, 0.41, 0.39, 0.34)
		socket.scale = Vector2.ONE * (1.10 if lit else 0.88)


func _layout_material() -> void:
	if material_root == null or size.x < 24.0 or size.y < 24.0:
		return
	var short_side := minf(size.x, size.y)
	_visual_center = size * 0.5 - Vector2(0.0, short_side * 0.035)
	var medallion_diameter := clampf(short_side * 0.56, 46.0, 232.0)
	_outer_diameter = clampf(short_side * 0.88, 70.0, 360.0)
	_satellite_size = clampf(_outer_diameter * 0.135, 12.0, 46.0)

	_set_square(medallion_shadow, _visual_center + Vector2(short_side * 0.018, short_side * 0.025), medallion_diameter * 1.04)
	_set_square(medallion, _visual_center, medallion_diameter)
	_set_square(center_icon, _visual_center, medallion_diameter * 0.42)
	_set_square(constellation, _visual_center, _outer_diameter)
	_set_square(focus_ring, _visual_center, _outer_diameter * 0.86)
	_set_square(pinnacle_ring, _visual_center, _outer_diameter * 1.02)

	_layout_satellites(0.0)
	var socket_size := clampf(short_side * 0.043, 7.0, 17.0)
	var socket_gap := clampf(short_side * 0.010, 2.0, 5.0)
	var visible_sockets := mini(max_rank, MAX_VISIBLE_RANK)
	var row_width := float(visible_sockets) * socket_size + float(maxi(visible_sockets - 1, 0)) * socket_gap
	var socket_y := minf(size.y - socket_size, _visual_center.y + medallion_diameter * 0.58)
	for index in rank_sockets.size():
		var socket := rank_sockets[index]
		socket.position = Vector2(_visual_center.x - row_width * 0.5 + float(index) * (socket_size + socket_gap), socket_y)
		socket.size = Vector2.ONE * socket_size
		socket.pivot_offset = Vector2.ONE * socket_size * 0.5


func _apply_motion() -> void:
	if focus_ring == null or _outer_diameter <= 0.0:
		return
	var power := float(rank) / float(maxi(max_rank, 1))
	var phase := 0.0 if reduced_motion else time
	focus_ring.rotation = phase * (0.10 + power * 0.06)
	constellation.rotation = -phase * (0.025 + power * 0.018)
	pinnacle_ring.rotation = phase * 0.14
	var pulse := 1.0 if reduced_motion else 1.0 + sin(phase * 1.45) * 0.012 * power
	constellation.scale = Vector2.ONE * pulse
	center_icon.scale = Vector2.ONE * (1.0 if reduced_motion else 1.0 + sin(phase * 1.8) * 0.018 * power)
	_layout_satellites(0.0 if reduced_motion else phase * (0.08 + power * 0.06))


func _layout_satellites(orbit_phase: float) -> void:
	if satellite_icons.is_empty() or _outer_diameter <= 0.0:
		return
	var orbit_radius := _outer_diameter * 0.345
	for index in satellite_icons.size():
		var angle := -PI * 0.5 + TAU * float(index) / float(MAX_VISIBLE_RANK) + orbit_phase
		var center := _visual_center + Vector2.from_angle(angle) * orbit_radius
		var satellite := satellite_icons[index]
		satellite.position = center - Vector2.ONE * _satellite_size * 0.5
		satellite.size = Vector2.ONE * _satellite_size
		satellite.pivot_offset = Vector2.ONE * _satellite_size * 0.5
		satellite.rotation = angle + PI * 0.5


func _set_square(control: Control, center: Vector2, diameter: float) -> void:
	control.position = center - Vector2.ONE * diameter * 0.5
	control.size = Vector2.ONE * diameter
	control.pivot_offset = Vector2.ONE * diameter * 0.5


func _texture_layer(parent: Control, layer_name: String, texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.custom_minimum_size = Vector2.ZERO
	parent.add_child(layer)
	return layer


func _atlas_region(atlas: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	return texture


func _accent() -> Color:
	match technique_id:
		&"vitality":
			return JADE
		&"magnet":
			return CYAN
	return GOLD


func _sync_reduced_motion() -> void:
	var profile := get_node_or_null("/root/MetaProfile")
	if profile != null:
		var settings_value: Variant = profile.get("settings")
		if settings_value is Dictionary:
			reduced_motion = bool((settings_value as Dictionary).get("reduced_motion", false))
	set_process(not reduced_motion)
	if reduced_motion:
		time = 0.0
