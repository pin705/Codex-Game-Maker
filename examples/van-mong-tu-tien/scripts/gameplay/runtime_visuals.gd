class_name RuntimeVisuals
extends RefCounted

## Optional sprite bridge for accepted runtime art.
##
## Gameplay never depends on these files: if a role has no imported texture,
## callers keep their procedural CanvasItem drawing. Filename matching accepts
## both the short contract names (player_idle.png) and versioned exports such
## as PLAYER-IDLE-v001.webp.

const RUNTIME_ROOT := "res://assets/generated/runtime"
const IMAGE_EXTENSIONS := ["png", "webp", "jpg", "jpeg"]
const ROLE_TOKENS := {
	&"player_idle": ["player", "idle"],
	&"player_move": ["player", "move"],
	&"enemy_wisp": ["enemy", "wisp"],
	&"enemy_beast": ["enemy", "beast"],
	&"enemy_demon": ["enemy", "demon"],
	&"enemy_elite": ["enemy", "elite"],
	&"enemy_boss": ["enemy", "boss"],
	&"projectile_sword": ["projectile", "sword"],
	&"projectile_phoenix": ["projectile", "phoenix"],
	&"qi_orb": ["qi", "orb"],
	&"effect_ring": ["effect", "ring"],
	&"effect_burst": ["effect", "burst"],
	&"effect_hit": ["effect", "hit"],
	&"effect_portal": ["effect", "portal"]
}

static var _texture_cache: Dictionary = {}
static var _frame_cache: Dictionary = {}

static func prime_texture(role: StringName, texture: Texture2D) -> void:
	# Useful for deterministic tests and for future asset-bundle preloading.
	_texture_cache[role] = texture

static func clear_cache() -> void:
	_texture_cache.clear()
	_frame_cache.clear()

static func get_animation_frames(role: StringName) -> Array:
	if _frame_cache.has(role):
		return _frame_cache[role]
	var frames: Array = []
	var directory_path := "%s/%s_frames" % [RUNTIME_ROOT, String(role)]
	var directory := DirAccess.open(directory_path)
	if directory != null:
		var files := directory.get_files()
		files.sort()
		for filename: String in files:
			var lower := filename.to_lower()
			if not lower.ends_with(".png") and not lower.ends_with(".webp"):
				continue
			var loaded: Variant = load("%s/%s" % [directory_path, filename])
			if loaded is Texture2D:
				frames.append(loaded as Texture2D)
	_frame_cache[role] = frames
	return frames

static func get_texture(role: StringName) -> Texture2D:
	if _texture_cache.has(role):
		return _texture_cache[role] as Texture2D
	var resolved := _resolve_path(role)
	var texture: Texture2D = null
	if not resolved.is_empty():
		var loaded: Variant = load(resolved)
		if loaded is Texture2D:
			texture = loaded as Texture2D
	_texture_cache[role] = texture
	return texture

static func attach(parent: Node2D, role: StringName, target_height: float, offset := Vector2.ZERO) -> Sprite2D:
	var texture := get_texture(role)
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = "RuntimeSprite_%s" % String(role)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = offset
	sprite.z_index = 1
	# Character art is authored with a feet/bottom pivot. Cropping the accepted
	# frames to their alpha bounds keeps runtime scale honest; the offset below
	# then puts the visible feet on the gameplay node instead of making the
	# transparent source canvas dictate the collision position. Projectiles,
	# pickups and FX remain center-pivoted.
	sprite.centered = not _is_bottom_anchored(role)
	parent.add_child(sprite)
	configure(sprite, texture, target_height)
	return sprite

static func configure(sprite: Sprite2D, texture: Texture2D, target_height: float) -> void:
	if sprite == null or texture == null:
		return
	sprite.texture = texture
	var source_size := texture.get_size()
	var source_height := maxf(source_size.y, 1.0)
	var uniform_scale := maxf(target_height, 1.0) / source_height
	sprite.scale = Vector2.ONE * uniform_scale
	if not sprite.centered:
		# Sprite2D offsets are expressed in source pixels and are scaled with the
		# texture, so this aligns the source bottom-center with the parent origin.
		sprite.offset = Vector2(-source_size.x * 0.5, -source_size.y)

static func swap(sprite: Sprite2D, role: StringName, target_height: float) -> bool:
	if sprite == null:
		return false
	var texture := get_texture(role)
	if texture == null:
		return false
	configure(sprite, texture, target_height)
	return true

static func _resolve_path(role: StringName) -> String:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(RUNTIME_ROOT)):
		return ""
	var direct_names: Array[String] = [String(role)]
	for extension: String in IMAGE_EXTENSIONS:
		direct_names.append("%s.%s" % [String(role), extension])
		direct_names.append("%s-v001.%s" % [String(role), extension])
	for filename: String in direct_names:
		var direct_path := "%s/%s" % [RUNTIME_ROOT, filename]
		if ResourceLoader.exists(direct_path):
			return direct_path

	var tokens: Array = ROLE_TOKENS.get(role, [String(role)])
	return _scan_directory(RUNTIME_ROOT, tokens)

static func _is_bottom_anchored(role: StringName) -> bool:
	var name := String(role)
	return name.begins_with("player_") or name.begins_with("enemy_")

static func _scan_directory(directory_path: String, tokens: Array) -> String:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return ""
	var files: PackedStringArray = directory.get_files()
	files.sort()
	for filename: String in files:
		var lower_name := filename.to_lower()
		var is_image := false
		for extension: String in IMAGE_EXTENSIONS:
			if lower_name.ends_with(".%s" % extension):
				is_image = true
				break
		if not is_image:
			continue
		var normalized := lower_name.replace("-", "_").replace(" ", "_")
		var matches := true
		for token: String in tokens:
			if normalized.find(token.to_lower()) < 0:
				matches = false
				break
		if matches:
			return "%s/%s" % [directory_path, filename]
	var subdirectories: PackedStringArray = directory.get_directories()
	subdirectories.sort()
	for subdirectory: String in subdirectories:
		var nested_match := _scan_directory("%s/%s" % [directory_path, subdirectory], tokens)
		if not nested_match.is_empty():
			return nested_match
	return ""
