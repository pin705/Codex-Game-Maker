param(
  [string]$Root = ".",
  [string]$OutDir = "",
  [Parameter(Mandatory = $true)]
  [string]$AssetId,
  [ValidateSet("sprite", "platform", "prop", "fx", "map-object")]
  [string]$Kind = "sprite",
  [string]$Action = "",
  [int]$Rows = 3,
  [int]$Cols = 4,
  [int]$CellWidth = 384,
  [int]$CellHeight = 384,
  [int]$SafeMargin = 48,
  [string]$KeyColor = "#FF00FF",
  [int]$FootLine = 0,
  [string]$Pivot = "bottom",
  [int]$EdgeGuard = 0,
  [int]$MaxFootDrift = 18,
  [double]$MaxScaleDrift = 0.16,
  [switch]$AllowEmptyCells,
  [switch]$AllowHorizontalEdgeTouch,
  [switch]$AllowVerticalEdgeTouch,
  [switch]$Loop
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_python.ps1"
$harness = Join-Path $repoRoot.Path "codex-game-studio/scripts/assets/cgs_asset_harness.py"

. $pythonHelper

$rootPath = (Resolve-Path -LiteralPath $Root).Path
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $rootPath "design/assets/harnesses"
}

$argsList = @(
  $harness,
  "create",
  "--out-dir", $OutDir,
  "--asset-id", $AssetId,
  "--kind", $Kind,
  "--rows", "$Rows",
  "--cols", "$Cols",
  "--cell-width", "$CellWidth",
  "--cell-height", "$CellHeight",
  "--safe-margin", "$SafeMargin",
  "--key-color", $KeyColor,
  "--foot-line", "$FootLine",
  "--pivot", $Pivot,
  "--edge-guard", "$EdgeGuard",
  "--max-foot-drift", "$MaxFootDrift",
  "--max-scale-drift", "$MaxScaleDrift"
)

if (![string]::IsNullOrWhiteSpace($Action)) { $argsList += @("--action", $Action) }
if ($AllowEmptyCells) { $argsList += "--allow-empty-cells" }
if ($AllowHorizontalEdgeTouch) { $argsList += "--allow-horizontal-edge-touch" }
if ($AllowVerticalEdgeTouch) { $argsList += "--allow-vertical-edge-touch" }
if ($Loop) { $argsList += "--loop" }

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
