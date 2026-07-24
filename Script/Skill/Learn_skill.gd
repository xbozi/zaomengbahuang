extends Node2D
@onready var fullscreen_mask: ColorRect = $fengeceng
@onready var bg: Sprite2D = $bg
@onready var front_bg: ColorRect = $bg/lh_pic/front_bg
@onready var Title: Label = $bg/lh_pic/front_bg/Title
@onready var Lh_value: Label = $bg/lh_pic/lh_value
#主动技能位置：(40,50)
var zd_sk
var bd_sk
var is_zd: bool = false
var is_bd: bool = false
var hidden_mobile_controls: Array = []

func _ready() -> void:
	apply_mobile_layout()
	hide_mobile_controls()
	is_zd = true
	zd_sk = Global.add_zd_skillscene(front_bg,Vector2(40,50))
	is_bd = false

func apply_mobile_layout() -> void:
	position = Vector2.ZERO
	fullscreen_mask.position = Vector2.ZERO
	fullscreen_mask.size = ScreenFit.TARGET_VIEWPORT_SIZE
	bg.position = ScreenFit.TARGET_VIEWPORT_SIZE * 0.5

func hide_mobile_controls() -> void:
	hidden_mobile_controls.clear()
	var mobile_controls_list := get_tree().root.find_children("MobileControls", "", true, false)
	for mobile_controls in mobile_controls_list:
		if mobile_controls.visible:
			hidden_mobile_controls.append(mobile_controls)
			mobile_controls.visible = false

func restore_mobile_controls() -> void:
	for mobile_controls in hidden_mobile_controls:
		if is_instance_valid(mobile_controls):
			mobile_controls.visible = true
	hidden_mobile_controls.clear()

func _exit_tree() -> void:
	restore_mobile_controls()

func _physics_process(_delta: float) -> void:
	if is_zd:
		Title.text = "主动技能"
	if is_bd:
		Title.text = "被动技能"
	Lh_value.text = str(PlayerData.player_data["coin_num"])

func _on_zd_skill_pressed() -> void:
	is_zd = true
	is_bd = false
	if zd_sk == null:
		zd_sk = Global.add_zd_skillscene(front_bg,Vector2(40,50))
	if bd_sk != null:
		bd_sk.queue_free()
func _on_bd_skill_pressed() -> void:
	is_zd = false
	is_bd = true
	if bd_sk == null:
		bd_sk = Global.add_bd_skillscene(front_bg,Vector2(10,50))
	if zd_sk != null:
		zd_sk.queue_free()
	

func _on_close_pressed() -> void:
	restore_mobile_controls()
	queue_free()
