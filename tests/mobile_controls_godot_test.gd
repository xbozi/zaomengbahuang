extends SceneTree

const ACTIONS_TO_RELEASE := ["move_left", "move_right", "down", "Exit"]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var resource := ResourceLoader.load("res://Scene/MobileControls/MobileControls.tscn")
	if not _check(resource is PackedScene, "MobileControls.tscn must load as a PackedScene"):
		_finish()
		return

	var controls := (resource as PackedScene).instantiate()
	get_root().add_child(controls)
	await process_frame
	controls.visible = true

	_check(controls is CanvasLayer, "Root must be a CanvasLayer")

	var expected_actions := {
		"Attack": "normalhit",
		"Jump": "jump",
		"Skill1": "slz",
		"Skill2": "lys",
		"Skill3": "lyfb",
		"Skill4": "hmz",
		"Skill5": "hytj",
		"Magic": "MagicWeapon",
		"Wushuang": String.chr(0x65E0) + String.chr(0x53CC),
		"Zhenfa": String.chr(0x9635) + String.chr(0x6CD5),
	}

	for button_name in expected_actions:
		var button_path: String = "Root/Buttons/" + str(button_name)
		var button := controls.get_node_or_null(button_path) as TouchScreenButton
		if not _check(button != null, "%s must be a TouchScreenButton" % button_path):
			continue
		_check(button.action == expected_actions[button_name], "%s must map to %s" % [button_path, expected_actions[button_name]])

	var joystick := controls.get_node_or_null("Root/Joystick") as Control
	if _check(joystick != null, "Root/Joystick must be a Control"):
		var start_position: Vector2 = joystick.get_global_rect().get_center()
		var first_touch := InputEventScreenTouch.new()
		first_touch.index = 7
		first_touch.position = start_position
		first_touch.pressed = true
		joystick._input(first_touch)

		var second_touch := InputEventScreenTouch.new()
		second_touch.index = 9
		second_touch.position = start_position
		second_touch.pressed = true
		joystick._input(second_touch)
		_check(joystick.get("joystick_touch_index") == 7, "Joystick must retain touch owner 7 when touch 9 begins")

		var drag := InputEventScreenDrag.new()
		drag.index = 7
		drag.position = start_position + Vector2(80.0, 0.0)
		drag.relative = Vector2(80.0, 0.0)
		joystick._input(drag)
		_check(Input.is_action_pressed("move_right"), "Dragging owner touch right must press move_right")
		_check(not Input.is_action_pressed("move_left"), "Dragging owner touch right must not press move_left")

		var release := InputEventScreenTouch.new()
		release.index = 7
		release.position = drag.position
		release.pressed = false
		joystick._input(release)
		_check(not Input.is_action_pressed("move_right"), "Releasing owner touch must release move_right")
		_check(joystick.get("joystick_touch_index") == -1, "Releasing owner touch must reset joystick owner to -1")

	controls.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	failures.append(message)
	return false


func _finish() -> void:
	for action in ACTIONS_TO_RELEASE:
		Input.action_release(action)

	if failures.is_empty():
		print("Mobile controls Godot resource and touch tests passed.")
		quit(0)
	else:
		quit(1)