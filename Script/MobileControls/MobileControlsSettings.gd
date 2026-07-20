extends CanvasLayer

const LAYOUT_SETTING := "MobileControlsLayout"
const OPACITY_SETTING := "MobileControlsOpacity"
const DEFAULT_OPACITY := 1.0
const DEFAULT_LAYOUT := {
	"Joystick": Vector2(0.18, 0.76),
	"Attack": Vector2(0.86, 0.78),
	"Jump": Vector2(0.92, 0.60),
	"Skill1": Vector2(0.70, 0.82),
	"Skill2": Vector2(0.64, 0.69),
	"Skill3": Vector2(0.69, 0.54),
	"Skill4": Vector2(0.78, 0.44),
	"Skill5": Vector2(0.87, 0.40),
	"Magic": Vector2(0.76, 0.16),
	"Wushuang": Vector2(0.84, 0.16),
	"Zhenfa": Vector2(0.92, 0.16),
}
const CONTROL_LABELS := {
	"Joystick": "摇杆",
	"Attack": "普攻",
	"Jump": "跳跃",
	"Skill1": "技1",
	"Skill2": "技2",
	"Skill3": "技3",
	"Skill4": "技4",
	"Skill5": "技5",
	"Magic": "法宝",
	"Wushuang": "无双",
	"Zhenfa": "阵法",
}

@onready var preview_area: Control = $Root/Panel/PreviewArea
@onready var opacity_slider: HSlider = $Root/Panel/OpacitySlider

var working_layout: Dictionary = {}
var preview_buttons: Dictionary = {}
var dragging_name := ""


func _ready() -> void:
	layer = 120
	ensure_settings()
	working_layout = duplicate_layout(MainSet.set_data[LAYOUT_SETTING])
	opacity_slider.value = get_opacity()
	create_preview_buttons()
	update_preview()


func ensure_settings() -> void:
	if not MainSet.set_data.has(LAYOUT_SETTING) or not (MainSet.set_data[LAYOUT_SETTING] is Dictionary):
		MainSet.set_data[LAYOUT_SETTING] = get_default_layout()
	else:
		var saved_layout: Dictionary = MainSet.set_data[LAYOUT_SETTING]
		var default_layout := get_default_layout()
		for control_name in default_layout:
			if not saved_layout.has(control_name):
				saved_layout[control_name] = default_layout[control_name]
		MainSet.set_data[LAYOUT_SETTING] = saved_layout
	if not MainSet.set_data.has(OPACITY_SETTING):
		MainSet.set_data[OPACITY_SETTING] = DEFAULT_OPACITY


func get_default_layout() -> Dictionary:
	var layout := {}
	for control_name in DEFAULT_LAYOUT:
		layout[control_name] = vector_to_saved_position(DEFAULT_LAYOUT[control_name])
	return layout


func duplicate_layout(source: Dictionary) -> Dictionary:
	var result := {}
	var default_layout := get_default_layout()
	for control_name in default_layout:
		result[control_name] = vector_to_saved_position(saved_position_to_vector(source.get(control_name, default_layout[control_name]), saved_position_to_vector(default_layout[control_name], Vector2.ZERO)))
	return result


func vector_to_saved_position(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func saved_position_to_vector(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return Vector2(clampf(value.x, 0.0, 1.0), clampf(value.y, 0.0, 1.0))
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2(clampf(float(value["x"]), 0.0, 1.0), clampf(float(value["y"]), 0.0, 1.0))
	return fallback


func get_opacity() -> float:
	return clampf(float(MainSet.set_data.get(OPACITY_SETTING, DEFAULT_OPACITY)), 0.25, 1.0)


func create_preview_buttons() -> void:
	for control_name in DEFAULT_LAYOUT:
		var button := Button.new()
		button.name = control_name
		button.text = CONTROL_LABELS.get(control_name, control_name)
		button.custom_minimum_size = Vector2(62.0, 34.0) if control_name != "Joystick" else Vector2(86.0, 44.0)
		button.size = button.custom_minimum_size
		button.mouse_default_cursor_shape = Control.CURSOR_MOVE
		button.gui_input.connect(Callable(self, "_on_preview_button_gui_input").bind(control_name))
		preview_area.add_child(button)
		preview_buttons[control_name] = button


func update_preview() -> void:
	var opacity := get_opacity()
	for control_name in preview_buttons:
		var button := preview_buttons[control_name] as Button
		var normalized_position := saved_position_to_vector(working_layout.get(control_name, vector_to_saved_position(DEFAULT_LAYOUT[control_name])), DEFAULT_LAYOUT[control_name])
		var center := Vector2(preview_area.size.x * normalized_position.x, preview_area.size.y * normalized_position.y)
		button.position = clamp_preview_button_position(center - button.size * 0.5, button.size, control_name)
		button.modulate.a = opacity


func clamp_preview_button_position(position: Vector2, button_size: Vector2, control_name: String = "") -> Vector2:
	var left_limit := 0.0
	var right_limit := maxf(0.0, preview_area.size.x - button_size.x)
	if control_name == "Joystick":
		left_limit = -button_size.x * 0.5
		right_limit = preview_area.size.x - button_size.x * 0.5
	return Vector2(
		clampf(position.x, left_limit, right_limit),
		clampf(position.y, 0.0, maxf(0.0, preview_area.size.y - button_size.y))
	)


func _on_preview_button_gui_input(event: InputEvent, control_name: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			dragging_name = control_name if mouse_event.pressed else ""
			if mouse_event.pressed:
				move_control_to_local_position(control_name, preview_area.get_local_mouse_position())
	elif event is InputEventMouseMotion and dragging_name == control_name:
		move_control_to_local_position(control_name, preview_area.get_local_mouse_position())
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		dragging_name = control_name if touch_event.pressed else ""
		if touch_event.pressed:
			move_control_to_local_position(control_name, make_preview_gui_position_local(preview_buttons.get(control_name) as Control, touch_event.position))
	elif event is InputEventScreenDrag and dragging_name == control_name:
		var drag_event := event as InputEventScreenDrag
		move_control_to_local_position(control_name, make_preview_gui_position_local(preview_buttons.get(control_name) as Control, drag_event.position))


func make_preview_position_local(canvas_position: Vector2) -> Vector2:
	return preview_area.get_global_transform_with_canvas().affine_inverse() * canvas_position


func make_preview_gui_position_local(source_control: Control, local_position: Vector2) -> Vector2:
	if source_control == null:
		return local_position
	var canvas_position := source_control.get_global_transform_with_canvas() * local_position
	return preview_area.get_global_transform_with_canvas().affine_inverse() * canvas_position


func move_control_to_local_position(control_name: String, local_position: Vector2) -> void:
	if preview_area.size.x <= 0.0 or preview_area.size.y <= 0.0:
		return
	working_layout[control_name] = {
		"x": clampf(local_position.x / preview_area.size.x, 0.0, 1.0),
		"y": clampf(local_position.y / preview_area.size.y, 0.0, 1.0),
	}
	update_preview()


func reset_to_default_layout() -> void:
	working_layout = get_default_layout()
	update_preview()


func _on_opacity_slider_value_changed(value: float) -> void:
	MainSet.set_data[OPACITY_SETTING] = clampf(value, 0.25, 1.0)
	update_preview()


func _on_reset_button_pressed() -> void:
	reset_to_default_layout()


func _on_save_button_pressed() -> void:
	MainSet.set_data[LAYOUT_SETTING] = duplicate_layout(working_layout)
	MainSet.set_data[OPACITY_SETTING] = get_opacity()
	MemoryClass.main_bc()
	queue_free()


func _on_return_button_pressed() -> void:
	queue_free()
