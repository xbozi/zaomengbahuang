$ErrorActionPreference = "Stop"

function Read-TextFile([string]$Path) {
	if (-not (Test-Path $Path)) {
		throw "Missing file: $Path"
	}
	return Get-Content -Raw -Encoding UTF8 $Path
}

function Assert-Contains([string]$Text, [string]$Needle, [string]$Message) {
	if (-not $Text.Contains($Needle)) {
		throw $Message
	}
}

function Assert-NotContains([string]$Text, [string]$Needle, [string]$Message) {
	if ($Text.Contains($Needle)) {
		throw $Message
	}
}

$damageNumber = Read-TextFile "Script/Hittext/DamageNumber.gd"
$magicWeaponSkillCd = Read-TextFile "Script/MagicWeapon/MagicWeaponSkillCd.gd"
$basicCreateMonster = Read-TextFile "Script/Base/BasicCreateMonster.gd"

Assert-Contains $damageNumber "func get_number_texture(texture_path: String) -> Texture2D:" "DamageNumber should load number textures through a cached helper."
Assert-Contains $damageNumber "Global.get_cached_resource(texture_path)" "DamageNumber should use Global resource cache for number textures."
Assert-NotContains $damageNumber "set_texture(load(" "DamageNumber should not load textures directly when assigning number sprites."

Assert-Contains $magicWeaponSkillCd "var cached_skill_name := `"`"" "MagicWeaponSkillCd should track the last loaded skill name."
Assert-Contains $magicWeaponSkillCd "var cached_is_zhenfa := false" "MagicWeaponSkillCd should track the last loaded icon type."
Assert-Contains $magicWeaponSkillCd "func update_skill_icon_if_needed() -> void:" "MagicWeaponSkillCd should isolate icon loading behind a cache check."
Assert-Contains $magicWeaponSkillCd "Global.get_cached_resource(icon_path)" "MagicWeaponSkillCd should use Global resource cache for icons."
Assert-NotContains $magicWeaponSkillCd "skillicon.texture = load(" "MagicWeaponSkillCd should not load skillicon texture every frame."
Assert-NotContains $magicWeaponSkillCd "pic_box.texture_progress = load(" "MagicWeaponSkillCd should not load cooldown texture every frame."

Assert-Contains $basicCreateMonster "const MONSTER_CREATE_CHECK_INTERVAL := 0.15" "BasicCreateMonster should define a throttled check interval."
Assert-Contains $basicCreateMonster "var monster_create_check_left := 0.0" "BasicCreateMonster should track remaining time before next spawn check."
Assert-Contains $basicCreateMonster "monster_create_check_left -= delta" "BasicCreateMonster should decrement the throttled check timer."
Assert-Contains $basicCreateMonster "BaseLevel_.monster.get_child_count()" "BasicCreateMonster should use get_child_count instead of allocating get_children arrays."
Assert-Contains $basicCreateMonster "create_monster.is_stopped()" "BasicCreateMonster should avoid restarting an active spawn timer."
Assert-NotContains $basicCreateMonster "BaseLevel_.monster.get_children().size()" "BasicCreateMonster should not count monsters via get_children().size()."

Write-Host "Stage 3 performance optimization hooks are present."
