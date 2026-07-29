param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$repo = Resolve-Path -LiteralPath $Root
$repoPath = $repo.Path
$pluginJson = Join-Path $repoPath ".codex-plugin/plugin.json"
$skillsRoot = Join-Path $repoPath "skills"
$platformHelper = Join-Path $repoPath "scripts/lib/cgs_platform.ps1"
$engineDetector = Join-Path $repoPath "scripts/guards/detect_engine.ps1"
$reviewGate = Join-Path $repoPath "scripts/guards/review_gate.ps1"
$storyGate = Join-Path $repoPath "scripts/guards/story_gate.ps1"
$assetGate = Join-Path $repoPath "scripts/guards/asset_gate.ps1"
$godotLintGate = Join-Path $repoPath "scripts/guards/godot_lint_gate.ps1"
$productionGate = Join-Path $repoPath "scripts/guards/production_gate.ps1"
$releaseGate = Join-Path $repoPath "scripts/guards/release_gate.ps1"
$assetProcessor = Join-Path $repoPath "scripts/assets/cgs_asset_processor.py"
$assetHarness = Join-Path $repoPath "scripts/assets/cgs_asset_harness.py"
$pythonHelper = Join-Path $repoPath "scripts/lib/cgs_python.ps1"
$assetRequirements = Join-Path $repoPath "requirements-asset-tools.txt"
$godotChecker = Join-Path $repoPath "tools/check-godot.ps1"
$reviewGateWrapper = Join-Path $repoPath "tools/check-review-gate.ps1"
$storyGateWrapper = Join-Path $repoPath "tools/check-story-gate.ps1"
$assetGateWrapper = Join-Path $repoPath "tools/check-asset-gate.ps1"
$assetQaWrapper = Join-Path $repoPath "tools/check-asset-qa.ps1"
$assetToolsWrapper = Join-Path $repoPath "tools/check-asset-tools.ps1"
$keyColorSuggestWrapper = Join-Path $repoPath "tools/suggest-key-color.ps1"
$assetWorkflow = Join-Path $repoPath "scripts/assets/cgs_asset_workflows.py"
$godotLintWrapper = Join-Path $repoPath "tools/check-godot-lint.ps1"
$productionGateWrapper = Join-Path $repoPath "tools/check-production-gate.ps1"
$releaseGateWrapper = Join-Path $repoPath "tools/check-release-gate.ps1"
$commandsCatalog = Join-Path $repoPath "references/commands/catalog.yaml"
$playableShowcaseRules = Join-Path $repoPath "references/rules/playable-showcase-integration.md"
$topdownSurvivorRules = Join-Path $repoPath "references/rules/topdown-survivor-character-assets.md"
$previewTools = @(
  "tools/install-godot-export-templates.ps1",
  "tools/export-godot-web.ps1",
  "tools/serve-godot-web.ps1",
  "tools/preview-godot-web.ps1",
  "tools/register-godot.ps1",
  "tools/process-sprite-sheet.ps1",
  "tools/process-prop-pack.ps1",
  "tools/create-asset-harness.ps1",
  "tools/check-asset-harness.ps1",
  "tools/rectify-asset-to-harness.ps1",
  "tools/suggest-key-color.ps1",
  "tools/compose-layered-map-preview.ps1",
  "tools/create-action-bundle.ps1",
  "tools/repair-asset-processing.ps1",
  "tools/import-sprite-to-godot.ps1",
  "tools/import-map-to-godot.ps1",
  "tools/create-reference-variant-spec.ps1",
  "tools/create-playable-showcase.ps1",
  "tools/install-professional-hooks.ps1",
  "tools/uninstall-professional-hooks.ps1"
)

$assetTemplates = @(
  "references/templates/sprite-asset-spec.yaml",
  "references/templates/asset-harness-spec.yaml",
  "references/templates/map-asset-spec.yaml",
  "references/templates/asset-qa-report.md",
  "references/templates/godot-import-manifest.yaml",
  "references/templates/scene-scale-plan.yaml",
  "references/templates/action-bundle-spec.yaml",
  "references/templates/action-bundle-report.md",
  "references/templates/godot-sprite-import-spec.yaml",
  "references/templates/map-scene-import-spec.yaml",
  "references/templates/reference-variant-spec.yaml",
  "references/templates/topdown-survivor-character-contract.yaml",
  "references/templates/playable-showcase-qa.md"
)

$ok = $true

function Report($status, $message) {
  Write-Host "[$status] $message"
}

if (Test-Path -LiteralPath $platformHelper) {
  . $platformHelper
  Report "OK" "platform helper exists"
  Report "OK" "detected OS: $(Get-CgsPlatform) ($(Get-CgsArchitecture))"
} else {
  Report "FAIL" "Missing platform helper at $platformHelper"
  $ok = $false
}

if (Test-Path -LiteralPath $pluginJson) {
  try {
    Get-Content -Raw -LiteralPath $pluginJson | ConvertFrom-Json | Out-Null
    Report "OK" "plugin.json parses"
  } catch {
    Report "FAIL" "plugin.json is invalid JSON: $($_.Exception.Message)"
    $script:ok = $false
  }
} else {
  Report "FAIL" "Missing plugin.json at $pluginJson"
  $ok = $false
}

if (Test-Path -LiteralPath $skillsRoot) {
  $skills = Get-ChildItem -LiteralPath $skillsRoot -Directory
  if ($skills.Count -eq 0) {
    Report "FAIL" "No skills found under $skillsRoot"
    $ok = $false
  }

  foreach ($skill in $skills) {
    $skillFile = Join-Path $skill.FullName "SKILL.md"
    if (!(Test-Path -LiteralPath $skillFile)) {
      Report "FAIL" "$($skill.Name) is missing SKILL.md"
      $ok = $false
      continue
    }

    $content = Get-Content -Raw -LiteralPath $skillFile
    if ($content -notmatch "(?s)^---\s+.*name:\s*$($skill.Name).*description:\s+.*---") {
      Report "WARN" "$($skill.Name) SKILL.md exists, but frontmatter should be reviewed"
    } else {
      Report "OK" "$($skill.Name) skill frontmatter found"
    }
  }
} else {
  Report "FAIL" "Missing skills directory at $skillsRoot"
  $ok = $false
}

if (Test-Path -LiteralPath $engineDetector) {
  Report "OK" "engine detector exists"
  $ps = Get-CgsPowerShellCommand
  $result = & $ps @(New-CgsPowerShellArgs -ScriptPath $engineDetector -ArgumentList @("-Root", $repoPath))
  Report "OK" "engine detector output:"
  Write-Host $result
} else {
  Report "FAIL" "Missing engine detector at $engineDetector"
  $ok = $false
}

if (Test-Path -LiteralPath $reviewGate) {
  Report "OK" "review gate exists"
} else {
  Report "FAIL" "Missing review gate at $reviewGate"
  $ok = $false
}

if (Test-Path -LiteralPath $reviewGateWrapper) {
  Report "OK" "review gate wrapper exists"
} else {
  Report "FAIL" "Missing review gate wrapper at $reviewGateWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $storyGate) {
  Report "OK" "story gate exists"
} else {
  Report "FAIL" "Missing story gate at $storyGate"
  $ok = $false
}

if (Test-Path -LiteralPath $storyGateWrapper) {
  Report "OK" "story gate wrapper exists"
} else {
  Report "FAIL" "Missing story gate wrapper at $storyGateWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $assetGate) {
  Report "OK" "asset gate exists"
} else {
  Report "FAIL" "Missing asset gate at $assetGate"
  $ok = $false
}

if (Test-Path -LiteralPath $assetGateWrapper) {
  Report "OK" "asset gate wrapper exists"
} else {
  Report "FAIL" "Missing asset gate wrapper at $assetGateWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $assetQaWrapper) {
  Report "OK" "asset QA wrapper exists"
} else {
  Report "FAIL" "Missing asset QA wrapper at $assetQaWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $assetToolsWrapper) {
  Report "OK" "asset tools checker exists"
} else {
  Report "FAIL" "Missing asset tools checker at $assetToolsWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $keyColorSuggestWrapper) {
  Report "OK" "asset key-color suggester exists"
} else {
  Report "FAIL" "Missing asset key-color suggester at $keyColorSuggestWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $assetProcessor) {
  Report "OK" "asset processor exists"
} else {
  Report "FAIL" "Missing asset processor at $assetProcessor"
  $ok = $false
}

if (Test-Path -LiteralPath $assetHarness) {
  Report "OK" "asset harness exists"
} else {
  Report "FAIL" "Missing asset harness at $assetHarness"
  $ok = $false
}

if (Test-Path -LiteralPath $assetWorkflow) {
  Report "OK" "asset workflow coordinator exists"
} else {
  Report "FAIL" "Missing asset workflow coordinator at $assetWorkflow"
  $ok = $false
}

if (Test-Path -LiteralPath $pythonHelper) {
  Report "OK" "Python helper exists"
} else {
  Report "FAIL" "Missing Python helper at $pythonHelper"
  $ok = $false
}

if (Test-Path -LiteralPath $assetRequirements) {
  Report "OK" "asset requirements file exists"
} else {
  Report "FAIL" "Missing asset requirements at $assetRequirements"
  $ok = $false
}

if (Test-Path -LiteralPath $godotLintGate) {
  Report "OK" "Godot lint gate exists"
} else {
  Report "FAIL" "Missing Godot lint gate at $godotLintGate"
  $ok = $false
}

if (Test-Path -LiteralPath $godotLintWrapper) {
  Report "OK" "Godot lint gate wrapper exists"
} else {
  Report "FAIL" "Missing Godot lint gate wrapper at $godotLintWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $productionGate) {
  Report "OK" "production gate exists"
} else {
  Report "FAIL" "Missing production gate at $productionGate"
  $ok = $false
}

if (Test-Path -LiteralPath $productionGateWrapper) {
  Report "OK" "production gate wrapper exists"
} else {
  Report "FAIL" "Missing production gate wrapper at $productionGateWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $releaseGate) {
  Report "OK" "release gate exists"
} else {
  Report "FAIL" "Missing release gate at $releaseGate"
  $ok = $false
}

if (Test-Path -LiteralPath $releaseGateWrapper) {
  Report "OK" "release gate wrapper exists"
} else {
  Report "FAIL" "Missing release gate wrapper at $releaseGateWrapper"
  $ok = $false
}

if (Test-Path -LiteralPath $commandsCatalog) {
  Report "OK" "professional command alias catalog exists"
} else {
  Report "FAIL" "Missing command alias catalog at $commandsCatalog"
  $ok = $false
}

if (Test-Path -LiteralPath $playableShowcaseRules) {
  Report "OK" "playable showcase integration rules exist"
} else {
  Report "FAIL" "Missing playable showcase integration rules at $playableShowcaseRules"
  $ok = $false
}

if (Test-Path -LiteralPath $topdownSurvivorRules) {
  Report "OK" "top-down survivor character rules exist"
} else {
  Report "FAIL" "Missing top-down survivor character rules at $topdownSurvivorRules"
  $ok = $false
}

foreach ($relativeTool in $previewTools) {
  $toolPath = Join-Path $repoPath $relativeTool
  if (Test-Path -LiteralPath $toolPath) {
    Report "OK" "$relativeTool exists"
  } else {
    Report "FAIL" "Missing preview tool: $relativeTool"
    $ok = $false
  }
}

foreach ($relativeTemplate in $assetTemplates) {
  $templatePath = Join-Path $repoPath $relativeTemplate
  if (Test-Path -LiteralPath $templatePath) {
    Report "OK" "$relativeTemplate exists"
  } else {
    Report "FAIL" "Missing asset template: $relativeTemplate"
    $ok = $false
  }
}

if (Test-Path -LiteralPath $godotChecker) {
  Report "OK" "Godot checker exists"
  $ps = Get-CgsPowerShellCommand
  $godotResult = & $ps @(New-CgsPowerShellArgs -ScriptPath $godotChecker)
  Report "OK" "Godot checker output:"
  Write-Host $godotResult
} else {
  Report "WARN" "Godot checker not found. This does not block setup, but beginners will get less guidance."
}

if ($ok) {
  Write-Host ""
  Report "OK" "Codex Game Maker basic setup looks ready."
  exit 0
}

Write-Host ""
Report "FAIL" "Codex Game Maker setup has issues to fix."
exit 1

