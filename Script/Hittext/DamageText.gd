extends Node2D
@onready var show_player: AnimationPlayer = $ShowPlayer
@onready var number: HBoxContainer = $Midlle/Number

var Number: int
var Type: String
var is_set: bool = false
var is_crit: bool
var target: BaseObject
var pool_scene_path: String = ""

func reuse_from_pool():
	is_set = false
	set_physics_process(true)

func reset_for_pool():
	is_set = false
	target = null
	Number = 0
	Type = ""
	is_crit = false
	if show_player != null:
		show_player.stop()
	if number != null:
		for child in number.get_children():
			number.remove_child(child)
			child.queue_free()

func changeNumber():
	var loc_2 = str(Number)
	var loc_1 =  loc_2.split("")
	if Type == "physics":

		if is_crit:
			number.add_theme_constant_override("separation",-20)
		else:
			number.add_theme_constant_override("separation",-10)
	for i in loc_1:
		i = int(i)
		Global.addDamageNumber(number,i,Type,is_crit,target)

func _physics_process(_delta: float) -> void:
	if not is_set:
		changeNumber()
		is_set = true
		if target != null:
			if target is BaseHero:
				if is_crit:
					show_player.play("Crit")
					await show_player.animation_finished
				else:
					show_player.play("physics")
					await show_player.animation_finished
			else:
				show_player.play("physics")
				await show_player.animation_finished
		_recycle_or_free()

func _recycle_or_free():
	if pool_scene_path != "":
		PoolManager.recycle_instance(pool_scene_path,self)
	else:
		queue_free()