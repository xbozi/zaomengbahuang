extends Node2D
@onready var behitplayer: AnimatedSprite2D = $behitplayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var pool_scene_path: String = ""

func _ready() -> void:
	randomize()
	do_()

func reuse_from_pool():
	do_()

func reset_for_pool():
	if animation_player != null:
		animation_player.stop()

func do_():
	if randi_range(0,100) < 50:
		animation_player.play("hurt_1")
	else:
		animation_player.play("hurt_2")
	await animation_player.animation_finished

	pass_()
func pass_():
	if pool_scene_path != "":
		PoolManager.recycle_instance(pool_scene_path,self)
	else:
		queue_free()