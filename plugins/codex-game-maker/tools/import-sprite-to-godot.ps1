param(
  [string]$Project = ".",
  [Parameter(Mandatory = $true)]
  [string]$BundleId,
  [string]$AssetIds = "",
  [string]$SceneName = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$workflow = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_workflows.py"

. $pythonHelper

$argsList = @(
  $workflow,
  "godot-sprite",
  "--project", $Project,
  "--bundle-id", $BundleId
)

if (![string]::IsNullOrWhiteSpace($AssetIds)) { $argsList += @("--asset-ids", $AssetIds) }
if (![string]::IsNullOrWhiteSpace($SceneName)) { $argsList += @("--scene-name", $SceneName) }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
