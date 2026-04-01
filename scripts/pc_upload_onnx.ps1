param(
  [string]$ConfigPath = "",
  [string]$OnnxPath = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"
Assert-Command -Name "scp"

$cfg = Load-Config -ConfigPath $ConfigPath

if ([string]::IsNullOrWhiteSpace($OnnxPath)) {
  $OnnxPath = [string]$cfg.local.onnx_path
}

if (!(Test-Path -LiteralPath $OnnxPath)) {
  $projectRoot = Get-ProjectRoot
  $candidates = Get-ChildItem -LiteralPath $projectRoot -Recurse -Filter best.onnx -File |
    Where-Object { $_.FullName -notmatch "\\.venv\\" } |
    Sort-Object LastWriteTime -Descending
  if ($candidates.Count -gt 0) {
    $OnnxPath = $candidates[0].FullName
    Write-Host "Configured ONNX not found, fallback to: $OnnxPath"
  }
}

if (!(Test-Path -LiteralPath $OnnxPath)) {
  throw "ONNX file not found: $OnnxPath"
}

$target = "{0}@{1}:{2}" -f $cfg.board.user, $cfg.board.ip, $cfg.board.onnx_path
Write-Host "Uploading ONNX -> $target"
scp "$OnnxPath" "$target"
if ($LASTEXITCODE -ne 0) {
  throw "scp upload failed with exit code $LASTEXITCODE"
}
