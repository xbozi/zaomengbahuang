extends Node

const BASE_SIZE := Vector2(940, 590)
const DEFAULT_SAFE_PADDING := 28.0

func current_viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func base_center() -> Vector2:
	return BASE_SIZE * 0.5

func base_point(x: float, y: float) -> Vector2:
	return Vector2(x, y)

func viewport_size_or_current(viewport_size: Vector2 = Vector2.ZERO) -> Vector2:
	var size := viewport_size
	if size == Vector2.ZERO:
		size = current_viewport_size()
	return size

func cover_scale(viewport_size: Vector2 = Vector2.ZERO, base_size: Vector2 = BASE_SIZE) -> float:
	var size := viewport_size_or_current(viewport_size)
	if size.x <= 0.0 or size.y <= 0.0 or base_size.x <= 0.0 or base_size.y <= 0.0:
		return 1.0
	return max(size.x / base_size.x, size.y / base_size.y)

func cover_offset(viewport_size: Vector2 = Vector2.ZERO, base_size: Vector2 = BASE_SIZE) -> Vector2:
	var size := viewport_size_or_current(viewport_size)
	var scale_value := cover_scale(size, base_size)
	return (size - base_size * scale_value) * 0.5

func fit_scale(viewport_size: Vector2 = Vector2.ZERO, base_size: Vector2 = BASE_SIZE) -> float:
	var size := viewport_size_or_current(viewport_size)
	if size.x <= 0.0 or size.y <= 0.0 or base_size.x <= 0.0 or base_size.y <= 0.0:
		return 1.0
	return min(size.x / base_size.x, size.y / base_size.y)

func fit_offset(viewport_size: Vector2 = Vector2.ZERO, base_size: Vector2 = BASE_SIZE) -> Vector2:
	var size := viewport_size_or_current(viewport_size)
	var scale_value := fit_scale(size, base_size)
	return (size - base_size * scale_value) * 0.5

func logical_display_safe_rect() -> Rect2:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	if not OS.has_feature("android"):
		return viewport_rect
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if screen_size.x <= 0 or screen_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return viewport_rect
	var logical_scale := Vector2(
		viewport_rect.size.x / float(screen_size.x),
		viewport_rect.size.y / float(screen_size.y)
	)
	return Rect2(
		viewport_rect.position + Vector2(float(safe_area.position.x), float(safe_area.position.y)) * logical_scale,
		Vector2(float(safe_area.size.x), float(safe_area.size.y)) * logical_scale
	)

func safe_fit_rect(padding: float = DEFAULT_SAFE_PADDING) -> Rect2:
	var rect := logical_display_safe_rect()
	var safe_padding := clampf(padding, 0.0, 96.0)
	if rect.size.x > safe_padding * 2.0 and rect.size.y > safe_padding * 2.0:
		rect = rect.grow(-safe_padding)
	return rect

func apply_canvas_cover(root: Node2D, base_size: Vector2 = BASE_SIZE) -> void:
	if root == null:
		return
	var size := current_viewport_size()
	var scale_value := cover_scale(size, base_size)
	root.scale = Vector2(scale_value, scale_value)
	root.position = cover_offset(size, base_size)

func apply_canvas_mobile_safe_fit(root: Node2D, base_size: Vector2 = BASE_SIZE, padding: float = DEFAULT_SAFE_PADDING) -> void:
	if root == null:
		return
	if not OS.has_feature("android"):
		apply_canvas_cover(root, base_size)
		return
	var rect := safe_fit_rect(padding)
	var scale_value := fit_scale(rect.size, base_size)
	root.scale = Vector2(scale_value, scale_value)
	root.position = rect.position + fit_offset(rect.size, base_size)
