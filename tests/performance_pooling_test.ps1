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

function Get-FunctionBody([string]$Text, [string]$FunctionName) {
	$pattern = "(?ms)^func\s+$([regex]::Escape($FunctionName))\b.*?(?=^func\s+|\z)"
	$match = [regex]::Match($Text, $pattern)
	if (-not $match.Success) {
		throw "Missing function: $FunctionName"
	}
	return $match.Value
}

$poolManager = Read-TextFile "PoolManager.gd"
$global = Read-TextFile "Global.gd"
$damageText = Read-TextFile "Script/Hittext/DamageText.gd"
$missEffect = Read-TextFile "Script/Hittext/MissEffect.gd"
$specialAffect = Read-TextFile "Script/Base/special_affect.gd"
$monsterBeHit = Read-TextFile "Scene/MonsterDamage/monster_be_hit.gd"

Assert-Contains $poolManager "var scene_cache" "PoolManager should cache PackedScene resources by path."
Assert-Contains $poolManager "const DEFAULT_MAX_POOL_SIZE" "PoolManager should cap pooled instances."
Assert-Contains $poolManager "func get_instance(scene_path: String) -> Node:" "PoolManager should expose get_instance(scene_path)."
Assert-Contains $poolManager "func recycle_instance(scene_path: String, instance: Node)" "PoolManager should expose recycle_instance(scene_path, instance)."

$recycleBody = Get-FunctionBody $poolManager "recycle_instance"
Assert-Contains $recycleBody "instance.get_parent().remove_child(instance)" "PoolManager recycle should detach the node from its parent."
Assert-Contains $recycleBody "instance.reset_for_pool()" "PoolManager recycle should call reset_for_pool when available."
Assert-Contains $recycleBody "instance.hide()" "PoolManager recycle should hide pooled nodes."
Assert-Contains $recycleBody "pools[scene_path].append(instance)" "PoolManager recycle should append reusable nodes back into the pool."
Assert-NotContains $recycleBody "instance.queue_free()" "PoolManager recycle must not queue_free before storing an instance."

foreach ($functionName in @("addMissEffect", "addDamageText", "add_SpecialEffect", "add_mr_hurt")) {
	$body = Get-FunctionBody $global $functionName
	Assert-Contains $body "PoolManager.get_instance(" "Global.$functionName should fetch high-frequency visual nodes from PoolManager."
	Assert-Contains $body "parent.add_child(target)" "Global.$functionName should attach pooled nodes to the requested parent."
}

Assert-Contains $damageText "const POOL_SCENE_PATH := `"res://Scene/hittest/DamageText.tscn`"" "DamageText should define its pool scene path."
Assert-Contains $damageText "func reset_for_pool() -> void:" "DamageText should reset state before reuse."
Assert-Contains $damageText "func recycle_to_pool() -> void:" "DamageText should recycle after animation."
Assert-Contains $damageText "PoolManager.recycle_instance(POOL_SCENE_PATH, self)" "DamageText should return itself to PoolManager."

Assert-Contains $missEffect "const POOL_SCENE_PATH := `"res://Scene/hittest/miss_effect.tscn`"" "MissEffect should define its pool scene path."
Assert-Contains $missEffect "func reset_for_pool() -> void:" "MissEffect should reset state before reuse."
Assert-Contains $missEffect "func recycle_to_pool() -> void:" "MissEffect should recycle after animation."
Assert-Contains $missEffect "PoolManager.recycle_instance(POOL_SCENE_PATH, self)" "MissEffect should return itself to PoolManager."

Assert-Contains $specialAffect "const POOL_SCENE_PATH := `"res://Scene/Base/special_affect.tscn`"" "special_affect should define its pool scene path."
Assert-Contains $specialAffect "func reset_for_pool() -> void:" "special_affect should reset state before reuse."
Assert-Contains $specialAffect "func recycle_to_pool() -> void:" "special_affect should recycle after animation."
Assert-Contains $specialAffect "PoolManager.recycle_instance(POOL_SCENE_PATH, self)" "special_affect should return itself to PoolManager."

Assert-Contains $monsterBeHit "const POOL_SCENE_PATH := `"res://Scene/MonsterDamage/monster_be_hit.tscn`"" "monster_be_hit should define its pool scene path."
Assert-Contains $monsterBeHit "func reset_for_pool() -> void:" "monster_be_hit should reset state before reuse."
Assert-Contains $monsterBeHit "func recycle_to_pool() -> void:" "monster_be_hit should recycle after animation."
Assert-Contains $monsterBeHit "PoolManager.recycle_instance(POOL_SCENE_PATH, self)" "monster_be_hit should return itself to PoolManager."
Assert-NotContains $monsterBeHit "`n`tqueue_free()" "monster_be_hit should not directly queue_free after animation."

Write-Host "Performance pooling hooks are present."
