param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
$assetGate = Join-Path $repoRoot.Path "scripts/guards/asset_gate.ps1"

if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}
if (!(Test-Path -LiteralPath $assetGate)) {
  throw "Cannot find asset gate script: $assetGate"
}

. $platformHelper

$argsList = @("-Root", $Root)
if ($Strict) {
  $argsList += "-Strict"
}

Invoke-CgsPowerShellScript -ScriptPath $assetGate -ArgumentList $argsList
exit $LASTEXITCODE
