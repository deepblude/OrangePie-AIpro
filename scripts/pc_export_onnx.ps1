param(
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"

$cfg = Load-Config -ConfigPath $ConfigPath
Assert-Command -Name ([string]$cfg.pc.python_exe)
$projectRoot = Get-ProjectRoot
$pcDir = Join-Path $projectRoot "pc_train"

if (!(Test-Path -LiteralPath $pcDir)) {
  throw "pc_train directory not found: $pcDir"
}

Push-Location $pcDir
try {
  $args = @(
    "train_and_export.py",
    "--data", [string]$cfg.pc.train.data,
    "--model", [string]$cfg.pc.train.model,
    "--imgsz", [string]$cfg.pc.train.imgsz,
    "--epochs", [string]$cfg.pc.train.epochs,
    "--project", [string]$cfg.pc.train.project,
    "--name", [string]$cfg.pc.train.name,
    "--opset", [string]$cfg.pc.train.opset
  )

  $bestPt = [string]$cfg.pc.train.best_pt
  if (![string]::IsNullOrWhiteSpace($bestPt)) {
    $args += @("--best-pt", $bestPt)
  }

  Write-Host "Running: $($cfg.pc.python_exe) $($args -join ' ')"
  & $cfg.pc.python_exe @args
  if ($LASTEXITCODE -ne 0) {
    throw "train_and_export.py failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
