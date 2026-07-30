class_name CultivationMeter
extends ProgressBar

## Dynamic meter state presented through authored UIKIT-007 hardware.
## The empty bronze channel, material grain and current-edge seal are atlas
## regions; only fill width and tint are runtime state.

const RITUAL_ATLAS: Texture2D = preload("res://assets/generated/ui/UIKIT-007-ritual-surface-atlas/runtime/atlas-transparent.png")
const TRACK_REGION := Rect2(1244.0, 142.0, 240.0, 30.0)
const CYAN_MATERIAL_REGION := Rect2(1244.0, 111.0, 240.0, 30.0)
const EDGE_SEAL_REGION := Rect2(1312.0, 788.0, 168.0, 160.0)

const MATERIAL_SHADER := """
shader_type canvas_item;

uniform vec4 meter_tint : source_color = vec4(0.34, 0.82, 0.65, 1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float cyan = smoothstep(0.04, 0.24, min(source.g, source.b) - source.r);
	float value = dot(source.rgb, vec3(0.24, 0.62, 0.14));
	vec3 brushed = meter_tint.rgb * mix(0.52, 1.22, value);
	COLOR = vec4(brushed, source.a * cyan * meter_tint.a);
}
"""

var meter_color := Color("#57d2a7")
var track_color := Color("#061113")
var edge_color := Color("#d8cba4")
var meter_seed := 1

var authored_track: NinePatchRect
var fill_clip: Control
var fill_gradient: TextureRect
var fill_grain: TextureRect
var edge_seal: TextureRect
var tick_marks: Array[ColorRect] = []
var _gradient := Gradient.new()
var _gradient_texture := GradientTexture1D.new()
var _grain_material := ShaderMaterial.new()


func _init() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	for state in [&"background", &"fill"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())

	authored_track = NinePatchRect.new()
	authored_track.name = "V3MeterChannel"
	authored_track.texture = _atlas_region(TRACK_REGION)
	authored_track.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	authored_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	authored_track.draw_center = true
	authored_track.set_patch_margin(SIDE_LEFT, 18)
	authored_track.set_patch_margin(SIDE_TOP, 10)
	authored_track.set_patch_margin(SIDE_RIGHT, 18)
	authored_track.set_patch_margin(SIDE_BOTTOM, 10)
	add_child(authored_track)

	fill_clip = Control.new()
	fill_clip.name = "DynamicFillClip"
	fill_clip.clip_contents = true
	fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill_clip)

	_gradient_texture.gradient = _gradient
	_gradient_texture.width = 256
	fill_gradient = TextureRect.new()
	fill_gradient.name = "MaterialUnderpaint"
	fill_gradient.texture = _gradient_texture
	fill_gradient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill_gradient.stretch_mode = TextureRect.STRETCH_SCALE
	fill_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_clip.add_child(fill_gradient)

	var grain_shader := Shader.new()
	grain_shader.code = MATERIAL_SHADER
	_grain_material.shader = grain_shader
	fill_grain = TextureRect.new()
	fill_grain.name = "AuthoredMaterialGrain"
	fill_grain.texture = _atlas_region(CYAN_MATERIAL_REGION)
	fill_grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill_grain.stretch_mode = TextureRect.STRETCH_SCALE
	fill_grain.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fill_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_grain.material = _grain_material
	fill_clip.add_child(fill_grain)

	for index in range(1, 5):
		var tick := ColorRect.new()
		tick.name = "EtchedDivision%02d" % index
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick_marks.append(tick)
		add_child(tick)

	edge_seal = TextureRect.new()
	edge_seal.name = "CurrentEdgeSeal"
	edge_seal.texture = _atlas_region(EDGE_SEAL_REGION)
	edge_seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	edge_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	edge_seal.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	edge_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge_seal)

	changed.connect(_refresh_meter)
	value_changed.connect(func(_new_value: float) -> void: _refresh_meter())
	_update_fill_material()


func configure(fill: Color, maximum_value: float, seed: int = 1) -> CultivationMeter:
	meter_color = fill
	meter_seed = seed
	max_value = maximum_value
	value = maximum_value
	_update_fill_material()
	_refresh_meter()
	return self


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		_refresh_meter()


func _refresh_meter() -> void:
	if authored_track == null or size.x < 8.0 or size.y < 4.0:
		return
	var channel_height := minf(size.y, 18.0)
	var channel_y := (size.y - channel_height) * 0.5
	authored_track.position = Vector2(0.0, channel_y)
	authored_track.size = Vector2(size.x, channel_height)
	authored_track.modulate = Color(1.0, 1.0, 1.0, 0.96)
	authored_track.set_patch_margin(SIDE_LEFT, int(round(minf(18.0, size.x * 0.22))))
	authored_track.set_patch_margin(SIDE_RIGHT, int(round(minf(18.0, size.x * 0.22))))
	authored_track.set_patch_margin(SIDE_TOP, int(round(minf(10.0, channel_height * 0.42))))
	authored_track.set_patch_margin(SIDE_BOTTOM, int(round(minf(10.0, channel_height * 0.42))))

	var horizontal_inset := clampf(channel_height * 0.42, 4.0, 8.0)
	var vertical_inset := clampf(channel_height * 0.20, 1.5, 3.0)
	var inner_size := Vector2(
		maxf(1.0, size.x - horizontal_inset * 2.0),
		maxf(1.0, channel_height - vertical_inset * 2.0)
	)
	var ratio := clampf(value / maxf(max_value, 0.0001), 0.0, 1.0)
	fill_clip.position = Vector2(horizontal_inset, channel_y + vertical_inset)
	fill_clip.size = Vector2(inner_size.x * ratio, inner_size.y)
	fill_clip.visible = ratio > 0.001
	fill_gradient.position = Vector2.ZERO
	fill_gradient.size = inner_size
	fill_grain.position = Vector2.ZERO
	fill_grain.size = inner_size

	for index in tick_marks.size():
		var tick := tick_marks[index]
		var tick_x := horizontal_inset + inner_size.x * float(index + 1) / 5.0
		tick.position = Vector2(round(tick_x), channel_y + vertical_inset + 1.0)
		tick.size = Vector2(1.0, maxf(2.0, inner_size.y - 2.0))
		tick.color = Color(edge_color, 0.20)

	var seal_size := clampf(channel_height * 0.72, 7.0, 13.0)
	var seal_x := horizontal_inset + inner_size.x * ratio
	edge_seal.position = Vector2(seal_x - seal_size * 0.5, channel_y + (channel_height - seal_size) * 0.5)
	edge_seal.size = Vector2.ONE * seal_size
	edge_seal.modulate = Color(1.0, 1.0, 1.0, 0.82)
	edge_seal.visible = ratio > 0.025 and ratio < 0.985


func _update_fill_material() -> void:
	if _gradient == null:
		return
	_gradient.offsets = PackedFloat32Array([0.0, 0.16, 0.72, 1.0])
	_gradient.colors = PackedColorArray([
		Color(meter_color.darkened(0.46), 0.96),
		Color(meter_color.lightened(0.22), 1.0),
		Color(meter_color, 0.98),
		Color(meter_color.darkened(0.34), 0.96),
	])
	_grain_material.set_shader_parameter("meter_tint", meter_color)


func _atlas_region(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = RITUAL_ATLAS
	texture.region = region
	return texture
