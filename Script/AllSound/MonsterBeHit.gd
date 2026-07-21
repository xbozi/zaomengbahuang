extends AudioStreamPlayer
#音效控制
var target
var stream_resource: AudioStream
var is_set = false

func setup_audio() -> void:
	if stream_resource == null and target != null:
		stream_resource = Global.get_cached_audio_stream(target)
	stream = stream_resource
	play()
	is_set = true

func _physics_process(_delta: float) -> void:
	if not is_set:
		setup_audio()
	if MainSet.set_data["RoleOrMonsterHit"]:
		set_volume_db(int(MainSet.set_data["MusicFB_2"]))
	else:
		set_volume_db(-80)
	


func _on_finished() -> void:
	queue_free()
