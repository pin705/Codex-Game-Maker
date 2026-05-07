param(
  [string]$Root = ".",
  [string]$Story = "",
  [ValidateSet("Ready", "Done")]
  [string]$Mode = "Ready",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_platform.ps1"
$storyGate = Join-Path $repoRoot.Path "codex-game-studio/scripts/guards/story_gate.ps1"

if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}
if (!(Test-Path -LiteralPath $storyGate)) {
  throw "Cannot find story gate script: $storyGate"
}

. $platformHelper

$argsList = @("-Root", $Root, "-Mode", $Mode)

if (![string]::IsNullOrWhiteSpace($Story)) {
  $argsList += @("-Story", $Story)
}

if ($Strict) {
  $argsList += "-Strict"
}

Invoke-CgsPowerShellScript -ScriptPath $storyGate -ArgumentList $argsList
exit $LASTEXITCODE
