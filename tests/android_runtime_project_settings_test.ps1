param()

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$projectPath = Join-Path $projectRoot "project.godot"
$exportPath = Join-Path $projectRoot "export_presets.cfg"

if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
	throw "project.godot is missing."
}
if (-not (Test-Path -LiteralPath $exportPath -PathType Leaf)) {
	throw "export_presets.cfg is missing."
}

$projectText = [System.IO.File]::ReadAllText($projectPath, [System.Text.Encoding]::UTF8)
$exportText = [System.IO.File]::ReadAllText($exportPath, [System.Text.Encoding]::UTF8)

if ($projectText -notmatch '(?m)^config/use_hidden_project_data_directory=true$') {
	throw "Android runtime fix missing: config/use_hidden_project_data_directory must be true."
}

if ($projectText -notmatch '(?m)^textures/vram_compression/import_etc2_astc=true$') {
	throw "Android runtime fix missing: ETC2/ASTC texture import setting."
}

if (-not $exportText.Contains('export_filter="all_resources"')) {
	throw "Android export must include all resources."
}

if (-not $exportText.Contains('exclude_filter="godot/**"')) {
	throw "Android export must exclude local Godot editor state."
}

Write-Host "Android runtime project settings are present."