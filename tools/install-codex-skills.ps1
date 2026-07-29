param(
  [string]$RepoRoot = ".",
  [string]$CodexHome = "",
  [switch]$Force
)

$repo = Resolve-Path -LiteralPath $RepoRoot
$repoPath = $repo.Path

$pluginRoot = ""
if ((Test-Path -LiteralPath (Join-Path $repoPath "skills")) -and (Test-Path -LiteralPath (Join-Path $repoPath "references"))) {
  $pluginRoot = $repoPath
} elseif (Test-Path -LiteralPath (Join-Path $repoPath "codex-game-studio/skills")) {
  $pluginRoot = Join-Path $repoPath "codex-game-studio"
} elseif (Test-Path -LiteralPath (Join-Path $repoPath "plugins/codex-game-maker/skills")) {
  $pluginRoot = Join-Path $repoPath "plugins/codex-game-maker"
} else {
  throw "Cannot locate a Codex Game Maker plugin root under: $repoPath"
}

$platformHelper = Join-Path $pluginRoot "scripts/lib/cgs_platform.ps1"
if (Test-Path -LiteralPath $platformHelper) {
  . $platformHelper
}

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
  if (Get-Command Get-CgsDefaultCodexHome -ErrorAction SilentlyContinue) {
    $CodexHome = Get-CgsDefaultCodexHome
  } elseif (![string]::IsNullOrWhiteSpace($HOME)) {
    $CodexHome = Join-Path $HOME ".codex"
  } else {
    $CodexHome = Join-Path $env:USERPROFILE ".codex"
  }
}

$skillsRoot = Join-Path $pluginRoot "skills"
$referencesRoot = Join-Path $pluginRoot "references"
$scriptsRoot = Join-Path $pluginRoot "scripts"
$toolsRoot = Join-Path $pluginRoot "tools"
if (!(Test-Path -LiteralPath $toolsRoot)) {
  $toolsRoot = Join-Path $repoPath "tools"
}
$destSkillsRoot = Join-Path $CodexHome "skills"

if (!(Test-Path -LiteralPath $skillsRoot)) {
  throw "Cannot find skills directory: $skillsRoot"
}

New-Item -ItemType Directory -Force -Path $destSkillsRoot | Out-Null

foreach ($skill in Get-ChildItem -LiteralPath $skillsRoot -Directory) {
  $dest = Join-Path $destSkillsRoot $skill.Name

  if (Test-Path -LiteralPath $dest) {
    if (!$Force) {
      Write-Host "Skipping existing skill: $($skill.Name). Use -Force to replace it."
      continue
    }

    $resolvedDest = Resolve-Path -LiteralPath $dest
    $resolvedSkillsRoot = Resolve-Path -LiteralPath $destSkillsRoot
    if (!$resolvedDest.Path.StartsWith($resolvedSkillsRoot.Path, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove path outside Codex skills directory: $($resolvedDest.Path)"
    }
    Remove-Item -LiteralPath $resolvedDest.Path -Recurse -Force
  }

  Copy-Item -LiteralPath $skill.FullName -Destination $dest -Recurse

  if (Test-Path -LiteralPath $referencesRoot) {
    Copy-Item -LiteralPath $referencesRoot -Destination (Join-Path $dest "references") -Recurse
  }

  if (Test-Path -LiteralPath $scriptsRoot) {
    Copy-Item -LiteralPath $scriptsRoot -Destination (Join-Path $dest "scripts") -Recurse
  }

  if (Test-Path -LiteralPath $toolsRoot) {
    Copy-Item -LiteralPath $toolsRoot -Destination (Join-Path $dest "tools") -Recurse
  }

  $installedSkill = Join-Path $dest "SKILL.md"
  if (Test-Path -LiteralPath $installedSkill) {
    $content = [System.IO.File]::ReadAllText($installedSkill)
    $content = $content.Replace("../../references/", "references/")
    $content = $content.Replace("../../scripts/", "scripts/")
    $content = $content.Replace("../../../tools/", "tools/")
    $content = $content.Replace("../../tools/", "tools/")
    [System.IO.File]::WriteAllText($installedSkill, $content, [System.Text.UTF8Encoding]::new($false))
  }

  Write-Host "Installed skill: $($skill.Name)"
}

Write-Host ""
Write-Host "Installed Codex Game Maker skills into: $destSkillsRoot"
Write-Host "Restart Codex to pick up new skills."

