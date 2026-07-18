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

	var controls := (resource as PackedScene).instantiate() as CanvasLayer
	if not _check(controls != null, "Root must be a CanvasLayer"):
		_finish()
		return
	get_root().add_child(controls)
	await process_frame
	controls.visible = true

	MainSet.set_data.erase("MobileControlsLayout")
	MainSet.set_data.erase("MobileControlsOpacity")
	MainSet.set_data.erase("MobileControlsSafePadding")
	controls.call("ensure_mobile_control_settings")
	_check(MainSet.set_data.has("MobileControlsLayout"), "Missing layout must be filled from defaults")
	_check(MainSet.set_data.has("MobileControlsOpacity"), "Missing opacity must be filled from defaults")
	_check(MainSet.set_data.has("MobileControlsSafePadding"), "Missing safe padding must be filled from defaults")

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

	MainSet.set_data["MobileControlsLayout"]["Attack"] = {"x": 2.0, "y": -1.0}
	MainSet.set_data["MobileControlsLayout"]["Joystick"] = {"x": -1.0, "y": 2.0}
	MainSet.set_data["MobileControlsOpacity"] = 0.42
	MainSet.set_data["MobileControlsSafePadding"] = 36.0
	controls.call("fit_controls_in_rect", Rect2(Vector2(20.0, 30.0), Vector2(400.0, 220.0)))
	controls.call("apply_opacity", controls.call("get_saved_opacity"))

	var attack := controls.get_node_or_null("Root/Buttons/Attack") as TouchScreenButton
	if _check(attack != null, "Attack button must still exist after fitting"):
		_check(attack.position.x <= 400.0 - 52.0, "Attack x must be clamped inside safe rect")
		_check(attack.position.y >= 52.0, "Attack y must be clamped inside safe rect")
		_check(absf(float(attack.get("control_opacity")) - 0.42) < 0.001, "Attack opacity must be applied")

	var joystick := controls.get_node_or_null("Root/Joystick") as Control
	if _check(joystick != null, "Root/Joystick must be a Control"):
		var joystick_radius := float(joystick.get("joystick_radius"))
		_check(joystick.position.x < 0.0, "Joystick touch area may extend left so the visual pad can sit near the edge")
		_check(joystick.position.x + joystick.size.x * 0.5 - joystick_radius >= 0.0, "Joystick visual pad must not extend past safe rect left edge")
		_check(joystick.position.y + joystick.size.y * 0.5 + joystick_radius <= 220.0, "Joystick visual pad must not extend past safe rect bottom edge")
		_check(absf(float(joystick.get("control_opacity")) - 0.42) < 0.001, "Joystick opacity must be applied")

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
		print("Mobile controls Godot resource, layout, opacity, and touch tests passed.")
		quit(0)
	else:
		quit(1)
