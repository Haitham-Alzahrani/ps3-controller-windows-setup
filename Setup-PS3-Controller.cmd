@echo off
rem =====================================================================
rem  PS3 (DualShock 3) controller setup for 64-bit Windows 10/11. See README.md.
rem =====================================================================
rem  Just double-click this file and click Yes on the admin prompt.
rem    (no switch)    set up, choosing the right route for this PC, then test
rem    /dongle        set up the 8BitDo dongle route
rem    /bluetooth     set up the built-in Bluetooth route
rem    /check         only report on this PC (no admin needed)
rem    /test          only test the controller (no admin needed)
rem    /pair          pair the controller with an 8BitDo dongle
rem    /uninstall     remove the dongle route
rem    /quiet         add after the above: no test and no pause at the end
rem =====================================================================
setlocal
set "PS3_SELF=%~f0"
set "PS3_ARGS=%*"
if /i not "%~1"=="/test" if /i not "%~1"=="/check" (
  net session >nul 2>&1
  if errorlevel 1 (
    echo Asking for administrator rights...
    powershell -NoProfile -Command "$a=@{}; if($env:PS3_ARGS){$a.ArgumentList=$env:PS3_ARGS}; Start-Process -FilePath $env:PS3_SELF -Verb RunAs @a"
    exit /b
  )
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create(((Get-Content -LiteralPath $env:PS3_SELF -Raw) -split '(?m)^#__PS__\r?$',2)[1]))"
set "PS3_RC=%errorlevel%"
echo.%*| find /i "/quiet" >nul || (
  echo.
  pause
)
exit /b %PS3_RC%
#__PS__
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---- downloads, all verified by hash ---------------------------------------
$ViGEmBus = @{
    Folder='vigem'; Name='ViGEmBus_1.22.0_x64_x86_arm64.exe'
    Url='https://github.com/nefarius/ViGEmBus/releases/download/v1.22.0/ViGEmBus_1.22.0_x64_x86_arm64.exe'
    HashType='SHA256'; Hash='89220A7865076B342892F98865F3499FB7C4CFD673159E89D352C360FD014C6A'
}
$ViGEmClient = @{
    Folder='vigem'; Name='nefarius.vigem.client.1.21.256.nupkg'
    Url='https://api.nuget.org/v3-flatcontainer/nefarius.vigem.client/1.21.256/nefarius.vigem.client.1.21.256.nupkg'
    HashType='SHA256'; Hash='FF460031B33E0882CD1166FE2D072D0FE97578480C61ED85DCCFA6C930FDB55E'
}
$PairTool = @{
    Folder='8bitdo'; Name='8BitDo_PS3_Tool_Win_V1.4.zip'
    Url='https://download.8bitdo.com/Tools/Receiver/8BitDo_PS3_Tool_Win_V1.4.zip'
    HashType='SHA256'; Hash='336A0B2DE0F893F837F5C1F091D5EC8AD932829C732933F9962DAC86D66BC6C2'
}
$Dotnet = @{
    Folder='dotnet'; Name='windowsdesktop-runtime-10.0.14-win-x64.exe'
    Url='https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/10.0.14/windowsdesktop-runtime-10.0.14-win-x64.exe'
    HashType='SHA512'; Hash='337dacab1636219147b3fe75e451bf5b1c17bca2c86328266d40c4ad1ff0a1e8391c4746ca7a5b702b65b61e8bfe834566cfc1b548cc10aef90b441357b10b69'
}
$DsHidMini = @{
    Folder='dshidmini'; Name='Nefarius_DsHidMini_Drivers_x64_arm64_v3.27.0.msi'
    Url='https://github.com/nefarius/DsHidMini/releases/download/setup-v3.27.0/Nefarius_DsHidMini_Drivers_x64_arm64_v3.27.0.msi'
    HashType='SHA256'; Hash='8887abd79aad3ba45b22d2d2050ebeaeb6da9eab18ede11c5464149e393f6410'
    Match='DsHidMini'; Version=[version]'3.27.0'
}
$BthPS3 = @{
    Folder='bthps3'; Name='Nefarius_BthPS3_Drivers_x64_arm64_v3.2.1.msi'
    Url='https://github.com/nefarius/BthPS3/releases/download/setup-v3.2.1/Nefarius_BthPS3_Drivers_x64_arm64_v3.2.1.msi'
    HashType='SHA256'; Hash='704dbfc3e7fe961b255ed53aadc21c730cc5c250686eb29fbb6c82c34bfcc1be'
    Match='BthPS3'; Version=[version]'3.2.1'
}

# ---- radios the BthPS3 setup is known to knock offline ----------------------
# BthPS3 setup restarts the radio. These then stop responding ("Device Descriptor Request
# Failed") until the PC is fully powered off, and setup fails with code 1603.
$KnownBadRadios = @{
    'VID_0CF3&PID_3004' = 'Qualcomm Atheros AR3012, seen on an MSI GS60'
}

$Words = @(([string]$env:PS3_ARGS).Trim().ToLower() -split '\s+' | Where-Object { $_ })
$Quiet = $Words -contains '/quiet'
$Mode = @($Words | Where-Object { $_ -ne '/quiet' }) | Select-Object -First 1
$SelfDir = Split-Path -Parent $env:PS3_SELF
$LogFile = "$env:PS3_SELF.log"
$InstalledDir = Join-Path $SelfDir 'installed'
$DownloadDir = Join-Path $SelfDir 'installers'
$DriverInf = Join-Path $SelfDir 'driver\PLAYSTATION(R)3_Controller.inf'
$DriverCat = Join-Path $SelfDir 'driver\PLAYSTATION(R)3_Controller.cat'
$HelperSource = Join-Path $SelfDir 'helper\PS3LinkHelper.cs'
$HelperExe = Join-Path $InstalledDir 'PS3LinkHelper.exe'
$RunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$ResetTask = 'Bluetooth Radio Auto Reset'
$RebootNeeded = $false

function Say([string]$Text, [string]$Color = 'Gray') {
    Write-Host $Text -ForegroundColor $Color
    try { Add-Content -LiteralPath $LogFile -Value ('{0:u}  {1}' -f (Get-Date).ToUniversalTime(), $Text) } catch {}
}

function Say-PowerOff {
    Say '         Turn the PC fully off to bring it back: hold Shift while clicking Shut down,' 'Yellow'
    Say '         wait 30 seconds, then turn it on again.' 'Yellow'
}

# ---- what is on this PC -----------------------------------------------------
function Get-Uninstall([string]$Match) {
    Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match $Match } | Select-Object -First 1
}

function Get-InstalledVersion([string]$Match) {
    $e = Get-Uninstall $Match
    if ($e) { try { [version]$e.DisplayVersion } catch { [version]'0.0.0' } }
}

function Get-Packages {
    $blocks = (pnputil /enum-drivers | Out-String) -split '(?:\r?\n){2,}'
    foreach ($b in $blocks) {
        $pub = [regex]::Match($b, 'Published Name:\s+(\S+)').Groups[1].Value
        if ($pub) { [pscustomobject]@{ Published = $pub; Original = [regex]::Match($b, 'Original Name:\s+(.+)').Groups[1].Value.Trim(); Provider = [regex]::Match($b, 'Provider Name:\s+(.+)').Groups[1].Value.Trim() } }
    }
}

# The dongle's Bluetooth address is its 12-digit USB serial number.
function Get-DongleAddress {
    foreach ($d in @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue)) {
        if ($d.InstanceId -match '^USB\\VID_2DC8&PID_[0-9A-Fa-f]{4}\\([0-9A-Fa-f]{12})$') { return $Matches[1].ToUpper() }
    }
}

function Test-CableIn { [bool](Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'USB\VID_054C&PID_0268\*' }) }

function Get-Radio {
    Get-PnpDevice -PresentOnly -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object {
        $_.InstanceId -match '^(USB|PCI)\\' -and $_.FriendlyName -notmatch 'Enumerator|Profile|Peripheral|RFCOMM|Device \('
    } | Sort-Object { $_.Status -ne 'OK' } | Select-Object -First 1
}

function Get-RadioKnownBad($Radio) {
    if ($Radio) { $k = $KnownBadRadios.Keys | Where-Object { $Radio.InstanceId -like "*$_*" } | Select-Object -First 1; if ($k) { $KnownBadRadios[$k] } }
}

# A taken-over or stuck radio does not show in the Bluetooth class, so look for it on USB.
function Say-MissingRadio {
    $usb = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '^USB\\VID_' })
    $taken = $usb | Where-Object { (Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName 'DEVPKEY_Device_CompatibleIds' -ErrorAction SilentlyContinue).Data -match '^USB\\Class_E0&SubClass_01' } | Select-Object -First 1
    $stuck = $usb | Where-Object { $_.InstanceId -like 'USB\VID_0000*' -and $_.Status -ne 'OK' } | Select-Object -First 1
    if ($taken) {
        $svc = (Get-PnpDeviceProperty -InstanceId $taken.InstanceId -KeyName 'DEVPKEY_Device_Service' -ErrorAction SilentlyContinue).Data
        Say ("  [FAIL] Radio found, but Windows cannot use it: {0} is driven by {1}. ScpToolkit does this." -f $taken.FriendlyName, $svc) 'Red'
    } elseif ($stuck) {
        Say ("  [WARN] No working Bluetooth radio, and a USB device has stopped responding: {0}" -f $stuck.FriendlyName) 'Yellow'
        Say-PowerOff
    } else {
        Say '  [NOTE] No Bluetooth radio found.' 'Yellow'
    }
}

function Choose-Route {
    if ($Mode -eq '/dongle') { return 'dongle' }
    if ($Mode -eq '/bluetooth') { return 'bluetooth' }
    if (Get-DongleAddress) { return 'dongle' }
    if (Get-RadioKnownBad (Get-Radio)) { return 'dongle' }
    'bluetooth'
}

function Check-Requirements {
    Say ''
    Say 'Requirements' 'Cyan'
    $os = Get-CimInstance Win32_OperatingSystem
    Say ("  Windows : {0}, build {1}, {2}" -f $os.Caption, $os.BuildNumber, $os.OSArchitecture)
    $ok = $true
    if (-not [Environment]::Is64BitOperatingSystem) { Say '  [FAIL] 64-bit Windows is required.' 'Red'; $ok = $false }
    if ([Environment]::OSVersion.Version.Build -lt 17763) { Say '  [FAIL] Windows 10 version 1809 or newer is required.' 'Red'; $ok = $false }
    $scp = Get-InstalledVersion 'ScpToolkit'
    if ($scp) { Say "  [FAIL] ScpToolkit $scp is installed. Uninstall it in Windows Settings > Apps first." 'Red'; $ok = $false }
    if (Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'USB\VID_054C&PID_0268\*' -and $_.Class -match 'libusbk' }) {
        Say '  [FAIL] The controller is bound to a libusbK driver, left by ScpToolkit. Delete it in Device Manager.' 'Red'; $ok = $false
    }
    if ($ok) { Say '  [OK] This PC meets the requirements.' 'Green' }
    $ok
}

function Show-Report {
    Say ''
    Say 'This PC' 'Cyan'
    $radio = Get-Radio
    if ($radio) {
        Say ("  Bluetooth radio : {0} [{1}]" -f $radio.FriendlyName, $radio.Status)
        $bad = Get-RadioKnownBad $radio
        if ($bad) { Say ("  [WARN] BthPS3 setup is known to knock this radio offline ({0}). Use the dongle route." -f $bad) 'Yellow' }
    } else { Say-MissingRadio }
    $addr = Get-DongleAddress
    Say ("  8BitDo dongle   : " + $(if ($addr) { "plugged in, address $addr" } else { 'not plugged in' }))
    Say ("  Controller cable: " + $(if (Test-CableIn) { 'plugged in' } else { 'not plugged in' }))
    Say ("  Best route      : " + (Choose-Route)) 'Cyan'
    Say ''
    Say 'Installed' 'Cyan'
    $pkgs = @(Get-Packages)
    Say ("  Minimal USB driver : " + $(if ($pkgs | Where-Object { $_.Provider -eq 'libusb-win32' -and $_.Original -like 'playstation*' }) { 'yes' } else { 'no' }))
    Say ("  Link helper        : " + $(if (Get-Process PS3LinkHelper -ErrorAction SilentlyContinue) { 'running' } elseif (Test-Path -LiteralPath $HelperExe) { 'built, not running' } else { 'no' }))
    Say ("  ViGEmBus           : " + $(if (Get-InstalledVersion 'ViGEm') { Get-InstalledVersion 'ViGEm' } else { 'no' }))
    Say ("  DsHidMini          : " + $(if (Get-InstalledVersion 'DsHidMini') { Get-InstalledVersion 'DsHidMini' } else { 'no' }))
    Say ("  BthPS3             : " + $(if (Get-InstalledVersion 'BthPS3') { Get-InstalledVersion 'BthPS3' } else { 'no' }))
}

# ---- download / install helpers ---------------------------------------------
function Get-Installer($Item) {
    $folder = Join-Path $DownloadDir $Item.Folder
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $path = Join-Path $folder $Item.Name
    if (-not (Test-Path -LiteralPath $path)) {
        Say "  downloading $($Item.Name) ..."
        Invoke-WebRequest -Uri $Item.Url -OutFile $path -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $path -Algorithm $Item.HashType).Hash -ine $Item.Hash) {
        Remove-Item -LiteralPath $path -Force
        throw "$($Item.Name) failed the hash check, so it was deleted. Run this file again."
    }
    $path
}

function Invoke-Msi([string]$Arguments, [string]$Label) {
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $Arguments -Wait -PassThru
    if ($p.ExitCode -in 3010, 1641) { $script:RebootNeeded = $true }
    elseif ($p.ExitCode -notin 0, 1605) { throw "$Label failed with code $($p.ExitCode)." }
}

function Remove-Product([string]$Match) {
    $e = Get-Uninstall $Match
    if (-not $e) { return }
    Say "  removing $($e.DisplayName) ..."
    Invoke-Msi "/x $($e.PSChildName) /qn /norestart" "Removing $($e.DisplayName)"
}

function Remove-ControllerEntries {
    Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'USB\VID_054C&PID_0268\*' } | ForEach-Object {
        $null = pnputil /remove-device $_.InstanceId
    }
}

function Remove-Packages([string]$Pattern) {
    foreach ($p in @(Get-Packages | Where-Object { $_.Original -match $Pattern })) {
        Say "  removing driver package $($p.Original)"
        $null = pnputil /delete-driver $p.Published /uninstall
    }
}

function Wait-CableOut {
    if (-not (Test-CableIn)) { return }
    Say '  >> Unplug the controller''s USB cable to continue. <<' 'Yellow'
    $end = (Get-Date).AddMinutes(10)
    while ((Test-CableIn) -and (Get-Date) -lt $end) { Start-Sleep -Seconds 1 }
    if (Test-CableIn) { throw 'The controller''s cable was not unplugged.' }
}

function Stop-Helper {
    Get-Process PS3LinkHelper -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500
}

# Started through Explorer so the helper runs without admin rights, as it does at sign-in.
function Start-Helper {
    Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$HelperExe`""
    $end = (Get-Date).AddSeconds(15)
    while (-not (Get-Process PS3LinkHelper -ErrorAction SilentlyContinue) -and (Get-Date) -lt $end) { Start-Sleep -Milliseconds 300 }
    [bool](Get-Process PS3LinkHelper -ErrorAction SilentlyContinue)
}

# ---- the dongle route --------------------------------------------------------
function Install-MinimalDriver {
    $sig = Get-AuthenticodeSignature -LiteralPath $DriverCat
    if (-not $sig.SignerCertificate -or $sig.SignerCertificate.Subject -notmatch 'VID_054C&PID_0268 \(libwdi autogenerated\)') { throw 'The driver package has an unexpected signature.' }
    # Same self-made certificate that Zadig would install, so Windows accepts this package.
    foreach ($storeName in 'Root', 'TrustedPublisher') {
        $store = New-Object Security.Cryptography.X509Certificates.X509Store($storeName, 'LocalMachine')
        $store.Open('ReadWrite'); $store.Add($sig.SignerCertificate); $store.Close()
    }
    $out = pnputil /add-driver $DriverInf | Out-String
    if ($LASTEXITCODE -notin 0, 259, 3010) { throw "Adding the USB driver failed with code $LASTEXITCODE. $out" }
    Say '  minimal USB driver added'
}

function Build-Helper([string]$DongleAddress) {
    New-Item -ItemType Directory -Force -Path $InstalledDir | Out-Null
    $client = Join-Path $InstalledDir 'Nefarius.ViGEm.Client.dll'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead((Get-Installer $ViGEmClient))
    try { [IO.Compression.ZipFileExtensions]::ExtractToFile(($zip.Entries | Where-Object { $_.FullName -eq 'lib/netstandard2.0/Nefarius.ViGEm.Client.dll' }), $client, $true) } finally { $zip.Dispose() }
    $fw = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
    if (-not (Test-Path -LiteralPath "$fw\netstandard.dll")) { throw '.NET Framework 4.7.1 or newer is required to build the helper.' }
    $ErrorActionPreference = 'Continue'
    $out = & "$fw\csc.exe" /nologo /target:winexe /platform:x64 /optimize+ "/out:$HelperExe" "/r:$client" "/r:$fw\netstandard.dll" "$HelperSource" 2>&1 | Out-String
    $built = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($built -ne 0) { throw "Building the helper failed: $out" }
    [IO.File]::WriteAllText((Join-Path $InstalledDir 'dongle-address.txt'), $DongleAddress)
    Say '  helper built'
}

# Radios that fail on wake get reset automatically, only while Windows reports them failed.
function Install-ResetTask($Radio) {
    $check = @'
$id = '__RADIO__'
function Get-Code { (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_ProblemCode' -ErrorAction SilentlyContinue).Data }
function Note([string]$Text, [string]$Type = 'INFORMATION') { eventcreate /ID 100 /L APPLICATION /SO 'Bluetooth Radio Auto Reset' /T $Type /D $Text | Out-Null }
Start-Sleep -Seconds 5
foreach ($try in 1..3) {
    $code = Get-Code
    if ($code -notin 10, 43) {
        if ($try -gt 1) { Note "Radio recovered after $($try - 1) reset(s)." }
        exit 0
    }
    Note "Radio has problem code $code. Resetting it, attempt $try." 'WARNING'
    pnputil /restart-device $id | Out-Null
    Start-Sleep -Seconds 15
}
if ((Get-Code) -in 10, 43) { Note 'Radio is still failing after 3 resets. A full power-off may be needed.' 'ERROR'; exit 1 }
Note 'Radio recovered after 3 resets.'
exit 0
'@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($check.Replace('__RADIO__', $Radio.InstanceId)))
    $xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Resets the built-in Bluetooth radio only if Windows reports it has failed (Code 10 or 43). Added by Setup-PS3-Controller.</Description></RegistrationInfo>
  <Triggers>
    <BootTrigger><Enabled>true</Enabled><Delay>PT30S</Delay></BootTrigger>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="System"&gt;&lt;Select Path="System"&gt;*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]&lt;/Select&gt;&lt;Select Path="System"&gt;*[System[Provider[@Name='BTHUSB'] and (EventID=6 or EventID=17)]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals><Principal id="Author"><UserId>S-1-5-18</UserId><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
  </Settings>
  <Actions Context="Author"><Exec><Command>powershell.exe</Command><Arguments>-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encoded</Arguments></Exec></Actions>
</Task>
"@
    Register-ScheduledTask -TaskName $ResetTask -Xml $xml -Force | Out-Null
    Say '  automatic Bluetooth reset added for this radio'
}

function Remove-DongleRoute {
    Stop-Helper
    Remove-ItemProperty -LiteralPath $RunKey -Name 'PS3LinkHelper' -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $ResetTask -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Packages '^playstation\(r\)3_controller\.inf$'
    Remove-ControllerEntries
    Remove-Product 'ViGEm'
    $sig = Get-AuthenticodeSignature -LiteralPath $DriverCat
    if ($sig.SignerCertificate) {
        foreach ($storeName in 'Root', 'TrustedPublisher') {
            $store = New-Object Security.Cryptography.X509Certificates.X509Store($storeName, 'LocalMachine')
            $store.Open('ReadWrite'); $store.Remove($sig.SignerCertificate); $store.Close()
        }
    }
}

function Install-DongleRoute {
    $addr = Get-DongleAddress
    if (-not $addr) { throw 'Plug the 8BitDo dongle in first (do not press its button), then run this file again.' }
    Say ''
    Say 'Step 1 of 3: replace the old USB drivers' 'Cyan'
    Wait-CableOut
    Stop-Helper
    # Their driver sends the "start streaming" command that leaves the dongle stuck, and their updater could bring it back.
    Remove-Product 'DsHidMini'
    Remove-Product 'BthPS3'
    Remove-Packages '^(dshidmini|bthps3|bthps3psm)\.inf$'
    Remove-ControllerEntries
    Install-MinimalDriver
    Say ''
    Say 'Step 2 of 3: install the virtual gamepad driver, for when the dongle is out' 'Cyan'
    if (Get-InstalledVersion 'ViGEm') { Say '  ViGEmBus: already installed' }
    else {
        $p = Start-Process -FilePath (Get-Installer $ViGEmBus) -ArgumentList '/quiet', '/norestart' -Wait -PassThru
        if ($p.ExitCode -in 3010, 1641) { $script:RebootNeeded = $true } elseif ($p.ExitCode -ne 0) { throw "ViGEmBus failed to install, code $($p.ExitCode)." }
        Say '  ViGEmBus: installed'
    }
    Say ''
    Say 'Step 3 of 3: build and start the link helper' 'Cyan'
    Build-Helper $addr
    New-ItemProperty -LiteralPath $RunKey -Name 'PS3LinkHelper' -PropertyType String -Value "`"$HelperExe`"" -Force | Out-Null
    $radio = Get-Radio
    if ($radio -and (Get-RadioKnownBad $radio)) { Install-ResetTask $radio }
    if (Start-Helper) { Say '  helper running, and set to start when you sign in' 'Green' } else { Say '  [WARN] The helper did not start. Check Bitdefender or your antivirus.' 'Yellow' }
    Say ''
    if ($RebootNeeded) { Say '  >> Restart Windows when you can. <<' 'Yellow' }
    Say 'RESULT setup: dongle route ready' 'Green'
    Say '  If this controller has never been paired with this dongle, run this file with /pair once.'
}

function Invoke-Pair {
    if (-not (Get-Uninstall 'ViGEm') -or -not (Test-Path -LiteralPath $HelperExe)) { throw 'Run the dongle setup first.' }
    $zip = Get-Installer $PairTool
    $tool = Join-Path $DownloadDir '8bitdo\tool'
    if (-not (Test-Path -LiteralPath $tool)) { Expand-Archive -LiteralPath $zip -DestinationPath $tool }
    $exe = Get-ChildItem -LiteralPath $tool -Recurse -Filter '*Tools_for_PS3_Controller.exe' | Select-Object -First 1
    Stop-Helper
    Say ''
    Say 'Pair the controller with the dongle' 'Cyan'
    Say '  1. Unplug the dongle.' 'Yellow'
    Say '  2. Hold the dongle''s button, plug it in, keep holding for 3 seconds, then let go.' 'Yellow'
    Say '  3. Plug the controller in with its cable.' 'Yellow'
    Say '  4. In the red window, click Pair. When it says Paired OK, click OK and close it.' 'Yellow'
    Say '  The program is unsigned. If Windows warns you: More info, then Run anyway.'
    Start-Process -FilePath $exe.FullName -Wait
    $null = Start-Helper
    Say ''
    Say 'Now unplug the dongle and plug it back in without pressing its button, unplug the cable, and press PS.' 'Cyan'
}

# ---- the built-in Bluetooth route --------------------------------------------
function Install-Runtime {
    $folder = Join-Path $env:ProgramFiles 'dotnet\shared\Microsoft.WindowsDesktop.App'
    if ((Test-Path -LiteralPath $folder) -and (Get-ChildItem -LiteralPath $folder -Directory | Where-Object { $_.Name -like '10.*' })) {
        Say '  .NET 10 Desktop Runtime: already installed'; return
    }
    Say '  installing .NET 10 Desktop Runtime ...'
    $p = Start-Process -FilePath (Get-Installer $Dotnet) -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
    if ($p.ExitCode -in 3010, 1641) { $script:RebootNeeded = $true }
    elseif ($p.ExitCode -notin 0, 1638) { throw ".NET runtime installer failed with code $($p.ExitCode)." }
}

function Install-Msi($Item, [string]$Label) {
    $have = Get-InstalledVersion $Item.Match
    if ($have -and $have -ge $Item.Version) { Say "  ${Label}: version $have already installed"; return }
    Say "  installing $Label ..."
    $log = Join-Path $env:TEMP ('PS3-' + $Item.Match + '-install.log')
    Invoke-Msi ('/i "{0}" /qn /norestart /L*v "{1}"' -f (Get-Installer $Item), $log) "$Label (details: $log)"
}

# Auto pairing writes this PC's Bluetooth address into the controller whenever it is plugged in by USB.
function Set-DriverConfig {
    $folder = Join-Path $env:ProgramData 'DsHidMini'
    $file = Join-Path $folder 'DsHidMini.json'
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $config = $null
    if (Test-Path -LiteralPath $file) {
        try { $config = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json } catch { Copy-Item $file "$file.bak" -Force }
    }
    if (-not $config) { $config = [pscustomobject]@{ IPCEnabled = $true } }
    if (-not $config.Global) { $config | Add-Member -Force -NotePropertyName Global -NotePropertyValue ([pscustomobject]@{}) }
    $config.Global | Add-Member -Force -NotePropertyName HidDeviceMode -NotePropertyValue 'XInput'
    $config.Global | Add-Member -Force -NotePropertyName DevicePairingMode -NotePropertyValue 'Auto'
    $config.Global.PSObject.Properties.Remove('CustomPairingAddress')
    # The driver's JSON parser needs UTF-8 without a byte order mark.
    [IO.File]::WriteAllText($file, ($config | ConvertTo-Json -Depth 32), (New-Object Text.UTF8Encoding($false)))
    Say '  DsHidMini set to XInput + Auto pairing'
}

function Install-BluetoothRoute {
    Say ''
    Say 'Step 1 of 2: install and configure the USB driver' 'Cyan'
    Wait-CableOut
    if ((Get-Uninstall 'ViGEm') -or (Get-Process PS3LinkHelper -ErrorAction SilentlyContinue)) { Say '  removing the dongle route first ...'; Remove-DongleRoute }
    Install-Runtime
    Install-Msi $DsHidMini 'DsHidMini'
    Set-DriverConfig
    Say ''
    Say 'Step 2 of 2: install the wireless driver' 'Cyan'
    $radio = Get-Radio
    if (-not $radio) { Say-MissingRadio; Say 'RESULT setup: USB ready, wireless driver NOT installed' 'Yellow'; return 2 }
    $bad = Get-RadioKnownBad $radio
    if ($bad) {
        Say ("  skipped: its setup would knock this radio offline ({0}). Use the dongle route." -f $bad) 'Yellow'
        Say 'RESULT setup: USB ready, wireless driver NOT installed' 'Yellow'
        return 2
    }
    try { Install-Msi $BthPS3 'BthPS3' }
    catch {
        Say "  [FAIL] $($_.Exception.Message)" 'Red'
        if (-not (Get-PnpDevice -PresentOnly -InstanceId $radio.InstanceId -ErrorAction SilentlyContinue)) { Say '  [WARN] The Bluetooth radio stopped responding during that setup.' 'Yellow'; Say-PowerOff }
        Say 'RESULT setup: USB ready, wireless driver NOT installed' 'Yellow'
        return 2
    }
    if ($RebootNeeded) { Say '  >> Restart Windows, then use the pairing steps below. <<' 'Yellow' }
    Say 'RESULT setup: drivers installed and configured' 'Green'
    Say '  USB      : plug in the cable and press PS.'
    Say '  WIRELESS : plug in the cable once, wait 5 seconds, unplug it, press PS.'
    0
}

# ---- test --------------------------------------------------------------------
function Test-Controller {
    Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class XInputProbe {
    [StructLayout(LayoutKind.Sequential)]
    struct State { public uint Packet; public ushort Buttons; public byte LT; public byte RT; public short LX; public short LY; public short RX; public short RY; }
    [DllImport("xinput1_4.dll")] static extern int XInputGetState(int user, out State state);
    public static int Buttons() { int all = 0; for (int i = 0; i < 4; i++) { State s; if (XInputGetState(i, out s) == 0) all |= s.Buttons; } return all; }
}
'@
    Say ''
    Say 'Test' 'Cyan'
    Say '  Press X on the controller. If it is off, press PS first. No rush: this waits 5 minutes.' 'Yellow'
    $end = (Get-Date).AddMinutes(5)
    $released = $false
    while ((Get-Date) -lt $end) {
        if ([XInputProbe]::Buttons() -eq 0) { $released = $true }
        elseif ($released) {
            $route = if (-not (Get-DongleAddress) -and (Test-CableIn)) { 'over the cable' } elseif (Get-DongleAddress) { 'through the dongle' } else { 'over Bluetooth' }
            Say "  RESULT: WORKING, $route" 'Green'
            return
        }
        Start-Sleep -Milliseconds 30
    }
    Say '  RESULT: no press seen. See Troubleshooting in README.md.' 'Yellow'
}

# =========================== main ============================================
try {
    if ($Mode -eq '/test') { Test-Controller; exit 0 }
    Say '=== PS3 controller setup ===' 'Cyan'
    $ok = Check-Requirements
    Show-Report
    if ($Mode -eq '/check') { Say ''; Say 'Check complete (nothing changed).' 'Cyan'; exit ([int](-not $ok)) }
    if ($Mode -eq '/uninstall') { Say ''; Remove-DongleRoute; Say 'RESULT: dongle route removed' 'Green'; exit 0 }
    if ($Mode -eq '/pair') { Invoke-Pair; exit 0 }
    if (-not $ok) { throw 'Fix the items marked FAIL above, then run this file again.' }
    $code = 0
    if ((Choose-Route) -eq 'dongle') { Install-DongleRoute } else { $code = Install-BluetoothRoute }
    if (-not $Quiet) { Test-Controller }
    exit $code
}
catch {
    Say ''
    Say "RESULT setup: FAILED - $($_.Exception.Message)" 'Red'
    exit 1
}
