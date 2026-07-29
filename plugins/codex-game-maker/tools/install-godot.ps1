param(
  [string]$InstallDir = "",
  [string]$Version = "4.6.2",
  [string]$Status = "stable",
  [switch]$WithExportTemplates,
  [switch]$Force,
  [switch]$AddToPath,
  [switch]$KeepDownloads,
  [string]$Sha512 = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
$installer = Join-Path $repoRoot.Path "scripts/install_godot.py"
. $pythonHelper
. $platformHelper

$arguments = @($installer, "--version", $Version, "--status", $Status)
if (![string]::IsNullOrWhiteSpace($InstallDir)) { $arguments += @("--install-dir", $InstallDir) }
if ($WithExportTemplates) { $arguments += "--with-export-templates" }
if ($Force) { $arguments += "--force" }
if ($KeepDownloads) { $arguments += "--keep-downloads" }
if (![string]::IsNullOrWhiteSpace($Sha512)) { $arguments += @("--sha512", $Sha512) }

Invoke-CgsPython -Arguments $arguments
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($AddToPath) {
  if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    throw "-AddToPath requires an explicit stable -InstallDir so PATH never points into a versioned plugin cache."
  }
  $pathResult = Add-CgsPathEntry -Entry (Join-Path ([System.IO.Path]::GetFullPath($InstallDir)) "bin")
  Write-Host $pathResult.message
}
