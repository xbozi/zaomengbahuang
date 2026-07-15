$ErrorActionPreference = "Stop"

function Read-Utf8File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$RejectBom
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file is missing: $Path"
    }

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($RejectBom -and $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "UTF-8 BOM is not allowed: $Path"
    }

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
$paths = @{
    MobileControls = Join-Path $projectRoot "Script\MobileControls\MobileControls.gd"
    MobileJoystick = Join-Path $projectRoot "Script\MobileControls\MobileJoystick.gd"
    MobileActionButton = Join-Path $projectRoot "Script\MobileControls\MobileActionButton.gd"
    MobileScene = Join-Path $projectRoot "Scene\MobileControls\MobileControls.tscn"
    BaseThroughLevel = Join-Path $projectRoot "Script\Base\BaseThroughLevel.gd"
    Level20 = Join-Path $projectRoot "Script\Level\Level_20.gd"
}

$mobileControls = Read-Utf8File -Path $paths.MobileControls -RejectBom
$mobileJoystick = Read-Utf8File -Path $paths.MobileJoystick -RejectBom
$mobileActionButton = Read-Utf8File -Path $paths.MobileActionButton -RejectBom
$mobileScene = Read-Utf8File -Path $paths.MobileScene -RejectBom
$baseThroughLevel = Read-Utf8File -Path $paths.BaseThroughLevel -RejectBom
$level20 = Read-Utf8File -Path $paths.Level20 -RejectBom

Require-Tokens -Source $mobileActionButton -Label "MobileActionButton.gd" -Tokens @(
    "extends TouchScreenButton",
    "CircleShape2D.new()",
    "draw_circle",
    "ThemeDB.fallback_font"
)

Require-Tokens -Source $mobileJoystick -Label "MobileJoystick.gd" -Tokens @(
    "extends Control",
    "InputEventScreenTouch",
    "InputEventScreenDrag",
    "make_canvas_position_local",
    "joystick_touch_index",
    "Input.action_press",
    "Input.action_release",
    "release_all_actions",
    '"move_left"',
    '"move_right"',
    '"down"',
    '"Exit"'
)

if ($mobileJoystick.Contains("to_local(")) {
    throw "MobileJoystick.gd extends Control and must not call the Node2D-only to_local() API."
}

Require-Tokens -Source $mobileControls -Label "MobileControls.gd" -Tokens @(
    "extends CanvasLayer",
    'OS.has_feature("android")',
    "force_show_mobile_controls",
    'MainSet.set_data["MobileControlsShow"]',
    "get_viewport().size_changed",
    "BUTTON_LAYOUT",
    "DisplayServer.get_display_safe_area()",
    "DisplayServer.screen_get_size()"
)

if ($mobileScene -match '(?m)^\[node[^\r\n]*\btype="Button"') {
    throw "MobileControls.tscn must not contain ordinary Button nodes."
}

$wushuang = -join @([char]0x65E0, [char]0x53CC)
$zhenfa = -join @([char]0x9635, [char]0x6CD5)
$expectedMappings = [ordered]@{
    Attack = "normalhit"
    Jump = "jump"
    Skill1 = "slz"
    Skill2 = "lys"
    Skill3 = "lyfb"
    Skill4 = "hmz"
    Skill5 = "hytj"
    Magic = "MagicWeapon"
    Wushuang = $wushuang
    Zhenfa = $zhenfa
}

foreach ($entry in $expectedMappings.GetEnumerator()) {
    $nodeName = [regex]::Escape($entry.Key)
    $nodePattern = '(?ms)^\[node\s+name="' + $nodeName + '"[^\r\n]*\btype="TouchScreenButton"[^\r\n]*\]\r?\n(.*?)(?=^\[node\s|\z)'
    $nodeMatch = [regex]::Match($mobileScene, $nodePattern)
    if (-not $nodeMatch.Success) {
        throw "MobileControls.tscn is missing TouchScreenButton node: $($entry.Key)"
    }

    $expectedAction = 'action = "' + $entry.Value + '"'
    if (-not $nodeMatch.Groups[1].Value.Contains($expectedAction)) {
        throw "MobileControls.tscn maps $($entry.Key) incorrectly; expected $expectedAction"
    }
}

$readyBody = Get-GdscriptFunctionBody -Source $baseThroughLevel -Name "_ready" -Label "BaseThroughLevel.gd"
Require-Tokens -Source $readyBody -Label "BaseThroughLevel.gd _ready()" -Tokens @(
    "add_mobile_controls()"
)

$addMobileControlsBody = Get-GdscriptFunctionBody -Source $baseThroughLevel -Name "add_mobile_controls" -Label "BaseThroughLevel.gd"
Require-Tokens -Source $addMobileControlsBody -Label "BaseThroughLevel.gd add_mobile_controls()" -Tokens @(
    'has_node("MobileControls")',
    "add_child(mobile_controls)"
)

if ($addMobileControlsBody.Contains("canvas_layer.add_child(mobile_controls)")) {
    throw "BaseThroughLevel.gd add_mobile_controls() must add mobile controls to the level, not its existing canvas_layer."
}

$level20ReadyBody = Get-GdscriptFunctionBody -Source $level20 -Name "_ready" -Label "Level_20.gd"
if (-not $level20ReadyBody.Contains("add_mobile_controls()") -and
    -not $level20ReadyBody.Contains("super._ready()")) {
    throw "Level_20.gd _ready() must mount mobile controls directly or call super._ready()."
}

Write-Host "Mobile controls structure and mappings are valid."