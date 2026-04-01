param(
  [string]$ConfigPath = "",
  [string]$LocalPath = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"
Assert-Command -Name "scp"

$cfg = Load-Config -ConfigPath $ConfigPath

if ([string]::IsNullOrWhiteSpace($LocalPath)) {
  $LocalPath = [string]$cfg.local.pull_result_to
}

$parent = Split-Path -Parent $LocalPath
if (![string]::IsNullOrWhiteSpace($parent) -and !(Test-Path -LiteralPath $parent)) {
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

$remote = "{0}@{1}:{2}" -f $cfg.board.user, $cfg.board.ip, $cfg.inference.result_path
Write-Host "Downloading result <- $remote"
scp "$remote" "$LocalPath"
if ($LASTEXITCODE -ne 0) {
  throw "scp download failed with exit code $LASTEXITCODE"
}

Write-Host "Saved: $LocalPath"
