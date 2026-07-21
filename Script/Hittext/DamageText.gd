extends Node2D
const POOL_SCENE_PATH := "res://Scene/hittest/DamageText.tscn"

@onready var show_player: AnimationPlayer = $ShowPlayer
@onready var number: HBoxContainer = $Midlle/Number

var Number: int
var Type: String
var is_set: bool = false
var is_crit: bool
var target: BaseObject

func _ready() -> void:
	remove_queue_free_tracks(show_player)

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
	Number = 0
	Type = ""
	is_set = false
	is_crit = false
	target = null
	if is_node_ready():
		show_player.stop()
		$Midlle.position = Vector2.ZERO
		$Midlle.scale = Vector2.ONE
		number.modulate = Color(1, 1, 1, 1)
		number.add_theme_constant_override("separation", -10)
		for child in number.get_children():
			number.remove_child(child)
			child.queue_free()

func recycle_to_pool() -> void:
	PoolManager.recycle_instance(POOL_SCENE_PATH, self)

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
	if is_set:
		return
	changeNumber()
	is_set = true
	var animation_name := "physics"
	if target != null and target is BaseHero and is_crit:
		animation_name = "Crit"
	show_player.play(animation_name)
	await show_player.animation_finished
	recycle_to_pool()

