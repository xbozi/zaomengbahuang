extends SceneTree

func _init() -> void:
	var script = load("res://Script/Utils/ScreenFit.gd")
	if script == null:
		push_error("ScreenFit script must load")
		quit(1)
		return

	var fit = script.new()
	var scale_value = fit.cover_scale(Vector2(1600, 900))
	assert_near(scale_value, 1.70213, 0.01, "cover scale fills widened viewport")

	var offset = fit.cover_offset(Vector2(1600, 900))
	assert_near(offset.x, 0.0, 0.01, "cover offset keeps width filled")
	assert_near(offset.y, -52.12766, 0.01, "cover offset centers cropped height")

	var center = fit.base_center()
	assert_near(center.x, 470.0, 0.01, "base center x")
	assert_near(center.y, 295.0, 0.01, "base center y")

	var point = fit.base_point(470, 300)
	assert_near(point.x, 470.0, 0.01, "base point x")
	assert_near(point.y, 300.0, 0.01, "base point y")
	quit(0)

func assert_near(actual: float, expected: float, tolerance: float, label: String) -> void:
	if abs(actual - expected) > tolerance:
		push_error("%s expected %.4f got %.4f" % [label, expected, actual])
		quit(1)