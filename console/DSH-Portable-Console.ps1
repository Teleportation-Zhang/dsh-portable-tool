#requires -Version 5.0
# DSH 便携控制台 v1.1（WinForms 原生窗口，无需浏览器 / 无需 Python）
# v1.1 变化：子页面操作、插件勾选同步、内部对话框、执行中可取消
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$Root       = Split-Path -Parent $ScriptDir
$DataDir    = Join-Path $Root 'data\dsh-desktop'
$Harness    = Join-Path $DataDir 'harness'
$ManifestP  = Join-Path $Root 'manifest.json'
$AppData    = Join-Path $env:APPDATA 'dsh-desktop'
$HostHarness= Join-Path $AppData 'harness'
$ExePath    = Join-Path $Root 'program\DSH Desktop\DSH Desktop.exe'
$ConfigP    = Join-Path $ScriptDir 'console-config.json'

$NEVER = @('dsh-plugin-wallpaper-engine','dsh-whale-widget','dsh-better-sidebar',
           'dsh-plugin-save-token','dsh-550c-boot','dsh-wechat',
           'dsh-onebot-qq','@deepseek-ai/dsh-experimental-schedule-bundle')
$SESSION_PREFIXES = @('dsh.conversation.','dsh.sidebar-right.v1.session-',
                      'dsh.user-questions.drafts.v1.session-')
$SESSION_KEYS = @('dsh.sessions.current')

$Clr = @{
  Bg='#0a0e13'; Panel='#0f151c'; Card='#121b24'; Line='#1d2b38'
  Text='#dbe7f3'; Dim='#6f879e'; Cyan='#22d3ee'; CyanDim='#0e7490'
  Green='#34d399'; Amber='#fbbf24'; Red='#f87171'
}
function Get-Col([string]$name) {
  if ($Clr.ContainsKey($name)) { return [System.Drawing.ColorTranslator]::FromHtml($Clr[$name]) }
  return [System.Drawing.Color]::White
}
function New-Font([string]$family, [float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
  return New-Object System.Drawing.Font($family, $size, $style)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'DSH 便携控制台'
$form.ClientSize = New-Object System.Drawing.Size(1060, 700)
$form.StartPosition = 'CenterScreen'
$form.BackColor = Get-Col Bg
$form.ForeColor = Get-Col Text
$form.Font = New-Font 'Microsoft YaHei UI' 9
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false

# ---------- 左栏 ----------
$left = New-Object System.Windows.Forms.Panel
$left.Location = New-Object System.Drawing.Point(0, 0)
$left.Size = New-Object System.Drawing.Size(300, 700)
$left.BackColor = Get-Col Panel
$form.Controls.Add($left)

$logo = New-Object System.Windows.Forms.Label
$logo.Text = 'DSH PORTABLE'
$logo.Font = New-Font 'Consolas' 15 ([System.Drawing.FontStyle]::Bold)
$logo.ForeColor = Get-Col Cyan
$logo.Location = New-Object System.Drawing.Point(22, 20)
$logo.AutoSize = $true
$left.Controls.Add($logo)

$logoSub = New-Object System.Windows.Forms.Label
$logoSub.Text = '便携版控制台 v1.1'
$logoSub.Font = New-Font 'Microsoft YaHei UI' 8
$logoSub.ForeColor = Get-Col Dim
$logoSub.Location = New-Object System.Drawing.Point(23, 48)
$logoSub.AutoSize = $true
$left.Controls.Add($logoSub)

$usbCard = New-Object System.Windows.Forms.Panel
$usbCard.Location = New-Object System.Drawing.Point(20, 78)
$usbCard.Size = New-Object System.Drawing.Size(260, 132)
$usbCard.BackColor = Get-Col Card
$left.Controls.Add($usbCard)

$usbLabel = New-Object System.Windows.Forms.Label
$usbLabel.Text = 'U 盘'
$usbLabel.Font = New-Font 'Microsoft YaHei UI' 8
$usbLabel.ForeColor = Get-Col Dim
$usbLabel.Location = New-Object System.Drawing.Point(14, 8)
$usbLabel.AutoSize = $true
$usbCard.Controls.Add($usbLabel)

$usbDrive = New-Object System.Windows.Forms.Label
$usbDrive.Text = 'E:'
$usbDrive.Font = New-Font 'Consolas' 30 ([System.Drawing.FontStyle]::Bold)
$usbDrive.ForeColor = Get-Col Cyan
$usbDrive.Location = New-Object System.Drawing.Point(12, 24)
$usbDrive.AutoSize = $true
$usbCard.Controls.Add($usbDrive)

$usbState = New-Object System.Windows.Forms.Label
$usbState.Text = '检测中'
$usbState.Font = New-Font 'Microsoft YaHei UI' 8
$usbState.ForeColor = Get-Col Dim
$usbState.Location = New-Object System.Drawing.Point(92, 34)
$usbState.AutoSize = $true
$usbCard.Controls.Add($usbState)

$usbPath = New-Object System.Windows.Forms.Label
$usbPath.Text = ''
$usbPath.Font = New-Font 'Consolas' 8
$usbPath.ForeColor = Get-Col Dim
$usbPath.Location = New-Object System.Drawing.Point(14, 76)
$usbPath.AutoSize = $false
$usbPath.Size = New-Object System.Drawing.Size(232, 18)
$usbCard.Controls.Add($usbPath)

$usbSync = New-Object System.Windows.Forms.Label
$usbSync.Text = '上次同步：--'
$usbSync.Font = New-Font 'Microsoft YaHei UI' 8
$usbSync.ForeColor = Get-Col Dim
$usbSync.Location = New-Object System.Drawing.Point(14, 98)
$usbSync.AutoSize = $true
$usbCard.Controls.Add($usbSync)

$btnLaunch = New-Object System.Windows.Forms.Button
$btnLaunch.Text = '▶  一键启动 DSH'
$btnLaunch.Font = New-Font 'Microsoft YaHei UI' 11 ([System.Drawing.FontStyle]::Bold)
$btnLaunch.Location = New-Object System.Drawing.Point(20, 226)
$btnLaunch.Size = New-Object System.Drawing.Size(260, 52)
$btnLaunch.BackColor = Get-Col Cyan
$btnLaunch.ForeColor = Get-Col Bg
$btnLaunch.FlatStyle = 'Flat'
$btnLaunch.FlatAppearance.BorderSize = 0
$btnLaunch.Cursor = [System.Windows.Forms.Cursors]::Hand
$left.Controls.Add($btnLaunch)

$opButtons = @()
$opDefs = @(
  @{ Text='⇅  同步到 U 盘';   Key='sync' },
  @{ Text='↺  从 U 盘回滚';   Key='rollback' },
  @{ Text='⌦  清理残留';      Key='cleanup' },
  @{ Text='✕  清空 U 盘对话'; Key='wipe' },
  @{ Text='↩  还原本机数据目录'; Key='restore-host' }
)
$oy = 292
foreach ($d in $opDefs) {
  $b = New-Object System.Windows.Forms.Button
  $b.Text = $d.Text
  $b.Font = New-Font 'Microsoft YaHei UI' 9.5
  $b.Location = New-Object System.Drawing.Point(20, $oy)
  $b.Size = New-Object System.Drawing.Size(260, 38)
  $b.BackColor = Get-Col Card
  $b.ForeColor = Get-Col Text
  $b.FlatStyle = 'Flat'
  $b.FlatAppearance.BorderColor = Get-Col Line
  $b.FlatAppearance.BorderSize = 1
  $b.TextAlign = 'MiddleLeft'
  $b.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
  $b.Cursor = [System.Windows.Forms.Cursors]::Hand
  $b.Tag = $d.Key
  $left.Controls.Add($b)
  $opButtons += $b
  $oy += 46
}

$hostState = New-Object System.Windows.Forms.Label
$hostState.Text = '本机状态读取中…'
$hostState.Font = New-Font 'Microsoft YaHei UI' 8
$hostState.ForeColor = Get-Col Dim
$hostState.Location = New-Object System.Drawing.Point(22, 640)
$hostState.AutoSize = $true
$left.Controls.Add($hostState)

# ---------- 右栏 ----------
$right = New-Object System.Windows.Forms.Panel
$right.Location = New-Object System.Drawing.Point(300, 0)
$right.Size = New-Object System.Drawing.Size(760, 700)
$right.BackColor = Get-Col Bg
$form.Controls.Add($right)

function New-Label([string]$text, [float]$size, [string]$col, [int]$x, [int]$y, [bool]$bold = $false) {
  $l = New-Object System.Windows.Forms.Label
  $l.Text = $text
  $l.Font = New-Font 'Microsoft YaHei UI' $size $(if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular })
  $l.ForeColor = Get-Col $col
  $l.Location = New-Object System.Drawing.Point($x, $y)
  $l.AutoSize = $true
  return $l
}
function New-Box([int]$x, [int]$y, [int]$w, [int]$h, [string]$col) {
  $p = New-Object System.Windows.Forms.Panel
  $p.Location = New-Object System.Drawing.Point($x, $y)
  $p.Size = New-Object System.Drawing.Size($w, $h)
  $p.BackColor = Get-Col $col
  return $p
}
function New-Bar([int]$x, [int]$y, [int]$w) {
  $pb = New-Object System.Windows.Forms.ProgressBar
  $pb.Location = New-Object System.Drawing.Point($x, $y)
  $pb.Size = New-Object System.Drawing.Size($w, 10)
  $pb.Minimum = 0; $pb.Maximum = 100; $pb.Value = 0
  $pb.Style = 'Blocks'
  return $pb
}
function New-Log([int]$x, [int]$y, [int]$w, [int]$h) {
  $rt = New-Object System.Windows.Forms.RichTextBox
  $rt.Location = New-Object System.Drawing.Point($x, $y)
  $rt.Size = New-Object System.Drawing.Size($w, $h)
  $rt.BackColor = Get-Col Card
  $rt.ForeColor = Get-Col Text
  $rt.BorderStyle = 'None'
  $rt.Font = New-Font 'Consolas' 8.5
  $rt.ReadOnly = $true
  $rt.ScrollBars = 'Vertical'
  return $rt
}

# ---------- home 视图 ----------
$homeView = New-Object System.Windows.Forms.Panel
$homeView.Location = New-Object System.Drawing.Point(26, 20)
$homeView.Size = New-Object System.Drawing.Size(708, 660)
$homeView.BackColor = Get-Col Bg
$right.Controls.Add($homeView)

$homeView.Controls.Add((New-Label '控制台' 14 'Text' 0 0 $true)) | Out-Null
$homeView.Controls.Add((New-Label '同步 · 回滚 · 清理 · 启动，对话数据永不进入同步' 8 'Dim' 2 30)) | Out-Null

$envCard = New-Box 0 60 708 92 'Panel'
$homeView.Controls.Add($envCard)
$envCard.Controls.Add((New-Label '本机环境' 8 'Dim' 14 8)) | Out-Null
$envFields = @()
$fx = 14
foreach ($lab in @('DSH 版本','安装体积','DSH_HOME 体积','插件包')) {
  $envCard.Controls.Add((New-Label $lab 7.5 'Dim' $fx 30)) | Out-Null
  $v = New-Label '--' 12 'Text' $fx 48
  $v.Font = New-Font 'Consolas' 12 ([System.Drawing.FontStyle]::Bold)
  $envCard.Controls.Add($v) | Out-Null
  $envFields += $v
  $fx += 170
}

$homeView.Controls.Add((New-Label '从左侧选择操作：点一下进入子页面，确认选项后再执行。' 8.5 'Dim' 0 170)) | Out-Null
$homeProg = New-Bar 0 200 708
$homeView.Controls.Add($homeProg)
$homePhase = New-Label '就绪。' 8 'Dim' 0 216
$homeView.Controls.Add($homePhase)
$homeLog = New-Log 0 242 708 418
$homeView.Controls.Add($homeLog)

# ---------- op 视图 ----------
$opView = New-Object System.Windows.Forms.Panel
$opView.Location = New-Object System.Drawing.Point(26, 20)
$opView.Size = New-Object System.Drawing.Size(708, 660)
$opView.BackColor = Get-Col Bg
$opView.Visible = $false
$right.Controls.Add($opView)

$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Text = '← 返回'
$btnBack.Location = New-Object System.Drawing.Point(0, 0)
$btnBack.Size = New-Object System.Drawing.Size(86, 32)
$btnBack.BackColor = Get-Col Card
$btnBack.ForeColor = Get-Col Text
$btnBack.FlatStyle = 'Flat'
$btnBack.FlatAppearance.BorderColor = Get-Col Line
$btnBack.FlatAppearance.BorderSize = 1
$btnBack.Cursor = [System.Windows.Forms.Cursors]::Hand
$opView.Controls.Add($btnBack)

$opTitle = New-Label '同步到 U 盘' 14 'Text' 100 2 $true
$opView.Controls.Add($opTitle)
$opDesc = New-Label '' 8 'Dim' 0 38
$opDesc.Size = New-Object System.Drawing.Size(708, 34)
$opDesc.AutoSize = $false
$opView.Controls.Add($opDesc)

$pluginList = New-Object System.Windows.Forms.CheckedListBox
$pluginList.Location = New-Object System.Drawing.Point(0, 80)
$pluginList.Size = New-Object System.Drawing.Size(708, 296)
$pluginList.BackColor = Get-Col Card
$pluginList.ForeColor = Get-Col Text
$pluginList.BorderStyle = 'FixedSingle'
$pluginList.CheckOnClick = $true
$pluginList.Font = New-Font 'Microsoft YaHei UI' 9
$pluginList.IntegralHeight = $false
$opView.Controls.Add($pluginList)

$opNote = New-Label '' 8.5 'Dim' 0 84
$opNote.Size = New-Object System.Drawing.Size(708, 296)
$opNote.AutoSize = $false
$opView.Controls.Add($opNote)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = '开始同步'
$btnRun.Font = New-Font 'Microsoft YaHei UI' 10 ([System.Drawing.FontStyle]::Bold)
$btnRun.Location = New-Object System.Drawing.Point(0, 398)
$btnRun.Size = New-Object System.Drawing.Size(220, 42)
$btnRun.BackColor = Get-Col Cyan
$btnRun.ForeColor = Get-Col Bg
$btnRun.FlatStyle = 'Flat'
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$opView.Controls.Add($btnRun)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = '■ 取消'
$btnCancel.Font = New-Font 'Microsoft YaHei UI' 9.5
$btnCancel.Location = New-Object System.Drawing.Point(232, 398)
$btnCancel.Size = New-Object System.Drawing.Size(140, 42)
$btnCancel.BackColor = Get-Col Card
$btnCancel.ForeColor = Get-Col Amber
$btnCancel.FlatStyle = 'Flat'
$btnCancel.FlatAppearance.BorderColor = Get-Col Line
$btnCancel.FlatAppearance.BorderSize = 1
$btnCancel.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnCancel.Visible = $false
$opView.Controls.Add($btnCancel)

$opProg = New-Bar 0 448 708
$opView.Controls.Add($opProg)
$opPhase = New-Label '就绪。' 8 'Dim' 0 464
$opView.Controls.Add($opPhase)
$opLog = New-Log 0 490 708 166
$opView.Controls.Add($opLog)

# ---------- 状态 ----------
$script:HostInfo = $null
$script:UsbInfo  = $null
$script:Manifest = $null
$script:Busy     = $false
$script:CancelRequested = $false
$script:ActiveLog = $homeLog
$script:OpKey = ''
$script:DlgResult = $null
$script:DlgDone = $false

function Log([string]$msg, [string]$col = 'Text') {
  $box = $script:ActiveLog
  $box.SelectionStart = $box.TextLength
  $box.SelectionColor = Get-Col $col
  $box.AppendText(('[' + (Get-Date -Format 'HH:mm:ss') + '] ' + $msg) + "`r`n")
  $box.SelectionStart = $box.TextLength
  $box.ScrollToCaret()
  [System.Windows.Forms.Application]::DoEvents()
}
function Pump() { [System.Windows.Forms.Application]::DoEvents() }
function Set-Progress([int]$pct, [string]$text) {
  $v = [Math]::Max(0, [Math]::Min(100, $pct))
  $homeProg.Value = $v
  $opProg.Value = $v
  $homePhase.Text = $text
  $opPhase.Text = $text
  Pump
}
function Set-Busy([bool]$busy) {
  $script:Busy = $busy
  foreach ($b in $opButtons) { $b.Enabled = (-not $busy) }
  $btnLaunch.Enabled = (-not $busy)
  $btnRun.Enabled = (-not $busy)
  $btnBack.Enabled = (-not $busy)
  $btnCancel.Visible = $busy
  $btnCancel.Enabled = $true
  $btnCancel.Text = '■ 取消'
}
function Fmt-Bytes([double]$bytes) {
  if ($bytes -ge 1GB) { return ('{0:N1} GB' -f ($bytes / 1GB)) }
  return ('{0:N0} MB' -f ($bytes / 1MB))
}
$script:DirSizeCache = @{}
function Get-DirSize([string]$path) {
  if (-not $path) { return 0 }
  $c = $script:DirSizeCache[$path]
  if ($c -and ((Get-Date) - $c.Time).TotalSeconds -lt 90) { return $c.Size }
  if (-not (Test-Path -LiteralPath $path)) { return 0 }
  $sum = 0
  try { $sum = (Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch { $sum = 0 }
  if (-not $sum) { $sum = 0 }
  $script:DirSizeCache[$path] = @{ Size = [double]$sum; Time = (Get-Date) }
  return [double]$sum
}
function Find-InstallDir {
  $cands = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness'),
    # 如需其它安装位置，在这里补充候选路径
    
  )
  foreach ($c in $cands) {
    if ($c -and (Test-Path -LiteralPath (Join-Path $c 'DSH Desktop.exe'))) { return $c }
  }
  return $null
}
function Get-InstallVersion([string]$dir) {
  if (-not $dir) { return '' }
  $exe = Join-Path $dir 'DSH Desktop.exe'
  if (Test-Path -LiteralPath $exe) {
    try { return (Get-Item -LiteralPath $exe).VersionInfo.FileVersion.Trim() } catch { return '' }
  }
  return ''
}
function Read-Manifest {
  if (Test-Path -LiteralPath $ManifestP) {
    try { return (Get-Content -LiteralPath $ManifestP -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
  }
  return $null
}
function Get-Plugins {
  $pkg = Join-Path $HostHarness 'profiles\web\package.json'
  if (-not (Test-Path -LiteralPath $pkg)) { return @() }
  try {
    $j = Get-Content -LiteralPath $pkg -Raw -Encoding UTF8 | ConvertFrom-Json
    $deps = $j.dependencies
    if (-not $deps) { return @() }
    $list = @()
    foreach ($prop in $deps.PSObject.Properties) {
      $list += [pscustomobject]@{ Name = $prop.Name; Version = [string]$prop.Value }
    }
    return $list
  } catch { return @() }
}
function Load-Config {
  if (Test-Path -LiteralPath $ConfigP) {
    try { return (Get-Content -LiteralPath $ConfigP -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
  }
  return $null
}
function Write-Utf8NoBom([string]$path, [string]$text) {
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}
function Save-Config($cfg) {
  try { Write-Utf8NoBom $ConfigP ($cfg | ConvertTo-Json -Depth 10) } catch { }
}
function Refresh-State {
  $hi = @{ Dir = (Find-InstallDir); Version = ''; Size = 0; HomeSize = 0; Plugins = @() }
  $hi.Version = Get-InstallVersion $hi.Dir
  $hi.Size = Get-DirSize $hi.Dir
  # 接管中：%APPDATA%\dsh-desktop 是 junction → 扫它等于扫 U 盘（USB 随机读，几十秒）
  $mfR = Read-Manifest
  $dshRootR = Join-Path $env:APPDATA 'dsh-desktop'
  $isTk = $false
  if (Test-Path -LiteralPath $dshRootR) {
    try { $itR = Get-Item -LiteralPath $dshRootR -Force; $isTk = [bool]($itR.Attributes -band [System.IO.FileAttributes]::ReparsePoint) } catch { }
  }
  if ($isTk -and $mfR -and $mfR.syncBytes) { $hi.HomeSize = [double]$mfR.syncBytes }
  else { $hi.HomeSize = Get-DirSize $HostHarness }
  $hi.Plugins = Get-Plugins
  $script:HostInfo = $hi
  $script:UsbInfo = @{
    Drive = ($Root.Substring(0,2))
    Path = $Root
    Initialized = (Test-Path -LiteralPath $DataDir)
    Manifest = (Read-Manifest)
  }
  $envFields[0].Text = if ($hi.Version) { $hi.Version } else { '--' }
  $envFields[1].Text = Fmt-Bytes $hi.Size
  $envFields[2].Text = Fmt-Bytes $hi.HomeSize
  $envFields[3].Text = ('{0} 包' -f $hi.Plugins.Count)
  $usbDrive.Text = $script:UsbInfo.Drive
  $usbState.Text = if ($script:UsbInfo.Initialized) { '便携目录就绪' } else { '待初始化' }
  $usbPath.Text = $script:UsbInfo.Path
  $m = $script:UsbInfo.Manifest
  $usbSync.Text = '上次同步：' + $(if ($m -and $m.lastSync) { [string]$m.lastSync } else { '--' })
  $hostState.Text = ('本机 DSH {0} · 插件 {1} 个' -f $hi.Version, $hi.Plugins.Count)
}

# ---------- 视图切换 ----------
function Show-Home {
  $script:ActiveLog = $homeLog
  $homeView.Visible = $true
  $opView.Visible = $false
  $script:OpKey = ''
  Refresh-State
}
function Show-OpPage([string]$key) {
  $script:OpKey = $key
  $homeView.Visible = $false
  $opView.Visible = $true
  $script:ActiveLog = $opLog
  $opLog.Clear()
  Set-Progress 0 '就绪。'
  $mk = Read-TakeoverMarker
  if ($mk -or (Test-Path -LiteralPath $BackupPath)) {
    $procs = @(Get-Process -Name 'DSH Desktop' -ErrorAction SilentlyContinue)
    if ($procs.Count -eq 0) {
      if (Restore-HostData -Force) { Log '检测到上次未还原的接管，已自动还原本机数据目录。' 'Green' }
    } else {
      Log '检测到上次接管未还原，但 DSH 正在运行；关闭 DSH 后会自动还原。' 'Amber'
    }
  }
  $btnRun.Visible = $true
  $btnRun.Enabled = $true
  $btnCancel.Visible = $false
  $pluginList.Visible = $false
  $opNote.Visible = $false

  switch ($key) {
    'sync' {
      $opTitle.Text = '同步到 U 盘'
      $opDesc.Text = '把本机 DSH 的配置、密钥与勾选的插件复制到 U 盘。对话（会话/附件/草稿）永远不会进入 U 盘。'
      $btnRun.Text = '开始同步'
      $pluginList.Visible = $true
      $opNote.Visible = $false
      Load-PluginList
      Log '已读取本机插件列表，勾选要同步的插件后点「开始同步」。' 'Dim'
    }
    'rollback' {
      $opTitle.Text = '从 U 盘回滚'
      $opDesc.Text = '用 U 盘上的配置与插件覆盖本机 DSH。本机会话不受影响，执行前会自动备份本机当前状态。'
      $btnRun.Text = '开始回滚'
      $opNote.Text = "回滚会覆盖：profiles\web 配置、插件、密钥、AGENTS.md`r`n不回滚：sessions、attachments、cache、logs、media`r`n`r`n执行前会把本机 DSH_HOME 备份到 %APPDATA%\dsh-desktop\harness-backup-<时间>。`r`n回滚完成后需要完全退出并重新打开 DSH。"
      $opNote.Visible = $true
      Log '准备回滚。' 'Dim'
    }
    'cleanup' {
      $opTitle.Text = '清理残留'
      $opDesc.Text = '删除 U 盘数据目录里的缓存、日志、恢复记录、临时文件与旧备份（保留最近 2 个）。对话内容不受影响。'
      $btnRun.Text = '开始清理'
      $opNote.Text = "会清理：cache、recovery、logs、media\onebot、desktop-host-sources.patch.yml、*.tmp`r`n以及 backups 里除最近 2 个之外的旧备份。`r`n`r`n不会碰：插件、配置、密钥、对话。"
      $opNote.Visible = $true
      Log '准备清理。' 'Dim'
    }
    'wipe' {
      $opTitle.Text = '清空 U 盘对话'
      $opDesc.Text = '永久删除 U 盘上的全部会话、附件、界面草稿与工作区里的会话索引。插件、配置、密钥保留，本机对话不受影响。'
      $btnRun.Text = '清空对话'
      $opNote.Text = "会删除：sessions、attachments、recovery、media、storages\session_projcache`r`n并清除：desktop-storage.json 里的会话键与草稿、workspace.json 的 sessionIds`r`n`r`n删除后不可恢复。"
      $opNote.Visible = $true
      Log '准备清空对话框。' 'Dim'
    }
  }
}

function Load-PluginList {
  $pluginList.Items.Clear()
  $cfg = Load-Config
  $selected = @()
  if ($cfg -and $cfg.syncPlugins) { $selected = @($cfg.syncPlugins) }
  $plugins = Get-Plugins
  foreach ($p in $plugins) {
    $checked = $true
    if ($selected.Count -gt 0) { $checked = ($selected -contains $p.Name) }
    else { $checked = -not ($NEVER -contains $p.Name) }
    if ($NEVER -contains $p.Name) { $checked = $false }
    $idx = $pluginList.Items.Add(($p.Name + '    ' + $p.Version))
    $pluginList.SetItemChecked($idx, $checked)
  }
}

# ---------- 内部对话框 ----------
function Show-Dialog([string]$title, [string]$body, [string]$okText = '确定', [string]$cancelText = '') {
  $script:DlgResult = $null
  $script:DlgDone = $false
  $overlay = New-Object System.Windows.Forms.Panel
  $overlay.Bounds = New-Object System.Drawing.Rectangle(0, 0, $form.ClientSize.Width, $form.ClientSize.Height)
  $overlay.BackColor = [System.Drawing.Color]::FromArgb(210, 5, 8, 12)
  $form.Controls.Add($overlay)
  $overlay.BringToFront()

  $card = New-Box 220 170 620 260 'Card'
  $card.BackColor = Get-Col Panel
  $overlay.Controls.Add($card)
  $tl = New-Label $title 11 'Text' 24 18 $true
  $card.Controls.Add($tl)
  $bl = New-Label $body 9 'Text' 24 56
  $bl.Size = New-Object System.Drawing.Size(572, 130)
  $bl.AutoSize = $false
  $card.Controls.Add($bl)

  $okBtn = New-Object System.Windows.Forms.Button
  $okBtn.Text = $okText
  $okBtn.Size = New-Object System.Drawing.Size(120, 36)
  $okBtn.BackColor = Get-Col Cyan
  $okBtn.ForeColor = Get-Col Bg
  $okBtn.FlatStyle = 'Flat'
  $okBtn.FlatAppearance.BorderSize = 0
  $okBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
  $okBtn.Location = New-Object System.Drawing.Point(472, 212)
  $card.Controls.Add($okBtn)

  $cancelBtn = $null
  if ($cancelText) {
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = $cancelText
    $cancelBtn.Size = New-Object System.Drawing.Size(120, 36)
    $cancelBtn.BackColor = Get-Col Card
    $cancelBtn.ForeColor = Get-Col Text
    $cancelBtn.FlatStyle = 'Flat'
    $cancelBtn.FlatAppearance.BorderColor = Get-Col Line
    $cancelBtn.FlatAppearance.BorderSize = 1
    $cancelBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cancelBtn.Location = New-Object System.Drawing.Point(340, 212)
    $card.Controls.Add($cancelBtn)
  }

  $close = {
    param($val)
    $script:DlgResult = $val
    $script:DlgDone = $true
  }
  $okBtn.Add_Click({ & $close $true }.GetNewClosure())
  if ($cancelBtn) { $cancelBtn.Add_Click({ & $close $false }.GetNewClosure()) }

  while (-not $script:DlgDone) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 25
  }
  $form.Controls.Remove($overlay)
  $overlay.Dispose()
  return $script:DlgResult
}
function Show-Confirm([string]$title, [string]$body) {
  return (Show-Dialog $title $body '继续' '取消')
}
function Show-Notice([string]$title, [string]$body) {
  return (Show-Dialog $title $body '知道了')
}

# ---------- 操作 ----------
function Run-Robocopy([string]$src, [string]$dst, [string[]]$extra = @()) {
  $argLine = '"' + $src + '" "' + $dst + '" /E /NFL /NDL /NJH /NJS /R:1 /W:1'
  foreach ($e in $extra) { $argLine += ' ' + $e }
  $p = Start-Process -FilePath 'robocopy.exe' -ArgumentList $argLine -PassThru -WindowStyle Hidden
  while (-not $p.HasExited) {
    if ($script:CancelRequested) {
      try { $p.Kill() } catch { }
      throw 'cancelled'
    }
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 80
  }
  return $p.ExitCode
}

function Invoke-Sync([string[]]$SelectedPlugins) {
  try {
    $script:CancelRequested = $false
    Set-Busy $true
    Set-Progress 3 '准备同步'
    Log '开始同步：本机 DSH_HOME → U 盘' 'Cyan'
    if (-not (Test-Path -LiteralPath $HostHarness)) { Log ('本机没有 DSH_HOME：' + $HostHarness) 'Red'; return }

    $allDeps = @()
    $pkgSrc = Join-Path $HostHarness 'profiles\web\package.json'
    if (Test-Path -LiteralPath $pkgSrc) {
      try { $allDeps = @((Get-Content -LiteralPath $pkgSrc -Raw -Encoding UTF8 | ConvertFrom-Json).dependencies.PSObject.Properties.Name) } catch { }
    }
    $keep = @($SelectedPlugins)
    $drop = @($allDeps | Where-Object { $keep -notcontains $_ })
    Log ('同步插件：' + ($keep -join ', '))
    if ($drop.Count -gt 0) { Log ('不同步插件：' + ($drop -join ', ')) 'Dim' }

    Set-Progress 8 '清理目标数据目录'
    if (Test-Path -LiteralPath $Harness) { Remove-Item -LiteralPath $Harness -Recurse -Force -ErrorAction SilentlyContinue }
    $webDst = Join-Path $Harness 'profiles\web'
    New-Item -ItemType Directory -Path $webDst -Force | Out-Null

    $srcWeb = Join-Path $HostHarness 'profiles\web'
    Set-Progress 12 '复制 profiles/web 配置'
    foreach ($f in @('package.json','cordis.patch.yml','cordis.yml','desktop-storage.json')) {
      $p = Join-Path $srcWeb $f
      if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination (Join-Path $webDst $f) -Force }
    }
    Log '配置已复制：package.json / cordis.patch.yml / cordis.yml / desktop-storage.json'
    # 市场缓存与插件管理状态（否则 U 盘版提示「未能获取市场版本信息」）
    foreach ($d in @('.dsh-market','.plugin-manager','.dsh-module-fallback')) {
      $srcD = Join-Path $srcWeb $d
      if (Test-Path -LiteralPath $srcD) {
        $dstD = Join-Path $webDst $d
        if (Test-Path -LiteralPath $dstD) { Remove-Item -LiteralPath $dstD -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item -LiteralPath $srcD -Destination $dstD -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
    foreach ($f in @('pnpm-workspace.yaml','pnpm-lock.yaml','.npmrc','.generations-migrated')) {
      $p2 = Join-Path $srcWeb $f
      if (Test-Path -LiteralPath $p2) { Copy-Item -LiteralPath $p2 -Destination (Join-Path $webDst $f) -Force }
    }
    Log '辅助配置已复制：市场缓存 / 插件管理状态 / pnpm 配置'

    $srcNm = Join-Path $srcWeb 'node_modules'
    if (Test-Path -LiteralPath $srcNm) {
      Set-Progress 20 '复制 node_modules'
      $rc = Run-Robocopy $srcNm (Join-Path $webDst 'node_modules')
      if ($rc -ge 8) { Log ('node_modules 复制出现错误（robocopy ' + $rc + '）') 'Amber' }
      Log 'node_modules 已复制'
    }
    # 插件包副本（profiles\.generations）：package.json 的 pnpm.overrides 用 link: 指向这里，
    # 不复制的话目标机 lock-recovery 解析不到 billion-context / dsh-damage-pulse / dsh-token-usage-stats
    $genSrc = Join-Path $HostHarness 'profiles\.generations'
    if (Test-Path -LiteralPath $genSrc) {
      Set-Progress 45 '复制 .generations（插件包）'
      $null = Run-Robocopy $genSrc (Join-Path $Harness 'profiles\.generations')
      Log '.generations 已复制（供 pnpm.overrides 的 link 解析）'
    }
    # 把 link: 安装的插件在 node_modules 里做成 junction（与主电脑一致）。
    # 若留实体目录，DSH 启动时的 generation projection 会尝试再建 symlink 而报 EISDIR。
    try {
      $pkgLink = Get-Content -LiteralPath (Join-Path $webDst 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($pkgLink.pnpm -and $pkgLink.pnpm.overrides) {
        foreach ($prop in $pkgLink.pnpm.overrides.PSObject.Properties) {
          $ov = [string]$prop.Value
          if ($ov -notlike 'link:*') { continue }
          $relPath = $ov.Substring(5)
          $tgt = if ([System.IO.Path]::IsPathRooted($relPath)) { $relPath } else { Join-Path $webDst $relPath }
          if (-not (Test-Path -LiteralPath $tgt)) { continue }
          $linkPath = Join-Path (Join-Path $webDst 'node_modules') $prop.Name
          if (Test-Path -LiteralPath $linkPath) {
            $li = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
            if ($li -and (($li.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)) { continue }
            Remove-Item -LiteralPath $linkPath -Recurse -Force -ErrorAction SilentlyContinue
          }
          New-Item -ItemType Junction -Path $linkPath -Target $tgt -ErrorAction Stop | Out-Null
          Log ('本地链接已建立：' + $prop.Name)
        }
      }
    } catch { Log ('建立本地链接失败：' + $_) 'Amber' }
    foreach ($d in @('data','storages','skills','kimi-ppt')) {
      $src = Join-Path $HostHarness $d
      if (Test-Path -LiteralPath $src) {
        Set-Progress 55 ($d + ' 复制中')
        $null = Run-Robocopy $src (Join-Path $Harness $d) @('/XD','session_projcache')
        Log ($d + ' 已复制')
      }
    }
    $agents = Join-Path $HostHarness 'AGENTS.md'
    if (Test-Path -LiteralPath $agents) { Copy-Item -LiteralPath $agents -Destination (Join-Path $Harness 'AGENTS.md') -Force }

    Set-Progress 86 '剔除会话数据'
    $storageDst = Join-Path $webDst 'desktop-storage.json'
    if (Test-Path -LiteralPath $storageDst) {
      try {
        $json = Get-Content -LiteralPath $storageDst -Raw -Encoding UTF8 | ConvertFrom-Json
        $removed = 0
        foreach ($prop in @($json.PSObject.Properties)) {
          $k = $prop.Name
          $hit = $false
          foreach ($pre in $SESSION_PREFIXES) { if ($k.StartsWith($pre)) { $hit = $true; break } }
          if (-not $hit) { foreach ($sk in $SESSION_KEYS) { if ($k -eq $sk) { $hit = $true; break } } }
          if ($hit) { $json.PSObject.Properties.Remove($k); $removed++ }
        }
        Write-Utf8NoBom $storageDst ($json | ConvertTo-Json -Depth 100 -Compress)
        Log ('desktop-storage 剔除会话键 ' + $removed + ' 个')
      } catch { Log ('desktop-storage 处理失败：' + $_) 'Amber' }
    }
    $wsDst = Join-Path $Harness 'storages\workspace.json'
    if (Test-Path -LiteralPath $wsDst) {
      try {
        $ws = Get-Content -LiteralPath $wsDst -Raw -Encoding UTF8 | ConvertFrom-Json
        $cnt = 0
        foreach ($prop in @($ws.PSObject.Properties)) {
          $v = $prop.Value
          if ($v -and $v.PSObject.Properties['sessionIds']) {
            if (@($v.sessionIds).Count -gt 0) { $cnt++ }
            $v.sessionIds = @()
          }
        }
        Write-Utf8NoBom $wsDst ($ws | ConvertTo-Json -Depth 100 -Compress)
        Log ('workspace.json 清空 sessionIds（' + $cnt + ' 个工作区）')
      } catch { Log ('workspace.json 处理失败：' + $_) 'Amber' }
    }

    Set-Progress 93 '处理密钥文件'
    $credSrc = Join-Path $HostHarness '.credentials.yaml'
    if (Test-Path -LiteralPath $credSrc) {
      $text = Get-Content -LiteralPath $credSrc -Raw -Encoding UTF8
      $lines = $text -split "`r?`n"
      $out = New-Object System.Collections.Generic.List[string]
      $skip = $false
      foreach ($line in $lines) {
        if ($line -match '^records:') { $skip = $true; continue }
        if ($skip -and $line -match '^\S') { $skip = $false }
        if (-not $skip) { $out.Add($line) }
      }
      Write-Utf8NoBom (Join-Path $Harness '.credentials.yaml') ($out -join "`r`n")
      Log '密钥已复制（已剥离浏览器会话授权）'
    }

    Set-Progress 96 '应用插件同步开关'
    if ($true) {
      $pkgDst = Join-Path $webDst 'package.json'
      if (Test-Path -LiteralPath $pkgDst) {
        try {
          $pj = Get-Content -LiteralPath $pkgDst -Raw -Encoding UTF8 | ConvertFrom-Json
          # 重建 dependencies：与 bundles 同步裁剪（heal 会把 dependencies 里带 bundle.patch 的包加回 bundles）
          $srcPj = $null
          try { $srcPj = Get-Content -LiteralPath $pkgSrc -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
          $newDeps = [ordered]@{}
          foreach ($k in $keep) {
            $ver = $null
            if ($srcPj) { $sp = $srcPj.dependencies.PSObject.Properties[$k]; if ($sp) { $ver = $sp.Value } }
            if (-not $ver) {
              $nmPkg = Join-Path $webDst ('node_modules\' + $k + '\package.json')
              if (Test-Path -LiteralPath $nmPkg) { try { $ver = (Get-Content $nmPkg -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch { } }
            }
            if (-not $ver) { $ver = '0.0.0' }
            $newDeps[$k] = $ver
          }
          $pj.dependencies = [pscustomobject]$newDeps
          $pj.dsh.profile.bundles = @('@deepseek-ai/dsh-base','@deepseek-ai/dsh-web-app') + ($keep | Where-Object { $_ -ne '@deepseek-ai/dsh-base' -and $_ -ne '@deepseek-ai/dsh-web-app' })
          # 不做「隔离」：deps 已裁剪，heal 不会加回未勾选插件；
          # 改 dsh.bundle.patch 会经 junction 污染 .generations 原始包，
          # 导致目标机 preflight 报 "dsh.bundle.patch must be a file path or a list of file paths"。
          Write-Utf8NoBom $pkgDst ($pj | ConvertTo-Json -Depth 100)
          Log ('依赖清单（' + $newDeps.Count + ' 项）：' + (($newDeps.Keys) -join ', '))
          Log ('插件启用列表（' + (@($pj.dsh.profile.bundles).Count) + ' 项）：' + ($pj.dsh.profile.bundles -join ', '))
        } catch { Log ('package.json 处理失败：' + $_) 'Amber' }
      }
      # 保留 node_modules 内容（不删目录，避免触发 pnpm 重装）

      # 保留 pnpm-lock.yaml 与 .modules.yaml 原样（避免触发重装）
      $patchDst = Join-Path $webDst 'cordis.patch.yml'
      if (Test-Path -LiteralPath $patchDst) {
        try {
          $pl = Get-Content -LiteralPath $patchDst -Encoding UTF8
          $outLines = New-Object System.Collections.Generic.List[string]
          $block = New-Object System.Collections.Generic.List[string]
          $flush = {
            param($blk)
            if ($blk.Count -eq 0) { return }
            $t = ($blk -join "`r`n")
            $remove = $false
            $idm = [regex]::Match($t, '^- id:\s*([^\s#]+)')
            $idv = ''
            if ($idm.Success) { $idv = $idm.Groups[1].Value }
            foreach ($d in $drop) {
              if ($t -match ('name:\s*["'']?' + [regex]::Escape($d) + '["'']?')) { $remove = $true; break }
              if ($idv -ne '' -and $d.StartsWith($idv)) { $remove = $true; break }
            }
            if (-not $remove) { foreach ($b in $blk) { $outLines.Add($b) } }
          }
          foreach ($line in $pl) {
            if ($line -match '^- ') {
              & $flush $block
              $block = New-Object System.Collections.Generic.List[string]
              $block.Add($line)
            } else { $block.Add($line) }
          }
          & $flush $block
          Write-Utf8NoBom $patchDst ($outLines -join "`r`n")
          Log '已从 cordis.patch.yml 移除未勾选插件'
        } catch { Log ('cordis.patch.yml 处理失败：' + $_) 'Amber' }
      }
    }
    # 便携修正：把本机环境依赖改写成便携版可用的形式
    try {
      $pkgFix = Join-Path $webDst 'package.json'
      if (Test-Path -LiteralPath $pkgFix) {
        $pf = Get-Content -LiteralPath $pkgFix -Raw -Encoding UTF8 | ConvertFrom-Json
        $fixed = $false
        if ($pf.dependencies.'dsh-audio-listen' -like 'link:*') { $pf.dependencies.'dsh-audio-listen' = '0.1.0'; $fixed = $true }
        # overrides 保留：link:../.generations/live/... 指向 U 盘 profiles\.generations（已同步复制）
        # 清空 overrides 会让这几个 link 安装的插件在目标机 lock-recovery 时被裁掉
        if ($fixed) {
          Write-Utf8NoBom $pkgFix ($pf | ConvertTo-Json -Depth 100)
          Log '便携修正：audio-listen 改为 0.1.0、pnpm.overrides 已保留（link → U 盘 .generations）'
        }
      }
    } catch { Log ('便携修正失败：' + $_) 'Amber' }
      # 便携修正后刷新 good 备份（保证 good 是「便携可用」状态）
      $pkgGoodSrc = Join-Path $webDst 'package.json'
      if (Test-Path -LiteralPath $pkgGoodSrc) { Copy-Item -LiteralPath $pkgGoodSrc -Destination (Join-Path $webDst 'package.json.good') -Force }
    # 离线依赖补装（U 盘 backups\offline-pkgs 已缓存 tarball，不需要联网）
    $offlineFix = Join-Path $Root 'console\lib\install-offline-deps.ps1'
    if (Test-Path -LiteralPath $offlineFix) {
      try {
        Set-Progress 97 '补装离线依赖'
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $offlineFix -Root $Root 2>&1
        $inst = @($out | Where-Object { $_ -match 'installed|from usb cache' }).Count
        Log ('离线依赖检查完成（' + $inst + ' 条安装记录）')
      } catch { Log ('离线依赖补装失败：' + $_) 'Amber' }
    }
    Set-Progress 98 '写入 manifest'
    $m = @{
      createdAt   = if ($script:Manifest -and $script:Manifest.createdAt) { $script:Manifest.createdAt } else { (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') }
      lastSync    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
      machine     = $env:COMPUTERNAME
      dshVersion  = $script:HostInfo.Version
      syncBytes   = (Get-DirSize $Harness)
      pluginsRemoved = $drop
    }
    Write-Utf8NoBom $ManifestP ($m | ConvertTo-Json -Depth 10)
    Save-Config @{ syncPlugins = $keep }
    $size = Fmt-Bytes (Get-DirSize $Harness)
    Set-Progress 100 ('同步完成 · ' + $size)
    Log ('同步完成：' + $Harness + '（' + $size + '）') 'Green'
    Refresh-State
  } catch {
    if ($script:CancelRequested) {
      Log '同步已取消。U 盘上的数据可能不完整，建议重新同步。' 'Amber'
      Set-Progress 0 '已取消'
    } else {
      Log ('同步失败：' + $_) 'Red'
      Set-Progress 0 '同步失败'
    }
  } finally {
    Set-Busy $false
  }
}

function Invoke-Rollback {
  try {
    $script:CancelRequested = $false
    Set-Busy $true
    Set-Progress 3 '准备回滚'
    Log '开始从 U 盘回滚到本机' 'Cyan'
    if (-not (Test-Path -LiteralPath $Harness)) { Log 'U 盘上没有便携数据，无法回滚。' 'Red'; return }
    $backup = Join-Path $AppData ('harness-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    if (Test-Path -LiteralPath $HostHarness) {
      Set-Progress 10 '备份本机 DSH_HOME'
      New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
      Copy-Item -LiteralPath $HostHarness -Destination $backup -Recurse -Force -ErrorAction SilentlyContinue
      Log ('本机已备份：' + $backup)
    }
    Set-Progress 35 '复制配置与插件'
    New-Item -ItemType Directory -Path $HostHarness -Force | Out-Null
    $null = Run-Robocopy $Harness $HostHarness @('/XD','sessions','attachments','cache','recovery','logs','media','/XF','desktop-host-sources.patch.yml')
    Log '配置、插件、密钥已恢复'
    Set-Progress 100 '回滚完成，重启 DSH 后生效'
    Log '回滚完成。请完全退出并重新打开 DSH。' 'Green'
    Refresh-State
  } catch {
    if ($script:CancelRequested) { Log '回滚已取消（本机可能处于部分覆盖状态，建议重新回滚）。' 'Amber'; Set-Progress 0 '已取消' }
    else { Log ('回滚失败：' + $_) 'Red'; Set-Progress 0 '回滚失败' }
  } finally { Set-Busy $false }
}

function Invoke-Cleanup {
  try {
    $script:CancelRequested = $false
    Set-Busy $true
    Set-Progress 5 '清理缓存与恢复数据'
    Log '开始清理 U 盘残留' 'Cyan'
    foreach ($d in @('cache','recovery','logs','media','backups')) {
      $p = Join-Path $Harness $d
      if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue; Log ('已清理 ' + $d) }
    }
    $patch = Join-Path $Harness 'desktop-host-sources.patch.yml'
    if (Test-Path -LiteralPath $patch) { Remove-Item -LiteralPath $patch -Force; Log '已清理临时生成文件' }
    $lock = Join-Path $DataDir 'lockfile'
    if (Test-Path -LiteralPath $lock) { Remove-Item -LiteralPath $lock -Force; Log '已清理残留锁文件' }
    Set-Progress 60 '清理旧备份'
    $bkRoot = Join-Path $Root 'backups'
    if (Test-Path -LiteralPath $bkRoot) {
      $items = Get-ChildItem -LiteralPath $bkRoot -Directory | Sort-Object LastWriteTime -Descending
      if ($items.Count -gt 2) {
        $items | Select-Object -Skip 2 | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
        Log '旧备份已清理（保留最近 2 个）'
      }
    }
    Set-Progress 100 '清理完成'
    Log '残留清理完成（缓存 / 日志 / 恢复 / 临时文件 / 旧备份）' 'Green'
    Refresh-State
  } catch {
    Log ('清理失败：' + $_) 'Red'
    Set-Progress 0 '清理失败'
  } finally { Set-Busy $false }
}

function Invoke-Wipe {
  try {
    $script:CancelRequested = $false
    Set-Busy $true
    Set-Progress 5 '删除会话与附件'
    Log '开始清空 U 盘对话' 'Cyan'
    foreach ($d in @('sessions','attachments','recovery','media')) {
      $p = Join-Path $Harness $d
      if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue; Log ('已删除 ' + $d) }
    }
    $cache = Join-Path $Harness 'storages\session_projcache'
    if (Test-Path -LiteralPath $cache) { Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction SilentlyContinue; Log '已删除 session_projcache' }
    Set-Progress 40 '清理界面草稿'
    $storage = Join-Path $Harness 'profiles\web\desktop-storage.json'
    if (Test-Path -LiteralPath $storage) {
      try {
        $json = Get-Content -LiteralPath $storage -Raw -Encoding UTF8 | ConvertFrom-Json
        $removed = 0
        foreach ($prop in @($json.PSObject.Properties)) {
          $k = $prop.Name; $hit = $false
          foreach ($pre in $SESSION_PREFIXES) { if ($k.StartsWith($pre)) { $hit = $true; break } }
          if (-not $hit) { foreach ($sk in $SESSION_KEYS) { if ($k -eq $sk) { $hit = $true; break } } }
          if ($hit) { $json.PSObject.Properties.Remove($k); $removed++ }
        }
        Write-Utf8NoBom $storage ($json | ConvertTo-Json -Depth 100 -Compress)
        Log ('desktop-storage 会话键已清除 ' + $removed + ' 个')
      } catch { Log ('desktop-storage 处理失败：' + $_) 'Amber' }
    }
    Set-Progress 70 '清空工作区索引'
    $ws = Join-Path $Harness 'storages\workspace.json'
    if (Test-Path -LiteralPath $ws) {
      try {
        $w = Get-Content -LiteralPath $ws -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($prop in @($w.PSObject.Properties)) {
          $v = $prop.Value
          if ($v -and $v.PSObject.Properties['sessionIds']) { $v.sessionIds = @() }
        }
        Write-Utf8NoBom $ws ($w | ConvertTo-Json -Depth 100 -Compress)
        Log 'workspace.json 索引已清空'
      } catch { Log ('workspace.json 处理失败：' + $_) 'Amber' }
    }
    Set-Progress 100 '清空对话完成'
    Log 'U 盘对话已清空（插件、配置、密钥保留）' 'Green'
    Refresh-State
  } catch {
    Log ('清空失败：' + $_) 'Red'
    Set-Progress 0 '清空失败'
  } finally { Set-Busy $false }
}

$BackupPath = Join-Path $env:APPDATA 'dsh-desktop.portable-backup'
$MarkerPath = Join-Path $env:APPDATA 'dsh-desktop.portable-takeover.json'

function Write-TakeoverMarker {
  $obj = [ordered]@{ backup = $BackupPath; target = $DataDir; usb = $Root; time = (Get-Date).ToString('o') }
  [System.IO.File]::WriteAllText($MarkerPath, ($obj | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
}
function Clear-TakeoverMarker {
  if (Test-Path -LiteralPath $MarkerPath) { Remove-Item -LiteralPath $MarkerPath -Force -ErrorAction SilentlyContinue }
}
function Read-TakeoverMarker {
  if (-not (Test-Path -LiteralPath $MarkerPath)) { return $null }
  try { return (Get-Content -LiteralPath $MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Restore-HostData([switch]$Force) {
  if (-not (Test-Path -LiteralPath $BackupPath)) { return $false }
  $procs = @(Get-Process -Name 'DSH Desktop' -ErrorAction SilentlyContinue)
  if ($procs.Count -gt 0 -and -not $Force) {
    Log '上次临时切换尚未还原，但 DSH 仍在运行；关闭 DSH 后会自动还原。' 'Amber'
    return $false
  }
  if (Test-Path -LiteralPath $AppData) {
    $isLink = $false
    try { $isLink = [bool]((Get-Item -LiteralPath $AppData -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) } catch { }
    if ($isLink) {
      Remove-Item -LiteralPath $AppData -Force -ErrorAction SilentlyContinue
    } else {
      Log '异常：本机数据目录与备份同时存在，未自动处理。' 'Red'
      return $false
    }
  }
  try {
    Move-Item -LiteralPath $BackupPath -Destination $AppData -Force -ErrorAction Stop
    Clear-TakeoverMarker
    Log '已还原本机数据目录。' 'Green'
    return $true
  } catch {
    Log ('还原本机数据目录失败：' + $_) 'Red'
    return $false
  }
}

function Invoke-Launch {
  try {
    if (-not (Test-Path -LiteralPath $ExePath)) {
      $null = Show-Notice '便携程序未就绪 · 自动降级说明' ("U 盘上还没有便携版程序：`r`n$ExePath`r`n`r`n请先在主电脑上执行「同步到 U 盘」，或把程序复制到该目录。`r`n`r`n如果暂时来不及，可改用 C 方案：在目标机临时下载官方安装包运行，用完卸载。")
      return
    }
    if (Test-Path -LiteralPath $AppData) {
      $isLink = $false
      try {
        $item = Get-Item -LiteralPath $AppData -Force
        $isLink = [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
      } catch { }
            if (-not $isLink) {
        $procs = @(Get-Process -Name 'DSH Desktop' -ErrorAction SilentlyContinue)
        if ($procs.Count -gt 0) {
          $null = Show-Notice '本机 DSH 正在运行 · 无法临时接管' ("这台电脑装有 DSH，而且正在运行：`r`n$AppData`r`n`r`n便携版需要临时接管数据目录，请先完全退出本机 DSH 再试。`r`n`r`n两者不能同时使用同一数据目录。")
          return
        }
        $ok2 = Show-Confirm '本机已安装 DSH · 临时接管数据目录？' ("这台电脑已经安装过 DSH：`r`n$AppData`r`n`r`n便携版会临时把它改名藏起来（→ dsh-desktop.portable-backup），改用 U 盘上的数据目录；`r`n关闭 DSH（或点「关闭 DSH 并清理」）后自动还原。`r`n`r`n期间本机 DSH 不能用，数据不会丢。`r`n`r`n继续吗？")
        if (-not $ok2) { Log '已取消临时接管。' 'Amber'; return }
        try {
          Move-Item -LiteralPath $AppData -Destination $BackupPath -Force -ErrorAction Stop
          Write-TakeoverMarker
          $script:TakeoverHost = $true
          Log '已临时移开本机数据目录（退出时自动还原）。' 'Amber'
        } catch {
          Log ('无法改名本机数据目录（可能被占用）：' + $_) 'Red'
          $null = Show-Notice '临时接管失败' ([string]$_)
          return
        }
      }
    }
    if (-not (Test-Path -LiteralPath $AppData)) {
    # 启动前自愈：校正 profile 插件启用列表（防止 DSH 上次启动改写后残留）
    $ensure = Join-Path $PSScriptRoot 'lib\ensure-profile-plugins.ps1'
    if (Test-Path -LiteralPath $ensure) {
      Set-Progress 20 '校正插件启用列表'
      Log '校正插件启用列表（自愈）…'
      try {
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ensure -Root $Root -Quiet 2>&1
        if ($out) { Log ('自愈：' + ($out -join ' / ')) }
        Log '插件启用列表已校正' 'Green'
      } catch { Log ('自愈失败（继续启动）：' + $_) 'Amber' }
    }
      Set-Progress 30 '创建数据链接'
      Log ('创建数据链接：' + $AppData + ' → ' + $DataDir)
      New-Item -ItemType Junction -Path $AppData -Target $DataDir -Force | Out-Null
      if (-not (Test-Path -LiteralPath $AppData)) { Log '数据链接创建失败' 'Red'; return }
    }
    Set-Progress 70 '启动 DSH'
    Log ('启动：' + $ExePath)
    Start-Process -FilePath $ExePath
    Set-Progress 100 '已启动'
    Log 'DSH 已启动。关闭后请双击「移除便携链接.bat」恢复本机干净状态。' 'Green'
  } catch {
    Log ('启动失败：' + $_) 'Red'
    $null = Show-Notice '启动失败' ([string]$_)
  }
}

# ---------- 启动 / 关闭 状态 ----------
$ProgDir = Join-Path $Root 'program'

$script:ProcPathCache = @{}
function Get-PortableDshProcs {
  $list = @()
  foreach ($p in @(Get-Process -Name 'DSH Desktop' -ErrorAction SilentlyContinue)) {
    $path = $script:ProcPathCache[$p.Id]
    if (-not $path) {
      try { $path = [string]$p.MainModule.FileName } catch { $path = '' }
      $script:ProcPathCache[$p.Id] = $path
    }
    if (-not $path -or $path.StartsWith($ProgDir, [System.StringComparison]::OrdinalIgnoreCase)) { $list += $p }
  }
  foreach ($k in @($script:ProcPathCache.Keys)) { if (-not (Get-Process -Id $k -ErrorAction SilentlyContinue)) { $script:ProcPathCache.Remove($k) } }
  return $list
}

function Update-LaunchButton {
  $running = (@(Get-PortableDshProcs).Count -gt 0)
  if ($running) {
    if ($btnLaunch.Text -ne '■  关闭 DSH 并清理') {
      $btnLaunch.Text = '■  关闭 DSH 并清理'
      $btnLaunch.BackColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
      $btnLaunch.ForeColor = [System.Drawing.Color]::White
    }
  } else {
    if ($btnLaunch.Text -ne '▶  一键启动 DSH') {
      $btnLaunch.Text = '▶  一键启动 DSH'
      $btnLaunch.BackColor = Get-Col Cyan
      $btnLaunch.ForeColor = Get-Col Bg
    }
  }
  return $running
}

function Stop-PortableDshAndCleanup {
  try {
    $script:CancelRequested = $false
    Set-Busy $true
    Set-Progress 10 '正在关闭 DSH'
    Log '正在关闭便携版 DSH…' 'Cyan'
    foreach ($p in @(Get-PortableDshProcs)) { try { $null = $p.CloseMainWindow() } catch { } }
    for ($i = 0; $i -lt 20; $i++) {
      Start-Sleep -Milliseconds 400
      [System.Windows.Forms.Application]::DoEvents()
      if (@(Get-PortableDshProcs).Count -eq 0) { break }
    }
    foreach ($p in @(Get-PortableDshProcs)) { try { $p.Kill() } catch { } }
    Start-Sleep -Milliseconds 800
    if (@(Get-PortableDshProcs).Count -gt 0) { Log 'DSH 进程仍在运行，请手动结束后再试。' 'Amber' }
    else { Log 'DSH 已关闭。' }
    # 先还原（关键）：即使下面清理卡死，主机数据也已经是安全的
    if ($script:TakeoverHost) {
      Set-Progress 40 '还原本机数据目录'
      Log '还原本机数据目录…'
      Restore-HostData -Force | Out-Null
      $script:TakeoverHost = $false
      Log '本机数据目录已还原。' 'Green'
    }
    Set-Progress 60 '清理残留'
    Log '正在清理残留（缓存 / 日志 / 恢复记录 / 临时文件 / 锁文件）…'
    foreach ($d in @('cache', 'recovery', 'logs', 'media')) {
      $p = Join-Path $Harness $d
      if (Test-Path -LiteralPath $p) {
        try { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        [System.Windows.Forms.Application]::DoEvents()
        Log ('已清理 ' + $d)
      }
    }
    $patch = Join-Path $Harness 'desktop-host-sources.patch.yml'
    if (Test-Path -LiteralPath $patch) { Remove-Item -LiteralPath $patch -Force; Log '已清理临时生成文件' }
    $lock = Join-Path $DataDir 'lockfile'
    if (Test-Path -LiteralPath $lock) { Remove-Item -LiteralPath $lock -Force; Log '已清理残留锁文件' }
    Set-Progress 100 '已关闭并清理'
    Log 'DSH 已关闭，残留已清理。可以安全拔出 U 盘。' 'Green'
    Refresh-State
  } catch {
    Log ('关闭或清理失败：' + $_) 'Red'
    Set-Progress 0 '操作失败'
  } finally {
    Set-Busy $false
    Update-LaunchButton | Out-Null
  }
}

# ---------- 事件 ----------
$btnLaunch.Add_Click({
  if ($script:Busy) { return }
  if (@(Get-PortableDshProcs).Count -gt 0) { Stop-PortableDshAndCleanup } else { Invoke-Launch }
  Update-LaunchButton | Out-Null
})
$btnBack.Add_Click({ if (-not $script:Busy) { Show-Home } })

foreach ($b in $opButtons) {
  $b.Add_Click({
    if ($script:Busy) { return }
    $k = $this.Tag
    if ($k -eq 'restore-host') {
      if (-not (Show-Confirm '还原本机数据目录？' ("如果上次临时接管没有正常结束，本机数据目录会停在：`r`n$BackupPath`r`n`r`n这个操作会把它改回来（需要先完全退出 DSH）。`r`n`r`n继续吗？"))) { return }
      if (Restore-HostData -Force) { Log '已还原本机数据目录。' 'Green' } else { Log '没有需要还原的备份（或还原失败）。' 'Amber' }
      Update-LaunchButton | Out-Null
      return
    }    Show-OpPage $k
  })
}

$btnRun.Add_Click({
  if ($script:Busy) { return }
  $key = $script:OpKey
  if ($key -eq 'sync') {
    $selected = @()
    foreach ($item in $pluginList.CheckedItems) {
      $selected += ([string]$item).Split(' ')[0]
    }
    if ($selected.Count -eq 0) {
      $null = Show-Notice '没有勾选插件' '至少要勾选一个插件；核心插件（电脑控制、音频、市场、上下文）建议保留勾选。'
      return
    }
    $script:ActiveLog = $opLog
    Invoke-Sync $selected
  } elseif ($key -eq 'rollback') {
    if (Show-Confirm '确认从 U 盘回滚？' ("将用 U 盘数据覆盖本机 DSH 配置与插件（不会覆盖本机会话）。`r`n`r`n执行前会自动备份本机当前状态；回滚完成后需要重启 DSH 才会生效。")) { Invoke-Rollback }
  } elseif ($key -eq 'cleanup') {
    if (Show-Confirm '确认清理残留？' '将删除 U 盘数据目录里的缓存、日志、恢复记录、临时文件与旧备份（保留最近 2 个）。对话内容不受影响。') { Invoke-Cleanup }
  } elseif ($key -eq 'wipe') {
    if (Show-Confirm '确认清空 U 盘对话？' ("将永久删除 U 盘上的全部会话、附件和界面草稿。`r`n`r`n此操作不可撤销，但不会影响本机 DSH 的对话。")) { Invoke-Wipe }
  }
})

$btnCancel.Add_Click({
  if ($script:Busy) {
    $script:CancelRequested = $true
    $btnCancel.Text = '正在停止…'
    $btnCancel.Enabled = $false
  }
})

$form.Add_FormClosing({
  param($s, $e)
  if ($script:Busy) {
    $e.Cancel = $true
    $script:CancelRequested = $true
    Log '已请求取消，正在停止…' 'Amber'
  }
})

# ---------- 启动 ----------
$form.Add_Shown({
  Show-Home
  Set-Progress 0 '就绪。'
  Update-LaunchButton | Out-Null
  Log '控制台已就绪。' 'Cyan'
  Log ('U 盘：' + $Root + '  ·  本机 DSH：' + $(if ($script:HostInfo.Dir) { $script:HostInfo.Dir } else { '未检测到' }))
})
$uiTimer = New-Object System.Windows.Forms.Timer
$uiTimer.Interval = 2000
$uiTimer.Add_Tick({
  Update-LaunchButton | Out-Null
  if ($script:TakeoverHost) {
    $procs = @(Get-Process -Name 'DSH Desktop' -ErrorAction SilentlyContinue)
    if ($procs.Count -eq 0 -and (Test-Path -LiteralPath $BackupPath)) {
      Restore-HostData -Force | Out-Null
      $script:TakeoverHost = $false
      Log '便携版已退出，本机数据目录已自动还原。' 'Green'
    }
  }
})
$uiTimer.Start()

[void]$form.ShowDialog()
