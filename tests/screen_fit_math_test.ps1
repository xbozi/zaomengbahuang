$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$screenFit = Get-Content -Raw (Join-Path $projectRoot "Script\Utils\ScreenFit.gd")

foreach ($required in @("func cover_scale", "func cover_offset", "func apply_canvas_cover", "func fit_scale", "func fit_offset", "func safe_fit_rect", "func apply_canvas_mobile_safe_fit", "func base_point", "const BASE_SIZE := Vector2(940, 590)")) {
    if (-not $screenFit.Contains($required)) {
        throw "ScreenFit is missing: $required"
    }
}

$baseW = 940.0
$baseH = 590.0
$viewportW = 1600.0
$viewportH = 900.0
$scale = [Math]::Max($viewportW / $baseW, $viewportH / $baseH)
$offsetX = ($viewportW - $baseW * $scale) / 2.0
$offsetY = ($viewportH - $baseH * $scale) / 2.0

if ([Math]::Abs($scale - 1.70212765957447) -gt 0.0001) { throw "Unexpected cover scale: $scale" }
if ([Math]::Abs($offsetX - 0.0) -gt 0.0001) { throw "Unexpected cover offset x: $offsetX" }
if ([Math]::Abs($offsetY - -52.1276595744681) -gt 0.0001) { throw "Unexpected cover offset y: $offsetY" }

foreach ($file in @("Main_Menu.gd", "Map_1.gd", "Map_2.gd", "Map_3.gd", "Map_4.gd", "Map_5.gd")) {
    $source = Get-Content -Raw (Join-Path $projectRoot "Script\Main_menu\$file")
    if (-not $source.Contains("ScreenFit.apply_canvas_mobile_safe_fit(self)")) {
        throw "$file does not apply Android-safe canvas fitting."
    }
}

$fitScale = [Math]::Min($viewportW / $baseW, $viewportH / $baseH)
$fitOffsetX = ($viewportW - $baseW * $fitScale) / 2.0
$fitOffsetY = ($viewportH - $baseH * $fitScale) / 2.0

if ([Math]::Abs($fitScale - 1.52542372881356) -gt 0.0001) { throw "Unexpected fit scale: $fitScale" }
if ([Math]::Abs($fitOffsetX - 83.0508474576271) -gt 0.0001) { throw "Unexpected fit offset x: $fitOffsetX" }
if ([Math]::Abs($fitOffsetY - 0.0) -gt 0.0001) { throw "Unexpected fit offset y: $fitOffsetY" }

Write-Host "ScreenFit cover and Android-safe fit math/hooks are present."
