param(
  [string]$Root = ".",
  [Parameter(Mandatory = $true)]
  [string]$AssetId,
  [Parameter(Mandatory = $true)]
  [string]$ReferenceFile,
  [Parameter(Mandatory = $true)]
  [string]$Description,
  [string]$Actions = "idle,run,jump",
  [string]$KeyColor = "suggest",
  [switch]$Lookdev
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$workflow = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_workflows.py"

. $pythonHelper

$argsList = @(
  $workflow,
  "reference-variant",
  "--root", $Root,
  "--asset-id", $AssetId,
  "--reference-file", $ReferenceFile,
  "--description", $Description,
  "--actions", $Actions,
  "--key-color", $KeyColor
)
if ($Lookdev) { $argsList += "--lookdev" }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
