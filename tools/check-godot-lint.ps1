param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
$lintGate = Join-Path $repoRoot.Path "scripts/guards/godot_lint_gate.ps1"

if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}
if (!(Test-Path -LiteralPath $lintGate)) {
  throw "Cannot find Godot lint gate script: $lintGate"
}

. $platformHelper

$argsList = @("-Root", $Root)
if ($Strict) {
  $argsList += "-Strict"
}

Invoke-CgsPowerShellScript -ScriptPath $lintGate -ArgumentList $argsList
exit $LASTEXITCODE
