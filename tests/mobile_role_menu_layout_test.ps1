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

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$roleInfoPath = Join-Path $projectRoot "Script\Level\Role_information.gd"
$roleInfoScenePath = Join-Path $projectRoot "Scene\Level\Role_information.tscn"

$roleInfo = Read-Utf8File -Path $roleInfoPath -RejectBom
$roleInfoScene = Read-Utf8File -Path $roleInfoScenePath -RejectBom

Require-Tokens -Source $roleInfo -Label "Role_information.gd" -Tokens @(
    "const MOBILE_ROLE_MENU_TOP_OFFSET := 128.0",
    "const MOBILE_ROLE_MENU_TOGGLE_TOP_OFFSET := 88.0",
    "const MOBILE_ROLE_MENU_BUTTON_GAP := 8.0",
    "const MOBILE_ROLE_MENU_TOGGLE_SIZE := Vector2(68.0, 32.0)",
    "var mobile_role_menu_toggle: Button",
    "var mobile_role_menu_collapsed := false",
    "var role_menu_default_position",
    "var role_menu_button_default_offsets",
    "var role_menu_default_texture: Texture2D",
    '@onready var role_menu: Sprite2D = $roleLayer/role_menu',
    '@onready var role_menu_backpack: TextureButton = $roleLayer/role_menu/backpack',
    '@onready var role_menu_set: TextureButton = $roleLayer/role_menu/set',
    '@onready var role_menu_skill: TextureButton = $roleLayer/role_menu/skill',
    '@onready var role_menu_magic_weapon: TextureButton = $roleLayer/role_menu/magic_weapon',
    '@onready var role_menu_pet: TextureButton = $roleLayer/role_menu/pet',
    "capture_role_menu_defaults()",
    "apply_role_menu_layout()",
    "func apply_role_menu_layout()",
    "apply_mobile_role_menu_backdrop()",
    "func apply_mobile_role_menu_backdrop() -> void:",
    "role_menu.texture = null",
    "restore_role_menu_backdrop()",
    "func restore_role_menu_backdrop() -> void:",
    "role_menu.texture = role_menu_default_texture",
    'OS.has_feature("android")',
    "ScreenFit.safe_fit_rect()",
    "get_viewport().size_changed",
    "ensure_mobile_role_menu_toggle()",
    "func ensure_mobile_role_menu_toggle()",
    "mobile_role_menu_toggle = Button.new()",
    'mobile_role_menu_toggle.name = "MobileRoleMenuToggle"',
    'mobile_role_menu_toggle.pressed.connect(_on_mobile_role_menu_toggle_pressed)',
    "func _on_mobile_role_menu_toggle_pressed() -> void:",
    "mobile_role_menu_collapsed = not mobile_role_menu_collapsed",
    "apply_mobile_role_menu_visibility()",
    "func apply_mobile_role_menu_visibility() -> void:",
    "button.visible = not mobile_role_menu_collapsed",
    "mobile_role_menu_toggle.text =",
    "if mobile_role_menu_collapsed else",
    "layout_mobile_role_menu_toggle(safe_rect)",
    "func layout_mobile_role_menu_toggle(safe_rect: Rect2) -> void:",
    "safe_rect.position.y + MOBILE_ROLE_MENU_TOGGLE_TOP_OFFSET",
    "restore_role_menu_default_layout()",
    "layout_mobile_role_menu_top_center()",
    "safe_rect.position.y + MOBILE_ROLE_MENU_TOP_OFFSET",
    "total_width := button_width_sum + MOBILE_ROLE_MENU_BUTTON_GAP * float(buttons.size() - 1)",
    "var desired_position := Vector2(cursor_x, center_y - button_size.y * 0.5)",
    "button.position = desired_position - role_menu.position",
    "role_menu.position = role_menu_default_position",
    "role_menu_default_texture = role_menu.texture"
)


Require-Tokens -Source $roleInfoScene -Label "Role_information.tscn default PC layout" -Tokens @(
    '[node name="role_menu" type="Sprite2D" parent="roleLayer"]',
    "position = Vector2(90, 531)",
    '[node name="backpack" type="TextureButton" parent="roleLayer/role_menu"]',
    "offset_left = -87.0",
    '[node name="set" type="TextureButton" parent="roleLayer/role_menu"]',
    "offset_left = -55.0",
    '[node name="skill" type="TextureButton" parent="roleLayer/role_menu"]',
    "offset_left = -93.0",
    '[node name="magic_weapon" type="TextureButton" parent="roleLayer/role_menu"]',
    "offset_left = -65.0",
    '[node name="pet" type="TextureButton" parent="roleLayer/role_menu"]',
    "offset_left = -27.0"
)

Write-Host "Mobile role menu top-center layout hooks are present."
