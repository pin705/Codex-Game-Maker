param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$repo = Resolve-Path -LiteralPath $Root
$repoPath = $repo.Path
$hooksDir = Join-Path $repoPath ".git/hooks"
$marker = "# Codex Game Maker professional hook"

if (!(Test-Path -LiteralPath $hooksDir)) {
  Write-Host "No hooks directory found: $hooksDir"
  exit 0
}

foreach ($name in @("pre-commit", "pre-push")) {
  $path = Join-Path $hooksDir $name
  if (!(Test-Path -LiteralPath $path)) { continue }

  $existing = Get-Content -Raw -LiteralPath $path
  if ($existing -match [regex]::Escape($marker)) {
    Remove-Item -LiteralPath $path -Force
    Write-Host "Removed professional hook: $name"

    $backup = Get-ChildItem -LiteralPath $hooksDir -File -Filter "$name.codex-game-*.bak" -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
    if ($backup) {
      Move-Item -LiteralPath $backup.FullName -Destination $path -Force
      Write-Host "Restored previous hook backup: $($backup.Name)"
    }
  } else {
    Write-Host "Skipped non-Codex hook: $name"
  }
}

