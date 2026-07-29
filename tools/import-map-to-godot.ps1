param(
  [string]$Project = ".",
  [string]$AssetId = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$workflow = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_workflows.py"

. $pythonHelper

$argsList = @(
  $workflow,
  "godot-map",
  "--project", $Project
)

if (![string]::IsNullOrWhiteSpace($AssetId)) { $argsList += @("--asset-id", $AssetId) }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
