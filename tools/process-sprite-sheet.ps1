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
  [string]$AssetId = "sprite-asset",
  [int]$ExpectedFrames = 0,
  [ValidateSet("center", "bottom", "feet")]
  [string]$Anchor = "center",
  [double]$FitScale = 0.92,
  [string]$KeyColor = "#FF00FF",
  [int]$Tolerance = 24,
  [int]$Softness = 16,
  [int]$DurationMs = 140,
  [switch]$DirectionStrips,
  [switch]$NoSharedScale
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$processor = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_processor.py"

. $pythonHelper

$argsList = @(
  $processor,
  "sprite",
  "--input", (Resolve-Path -LiteralPath $InputPath).Path,
  "--out-dir", $OutDir,
  "--asset-id", $AssetId,
  "--rows", "$Rows",
  "--cols", "$Cols",
  "--expected-frames", "$ExpectedFrames",
  "--anchor", $Anchor,
  "--fit-scale", "$FitScale",
  "--key-color", $KeyColor,
  "--tolerance", "$Tolerance",
  "--softness", "$Softness",
  "--duration-ms", "$DurationMs"
)

if ($DirectionStrips) { $argsList += "--direction-strips" }
if ($NoSharedScale) { $argsList += "--no-shared-scale" }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
