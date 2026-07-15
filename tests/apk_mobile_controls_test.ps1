param(
	[string]$ApkPath = "build\zaomeng-bahuang.apk"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$candidateApk = if ([System.IO.Path]::IsPathRooted($ApkPath)) {
	$ApkPath
} else {
	Join-Path $projectRoot $ApkPath
}
if (-not (Test-Path -LiteralPath $candidateApk -PathType Leaf)) {
	throw "APK does not exist: $candidateApk. Export a fresh Android build before running this test."
}

$resolvedApk = Resolve-Path -LiteralPath $candidateApk
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($resolvedApk)

try {
	$requiredContent = [ordered]@{
		"assets/Scene/MobileControls/MobileControls.tscn" = @(
			'[node name="MobileControls" type="CanvasLayer"]',
			'[node name="Attack" type="TouchScreenButton"',
			'action = "normalhit"',
			'action = "jump"'
		)
		"assets/Script/MobileControls/MobileControls.gd" = @(
			"extends CanvasLayer",
			"DisplayServer.get_display_safe_area()"
		)
		"assets/Script/MobileControls/MobileJoystick.gd" = @(
			"extends Control",
			"joystick_touch_index",
			"press_action_once"
		)
		"assets/Script/MobileControls/MobileActionButton.gd" = @(
			"extends TouchScreenButton",
			"CircleShape2D.new()"
		)
		"assets/Script/Base/BaseThroughLevel.gd" = @(
			"func add_mobile_controls()",
			'has_node("MobileControls")'
		)
		"assets/Script/Level/Level_20.gd" = @(
			"add_mobile_controls()"
		)
		"assets/Script/Main_menu/GameSet.gd" = @(
			'OS.has_feature("android")',
			'mobile_controls_open_or_close.disabled = true',
			'mobile_controls_open_or_close.disabled = false',
			"func _on_mobile_controls_open_or_close_pressed()"
		)
		"assets/Script/MemoryClass/main_set.gd" = @(
			'"MobileControlsShow": false'
		)
		"assets/Scene/Main_menu/GameSet.tscn" = @(
			'[node name="MobileControls" type="Label"',
			'method="_on_mobile_controls_open_or_close_pressed"'
		)
	}

	foreach ($entryName in $requiredContent.Keys) {
		$entry = $zip.GetEntry($entryName)
		if ($null -eq $entry) {
			throw "APK is missing $entryName"
		}

		$stream = $entry.Open()
		$memory = New-Object System.IO.MemoryStream
		try {
			$stream.CopyTo($memory)
			$bytes = $memory.ToArray()
		} finally {
			$stream.Dispose()
			$memory.Dispose()
		}

		if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
			throw "APK entry still has a UTF-8 BOM: $entryName"
		}

		$text = [System.Text.Encoding]::UTF8.GetString($bytes)
		foreach ($required in $requiredContent[$entryName]) {
			if (-not $text.Contains($required)) {
				throw "APK resource is stale or invalid: $entryName is missing $required"
			}
		}
	}

	$remapName = "assets/Scene/Main_menu/GameSet.tscn.remap"
	$remapEntry = $zip.GetEntry($remapName)
	if ($null -eq $remapEntry) {
		throw "APK is missing the runtime GameSet scene remap: $remapName"
	}

	$reader = New-Object System.IO.StreamReader($remapEntry.Open(), [System.Text.Encoding]::UTF8)
	try {
		$remapText = $reader.ReadToEnd()
	} finally {
		$reader.Dispose()
	}

	$remapMatch = [regex]::Match($remapText, 'path="res://([^"]+-GameSet\.scn)"')
	if (-not $remapMatch.Success) {
		throw "APK GameSet remap does not identify its compiled scene."
	}

	$compiledEntryName = "assets/" + $remapMatch.Groups[1].Value
	$compiledEntry = $zip.GetEntry($compiledEntryName)
	if ($null -eq $compiledEntry) {
		throw "APK is missing the compiled GameSet scene: $compiledEntryName"
	}

	$compiledStream = $compiledEntry.Open()
	$compiledMemory = New-Object System.IO.MemoryStream
	try {
		$compiledStream.CopyTo($compiledMemory)
		$compiledText = [System.Text.Encoding]::ASCII.GetString($compiledMemory.ToArray())
	} finally {
		$compiledStream.Dispose()
		$compiledMemory.Dispose()
	}

	foreach ($required in @(
		"MobileControls",
		"MobileControlsOpenOrClose",
		"_on_mobile_controls_open_or_close_pressed"
	)) {
		if (-not $compiledText.Contains($required)) {
			throw "APK compiled GameSet scene is stale: missing $required"
		}
	}
} finally {
	$zip.Dispose()
}

Write-Host "APK contains the corrected mobile controls resources."
