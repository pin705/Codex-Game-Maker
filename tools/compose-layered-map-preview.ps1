param(
  [Parameter(Mandatory = $true)]
  [string]$Base,
  [Parameter(Mandatory = $true)]
  [string]$Placements,
  [Parameter(Mandatory = $true)]
  [string]$Out
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$processor = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_processor.py"

. $pythonHelper

$argsList = @(
  $processor,
  "layered-preview",
  "--base", (Resolve-Path -LiteralPath $Base).Path,
  "--placements", (Resolve-Path -LiteralPath $Placements).Path,
  "--out", $Out
)

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
