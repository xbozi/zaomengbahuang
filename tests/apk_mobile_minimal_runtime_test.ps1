param(
	[string]$ApkPath = "build\zaomeng-bahuang-mobile-minimal-debug.apk",
	[string]$BaseApkPath = "C:\tmp\zaomeng-bahuang-apkfix\build\zaomeng-bahuang-fixed-signed.apk"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$targetApk = if ([System.IO.Path]::IsPathRooted($ApkPath)) { $ApkPath } else { Join-Path $projectRoot $ApkPath }
if (-not (Test-Path -LiteralPath $targetApk -PathType Leaf)) {
	throw "APK does not exist: $targetApk"
}
if (-not (Test-Path -LiteralPath $BaseApkPath -PathType Leaf)) {
	throw "Base APK does not exist: $BaseApkPath"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ApkEntryBytes([string]$ZipPath, [string]$EntryName) {
	$zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
	try {
		$entry = $zip.GetEntry($EntryName)
		if ($null -eq $entry) { return $null }
		$stream = $entry.Open()
		$memory = [System.IO.MemoryStream]::new()
		try {
			$stream.CopyTo($memory)
			return $memory.ToArray()
		} finally {
			$memory.Dispose()
			$stream.Dispose()
		}
	} finally {
		$zip.Dispose()
	}
}

function Get-Sha256([byte[]]$Bytes) {
	if ($null -eq $Bytes) { return "<missing>" }
	$sha = [System.Security.Cryptography.SHA256]::Create()
	try { return [System.BitConverter]::ToString($sha.ComputeHash($Bytes)) } finally { $sha.Dispose() }
}

$mustStayFromBase = @(
	"assets/project.binary",
	"assets/Script/MemoryClass/main_set.gd",
	"assets/Script/Main_menu/Main_Menu.gd",
	"assets/Script/Main_menu/GameSet.gd",
	"assets/Scene/Main_menu/GameSet.tscn",
	"assets/Scene/Main_menu/GameSet.tscn.remap",
	"assets/.godot/exported/133200997/export-0c1c57e87f50ba0a808b67d5b612f21b-GameSet.scn"
)

foreach ($entryName in $mustStayFromBase) {
	$targetHash = Get-Sha256 (Get-ApkEntryBytes $targetApk $entryName)
	$baseHash = Get-Sha256 (Get-ApkEntryBytes $BaseApkPath $entryName)
	if ($targetHash -ne $baseHash) {
		throw "APK changed startup/settings resource unexpectedly: $entryName"
	}
}

$sourceResources = [ordered]@{
	"assets/Scene/MobileControls/MobileControls.tscn" = "Scene\MobileControls\MobileControls.tscn"
	"assets/Script/MobileControls/MobileControls.gd" = "Script\MobileControls\MobileControls.gd"
	"assets/Script/MobileControls/MobileJoystick.gd" = "Script\MobileControls\MobileJoystick.gd"
	"assets/Script/MobileControls/MobileActionButton.gd" = "Script\MobileControls\MobileActionButton.gd"
	"assets/Script/Base/BaseThroughLevel.gd" = "Script\Base\BaseThroughLevel.gd"
	"assets/Script/Level/Level_20.gd" = "Script\Level\Level_20.gd"
}

foreach ($entryName in $sourceResources.Keys) {
	$entryBytes = Get-ApkEntryBytes $targetApk $entryName
	if ($null -eq $entryBytes) {
		throw "APK is missing required mobile runtime resource: $entryName"
	}
	$sourcePath = Join-Path $projectRoot $sourceResources[$entryName]
	$sourceBytes = [System.IO.File]::ReadAllBytes($sourcePath)
	if ((Get-Sha256 $entryBytes) -ne (Get-Sha256 $sourceBytes)) {
		throw "APK mobile runtime resource differs from source: $entryName"
	}
}

$joystickText = [System.Text.Encoding]::UTF8.GetString((Get-ApkEntryBytes $targetApk "assets/Script/MobileControls/MobileJoystick.gd"))
if ($joystickText.Contains("to_local(")) {
	throw "APK MobileJoystick.gd still contains Godot 4.1-incompatible to_local()."
}
if (-not $joystickText.Contains("make_canvas_position_local")) {
	throw "APK MobileJoystick.gd is missing make_canvas_position_local()."
}

Write-Host "APK mobile runtime patch is minimal and parser-safe."