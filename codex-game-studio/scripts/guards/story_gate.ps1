param(
  [string]$Root = ".",
  [string]$Story = "",
  [ValidateSet("Ready", "Done")]
  [string]$Mode = "Ready",
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

function Get-SectionText([string]$Text, [string]$Name) {
  $pattern = "(?ms)^##\s+" + [regex]::Escape($Name) + "\s*\r?\n(?<body>.*?)(?=^##\s+|\z)"
  $match = [regex]::Match($Text, $pattern)
  if ($match.Success) { return $match.Groups["body"].Value.Trim() }
  return ""
}

function Is-PlaceholderOnly([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
  $trimmed = $Value.Trim()
  if ($trimmed -match '^\[[^\]]+\]$') { return $true }
  if ($trimmed -match '^- \[[^\]]+\]\s*$') { return $true }
  return $false
}

$resolved = Resolve-Path -LiteralPath $Root
$rootPath = $resolved.Path
$blockers = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$evidence = [System.Collections.ArrayList]::new()
$stories = @()

if (![string]::IsNullOrWhiteSpace($Story)) {
  $storyPath = if ([System.IO.Path]::IsPathRooted($Story)) { $Story } else { Join-Path $rootPath $Story }
  if (Test-Path -LiteralPath $storyPath) {
    $stories = @(Get-Item -LiteralPath $storyPath)
  } else {
    Add-Item $blockers "story.not_found" "Story file was not found: $Story" $storyPath
  }
} else {
  $storyDir = Join-Path $rootPath "production/stories"
  if (Test-Path -LiteralPath $storyDir) {
    $stories = @(Get-ChildItem -LiteralPath $storyDir -File -Filter "*.md" | Sort-Object Name)
  }
}

if ($stories.Count -eq 0 -and $blockers.Count -eq 0) {
  Add-Item $blockers "story.missing" "No story files found. Create production/stories/STORY-0001-[name].md from implementation-story.md." (Join-Path $rootPath "production/stories")
}

$storyResults = [System.Collections.ArrayList]::new()

foreach ($storyFile in $stories) {
  $text = Get-Content -Raw -LiteralPath $storyFile.FullName
  $storyWarnings = [System.Collections.ArrayList]::new()
  $storyBlockers = [System.Collections.ArrayList]::new()

  foreach ($section in @("Player Value", "Goal", "Acceptance Criteria", "Verification Plan")) {
    if (!(Test-Section $text $section)) {
      Add-Item $storyBlockers "story.section.missing" "Missing required section: $section" $storyFile.FullName
    }
  }

  if (!(Test-Section $text "Files To Touch")) {
    Add-Item $storyWarnings "story.files_to_touch.missing" "Missing Files To Touch section." $storyFile.FullName
  }

  $goalText = Get-SectionText $text "Goal"
  if (Is-PlaceholderOnly $goalText) {
    Add-Item $storyBlockers "story.goal.placeholder" "Goal is empty or still placeholder text." $storyFile.FullName
  }

  $acceptance = Get-SectionText $text "Acceptance Criteria"
  $criteriaMatches = @([regex]::Matches($acceptance, '(?m)^\s*-\s+\[( |x|X)\]\s+(.+)$'))
  if ($criteriaMatches.Count -eq 0) {
    Add-Item $storyBlockers "story.acceptance.missing" "Acceptance Criteria must contain checklist items." $storyFile.FullName
  }

  $checked = @($criteriaMatches | Where-Object { $_.Groups[1].Value -match 'x|X' }).Count
  $unchecked = $criteriaMatches.Count - $checked

  $verification = Get-SectionText $text "Verification Plan"
  if (Is-PlaceholderOnly $verification) {
    Add-Item $storyWarnings "story.verification.placeholder" "Verification Plan is empty or still placeholder text." $storyFile.FullName
  }

  if ($Mode -eq "Done") {
    if ($unchecked -gt 0) {
      Add-Item $storyBlockers "story.acceptance.unchecked" "$unchecked acceptance criteria are still unchecked." $storyFile.FullName
    }

    if (!(Test-Section $text "Evidence")) {
      Add-Item $storyBlockers "story.evidence.missing" "Done mode requires an Evidence section." $storyFile.FullName
    } else {
      $evidenceText = Get-SectionText $text "Evidence"
      if (Is-PlaceholderOnly $evidenceText -or $evidenceText -match '\[command -> result\]') {
        Add-Item $storyBlockers "story.evidence.placeholder" "Evidence section is empty or still placeholder text." $storyFile.FullName
      }
    }
  }

  foreach ($item in $storyWarnings) { Add-Item $warnings $item.code $item.message $item.path }
  foreach ($item in $storyBlockers) { Add-Item $blockers $item.code $item.message $item.path }

  [void]$storyResults.Add([pscustomobject]@{
    path = $storyFile.FullName
    criteria_total = $criteriaMatches.Count
    criteria_checked = $checked
    criteria_unchecked = $unchecked
    warnings = $storyWarnings
    blockers = $storyBlockers
  })

  Add-Item $evidence "story.read" "Story file checked: $($storyFile.Name)" $storyFile.FullName
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
  mode = $Mode
  gate = $gate
  stories_checked = $stories.Count
  blockers = $blockers
  warnings = $warnings
  evidence = $evidence
  stories = $storyResults
} | ConvertTo-Json -Depth 7
