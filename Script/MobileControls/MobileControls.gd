extends CanvasLayer

const FORCE_SHOW_SETTING := "application/run/force_show_mobile_controls"
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
const BUTTON_LAYOUT := {
	"Attack": Vector2(0.88, 0.82),
	"Jump": Vector2(0.95, 0.63),
	"Skill1": Vector2(0.72, 0.86),
	"Skill2": Vector2(0.65, 0.72),
	"Skill3": Vector2(0.70, 0.56),
	"Skill4": Vector2(0.79, 0.46),
	"Skill5": Vector2(0.88, 0.42),
	"Magic": Vector2(0.79, 0.14),
	"Wushuang": Vector2(0.87, 0.14),
	"Zhenfa": Vector2(0.95, 0.14),
}

@onready var root: Control = $Root
@onready var buttons: Node2D = $Root/Buttons


func _ready() -> void:
	layer = 100
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


func fit_viewport() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	root.position = Vector2.ZERO
	root.size = viewport_size
	for button_name in BUTTON_LAYOUT:
		var button := buttons.get_node_or_null(button_name) as TouchScreenButton
		if button != null:
			button.position = viewport_size * BUTTON_LAYOUT[button_name]


func validate_actions() -> void:
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			push_warning("MobileControls: missing required InputMap action '%s'." % action_name)
