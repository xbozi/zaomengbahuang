$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$screenFit = Get-Content -Raw (Join-Path $projectRoot "Script\Utils\ScreenFit.gd")

foreach ($required in @("func cover_scale", "func cover_offset", "func apply_canvas_cover", "func base_point", "const BASE_SIZE := Vector2(940, 590)")) {
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
    if (-not $source.Contains("ScreenFit.apply_canvas_cover(self)")) {
        throw "$file does not apply canvas cover."
    }
}

Write-Host "ScreenFit cover math and menu/map hooks are present."