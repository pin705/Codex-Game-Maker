param(
  [string]$Root = ".",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repo = Resolve-Path -LiteralPath $Root
$repoPath = $repo.Path
$gitDir = Join-Path $repoPath ".git"
$hooksDir = Join-Path $gitDir "hooks"

if (!(Test-Path -LiteralPath $gitDir)) {
  throw "No .git directory found at $repoPath. Initialize git before installing professional hooks."
}

New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null

$marker = "# Codex Game Maker professional hook"

function Install-Hook([string]$Name, [string]$Body) {
  $path = Join-Path $hooksDir $Name
  if (Test-Path -LiteralPath $path) {
    $existing = Get-Content -Raw -LiteralPath $path
    if ($existing -notmatch [regex]::Escape($marker)) {
      if (!$Force) {
        $stamp = Get-Date -Format "yyyyMMddHHmmss"
        $backup = "$path.codex-game-studio.$stamp.bak"
        Copy-Item -LiteralPath $path -Destination $backup -Force
        Write-Host "Backed up existing hook: $backup"
      }
    }
  }

  [System.IO.File]::WriteAllText($path, $Body, [System.Text.Encoding]::ASCII)
  try { & chmod +x $path | Out-Null } catch {}
  Write-Host "Installed professional hook: $Name"
}

$preCommit = @'
#!/bin/sh
# Codex Game Maker professional hook
ROOT="$(git rev-parse --show-toplevel)"
if command -v pwsh >/dev/null 2>&1; then
  PS=pwsh
elif command -v powershell.exe >/dev/null 2>&1; then
  PS=powershell.exe
elif command -v powershell >/dev/null 2>&1; then
  PS=powershell
else
  echo "Codex Game Maker hooks require PowerShell. Install PowerShell 7 (pwsh) or uninstall hooks."
  exit 1
fi
PS_ARGS="-NoProfile"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) PS_ARGS="$PS_ARGS -ExecutionPolicy Bypass" ;; esac

"$PS" $PS_ARGS -File "$ROOT/tools/check-asset-gate.ps1" -Root "$ROOT" || exit 1
"$PS" $PS_ARGS -File "$ROOT/tools/check-story-gate.ps1" -Root "$ROOT" -Mode Ready || exit 1
"$PS" $PS_ARGS -File "$ROOT/tools/check-godot-lint.ps1" -Root "$ROOT" || exit 1
'@

$prePush = @'
#!/bin/sh
# Codex Game Maker professional hook
ROOT="$(git rev-parse --show-toplevel)"
if command -v pwsh >/dev/null 2>&1; then
  PS=pwsh
elif command -v powershell.exe >/dev/null 2>&1; then
  PS=powershell.exe
elif command -v powershell >/dev/null 2>&1; then
  PS=powershell
else
  echo "Codex Game Maker hooks require PowerShell. Install PowerShell 7 (pwsh) or uninstall hooks."
  exit 1
fi
PS_ARGS="-NoProfile"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) PS_ARGS="$PS_ARGS -ExecutionPolicy Bypass" ;; esac

"$PS" $PS_ARGS -File "$ROOT/tools/check-review-gate.ps1" -Root "$ROOT" || exit 1
if [ -f "$ROOT/project.godot" ] && [ -f "$ROOT/export_presets.cfg" ]; then
  "$PS" $PS_ARGS -File "$ROOT/tools/export-godot-web.ps1" -Project "$ROOT" || exit 1
fi
'@

Install-Hook "pre-commit" $preCommit
Install-Hook "pre-push" $prePush

Write-Host ""
Write-Host "Professional hooks installed. To remove them:"
Write-Host "  pwsh -File tools/uninstall-professional-hooks.ps1"


