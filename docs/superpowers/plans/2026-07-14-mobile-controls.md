# Mobile Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken mobile overlay with a Godot 4.1 multi-touch joystick and action-button layer that appears in Android levels and supports moving while attacking, jumping, or casting skills.

**Architecture:** Keep the existing InputMap and character scripts unchanged. A dedicated `CanvasLayer` owns a left-side floating joystick and custom `TouchScreenButton` nodes; both feed the existing actions, while `BaseThroughLevel` mounts the layer once per level. Tests load the scene through Godot itself and inspect the exported APK so text-resource or packaging failures cannot pass as they did previously.

**Tech Stack:** Godot 4.1, GDScript, `.tscn` text scenes, PowerShell regression tests, Android APK/ZIP inspection.

---

## File map

- Create `Script/MobileControls/MobileActionButton.gd`: a reusable `TouchScreenButton` that creates its own circular hit shape and draws a readable placeholder visual.
- Create `Script/MobileControls/MobileJoystick.gd`: owns one touch index, converts drag distance to existing movement actions, draws the joystick, and releases every injected action safely.
- Replace `Script/MobileControls/MobileControls.gd`: controls Android/debug visibility, viewport layout, action validation, and button placement.
- Replace `Scene/MobileControls/MobileControls.tscn`: independent `CanvasLayer` containing the joystick and ten `TouchScreenButton` action nodes.
- Modify `Script/Base/BaseThroughLevel.gd`: mount the independent canvas once on Android or when PC debug display is enabled.
- Modify `Script/Main_menu/GameSet.gd`: make the existing setting an explicit PC debug toggle and show Android's automatic state accurately.
- Keep `Script/MemoryClass/main_set.gd` and `Scene/Main_menu/GameSet.tscn`: retain the setting key and existing setting row, changing them only if the tests expose a wiring mismatch.
- Replace `tests/mobile_controls_test.ps1`: static regression coverage for UTF-8, node types, action mapping, and level mounting.
- Create `tests/mobile_controls_godot_test.gd`: real Godot resource-load and joystick lifecycle test.
- Create `tests/apk_mobile_controls_test.ps1`: verify the built APK contains the corrected scene and scripts.
- Modify `tests/game_settings_mobile_controls_test.ps1`: cover Android automatic state and PC-only toggle semantics.

Do not stage or modify `godot/editor/**`, `godot/exported/**`, `.codex_tmp/**`, or unrelated user changes.

### Task 1: Lock the failure down with regression tests

**Files:**
- Replace: `tests/mobile_controls_test.ps1`
- Create: `tests/mobile_controls_godot_test.gd`
- Modify: `tests/game_settings_mobile_controls_test.ps1`

- [ ] **Step 1: Replace the static mobile-controls test**

Write `tests/mobile_controls_test.ps1` as:

```powershell
$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$paths = @{
    RootScript = Join-Path $projectRoot "Script\MobileControls\MobileControls.gd"
    JoystickScript = Join-Path $projectRoot "Script\MobileControls\MobileJoystick.gd"
    ButtonScript = Join-Path $projectRoot "Script\MobileControls\MobileActionButton.gd"
    Scene = Join-Path $projectRoot "Scene\MobileControls\MobileControls.tscn"
    BaseLevel = Join-Path $projectRoot "Script\Base\BaseThroughLevel.gd"
}

foreach ($entry in $paths.GetEnumerator()) {
    if (-not (Test-Path $entry.Value)) {
        throw "Missing $($entry.Key): $($entry.Value)"
    }
    $bytes = [System.IO.File]::ReadAllBytes($entry.Value)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "$($entry.Value) has a UTF-8 BOM."
    }
}

$rootScript = Get-Content -Raw -Encoding UTF8 $paths.RootScript
$joystickScript = Get-Content -Raw -Encoding UTF8 $paths.JoystickScript
$buttonScript = Get-Content -Raw -Encoding UTF8 $paths.ButtonScript
$scene = Get-Content -Raw -Encoding UTF8 $paths.Scene
$baseLevel = Get-Content -Raw -Encoding UTF8 $paths.BaseLevel

foreach ($required in @(
    "extends TouchScreenButton",
    "CircleShape2D.new()",
    "draw_circle",
    "ThemeDB.fallback_font"
)) {
    if (-not $buttonScript.Contains($required)) {
        throw "MobileActionButton.gd is missing: $required"
    }
}

foreach ($required in @(
    "extends Control",
    "InputEventScreenTouch",
    "InputEventScreenDrag",
    "joystick_touch_index",
    "Input.action_press",
    "Input.action_release",
    "release_all_actions",
    '"move_left"',
    '"move_right"',
    '"down"',
    '"Exit"'
)) {
    if (-not $joystickScript.Contains($required)) {
        throw "MobileJoystick.gd is missing: $required"
    }
}

foreach ($required in @(
    "extends CanvasLayer",
    'OS.has_feature("android")',
    "force_show_mobile_controls",
    'MainSet.set_data["MobileControlsShow"]',
    "get_viewport().size_changed",
    "BUTTON_LAYOUT"
)) {
    if (-not $rootScript.Contains($required)) {
        throw "MobileControls.gd is missing: $required"
    }
}

if ($scene -match 'type="Button"') {
    throw 'MobileControls.tscn must not use ordinary Button nodes for combat input.'
}

$actions = [ordered]@{
    Attack = "normalhit"
    Jump = "jump"
    Skill1 = "slz"
    Skill2 = "lys"
    Skill3 = "lyfb"
    Skill4 = "hmz"
    Skill5 = "hytj"
    Magic = "MagicWeapon"
    Wushuang = ([string]::Concat([char]0x65E0, [char]0x53CC))
    Zhenfa = ([string]::Concat([char]0x9635, [char]0x6CD5))
}

foreach ($entry in $actions.GetEnumerator()) {
    $nodePattern = '\[node name="' + [regex]::Escape($entry.Key) + '" type="TouchScreenButton"'
    if ($scene -notmatch $nodePattern) {
        throw "Missing TouchScreenButton node: $($entry.Key)"
    }
    if (-not $scene.Contains('action = "' + $entry.Value + '"')) {
        throw "Missing action mapping: $($entry.Key) -> $($entry.Value)"
    }
}

foreach ($required in @(
    'func add_mobile_controls',
    'has_node("MobileControls")',
    'add_child(mobile_controls)'
)) {
    if (-not $baseLevel.Contains($required)) {
        throw "BaseThroughLevel.gd is missing: $required"
    }
}

if ($baseLevel.Contains('canvas_layer.add_child(mobile_controls)')) {
    throw 'MobileControls must own an independent CanvasLayer.'
}

Write-Host "Mobile controls structure and mappings are valid."
```

- [ ] **Step 2: Add the real Godot resource test**

Create `tests/mobile_controls_godot_test.gd`:

```gdscript
extends SceneTree

const MOBILE_SCENE := "res://Scene/MobileControls/MobileControls.tscn"
const EXPECTED_ACTIONS := {
	"Attack": "normalhit",
	"Jump": "jump",
	"Skill1": "slz",
	"Skill2": "lys",
	"Skill3": "lyfb",
	"Skill4": "hmz",
	"Skill5": "hytj",
	"Magic": "MagicWeapon",
	"Wushuang": "无双",
	"Zhenfa": "阵法",
}

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var packed = ResourceLoader.load(MOBILE_SCENE)
	expect_true(packed is PackedScene, "MobileControls.tscn must load as PackedScene")
	if not packed is PackedScene:
		finish()
		return

	var controls = packed.instantiate()
	get_root().add_child(controls)
	await process_frame
	expect_true(controls is CanvasLayer, "MobileControls root must be CanvasLayer")

	for node_name in EXPECTED_ACTIONS:
		var button = controls.get_node_or_null("Root/Buttons/" + node_name)
		expect_true(button is TouchScreenButton, node_name + " must be TouchScreenButton")
		if button is TouchScreenButton:
			expect_true(button.action == EXPECTED_ACTIONS[node_name], node_name + " action mismatch")

	var joystick = controls.get_node_or_null("Root/Joystick")
	expect_true(joystick != null, "Joystick node must exist")
	if joystick != null:
		var start := joystick.get_global_rect().get_center()
		var touch := InputEventScreenTouch.new()
		touch.index = 7
		touch.position = start
		touch.pressed = true
		joystick._input(touch)

		var second_touch := InputEventScreenTouch.new()
		second_touch.index = 9
		second_touch.position = start
		second_touch.pressed = true
		joystick._input(second_touch)
		expect_true(joystick.joystick_touch_index == 7, "Joystick must retain its first touch owner")

		var drag := InputEventScreenDrag.new()
		drag.index = 7
		drag.position = start + Vector2(80.0, 0.0)
		joystick._input(drag)
		expect_true(Input.is_action_pressed("move_right"), "Right drag must press move_right")
		expect_true(not Input.is_action_pressed("move_left"), "Right drag must release move_left")

		var release := InputEventScreenTouch.new()
		release.index = 7
		release.position = drag.position
		release.pressed = false
		joystick._input(release)
		expect_true(not Input.is_action_pressed("move_right"), "Touch release must release move_right")
		expect_true(joystick.joystick_touch_index == -1, "Touch release must clear owner")

	controls.queue_free()
	await process_frame
	finish()

func finish() -> void:
	for action_name in ["move_left", "move_right", "down", "Exit"]:
		Input.action_release(action_name)
	if failures.is_empty():
		print("Mobile controls Godot resource and touch tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
```

- [ ] **Step 3: Extend the settings regression test**

Add these required tokens to `tests/game_settings_mobile_controls_test.ps1` when checking `GameSet.gd`:

```powershell
foreach ($required in @(
    'OS.has_feature("android")',
    'mobile_controls_open_or_close.disabled = true',
    'mobile_controls_open_or_close.text = "自动开启"',
    'if OS.has_feature("android"):',
    'return'
)) {
    if (-not $gameSetScript.Contains($required)) {
        throw "GameSet.gd is missing mobile platform behavior: $required"
    }
}
```

- [ ] **Step 4: Run the new static tests and confirm the expected red state**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\mobile_controls_test.ps1
powershell -ExecutionPolicy Bypass -File tests\game_settings_mobile_controls_test.ps1
```

Expected: FAIL because `MobileJoystick.gd` and `MobileActionButton.gd` do not exist, the scene still contains ordinary `Button` nodes, and Android setting semantics are absent.

- [ ] **Step 5: Commit the failing tests**

```powershell
git add tests/mobile_controls_test.ps1 tests/mobile_controls_godot_test.gd tests/game_settings_mobile_controls_test.ps1
git commit -m "test: define mobile multi-touch behavior"
```

### Task 2: Build the reusable multi-touch action button

**Files:**
- Create: `Script/MobileControls/MobileActionButton.gd`

- [ ] **Step 1: Create the button script**

Write `Script/MobileControls/MobileActionButton.gd`:

```gdscript
extends TouchScreenButton
class_name MobileActionButton

@export var label_text := ""
@export var radius := 32.0
@export var font_size := 18
@export var normal_color := Color(0.10, 0.14, 0.20, 0.58)
@export var pressed_color := Color(0.95, 0.58, 0.16, 0.88)
@export var border_color := Color(0.90, 0.94, 1.0, 0.72)

func _ready() -> void:
	var touch_shape := CircleShape2D.new()
	touch_shape.radius = radius
	shape = touch_shape
	shape_centered = true
	pressed.connect(queue_redraw)
	released.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var fill_color := pressed_color if is_pressed() else normal_color
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius - 1.0, 0.0, TAU, 48, border_color, 2.0, true)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(-text_size.x * 0.5, text_size.y * 0.32)
	draw_string(font, baseline, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
```

- [ ] **Step 2: Run the static test and confirm progress remains red for the next missing unit**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\mobile_controls_test.ps1
```

Expected: FAIL for missing `MobileJoystick.gd`; it must no longer fail on `MobileActionButton.gd`.

- [ ] **Step 3: Commit the button unit**

```powershell
git add Script/MobileControls/MobileActionButton.gd
git commit -m "feat: add mobile multi-touch action button"
```

### Task 3: Implement the touch-owned floating joystick

**Files:**
- Create: `Script/MobileControls/MobileJoystick.gd`

- [ ] **Step 1: Create the joystick script**

Write `Script/MobileControls/MobileJoystick.gd`:

```gdscript
extends Control
class_name MobileJoystick

@export var joystick_radius := 72.0
@export var knob_radius := 29.0
@export var horizontal_deadzone := 0.25
@export var vertical_deadzone := 0.55

var joystick_touch_index := -1
var joystick_center := Vector2.ZERO
var knob_offset := Vector2.ZERO
var pressed_actions: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_on_visibility_changed)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch_index == -1 and get_global_rect().has_point(event.position):
			joystick_touch_index = event.index
			joystick_center = to_local(event.position)
			update_joystick(Vector2.ZERO)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == joystick_touch_index:
			joystick_touch_index = -1
			release_all_actions()
			knob_offset = Vector2.ZERO
			queue_redraw()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == joystick_touch_index:
		update_joystick(to_local(event.position) - joystick_center)
		get_viewport().set_input_as_handled()

func update_joystick(offset: Vector2) -> void:
	knob_offset = offset.limit_length(joystick_radius)
	var axis := knob_offset / joystick_radius
	update_horizontal_actions(axis.x)
	update_vertical_actions(axis.y)
	queue_redraw()

func update_horizontal_actions(value: float) -> void:
	if value < -horizontal_deadzone:
		press_action("move_left", absf(value))
		release_action("move_right")
	elif value > horizontal_deadzone:
		press_action("move_right", value)
		release_action("move_left")
	else:
		release_action("move_left")
		release_action("move_right")

func update_vertical_actions(value: float) -> void:
	if value > vertical_deadzone:
		press_action("down")
		release_action("Exit")
	elif value < -vertical_deadzone:
		press_action("Exit")
		release_action("down")
	else:
		release_action("down")
		release_action("Exit")

func press_action(action_name: String, strength := 1.0) -> void:
	pressed_actions[action_name] = true
	Input.action_press(action_name, strength)

func release_action(action_name: String) -> void:
	if not pressed_actions.has(action_name):
		return
	pressed_actions.erase(action_name)
	Input.action_release(action_name)

func release_all_actions() -> void:
	for action_name in pressed_actions.keys():
		Input.action_release(action_name)
	pressed_actions.clear()

func _draw() -> void:
	var center := joystick_center if joystick_touch_index != -1 else size * 0.5
	draw_circle(center, joystick_radius, Color(0.08, 0.12, 0.18, 0.30))
	draw_arc(center, joystick_radius - 1.0, 0.0, TAU, 64, Color(0.80, 0.88, 1.0, 0.42), 2.0, true)
	draw_circle(center + knob_offset, knob_radius, Color(0.78, 0.88, 1.0, 0.68))

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		joystick_touch_index = -1
		knob_offset = Vector2.ZERO
		release_all_actions()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		joystick_touch_index = -1
		knob_offset = Vector2.ZERO
		release_all_actions()

func _exit_tree() -> void:
	release_all_actions()
```

- [ ] **Step 2: Run the static test and confirm the scene is now the remaining failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\mobile_controls_test.ps1
```

Expected: FAIL because `MobileControls.tscn` still uses ordinary `Button` nodes and the root script is still the old implementation.

- [ ] **Step 3: Commit the joystick unit**

```powershell
git add Script/MobileControls/MobileJoystick.gd
git commit -m "feat: add touch-owned mobile joystick"
```

### Task 4: Replace the overlay scene and mount it independently

**Files:**
- Replace: `Script/MobileControls/MobileControls.gd`
- Replace: `Scene/MobileControls/MobileControls.tscn`
- Modify: `Script/Base/BaseThroughLevel.gd:1-103`

- [ ] **Step 1: Replace the root controller**

Write `Script/MobileControls/MobileControls.gd`:

```gdscript
extends CanvasLayer

const FORCE_SHOW_SETTING := "application/run/force_show_mobile_controls"
const REQUIRED_ACTIONS := [
	"move_left", "move_right", "down", "Exit", "normalhit", "jump",
	"slz", "lys", "lyfb", "hmz", "hytj", "MagicWeapon", "无双", "阵法",
]
const BUTTON_LAYOUT := {
	"Attack": Vector2(0.88, 0.82),
	"Jump": Vector2(0.95, 0.63),
	"Skill1": Vector2(0.72, 0.86),
	"Skill2": Vector2(0.65, 0.72),
	"Skill3": Vector2(0.70, 0.56),
	"Skill4": Vector2(0.79, 0.46),
	"Skill5": Vector2(0.88, 0.42),
	"Magic": Vector2(0.79, 0.14),
	"Wushuang": Vector2(0.87, 0.14),
	"Zhenfa": Vector2(0.95, 0.14),
}

@onready var root: Control = $Root
@onready var buttons: Node2D = $Root/Buttons

func _ready() -> void:
	layer = 100
	visible = should_show_mobile_controls()
	validate_actions()
	fit_viewport()
	if not get_viewport().size_changed.is_connected(fit_viewport):
		get_viewport().size_changed.connect(fit_viewport)

func should_show_mobile_controls() -> bool:
	return OS.has_feature("android") \
		or ProjectSettings.get_setting(FORCE_SHOW_SETTING, false) \
		or (MainSet.set_data.has("MobileControlsShow") and MainSet.set_data["MobileControlsShow"])

func fit_viewport() -> void:
	root.position = Vector2.ZERO
	root.size = get_viewport().get_visible_rect().size
	for button_name in BUTTON_LAYOUT:
		var button := buttons.get_node_or_null(button_name) as TouchScreenButton
		if button != null:
			button.position = Vector2(
				root.size.x * BUTTON_LAYOUT[button_name].x,
				root.size.y * BUTTON_LAYOUT[button_name].y
			)

func validate_actions() -> void:
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			push_warning("Mobile controls InputMap action is missing: " + action_name)
```

- [ ] **Step 2: Replace the scene with an independent canvas and TouchScreenButtons**

Write `Scene/MobileControls/MobileControls.tscn` as UTF-8 without BOM:

```text
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://Script/MobileControls/MobileControls.gd" id="1_root"]
[ext_resource type="Script" path="res://Script/MobileControls/MobileJoystick.gd" id="2_joystick"]
[ext_resource type="Script" path="res://Script/MobileControls/MobileActionButton.gd" id="3_button"]

[node name="MobileControls" type="CanvasLayer"]
layer = 100
script = ExtResource("1_root")

[node name="Root" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="Joystick" type="Control" parent="Root"]
layout_mode = 1
anchors_preset = 12
anchor_top = 0.52
anchor_right = 0.42
anchor_bottom = 1.0
offset_left = 18.0
offset_top = 8.0
offset_right = -8.0
offset_bottom = -18.0
grow_horizontal = 2
grow_vertical = 0
mouse_filter = 2
script = ExtResource("2_joystick")

[node name="Buttons" type="Node2D" parent="Root"]

[node name="Attack" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(827, 484)
action = "normalhit"
script = ExtResource("3_button")
label_text = "普攻"
radius = 52.0
font_size = 20

[node name="Jump" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(893, 372)
action = "jump"
script = ExtResource("3_button")
label_text = "跳跃"
radius = 40.0

[node name="Skill1" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(677, 507)
action = "slz"
script = ExtResource("3_button")
label_text = "技1"

[node name="Skill2" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(611, 425)
action = "lys"
script = ExtResource("3_button")
label_text = "技2"

[node name="Skill3" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(658, 330)
action = "lyfb"
script = ExtResource("3_button")
label_text = "技3"

[node name="Skill4" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(743, 271)
action = "hmz"
script = ExtResource("3_button")
label_text = "技4"

[node name="Skill5" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(827, 248)
action = "hytj"
script = ExtResource("3_button")
label_text = "技5"

[node name="Magic" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(743, 83)
action = "MagicWeapon"
script = ExtResource("3_button")
label_text = "法宝"
radius = 27.0
font_size = 15

[node name="Wushuang" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(818, 83)
action = "无双"
script = ExtResource("3_button")
label_text = "无双"
radius = 27.0
font_size = 15

[node name="Zhenfa" type="TouchScreenButton" parent="Root/Buttons"]
position = Vector2(893, 83)
action = "阵法"
script = ExtResource("3_button")
label_text = "阵法"
radius = 27.0
font_size = 15
```

- [ ] **Step 3: Change the level mount from the existing HUD canvas to the level root**

Keep `MOBILE_CONTROLS_PATH` and replace `add_mobile_controls()` in `Script/Base/BaseThroughLevel.gd` with:

```gdscript
func add_mobile_controls() -> void:
	var debug_show := MainSet.set_data.has("MobileControlsShow") and MainSet.set_data["MobileControlsShow"]
	var force_show := ProjectSettings.get_setting("application/run/force_show_mobile_controls", false)
	if not OS.has_feature("android") and not debug_show and not force_show:
		return
	if has_node("MobileControls"):
		return
	var packed = ResourceLoader.load(MOBILE_CONTROLS_PATH)
	if not packed is PackedScene:
		push_warning("MobileControls scene failed to load: " + MOBILE_CONTROLS_PATH)
		return
	var mobile_controls = packed.instantiate()
	if mobile_controls == null:
		push_warning("MobileControls scene failed to instantiate: " + MOBILE_CONTROLS_PATH)
		return
	mobile_controls.name = "MobileControls"
	add_child(mobile_controls)
```

- [ ] **Step 4: Run static tests**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\mobile_controls_test.ps1
```

Expected: `Mobile controls structure and mappings are valid.`

- [ ] **Step 5: Run the real Godot resource and touch test**

Run:

```powershell
& '.\.tools\godot-4.1.4\Godot_v4.1.4-stable_win64_console.exe' --headless --path . --script res://tests/mobile_controls_godot_test.gd
```

Expected: exit code 0 and `Mobile controls Godot resource and touch tests passed.` No `MobileControls.tscn` parse error is allowed.

- [ ] **Step 6: Commit the working overlay**

```powershell
git add Scene/MobileControls/MobileControls.tscn Script/MobileControls/MobileControls.gd Script/MobileControls/MobileActionButton.gd Script/MobileControls/MobileJoystick.gd Script/Base/BaseThroughLevel.gd
git commit -m "feat: add reliable mobile multi-touch controls"
```

### Task 5: Make the settings status truthful

**Files:**
- Modify: `Script/Main_menu/GameSet.gd:68-77,246-250`
- Verify: `Script/MemoryClass/main_set.gd`
- Verify: `Scene/Main_menu/GameSet.tscn`
- Test: `tests/game_settings_mobile_controls_test.ps1`

- [ ] **Step 1: Update the per-frame status display**

Replace the current mobile-setting display block in `_physics_process()` with:

```gdscript
	if not MainSet.set_data.has("MobileControlsShow"):
		MainSet.set_data["MobileControlsShow"] = false
	if OS.has_feature("android"):
		mobile_controls_open_or_close.text = "自动开启"
		mobile_controls_open_or_close.disabled = true
	else:
		mobile_controls_open_or_close.disabled = false
		if MainSet.set_data["MobileControlsShow"]:
			mobile_controls_open_or_close.text = "开启中"
		else:
			mobile_controls_open_or_close.text = "关闭中"
```

- [ ] **Step 2: Guard the PC debug toggle on Android**

Replace `_on_mobile_controls_open_or_close_pressed()` with:

```gdscript
func _on_mobile_controls_open_or_close_pressed() -> void:
	if OS.has_feature("android"):
		return
	if not MainSet.set_data.has("MobileControlsShow"):
		MainSet.set_data["MobileControlsShow"] = false
	MainSet.set_data["MobileControlsShow"] = not MainSet.set_data["MobileControlsShow"]
	MemoryClass.main_bc()
```

- [ ] **Step 3: Run both setting and mobile regression tests**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\game_settings_mobile_controls_test.ps1
powershell -ExecutionPolicy Bypass -File tests\mobile_controls_test.ps1
```

Expected: both exit 0. The setting test prints `Game settings mobile controls toggle is wired.`

- [ ] **Step 4: Commit the settings behavior**

```powershell
git add Script/Main_menu/GameSet.gd Script/MemoryClass/main_set.gd Scene/Main_menu/GameSet.tscn tests/game_settings_mobile_controls_test.ps1
git commit -m "fix: report mobile controls state accurately"
```

### Task 6: Prove the exported APK contains the corrected controls

**Files:**
- Create: `tests/apk_mobile_controls_test.ps1`
- Build output: `build/zaomeng-bahuang.apk` (do not commit)

- [ ] **Step 1: Create the APK content test**

Write `tests/apk_mobile_controls_test.ps1`:

```powershell
param(
    [string]$ApkPath = "build\zaomeng-bahuang.apk"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$resolvedApk = Resolve-Path (Join-Path $projectRoot $ApkPath)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($resolvedApk)

try {
    $requiredEntries = @(
        "assets/Scene/MobileControls/MobileControls.tscn",
        "assets/Script/MobileControls/MobileControls.gd",
        "assets/Script/MobileControls/MobileJoystick.gd",
        "assets/Script/MobileControls/MobileActionButton.gd",
        "assets/Script/Base/BaseThroughLevel.gd"
    )

    foreach ($entryName in $requiredEntries) {
        if ($null -eq $zip.GetEntry($entryName)) {
            throw "APK is missing $entryName"
        }
    }

    $sceneEntry = $zip.GetEntry("assets/Scene/MobileControls/MobileControls.tscn")
    $stream = $sceneEntry.Open()
    $memory = New-Object System.IO.MemoryStream
    $stream.CopyTo($memory)
    $stream.Dispose()
    $sceneBytes = $memory.ToArray()
    $memory.Dispose()

    if ($sceneBytes.Length -ge 3 -and $sceneBytes[0] -eq 0xEF -and $sceneBytes[1] -eq 0xBB -and $sceneBytes[2] -eq 0xBF) {
        throw "APK MobileControls.tscn still has a UTF-8 BOM."
    }

    $sceneText = [System.Text.Encoding]::UTF8.GetString($sceneBytes)
    foreach ($required in @(
        '[node name="MobileControls" type="CanvasLayer"]',
        '[node name="Attack" type="TouchScreenButton"',
        'action = "normalhit"',
        'action = "jump"'
    )) {
        if (-not $sceneText.Contains($required)) {
            throw "APK mobile scene is stale or invalid: missing $required"
        }
    }
} finally {
    $zip.Dispose()
}

Write-Host "APK contains the corrected mobile controls resources."
```

- [ ] **Step 2: Export a new Android debug APK**

Run:

```powershell
& '.\.tools\godot-4.1.4\Godot_v4.1.4-stable_win64_console.exe' --headless --path . --export-debug 'Android' 'build\zaomeng-bahuang.apk'
```

Expected: exit code 0 and a newly timestamped `build/zaomeng-bahuang.apk`. Do not reuse `build/zaomeng-bahuang-release.apk` from 15:51 because it predates the repaired resource.

- [ ] **Step 3: Inspect the exported APK**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\apk_mobile_controls_test.ps1 -ApkPath build\zaomeng-bahuang.apk
```

Expected: `APK contains the corrected mobile controls resources.`

- [ ] **Step 4: Run the full automated verification set**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\mobile_controls_test.ps1
powershell -ExecutionPolicy Bypass -File tests\game_settings_mobile_controls_test.ps1
& '.\.tools\godot-4.1.4\Godot_v4.1.4-stable_win64_console.exe' --headless --path . --script res://tests/mobile_controls_godot_test.gd
powershell -ExecutionPolicy Bypass -File tests\apk_mobile_controls_test.ps1 -ApkPath build\zaomeng-bahuang.apk
git status --short
```

Expected: all tests exit 0. `git status --short` may still show pre-existing editor caches and build/export changes; verify no unrelated path was staged.

- [ ] **Step 5: Commit the APK regression test only**

```powershell
git add tests/apk_mobile_controls_test.ps1
git commit -m "test: verify mobile controls in Android export"
```

- [ ] **Step 6: Perform Android acceptance**

Install the newly generated APK in the emulator or device. Enter a `BaseLevel` stage, hold the joystick to the right, and while still holding it press: attack, jump, each of the five skills, magic weapon, wushuang, and zhenfa. Acceptance requires continuous movement, responsive second-finger actions, no stuck movement after release, and no `MobileControls.tscn` load error in the device log.
