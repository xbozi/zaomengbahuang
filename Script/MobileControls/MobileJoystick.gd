extends Control
class_name MobileJoystick

@export_range(1.0, 256.0, 1.0) var joystick_radius: float = 72.0
@export_range(1.0, 256.0, 1.0) var knob_radius: float = 29.0
@export_range(0.0, 1.0, 0.01) var horizontal_deadzone: float = 0.25
@export_range(0.0, 1.0, 0.01) var vertical_deadzone: float = 0.55

var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var knob_offset: Vector2 = Vector2.ZERO
var pressed_actions: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_on_visibility_changed)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			if joystick_touch_index == -1 and get_global_rect().has_point(touch_event.position):
				joystick_touch_index = touch_event.index
				joystick_center = make_canvas_position_local(touch_event.position)
				update_joystick(Vector2.ZERO)
				get_viewport().set_input_as_handled()
		elif touch_event.index == joystick_touch_index:
			reset_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index == joystick_touch_index:
			update_joystick(make_canvas_position_local(drag_event.position) - joystick_center)
			get_viewport().set_input_as_handled()


func update_joystick(offset: Vector2) -> void:
	knob_offset = offset.limit_length(joystick_radius)
	var axis := knob_offset / joystick_radius
	update_horizontal_actions(axis.x)
	update_vertical_actions(axis.y)
	queue_redraw()


func update_horizontal_actions(value: float) -> void:
	if value < -horizontal_deadzone:
		press_action("move_left", absf(value))
		release_action("move_right")
	elif value > horizontal_deadzone:
		press_action("move_right", value)
		release_action("move_left")
	else:
		release_action("move_left")
		release_action("move_right")


func update_vertical_actions(value: float) -> void:
	if value > vertical_deadzone:
		press_action_once("down")
		release_action("Exit")
	elif value < -vertical_deadzone:
		press_action_once("Exit")
		release_action("down")
	else:
		release_action("down")
		release_action("Exit")


func press_action(action_name: String, strength: float = 1.0) -> void:
	pressed_actions[action_name] = true
	Input.action_press(action_name, strength)


func press_action_once(action_name: String) -> void:
	if pressed_actions.has(action_name):
		return
	press_action(action_name)


func release_action(action_name: String) -> void:
	if not pressed_actions.has(action_name):
		return
	Input.action_release(action_name)
	pressed_actions.erase(action_name)


func release_all_actions() -> void:
	for action_name in pressed_actions.keys():
		Input.action_release(action_name)
	pressed_actions.clear()


func reset_joystick() -> void:
	joystick_touch_index = -1
	joystick_center = Vector2.ZERO
	knob_offset = Vector2.ZERO
	release_all_actions()
	queue_redraw()


func _draw() -> void:
	var center := joystick_center if joystick_touch_index != -1 else size * 0.5
	draw_circle(center, joystick_radius, Color(0.10, 0.14, 0.20, 0.40))
	draw_arc(center, joystick_radius - 1.0, 0.0, TAU, 64, Color(0.90, 0.94, 1.0, 0.62), 2.0, true)
	draw_circle(center + knob_offset, knob_radius, Color(0.90, 0.94, 1.0, 0.70))


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		reset_joystick()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		reset_joystick()


func _exit_tree() -> void:
	reset_joystick()
