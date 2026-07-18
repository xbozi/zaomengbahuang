extends TouchScreenButton
class_name MobileActionButton

@export var label_text: String = ""
@export var radius: float = 32.0
@export var font_size: int = 18
@export var normal_color: Color = Color(0.10, 0.14, 0.20, 0.58)
@export var pressed_color: Color = Color(0.95, 0.58, 0.16, 0.88)
@export var border_color: Color = Color(0.90, 0.94, 1.0, 0.72)
@export_range(0.25, 1.0, 0.01) var control_opacity: float = 1.0


func _ready() -> void:
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = radius
	shape = circle_shape
	shape_centered = true
	pressed.connect(queue_redraw)
	released.connect(queue_redraw)
	queue_redraw()


func set_control_opacity(value: float) -> void:
	control_opacity = clampf(value, 0.25, 1.0)
	queue_redraw()


func color_with_opacity(color: Color) -> Color:
	var result := color
	result.a *= control_opacity
	return result


func _draw() -> void:
	var fill_color := color_with_opacity(pressed_color if is_pressed() else normal_color)
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius - 1.0, 0.0, TAU, 48, color_with_opacity(border_color), 2.0, true)

	var font := ThemeDB.fallback_font
	var label_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(-label_size.x * 0.5, label_size.y * 0.32)
	draw_string(font, baseline, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color_with_opacity(Color.WHITE))
