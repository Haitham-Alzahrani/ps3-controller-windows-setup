# =============================================================================
#  PS3 Controller Setup - friendly bilingual (English / Arabic) window.
#
#  WHAT IS NEW vs WHAT IS PROVEN:
#    - The driver / cert / pairing work is done ENTIRELY by the proven
#      Setup-PS3-Controller.cmd, UNCHANGED. This window only shows friendly
#      text and a button, then launches that proven .cmd the SAME way the
#      .cmd elevates itself (Start-Process -Verb RunAs).
#    - This window is the only new code. It has not yet been run on Windows;
#      its first launch confirms the window works. If it ever misbehaves, the
#      proven Setup-PS3-Controller.cmd can still be run directly.
#
#  Success/failure is read from the engine's EXIT CODE (0 = success).
# =============================================================================

$ErrorActionPreference = 'Stop'

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
}

# ---- paths -------------------------------------------------------------------
$GuiDir = $PSScriptRoot
if (-not $GuiDir) { $GuiDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$Root      = Split-Path -Parent $GuiDir
$Engine    = Join-Path $Root 'Setup-PS3-Controller.cmd'
$EngineLog = "$Engine.log"
$GuiLog    = Join-Path $GuiDir 'gui.log'

function Write-GuiLog([string]$m) {
    try { Add-Content -LiteralPath $GuiLog -Value ('{0:u}  {1}' -f (Get-Date).ToUniversalTime(), $m) -Encoding UTF8 } catch {}
}

# ---- language ----------------------------------------------------------------
$script:Langs = @{}
foreach ($code in 'en','ar') {
    try {
        $p = Join-Path $GuiDir ("lang\{0}.json" -f $code)
        $script:Langs[$code] = (Get-Content -LiteralPath $p -Raw -Encoding UTF8) | ConvertFrom-Json
    } catch { Write-GuiLog "Could not load language '$code': $_" }
}
if ($script:Langs.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Language files are missing (gui\lang\en.json / ar.json).", "PS3 Controller Setup") | Out-Null
    return
}

# default language from Windows, falling back to English then whatever loaded
$script:Current = 'en'
try { if ((Get-UICulture).Name -like 'ar*') { $script:Current = 'ar' } } catch {}
if (-not $script:Langs[$script:Current]) { $script:Current = ($script:Langs.Keys | Select-Object -First 1) }
function T { param($key) $t = $script:Langs[$script:Current]; if ($t.PSObject.Properties[$key]) { $t.$key } else { $key } }

# ---- colors / fonts ----------------------------------------------------------
$Green = [System.Drawing.Color]::FromArgb(0, 130, 0)
$Red   = [System.Drawing.Color]::FromArgb(176, 0, 0)
$Gray  = [System.Drawing.Color]::FromArgb(110, 110, 110)
$fontHeading = New-Object System.Drawing.Font('Segoe UI', 17, [System.Drawing.FontStyle]::Bold)
$fontBtnBig  = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
$fontNormal  = New-Object System.Drawing.Font('Segoe UI', 10)
$fontStatus  = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$fontSmall   = New-Object System.Drawing.Font('Segoe UI', 9)

# ---- form --------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.ClientSize    = New-Object System.Drawing.Size(470, 350)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.BackColor = [System.Drawing.Color]::White

$lnkLang = New-Object System.Windows.Forms.LinkLabel
$lnkLang.AutoSize = $true
$lnkLang.Location = New-Object System.Drawing.Point(380, 12)
$lnkLang.Font = $fontSmall
$form.Controls.Add($lnkLang)

$lblHeading = New-Object System.Windows.Forms.Label
$lblHeading.Location = New-Object System.Drawing.Point(10, 46)
$lblHeading.Size = New-Object System.Drawing.Size(450, 40)
$lblHeading.TextAlign = 'MiddleCenter'
$lblHeading.Font = $fontHeading
$form.Controls.Add($lblHeading)

$lblIntro = New-Object System.Windows.Forms.Label
$lblIntro.Location = New-Object System.Drawing.Point(25, 90)
$lblIntro.Size = New-Object System.Drawing.Size(420, 45)
$lblIntro.TextAlign = 'MiddleCenter'
$lblIntro.Font = $fontNormal
$form.Controls.Add($lblIntro)

$btnSetup = New-Object System.Windows.Forms.Button
$btnSetup.Location = New-Object System.Drawing.Point(115, 148)
$btnSetup.Size = New-Object System.Drawing.Size(240, 56)
$btnSetup.Font = $fontBtnBig
$btnSetup.BackColor = [System.Drawing.Color]::FromArgb(230, 240, 255)
$form.Controls.Add($btnSetup)

$lblUac = New-Object System.Windows.Forms.Label
$lblUac.Location = New-Object System.Drawing.Point(25, 212)
$lblUac.Size = New-Object System.Drawing.Size(420, 20)
$lblUac.TextAlign = 'MiddleCenter'
$lblUac.ForeColor = $Gray
$lblUac.Font = $fontSmall
$form.Controls.Add($lblUac)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(115, 238)
$progress.Size = New-Object System.Drawing.Size(240, 16)
$progress.Style = 'Marquee'
$progress.MarqueeAnimationSpeed = 30
$progress.Visible = $false
$form.Controls.Add($progress)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(25, 262)
$lblStatus.Size = New-Object System.Drawing.Size(420, 50)
$lblStatus.TextAlign = 'MiddleCenter'
$lblStatus.Font = $fontStatus
$lblStatus.Visible = $false
$form.Controls.Add($lblStatus)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Location = New-Object System.Drawing.Point(20, 316)
$btnRemove.Size = New-Object System.Drawing.Size(110, 26)
$btnRemove.Font = $fontSmall
$form.Controls.Add($btnRemove)

$btnHelp = New-Object System.Windows.Forms.Button
$btnHelp.Location = New-Object System.Drawing.Point(340, 316)
$btnHelp.Size = New-Object System.Drawing.Size(110, 26)
$btnHelp.Font = $fontSmall
$btnHelp.Visible = $false
$form.Controls.Add($btnHelp)

# ---- language application + RTL ---------------------------------------------
function Apply-Language {
    $rtl = ($script:Current -eq 'ar')
    $form.RightToLeft = if ($rtl) { 'Yes' } else { 'No' }
    $form.RightToLeftLayout = $rtl
    $form.Text        = (T 'appTitle')
    $lblHeading.Text  = (T 'heading')
    $lblIntro.Text    = (T 'intro')
    $btnSetup.Text    = (T 'btnSetup')
    $lblUac.Text      = (T 'uacHint')
    $btnRemove.Text   = (T 'btnRemove')
    $btnHelp.Text     = (T 'btnHelp')
    $other = if ($script:Current -eq 'en') { 'ar' } else { 'en' }
    if ($script:Langs[$other]) { $lnkLang.Text = $script:Langs[$other].langName }
}

$lnkLang.Add_LinkClicked({
    $script:Current = if ($script:Current -eq 'en') { 'ar' } else { 'en' }
    if (-not $script:Langs[$script:Current]) { $script:Current = ($script:Langs.Keys | Select-Object -First 1) }
    Apply-Language
})

# ---- run the proven engine ---------------------------------------------------
$script:proc = $null
$script:mode = $null

function Set-Busy([bool]$busy) {
    $btnSetup.Enabled  = -not $busy
    $btnRemove.Enabled = -not $busy
    $lnkLang.Enabled   = -not $busy
    $progress.Visible  = $busy
    $lblUac.Visible    = $busy
}

function Start-Engine([string[]]$engineArgs, [string]$mode, [string]$busyText) {
    if (-not (Test-Path -LiteralPath $Engine)) {
        $lblStatus.Text = (T 'engineMissing'); $lblStatus.ForeColor = $Red; $lblStatus.Visible = $true
        Write-GuiLog "Engine not found at $Engine"
        return
    }
    $btnHelp.Visible = $false
    $script:mode = $mode
    Set-Busy $true
    $lblStatus.Text = $busyText; $lblStatus.ForeColor = [System.Drawing.Color]::Black; $lblStatus.Visible = $true
    [System.Windows.Forms.Application]::DoEvents()
    try {
        # Same elevation the proven .cmd uses on itself (line 22): Start-Process -Verb RunAs.
        $script:proc = Start-Process -FilePath $Engine -ArgumentList $engineArgs -Verb RunAs -WindowStyle Hidden -PassThru
        Write-GuiLog "Launched engine ($mode) args=[$($engineArgs -join ' ')] pid=$($script:proc.Id)"
        $timer.Start()
    } catch {
        # Most common: user clicked No on the Windows (UAC) prompt.
        Write-GuiLog "Launch cancelled/failed ($mode): $_"
        Set-Busy $false
        $lblStatus.Text = (T 'uacCancelled'); $lblStatus.ForeColor = $Red; $lblStatus.Visible = $true
        $script:proc = $null
    }
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    if (-not $script:proc) { $timer.Stop(); return }
    if (-not $script:proc.HasExited) { return }
    $timer.Stop()
    $code = -1
    try { $code = $script:proc.ExitCode } catch {}
    $m = $script:mode
    $script:proc = $null
    Set-Busy $false
    Write-GuiLog "Engine ($m) finished with exit code $code"
    if ($code -eq 0) {
        $lblStatus.ForeColor = $Green
        if ($m -eq 'remove') { $lblStatus.Text = (T 'removeDone') }
        else { $lblStatus.Text = (T 'doneTitle') + "`r`n" + (T 'doneMsg') }
    } else {
        $lblStatus.ForeColor = $Red
        $lblStatus.Text = (T 'failTitle') + "`r`n" + (T 'failMsg')
        $btnHelp.Visible = $true
    }
    $lblStatus.Visible = $true
})

$btnSetup.Add_Click({ Start-Engine @('/quiet') 'setup' (T 'working') })

$btnRemove.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        (T 'removeConfirm'), (T 'appTitle'),
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-Engine @('/uninstall','/quiet') 'remove' (T 'removing')
    }
})

$btnHelp.Add_Click({
    $log = if (Test-Path -LiteralPath $EngineLog) { $EngineLog } elseif (Test-Path -LiteralPath $GuiLog) { $GuiLog } else { $null }
    if ($log) { Start-Process notepad.exe -ArgumentList $log } else {
        [System.Windows.Forms.MessageBox]::Show("No log file yet.", (T 'appTitle')) | Out-Null
    }
})

# ---- go ----------------------------------------------------------------------
Apply-Language
Write-GuiLog "GUI started. Engine=$Engine Exists=$([bool](Test-Path -LiteralPath $Engine)) Lang=$script:Current"
[void]$form.ShowDialog()
