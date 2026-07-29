param(
  [string]$InstallDir = "",
  [switch]$NoPath,
  [switch]$WithExportTemplates,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}

. $platformHelper

$version = "4.4"
$status = "stable"
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
  $InstallDir = Join-Path $repoRoot.Path ".tools/godot"
}

$installBase = [System.IO.Path]::GetFullPath($InstallDir)
$profile = Get-CgsGodotInstallProfile -Version $version -Status $status -InstallBase $installBase
$zipPath = Join-Path $profile.install_root $profile.file_name

Write-Host "Codex Game Maker - Godot 4.4 Setup"
Write-Host "Detected OS: $($profile.platform) ($($profile.architecture))"
Write-Host "Install directory: $($profile.install_root)"
Write-Host "Command wrapper: $($profile.wrapper_path)"

New-Item -ItemType Directory -Force -Path $profile.install_root | Out-Null

if ((Test-Path -LiteralPath $profile.executable_path) -and !$Force) {
  Write-Host "Godot 4.4 already exists: $($profile.executable_path)"
} else {
  Write-Host "Downloading Godot 4.4 stable from official GitHub release..."
  Write-Host "  $($profile.download_url)"
  Invoke-WebRequest -Uri $profile.download_url -OutFile $zipPath

  Write-Host "Extracting..."
  Expand-Archive -LiteralPath $zipPath -DestinationPath $profile.install_root -Force
  Remove-Item -LiteralPath $zipPath -Force

  if (!(Test-Path -LiteralPath $profile.executable_path)) {
    $found = Get-ChildItem -LiteralPath $profile.install_root -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "Godot_v4.4-stable*" -or $_.Name -eq "Godot" } |
      Select-Object -First 1
    if ($found) {
      Write-Host "Found extracted Godot executable candidate: $($found.FullName)"
    } else {
      throw "Godot executable was not found after extraction."
    }
  }
}

if (!(Test-Path -LiteralPath $profile.executable_path)) {
  throw "Godot executable was not found at expected path: $($profile.executable_path)"
}

Write-CgsGodotWrapper -Profile $profile
Write-Host "Command wrapper created: $($profile.wrapper_path)"

if (!$NoPath) {
  $pathResult = Add-CgsPathEntry -Entry $profile.bin_dir
  Write-Host $pathResult.message
  Write-Host "Restart Codex or your terminal so PATH changes are picked up."
} else {
  Write-Host "Skipped PATH update because -NoPath was provided."
}

Write-Host ""
Write-Host "Done. Test with:"
Write-Host "  godot --version"
if ((Get-CgsPlatform) -eq "windows") {
  Write-Host "  powershell -ExecutionPolicy Bypass -File tools\check-godot.ps1"
} else {
  Write-Host "  pwsh -File tools/check-godot.ps1"
}

if ($WithExportTemplates) {
  $templatesScript = Join-Path $repoRoot.Path "tools/install-godot-export-templates.ps1"
  if (!(Test-Path -LiteralPath $templatesScript)) {
    throw "Cannot find export templates installer: $templatesScript"
  }

  Write-Host ""
  Write-Host "Installing Godot export templates for browser preview..."
  Invoke-CgsPowerShellScript -ScriptPath $templatesScript
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
  Write-Host ""
  Write-Host "For browser preview/export, also run:"
  if ((Get-CgsPlatform) -eq "windows") {
    Write-Host "  powershell -ExecutionPolicy Bypass -File tools\install-godot-export-templates.ps1"
  } else {
    Write-Host "  pwsh -File tools/install-godot-export-templates.ps1"
  }
}


