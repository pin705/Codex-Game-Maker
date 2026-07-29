param(
  [Parameter(Mandatory = $true)]
  [string]$Description
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$processor = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_processor.py"

. $pythonHelper

$argsList = @(
  $processor,
  "suggest-key",
  "--description", $Description
)

Invoke-CgsPython -Arguments $argsList
exit $LASTEXITCODE
