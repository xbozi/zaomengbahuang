extends CanvasLayer

const FORCE_SHOW_SETTING := "application/run/force_show_mobile_controls"
const LAYOUT_SETTING := "MobileControlsLayout"
const OPACITY_SETTING := "MobileControlsOpacity"
const SAFE_PADDING_SETTING := "MobileControlsSafePadding"
const DEFAULT_OPACITY := 1.0
const DEFAULT_SAFE_PADDING := 28.0
const JOYSTICK_LAYOUT := {
	"Joystick": Vector2(0.18, 0.76),
}
const BUTTON_LAYOUT := {
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
const REQUIRED_ACTIONS := [
	"move_left",
	"move_right",
	"down",
	"Exit",
	"normalhit",
	"jump",
	"slz",
	"lys",
	"lyfb",
	"hmz",
	"hytj",
	"MagicWeapon",
	"无双",
	"阵法",
]

@onready var root: Control = $Root
@onready var joystick: Control = $Root/Joystick
@onready var buttons: Node2D = $Root/Buttons


func _ready() -> void:
	layer = 100
	ensure_mobile_control_settings()
	visible = should_show()
	validate_actions()
	fit_viewport()
	var resize_callback := Callable(self, "fit_viewport")
	if not get_viewport().size_changed.is_connected(resize_callback):
		get_viewport().size_changed.connect(resize_callback)


func should_show() -> bool:
	var force_show := bool(ProjectSettings.get_setting(FORCE_SHOW_SETTING, false))
	var debug_show: bool = MainSet.set_data.has("MobileControlsShow") and bool(MainSet.set_data["MobileControlsShow"])
	return OS.has_feature("android") or force_show or debug_show


func get_default_layout() -> Dictionary:
	var layout := {}
	for control_name in JOYSTICK_LAYOUT:
		layout[control_name] = vector_to_saved_position(JOYSTICK_LAYOUT[control_name])
	for control_name in BUTTON_LAYOUT:
		layout[control_name] = vector_to_saved_position(BUTTON_LAYOUT[control_name])
	return layout


func vector_to_saved_position(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func ensure_mobile_control_settings() -> void:
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
	if not MainSet.set_data.has(SAFE_PADDING_SETTING):
		MainSet.set_data[SAFE_PADDING_SETTING] = DEFAULT_SAFE_PADDING


func get_saved_layout() -> Dictionary:
	ensure_mobile_control_settings()
	var saved_layout: Dictionary = MainSet.set_data[LAYOUT_SETTING]
	var default_layout := get_default_layout()
	var result := {}
	for control_name in default_layout:
		result[control_name] = saved_position_to_vector(saved_layout.get(control_name, default_layout[control_name]), saved_position_to_vector(default_layout[control_name], Vector2.ZERO))
	return result


func saved_position_to_vector(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return Vector2(clampf(value.x, 0.0, 1.0), clampf(value.y, 0.0, 1.0))
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2(clampf(float(value["x"]), 0.0, 1.0), clampf(float(value["y"]), 0.0, 1.0))
	return fallback


func get_saved_opacity() -> float:
	ensure_mobile_control_settings()
	return clampf(float(MainSet.set_data[OPACITY_SETTING]), 0.25, 1.0)


func get_safe_padding() -> float:
	ensure_mobile_control_settings()
	return clampf(float(MainSet.set_data[SAFE_PADDING_SETTING]), 0.0, 96.0)


func get_logical_safe_rect() -> Rect2:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	if not OS.has_feature("android"):
		return viewport_rect

	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if screen_size.x <= 0 or screen_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return viewport_rect

	var logical_scale: Vector2 = Vector2(
		viewport_rect.size.x / float(screen_size.x),
		viewport_rect.size.y / float(screen_size.y)
	)
	var safe_position: Vector2 = Vector2(float(safe_area.position.x), float(safe_area.position.y))
	var safe_size: Vector2 = Vector2(float(safe_area.size.x), float(safe_area.size.y))
	return Rect2(
		viewport_rect.position + safe_position * logical_scale,
		safe_size * logical_scale
	)


func get_padded_safe_rect() -> Rect2:
	var safe_rect := get_logical_safe_rect()
	var padding := get_safe_padding()
	if safe_rect.size.x > padding * 2.0 and safe_rect.size.y > padding * 2.0:
		safe_rect = safe_rect.grow(-padding)
	return safe_rect


func fit_viewport() -> void:
	fit_controls_in_rect(get_padded_safe_rect())
	apply_opacity(get_saved_opacity())


func fit_controls_in_rect(safe_rect: Rect2) -> void:
	ensure_mobile_control_settings()
	root.position = safe_rect.position
	root.size = safe_rect.size
	var saved_layout := get_saved_layout()
	fit_joystick(saved_layout.get("Joystick", JOYSTICK_LAYOUT["Joystick"]))
	for button_name in BUTTON_LAYOUT:
		var button := buttons.get_node_or_null(button_name) as TouchScreenButton
		if button != null:
			var radius: float = float(button.get("radius")) if button.get("radius") != null else 32.0
			button.position = clamp_control_position(saved_layout.get(button_name, BUTTON_LAYOUT[button_name]), root.size, radius)


func fit_joystick(normalized_position: Vector2) -> void:
	if joystick == null:
		return
	joystick.anchor_left = 0.0
	joystick.anchor_top = 0.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 0.0
	var radius: float = float(joystick.get("joystick_radius")) if joystick.get("joystick_radius") != null else 72.0
	var joystick_size := Vector2(radius * 2.0 + 96.0, radius * 2.0 + 96.0)
	joystick.size = joystick_size
	var center := clamp_control_position(normalized_position, root.size, get_joystick_edge_margin(radius))
	joystick.position = center - joystick_size * 0.5


func get_joystick_edge_margin(radius: float) -> float:
	return radius


func clamp_control_position(normalized_position: Vector2, area_size: Vector2, margin: float) -> Vector2:
	var position := area_size * normalized_position
	if area_size.x >= margin * 2.0:
		position.x = clampf(position.x, margin, area_size.x - margin)
	else:
		position.x = area_size.x * 0.5
	if area_size.y >= margin * 2.0:
		position.y = clampf(position.y, margin, area_size.y - margin)
	else:
		position.y = area_size.y * 0.5
	return position


func apply_opacity(value: float) -> void:
	var opacity := clampf(value, 0.25, 1.0)
	if joystick != null and joystick.has_method("set_control_opacity"):
		joystick.set_control_opacity(opacity)
	for child in buttons.get_children():
		if child.has_method("set_control_opacity"):
			child.set_control_opacity(opacity)


func validate_actions() -> void:
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			push_warning("MobileControls: missing required InputMap action '%s'." % action_name)
