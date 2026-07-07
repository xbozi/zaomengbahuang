extends Button
var MyName: String
var MyFather
@onready var role_name: Label = $RoleName


func _physics_process(delta: float) -> void:
	var icon_name = MyName
	if MyName == "yte":
		icon_name = "xbl"
	self.set_button_icon(load("res://Art/MainGame/ChoosePlayer/" + str(icon_name) + ".png"))
	match MyName:
		"swk":
			role_name.text = "孙悟空"
		"zbj":
			role_name.text = "猪八戒"
		"tsz":
			role_name.text = "唐三藏"
		"swj":
			role_name.text = "沙悟净"
		"xbl":
			role_name.text = "小白龙"
		"yte":
			role_name.text = "玉兔儿"
	set_physics_process(false)



func _on_pressed() -> void:
	match MyName:
		"swk":
			MyFather.CurrentChoose = 1
			MyFather.AddStar(1)
		"zbj":
			MyFather.CurrentChoose = 3
			MyFather.AddStar(3)
		"tsz":
			MyFather.CurrentChoose = 2
			MyFather.AddStar(2)
		"swj":
			MyFather.CurrentChoose = 4
			MyFather.AddStar(4)
		"xbl":
			MyFather.CurrentChoose = 5
			MyFather.AddStar(5)
		"yte":
			MyFather.CurrentChoose = 6
			MyFather.AddStar(6)
	MyFather.SetRole()
