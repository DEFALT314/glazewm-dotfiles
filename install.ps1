# install.ps1 - set up the GlazeWM desktop on this machine.
#
# Normally started by bootstrap.ps1. From a checkout:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Installs the apps with winget, copies the configs into place and applies
# the Windows side: themes, wallpaper, cursor, hidden taskbar, autostart.
# Safe to re-run. The first time a config already exists it is moved to
# ~\.glzr\backup\.

param([string]$Root = $PSScriptRoot)

$ErrorActionPreference = 'Stop'
$glzr = Join-Path $HOME '.glzr'
$glazewm = "$env:ProgramFiles\glzr.io\GlazeWM\glazewm.exe"
$flow = "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe"

Add-Type -Namespace Win32 -Name Desktop -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern int SystemParametersInfo(int action, int param, string value, int flags);
'@
$SPIF_UPDATE = 3  # SPIF_UPDATEINIFILE | SPIF_SENDCHANGE

function Step($name) { Write-Host "`n== $name" -ForegroundColor Cyan }

# Backups live outside the folders GlazeWM and Zebar read. Zebar loads
# every ~\.glzr\zebar\*\zpack.json and keys packs by their name, so a
# backup copy next to the bar would replace it.
function Install-Item($src, $dst) {
    if (Test-Path $dst) {
        $backup = "$glzr\backup\$(Split-Path $dst -Leaf)"
        if (Test-Path $backup) { Remove-Item $dst -Recurse -Force }
        else {
            New-Item -ItemType Directory -Force (Split-Path $backup) | Out-Null
            Move-Item $dst $backup
        }
    }
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    Copy-Item $src $dst -Recurse
    Write-Host "  $dst"
}

function Save-Download($url, $dst) {
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $dst
}

Step 'Apps'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store.'
}
foreach ($id in 'glzr-io.glazewm', 'glzr-io.zebar', 'Flow-Launcher.Flow-Launcher', 'DEVCOM.JetBrainsMonoNerdFont') {
    winget install --exact --id $id --silent --accept-package-agreements --accept-source-agreements
    # -1978335189: already installed, no update available.
    if ($LASTEXITCODE -notin 0, -1978335189) { Write-Warning "winget failed for $id ($LASTEXITCODE)" }
}

Step 'GlazeWM + Zebar configs'
# Left by older versions of this script, and loaded by Zebar instead of the
# current bar (see Install-Item).
Remove-Item "$glzr\zebar\mocha-bar.orig" -Recurse -Force -ErrorAction SilentlyContinue
Install-Item "$Root\glazewm\config.yaml" "$glzr\glazewm\config.yaml"
Install-Item "$Root\zebar\mocha-bar" "$glzr\zebar\mocha-bar"
Install-Item "$Root\zebar\settings.json" "$glzr\zebar\settings.json"

Step 'Windows Terminal theme'
# A fragment instead of editing settings.json: Terminal merges it on start.
Install-Item "$Root\terminal\catppuccin-mocha.json" `
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\glazewm-dotfiles\catppuccin-mocha.json"

Step 'Flow Launcher theme'
try {
    Save-Download 'https://raw.githubusercontent.com/catppuccin/flow-launcher/main/themes/Catppuccin%20Mocha.xaml' `
        "$env:APPDATA\FlowLauncher\Themes\Catppuccin Mocha.xaml"
    # Flow writes its settings on exit, so stop it before editing them.
    Get-Process Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force
    $settingsPath = "$env:APPDATA\FlowLauncher\Settings\Settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json
    } else {
        New-Item -ItemType Directory -Force (Split-Path $settingsPath) | Out-Null
        $settings = [pscustomobject]@{}
    }
    $settings | Add-Member -Force -NotePropertyName Theme -NotePropertyValue 'Catppuccin Mocha'
    [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 100))
    if (Test-Path $flow) { Start-Process $flow }
    Write-Host '  Catppuccin Mocha'
} catch {
    Write-Warning "Flow Launcher theme: $_"
}

Step 'Cursor (Bibata Modern Classic)'
try {
    $zip = Join-Path $env:TEMP 'bibata.zip'
    $unpacked = Join-Path $env:TEMP 'bibata'
    $cursors = "$env:LOCALAPPDATA\Microsoft\Windows\Cursors\Bibata-Modern-Classic"
    Save-Download 'https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic-Windows.zip' $zip
    Expand-Archive $zip $unpacked -Force
    New-Item -ItemType Directory -Force $cursors | Out-Null
    Copy-Item "$unpacked\Bibata-Modern-Classic-Regular-Windows\*" $cursors -Force
    Remove-Item $zip, $unpacked -Recurse -Force

    # Same role -> file mapping as the install.inf shipped in the zip.
    $roles = @{
        Arrow = 'Pointer.cur'; Help = 'Help.cur'; AppStarting = 'Work.ani'; Wait = 'Busy.ani'
        Crosshair = 'Cross.cur'; IBeam = 'Text.cur'; NWPen = 'Handwriting.cur'; No = 'Unavailable.cur'
        SizeNS = 'Vert.cur'; SizeWE = 'Horz.cur'; SizeNWSE = 'Dgn1.cur'; SizeNESW = 'Dgn2.cur'
        SizeAll = 'Move.cur'; UpArrow = 'Alternate.cur'; Hand = 'Link.cur'; Pin = 'Pin.cur'; Person = 'Person.cur'
    }
    $key = 'HKCU:\Control Panel\Cursors'
    foreach ($role in $roles.Keys) {
        New-ItemProperty $key -Name $role -Value "$cursors\$($roles[$role])" -PropertyType ExpandString -Force | Out-Null
    }
    Set-Item $key -Value 'Bibata-Modern-Classic'
    [Win32.Desktop]::SystemParametersInfo(0x57, 0, $null, $SPIF_UPDATE) | Out-Null  # SPI_SETCURSORS
    Write-Host "  $cursors"
} catch {
    Write-Warning "Cursor: $_"
}

Step 'Wallpaper'
# Fill = hyprpaper's fit_mode = cover. Company policy may override it.
$wall = "$glzr\wallpaper.png"
Copy-Item "$Root\assets\wallpaper.png" $wall -Force
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'
[Win32.Desktop]::SystemParametersInfo(0x14, 0, $wall, $SPIF_UPDATE) | Out-Null  # SPI_SETDESKWALLPAPER
Write-Host "  $wall"

Step 'Hide the taskbar'
# Byte 8 of StuckRects3: 3 = auto-hide, 2 = always shown. Explorer only
# reads it on start and restarts by itself when killed.
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
$stuckRects = (Get-ItemProperty $key).Settings
if ($stuckRects[8] -ne 3) {
    $stuckRects[8] = 3
    Set-ItemProperty $key -Name Settings -Value $stuckRects
    Stop-Process -Name explorer -Force
}
Write-Host '  auto-hide on'

Step 'Start GlazeWM'
if (Test-Path $glazewm) {
    # Same entry as the tray menu's "Run on system startup".
    Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name GlazeWM -Value "`"$glazewm`""
    # Restart so the new config applies. Zebar too: its installer may have
    # started it with the default bar, and GlazeWM launches it again.
    if (Get-Process glazewm -ErrorAction SilentlyContinue) {
        & "$env:ProgramFiles\glzr.io\GlazeWM\cli\glazewm.exe" command wm-exit
        Start-Sleep -Seconds 2
    }
    Get-Process zebar -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process $glazewm
    Write-Host '  running, starts with Windows'
} else {
    Write-Warning "GlazeWM not found at $glazewm"
}

Write-Host "`nDone. Left to do by hand: see 'Manual' in README.md." -ForegroundColor Green
