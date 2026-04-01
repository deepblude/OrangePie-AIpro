param(
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"
Assert-Command -Name "ssh"

$cfg = Load-Config -ConfigPath $ConfigPath
$sshTarget = "{0}@{1}" -f $cfg.board.user, $cfg.board.ip
$remoteScript = "{0}/board_convert/convert_to_om.sh" -f $cfg.board.workdir

$omPath = [string]$cfg.board.om_path
if ($omPath.EndsWith(".om")) {
  $outputPrefix = $omPath.Substring(0, $omPath.Length - 3)
}
else {
  $outputPrefix = $omPath
}

$remoteCmd = "bash '$remoteScript' '$($cfg.board.onnx_path)' '$($cfg.board.soc_version)' '$($cfg.pipeline.input_name)' '$($cfg.pipeline.input_shape)' '$outputPrefix'"
Write-Host "Remote convert: $remoteCmd"
$wrappedCmd = "bash -lc `"$remoteCmd`""
ssh -tt -o ServerAliveInterval=30 -o ServerAliveCountMax=10 $sshTarget $wrappedCmd
if ($LASTEXITCODE -ne 0) {
  throw "remote convert failed with exit code $LASTEXITCODE"
}
