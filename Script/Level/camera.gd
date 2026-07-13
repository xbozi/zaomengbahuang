extends Camera2D
var max_right := 940.0
var max_left := 0.0
var max_top := 0.0
var max_bottom := 590.0

func _physics_process(_delta: float) -> void:
	var visible_size = ScreenFit.current_viewport_size()
	self.limit_right = max(max_right, max_left + visible_size.x)
	self.limit_left = max_left
	self.limit_top = max_top
	self.limit_bottom = max(max_bottom, max_top + visible_size.y)
	
func disturb_offset(strength: float):
	
	self.offset = Vector2(randf_range(-strength,strength),randf_range(-strength,strength))

func Shake(strength: float,times: int,interv:float):
	
	for i in range(times):
		disturb_offset(strength)
		await get_tree().create_timer(interv,false).timeout
		reset_offset()
		
	reset_offset()
func reset_offset():
	self.offset = Vector2(0,0)
