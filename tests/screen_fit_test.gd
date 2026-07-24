extends SceneTree

func _init() -> void:
	var script = load("res://Script/Utils/ScreenFit.gd")
	if script == null:
		push_error("ScreenFit script must load")
		quit(1)
		return

	var fit = script.new()
	assert_near(fit.TARGET_VIEWPORT_SIZE.x, 1320.0, 0.01, "target viewport width")
	assert_near(fit.TARGET_VIEWPORT_SIZE.y, 594.0, 0.01, "target viewport height")

	var cover_scale_value = fit.cover_scale(Vector2(1320, 594))
	assert_near(cover_scale_value, 1.40426, 0.01, "cover scale fills 20:9 viewport")

	var cover_offset = fit.cover_offset(Vector2(1320, 594))
	assert_near(cover_offset.x, 0.0, 0.01, "cover offset keeps width filled")
	assert_near(cover_offset.y, -117.25532, 0.01, "cover offset centers cropped height")

	var fit_scale_value = fit.fit_scale(Vector2(1320, 594))
	assert_near(fit_scale_value, 1.00678, 0.01, "fit scale keeps legacy canvas fully visible")

	var fit_offset = fit.fit_offset(Vector2(1320, 594))
	assert_near(fit_offset.x, 186.81356, 0.01, "fit offset centers side margins")
	assert_near(fit_offset.y, 0.0, 0.01, "fit offset does not crop top UI")
	assert_fit_keeps_whole_canvas(fit, Vector2(1320, 594), "20:9 target")
	assert_fit_keeps_whole_canvas(fit, Vector2(1600, 900), "16:9 emulator")

	var cover_90_scale_value = fit.cover_90_scale(Vector2(1320, 594))
	assert_near(cover_90_scale_value, 1.26383, 0.01, "cover 90 scale fills then shrinks scene")

	var cover_90_offset = fit.cover_90_offset(Vector2(1320, 594))
	assert_near(cover_90_offset.x, 66.0, 0.01, "cover 90 offset centers shrunken width")
	assert_near(cover_90_offset.y, -75.82979, 0.01, "cover 90 offset keeps cover behavior after shrinking")

	var center = fit.base_center()
	assert_near(center.x, 470.0, 0.01, "base center x")
	assert_near(center.y, 295.0, 0.01, "base center y")

	var point = fit.base_point(470, 300)
	assert_near(point.x, 470.0, 0.01, "base point x")
	assert_near(point.y, 300.0, 0.01, "base point y")
	quit(0)

func assert_fit_keeps_whole_canvas(fit: Node, viewport_size: Vector2, label: String) -> void:
	var scale_value = fit.fit_scale(viewport_size)
	var offset = fit.fit_offset(viewport_size)
	var covered_size = fit.BASE_SIZE * scale_value
	if offset.x < -0.01 or offset.y < -0.01 or covered_size.x > viewport_size.x + 0.01 or covered_size.y > viewport_size.y + 0.01:
		push_error("%s fit crops legacy canvas" % label)
		quit(1)

func assert_near(actual: float, expected: float, tolerance: float, label: String) -> void:
	if abs(actual - expected) > tolerance:
		push_error("%s expected %.4f got %.4f" % [label, expected, actual])
		quit(1)