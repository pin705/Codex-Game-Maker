param(
  [Parameter(Mandatory = $true)]
  [string]$Spec,
  [Parameter(Mandatory = $true)]
  [Alias("Input")]
  [string]$InputPath,
  [string]$Report = "",
  [string]$KeyColor = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$harness = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_harness.py"

. $pythonHelper

$argsList = @(
  $harness,
  "validate",
  "--spec", (Resolve-Path -LiteralPath $Spec).Path,
  "--input", (Resolve-Path -LiteralPath $InputPath).Path
)

if (![string]::IsNullOrWhiteSpace($Report)) { $argsList += @("--report", $Report) }
if (![string]::IsNullOrWhiteSpace($KeyColor)) { $argsList += @("--key-color", $KeyColor) }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
