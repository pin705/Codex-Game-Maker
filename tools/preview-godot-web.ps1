param(
  [string]$Project = ".",
  [string]$Out = "build/web",
  [string]$Preset = "Web",
  [int]$Port = 8060,
  [string]$GodotPath = "",
  [switch]$Debug,
  [switch]$SkipExport,
  [switch]$NoOpen,
  [switch]$CreatePresetIfMissing
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_platform.ps1"
if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}

. $platformHelper

$projectPath = (Resolve-Path -LiteralPath $Project).Path
$outPath = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path $projectPath $Out }
$exportScript = Join-Path $PSScriptRoot "export-godot-web.ps1"
$serveScript = Join-Path $PSScriptRoot "serve-godot-web.ps1"

if (!$SkipExport) {
  $exportArgs = @("-Project", $projectPath, "-Out", $outPath, "-Preset", $Preset)

  if (![string]::IsNullOrWhiteSpace($GodotPath)) { $exportArgs += @("-GodotPath", $GodotPath) }
  if ($Debug) { $exportArgs += "-Debug" }
  if ($CreatePresetIfMissing) { $exportArgs += "-CreatePresetIfMissing" }

  Invoke-CgsPowerShellScript -ScriptPath $exportScript -ArgumentList $exportArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Godot Web export failed. Fix the error above before previewing."
  }
}

$serveArgs = @("-Root", $outPath, "-Port", "$Port")

if (!$NoOpen) { $serveArgs += "-Open" }

Invoke-CgsPowerShellScript -ScriptPath $serveScript -ArgumentList $serveArgs
exit $LASTEXITCODE
