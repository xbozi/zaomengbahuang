extends Node2D
const MONSTER_CREATE_CHECK_INTERVAL := 0.15

var BaseLevel_: BaseLevel
@onready var create_monster: Timer = $CreateMonster

@export var MonsterIdList: Array[int]
@export var MonsterPosition: Array[Vector2]
@export var Id: int = 1
@export var Stage: int = 1
var CreateInter: float = 1.2
var CanCreate: bool = false
var CanChcek: bool
var monster_create_check_left := 0.0

func _physics_process(delta: float) -> void:
	monster_create_check_left -= delta
	if monster_create_check_left > 0.0:
		return
	monster_create_check_left = MONSTER_CREATE_CHECK_INTERVAL
	var monster_count := BaseLevel_.monster.get_child_count()
	if monster_count > 4 and monster_count < 6:
		CanChcek = true
	elif monster_count < 4:
		CanCreate = true
	if CanChcek:
		Check()
		CanChcek = false
	if CanCreate:
		if create_monster.is_stopped():
			create_monster.start(CreateInter)
		CanCreate = false
func Check():
	match Stage:
		1:
			for i in BaseLevel_.create_1.get_children():
				if i.Id > Id:
					return
		2:
			for i in BaseLevel_.create_1.get_children():
				if i.Id > Id:
					return
		3:
			for i in BaseLevel_.create_1.get_children():
				if i.Id > Id:
					return
		4:
			for i in BaseLevel_.create_1.get_children():
				if i.Id > Id:
					return
	CanCreate = true
func CreateMonster(Id: int,Po: Vector2):
	Global.Create_Monster(Id,BaseLevel_.monster,Po)


func _on_create_monster_timeout() -> void:
	CreateMonster(MonsterIdList[0],MonsterPosition[0])
	MonsterIdList.remove_at(0)
	MonsterPosition.remove_at(0)
