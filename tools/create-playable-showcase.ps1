param(
  [string]$Root = ".",
  [string]$Name = "asset-pipeline-showcase",
  [string]$Title = "Asset Pipeline Showcase"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_python.ps1"
$workflow = Join-Path $repoRoot.Path "codex-game-studio/scripts/assets/cgs_asset_workflows.py"

. $pythonHelper

$argsList = @(
  $workflow,
  "showcase",
  "--root", $Root,
  "--name", $Name,
  "--title", $Title
)

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
