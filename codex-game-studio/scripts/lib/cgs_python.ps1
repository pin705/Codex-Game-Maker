function Get-CgsPythonCommand {
  $candidates = @()

  if (![string]::IsNullOrWhiteSpace($env:PYTHON)) {
    $candidates += @{ Command = $env:PYTHON; Args = @() }
  }

  foreach ($name in @("python", "python3")) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { $candidates += @{ Command = $cmd.Source; Args = @() } }
  }

  $py = Get-Command "py" -ErrorAction SilentlyContinue
  if ($py) {
    $candidates += @{ Command = $py.Source; Args = @("-3") }
  }

  foreach ($candidate in $candidates) {
    try {
      $command = $candidate["Command"]
      $args = @($candidate["Args"])
      $output = & $command @($args + @("-c", "import sys; print(sys.version_info[0])")) 2>$null
      if ($LASTEXITCODE -eq 0 -and "$output".Trim() -eq "3") {
        return [pscustomobject]@{
          command = $command
          args = $args
        }
      }
    } catch {
      continue
    }
  }

  return $null
}

function Invoke-CgsPython {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  $python = Get-CgsPythonCommand
  if (!$python) {
    throw "Python 3 was not found. Install Python 3 and retry."
  }

  & $python.command @($python.args + $Arguments)
}
