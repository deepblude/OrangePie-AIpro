param(
  [string]$ConfigPath = "",
  [switch]$SkipExport
)

$ErrorActionPreference = "Stop"

$scriptsDir = Split-Path -Parent $PSCommandPath

if (-not $SkipExport) {
  & "$scriptsDir\pc_export_onnx.ps1" -ConfigPath $ConfigPath
}

& "$scriptsDir\pc_upload_onnx.ps1" -ConfigPath $ConfigPath
& "$scriptsDir\pc_sync_board_scripts.ps1" -ConfigPath $ConfigPath
& "$scriptsDir\pc_remote_convert.ps1" -ConfigPath $ConfigPath
& "$scriptsDir\pc_remote_infer.ps1" -ConfigPath $ConfigPath
& "$scriptsDir\pc_pull_result.ps1" -ConfigPath $ConfigPath

Write-Host "Pipeline done."
