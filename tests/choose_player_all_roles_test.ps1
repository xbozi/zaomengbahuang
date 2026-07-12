$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$choosePlayerScript = Join-Path $projectRoot "Script\Main_menu\ChoosePlayer.gd"
$source = Get-Content -Raw $choosePlayerScript

$expectedPlayerList = 'var PlayerList = ["swk","tsz","zbj","swj","xbl"]'
if (-not $source.Contains($expectedPlayerList)) {
    throw "Expected the fixed PlayerList declaration: $expectedPlayerList"
}

if ($source -match 'PlayerList\.push_back\(') {
    throw "PlayerList must not be populated with push_back calls."
}

Write-Host "ChoosePlayer exposes all roles through the fixed PlayerList declaration."
