param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
$productionGate = Join-Path $repoRoot.Path "scripts/guards/production_gate.ps1"

if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}
if (!(Test-Path -LiteralPath $productionGate)) {
  throw "Cannot find production gate script: $productionGate"
}

. $platformHelper

$argsList = @("-Root", $Root)
if ($Strict) {
  $argsList += "-Strict"
}

Invoke-CgsPowerShellScript -ScriptPath $productionGate -ArgumentList $argsList
exit $LASTEXITCODE
