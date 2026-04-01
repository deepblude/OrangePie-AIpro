param(
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"
Assert-Command -Name "ssh"
Assert-Command -Name "scp"

$cfg = Load-Config -ConfigPath $ConfigPath
$sshTarget = "{0}@{1}" -f $cfg.board.user, $cfg.board.ip
$workdir = [string]$cfg.board.workdir

Write-Host "Create board directories: $workdir"
ssh $sshTarget "mkdir -p '$workdir/board_convert' '$workdir/board_deploy'"
if ($LASTEXITCODE -ne 0) {
  throw "create board directories failed with exit code $LASTEXITCODE"
}

$localConvert = Join-Path (Get-ProjectRoot) "board_convert\convert_to_om.sh"
$localInferPy = Join-Path (Get-ProjectRoot) "board_deploy\infer_image.py"
$localInferSh = Join-Path (Get-ProjectRoot) "board_deploy\run_infer.sh"

Write-Host "Sync board scripts..."
scp "$localConvert" "$sshTarget`:$workdir/board_convert/convert_to_om.sh"
if ($LASTEXITCODE -ne 0) { throw "upload convert_to_om.sh failed with exit code $LASTEXITCODE" }
scp "$localInferPy" "$sshTarget`:$workdir/board_deploy/infer_image.py"
if ($LASTEXITCODE -ne 0) { throw "upload infer_image.py failed with exit code $LASTEXITCODE" }
scp "$localInferSh" "$sshTarget`:$workdir/board_deploy/run_infer.sh"
if ($LASTEXITCODE -ne 0) { throw "upload run_infer.sh failed with exit code $LASTEXITCODE" }

ssh $sshTarget "chmod +x '$workdir/board_convert/convert_to_om.sh' '$workdir/board_deploy/run_infer.sh'"
if ($LASTEXITCODE -ne 0) {
  throw "chmod board scripts failed with exit code $LASTEXITCODE"
}

Write-Host "Board scripts synced."
