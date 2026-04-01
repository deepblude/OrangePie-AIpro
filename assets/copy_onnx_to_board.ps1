param(
  [Parameter(Mandatory=$true)][string]$OnnxPath,
  [Parameter(Mandatory=$true)][string]$BoardUser,
  [Parameter(Mandatory=$true)][string]$BoardIp,
  [string]$BoardTargetPath = "~/best.onnx"
)

if (!(Test-Path -LiteralPath $OnnxPath)) {
  throw "ONNX file not found: $OnnxPath"
}

$target = "${BoardUser}@${BoardIp}:$BoardTargetPath"
Write-Host "Running: scp `"$OnnxPath`" `"$target`""
scp "$OnnxPath" "$target"
