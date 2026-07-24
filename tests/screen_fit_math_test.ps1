$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$projectText = Get-Content -Raw (Join-Path $projectRoot "project.godot")
$screenFit = Get-Content -Raw (Join-Path $projectRoot "Script\Utils\ScreenFit.gd")

foreach ($required in @("func cover_scale", "func cover_offset", "func apply_canvas_cover", "func apply_legacy_fullscreen_cover", "func apply_legacy_fullscreen_fit", "func target_limited_viewport_size", "func cover_90_scale", "func cover_90_offset", "func apply_canvas_cover_90", "func apply_canvas_fit", "func fit_scale", "func fit_offset", "func safe_fit_rect", "func apply_canvas_mobile_safe_fit", "func base_point", "const BASE_SIZE := Vector2(940, 590)", "const TARGET_VIEWPORT_SIZE := Vector2(1320, 594)", "const COVER_90_RATIO := 0.9")) {
    if (-not $screenFit.Contains($required)) {
        throw "ScreenFit is missing: $required"
    }
}

if (-not $projectText.Contains('window/size/viewport_width=1320')) { throw "Project viewport width must be 1320 for 20:9." }
if (-not $projectText.Contains('window/size/viewport_height=594')) { throw "Project viewport height must be 594 for 20:9." }
if (-not $projectText.Contains('window/stretch/aspect="keep"')) { throw "Project stretch aspect must be keep to avoid exposing extra canvas." }
if (-not $projectText.Contains('rendering/environment/defaults/default_clear_color=Color(0, 0, 0, 1)')) { throw "Default clear color must be black so fit margins are not gray." }

$baseW = 940.0
$baseH = 590.0
$viewportW = 1320.0
$viewportH = 594.0
$coverScale = [Math]::Max($viewportW / $baseW, $viewportH / $baseH)
$coverOffsetX = ($viewportW - $baseW * $coverScale) / 2.0
$coverOffsetY = ($viewportH - $baseH * $coverScale) / 2.0

if ([Math]::Abs($coverScale - 1.40425531914894) -gt 0.0001) { throw "Unexpected cover scale: $coverScale" }
if ([Math]::Abs($coverOffsetX - 0.0) -gt 0.0001) { throw "Unexpected cover offset x: $coverOffsetX" }
if ([Math]::Abs($coverOffsetY - -117.255319148936) -gt 0.0001) { throw "Unexpected cover offset y: $coverOffsetY" }

$fitScale = [Math]::Min($viewportW / $baseW, $viewportH / $baseH)
$fitOffsetX = ($viewportW - $baseW * $fitScale) / 2.0
$fitOffsetY = ($viewportH - $baseH * $fitScale) / 2.0
$fitCoveredW = $baseW * $fitScale
$fitCoveredH = $baseH * $fitScale

if ([Math]::Abs($fitScale - 1.00677966101695) -gt 0.0001) { throw "Unexpected fit scale: $fitScale" }
if ([Math]::Abs($fitOffsetX - 186.813559322034) -gt 0.0001) { throw "Unexpected fit offset x: $fitOffsetX" }
if ([Math]::Abs($fitOffsetY - 0.0) -gt 0.0001) { throw "Unexpected fit offset y: $fitOffsetY" }
if ($fitOffsetX -lt -0.0001 -or $fitOffsetY -lt -0.0001) { throw "Legacy fullscreen fit must not crop top or left." }
if ($fitCoveredW -gt $viewportW + 0.0001 -or $fitCoveredH -gt $viewportH + 0.0001) { throw "Legacy fullscreen fit must keep the whole 940x590 canvas visible." }

function Assert-FitKeepsWholeCanvas($Width, $Height) {
    $scale = [Math]::Min($Width / $baseW, $Height / $baseH)
    $offsetX = ($Width - $baseW * $scale) / 2.0
    $offsetY = ($Height - $baseH * $scale) / 2.0
    if ($offsetX -lt -0.0001 -or $offsetY -lt -0.0001) { throw "Fit crops legacy canvas for ${Width}x${Height}." }
}

Assert-FitKeepsWholeCanvas 1320.0 594.0
Assert-FitKeepsWholeCanvas 1600.0 900.0

$legacyFullscreenFiles = @(
    "Script\Main_menu\Main_Menu.gd",
    "Script\Main_menu\Map_1.gd",
    "Script\Main_menu\Map_2.gd",
    "Script\Main_menu\Map_3.gd",
    "Script\Main_menu\Map_4.gd",
    "Script\Main_menu\Map_5.gd",
    "Script\Main_menu\ChoosePlayer.gd",
    "Script\Main_menu\Game_over_1.gd",
    "Script\Level\defeat.gd",
    "Script\Level\victory.gd"
)

foreach ($file in $legacyFullscreenFiles) {
    $source = Get-Content -Raw (Join-Path $projectRoot $file)
    if (-not $source.Contains("ScreenFit.apply_legacy_fullscreen_fit(self)")) {
        throw "$file does not apply legacy fullscreen fit."
    }
    if ($source.Contains("ScreenFit.apply_legacy_fullscreen_cover(self)")) {
        throw "$file must not use cover for fullscreen legacy scenes because it crops top UI."
    }
    if ($source.Contains("ScreenFit.apply_canvas_cover_90(self)")) {
        throw "$file must not use 90-percent canvas fitting."
    }
}

$camera = Get-Content -Raw (Join-Path $projectRoot "Script\Level\camera.gd")
if (-not $camera.Contains("ScreenFit.target_limited_viewport_size()")) {
    throw "Level camera must clamp viewport size to target viewport."
}

$cover90Scale = $coverScale * 0.9
$cover90OffsetX = ($viewportW - $baseW * $cover90Scale) / 2.0
$cover90OffsetY = ($viewportH - $baseH * $cover90Scale) / 2.0

if ([Math]::Abs($cover90Scale - 1.26382978723404) -gt 0.0001) { throw "Unexpected cover 90 scale: $cover90Scale" }
if ([Math]::Abs($cover90OffsetX - 66.0) -gt 0.0001) { throw "Unexpected cover 90 offset x: $cover90OffsetX" }
if ([Math]::Abs($cover90OffsetY - -75.8297872340426) -gt 0.0001) { throw "Unexpected cover 90 offset y: $cover90OffsetY" }

Write-Host "ScreenFit 20:9 fixed aspect, legacy fullscreen fit, black margins, and camera clamp are present."