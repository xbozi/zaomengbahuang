extends Node

const BASE_SIZE := Vector2(940, 590)

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

func apply_canvas_cover(root: Node2D, base_size: Vector2 = BASE_SIZE) -> void:
	if root == null:
		return
	var size := current_viewport_size()
	var scale_value := cover_scale(size, base_size)
	root.scale = Vector2(scale_value, scale_value)
	root.position = cover_offset(size, base_size)