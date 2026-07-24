$ErrorActionPreference = "Stop"

$scriptFiles = @()
$scriptFiles += Get-ChildItem -Path "Script" -Recurse -Filter "*.gd" -File
$scriptFiles += Get-ChildItem -Path "." -Filter "*.gd" -File

$riskyPatterns = @(
	'\bvar\s+\w+\s*:=.*(==|!=|>=|<=|>|<|\band\b|\bor\b|\bnot\b|\sif\s.+\selse\s)',
	'\bvar\s+\w+\s*:=.*(RoleProp\.|PlayerData\.|MainSet\.)'
)
$violations = @()

foreach ($file in $scriptFiles) {
	$lines = Get-Content -Path $file.FullName -Encoding UTF8
	for ($i = 0; $i -lt $lines.Count; $i++) {
		$line = $lines[$i]
		foreach ($pattern in $riskyPatterns) {
			if ($line -match $pattern) {
				$relativePath = Resolve-Path -Relative $file.FullName
				$violations += ("{0}:{1}: {2}" -f $relativePath.TrimStart('.\'), ($i + 1), $line.Trim())
				break
			}
		}
	}
}

if ($violations.Count -gt 0) {
	throw "Risky GDScript := type inference found:`n$($violations -join "`n")"
}

Write-Host "No risky GDScript := comparison/logical type inference found."