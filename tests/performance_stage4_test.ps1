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

$baseThroughLevel = Read-TextFile "Script/Base/BaseThroughLevel.gd"
$roleInformation = Read-TextFile "Script/Level/Role_information.gd"

Assert-Contains $baseThroughLevel "const LEVEL_STATUS_CHECK_INTERVAL := 0.15" "BaseThroughLevel should define a throttled status check interval."
Assert-Contains $baseThroughLevel "var level_status_check_left := 0.0" "BaseThroughLevel should track remaining time before level status checks."
Assert-Contains $baseThroughLevel "var cached_camera_stage := -1" "BaseThroughLevel should remember the stage used for camera bounds."
Assert-Contains $baseThroughLevel "var cached_camera_can_pass := false" "BaseThroughLevel should remember whether camera bounds were last updated after a pass check."
Assert-Contains $baseThroughLevel "func update_level_status_if_needed(delta: float) -> void:" "BaseThroughLevel should move exit/camera polling into a throttled helper."
Assert-Contains $baseThroughLevel "func update_exit_state() -> void:" "BaseThroughLevel should isolate exit visibility checks."
Assert-Contains $baseThroughLevel "func update_camera_bounds_if_needed() -> void:" "BaseThroughLevel should only update camera bounds when needed."
Assert-Contains $baseThroughLevel "func check_can_pass() -> bool:" "BaseThroughLevel should type check_can_pass so callers can infer bool results."
Assert-Contains $baseThroughLevel "level_status_check_left -= delta" "BaseThroughLevel should decrement the throttled status check timer."
Assert-Contains $baseThroughLevel "var next_camera_can_pass := check_can_pass()" "BaseThroughLevel should update camera bounds when monsters are cleared in the current stage."

$cameraBoundsBody = Get-FunctionBody $baseThroughLevel "update_camera_bounds_if_needed"
Assert-Contains $cameraBoundsBody "if current_stage < 1:" "BaseThroughLevel should not check stage dictionaries before the first stage is selected."
Assert-Contains $cameraBoundsBody "return" "BaseThroughLevel should return early when camera bounds cannot be updated."

$canCreateBody = Get-FunctionBody $baseThroughLevel "check_can_create"
Assert-Contains $canCreateBody 'var stage_key: String = "stage_" + str(stage)' "BaseThroughLevel should build stage keys once before dictionary checks."
Assert-Contains $canCreateBody "if stage < 1 or not Monster_group.has(stage_key):" "BaseThroughLevel should not create monsters from missing stage dictionaries."

$canPassBody = Get-FunctionBody $baseThroughLevel "check_can_pass"
Assert-Contains $canPassBody 'var stage_key: String = "stage_" + str(current_stage)' "BaseThroughLevel should build current stage keys once before pass checks."
Assert-Contains $canPassBody "if current_stage < 1 or not Monster_group.has(stage_key):" "BaseThroughLevel should not check pass state from missing stage dictionaries."

$physicsBody = Get-FunctionBody $baseThroughLevel "_physics_process"
Assert-Contains $physicsBody "update_level_status_if_needed(_delta)" "BaseThroughLevel physics process should call the throttled status helper."
Assert-NotContains $physicsBody "change_mysee()" "BaseThroughLevel physics process should not update camera bounds every frame."
Assert-NotContains $physicsBody "check_can_exit()" "BaseThroughLevel physics process should not check level exit every frame."
Assert-NotContains $physicsBody "one_check_can_exit()" "BaseThroughLevel physics process should not check single-scene exit every frame."

Assert-Contains $roleInformation "const ROLE_INFO_BUFF_REFRESH_INTERVAL := 0.2" "Role_information should define a throttled buff refresh interval."
Assert-Contains $roleInformation "var role_info_buff_refresh_left := 0.0" "Role_information should track remaining time before buff UI refresh."
Assert-Contains $roleInformation "func update_buff_icons_if_needed(delta: float) -> void:" "Role_information should move buff icon aggregation into a throttled helper."
Assert-Contains $roleInformation "role_info_buff_refresh_left -= delta" "Role_information should decrement the buff refresh timer."
Assert-Contains $roleInformation "var has_magic_weapon: bool =" "Role_information should type has_magic_weapon because player data dictionary access is Variant."

$rolePhysicsBody = Get-FunctionBody $roleInformation "_physics_process"
Assert-Contains $rolePhysicsBody "update_buff_icons_if_needed(delta)" "Role_information physics process should call throttled buff icon refresh."
Assert-NotContains $rolePhysicsBody "for i in Global.AllBuffList" "Role_information physics process should not aggregate buff icons every frame."

Write-Host "Stage 4 performance optimization hooks are present."
