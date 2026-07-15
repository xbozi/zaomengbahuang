$ErrorActionPreference = "Stop"

function Read-Utf8File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file is missing: $Path"
    }

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    try {
        return $utf8.GetString($bytes)
    }
    catch {
        throw "File is not valid UTF-8: $Path"
    }
}

function Require-Tokens {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string[]]$Tokens,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    foreach ($token in $Tokens) {
        if (-not $Source.Contains($token)) {
            throw "$Label is missing required token: $token"
        }
    }
}

function Get-GdscriptFunctionBody {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $escapedName = [regex]::Escape($Name)
    $pattern = '(?ms)^func\s+' + $escapedName + '\s*\([^\r\n]*\)[^\r\n]*\r?\n(?<Body>.*?)(?=^func\s+|\z)'
    $match = [regex]::Match($Source, $pattern)
    if (-not $match.Success) {
        throw "$Label is missing required function: $Name"
    }

    return $match.Groups["Body"].Value
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$mainSet = Read-Utf8File (Join-Path $projectRoot "Script\MemoryClass\main_set.gd")
$gameSet = Read-Utf8File (Join-Path $projectRoot "Script\Main_menu\GameSet.gd")
$gameSetScene = Read-Utf8File (Join-Path $projectRoot "Scene\Main_menu\GameSet.tscn")
$baseThroughLevel = Read-Utf8File (Join-Path $projectRoot "Script\Base\BaseThroughLevel.gd")

if (-not $mainSet.Contains('"MobileControlsShow": false')) {
    throw 'main_set.gd must default "MobileControlsShow" to false.'
}

$toggleBody = Get-GdscriptFunctionBody -Source $gameSet -Name "_on_mobile_controls_open_or_close_pressed" -Label "GameSet.gd"
$toggleAssignment = 'MainSet.set_data["MobileControlsShow"] = not MainSet.set_data["MobileControlsShow"]'
Require-Tokens -Source $toggleBody -Label "_on_mobile_controls_open_or_close_pressed()" -Tokens @(
    $toggleAssignment,
    "MemoryClass.main_bc()"
)

$toggleGuardPattern = '(?m)^[ \t]*if\s+OS\.has_feature\("android"\)\s*:\s*\r?\n[ \t]+return\b'
$toggleGuardMatch = [regex]::Match($toggleBody, $toggleGuardPattern)
if (-not $toggleGuardMatch.Success) {
    throw "GameSet.gd _on_mobile_controls_open_or_close_pressed() must return when running on Android."
}
if ($toggleGuardMatch.Index -gt $toggleBody.IndexOf($toggleAssignment)) {
    throw "GameSet.gd Android guard must return before the mobile controls setting is changed."
}

$physicsBody = Get-GdscriptFunctionBody -Source $gameSet -Name "_physics_process" -Label "GameSet.gd"
$androidBranchPattern = '(?ms)^(?<Indent>[ \t]*)if\s+OS\.has_feature\("android"\)\s*:\s*\r?\n(?<Android>.*?)^\k<Indent>else\s*:\s*\r?\n(?<NonAndroid>.*?)(?=^\k<Indent>\S|\z)'
$androidBranchMatch = [regex]::Match($physicsBody, $androidBranchPattern)
if (-not $androidBranchMatch.Success) {
    throw "GameSet.gd _physics_process() must have Android and non-Android mobile controls branches."
}

$automaticOpen = -join @([char]0x81EA, [char]0x52A8, [char]0x5F00, [char]0x542F)
$automaticOpenToken = 'mobile_controls_open_or_close.text = "' + $automaticOpen + '"'
Require-Tokens -Source $androidBranchMatch.Groups["Android"].Value -Label "GameSet.gd _physics_process() Android branch" -Tokens @(
    $automaticOpenToken,
    "mobile_controls_open_or_close.disabled = true"
)

$enabledText = -join @([char]0x5F00, [char]0x542F, [char]0x4E2D)
$disabledText = -join @([char]0x5173, [char]0x95ED, [char]0x4E2D)
$nonAndroidBranch = $androidBranchMatch.Groups["NonAndroid"].Value
Require-Tokens -Source $nonAndroidBranch -Label "GameSet.gd _physics_process() non-Android branch" -Tokens @(
    "mobile_controls_open_or_close.disabled = false",
    'MainSet.set_data["MobileControlsShow"]'
)

$statusTextPattern = '(?ms)^[ \t]*if\s+MainSet\.set_data\["MobileControlsShow"\]\s*:\s*\r?\n[ \t]+mobile_controls_open_or_close\.text\s*=\s*"' + [regex]::Escape($enabledText) + '".*?^[ \t]*else\s*:\s*\r?\n[ \t]+mobile_controls_open_or_close\.text\s*=\s*"' + [regex]::Escape($disabledText) + '"'
if ($nonAndroidBranch -notmatch $statusTextPattern) {
    throw "GameSet.gd _physics_process() non-Android branch must show enabled and disabled mobile controls status text."
}
$mobileControlsLabelPattern = '(?m)^\[node\s+name="MobileControls"[^\r\n]*\btype="Label"[^\r\n]*\]'
if ($gameSetScene -notmatch $mobileControlsLabelPattern) {
    throw "GameSet.tscn must contain the MobileControls Label."
}

$mobileControlsButtonPattern = '(?m)^\[node\s+name="MobileControlsOpenOrClose"[^\r\n]*\btype="Button"[^\r\n]*\]'
if ($gameSetScene -notmatch $mobileControlsButtonPattern) {
    throw "GameSet.tscn must contain the MobileControlsOpenOrClose Button."
}

$mobileControlsText = -join @(
    [char]0x624B,
    [char]0x673A,
    [char]0x89E6,
    [char]0x63A7,
    [char]0x64CD,
    [char]0x4F5C,
    [char]0xFF1A
)
if (-not $gameSetScene.Contains('text = "' + $mobileControlsText + '"')) {
    throw "GameSet.tscn must label the mobile controls setting with the expected Chinese text."
}

$mobileControlsPressedConnection = '[connection signal="pressed" from="Bg/BGColor/VBoxContainer2/MobileControls/MobileControlsOpenOrClose" to="." method="_on_mobile_controls_open_or_close_pressed"]'
if (-not $gameSetScene.Contains($mobileControlsPressedConnection)) {
    throw "GameSet.tscn must connect the mobile controls toggle signal."
}

$addMobileControlsBody = Get-GdscriptFunctionBody -Source $baseThroughLevel -Name "add_mobile_controls" -Label "BaseThroughLevel.gd"
if (-not $addMobileControlsBody.Contains('MainSet.set_data["MobileControlsShow"]')) {
    throw 'BaseThroughLevel.gd add_mobile_controls() must read MainSet.set_data["MobileControlsShow"].'
}

Write-Host "Game settings mobile controls toggle is wired."