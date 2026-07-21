extends AnimatedSprite2D
const POOL_SCENE_PATH := "res://Scene/Base/special_affect.tscn"

@onready var special_effect: AnimatedSprite2D = $"."
@onready var EffectPlayer: AnimationPlayer = $SpecialAffect

enum {
	do,
	remove
}

var Effect_name: String
var state = do
var Effect_dir: bool
var Effect_speed: float
var scale_

func _ready() -> void:
	remove_queue_free_tracks(EffectPlayer)

func remove_queue_free_tracks(animation_player: AnimationPlayer) -> void:
	var library := animation_player.get_animation_library("")
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
	Effect_name = ""
	state = do
	Effect_dir = false
	Effect_speed = 1.0
	scale_ = Vector2.ONE
	if is_node_ready():
		EffectPlayer.stop()
		special_effect.flip_h = false
		special_effect.scale = Vector2.ONE
		special_effect.self_modulate = Color(1, 1, 1, 1)
		special_effect.frame = 0
		special_effect.animation = &"Empty"

func recycle_to_pool() -> void:
	PoolManager.recycle_instance(POOL_SCENE_PATH, self)

func _physics_process(_delta: float) -> void:
	match state:
		do:
			if Effect_name != "":
				do_action(Effect_name)
		remove:
			pass

func do_action(name_):
	state = remove
	if not EffectPlayer.has_animation(name_):
		recycle_to_pool()
		return
	EffectPlayer.speed_scale = Effect_speed
	special_effect.flip_h = Effect_dir
	special_effect.scale = scale_
	EffectPlayer.play(name_)
	await EffectPlayer.animation_finished
	recycle_to_pool()
