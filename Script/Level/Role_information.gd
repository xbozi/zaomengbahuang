extends Node2D
const MOBILE_ROLE_MENU_TOP_OFFSET := 128.0
const MOBILE_ROLE_MENU_TOGGLE_TOP_OFFSET := 88.0
const MOBILE_ROLE_MENU_BUTTON_GAP := 8.0
const MOBILE_ROLE_MENU_TOGGLE_SIZE := Vector2(68.0, 32.0)
const ROLE_INFO_SKILL_REFRESH_INTERVAL := 0.25
@onready var role_head: Sprite2D = $roleLayer/role_head

@onready var role_level: Label = $roleLayer/role_hp_mp_exp/role_level
@onready var gogo: AnimatedSprite2D = $roleLayer/Gogo
@onready var role_layer: CanvasLayer = $roleLayer
@onready var role_menu: Sprite2D = $roleLayer/role_menu
@onready var role_menu_backpack: TextureButton = $roleLayer/role_menu/backpack
@onready var role_menu_set: TextureButton = $roleLayer/role_menu/set
@onready var role_menu_skill: TextureButton = $roleLayer/role_menu/skill
@onready var role_menu_magic_weapon: TextureButton = $roleLayer/role_menu/magic_weapon
@onready var role_menu_pet: TextureButton = $roleLayer/role_menu/pet
@onready var ws_effect: TextureProgressBar = $roleLayer/role_menu/ws_wk/ws_effect
@onready var max_ws: AnimatedSprite2D = $roleLayer/role_menu/max_ws
@onready var SkillBox: HBoxContainer = $roleLayer/role_menu/SkillBox
@onready var zhen_fa: TextureRect = $roleLayer/role_menu/SkillBox2/ZhenFa

@onready var hp_bar: TextureProgressBar = $roleLayer/role_hp_mp_exp/hp_bar
@onready var hp_text: Label = $roleLayer/role_hp_mp_exp/hp_bar/hp_text
@onready var mp_bar: TextureProgressBar = $roleLayer/role_hp_mp_exp/mp_bar
@onready var mp_text: Label = $roleLayer/role_hp_mp_exp/mp_bar/mp_text
@onready var exp_bar: TextureProgressBar = $roleLayer/role_hp_mp_exp/exp_bar
@onready var exp_text: Label = $roleLayer/role_hp_mp_exp/exp_bar/exp_text
@onready var nature_recovery_mp: Label = $roleLayer/role_hp_mp_exp/mp_bar/nature_recovery_mp
@onready var nature_recovery_hp: Label = $roleLayer/role_hp_mp_exp/hp_bar/nature_recovery_hp
@onready var grey: Sprite2D = $roleLayer/role_menu/grey
@onready var add_effect = $roleLayer/AddMyEffect
@onready var buff_box: HBoxContainer = $roleLayer/role_hp_mp_exp/Buff_box
@onready var role_protect: TextureProgressBar = $roleLayer/role_hp_mp_exp/RoleProtect
@onready var magic_weapon_skill_cd: TextureRect = $roleLayer/role_menu/SkillBox/MagicWeaponSkillCD


var Hp_Change:
	set(a):
		Hp_Change = a
		set_value_Hp(Hp_Change)
var buff_mpo
var buff_po
var buff_ice
var buff_speed_down
var buff_is_stun
var buff_is_Fire
var buff_is_Bleed
var Player: BaseHero
var role_menu_default_position := Vector2.ZERO
var role_menu_default_texture: Texture2D
var role_menu_button_default_offsets: Dictionary = {}
var mobile_role_menu_toggle: Button
var mobile_role_menu_collapsed := false
var role_info_skill_refresh_left := 0.0
var cached_magic_weapon_name = null
var cached_zhen_fa_name = null
var cached_hp_ratio := -1.0
var cached_mp_ratio := -1.0
var cached_exp_ratio := -1.0
var cached_ws_ratio := -1.0
var cached_role_protect_ratio := -1.0
var cached_role_level_text := ""
var cached_hp_text := ""
var cached_mp_text := ""
var cached_exp_text := ""
var cached_nature_recovery_hp := ""
var cached_nature_recovery_mp := ""
var cached_max_ws_visible = null

func get_role_menu_buttons() -> Array:
	return [role_menu_backpack, role_menu_set, role_menu_skill, role_menu_magic_weapon, role_menu_pet]

func capture_role_menu_defaults() -> void:
	role_menu_default_position = role_menu.position
	role_menu_default_texture = role_menu.texture
	role_menu_button_default_offsets.clear()
	for button in get_role_menu_buttons():
		role_menu_button_default_offsets[button.name] = button.position

func apply_role_menu_layout() -> void:
	if OS.has_feature("android"):
		ensure_mobile_role_menu_toggle()
		apply_mobile_role_menu_backdrop()
		layout_mobile_role_menu_top_center()
		apply_mobile_role_menu_visibility()
	else:
		restore_role_menu_backdrop()
		restore_role_menu_default_layout()
		if mobile_role_menu_toggle != null:
			mobile_role_menu_toggle.visible = false

func apply_mobile_role_menu_backdrop() -> void:
	role_menu.texture = null

func restore_role_menu_backdrop() -> void:
	role_menu.texture = role_menu_default_texture

func ensure_mobile_role_menu_toggle() -> void:
	if mobile_role_menu_toggle != null and is_instance_valid(mobile_role_menu_toggle):
		return
	mobile_role_menu_toggle = Button.new()
	mobile_role_menu_toggle.name = "MobileRoleMenuToggle"
	mobile_role_menu_toggle.custom_minimum_size = MOBILE_ROLE_MENU_TOGGLE_SIZE
	mobile_role_menu_toggle.size = MOBILE_ROLE_MENU_TOGGLE_SIZE
	mobile_role_menu_toggle.focus_mode = Control.FOCUS_NONE
	mobile_role_menu_toggle.process_mode = Node.PROCESS_MODE_ALWAYS
	mobile_role_menu_toggle.pressed.connect(_on_mobile_role_menu_toggle_pressed)
	role_layer.add_child(mobile_role_menu_toggle)

func _on_mobile_role_menu_toggle_pressed() -> void:
	mobile_role_menu_collapsed = not mobile_role_menu_collapsed
	apply_mobile_role_menu_visibility()
	apply_role_menu_layout()

func apply_mobile_role_menu_visibility() -> void:
	for button in get_role_menu_buttons():
		button.visible = not mobile_role_menu_collapsed
	if mobile_role_menu_toggle != null:
		mobile_role_menu_toggle.visible = true
		mobile_role_menu_toggle.text = "菜单" if mobile_role_menu_collapsed else "收起"

func layout_mobile_role_menu_toggle(safe_rect: Rect2) -> void:
	if mobile_role_menu_toggle == null:
		return
	mobile_role_menu_toggle.size = MOBILE_ROLE_MENU_TOGGLE_SIZE
	mobile_role_menu_toggle.position = Vector2(
		safe_rect.position.x + (safe_rect.size.x - MOBILE_ROLE_MENU_TOGGLE_SIZE.x) * 0.5,
		safe_rect.position.y + MOBILE_ROLE_MENU_TOGGLE_TOP_OFFSET - MOBILE_ROLE_MENU_TOGGLE_SIZE.y * 0.5
	)

func restore_role_menu_default_layout() -> void:
	role_menu.position = role_menu_default_position
	for button in get_role_menu_buttons():
		button.visible = true
		if role_menu_button_default_offsets.has(button.name):
			button.position = role_menu_button_default_offsets[button.name]

func layout_mobile_role_menu_top_center() -> void:
	var safe_rect := ScreenFit.safe_fit_rect()
	layout_mobile_role_menu_toggle(safe_rect)
	var buttons := get_role_menu_buttons()
	if buttons.is_empty():
		return
	var button_width_sum := 0.0
	for button in buttons:
		button_width_sum += get_role_menu_button_size(button).x
	var total_width := button_width_sum + MOBILE_ROLE_MENU_BUTTON_GAP * float(buttons.size() - 1)
	var cursor_x := safe_rect.position.x + (safe_rect.size.x - total_width) * 0.5
	var center_y := safe_rect.position.y + MOBILE_ROLE_MENU_TOP_OFFSET
	for button in buttons:
		var button_size := get_role_menu_button_size(button)
		var desired_position := Vector2(cursor_x, center_y - button_size.y * 0.5)
		button.position = desired_position - role_menu.position
		cursor_x += button_size.x + MOBILE_ROLE_MENU_BUTTON_GAP

func get_role_menu_button_size(button: TextureButton) -> Vector2:
	var button_size := button.size
	if button_size.x <= 0.0:
		button_size.x = 47.0
	if button_size.y <= 0.0:
		button_size.y = 40.0
	return button_size

func update_skill_pic_if_needed(delta: float) -> void:
	role_info_skill_refresh_left -= delta
	if role_info_skill_refresh_left > 0.0:
		return
	role_info_skill_refresh_left = ROLE_INFO_SKILL_REFRESH_INTERVAL
	set_skill_pic()

func update_role_info_ui() -> void:
	var magic_weapon_name = PlayerData.player_data["实战法宝"]
	var has_magic_weapon := magic_weapon_name != "" and PlayerData.player_data["法宝"].size() > 0
	if cached_magic_weapon_name != magic_weapon_name:
		cached_magic_weapon_name = magic_weapon_name
		magic_weapon_skill_cd.SkillName = magic_weapon_name
	if magic_weapon_skill_cd.visible != has_magic_weapon:
		magic_weapon_skill_cd.visible = has_magic_weapon

	var zhen_fa_name = PlayerData.player_data["已佩戴阵法"]
	var has_zhen_fa := zhen_fa_name != ""
	if cached_zhen_fa_name != zhen_fa_name:
		cached_zhen_fa_name = zhen_fa_name
		zhen_fa.SkillName = zhen_fa_name
	zhen_fa.Iszhenfa = true
	if zhen_fa.visible != has_zhen_fa:
		zhen_fa.visible = has_zhen_fa

	var next_nature_recovery_hp := ""
	if Player != null and RoleProp.roleprop.Hp < RoleProp.roleprop.SHp and RoleProp.roleprop.R_hp > 0:
		next_nature_recovery_hp = "+" + str(float(RoleProp.roleprop.R_hp)) + "/s * " + str(Player.CureValue)
	if cached_nature_recovery_hp != next_nature_recovery_hp:
		cached_nature_recovery_hp = next_nature_recovery_hp
		nature_recovery_hp.text = next_nature_recovery_hp

	var next_nature_recovery_mp := ""
	if RoleProp.roleprop.Mp < RoleProp.roleprop.SMp and RoleProp.roleprop.R_mp > 0:
		next_nature_recovery_mp = "+" + str(float(RoleProp.roleprop.R_mp)) + "/s"
	if cached_nature_recovery_mp != next_nature_recovery_mp:
		cached_nature_recovery_mp = next_nature_recovery_mp
		nature_recovery_mp.text = next_nature_recovery_mp

	var next_hp_ratio := float(RoleProp.roleprop.Hp) / RoleProp.roleprop.SHp
	if cached_hp_ratio != next_hp_ratio:
		cached_hp_ratio = next_hp_ratio
		Hp_Change = next_hp_ratio
		hp_bar.value = next_hp_ratio

	var next_mp_ratio := float(RoleProp.roleprop.Mp) / RoleProp.roleprop.SMp
	if cached_mp_ratio != next_mp_ratio:
		cached_mp_ratio = next_mp_ratio
		mp_bar.value = next_mp_ratio

	var next_exp_ratio := float(RoleProp.baseroleprop.exp) / RoleProp.baseroleprop.max_exp
	if cached_exp_ratio != next_exp_ratio:
		cached_exp_ratio = next_exp_ratio
		exp_bar.value = next_exp_ratio

	var next_role_level_text := str(RoleProp.baseroleprop.Level)
	if cached_role_level_text != next_role_level_text:
		cached_role_level_text = next_role_level_text
		role_level.text = next_role_level_text

	var next_hp_text := str(int(RoleProp.roleprop.Hp)) + '/' + str(int(RoleProp.roleprop.SHp))
	if cached_hp_text != next_hp_text:
		cached_hp_text = next_hp_text
		hp_text.text = next_hp_text

	var next_mp_text := str(int(RoleProp.roleprop.Mp)) + '/' + str(int(RoleProp.roleprop.SMp))
	if cached_mp_text != next_mp_text:
		cached_mp_text = next_mp_text
		mp_text.text = next_mp_text

	var next_exp_text := str(RoleProp.baseroleprop.exp) + '/' + str(RoleProp.baseroleprop.max_exp)
	if cached_exp_text != next_exp_text:
		cached_exp_text = next_exp_text
		exp_text.text = next_exp_text

	var next_ws_ratio := float(RoleProp.ws_value) /  RoleProp.max_ws_value
	if cached_ws_ratio != next_ws_ratio:
		cached_ws_ratio = next_ws_ratio
		ws_effect.value = next_ws_ratio

	var next_max_ws_visible := ws_effect.value >= 1 and not RoleProp.is_ws_state
	if cached_max_ws_visible != next_max_ws_visible:
		cached_max_ws_visible = next_max_ws_visible
		max_ws.visible = next_max_ws_visible

	if Player != null:
		var next_role_protect_ratio := float(Player.CurrentProtect) / float(Player.MaxProtect)
		if cached_role_protect_ratio != next_role_protect_ratio:
			cached_role_protect_ratio = next_role_protect_ratio
			role_protect.value = next_role_protect_ratio

func _ready() -> void:
	capture_role_menu_defaults()
	apply_role_menu_layout()
	var resize_callback := Callable(self, "apply_role_menu_layout")
	if not get_viewport().size_changed.is_connected(resize_callback):
		get_viewport().size_changed.connect(resize_callback)
	Global.MgCdPic = magic_weapon_skill_cd
	Global.zhen_fa = zhen_fa
	match int(PlayerData.player_data["Myself"]):
		1:
			role_head.texture = load("res://Art/HeroPicture/RoleProperiesBox/swk.png")
		2:
			role_head.texture = load("res://Art/HeroPicture/RoleProperiesBox/tsz.png")
		3:
			role_head.texture = load("res://Art/HeroPicture/RoleProperiesBox/zbj.png")
		4:
			role_head.texture = load("res://Art/HeroPicture/RoleProperiesBox/shs.png")
		5:
			role_head.texture = load("res://Art/HeroPicture/RoleProperiesBox/blm.png")
func _physics_process(delta: float) -> void:
	for i in Global.AllBuffList:
		SetBuffIconInfo(i)
	if get_parent().Role_ != null:
		Player = get_parent().Role_ as BaseHero
	update_skill_pic_if_needed(delta)
	update_role_info_ui()
func is_full_ws():
	return max_ws.visible == true and not RoleProp.is_ws_state
func set_skill_pic():
	for i in SkillBox.get_children():
		if i != null:
			if not i is mgcd:
				var Name = str(i.name)
				var Tar = PlayerData.player_data["技能学习"]["技能键位"][Name]
				if Tar != "":
					i.SkillName = Tar
				else:
					i.SkillName = "Empty"
func set_value_Hp(value):
	if not MainSet.set_data["HpBarDelay"]:
		$roleLayer/role_hp_mp_exp/hp_bar/hp_bar2.value = 0
		return
	create_tween().tween_property($roleLayer/role_hp_mp_exp/hp_bar/hp_bar2,"value",value,0.6)
func SetBuffIconInfo(Name):
	var IsHave: bool#是否拥有
	var Count: int = 1#拥有个数
	var BuffInfo = {
		"Name": Name,
		"value": 0.0,#伤害值
		"AddTime": 0.0,#添加时间
		"ReduceInterval": 0.0,#扣除伤害间隔
		"AttackKind": "",#伤害类型
		"HaveCount": 0,#拥有次数
	}
	for i in RoleProp.SourcePlayer.buff.get_children():
		for u in i.BuffInfo:
			if not BuffInfo.has(u):
				BuffInfo[u] = i.BuffInfo[u]
		if i.BuffInfo["Name"] == Name:
			IsHave = true
			BuffInfo["HaveCount"] += 1
			if i.BuffInfo.has("CanAdd"):
				if i.BuffInfo["CanAdd"]:
					BuffInfo["value"] += i.BuffInfo["value"]
				else:
					BuffInfo["value"] = i.BuffInfo["value"]
			else:
				BuffInfo["value"] += i.BuffInfo["value"]
			if i.BuffInfo.has("ReduceInterval"):
				BuffInfo["ReduceInterval"] = i.BuffInfo["ReduceInterval"]
			if not i.IsCheck:	
				BuffInfo["AttackKind"] = i.BuffInfo["AttackKind"]
				if i.BuffInfo.has("ReduceInterval"):
					BuffInfo["ReduceInterval"] = i.BuffInfo["ReduceInterval"]
				BuffInfo["AddTime"] = i.BuffInfo["AddTime"]
				buff_box.get_node(Name).buff_icon_remove.start(BuffInfo["AddTime"])
				buff_box.get_node(Name).DataList = BuffInfo
				i.IsCheck = true
			buff_box.get_node(Name).DataList = BuffInfo
	buff_box.get_node(Name).visible = IsHave
