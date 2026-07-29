param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
$releaseGate = Join-Path $repoRoot.Path "scripts/guards/release_gate.ps1"

if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}
if (!(Test-Path -LiteralPath $releaseGate)) {
  throw "Cannot find release gate script: $releaseGate"
}

. $platformHelper

$argsList = @("-Root", $Root)
if ($Strict) {
  $argsList += "-Strict"
}

Invoke-CgsPowerShellScript -ScriptPath $releaseGate -ArgumentList $argsList
exit $LASTEXITCODE
