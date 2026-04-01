param(
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"
Assert-Command -Name "ssh"

$cfg = Load-Config -ConfigPath $ConfigPath
$sshTarget = "{0}@{1}" -f $cfg.board.user, $cfg.board.ip
$remoteScript = "{0}/board_deploy/run_infer.sh" -f $cfg.board.workdir

$remoteCmd = @(
  "bash '$remoteScript'",
  "--model '$($cfg.board.om_path)'",
  "--image '$($cfg.inference.image_path)'",
  "--output '$($cfg.inference.result_path)'",
  "--device '$($cfg.board.device_id)'",
  "--imgsz '$($cfg.inference.imgsz)'",
  "--conf '$($cfg.inference.conf)'",
  "--iou '$($cfg.inference.iou)'",
  "--classes '$($cfg.inference.classes)'"
) -join " "

Write-Host "Remote infer: $remoteCmd"
$wrappedCmd = "bash -lc `"$remoteCmd`""
ssh -tt -o ServerAliveInterval=30 -o ServerAliveCountMax=10 $sshTarget $wrappedCmd
if ($LASTEXITCODE -ne 0) {
  throw "remote infer failed with exit code $LASTEXITCODE"
}
