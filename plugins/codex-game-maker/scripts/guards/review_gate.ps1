param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

$platformHelper = Join-Path (Split-Path -Parent $PSScriptRoot) "lib/cgs_platform.ps1"
if (!(Test-Path -LiteralPath $platformHelper)) {
  throw "Cannot find platform helper: $platformHelper"
}

. $platformHelper

function Add-Item([System.Collections.ArrayList]$List, [string]$Code, [string]$Message, [string]$Path = "") {
  [void]$List.Add([pscustomobject]@{
    code = $Code
    message = $Message
    path = $Path
  })
}

function Test-RelativePath([string]$Base, [string]$Relative) {
  $path = Join-Path $Base $Relative
  return Test-Path -LiteralPath $path
}

function Convert-ResPath([string]$ProjectRoot, [string]$ResPath) {
  if ([string]::IsNullOrWhiteSpace($ResPath)) { return "" }
  $clean = $ResPath.Trim().Trim('"')
  if ($clean.StartsWith("res://")) {
    $relative = $clean.Substring(6).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    return Join-Path $ProjectRoot $relative
  }
  return $clean
}

function Find-GodotCommand([string]$ProjectRoot) {
  return Find-CgsGodotCommand -Root $ProjectRoot
}

function Invoke-GuardJson([string]$ScriptPath, [string]$ProjectRoot, [string[]]$ExtraArgs = @()) {
  if (!(Test-Path -LiteralPath $ScriptPath)) { return $null }
  $ps = Get-CgsPowerShellCommand
  if (!$ps) {
    return [pscustomobject]@{
      gate = "BLOCKED"
      error = "PowerShell was not found for nested guard execution."
      blockers = @()
      warnings = @()
    }
  }

  $guardArgs = @("-Root", $ProjectRoot)
  $guardArgs += $ExtraArgs
  $args = New-CgsPowerShellArgs -ScriptPath $ScriptPath -ArgumentList $guardArgs
  $output = & $ps @args 2>&1
  if ($LASTEXITCODE -ne 0) {
    return [pscustomobject]@{
      gate = "BLOCKED"
      error = "$output"
      blockers = @()
      warnings = @()
    }
  }

  try {
    return ($output | Out-String | ConvertFrom-Json)
  } catch {
    return [pscustomobject]@{
      gate = "BLOCKED"
      error = "Guard did not return JSON: $output"
      blockers = @()
      warnings = @()
    }
  }
}

function Merge-GuardResult([string]$Name, $Result, [System.Collections.ArrayList]$Blockers, [System.Collections.ArrayList]$Warnings, [System.Collections.ArrayList]$Evidence) {
  if ($null -eq $Result) { return }

  Add-Item $Evidence "$Name.gate" "$Name gate result: $($Result.gate)"

  $blockerCount = if ($Result.blockers) { @($Result.blockers).Count } else { 0 }
  $warningCount = if ($Result.warnings) { @($Result.warnings).Count } else { 0 }

  if ($Result.gate -eq "BLOCKED") {
    Add-Item $Blockers "$Name.blocked" "$Name gate is BLOCKED ($blockerCount blockers, $warningCount warnings)."
  } elseif ($Result.gate -eq "PASS_WITH_WARNINGS") {
    Add-Item $Warnings "$Name.warnings" "$Name gate passed with warnings ($warningCount warnings)."
  }

  if ($Result.error) {
    Add-Item $Blockers "$Name.error" "$($Result.error)"
  }
}

$resolved = Resolve-Path -LiteralPath $Root
$rootPath = $resolved.Path

$blockers = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$evidence = [System.Collections.ArrayList]::new()
$checks = [System.Collections.ArrayList]::new()

$projectGodot = Join-Path $rootPath "project.godot"
$hasGodot = Test-Path -LiteralPath $projectGodot
$hasUnity = (Test-RelativePath $rootPath "Assets") -and (Test-RelativePath $rootPath "ProjectSettings")
$hasUnreal = @(Get-ChildItem -LiteralPath $rootPath -Filter "*.uproject" -File -ErrorAction SilentlyContinue).Count -gt 0
$hasWeb = Test-RelativePath $rootPath "package.json"

$engine = "Unknown"
if ($hasGodot) { $engine = "Godot" }
elseif ($hasUnity) { $engine = "Unity" }
elseif ($hasUnreal) { $engine = "Unreal" }
elseif ($hasWeb) { $engine = "Web" }

Add-Item $checks "engine.detected" "Detected engine: $engine"

if ($engine -eq "Unknown") {
  Add-Item $warnings "engine.missing" "No root engine project detected. Review can continue for docs, but playable readiness is not established."
}

if ($hasGodot) {
  Add-Item $evidence "godot.project" "project.godot exists." $projectGodot

  $projectText = Get-Content -Raw -LiteralPath $projectGodot
  $mainSceneMatch = [regex]::Match($projectText, '(?m)^\s*run/main_scene\s*=\s*"([^"]+)"')
  $mainScene = if ($mainSceneMatch.Success) { $mainSceneMatch.Groups[1].Value } else { "" }

  if ([string]::IsNullOrWhiteSpace($mainScene)) {
    Add-Item $warnings "godot.main_scene.missing" "project.godot does not define run/main_scene."
  } else {
    $mainScenePath = Convert-ResPath $rootPath $mainScene
    if (Test-Path -LiteralPath $mainScenePath) {
      Add-Item $evidence "godot.main_scene.exists" "Main scene exists: $mainScene" $mainScenePath
    } else {
      Add-Item $blockers "godot.main_scene.not_found" "project.godot points to a missing main scene: $mainScene" $mainScenePath
    }
  }

  $godotCmd = Find-GodotCommand $rootPath
  if ($godotCmd) {
    $versionOutput = & $godotCmd --version 2>&1 | Select-Object -First 1
    Add-Item $evidence "godot.cli.version" "Godot CLI found: $versionOutput" $godotCmd
    if ("$versionOutput" -notmatch "^4\.4") {
      Add-Item $warnings "godot.version.mismatch" "Godot CLI is available, but it does not appear to be Godot 4.4: $versionOutput" $godotCmd
    }
  } else {
    Add-Item $warnings "godot.cli.missing" "Godot CLI was not found. Run tools/install-godot.ps1 from the Codex Game Maker root for validation/export."
  }

  if (Test-RelativePath $rootPath "export_presets.cfg") {
    Add-Item $evidence "godot.export_presets" "export_presets.cfg exists." (Join-Path $rootPath "export_presets.cfg")
  } else {
    Add-Item $warnings "godot.export_presets.missing" "No export_presets.cfg found. Web/native export readiness is not established."
  }
}

$docChecks = @(
  @{ code = "doc.concept"; path = "design/gdd/game-concept.md"; message = "Concept doc exists." },
  @{ code = "doc.systems"; path = "design/gdd/systems-index.md"; message = "Systems index exists." },
  @{ code = "doc.art_bible"; path = "design/art/art-bible.md"; message = "Art bible exists." },
  @{ code = "doc.architecture"; path = "docs/architecture/architecture.md"; message = "Architecture doc exists." },
  @{ code = "doc.controls"; path = "docs/architecture/control-manifest.md"; message = "Control manifest exists." },
  @{ code = "doc.readme"; path = "README.md"; message = "README exists." }
)

foreach ($item in $docChecks) {
  $fullPath = Join-Path $rootPath $item.path
  if (Test-Path -LiteralPath $fullPath) {
    Add-Item $evidence $item.code $item.message $fullPath
  } else {
    Add-Item $warnings "$($item.code).missing" "Missing $($item.path)."
  }
}

$playtestFiles = @()
foreach ($relative in @("production/playtests", "production/reviews")) {
  $dir = Join-Path $rootPath $relative
  if (Test-Path -LiteralPath $dir) {
    $playtestFiles += Get-ChildItem -LiteralPath $dir -File -Filter "*.md" -ErrorAction SilentlyContinue
  }
}

if ($playtestFiles.Count -gt 0) {
  Add-Item $evidence "playtest.evidence" "Found playtest/review evidence files: $($playtestFiles.Count)." $playtestFiles[0].FullName
} else {
  Add-Item $warnings "playtest.evidence.missing" "No playtest or review evidence found under production/playtests or production/reviews."
}

$smokeDir = Join-Path $rootPath "production/smoke-tests"
$smokeFiles = if (Test-Path -LiteralPath $smokeDir) { @(Get-ChildItem -LiteralPath $smokeDir -File -Filter "*.md" -ErrorAction SilentlyContinue) } else { @() }
if ($smokeFiles.Count -gt 0) {
  Add-Item $evidence "smoke.evidence" "Smoke test evidence found: $($smokeFiles.Count)." $smokeFiles[0].FullName
} else {
  Add-Item $warnings "smoke.evidence.missing" "No smoke test evidence found under production/smoke-tests."
}

$regressionDir = Join-Path $rootPath "production/regression"
$regressionFiles = if (Test-Path -LiteralPath $regressionDir) { @(Get-ChildItem -LiteralPath $regressionDir -File -Filter "*.md" -ErrorAction SilentlyContinue) } else { @() }
if ($regressionFiles.Count -gt 0) {
  Add-Item $evidence "regression.evidence" "Regression checklist/evidence found: $($regressionFiles.Count)." $regressionFiles[0].FullName
}

$guardRoot = $PSScriptRoot
if ($hasGodot) {
  $lintResult = Invoke-GuardJson (Join-Path $guardRoot "godot_lint_gate.ps1") $rootPath
  Merge-GuardResult "godot_lint" $lintResult $blockers $warnings $evidence

  $webBuild = Join-Path $rootPath "build/web"
  $webFiles = @("index.html", "index.js", "index.wasm", "index.pck")
  $missingWebFiles = @()
  foreach ($file in $webFiles) {
    if (!(Test-Path -LiteralPath (Join-Path $webBuild $file))) { $missingWebFiles += $file }
  }
  if ($missingWebFiles.Count -eq 0) {
    Add-Item $evidence "web_preview.build" "Godot Web preview build files exist." $webBuild
  } else {
    Add-Item $warnings "web_preview.build.missing" "Godot Web preview build is missing or incomplete: $($missingWebFiles -join ', ')."
  }
}

$assetManifest = Join-Path $rootPath "design/assets/asset-manifest.yaml"
$generatedAssets = Join-Path $rootPath "assets/generated"

$sceneScaleCandidates = @(
  "design/scene-scale-plan.yaml",
  "design/scene-scale-plan.yml",
  "design/assets/scene-scale-plan.yaml",
  "design/assets/scene-scale-plan.yml"
)
$sceneScaleFiles = @()
foreach ($relative in $sceneScaleCandidates) {
  $candidate = Join-Path $rootPath $relative
  if (Test-Path -LiteralPath $candidate -PathType Leaf) { $sceneScaleFiles += $candidate }
}

$hasGeneratedRuntimeAssets = Test-Path -LiteralPath $generatedAssets
if ($hasGodot -and $hasGeneratedRuntimeAssets) {
  if ($sceneScaleFiles.Count -gt 0) {
    Add-Item $evidence "playable_showcase.scene_scale" "Scene scale plan exists for generated-asset runtime integration." $sceneScaleFiles[0]
  } else {
    Add-Item $warnings "playable_showcase.scene_scale.missing" "Generated runtime assets exist, but no scene-scale-plan.yaml was found under design/ or design/assets/."
  }

  $qaEvidence = @()
  foreach ($relative in @("production/playtests", "production/reviews", "production/smoke-tests", "production/regression")) {
    $dir = Join-Path $rootPath $relative
    if (Test-Path -LiteralPath $dir) {
      $candidateEvidence = @()
      $candidateEvidence += Get-ChildItem -LiteralPath $dir -File -Filter "*showcase*.md" -ErrorAction SilentlyContinue
      $candidateEvidence += Get-ChildItem -LiteralPath $dir -File -Filter "*playable*.md" -ErrorAction SilentlyContinue
      foreach ($file in @($candidateEvidence | Sort-Object FullName -Unique)) {
        $text = Get-Content -Raw -LiteralPath $file.FullName
        if ($text -notmatch "Not run yet") { $qaEvidence += $file }
      }
    }
  }
  if ($qaEvidence.Count -gt 0) {
    Add-Item $evidence "playable_showcase.qa" "Playable showcase QA evidence found: $($qaEvidence.Count)." $qaEvidence[0].FullName
  } else {
    Add-Item $warnings "playable_showcase.qa.missing" "Generated runtime assets exist, but no playable showcase QA evidence was found. Use references/templates/playable-showcase-qa.md."
  }
}

if ((Test-Path -LiteralPath $assetManifest) -or (Test-Path -LiteralPath $generatedAssets)) {
  $assetResult = Invoke-GuardJson (Join-Path $guardRoot "asset_gate.ps1") $rootPath
  Merge-GuardResult "asset" $assetResult $blockers $warnings $evidence
}

$productionStarted = (Test-Path -LiteralPath (Join-Path $rootPath "production/epics")) -or
  (Test-Path -LiteralPath (Join-Path $rootPath "production/sprints")) -or
  (Test-Path -LiteralPath (Join-Path $rootPath "production/stories"))
if ($productionStarted) {
  $productionResult = Invoke-GuardJson (Join-Path $guardRoot "production_gate.ps1") $rootPath
  Merge-GuardResult "production" $productionResult $blockers $warnings $evidence
}

$storiesDir = Join-Path $rootPath "production/stories"
if (Test-Path -LiteralPath $storiesDir) {
  $storyResult = Invoke-GuardJson (Join-Path $guardRoot "story_gate.ps1") $rootPath @("-Mode", "Done")
  Merge-GuardResult "story_done" $storyResult $blockers $warnings $evidence
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
  engine = $engine
  gate = $gate
  blockers = $blockers
  warnings = $warnings
  evidence = $evidence
  checks = $checks
} | ConvertTo-Json -Depth 6


