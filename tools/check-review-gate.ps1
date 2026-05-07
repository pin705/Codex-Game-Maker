param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_platform.ps1"
$reviewGate = Join-Path $repoRoot.Path "codex-game-studio/scripts/guards/review_gate.ps1"

if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}
if (!(Test-Path -LiteralPath $reviewGate)) {
  throw "Cannot find review gate script: $reviewGate"
}

. $platformHelper

$argsList = @("-Root", $Root)
if ($Strict) {
  $argsList += "-Strict"
}

Invoke-CgsPowerShellScript -ScriptPath $reviewGate -ArgumentList $argsList
exit $LASTEXITCODE
