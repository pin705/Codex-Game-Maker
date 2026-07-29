param(
  [string]$Version = "4.6.2",
  [string]$Status = "stable",
  [string]$InstallDir = "",
  [switch]$Force,
  [switch]$KeepDownloads
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$installer = Join-Path $repoRoot.Path "scripts/install_godot.py"
. $pythonHelper

$arguments = @($installer, "--version", $Version, "--status", $Status, "--with-export-templates")
if (![string]::IsNullOrWhiteSpace($InstallDir)) { $arguments += @("--install-dir", $InstallDir) }
if ($Force) { $arguments += "--force" }
if ($KeepDownloads) { $arguments += "--keep-downloads" }
Invoke-CgsPython -Arguments $arguments
exit $LASTEXITCODE
