param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

function Add-Item([System.Collections.ArrayList]$List, [string]$Code, [string]$Message, [string]$Path = "") {
  [void]$List.Add([pscustomobject]@{
    code = $Code
    message = $Message
    path = $Path
  })
}

function Test-Section([string]$Text, [string]$Name) {
  return $Text -match ("(?mi)^##\s+" + [regex]::Escape($Name) + "\s*$")
}

function Count-Unchecked([string]$Text) {
  return @([regex]::Matches($Text, '(?m)^\s*-\s+\[ \]\s+')).Count
}

$resolved = Resolve-Path -LiteralPath $Root
$rootPath = $resolved.Path
$releaseDir = Join-Path $rootPath "production/releases"
$buildWebDir = Join-Path $rootPath "build/web"

$blockers = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$evidence = [System.Collections.ArrayList]::new()

$releaseFiles = if (Test-Path -LiteralPath $releaseDir) {
  @(Get-ChildItem -LiteralPath $releaseDir -File -Filter "*release*.md" -ErrorAction SilentlyContinue)
} else {
  @()
}

if ($releaseFiles.Count -eq 0) {
  Add-Item $blockers "release.checklist.missing" "No release checklist found under production/releases." $releaseDir
} else {
  foreach ($file in $releaseFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($section in @("Build Evidence", "Content Readiness", "Player-Facing Notes", "Gate Results")) {
      if (!(Test-Section $text $section)) {
        Add-Item $blockers "release.section.missing" "Release checklist is missing section: $section" $file.FullName
      }
    }

    $unchecked = Count-Unchecked $text
    if ($unchecked -gt 0) {
      Add-Item $warnings "release.unchecked_items" "Release checklist has $unchecked unchecked item(s)." $file.FullName
    }

    Add-Item $evidence "release.checklist" "Release checklist found: $($file.Name)" $file.FullName
  }
}

$changelogFiles = @()
$rootChangelog = Join-Path $rootPath "CHANGELOG.md"
if (Test-Path -LiteralPath $rootChangelog) { $changelogFiles += Get-Item -LiteralPath $rootChangelog }
if (Test-Path -LiteralPath $releaseDir) {
  $changelogFiles += Get-ChildItem -LiteralPath $releaseDir -File -Filter "*changelog*.md" -ErrorAction SilentlyContinue
}

if ($changelogFiles.Count -eq 0) {
  Add-Item $warnings "release.changelog.missing" "No CHANGELOG.md or release changelog found."
} else {
  Add-Item $evidence "release.changelog" "Changelog found." $changelogFiles[0].FullName
}

$patchFiles = if (Test-Path -LiteralPath $releaseDir) {
  @(Get-ChildItem -LiteralPath $releaseDir -File -Filter "*patch*.md" -ErrorAction SilentlyContinue)
} else {
  @()
}
if ($patchFiles.Count -gt 0) {
  Add-Item $evidence "release.patch_notes" "Patch notes found." $patchFiles[0].FullName
}

$reviewEvidence = @()
foreach ($relative in @("production/reviews", "production/smoke-tests", "production/playtests")) {
  $dir = Join-Path $rootPath $relative
  if (Test-Path -LiteralPath $dir) {
    $reviewEvidence += Get-ChildItem -LiteralPath $dir -File -Filter "*.md" -ErrorAction SilentlyContinue
  }
}
if ($reviewEvidence.Count -eq 0) {
  Add-Item $warnings "release.evidence.missing" "No review/smoke/playtest evidence found for release."
} else {
  Add-Item $evidence "release.evidence" "Release evidence files found: $($reviewEvidence.Count)." $reviewEvidence[0].FullName
}

if (Test-Path -LiteralPath (Join-Path $rootPath "project.godot")) {
  $webFiles = @("index.html", "index.js", "index.wasm", "index.pck")
  $missing = @()
  foreach ($file in $webFiles) {
    if (!(Test-Path -LiteralPath (Join-Path $buildWebDir $file))) { $missing += $file }
  }

  if ($missing.Count -eq 0) {
    Add-Item $evidence "release.web_build" "Godot Web build files exist." $buildWebDir
  } else {
    Add-Item $warnings "release.web_build.missing" "Godot Web build is missing or incomplete: $($missing -join ', ')."
  }
}

if ($Strict -and $warnings.Count -gt 0) {
  Add-Item $blockers "strict.warnings" "Strict mode treats warnings as blockers."
}

$gate = if ($blockers.Count -gt 0) {
  "BLOCKED"
} elseif ($warnings.Count -gt 0) {
  "PASS_WITH_WARNINGS"
} else {
  "PASS"
}

[pscustomobject]@{
  root = $rootPath
  gate = $gate
  release_checklists = $releaseFiles.Count
  changelogs = $changelogFiles.Count
  patch_notes = $patchFiles.Count
  blockers = $blockers
  warnings = $warnings
  evidence = $evidence
} | ConvertTo-Json -Depth 6
