param(
  [string]$Root = "build/web",
  [int]$Port = 8060,
  [switch]$Open
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$platformHelper = Join-Path $repoRoot.Path "codex-game-studio/scripts/lib/cgs_platform.ps1"
if (Test-Path -LiteralPath $platformHelper) {
  . $platformHelper
}

function Test-PortAvailable([int]$CandidatePort) {
  $listener = $null
  try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $CandidatePort)
    $listener.Start()
    return $true
  } catch {
    return $false
  } finally {
    if ($listener) { $listener.Stop() }
  }
}

function Open-LocalUrl([string]$Url) {
  $platform = if (Get-Command Get-CgsPlatform -ErrorAction SilentlyContinue) { Get-CgsPlatform } else { "windows" }
  try {
    if ($platform -eq "macos") {
      & open $Url | Out-Null
    } elseif ($platform -eq "linux") {
      $xdg = Get-Command "xdg-open" -ErrorAction SilentlyContinue
      if ($xdg) {
        $xdgPath = $xdg.Source
        & $xdgPath $Url | Out-Null
      } else {
        Write-Host "No xdg-open command found. Open this URL manually: $Url"
      }
    } else {
      Start-Process $Url
    }
  } catch {
    Write-Host "Could not open the browser automatically. Open this URL manually: $Url"
  }
}

function Find-Port([int]$StartPort) {
  for ($candidate = $StartPort; $candidate -lt ($StartPort + 100); $candidate++) {
    if (Test-PortAvailable $candidate) { return $candidate }
  }
  throw "No available local port found from $StartPort to $($StartPort + 99)."
}

function Get-ContentType([string]$Path) {
  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".html" { return "text/html; charset=utf-8" }
    ".js" { return "text/javascript; charset=utf-8" }
    ".wasm" { return "application/wasm" }
    ".pck" { return "application/octet-stream" }
    ".png" { return "image/png" }
    ".jpg" { return "image/jpeg" }
    ".jpeg" { return "image/jpeg" }
    ".css" { return "text/css; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    default { return "application/octet-stream" }
  }
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$indexPath = Join-Path $rootPath "index.html"
if (!(Test-Path -LiteralPath $indexPath)) {
  throw "Cannot find index.html in $rootPath. Export the Godot Web build first."
}

$portToUse = Find-Port $Port
$prefix = "http://127.0.0.1:$portToUse/"
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $portToUse)
$listener.Start()

Write-Host "Serving Godot Web build:"
Write-Host "  Root: $rootPath"
Write-Host "  URL:  $prefix"
Write-Host "Press Ctrl+C to stop."

if ($Open) {
  Open-LocalUrl $prefix
}

function Write-HttpResponse {
  param(
    [System.IO.Stream]$Stream,
    [int]$StatusCode,
    [string]$StatusText,
    [string]$ContentType,
    [byte[]]$Body,
    [bool]$SendBody = $true
  )

  $headers = @(
    "HTTP/1.1 $StatusCode $StatusText",
    "Content-Type: $ContentType",
    "Content-Length: $($Body.Length)",
    "Cross-Origin-Opener-Policy: same-origin",
    "Cross-Origin-Embedder-Policy: require-corp",
    "Connection: close",
    "",
    ""
  ) -join "`r`n"

  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
  $Stream.Write($headerBytes, 0, $headerBytes.Length)
  if ($SendBody -and $Body.Length -gt 0) {
    $Stream.Write($Body, 0, $Body.Length)
  }
}

try {
  $rootFull = [System.IO.Path]::GetFullPath($rootPath)
  $rootPrefix = $rootFull.TrimEnd([char[]]@('\', '/')) + [System.IO.Path]::DirectorySeparatorChar

  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 4096, $true)
      $requestLine = $reader.ReadLine()
      if ([string]::IsNullOrWhiteSpace($requestLine)) {
        continue
      }

      while ($true) {
        $line = $reader.ReadLine()
        if ($null -eq $line -or $line -eq "") { break }
      }

      $match = [regex]::Match($requestLine, '^(GET|HEAD)\s+([^\s]+)\s+HTTP/')
      if (!$match.Success) {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Method not allowed")
        Write-HttpResponse -Stream $stream -StatusCode 405 -StatusText "Method Not Allowed" -ContentType "text/plain; charset=utf-8" -Body $body
        continue
      }

      $method = $match.Groups[1].Value
      $requestPath = $match.Groups[2].Value.Split("?")[0]
      $requestPath = [Uri]::UnescapeDataString($requestPath.TrimStart("/"))
      if ([string]::IsNullOrWhiteSpace($requestPath)) {
        $requestPath = "index.html"
      }

      $requestPath = $requestPath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
      $targetPath = [System.IO.Path]::GetFullPath((Join-Path $rootFull $requestPath))
      $isInsideRoot = $targetPath.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
        $targetPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)

      if (!$isInsideRoot -or !(Test-Path -LiteralPath $targetPath -PathType Leaf)) {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Not found")
        Write-HttpResponse -Stream $stream -StatusCode 404 -StatusText "Not Found" -ContentType "text/plain; charset=utf-8" -Body $body -SendBody ($method -eq "GET")
        continue
      }

      $bytes = [System.IO.File]::ReadAllBytes($targetPath)
      Write-HttpResponse -Stream $stream -StatusCode 200 -StatusText "OK" -ContentType (Get-ContentType $targetPath) -Body $bytes -SendBody ($method -eq "GET")
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
