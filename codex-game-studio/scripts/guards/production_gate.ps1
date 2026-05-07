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

function Count-Checklist([string]$Text, [string]$PrefixPattern) {
  return @([regex]::Matches($Text, "(?mi)^\s*-\s+\[( |x|X)\]\s+$PrefixPattern")).Count
}

$resolved = Resolve-Path -LiteralPath $Root
$rootPath = $resolved.Path
$blockers = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$evidence = [System.Collections.ArrayList]::new()

$epicDir = Join-Path $rootPath "production/epics"
$storyDir = Join-Path $rootPath "production/stories"
$sprintDir = Join-Path $rootPath "production/sprints"

$epics = if (Test-Path -LiteralPath $epicDir) { @(Get-ChildItem -LiteralPath $epicDir -File -Filter "*.md") } else { @() }
$stories = if (Test-Path -LiteralPath $storyDir) { @(Get-ChildItem -LiteralPath $storyDir -File -Filter "*.md") } else { @() }
$sprints = if (Test-Path -LiteralPath $sprintDir) { @(Get-ChildItem -LiteralPath $sprintDir -File -Filter "*.md") } else { @() }

if ($epics.Count -eq 0 -and $stories.Count -eq 0 -and $sprints.Count -eq 0) {
  Add-Item $warnings "production.not_started" "No production epics/stories/sprints found. This is acceptable before implementation planning starts." (Join-Path $rootPath "production")
}

foreach ($epic in $epics) {
  $text = Get-Content -Raw -LiteralPath $epic.FullName
  foreach ($section in @("Player Outcome", "Scope", "Stories", "Acceptance")) {
    if (!(Test-Section $text $section)) {
      Add-Item $blockers "epic.section.missing" "Epic is missing section: $section" $epic.FullName
    }
  }

  $storyRefs = Count-Checklist $text "STORY-\d+"
  if ($storyRefs -lt 3 -or $storyRefs -gt 7) {
    Add-Item $warnings "epic.story_count" "Epic should reference 3-7 small stories; found $storyRefs." $epic.FullName
  }

  Add-Item $evidence "epic.read" "Epic checked: $($epic.Name)" $epic.FullName
}

foreach ($sprint in $sprints) {
  $text = Get-Content -Raw -LiteralPath $sprint.FullName
  foreach ($section in @("Selected Stories", "Definition Of Done")) {
    if (!(Test-Section $text $section)) {
      Add-Item $blockers "sprint.section.missing" "Sprint plan/status is missing section: $section" $sprint.FullName
    }
  }

  $selectedStories = Count-Checklist $text "STORY-\d+"
  if ($selectedStories -eq 0) {
    Add-Item $warnings "sprint.no_selected_stories" "Sprint has no selected STORY-* checklist items." $sprint.FullName
  } elseif ($selectedStories -gt 5) {
    Add-Item $warnings "sprint.too_many_stories" "Sprint selects $selectedStories stories. Keep sprints small and verifiable." $sprint.FullName
  }

  if ($text -notmatch 'check-story-gate\.ps1' -or $text -notmatch 'check-review-gate\.ps1') {
    Add-Item $warnings "sprint.done_checks.missing" "Sprint Definition Of Done should reference story and review gates." $sprint.FullName
  }

  Add-Item $evidence "sprint.read" "Sprint file checked: $($sprint.Name)" $sprint.FullName
}

if ($epics.Count -gt 0 -and $stories.Count -eq 0) {
  Add-Item $blockers "production.stories.missing" "Epics exist, but production/stories has no story files." $storyDir
}

if ($stories.Count -gt 0) {
  Add-Item $evidence "stories.present" "Implementation stories found: $($stories.Count)." $storyDir
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
  epics = $epics.Count
  stories = $stories.Count
  sprints = $sprints.Count
  blockers = $blockers
  warnings = $warnings
  evidence = $evidence
} | ConvertTo-Json -Depth 6
