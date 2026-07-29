param(
  [string]$Version = "4.4",
  [string]$Status = "stable",
  [string]$DownloadDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}

. $platformHelper

if ([string]::IsNullOrWhiteSpace($DownloadDir)) {
  $DownloadDir = Join-Path $repoRoot.Path ".tools/godot"
}

$releaseTag = "$Version-$Status"
$templateVersion = "$Version.$Status"
$fileName = "Godot_v$Version-$Status" + "_export_templates.tpz"
$url = "https://github.com/godotengine/godot-builds/releases/download/$releaseTag/$fileName"
$templateRoot = Get-CgsGodotExportTemplatesRoot
$targetDir = Join-Path $templateRoot $templateVersion
$downloadPath = Join-Path $DownloadDir $fileName
$zipPath = Join-Path $DownloadDir ($fileName + ".zip")
$extractDir = Join-Path $DownloadDir "export-templates-$templateVersion"

Write-Host "Codex Game Maker - Godot export templates setup"
Write-Host "Template version: $templateVersion"
Write-Host "Install directory: $targetDir"

if ((Test-Path -LiteralPath (Join-Path $targetDir "web_release.zip")) -and !$Force) {
  Write-Host "Export templates already appear to be installed."
  Write-Host "Use -Force to reinstall."
  exit 0
}

New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if ((Test-Path -LiteralPath $extractDir) -and $Force) {
  Remove-Item -LiteralPath $extractDir -Recurse -Force
}

Write-Host "Downloading official Godot export templates..."
Invoke-WebRequest -Uri $url -OutFile $downloadPath

if (Test-Path -LiteralPath $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}
Copy-Item -LiteralPath $downloadPath -Destination $zipPath -Force

Write-Host "Extracting templates..."
New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

$templatesFolder = Join-Path $extractDir "templates"
if (!(Test-Path -LiteralPath $templatesFolder)) {
  throw "The extracted TPZ did not contain a templates folder."
}

Copy-Item -Path (Join-Path $templatesFolder "*") -Destination $targetDir -Recurse -Force
[System.IO.File]::WriteAllText((Join-Path $targetDir "version.txt"), $templateVersion, [System.Text.Encoding]::ASCII)

Remove-Item -LiteralPath $zipPath -Force

Write-Host ""
Write-Host "Done. Godot export templates installed:"
Write-Host "  $targetDir"
Write-Host "You can now export Web builds with:"
if ((Get-CgsPlatform) -eq "windows") {
  Write-Host "  powershell -ExecutionPolicy Bypass -File tools\export-godot-web.ps1 -Project ."
} else {
  Write-Host "  pwsh -File tools/export-godot-web.ps1 -Project ."
}


