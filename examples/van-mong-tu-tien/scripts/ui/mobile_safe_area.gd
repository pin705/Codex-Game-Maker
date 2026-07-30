class_name MobileSafeArea
extends RefCounted

## Shared safe-area math for mobile HUD surfaces. The returned rectangle is the
## intersection of the platform cutout-safe area and a conservative title-safe
## zone, with an optional extra inset for comfortable thumb clearance.

const DEFAULT_TITLE_SAFE_RATIO := 0.05


static func platform_safe_rect(viewport_size: Vector2) -> Rect2:
	var full := Rect2(Vector2.ZERO, viewport_size.max(Vector2.ONE))
	if not _is_mobile_runtime():
		return full
	var device_safe: Rect2i = DisplayServer.get_display_safe_area()
	if device_safe.size.x <= 0 or device_safe.size.y <= 0:
		return full
	var display_size: Vector2i = DisplayServer.screen_get_size()
	if display_size.x <= 0 or display_size.y <= 0:
		display_size = DisplayServer.window_get_size()
	if display_size.x <= 0 or display_size.y <= 0:
		return full
	var scale := Vector2(
		viewport_size.x / float(display_size.x),
		viewport_size.y / float(display_size.y)
	)
	var mapped := Rect2(Vector2(device_safe.position) * scale, Vector2(device_safe.size) * scale)
	return full.intersection(mapped)


static func title_safe_rect(
	viewport_size: Vector2,
	raw_safe_area: Rect2 = Rect2(),
	margin_ratio: float = DEFAULT_TITLE_SAFE_RATIO,
	additional_padding: float = 0.0
) -> Rect2:
	var safe_viewport_size := viewport_size.max(Vector2.ONE)
	var full := Rect2(Vector2.ZERO, safe_viewport_size)
	var raw := raw_safe_area if raw_safe_area.has_area() else full
	raw = full.intersection(raw)
	var ratio := clampf(margin_ratio, 0.0, 0.20)
	var title_margin := safe_viewport_size * ratio
	var title_safe := Rect2(title_margin, safe_viewport_size - title_margin * 2.0)
	var result := raw.intersection(title_safe)
	if not result.has_area():
		result = raw if raw.has_area() else full
	var padding := maxf(0.0, additional_padding)
	var max_padding := maxf(0.0, minf(result.size.x, result.size.y) * 0.5 - 1.0)
	padding = minf(padding, max_padding)
	return Rect2(result.position + Vector2.ONE * padding, result.size - Vector2.ONE * padding * 2.0)


static func centered_rect_inside(safe_rect: Rect2, center: Vector2, requested_size: Vector2) -> Rect2:
	var target_size := Vector2(
		minf(maxf(1.0, requested_size.x), safe_rect.size.x),
		minf(maxf(1.0, requested_size.y), safe_rect.size.y)
	)
	var half := target_size * 0.5
	var clamped_center := Vector2(
		clampf(center.x, safe_rect.position.x + half.x, safe_rect.end.x - half.x),
		clampf(center.y, safe_rect.position.y + half.y, safe_rect.end.y - half.y)
	)
	return Rect2(clamped_center - half, target_size)


static func _is_mobile_runtime() -> bool:
	return (
		OS.has_feature("mobile")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
		or OS.has_feature("android")
		or OS.has_feature("ios")
	)
