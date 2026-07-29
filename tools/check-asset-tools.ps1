param()

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$pythonHelper = Join-Path $repoRoot.Path "scripts/lib/cgs_python.ps1"
$processor = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_processor.py"
$workflow = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_workflows.py"
$harness = Join-Path $repoRoot.Path "scripts/assets/cgs_asset_harness.py"
$requirements = Join-Path $repoRoot.Path "requirements-asset-tools.txt"

if (!(Test-Path -LiteralPath $pythonHelper)) {
  throw "Cannot find Python helper: $pythonHelper"
}

. $pythonHelper

$blockers = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$evidence = [System.Collections.ArrayList]::new()

function Add-Item([System.Collections.ArrayList]$List, [string]$Code, [string]$Message, [string]$Path = "") {
  [void]$List.Add([pscustomobject]@{
    code = $Code
    message = $Message
    path = $Path
  })
}

$python = Get-CgsPythonCommand
if (!$python) {
  Add-Item $blockers "python.missing" "Python 3 was not found. Install Python 3 before using asset processors."
} else {
  Add-Item $evidence "python.found" "Python 3 found: $($python.command)"
  $depOutput = & $python.command @($python.args + @("-c", "import PIL, numpy; print('ok')")) 2>&1
  if ($LASTEXITCODE -ne 0) {
    Add-Item $blockers "python.asset_deps.missing" "Missing Python asset dependencies. Run: python -m pip install -r requirements-asset-tools.txt" $requirements
  } else {
    Add-Item $evidence "python.asset_deps" "Pillow and numpy are importable."
  }

  $compileOutput = & $python.command @($python.args + @("-m", "py_compile", $processor, $workflow, $harness)) 2>&1
  if ($LASTEXITCODE -ne 0) {
    Add-Item $blockers "python.asset_scripts.invalid" "Asset processor/workflow/harness Python scripts failed py_compile." "$processor; $workflow; $harness"
  } else {
    Add-Item $evidence "python.asset_scripts" "Asset processor, workflow, and harness scripts compile."
  }
}

if (Test-Path -LiteralPath $processor) {
  Add-Item $evidence "processor.exists" "Asset processor exists." $processor
} else {
  Add-Item $blockers "processor.missing" "Missing asset processor script." $processor
}

if (Test-Path -LiteralPath $workflow) {
  Add-Item $evidence "workflow.exists" "Asset workflow coordinator exists." $workflow
} else {
  Add-Item $blockers "workflow.missing" "Missing asset workflow coordinator script." $workflow
}

if (Test-Path -LiteralPath $harness) {
  Add-Item $evidence "harness.exists" "Asset harness script exists." $harness
} else {
  Add-Item $blockers "harness.missing" "Missing asset harness script." $harness
}

if (Test-Path -LiteralPath $requirements) {
  Add-Item $evidence "requirements.exists" "Asset tool requirements file exists." $requirements
} else {
  Add-Item $warnings "requirements.missing" "requirements-asset-tools.txt is missing." $requirements
}

$gate = if ($blockers.Count -gt 0) {
  "BLOCKED"
} elseif ($warnings.Count -gt 0) {
  "PASS_WITH_WARNINGS"
} else {
  "PASS"
}

[pscustomobject]@{
  gate = $gate
  blockers = $blockers
  warnings = $warnings
  evidence = $evidence
} | ConvertTo-Json -Depth 5

if ($blockers.Count -gt 0) { exit 1 }
