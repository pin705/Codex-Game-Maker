param(
  [string]$RequiredMajor = "4",
  [string]$RequiredMinor = "4",
  [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"

if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}

. $platformHelper

$godotPath = Find-CgsGodotCommand -Root $repoRoot.Path -RequiredMajor $RequiredMajor -RequiredMinor $RequiredMinor -GodotPath $GodotPath

if (!$godotPath) {
  [pscustomobject]@{
    found = $false
    required = "Godot $RequiredMajor.$RequiredMinor"
    severity = "WARN"
    platform = (Get-CgsPlatform)
    message = "Godot CLI was not found. From the Codex Game Maker root, run tools/install-godot.ps1 with PowerShell. It installs Godot 4.4 under .tools/godot, creates a repo-local wrapper, and updates PATH unless -NoPath is provided. Restart Codex or your terminal afterward."
  } | ConvertTo-Json -Depth 4
  exit 0
}

$versionOutput = & $godotPath --version 2>&1 | Select-Object -First 1
$versionText = "$versionOutput"
$match = [regex]::Match($versionText, "(\d+)\.(\d+)(?:\.(\d+))?")
$major = if ($match.Success) { $match.Groups[1].Value } else { "" }
$minor = if ($match.Success) { $match.Groups[2].Value } else { "" }
$compatible = ($major -eq $RequiredMajor -and $minor -eq $RequiredMinor)

[pscustomobject]@{
  found = $true
  path = $godotPath
  version_output = $versionText
  required = "Godot $RequiredMajor.$RequiredMinor"
  platform = (Get-CgsPlatform)
  compatible = $compatible
  severity = if ($compatible) { "OK" } else { "WARN" }
  message = if ($compatible) {
    "Godot CLI is available and matches the recommended minor version."
  } else {
    "Godot CLI was found, but it is not Godot $RequiredMajor.$RequiredMinor. Prefer Godot 4.4 for generated projects unless the user chooses another version."
  }
} | ConvertTo-Json -Depth 4


