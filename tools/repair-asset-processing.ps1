param(
  [string]$Root = ".",
  [string]$AssetId = "",
  [int]$MaxAttempts = 4,
  [switch]$Apply
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$workflow = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_workflows.py"

. $pythonHelper

$argsList = @(
  $workflow,
  "repair-assets",
  "--root", $Root,
  "--max-attempts", "$MaxAttempts"
)

if (![string]::IsNullOrWhiteSpace($AssetId)) { $argsList += @("--asset-id", $AssetId) }
if ($Apply) { $argsList += "--apply" }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
