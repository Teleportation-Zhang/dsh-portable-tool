param([string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)), [switch]$Quiet)
# 启动前自愈：确保 profile 的 bundles 包含核心包，且没有明显损坏
# 由 portable-launch.ps1 / DSH-Portable-Console.ps1 在启动 DSH 前调用
$ErrorActionPreference = 'Stop'
try {
  $web = Join-Path $Root 'data\dsh-desktop\harness\profiles\web'
  $pkg = Join-Path $web 'package.json'
  if (-not (Test-Path -LiteralPath $pkg)) { exit 0 }
  $pj = Get-Content -LiteralPath $pkg -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($null -eq $pj.dsh) { $pj | Add-Member -NotePropertyName dsh -NotePropertyValue ([pscustomobject]@{}) -Force }
  if ($null -eq $pj.dsh.profile) { $pj.dsh | Add-Member -NotePropertyName profile -NotePropertyValue ([pscustomobject]@{}) -Force }
  $changed = $false
  $bundles = @()
  if ($null -ne $pj.dsh.profile.bundles) { $bundles = @($pj.dsh.profile.bundles) }
  foreach ($core in @('@deepseek-ai/dsh-base', '@deepseek-ai/dsh-web-app')) {
    if ($bundles -notcontains $core) { $bundles += $core; $changed = $true }
  }
  $bundles = @($bundles | Select-Object -Unique)
  if ($changed) {
    $pj.dsh.profile.bundles = $bundles
    [System.IO.File]::WriteAllText($pkg, ($pj | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding($false)))
  }
  if (-not $Quiet) { Write-Host ('插件启用列表：' + ($bundles -join ', ')) }
} catch {
  if (-not $Quiet) { Write-Host ('自愈检查失败：' + $_) }
}
exit 0
