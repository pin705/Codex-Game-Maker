param(
  [string]$Root = ".",
  [Parameter(Mandatory = $true)]
  [string]$AssetId,
  [Parameter(Mandatory = $true)]
  [string]$Description,
  [string]$Category = "characters",
  [string]$View = "side",
  [ValidateSet("auto", "none", "full_directional", "side_only_last_horizontal")]
  [string]$DirectionModel = "auto",
  [string]$Actions = "idle,run,jump,attack,hurt",
  [string]$KeyColor = "suggest",
  [string]$ReferenceFile = "",
  [int]$CellWidth = 384,
  [int]$CellHeight = 384,
  [int]$JumpCellHeight = 512,
  [int]$SafeMargin = 56,
  [int]$MaxFootDrift = 18,
  [double]$MaxScaleDrift = 0.16,
  [double]$FitScale = 0.92,
  [int]$Tolerance = 70,
  [int]$Softness = 32,
  [switch]$ProcessExistingRaw
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$workflow = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_workflows.py"

. $pythonHelper

$argsList = @(
  $workflow,
  "action-bundle",
  "--root", $Root,
  "--asset-id", $AssetId,
  "--description", $Description,
  "--category", $Category,
  "--view", $View,
  "--direction-model", $DirectionModel,
  "--actions", $Actions,
  "--key-color", $KeyColor,
  "--cell-width", "$CellWidth",
  "--cell-height", "$CellHeight",
  "--jump-cell-height", "$JumpCellHeight",
  "--safe-margin", "$SafeMargin",
  "--max-foot-drift", "$MaxFootDrift",
  "--max-scale-drift", "$MaxScaleDrift",
  "--fit-scale", "$FitScale",
  "--tolerance", "$Tolerance",
  "--softness", "$Softness"
)

if (![string]::IsNullOrWhiteSpace($ReferenceFile)) { $argsList += @("--reference-file", $ReferenceFile) }
if ($ProcessExistingRaw) { $argsList += "--process-existing-raw" }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
