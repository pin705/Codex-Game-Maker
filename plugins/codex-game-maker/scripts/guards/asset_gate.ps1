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

function Clean-Value([string]$Value) {
  if ($null -eq $Value) { return "" }
  $trimmed = $Value.Trim()
  if (($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) -or ($trimmed.StartsWith("'") -and $trimmed.EndsWith("'"))) {
    return $trimmed.Substring(1, $trimmed.Length - 2)
  }
  return $trimmed
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

function Resolve-ProjectPath([string]$RootPath, [string]$MaybeRelative) {
  $clean = Clean-Value $MaybeRelative
  if ([string]::IsNullOrWhiteSpace($clean)) { return "" }
  if ($clean.StartsWith("res://")) {
    $clean = $clean.Substring(6)
  }
  $clean = $clean.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
  if ([System.IO.Path]::IsPathRooted($clean)) { return $clean }
  return Join-Path $RootPath $clean
}

function Get-ItemValue($Item, [string]$Name) {
  if ($null -eq $Item) { return "" }
  if ($Item.PSObject.Properties.Name -contains $Name) { return $Item.$Name }
  return ""
}

function Test-AcceptedStatus([string]$Status, [string]$SelectedFile) {
  return ($Status -match '^(accepted|selected|in_use|done|complete)$') -or ![string]::IsNullOrWhiteSpace($SelectedFile)
}

function Read-JsonFile([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path -LiteralPath $Path)) { return $null }
  try {
    return (Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Get-JsonValue($Object, [string[]]$Path, $Default = $null) {
  $cursor = $Object
  foreach ($part in $Path) {
    if ($null -eq $cursor) { return $Default }
    if ($cursor.PSObject.Properties.Name -notcontains $part) { return $Default }
    $cursor = $cursor.$part
  }
  return $cursor
}

function Test-PathField(
  [System.Collections.ArrayList]$Blockers,
  [System.Collections.ArrayList]$Evidence,
  [string]$RootPath,
  [string]$AssetId,
  [string]$FieldName,
  [string]$FieldValue,
  [string]$MissingCode,
  [string]$MissingMessage,
  [switch]$RequireGenerated
) {
  if ([string]::IsNullOrWhiteSpace($FieldValue)) {
    Add-Item $Blockers $MissingCode $MissingMessage
    return ""
  }

  $resolved = Resolve-ProjectPath $RootPath $FieldValue
  if (!(Test-Path -LiteralPath $resolved)) {
    Add-Item $Blockers "$MissingCode.not_found" "$FieldName for $AssetId does not exist: $FieldValue" $resolved
    return $resolved
  }

  if ($RequireGenerated) {
    $relative = Get-RelativePathSafe $RootPath $resolved
    if ($relative -notmatch '^assets/generated/') {
      Add-Item $Blockers "$MissingCode.outside_generated" "$FieldName for $AssetId must live under assets/generated/: $FieldValue" $resolved
      return $resolved
    }
  }

  Add-Item $Evidence "$FieldName.exists" "$FieldName exists for $AssetId." $resolved
  return $resolved
}

function Add-GeneratedCoverage(
  [System.Collections.Generic.List[string]]$CoverageDirs,
  [string]$RootPath,
  [string]$Path,
  [switch]$UseParent
) {
  if ([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path -LiteralPath $Path)) { return }

  $item = Get-Item -LiteralPath $Path
  $coveragePath = if ($UseParent -and !$item.PSIsContainer) { $item.Directory.FullName } else { $item.FullName }
  $relative = Get-RelativePathSafe $RootPath $coveragePath

  if ($relative -match '^assets/generated/' -and !$CoverageDirs.Contains($relative)) {
    $CoverageDirs.Add($relative)
  }
}

function Test-IsCoveredGeneratedFile(
  [string]$RelativePath,
  [System.Collections.Generic.List[string]]$CoverageDirs
) {
  foreach ($dir in $CoverageDirs) {
    $normalized = $dir.TrimEnd("/")
    if ($RelativePath -eq $normalized -or $RelativePath.StartsWith($normalized + "/", [System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  return $false
}

function Parse-AssetManifest([string]$ManifestPath) {
  $items = [System.Collections.ArrayList]::new()
  if (!(Test-Path -LiteralPath $ManifestPath)) { return $items }

  $current = $null
  foreach ($line in Get-Content -LiteralPath $ManifestPath) {
    if ($line -match '^\s*-\s+asset_id:\s*(.+?)\s*$') {
      if ($null -ne $current) { [void]$items.Add([pscustomobject]$current) }
      $current = [ordered]@{ asset_id = Clean-Value $matches[1] }
      continue
    }

    if ($null -ne $current -and $line -match '^\s+([A-Za-z0-9_\-]+):\s*(.*?)\s*$') {
      $current[$matches[1]] = Clean-Value $matches[2]
    }
  }

  if ($null -ne $current) { [void]$items.Add([pscustomobject]$current) }
  return $items
}

function Find-PromptForAsset([string]$RootPath, [string]$AssetId) {
  if ([string]::IsNullOrWhiteSpace($AssetId)) { return "" }
  $promptRoot = Join-Path $RootPath "assets/source-prompts"
  if (!(Test-Path -LiteralPath $promptRoot)) { return "" }

  foreach ($ext in @("yaml", "yml", "md", "json", "txt")) {
    $candidate = Join-Path $promptRoot "$AssetId.$ext"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }

  $match = Get-ChildItem -LiteralPath $promptRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.BaseName -ieq $AssetId } |
    Select-Object -First 1

  if ($match) { return $match.FullName }
  return ""
}

$resolved = Resolve-Path -LiteralPath $Root
$rootPath = $resolved.Path
$manifestPath = Join-Path $rootPath "design/assets/asset-manifest.yaml"
$generatedRoot = Join-Path $rootPath "assets/generated"
$promptsRoot = Join-Path $rootPath "assets/source-prompts"
$godotProject = Join-Path $rootPath "project.godot"
$godotImportManifest = Join-Path $rootPath "design/assets/godot-import-manifest.yaml"
$styleLockPath = Join-Path $rootPath "design/art/style-lock.json"
$hasGodot = Test-Path -LiteralPath $godotProject

$blockers = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$evidence = [System.Collections.ArrayList]::new()
$styleLock = Read-JsonFile $styleLockPath
$expectedStyleVersion = ""
$expectedStyleDigest = ""
if ($null -eq $styleLock) {
  Add-Item $blockers "style_lock.missing" "Missing or invalid design/art/style-lock.json." $styleLockPath
} else {
  $expectedStyleVersion = (Get-JsonValue $styleLock @("style_version") "").ToString()
  $expectedStyleDigest = (Get-JsonValue $styleLock @("digest") "").ToString()
  if ([string]::IsNullOrWhiteSpace($expectedStyleVersion) -or $expectedStyleDigest -notmatch '^[0-9a-f]{64}$') {
    Add-Item $blockers "style_lock.invalid" "Style lock needs a version and SHA-256 digest." $styleLockPath
  }
}

$generatedFiles = @()
if (Test-Path -LiteralPath $generatedRoot) {
  $generatedFiles = @(Get-ChildItem -LiteralPath $generatedRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension.ToLowerInvariant() -in @(".png", ".jpg", ".jpeg", ".webp") })
}

$promptFiles = @()
if (Test-Path -LiteralPath $promptsRoot) {
  $promptFiles = @(Get-ChildItem -LiteralPath $promptsRoot -Recurse -File -ErrorAction SilentlyContinue)
}

$manifestExists = Test-Path -LiteralPath $manifestPath
if ($manifestExists) {
  Add-Item $evidence "manifest.exists" "Asset manifest exists." $manifestPath
} elseif ($generatedFiles.Count -gt 0) {
  Add-Item $blockers "manifest.missing" "Generated assets exist, but design/assets/asset-manifest.yaml is missing." $manifestPath
} else {
  Add-Item $warnings "manifest.not_started" "No asset manifest found. This is acceptable before the generated asset pipeline starts." $manifestPath
}

$manifestItems = @(Parse-AssetManifest $manifestPath)
if ($manifestExists -and $manifestItems.Count -eq 0) {
  Add-Item $warnings "manifest.empty" "Asset manifest exists but contains no parsed asset entries." $manifestPath
}

$selectedRelative = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$promptRelative = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$coveredGeneratedDirs = [System.Collections.Generic.List[string]]::new()

foreach ($item in $manifestItems) {
  $assetId = Get-ItemValue $item "asset_id"
  $status = Get-ItemValue $item "status"
  $selected = Get-ItemValue $item "selected_file"
  $sourcePrompt = Get-ItemValue $item "source_prompt"
  $assetKind = (Get-ItemValue $item "asset_kind").ToString().ToLowerInvariant()
  $rawFile = Get-ItemValue $item "raw_file"
  $processedFile = Get-ItemValue $item "processed_file"
  $framesDir = Get-ItemValue $item "frames_dir"
  $gifPreview = Get-ItemValue $item "gif_preview"
  $previewFile = Get-ItemValue $item "preview_file"
  $pipelineMeta = Get-ItemValue $item "pipeline_meta"
  $expectedFramesRaw = Get-ItemValue $item "expected_frames"
  $godotImport = Get-ItemValue $item "godot_import"
  $collisionRole = (Get-ItemValue $item "collision_role").ToString().ToLowerInvariant()
  $propsMetadata = Get-ItemValue $item "props_metadata"
  $collisionMetadata = Get-ItemValue $item "collision_metadata"
  $zonesMetadata = Get-ItemValue $item "zones_metadata"
  $harnessSpec = Get-ItemValue $item "harness_spec"
  $harnessReport = Get-ItemValue $item "harness_report"
  $generationProvider = (Get-ItemValue $item "generation_provider").ToString().ToLowerInvariant()
  $styleVersion = (Get-ItemValue $item "style_version").ToString()
  $styleDigest = (Get-ItemValue $item "style_lock_sha256").ToString()

  if ([string]::IsNullOrWhiteSpace($assetId)) {
    Add-Item $blockers "manifest.asset_id.missing" "Manifest entry is missing asset_id." $manifestPath
  }

  $isAccepted = Test-AcceptedStatus $status $selected

  if ($isAccepted -and [string]::IsNullOrWhiteSpace($selected)) {
    Add-Item $blockers "asset.selected_file.missing" "Accepted asset $assetId has no selected_file." $manifestPath
  }

  if (![string]::IsNullOrWhiteSpace($selected)) {
    $selectedPath = Resolve-ProjectPath $rootPath $selected
    $relative = Get-RelativePathSafe $rootPath $selectedPath
    [void]$selectedRelative.Add($relative)

    if (!(Test-Path -LiteralPath $selectedPath)) {
      Add-Item $blockers "asset.selected_file.not_found" "selected_file for $assetId does not exist: $selected" $selectedPath
    } elseif ($relative -notmatch '^assets/generated/') {
      Add-Item $blockers "asset.selected_file.outside_generated" "selected_file for $assetId must live under assets/generated/: $selected" $selectedPath
    } else {
      Add-Item $evidence "asset.selected_file.exists" "Selected generated asset exists for $assetId." $selectedPath
    }
  }

  if ($isAccepted) {
    if ($styleVersion -ne $expectedStyleVersion -or $styleDigest -ne $expectedStyleDigest) {
      Add-Item $blockers "asset.style_binding" "Accepted asset $assetId is not bound to the current style version/digest." $manifestPath
    }
    $promptPath = ""
    if (![string]::IsNullOrWhiteSpace($sourcePrompt)) {
      $promptPath = Resolve-ProjectPath $rootPath $sourcePrompt
    } else {
      $promptPath = Find-PromptForAsset $rootPath $assetId
    }

    if ([string]::IsNullOrWhiteSpace($promptPath) -or !(Test-Path -LiteralPath $promptPath)) {
      Add-Item $blockers "asset.source_prompt.missing" "Accepted asset $assetId has no prompt/provenance file." $manifestPath
    } else {
      [void]$promptRelative.Add((Get-RelativePathSafe $rootPath $promptPath))
      Add-Item $evidence "asset.source_prompt.exists" "Prompt/provenance exists for $assetId." $promptPath
      $promptText = Get-Content -Raw -LiteralPath $promptPath
      if ([string]::IsNullOrWhiteSpace($expectedStyleDigest) -or $promptText -notmatch [regex]::Escape($expectedStyleDigest)) {
        Add-Item $blockers "asset.source_prompt.style_binding" "Prompt/provenance for $assetId does not name the current style digest." $promptPath
      }
    }
  }

  if ($isAccepted) {
    if ([string]::IsNullOrWhiteSpace($generationProvider)) {
      Add-Item $warnings "asset.generation_provider.missing" "Accepted asset $assetId has no generation_provider. Record gpt_image, web_sourced, user_supplied, or local_deterministic_placeholder."
    } elseif ($generationProvider -eq "local_deterministic_placeholder") {
      Add-Item $warnings "asset.placeholder.not_release_ready" "Accepted asset $assetId is marked local_deterministic_placeholder. It is valid for smoke tests but not a release-ready GPT Image showcase asset."
    } else {
      Add-Item $evidence "asset.generation_provider.exists" "generation_provider for $assetId is $generationProvider."
    }

    $rawPath = Test-PathField $blockers $evidence $rootPath $assetId "raw_file" $rawFile "asset.raw_file.missing" "Accepted asset $assetId has no raw_file."
    $processedPath = Test-PathField $blockers $evidence $rootPath $assetId "processed_file" $processedFile "asset.processed_file.missing" "Accepted asset $assetId has no processed_file." -RequireGenerated
    $metaPath = Test-PathField $blockers $evidence $rootPath $assetId "pipeline_meta" $pipelineMeta "asset.pipeline_meta.missing" "Accepted asset $assetId has no pipeline_meta."
    Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $processedPath -UseParent
    Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $metaPath -UseParent
    $meta = Read-JsonFile $metaPath
    if ($metaPath -and (Test-Path -LiteralPath $metaPath) -and $null -eq $meta) {
      Add-Item $blockers "asset.pipeline_meta.invalid_json" "pipeline_meta for $assetId is not valid JSON." $metaPath
    } elseif ($null -ne $meta -and ((Get-JsonValue $meta @("style_version") "").ToString() -ne $expectedStyleVersion -or (Get-JsonValue $meta @("style_lock_sha256") "").ToString() -ne $expectedStyleDigest)) {
      Add-Item $blockers "asset.pipeline_meta.style_binding" "pipeline_meta for $assetId is not bound to the current style version/digest." $metaPath
    }

    $isSpriteLike = $assetKind -match '^(sprite|player|enemy|npc|character|creature|projectile|impact|fx|ui_icon)$'
    $isPropPack = $assetKind -match '^(prop_pack|props|props_pack)$'
    $isMapLike = $assetKind -match '(map|level|stage|tilemap|parallax)'
    $needsHarness = $isSpriteLike -or $isPropPack -or $isMapLike -or ($collisionRole -ne "none" -and $collisionRole -ne "")
    $requiresBlockingHarness = $isSpriteLike

    if ($needsHarness) {
      if ([string]::IsNullOrWhiteSpace($harnessSpec)) {
        if ($requiresBlockingHarness) {
          Add-Item $blockers "asset.harness_spec.missing" "Accepted sprite asset $assetId has no harness_spec. Playable sprite sheets must record exact canvas/grid/safe-zone constraints."
        } else {
          Add-Item $warnings "asset.harness_spec.missing" "Accepted runtime asset $assetId has no harness_spec. Future generated gameplay assets should record exact canvas/grid/safe-zone constraints."
        }
      } else {
        $harnessSpecPath = Test-PathField $blockers $evidence $rootPath $assetId "harness_spec" $harnessSpec "asset.harness_spec.missing" "Accepted runtime asset $assetId has no harness_spec."
        $harnessSpecJson = Read-JsonFile $harnessSpecPath
        if ($harnessSpecPath -and (Test-Path -LiteralPath $harnessSpecPath) -and $null -eq $harnessSpecJson) {
          Add-Item $blockers "asset.harness_spec.invalid_json" "harness_spec for $assetId is not valid JSON." $harnessSpecPath
        }
      }

      if ([string]::IsNullOrWhiteSpace($harnessReport)) {
        if ($requiresBlockingHarness) {
          Add-Item $blockers "asset.harness_report.missing" "Accepted sprite asset $assetId has no harness_report. Run tools/check-asset-harness.ps1 before gameplay import."
        } else {
          Add-Item $warnings "asset.harness_report.missing" "Accepted runtime asset $assetId has no harness_report. Run tools/check-asset-harness.ps1 before gameplay import."
        }
      } else {
        $harnessReportPath = Test-PathField $blockers $evidence $rootPath $assetId "harness_report" $harnessReport "asset.harness_report.missing" "Accepted runtime asset $assetId has no harness_report."
        $harnessJson = Read-JsonFile $harnessReportPath
        if ($harnessReportPath -and (Test-Path -LiteralPath $harnessReportPath) -and $null -eq $harnessJson) {
          Add-Item $blockers "asset.harness_report.invalid_json" "harness_report for $assetId is not valid JSON." $harnessReportPath
        } elseif ($harnessJson) {
          $harnessGate = Get-JsonValue $harnessJson @("gate") ""
          if ($harnessGate -eq "BLOCKED") {
            Add-Item $blockers "asset.harness_report.blocked" "harness_report for $assetId is BLOCKED." $harnessReportPath
          } elseif ($harnessGate -eq "PASS_WITH_WARNINGS") {
            Add-Item $warnings "asset.harness_report.warning" "harness_report for $assetId passed with warnings." $harnessReportPath
          } elseif ($harnessGate -eq "PASS") {
            Add-Item $evidence "asset.harness_report.pass" "harness_report passes for $assetId." $harnessReportPath
          }
        }
      }
    }

    if ($isSpriteLike) {
      $framesPath = Test-PathField $blockers $evidence $rootPath $assetId "frames_dir" $framesDir "asset.frames_dir.missing" "Accepted sprite asset $assetId has no frames_dir."
      Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $framesPath
      $gifPath = Test-PathField $blockers $evidence $rootPath $assetId "gif_preview" $gifPreview "asset.gif_preview.missing" "Accepted sprite asset $assetId has no gif_preview."
      Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $gifPath -UseParent

      if ($framesPath -and (Test-Path -LiteralPath $framesPath)) {
        $frameFiles = @(Get-ChildItem -LiteralPath $framesPath -File -Filter "*.png" -ErrorAction SilentlyContinue)
        $expectedFrames = 0
        if ([int]::TryParse("$expectedFramesRaw", [ref]$expectedFrames) -and $expectedFrames -gt 0) {
          if ($frameFiles.Count -ne $expectedFrames) {
            Add-Item $blockers "asset.frame_count.mismatch" "Sprite asset $assetId expected $expectedFrames frames but found $($frameFiles.Count)." $framesPath
          } else {
            Add-Item $evidence "asset.frame_count.ok" "Sprite asset $assetId frame count matches expected_frames." $framesPath
          }
        } elseif ($meta) {
          $metaExpected = Get-JsonValue $meta @("grid", "expected_frames") 0
          $metaActual = Get-JsonValue $meta @("grid", "actual_frames") 0
          if ($metaExpected -gt 0 -and $metaActual -ne $metaExpected) {
            Add-Item $blockers "asset.frame_count.meta_mismatch" "Sprite asset $assetId metadata expected $metaExpected frames but got $metaActual." $metaPath
          }
        }
      }

      if ($meta) {
        $hasAlpha = Get-JsonValue $meta @("qa", "has_alpha") $null
        if ($hasAlpha -eq $false) {
          Add-Item $blockers "asset.alpha.missing" "Sprite asset $assetId processed output does not appear to have alpha transparency." $metaPath
        }

        $keyColor = Get-JsonValue $meta @("chroma_key", "key_color") "#FF00FF"
        $keyPixels = Get-JsonValue $meta @("qa", "opaque_key_pixels") $null
        if ($null -eq $keyPixels) { $keyPixels = Get-JsonValue $meta @("qa", "opaque_magenta_pixels") 0 }
        $residuePixels = [int]$keyPixels
        if ($residuePixels -gt 100) {
          Add-Item $blockers "asset.key_residue.blocking" "Sprite asset $assetId has $residuePixels opaque key-color pixels after processing ($keyColor)." $metaPath
        } elseif ($residuePixels -gt 0) {
          Add-Item $warnings "asset.key_residue.warning" "Sprite asset $assetId has $residuePixels opaque key-color pixels after processing ($keyColor)." $metaPath
        }

        $edgeTouch = @(Get-JsonValue $meta @("qa", "edge_touch_frames") @())
        if ($edgeTouch.Count -gt 0) {
          Add-Item $blockers "asset.edge_touch" "Sprite asset $assetId has frame(s) touching cell edges: $($edgeTouch -join ', '). Regenerate or rectify before runtime import." $metaPath
        }

        $frameCountOk = Get-JsonValue $meta @("qa", "frame_count_ok") $true
        $propCountOk = Get-JsonValue $meta @("qa", "prop_count_ok") $true
        if ($frameCountOk -eq $false -or $propCountOk -eq $false) {
          Add-Item $blockers "asset.count.meta_failed" "Asset $assetId metadata reports frame/prop count mismatch." $metaPath
        }
      }
    }

    if ($isPropPack) {
      $propsMetaPath = Test-PathField $blockers $evidence $rootPath $assetId "props_metadata" $propsMetadata "asset.props_metadata.missing" "Accepted prop pack $assetId has no props_metadata."
      Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $propsMetaPath -UseParent

      if ($meta) {
        $hasAlpha = Get-JsonValue $meta @("qa", "has_alpha") $null
        if ($hasAlpha -eq $false) {
          Add-Item $blockers "asset.alpha.missing" "Prop pack $assetId processed output does not appear to have alpha transparency." $metaPath
        }

        $keyColor = Get-JsonValue $meta @("chroma_key", "key_color") "#FF00FF"
        $keyPixels = Get-JsonValue $meta @("qa", "opaque_key_pixels") $null
        if ($null -eq $keyPixels) { $keyPixels = Get-JsonValue $meta @("qa", "opaque_magenta_pixels") 0 }
        $residuePixels = [int]$keyPixels
        if ($residuePixels -gt 100) {
          Add-Item $blockers "asset.key_residue.blocking" "Prop pack $assetId has $residuePixels opaque key-color pixels after processing ($keyColor)." $metaPath
        } elseif ($residuePixels -gt 0) {
          Add-Item $warnings "asset.key_residue.warning" "Prop pack $assetId has $residuePixels opaque key-color pixels after processing ($keyColor)." $metaPath
        }

        $edgeTouch = @(Get-JsonValue $meta @("qa", "edge_touch_frames") @())
        if ($edgeTouch.Count -gt 0) {
          Add-Item $warnings "asset.edge_touch" "Prop pack $assetId has item(s) touching cell edges: $($edgeTouch -join ', ')." $metaPath
        }

        $propCountOk = Get-JsonValue $meta @("qa", "prop_count_ok") $true
        if ($propCountOk -eq $false) {
          Add-Item $blockers "asset.count.meta_failed" "Prop pack $assetId metadata reports prop count mismatch." $metaPath
        }
      }
    }

    if ($isMapLike) {
      $mapPreviewPath = Test-PathField $blockers $evidence $rootPath $assetId "preview_file" $previewFile "asset.preview_file.missing" "Accepted map asset $assetId has no preview_file." -RequireGenerated
      Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $mapPreviewPath -UseParent
      $propsMetaPath = Test-PathField $blockers $evidence $rootPath $assetId "props_metadata" $propsMetadata "asset.props_metadata.missing" "Accepted map asset $assetId has no props_metadata."
      Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $propsMetaPath -UseParent

      if ($collisionRole -ne "none" -and $collisionRole -ne "") {
        $collisionMetaPath = Test-PathField $blockers $evidence $rootPath $assetId "collision_metadata" $collisionMetadata "asset.collision_metadata.missing" "Accepted map asset $assetId needs collision_metadata for collision_role '$collisionRole'."
        Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $collisionMetaPath -UseParent
      } elseif ([string]::IsNullOrWhiteSpace($collisionMetadata)) {
        Add-Item $warnings "asset.collision_metadata.missing" "Map asset $assetId has no collision_metadata. This is acceptable only for background-only art."
      }

      if ([string]::IsNullOrWhiteSpace($zonesMetadata)) {
        Add-Item $warnings "asset.zones_metadata.missing" "Map asset $assetId has no zones_metadata. This is acceptable only if the map has no triggers, exits, pickups, checkpoints, or encounters."
      } else {
        $zonesMetaPath = Test-PathField $blockers $evidence $rootPath $assetId "zones_metadata" $zonesMetadata "asset.zones_metadata.missing" "Map asset $assetId zones_metadata is missing."
        Add-GeneratedCoverage $coveredGeneratedDirs $rootPath $zonesMetaPath -UseParent
      }
    }

    if ($hasGodot -and $assetKind -notmatch '^(reference|concept|mood)$') {
      if (![string]::IsNullOrWhiteSpace($godotImport)) {
        Test-PathField $blockers $evidence $rootPath $assetId "godot_import" $godotImport "asset.godot_import.missing" "Godot import file for $assetId is missing." | Out-Null
      } elseif (Test-Path -LiteralPath $godotImportManifest) {
        Add-Item $evidence "godot_import_manifest.exists" "Godot import manifest exists for accepted assets." $godotImportManifest
      } else {
        Add-Item $warnings "asset.godot_import_manifest.missing" "Godot project has accepted asset $assetId but no godot_import field or design/assets/godot-import-manifest.yaml."
      }
    }
  }
}

foreach ($file in $generatedFiles) {
  $relative = Get-RelativePathSafe $rootPath $file.FullName
  if (!$selectedRelative.Contains($relative) -and !(Test-IsCoveredGeneratedFile $relative $coveredGeneratedDirs)) {
    Add-Item $blockers "asset.generated.orphan" "Generated asset is not referenced by asset-manifest.yaml: $relative" $file.FullName
  }
}

foreach ($file in $promptFiles) {
  $relative = Get-RelativePathSafe $rootPath $file.FullName
  if ($promptRelative.Count -gt 0 -and !$promptRelative.Contains($relative)) {
    Add-Item $warnings "asset.prompt.orphan" "Prompt/provenance file is not referenced by an accepted manifest asset: $relative" $file.FullName
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
  manifest = if ($manifestExists) { $manifestPath } else { "" }
  manifest_entries = $manifestItems.Count
  generated_files = $generatedFiles.Count
  prompt_files = $promptFiles.Count
  blockers = $blockers
  warnings = $warnings
  evidence = $evidence
} | ConvertTo-Json -Depth 6
