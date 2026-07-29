param(
  [string]$Root = ".",
  [switch]$SkipQuality
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$cli = Join-Path $repoRoot.Path "scripts/cgm.py"
if (!(Test-Path -LiteralPath $cli)) {
  throw "Cannot find cross-platform Codex Game Maker CLI: $cli"
}

$python = Get-Command python3 -ErrorAction SilentlyContinue
if (!$python) { $python = Get-Command python -ErrorAction SilentlyContinue }
if (!$python) { throw "Python 3 is required for the commercial release gate." }

$arguments = @($cli, "commercial-release", "--root", $Root)
if ($SkipQuality) { $arguments += "--skip-quality" }
& $python.Source @arguments
exit $LASTEXITCODE
