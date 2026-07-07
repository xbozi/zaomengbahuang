extends AnimatedSprite2D
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
var pool_scene_path: String = ""
var _is_running: bool = false

func reuse_from_pool():
	state = do
	_is_running = false
	set_physics_process(true)

func reset_for_pool():
	state = do
	_is_running = false
	Effect_name = ""
	Effect_dir = false
	Effect_speed = 1
	scale_ = Vector2(1,1)
	if EffectPlayer != null:
		EffectPlayer.stop()

func _physics_process(_delta: float) -> void:

	match state:
		do:
			if not _is_running:
				do_action(Effect_name)
		remove:
			pass

func do_action(name_):
	_is_running = true
	EffectPlayer.speed_scale = Effect_speed
	special_effect.flip_h = Effect_dir
	special_effect.scale = scale_
	EffectPlayer.play(name_)
	await EffectPlayer.animation_finished
	state = remove
	_recycle_or_free()
	pass

func _recycle_or_free():
	if pool_scene_path != "":
		PoolManager.recycle_instance(pool_scene_path,self)
	else:
		queue_free()