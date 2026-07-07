extends AudioStreamPlayer
#音效控制
var target
var is_set = false
var pool_scene_path: String = ""

func reuse_from_pool():
	is_set = false
	set_physics_process(true)

func reset_for_pool():
	stop()
	stream = null
	target = null
	is_set = false

func _physics_process(_delta: float) -> void:
	if not is_set:
		stream = Global.get_cached_resource(target)
		play()	
		is_set = true
	if MainSet.set_data["RoleOrMonsterHit"]:
		set_volume_db(int(MainSet.set_data["MusicFB_2"]))
	else:
		set_volume_db(-80)
	


func _on_finished() -> void:
	if pool_scene_path != "":
		PoolManager.recycle_instance(pool_scene_path,self)
	else:
		queue_free()