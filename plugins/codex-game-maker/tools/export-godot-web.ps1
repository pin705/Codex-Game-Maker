param(
  [string]$Project = ".",
  [string]$Out = "build/web",
  [string]$Preset = "Web",
  [string]$GodotPath = "",
  [switch]$Debug,
  [switch]$CreatePresetIfMissing
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_platform.ps1"
if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}

. $platformHelper

function Get-GodotTemplateVersion {
  param([string]$VersionOutput)

  $match = [regex]::Match($VersionOutput, '^(\d+\.\d+(?:\.\d+)?)\.([A-Za-z]+)')
  if ($match.Success) {
    return "$($match.Groups[1].Value).$($match.Groups[2].Value.ToLowerInvariant())"
  }

  $fallback = [regex]::Match($VersionOutput, '^(\d+\.\d+)')
  if ($fallback.Success) {
    return "$($fallback.Groups[1].Value).stable"
  }

  return "4.6.2.stable"
}

function Ensure-WebPreset {
  param(
    [string]$PresetFile,
    [string]$PresetName,
    [string]$ExportPath
  )

  $text = if (Test-Path -LiteralPath $PresetFile) { Get-Content -Raw -LiteralPath $PresetFile } else { "" }
  if ($text -match ('(?m)^name="' + [regex]::Escape($PresetName) + '"\r?$')) {
    return $false
  }

  if (!$CreatePresetIfMissing) {
    throw "No '$PresetName' export preset found in export_presets.cfg. Re-run with -CreatePresetIfMissing or add a Web preset in Godot."
  }

  $indices = [regex]::Matches($text, '(?m)^\[preset\.(\d+)\]') | ForEach-Object { [int]$_.Groups[1].Value }
  $nextIndex = if (@($indices).Count -gt 0) { (@($indices) | Measure-Object -Maximum).Maximum + 1 } else { 0 }
  $normalizedExportPath = $ExportPath.Replace("\", "/")

  $presetText = @"

[preset.$nextIndex]

name="$PresetName"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="$normalizedExportPath"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.$nextIndex.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
"@

  Add-Content -LiteralPath $PresetFile -Value $presetText
  return $true
}

$projectPath = (Resolve-Path -LiteralPath $Project).Path
$projectFile = Join-Path $projectPath "project.godot"
if (!(Test-Path -LiteralPath $projectFile)) {
  throw "Not a Godot project: $projectPath does not contain project.godot."
}

$outPath = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path $projectPath $Out }
New-Item -ItemType Directory -Force -Path $outPath | Out-Null
$htmlPath = Join-Path $outPath "index.html"
$projectFull = [System.IO.Path]::GetFullPath($projectPath).TrimEnd([char[]]@('\', '/'))
$htmlFull = [System.IO.Path]::GetFullPath($htmlPath)
$projectPrefix = $projectFull + [System.IO.Path]::DirectorySeparatorChar
$relativeHtmlPath = if ($htmlFull.StartsWith($projectPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
  $htmlFull.Substring($projectPrefix.Length)
} else {
  $htmlFull
}
$presetFile = Join-Path $projectPath "export_presets.cfg"

$createdPreset = Ensure-WebPreset -PresetFile $presetFile -PresetName $Preset -ExportPath $relativeHtmlPath

$godot = Find-CgsGodotCommand -Root $projectPath -GodotPath $GodotPath
if (!$godot) {
  throw "Godot CLI was not found. From the Codex Game Maker root, run tools/install-godot.ps1 with PowerShell."
}

$versionOutput = & $godot --version 2>&1 | Select-Object -First 1
$templateVersion = Get-GodotTemplateVersion -VersionOutput "$versionOutput"
$templateDir = Join-Path (Get-CgsGodotExportTemplatesRoot) $templateVersion
$releaseTemplate = Join-Path $templateDir "web_release.zip"
$debugTemplate = Join-Path $templateDir "web_debug.zip"
$neededTemplate = if ($Debug) { $debugTemplate } else { $releaseTemplate }

if (!(Test-Path -LiteralPath $neededTemplate)) {
  throw "Godot Web export template is missing: $neededTemplate. Run tools/install-godot-export-templates.ps1 with PowerShell."
}

$exportArg = if ($Debug) { "--export-debug" } else { "--export-release" }
$command = @("--headless", "--path", $projectPath, $exportArg, $Preset, $htmlPath)

Write-Host "Exporting Godot Web build..."
Write-Host "$godot $($command -join ' ')"
& $godot @command
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
  throw "Godot export failed with exit code $exitCode."
}

$expectedFiles = @("index.html", "index.js", "index.wasm", "index.pck")
$missing = @()
foreach ($file in $expectedFiles) {
  $candidate = Join-Path $outPath $file
  if (!(Test-Path -LiteralPath $candidate)) { $missing += $file }
}

[pscustomobject]@{
  exported = ($missing.Count -eq 0)
  project = $projectPath
  output = $outPath
  url_file = $htmlPath
  preset = $Preset
  debug = [bool]$Debug
  created_preset = $createdPreset
  godot = $godot
  godot_version = "$versionOutput"
  missing_files = $missing
} | ConvertTo-Json -Depth 4

