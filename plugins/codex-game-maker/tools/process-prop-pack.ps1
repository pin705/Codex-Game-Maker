param(
  [Parameter(Mandatory = $true)]
  [Alias("Input")]
  [string]$InputPath,
  [Parameter(Mandatory = $true)]
  [string]$OutDir,
  [Parameter(Mandatory = $true)]
  [int]$Rows,
  [Parameter(Mandatory = $true)]
  [int]$Cols,
  [string]$AssetId = "prop-pack",
  [int]$ExpectedProps = 0,
  [double]$FitScale = 0.94,
  [string]$KeyColor = "#FF00FF",
  [int]$Tolerance = 24,
  [int]$Softness = 16
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$processor = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_processor.py"

. $pythonHelper

$argsList = @(
  $processor,
  "prop-pack",
  "--input", (Resolve-Path -LiteralPath $InputPath).Path,
  "--out-dir", $OutDir,
  "--asset-id", $AssetId,
  "--rows", "$Rows",
  "--cols", "$Cols",
  "--expected-props", "$ExpectedProps",
  "--fit-scale", "$FitScale",
  "--key-color", $KeyColor,
  "--tolerance", "$Tolerance",
  "--softness", "$Softness"
)

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
