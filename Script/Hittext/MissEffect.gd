extends Node2D
const POOL_SCENE_PATH := "res://Scene/hittest/miss_effect.tscn"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var texture_rect: TextureRect = $TextureRect

var is_set := false

func _ready() -> void:
	remove_queue_free_tracks(animation_player)

func remove_queue_free_tracks(target_player: AnimationPlayer) -> void:
	var library := target_player.get_animation_library("")
	if library == null:
		return
	for animation_name in library.get_animation_list():
		var animation := library.get_animation(animation_name)
		var track_index := animation.get_track_count() - 1
		while track_index >= 0:
			if animation.track_get_type(track_index) == Animation.TYPE_METHOD:
				var should_remove := false
				for key_index in range(animation.track_get_key_count(track_index)):
					var key_value = animation.track_get_key_value(track_index, key_index)
					if key_value is Dictionary and key_value.has("method") and String(key_value["method"]) == "queue_free":
						should_remove = true
				if should_remove:
					animation.remove_track(track_index)
			track_index -= 1

func reset_for_pool() -> void:
	is_set = false
	if is_node_ready():
		animation_player.stop()
		texture_rect.position = Vector2(-27.5, -12.0)
		texture_rect.modulate = Color(1, 1, 1, 1)

func recycle_to_pool() -> void:
	PoolManager.recycle_instance(POOL_SCENE_PATH, self)

func _physics_process(_delta: float) -> void:
	if is_set:
		return
	is_set = true
	animation_player.play("miss")
	await animation_player.animation_finished
	recycle_to_pool()
