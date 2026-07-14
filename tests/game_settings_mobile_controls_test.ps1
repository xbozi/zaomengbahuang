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

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$mainSet = Read-Utf8File (Join-Path $projectRoot "Script\MemoryClass\main_set.gd")
$gameSet = Read-Utf8File (Join-Path $projectRoot "Script\Main_menu\GameSet.gd")
$gameSetScene = Read-Utf8File (Join-Path $projectRoot "Scene\Main_menu\GameSet.tscn")
$baseThroughLevel = Read-Utf8File (Join-Path $projectRoot "Script\Base\BaseThroughLevel.gd")

if (-not $mainSet.Contains('"MobileControlsShow": false')) {
    throw 'main_set.gd must default "MobileControlsShow" to false.'
}

Require-Tokens -Source $gameSet -Label "GameSet.gd" -Tokens @(
    "mobile_controls_open_or_close",
    "MobileControlsShow",
    "_on_mobile_controls_open_or_close_pressed",
    "MemoryClass.main_bc()",
    'OS.has_feature("android")',
    "mobile_controls_open_or_close.disabled = true"
)

$toggleFunctionPattern = '(?ms)^func\s+_on_mobile_controls_open_or_close_pressed\(\)\s*->\s*void[^\r\n]*\r?\n(?<Body>.*?)(?=^func\s+|\z)'
$toggleFunctionMatch = [regex]::Match($gameSet, $toggleFunctionPattern)
if (-not $toggleFunctionMatch.Success) {
    throw "GameSet.gd must define _on_mobile_controls_open_or_close_pressed()."
}

Require-Tokens -Source $toggleFunctionMatch.Groups["Body"].Value -Label "_on_mobile_controls_open_or_close_pressed()" -Tokens @(
    'MainSet.set_data["MobileControlsShow"] = not MainSet.set_data["MobileControlsShow"]',
    "MemoryClass.main_bc()"
)

$automaticOpen = -join @([char]0x81EA, [char]0x52A8, [char]0x5F00, [char]0x542F)
$automaticOpenToken = 'mobile_controls_open_or_close.text = "' + $automaticOpen + '"'
if (-not $gameSet.Contains($automaticOpenToken)) {
    throw "GameSet.gd is missing required token: $automaticOpenToken"
}

$androidGuardPattern = '(?m)^\s*if\s+OS\.has_feature\("android"\)\s*:\s*\r?\n\s+return\b'
if ($gameSet -notmatch $androidGuardPattern) {
    throw "GameSet.gd must guard the mobile controls toggle on Android and return."
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

if (-not $baseThroughLevel.Contains('MainSet.set_data["MobileControlsShow"]')) {
    throw 'BaseThroughLevel.gd must read MainSet.set_data["MobileControlsShow"].'
}

Write-Host "Game settings mobile controls toggle is wired."