$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
  $scriptsDir = Split-Path -Parent $PSCommandPath
  return (Split-Path -Parent $scriptsDir)
}

function Load-Config {
  param(
    [string]$ConfigPath = ""
  )

  if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path (Get-ProjectRoot) "project_config.json"
  }

  if (!(Test-Path -LiteralPath $ConfigPath)) {
    throw "Config not found: $ConfigPath"
  }

  $raw = Get-Content -LiteralPath $ConfigPath -Raw
  return $raw | ConvertFrom-Json
}

function Assert-Command {
  param([Parameter(Mandatory = $true)][string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $Name"
  }
}
