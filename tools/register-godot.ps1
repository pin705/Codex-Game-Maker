param(
  [Parameter(Mandatory = $true)]
  [string]$GodotPath,
  [string]$InstallDir = "",
  [switch]$NoPath
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_platform.ps1"
if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}

. $platformHelper

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
  $InstallDir = Join-Path $repoRoot.Path ".tools/godot"
}

$executable = Resolve-CgsGodotExecutable -Candidate $GodotPath
if (!$executable) {
  throw "Cannot find a Godot executable under: $GodotPath"
}

$platform = Get-CgsPlatform
$binDir = Join-Path ([System.IO.Path]::GetFullPath($InstallDir)) "bin"
$wrapperName = if ($platform -eq "windows") { "godot.cmd" } else { "godot" }
$profile = [pscustomobject]@{
  platform = $platform
  executable_path = $executable
  bin_dir = $binDir
  wrapper_path = Join-Path $binDir $wrapperName
}

Write-CgsGodotWrapper -Profile $profile

$versionOutput = & $profile.wrapper_path --version 2>&1 | Select-Object -First 1
$pathResult = $null
if (!$NoPath) {
  $pathResult = Add-CgsPathEntry -Entry $binDir
}

[pscustomobject]@{
  registered = $true
  platform = $platform
  executable = $executable
  wrapper = $profile.wrapper_path
  added_to_path = if ($pathResult) { [bool]$pathResult.changed } else { $false }
  path_message = if ($pathResult) { $pathResult.message } else { "Skipped PATH update because -NoPath was provided." }
  version_output = "$versionOutput"
} | ConvertTo-Json -Depth 4
