param(
  [string]$Root = ".",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

function Add-Item([System.Collections.ArrayList]$List, [string]$Code, [string]$Message, [string]$Path = "", [int]$Line = 0) {
  [void]$List.Add([pscustomobject]@{
    code = $Code
    message = $Message
    path = $Path
    line = $Line
  })
}

function Get-RelativePathSafe([string]$Base, [string]$Path) {
  $baseFull = [System.IO.Path]::GetFullPath($Base).TrimEnd([char[]]@('\', '/'))
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  $prefix = $baseFull + [System.IO.Path]::DirectorySeparatorChar
  if ($pathFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $pathFull.Substring($prefix.Length).Replace("\", "/")
  }
  return $pathFull.Replace("\", "/")
}

function Resolve-ResPath([string]$ProjectRoot, [string]$ResPath) {
  $clean = $ResPath.Trim().Trim('"', "'")
  if (!$clean.StartsWith("res://")) { return "" }
  $relative = $clean.Substring(6).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
  return Join-Path $ProjectRoot $relative
}

function Get-FunctionBody([string[]]$Lines, [int]$StartIndex) {
  $body = [System.Collections.ArrayList]::new()
  for ($i = $StartIndex + 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^\s*func\s+') { break }
    [void]$body.Add($Lines[$i])
  }
  return ($body -join "`n")
}

$resolved = Resolve-Path -LiteralPath $Root
$rootPath = $resolved.Path
$blockers = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$evidence = [System.Collections.ArrayList]::new()

$projectFile = Join-Path $rootPath "project.godot"
if (!(Test-Path -LiteralPath $projectFile)) {
  Add-Item $warnings "godot.project.missing" "No project.godot found. Godot lint only checks root Godot projects." $projectFile
}

$gdFiles = @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter "*.gd" -ErrorAction SilentlyContinue |
  Where-Object {
    $normalized = $_.FullName.Replace("\", "/")
    $normalized -notmatch "/\.godot/" -and
    $normalized -notmatch "/build/" -and
    $normalized -notmatch "/\.import/"
  })

if ($gdFiles.Count -eq 0) {
  Add-Item $warnings "gdscript.missing" "No .gd files found to lint." $rootPath
}

foreach ($file in $gdFiles) {
  $relative = Get-RelativePathSafe $rootPath $file.FullName
  $text = Get-Content -Raw -LiteralPath $file.FullName
  $lines = Get-Content -LiteralPath $file.FullName

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    if ($line -match '^\s*func\s+_(physics_process|process)\s*\(([^)]*)\)') {
      $args = $matches[2]
      $deltaMatch = [regex]::Match($args, '(^|,\s*)(?<name>_?delta)\b')
      if ($deltaMatch.Success) {
        $deltaName = $deltaMatch.Groups["name"].Value
        $body = Get-FunctionBody $lines $i
        if ($deltaName -eq "delta" -and $body -notmatch '\bdelta\b') {
          Add-Item $warnings "godot.delta.unused" "$($matches[1]) declares delta but does not appear to use it. Rename to _delta or use delta for frame-rate independent logic." $file.FullName ($i + 1)
        }
      }
    }

    foreach ($pathMatch in [regex]::Matches($line, 'res://[^"''\)\]\s]+')) {
      $target = Resolve-ResPath $rootPath $pathMatch.Value
      if (![string]::IsNullOrWhiteSpace($target) -and !(Test-Path -LiteralPath $target)) {
        Add-Item $blockers "godot.res_path.missing" "res:// path points to a missing file: $($pathMatch.Value)" $file.FullName ($i + 1)
      }
    }
  }

  $numericMatches = @([regex]::Matches($text, '(?<![A-Za-z0-9_])(?<num>\d+(?:\.\d+)?)(?![A-Za-z0-9_])'))
  $meaningfulNumbers = @($numericMatches | Where-Object {
    $n = $_.Groups["num"].Value
    $n -notin @("0", "1", "2") -and
    $_.Value -notmatch '^\d{4}$'
  })

  $hasTuningResource = ($text -match '@export') -or ($text -match 'Resource') -or ($relative -match '^scripts/resources/')
  $isGameplay = $relative -match '(^|/)scripts/(gameplay|player|enemy|combat|level)/' -or $relative -match '(^|/)(player|enemy|main)\.gd$'
  if ($isGameplay -and !$hasTuningResource -and $meaningfulNumbers.Count -ge 8) {
    Add-Item $warnings "godot.hardcoded_numbers" "Gameplay script has many numeric literals. Move tuning values to @export variables or resources." $file.FullName 1
  }

  $isUiScript = $relative -match '(^|/)(ui|hud|menus?)/' -or $text -match 'extends\s+(Control|CanvasLayer|Panel|Button|Label)'
  if ($isUiScript -and $text -match '(get_node\(".*(Player|Game|World|Level).*"\)|\$.*(Player|Game|World|Level).*=|\.health\s*=|\.score\s*=)') {
    Add-Item $warnings "godot.ui_gameplay_coupling" "UI script appears to mutate or directly reach into gameplay state. Prefer signals or a narrow interface." $file.FullName 1
  }

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $classMatch = [regex]::Match($text, '(?m)^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)')
  if ($classMatch.Success) {
    $className = $classMatch.Groups[1].Value
    $normalizedBase = ($baseName -replace '[_\-]', '').ToLowerInvariant()
    $normalizedClass = ($className -replace '[_\-]', '').ToLowerInvariant()
    if ($normalizedBase -ne $normalizedClass) {
      Add-Item $warnings "godot.naming.class_file_mismatch" "class_name '$className' does not match file name '$baseName'." $file.FullName 1
    }
  }
}

$sceneFiles = @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter "*.tscn" -ErrorAction SilentlyContinue |
  Where-Object {
    $normalized = $_.FullName.Replace("\", "/")
    $normalized -notmatch "/\.godot/" -and $normalized -notmatch "/build/"
  })

foreach ($scene in $sceneFiles) {
  $sceneText = Get-Content -Raw -LiteralPath $scene.FullName
  foreach ($pathMatch in [regex]::Matches($sceneText, 'res://[^"''\)\]\s]+')) {
    $target = Resolve-ResPath $rootPath $pathMatch.Value
    if (![string]::IsNullOrWhiteSpace($target) -and !(Test-Path -LiteralPath $target)) {
      Add-Item $blockers "godot.scene_res_path.missing" "Scene references a missing res:// file: $($pathMatch.Value)" $scene.FullName 1
    }
  }
}

if (Test-Path -LiteralPath (Join-Path $rootPath "export_presets.cfg")) {
  $presetText = Get-Content -Raw -LiteralPath (Join-Path $rootPath "export_presets.cfg")
  if ($presetText -match 'platform="Web"') {
    Add-Item $evidence "godot.web_preset" "Web export preset exists." (Join-Path $rootPath "export_presets.cfg")
  }
} else {
  Add-Item $warnings "godot.web_preset.missing" "No export_presets.cfg found. Web export preview may need -CreatePresetIfMissing."
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
  gdscript_files = $gdFiles.Count
  scene_files = $sceneFiles.Count
  blockers = $blockers
  warnings = $warnings
  evidence = $evidence
} | ConvertTo-Json -Depth 6
