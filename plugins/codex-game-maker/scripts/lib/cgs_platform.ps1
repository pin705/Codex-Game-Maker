function Get-CgsPlatform {
  if ($env:OS -eq "Windows_NT" -or [System.IO.Path]::DirectorySeparatorChar -eq "\") {
    return "windows"
  }

  $isMac = Get-Variable -Name IsMacOS -ValueOnly -ErrorAction SilentlyContinue
  if ($isMac) { return "macos" }

  $isLinux = Get-Variable -Name IsLinux -ValueOnly -ErrorAction SilentlyContinue
  if ($isLinux) { return "linux" }

  $uname = ""
  try {
    $uname = (& uname -s 2>$null | Select-Object -First 1)
  } catch {
    $uname = ""
  }

  switch -Regex ($uname) {
    "Darwin" { return "macos" }
    "Linux" { return "linux" }
    default { return "unknown" }
  }
}

function Get-CgsArchitecture {
  $arch = ""
  try {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
  } catch {
    $arch = $env:PROCESSOR_ARCHITECTURE
  }

  if ([string]::IsNullOrWhiteSpace($arch)) {
    try {
      $arch = (& uname -m 2>$null | Select-Object -First 1)
    } catch {
      $arch = ""
    }
  }

  switch -Regex ($arch.ToLowerInvariant()) {
    "^(x64|amd64|x86_64)$" { return "x86_64" }
    "^(arm64|aarch64)$" { return "arm64" }
    "^(x86|i386|i686)$" { return "x86_32" }
    default { return $arch.ToLowerInvariant() }
  }
}

function Get-CgsPathSeparator {
  if ((Get-CgsPlatform) -eq "windows") { return ";" }
  return ":"
}

function Get-CgsPathComparison {
  $platform = Get-CgsPlatform
  if ($platform -eq "windows" -or $platform -eq "macos") {
    return [System.StringComparison]::OrdinalIgnoreCase
  }

  return [System.StringComparison]::Ordinal
}

function Get-CgsPowerShellCommand {
  $currentProcess = $null
  try {
    $currentProcess = (Get-Process -Id $PID).Path
  } catch {
    $currentProcess = ""
  }

  if (![string]::IsNullOrWhiteSpace($currentProcess) -and (Test-Path -LiteralPath $currentProcess)) {
    return $currentProcess
  }

  foreach ($name in @("pwsh", "powershell", "powershell.exe")) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }

  return $null
}

function New-CgsPowerShellArgs {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [string[]]$ArgumentList = @()
  )

  $args = @("-NoProfile")
  if ((Get-CgsPlatform) -eq "windows") {
    $args += @("-ExecutionPolicy", "Bypass")
  }

  $args += @("-File", $ScriptPath)
  $args += $ArgumentList
  return $args
}

function Invoke-CgsPowerShellScript {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [string[]]$ArgumentList = @()
  )

  $ps = Get-CgsPowerShellCommand
  if (!$ps) {
    throw "PowerShell was not found. Install PowerShell 7 (pwsh) on macOS/Linux, or run from Windows PowerShell/PowerShell 7 on Windows."
  }

  $args = New-CgsPowerShellArgs -ScriptPath $ScriptPath -ArgumentList $ArgumentList
  & $ps @args
}

function Get-CgsDefaultCodexHome {
  if (![string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    return $env:CODEX_HOME
  }

  if (![string]::IsNullOrWhiteSpace($HOME)) {
    return (Join-Path $HOME ".codex")
  }

  if (![string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    return (Join-Path $env:USERPROFILE ".codex")
  }

  throw "Cannot determine Codex home. Set CODEX_HOME and retry."
}

function Get-CgsGodotInstallProfile {
  param(
    [string]$Version = "4.6.2",
    [string]$Status = "stable",
    [string]$InstallBase = "",
    [string]$Platform = "",
    [string]$Architecture = ""
  )

  if ([string]::IsNullOrWhiteSpace($Platform)) {
    $Platform = Get-CgsPlatform
  }
  if ([string]::IsNullOrWhiteSpace($Architecture)) {
    $Architecture = Get-CgsArchitecture
  }
  if ([string]::IsNullOrWhiteSpace($InstallBase)) {
    throw "InstallBase is required."
  }

  $releaseTag = "$Version-$Status"
  $fileName = ""
  $executableRelative = ""
  $platformFolder = $Platform

  switch ($Platform) {
    "windows" {
      $suffix = if ($Architecture -eq "arm64") { "windows_arm64.exe" } else { "win64.exe" }
      $fileName = "Godot_v$releaseTag" + "_$suffix.zip"
      $executableRelative = "Godot_v$releaseTag" + "_$suffix"
    }
    "macos" {
      $fileName = "Godot_v$releaseTag" + "_macos.universal.zip"
      $executableRelative = "Godot.app/Contents/MacOS/Godot"
    }
    "linux" {
      $linuxArch = if ($Architecture -eq "arm64") { "arm64" } elseif ($Architecture -eq "x86_32") { "x86_32" } else { "x86_64" }
      $fileName = "Godot_v$releaseTag" + "_linux.$linuxArch.zip"
      $executableRelative = "Godot_v$releaseTag" + "_linux.$linuxArch"
    }
    default {
      throw "Unsupported OS for automatic Godot install: $Platform"
    }
  }

  $installRoot = Join-Path $InstallBase $platformFolder
  $binDir = Join-Path $InstallBase "bin"
  $wrapperName = if ($Platform -eq "windows") { "godot.cmd" } else { "godot" }

  [pscustomobject]@{
    platform = $Platform
    architecture = $Architecture
    version = $Version
    status = $Status
    release_tag = $releaseTag
    file_name = $fileName
    download_url = "https://github.com/godotengine/godot-builds/releases/download/$releaseTag/$fileName"
    install_base = $InstallBase
    install_root = $installRoot
    executable_relative = $executableRelative
    executable_path = Join-Path $installRoot $executableRelative
    bin_dir = $binDir
    wrapper_name = $wrapperName
    wrapper_path = Join-Path $binDir $wrapperName
  }
}

function Write-CgsGodotWrapper {
  param(
    [Parameter(Mandatory = $true)]
    $Profile
  )

  New-Item -ItemType Directory -Force -Path $Profile.bin_dir | Out-Null

  if ($Profile.platform -eq "windows") {
    $content = "@echo off`r`n`"$($Profile.executable_path)`" %*`r`n"
    [System.IO.File]::WriteAllText($Profile.wrapper_path, $content, [System.Text.Encoding]::ASCII)
  } else {
    $content = "#!/bin/sh`nexec `"$($Profile.executable_path)`" `"$@`"`n"
    [System.IO.File]::WriteAllText($Profile.wrapper_path, $content, [System.Text.Encoding]::ASCII)
    try { & chmod +x $Profile.wrapper_path | Out-Null } catch {}
    try { & chmod +x $Profile.executable_path | Out-Null } catch {}
  }
}

function Test-CgsPathContains {
  param(
    [string]$PathValue,
    [string]$Entry
  )

  if ([string]::IsNullOrWhiteSpace($PathValue) -or [string]::IsNullOrWhiteSpace($Entry)) {
    return $false
  }

  $comparison = Get-CgsPathComparison
  $separator = Get-CgsPathSeparator
  $normalizedEntry = [System.IO.Path]::GetFullPath($Entry).TrimEnd([char[]]@('\', '/'))

  foreach ($part in ($PathValue -split [regex]::Escape($separator))) {
    if ([string]::IsNullOrWhiteSpace($part)) { continue }
    $candidate = ""
    try {
      $candidate = [System.IO.Path]::GetFullPath($part).TrimEnd([char[]]@('\', '/'))
    } catch {
      $candidate = $part.TrimEnd([char[]]@('\', '/'))
    }

    if ($candidate.Equals($normalizedEntry, $comparison)) {
      return $true
    }
  }

  return $false
}

function Add-CgsPathEntry {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Entry
  )

  $platform = Get-CgsPlatform
  $entryFull = [System.IO.Path]::GetFullPath($Entry)

  if ($platform -eq "windows") {
    $current = [Environment]::GetEnvironmentVariable("Path", "User")
    if (Test-CgsPathContains -PathValue $current -Entry $entryFull) {
      return [pscustomobject]@{ changed = $false; target = "User PATH"; message = "User PATH already contains: $entryFull" }
    }

    $newPath = if ([string]::IsNullOrWhiteSpace($current)) { $entryFull } else { "$current;$entryFull" }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    return [pscustomobject]@{ changed = $true; target = "User PATH"; message = "Added to User PATH: $entryFull" }
  }

  $shellName = Split-Path -Leaf $env:SHELL
  $profilePath = ""
  if ($shellName -eq "zsh") {
    $profilePath = Join-Path $HOME ".zshrc"
  } elseif ($shellName -eq "bash") {
    if ($platform -eq "macos") {
      $profilePath = Join-Path $HOME ".bash_profile"
    } else {
      $profilePath = Join-Path $HOME ".bashrc"
    }
  } else {
    $profilePath = Join-Path $HOME ".profile"
  }

  $marker = "# Codex Game Maker Godot PATH"
  $line = "export PATH=`"$entryFull`":`$PATH"
  $existing = if (Test-Path -LiteralPath $profilePath) { Get-Content -Raw -LiteralPath $profilePath } else { "" }

  if ($existing -match [regex]::Escape($entryFull)) {
    return [pscustomobject]@{ changed = $false; target = $profilePath; message = "Shell profile already references: $entryFull" }
  }

  Add-Content -LiteralPath $profilePath -Value "`n$marker`n$line"
  return [pscustomobject]@{ changed = $true; target = $profilePath; message = "Added Godot PATH entry to shell profile: $profilePath" }
}

function Get-CgsGodotExportTemplatesRoot {
  $platform = Get-CgsPlatform
  if ($platform -eq "windows" -and ![string]::IsNullOrWhiteSpace($env:APPDATA)) {
    return Join-Path $env:APPDATA "Godot/export_templates"
  }

  if ($platform -eq "macos") {
    return Join-Path $HOME "Library/Application Support/Godot/export_templates"
  }

  return Join-Path $HOME ".local/share/godot/export_templates"
}

function Get-CgsGodotCandidatePaths {
  param(
    [string]$Root = "",
    [string]$RequiredMajor = "4",
    [string]$RequiredMinor = "7",
    [string]$GodotPath = ""
  )

  $candidates = [System.Collections.ArrayList]::new()

  if (![string]::IsNullOrWhiteSpace($GodotPath)) {
    [void]$candidates.Add($GodotPath)
  }

  if (![string]::IsNullOrWhiteSpace($env:GODOT_BIN)) {
    [void]$candidates.Add($env:GODOT_BIN)
  }

  $platform = Get-CgsPlatform
  $rootsToSearch = [System.Collections.ArrayList]::new()
  if (![string]::IsNullOrWhiteSpace($Root) -and (Test-Path -LiteralPath $Root)) {
    $cursor = (Resolve-Path -LiteralPath $Root).Path
    while (![string]::IsNullOrWhiteSpace($cursor)) {
      [void]$rootsToSearch.Add($cursor)
      $parent = Split-Path -Parent $cursor
      if ($parent -eq $cursor) { break }
      $cursor = $parent
    }
  }

  foreach ($searchRoot in $rootsToSearch) {
    $installBase = Join-Path $searchRoot ".tools/godot"
    foreach ($candidate in @(
      (Join-Path $installBase "bin/godot.cmd"),
      (Join-Path $installBase "bin/godot"),
      (Join-Path $installBase "godot.cmd"),
      (Join-Path $installBase "Godot_v4.6.2-stable_win64.exe"),
      (Join-Path $installBase "windows/Godot_v4.6.2-stable_win64.exe"),
      (Join-Path $installBase "windows/Godot_v4.6.2-stable_windows_arm64.exe"),
      (Join-Path $installBase "macos/Godot.app/Contents/MacOS/Godot"),
      (Join-Path $installBase "linux/Godot_v4.6.2-stable_linux.x86_64"),
      (Join-Path $installBase "linux/Godot_v4.6.2-stable_linux.arm64"),
      (Join-Path $installBase "linux/Godot_v4.6.2-stable_linux.x86_32")
    )) {
      [void]$candidates.Add($candidate)
    }
  }

  foreach ($name in @("godot", "godot4", "godot4.6", "godot4.7", "Godot_v$RequiredMajor.$RequiredMinor")) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { [void]$candidates.Add($cmd.Source) }
  }

  if ($platform -eq "macos") {
    [void]$candidates.Add("/Applications/Godot.app/Contents/MacOS/Godot")
    [void]$candidates.Add((Join-Path $HOME "Applications/Godot.app/Contents/MacOS/Godot"))
  } elseif ($platform -eq "linux") {
    [void]$candidates.Add("/usr/local/bin/godot")
    [void]$candidates.Add("/usr/bin/godot")
    [void]$candidates.Add((Join-Path $HOME ".local/bin/godot"))
  } elseif ($platform -eq "windows") {
    $commonRoots = @()
    if (![string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { $commonRoots += (Join-Path $env:LOCALAPPDATA "Programs") }
    if (![string]::IsNullOrWhiteSpace($env:USERPROFILE)) { $commonRoots += (Join-Path $env:USERPROFILE "Downloads") }
    $commonRoots += @("C:\Program Files", "C:\Program Files (x86)")

    foreach ($commonRoot in $commonRoots) {
      if (!(Test-Path -LiteralPath $commonRoot)) { continue }
      $match = Get-ChildItem -LiteralPath $commonRoot -Recurse -Force -ErrorAction SilentlyContinue -Filter "Godot*_v$RequiredMajor.$RequiredMinor*.exe" |
        Select-Object -First 1
      if ($match) { [void]$candidates.Add($match.FullName) }
    }
  }

  $seen = @{}
  $deduped = @()
  foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    $key = $candidate.ToString()
    if ($seen.ContainsKey($key)) { continue }
    $seen[$key] = $true
    $deduped += $key
  }

  return $deduped
}

function Resolve-CgsGodotExecutable {
  param(
    [string]$Candidate
  )

  if ([string]::IsNullOrWhiteSpace($Candidate)) {
    return $null
  }

  if (!(Test-Path -LiteralPath $Candidate)) {
    return $null
  }

  $item = Get-Item -LiteralPath $Candidate -ErrorAction SilentlyContinue
  if (!$item) {
    return $null
  }

  if (!$item.PSIsContainer) {
    return $item.FullName
  }

  $platform = Get-CgsPlatform
  if ($platform -eq "macos" -and $item.Name -eq "Godot.app") {
    $macExe = Join-Path $item.FullName "Contents/MacOS/Godot"
    if (Test-Path -LiteralPath $macExe) {
      return (Resolve-Path -LiteralPath $macExe).Path
    }
  }

  $files = @(Get-ChildItem -LiteralPath $item.FullName -File -Recurse -ErrorAction SilentlyContinue)
  if ($platform -eq "windows") {
    $preferred = @($files | Where-Object { $_.Name -match '(?i)^Godot.*console.*\.exe$' } | Select-Object -First 1)
    if ($preferred.Count -gt 0) { return $preferred[0].FullName }

    $regular = @($files | Where-Object { $_.Name -match '(?i)^Godot.*\.exe$' } | Select-Object -First 1)
    if ($regular.Count -gt 0) { return $regular[0].FullName }
  } else {
    $preferred = @($files | Where-Object { $_.Name -match '(?i)^Godot' } | Select-Object -First 1)
    if ($preferred.Count -gt 0) { return $preferred[0].FullName }
  }

  return $null
}

function Find-CgsGodotCommand {
  param(
    [string]$Root = "",
    [string]$RequiredMajor = "4",
    [string]$RequiredMinor = "4",
    [string]$GodotPath = ""
  )

  foreach ($candidate in (Get-CgsGodotCandidatePaths -Root $Root -RequiredMajor $RequiredMajor -RequiredMinor $RequiredMinor -GodotPath $GodotPath)) {
    $resolved = Resolve-CgsGodotExecutable -Candidate $candidate
    if ($resolved) {
      return $resolved
    }
  }

  return $null
}
