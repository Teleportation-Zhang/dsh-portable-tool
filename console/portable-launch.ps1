#requires -Version 5.0
# DSH 便携版启动器（由「启动 DSH（便携版）.bat」调用）
# 负责：检查程序、处理数据目录链接（含断链/换盘符）、启动 DSH
# 方案 A：目标机已装 DSH 时，临时把本机数据目录改名让位，退出后自动还原

param(
  [switch]$DryRun,   # 只演练：打印将执行的动作，不实际改名/启动
  [switch]$Restore,  # 只做还原（把上次未还原的本机数据目录改回来）
  [switch]$NoPrompt  # 不询问（供控制台调用）
)

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$Root    = Split-Path -Parent $ScriptDir
$Target  = Join-Path $Root 'data\dsh-desktop'
$Exe     = Join-Path $Root 'program\DSH Desktop\DSH Desktop.exe'
$AppData = Join-Path $env:APPDATA 'dsh-desktop'
$Backup  = Join-Path $env:APPDATA 'dsh-desktop.portable-backup'
$Marker  = Join-Path $env:APPDATA 'dsh-desktop.portable-takeover.json'

function Log([string]$m) { Write-Host $m }

function Show-Msg([string]$text, [string]$title = 'DSH 便携版') {
  Write-Host ''
  Write-Host ('==== ' + $title + ' ====') -ForegroundColor Cyan
  Write-Host $text -ForegroundColor Yellow
  Write-Host ''
  Read-Host '按回车键关闭窗口' | Out-Null
}

function Test-IsLink([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return $false }
  try {
    $i = Get-Item -LiteralPath $p -Force
    return [bool]($i.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
  } catch { return $false }
}

function Get-LinkTarget([string]$p) {
  try { return [string](Get-Item -LiteralPath $p -Force).Target } catch { return '' }
}

function Get-DshProcs {
  return @(Get-Process -Name 'DSH Desktop' -ErrorAction SilentlyContinue)
}

# 还原本机数据目录：上次临时让位没还原时（崩溃/强关）调用
function Restore-HostData([switch]$Force) {
  if (-not (Test-Path -LiteralPath $Backup)) { return $false }

  $procs = Get-DshProcs
  if ($procs.Count -gt 0 -and -not $Force) {
    Show-Msg ("检测到上次临时切换尚未还原，但 DSH 还在运行。`r`n`r`n请先完全退出 DSH，再重新运行本启动器；`r`n或打开控制台点「还原本机数据目录」。")
    return $false
  }

  if (Test-Path -LiteralPath $AppData) {
    if (Test-IsLink $AppData) {
      Remove-Item -LiteralPath $AppData -Force -ErrorAction SilentlyContinue
    } else {
      Show-Msg ("检测到异常，两个目录同时存在：`r`n$AppData`r`n$Backup`r`n`r`n请手动确认保留哪一个（便携数据仍在 U 盘，不受影响）。")
      return $false
    }
  }

  try {
    Move-Item -LiteralPath $Backup -Destination $AppData -Force -ErrorAction Stop
    Log ('已还原本机数据目录：' + $AppData)
    return $true
  } catch {
    Show-Msg ("还原本机数据目录失败：`r`n" + [string]$_)
    return $false
  }
}

# 接管标记：接管时写、还原时删。崩溃后下次启动据此自愈。
function Write-TakeoverMarker() {
  $obj = [ordered]@{ backup = $Backup; target = $Target; usb = $Root; time = (Get-Date).ToString('o') }
  $json = $obj | ConvertTo-Json
  [System.IO.File]::WriteAllText($Marker, $json, (New-Object System.Text.UTF8Encoding($false)))
}
function Clear-TakeoverMarker() {
  if (Test-Path -LiteralPath $Marker) { Remove-Item -LiteralPath $Marker -Force -ErrorAction SilentlyContinue }
}
function Read-TakeoverMarker() {
  if (-not (Test-Path -LiteralPath $Marker)) { return $null }
  try { return (Get-Content -LiteralPath $Marker -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

# ---------- 手动还原模式 ----------
if ($Restore) {
  $ok = Restore-HostData -Force
  if (-not $ok) { Log '没有需要还原的备份（或还原失败）。' }
  exit 0
}

# ---------- 前置检查 ----------
if (-not (Test-Path -LiteralPath $Exe)) {
  Show-Msg ("没找到便携版程序：`r`n$Exe`r`n`r`n请回到主电脑，用控制台「同步到 U 盘」把程序装进来。")
  exit 1
}
if (-not (Test-Path -LiteralPath $Target)) {
  Show-Msg ("没找到便携数据目录：`r`n$Target`r`n`r`n请先在主电脑用控制台同步一次。")
  exit 1
}

# 先自动恢复上次残留（含崩溃标记）
$mk = Read-TakeoverMarker
if ($mk -and (Test-Path -LiteralPath $Backup)) {
  Log '检测到上次临时接管未还原，正在还原本机数据目录…'
  $done = Restore-HostData -Force
  if ($done) { Clear-TakeoverMarker; Log '已还原本机数据目录。' }
  else { Show-Msg '上次临时接管未能自动还原，请手动处理后再启动。'; exit 1 }
} else {
  Restore-HostData | Out-Null
  if (-not $mk) { Clear-TakeoverMarker }
}

# ---------- 判断当前模式 ----------
$mode = ''
if (Test-Path -LiteralPath $AppData) {
  if (Test-IsLink $AppData) {
    $t = Get-LinkTarget $AppData
    if ($t -and ($t.TrimEnd('\') -eq $Target.TrimEnd('\'))) {
      $mode = 'link-ok'
    } else {
      try {
        Remove-Item -LiteralPath $AppData -Force -ErrorAction Stop
        $mode = 'create'
      } catch {
        Show-Msg ("旧的数据链接无法删除（可能有 DSH 还在运行）：`r`n$AppData`r`n`r`n请完全退出 DSH 后重试。")
        exit 1
      }
    }
  } else {
    $mode = 'takeover'
  }
} else {
  $mode = 'create'
}

# ---------- 本机已装 DSH：临时让位 ----------
if ($mode -eq 'takeover') {
  $procs = Get-DshProcs
  if ($procs.Count -gt 0 -and -not $DryRun) {
    Show-Msg ("这台电脑装有 DSH，而且正在运行：`r`n$AppData`r`n`r`n便携版需要临时接管数据目录，请先完全退出本机 DSH 再试。`r`n`r`n（本机 DSH 关闭后，本启动器会临时把它改名藏起来，退出便携版时自动还原。）")
    exit 1
  }

  if (-not $NoPrompt) {
    Write-Host ''
    Write-Host '这台电脑已经装了 DSH。' -ForegroundColor Yellow
    Write-Host ('便携版会临时把本机数据目录改名藏起来：')
    Write-Host ('  ' + $AppData)
    Write-Host ('  → ' + $Backup)
    Write-Host '退出便携版后会自动还原；期间本机 DSH 不能用（数据不会丢）。'
    $ans = Read-Host '继续吗？(y/N)'
    if ($ans -notmatch '^[Yy]') { Write-Host '已取消。'; exit 0 }
  }

  if ($DryRun) {
    Log ('[DryRun] 改名本机数据目录 → ' + $Backup)
    Log ('[DryRun] 建立链接 → ' + $Target)
    exit 0
  }

  try {
    Move-Item -LiteralPath $AppData -Destination $Backup -Force -ErrorAction Stop
    Write-TakeoverMarker
    Log '已临时移开本机数据目录。'
  } catch {
    Show-Msg ("无法改名本机数据目录（可能被占用）：`r`n$AppData`r`n`r`n" + [string]$_)
    exit 1
  }
}

# ---------- 建立/修正链接 ----------
if ($mode -ne 'link-ok') {
  if ($DryRun) { Log ('[DryRun] 建立链接 → ' + $Target); exit 0 }
  try {
    New-Item -ItemType Junction -Path $AppData -Target $Target -Force -ErrorAction Stop | Out-Null
    Log '已建立便携数据链接。'
  } catch {
    # 失败时把本机数据目录还原，避免留下半成品
    Restore-HostData -Force | Out-Null
    Show-Msg ("创建数据链接失败：`r`n$AppData`r`n`r`n" + [string]$_)
    exit 1
  }
}

if ($DryRun) { Log ('[DryRun] 启动 → ' + $Exe); exit 0 }

# ---------- 启动并等待退出 ----------
try {
  $p = Start-Process -FilePath $Exe -PassThru -ErrorAction Stop
} catch {
  if ($mode -eq 'takeover') { Restore-HostData -Force | Out-Null }
  Show-Msg ("启动 DSH 失败：`r`n" + [string]$_)
  exit 1
}

Log ('已启动 DSH（PID ' + $p.Id + '）。关闭 DSH 后会自动还原数据目录。')
$p.WaitForExit()
Start-Sleep -Milliseconds 800

# ---------- 退出后还原 ----------
if ($mode -eq 'takeover') {
  if (Test-Path -LiteralPath $Backup) {
    Remove-Item -LiteralPath $AppData -Force -ErrorAction SilentlyContinue
    try {
      Move-Item -LiteralPath $Backup -Destination $AppData -Force -ErrorAction Stop
      Clear-TakeoverMarker
      Log '已还原本机数据目录。'
    } catch {
      Log ('还原本机数据目录失败：' + [string]$_)
      Log ('请手动把 ' + $Backup + ' 改名为 ' + $AppData)
    }
  }
} else {
  Remove-Item -LiteralPath $AppData -Force -ErrorAction SilentlyContinue
  Log '已移除临时数据链接。'
}

exit 0
