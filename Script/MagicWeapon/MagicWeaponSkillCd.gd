extends TextureRect
class_name mgcd
@onready var skillicon: TextureRect = $skillicon
@onready var pic_box: TextureProgressBar = $PicBox
@onready var last_time: Timer = $LastTime
@onready var time_text: Label = $TimeText

var SkillName: String
var MaxTime:float
var Iszhenfa: bool
var cached_skill_name := ""
var cached_is_zhenfa := false

func update_skill_icon_if_needed() -> void:
	if SkillName == null or SkillName == "":
		cached_skill_name = ""
		return
	if cached_skill_name == SkillName and cached_is_zhenfa == Iszhenfa:
		return
	cached_skill_name = SkillName
	cached_is_zhenfa = Iszhenfa
	var icon_path := ""
	if Iszhenfa:
		icon_path = "res://Art/TwentyEightConstellations/" + str(SkillName) + ".png"
	else:
		icon_path = "res://Art/MagicWeapon/Skill_Icon/" + str(SkillName) + ".png"
	var icon_texture = Global.get_cached_resource(icon_path)
	skillicon.texture = icon_texture
	pic_box.texture_progress = icon_texture

func _physics_process(delta: float) -> void:
	if SkillName != null and SkillName != "":
		update_skill_icon_if_needed()
		if MaxTime > 0:
			if last_time.is_stopped():
				last_time.start(MaxTime)
	if last_time.time_left <= 0:
		time_text.visible = false
		pic_box.value = 0
	else:
		time_text.visible = true
		if last_time.time_left > 1:
			time_text.text = str(snapped(last_time.time_left,1))
		else:
			time_text.text = str(snapped(last_time.time_left,0.1))
		pic_box.value = last_time.time_left / float(MaxTime)

func _on_last_time_timeout() -> void:
	MaxTime = 0


func _on_mouse_entered() -> void:
	pass
