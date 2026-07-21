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
$global = Read-Utf8File -Path (Join-Path $projectRoot "Global.gd") -RejectBom
$sound = Read-Utf8File -Path (Join-Path $projectRoot "Script\AllSound\MonsterBeHit.gd") -RejectBom
$bgm = Read-Utf8File -Path (Join-Path $projectRoot "Script\AllSound\BGM.gd") -RejectBom
$roleInfo = Read-Utf8File -Path (Join-Path $projectRoot "Script\Level\Role_information.gd") -RejectBom

Require-Tokens -Source $global -Label "Global.gd resource cache" -Tokens @(
    "var resource_cache: Dictionary = {}",
    "func get_cached_resource(resource_path: String):",
    "resource_cache[resource_path] = load(resource_path)",
    "func get_cached_monster_scene(monster_id: int):",
    "return get_cached_resource(",
    "func get_cached_audio_stream(audio_path: String):"
)

$createMonsterBody = Get-GdscriptFunctionBody -Source $global -Name "Create_Monster" -Label "Global.gd"
if ($createMonsterBody.Contains('load("res://Scene/Monster/Monster_" + str(M_id) + ".tscn")')) {
    throw "Create_Monster must use cached monster scenes instead of loading by dynamic path every spawn."
}
Require-Tokens -Source $createMonsterBody -Label "Global.gd Create_Monster()" -Tokens @(
    "get_cached_monster_scene(M_id)"
)

Require-Tokens -Source $sound -Label "MonsterBeHit.gd cached stream" -Tokens @(
    "var stream_resource: AudioStream",
    "func setup_audio() -> void:",
    "stream = stream_resource",
    "if stream_resource == null and target != null:",
    "Global.get_cached_audio_stream(target)"
)

$soundPhysicsBody = Get-GdscriptFunctionBody -Source $sound -Name "_physics_process" -Label "MonsterBeHit.gd"
if ($soundPhysicsBody.Contains("load(target)")) {
    throw "MonsterBeHit.gd must not load audio streams inside _physics_process."
}

Require-Tokens -Source $bgm -Label "BGM.gd cached stream" -Tokens @(
    "var stream_resource: AudioStream",
    "func setup_audio() -> void:",
    "stream = stream_resource",
    "if stream_resource == null and target != null:",
    "Global.get_cached_audio_stream(target)"
)

$bgmPhysicsBody = Get-GdscriptFunctionBody -Source $bgm -Name "_physics_process" -Label "BGM.gd"
if ($bgmPhysicsBody.Contains("load(target)")) {
    throw "BGM.gd must not load audio streams inside _physics_process."
}

Require-Tokens -Source $roleInfo -Label "Role_information.gd UI throttling" -Tokens @(
    "const ROLE_INFO_SKILL_REFRESH_INTERVAL := 0.25",
    "var role_info_skill_refresh_left := 0.0",
    "var cached_hp_ratio := -1.0",
    "func update_role_info_ui() -> void:",
    "func update_skill_pic_if_needed(delta: float) -> void:",
    "role_info_skill_refresh_left -= delta",
    "if role_info_skill_refresh_left > 0.0:",
    "role_info_skill_refresh_left = ROLE_INFO_SKILL_REFRESH_INTERVAL"
)

$roleInfoPhysicsBody = Get-GdscriptFunctionBody -Source $roleInfo -Name "_physics_process" -Label "Role_information.gd"
Require-Tokens -Source $roleInfoPhysicsBody -Label "Role_information.gd _physics_process()" -Tokens @(
    "update_skill_pic_if_needed(delta)",
    "update_role_info_ui()"
)
if ($roleInfoPhysicsBody.Contains("set_skill_pic()")) {
    throw "Role_information.gd _physics_process() must throttle set_skill_pic() through update_skill_pic_if_needed()."
}

Write-Host "Stage 1 performance optimization hooks are present."
