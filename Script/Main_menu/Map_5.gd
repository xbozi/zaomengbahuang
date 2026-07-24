extends Node2D
class_name Map5

func _ready() -> void:
	get_viewport().size_changed.connect(_apply_screen_fit)
	_apply_screen_fit()


func _on_level_40_pressed() -> void:
	pass # Replace with function body.


func _on_level_41_pressed() -> void:
	pass # Replace with function body.


func _on_level_42_pressed() -> void:
	pass # Replace with function body.


func _on_level_43_pressed() -> void:
	pass # Replace with function body.


func _on_level_44_pressed() -> void:
	pass # Replace with function body.


func _on_level_45_pressed() -> void:
	pass # Replace with function body.


func _on_level_46_pressed() -> void:
	pass # Replace with function body.


func _on_memory_class_pressed() -> void:
	pass # Replace with function body.


func _on_shop_pressed() -> void:
	pass # Replace with function body.


func _on_ldl_2_pressed() -> void:
	pass # Replace with function body.


func _on_skill_pressed() -> void:
	pass # Replace with function body.


func _on_activity_pressed() -> void:
	pass # Replace with function body.


func _on_task_pressed() -> void:
	pass # Replace with function body.


func _on_return_pressed() -> void:
	pass # Replace with function body.


func _on_game_set_pressed() -> void:
	pass # Replace with function body.


func _on_game_an_pressed() -> void:
	pass # Replace with function body.


func _on_pellet_pressed() -> void:
	pass # Replace with function body.

func _apply_screen_fit() -> void:
	ScreenFit.apply_legacy_fullscreen_fit(self)
