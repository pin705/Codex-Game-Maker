param(
  [Parameter(Mandatory = $true)]
  [string]$Spec,
  [Parameter(Mandatory = $true)]
  [Alias("Input")]
  [string]$InputPath,
  [Parameter(Mandatory = $true)]
  [string]$Output,
  [string]$Meta = "",
  [ValidateSet("auto", "grid", "components", "largest")]
  [string]$Method = "auto",
  [int]$SourceRows = 0,
  [int]$SourceCols = 0,
  [string]$KeyColor = "",
  [int]$Tolerance = -1,
  [double]$FitScale = 1.0,
  [int]$Padding = 2,
  [ValidateSet("", "center", "bottom", "feet")]
  [string]$Anchor = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_python.ps1"
$harness = Join-Path $repoRoot.Path "codex-game-studio/scripts/assets/cgs_asset_harness.py"

. $pythonHelper

$argsList = @(
  $harness,
  "rectify",
  "--spec", (Resolve-Path -LiteralPath $Spec).Path,
  "--input", (Resolve-Path -LiteralPath $InputPath).Path,
  "--output", $Output,
  "--method", $Method,
  "--source-rows", "$SourceRows",
  "--source-cols", "$SourceCols",
  "--tolerance", "$Tolerance",
  "--fit-scale", "$FitScale",
  "--padding", "$Padding"
)

if (![string]::IsNullOrWhiteSpace($Meta)) { $argsList += @("--meta", $Meta) }
if (![string]::IsNullOrWhiteSpace($KeyColor)) { $argsList += @("--key-color", $KeyColor) }
if (![string]::IsNullOrWhiteSpace($Anchor)) { $argsList += @("--anchor", $Anchor) }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
