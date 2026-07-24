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

$learnSkill = Read-TextFile "Script/Skill/Learn_skill.gd"

Assert-Contains $learnSkill '@onready var fullscreen_mask: ColorRect = $fengeceng' "Learn_skill should reference the fullscreen mask."
Assert-Contains $learnSkill '@onready var bg: Sprite2D = $bg' "Learn_skill should reference the main background panel."
Assert-Contains $learnSkill "var hidden_mobile_controls: Array = []" "Learn_skill should remember hidden mobile controls."
Assert-Contains $learnSkill "func apply_mobile_layout() -> void:" "Learn_skill should apply mobile layout on open."
Assert-Contains $learnSkill "ScreenFit.TARGET_VIEWPORT_SIZE" "Learn_skill should size itself against the target mobile viewport."
Assert-Contains $learnSkill "fullscreen_mask.size = ScreenFit.TARGET_VIEWPORT_SIZE" "Learn_skill mask should cover the whole target viewport."
Assert-Contains $learnSkill "bg.position = ScreenFit.TARGET_VIEWPORT_SIZE * 0.5" "Learn_skill panel should be centered in the target viewport."
Assert-Contains $learnSkill "func hide_mobile_controls() -> void:" "Learn_skill should hide mobile controls while open."
Assert-Contains $learnSkill 'find_children("MobileControls"' "Learn_skill should locate MobileControls nodes."
Assert-Contains $learnSkill "mobile_controls.visible = false" "Learn_skill should hide MobileControls."
Assert-Contains $learnSkill "func restore_mobile_controls() -> void:" "Learn_skill should restore hidden mobile controls."
Assert-Contains $learnSkill "mobile_controls.visible = true" "Learn_skill should make hidden MobileControls visible again."
Assert-Contains $learnSkill "func _exit_tree() -> void:" "Learn_skill should restore controls when closed by any path."
Assert-Contains $learnSkill "restore_mobile_controls()" "Learn_skill should call restore_mobile_controls when exiting."

Write-Host "Learn skill mobile layout hooks are present."
