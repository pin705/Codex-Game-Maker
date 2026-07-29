param(
  [string]$Root = "."
)

$resolved = Resolve-Path -LiteralPath $Root
$rootPath = $resolved.Path

function Get-RelativeToRoot($path) {
  $rootFull = [System.IO.Path]::GetFullPath($rootPath).TrimEnd([char[]]@('\', '/'))
  $pathFull = [System.IO.Path]::GetFullPath($path)
  $prefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
  if ($pathFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $pathFull.Substring($prefix.Length).Replace("\", "/")
  }
  return $pathFull.Replace("\", "/")
}

function Has-AnyAtRoot($patterns) {
  foreach ($pattern in $patterns) {
    if (Get-ChildItem -LiteralPath $rootPath -Force -ErrorAction SilentlyContinue -Filter $pattern | Select-Object -First 1) {
      return $true
    }
  }
  return $false
}

function Test-ExactRootChildName($name) {
  $children = @(Get-ChildItem -LiteralPath $rootPath -Force -ErrorAction SilentlyContinue)
  foreach ($child in $children) {
    if ([string]::Equals($child.Name, $name, [System.StringComparison]::Ordinal)) {
      return $true
    }
  }
  return $false
}

function Find-NestedProjects($fileName) {
  $matches = Get-ChildItem -LiteralPath $rootPath -Recurse -Force -ErrorAction SilentlyContinue -Filter $fileName |
    Where-Object {
      $normalized = $_.FullName.Replace("\", "/")
      ($_.DirectoryName -ne $rootPath) -and
        ($normalized -notmatch "/\.git/") -and
        ($normalized -notmatch "/\.research/")
    }

  @($matches | ForEach-Object {
    Get-RelativeToRoot $_.DirectoryName
  } | Sort-Object -Unique)
}

$signals = [ordered]@{
  Godot = @()
  Unity = @()
  Unreal = @()
  Web = @()
}

$nestedProjects = [ordered]@{
  Godot = @(Find-NestedProjects "project.godot")
  Unreal = @(Find-NestedProjects "*.uproject")
}

if (Test-Path -LiteralPath (Join-Path $rootPath "project.godot")) { $signals.Godot += "project.godot" }
if (Test-Path -LiteralPath (Join-Path $rootPath ".godot")) { $signals.Godot += ".godot/" }
if ($signals.Godot.Count -gt 0 -and (Has-AnyAtRoot @("*.tscn", "*.tres", "*.gd"))) { $signals.Godot += "Godot root scene/resource/script files" }

if (Test-ExactRootChildName "Assets") { $signals.Unity += "Assets/" }
if ((Test-ExactRootChildName "ProjectSettings") -and (Test-Path -LiteralPath (Join-Path $rootPath "ProjectSettings/ProjectVersion.txt"))) { $signals.Unity += "ProjectSettings/ProjectVersion.txt" }
if ((Test-ExactRootChildName "Packages") -and (Test-Path -LiteralPath (Join-Path $rootPath "Packages/manifest.json"))) { $signals.Unity += "Packages/manifest.json" }

if (Has-AnyAtRoot @("*.uproject")) { $signals.Unreal += "*.uproject" }
if (Test-Path -LiteralPath (Join-Path $rootPath "Config/DefaultEngine.ini")) { $signals.Unreal += "Config/DefaultEngine.ini" }
if (Has-AnyAtRoot @("*.Build.cs")) { $signals.Unreal += "*.Build.cs" }

if (Test-Path -LiteralPath (Join-Path $rootPath "package.json")) { $signals.Web += "package.json" }
if (Has-AnyAtRoot @("vite.config.*", "next.config.*")) { $signals.Web += "Vite/Next config" }

$detected = @()
foreach ($key in $signals.Keys) {
  if ($signals[$key].Count -gt 0) { $detected += $key }
}

$recommendation = if ($detected.Count -eq 0) {
  if ($nestedProjects.Godot.Count -gt 0) {
    "No root engine project detected. Nested Godot project(s) found: $($nestedProjects.Godot -join ', '). Open one of those folders, or start a new root project with Godot 4.7.1 + Web export."
  } else {
    "Blank project: recommend Godot 4.7.1 + Web export."
  }
} elseif ($detected -contains "Godot") {
  "Existing Godot project: continue with Godot."
} elseif ($detected -contains "Unity") {
  "Existing Unity project: continue with Unity unless the user asks to migrate."
} elseif ($detected -contains "Unreal") {
  "Existing Unreal project: continue with Unreal unless the user asks to migrate."
} elseif ($detected -contains "Web") {
  "Existing web project: continue with current web stack; do not recommend Phaser/Three/Pixi unless requested."
} else {
  "Mixed or unknown project: inspect manually before recommending an engine."
}

[pscustomobject]@{
  root = $rootPath
  detected_engines = $detected
  signals = $signals
  nested_projects = $nestedProjects
  recommendation = $recommendation
} | ConvertTo-Json -Depth 5
