# bootstrap.ps1 - install or update with one line in PowerShell:
#   irm https://raw.githubusercontent.com/DEFALT314/glazewm-dotfiles/main/bootstrap.ps1 | iex
#
# Downloads the repo to ~\glazewm-dotfiles (replacing an older copy, no
# git needed) and runs install.ps1 from there.

& {
    $ErrorActionPreference = 'Stop'
    $dest = Join-Path $HOME 'glazewm-dotfiles'
    $zip = Join-Path $env:TEMP 'glazewm-dotfiles.zip'
    $unpacked = Join-Path $env:TEMP 'glazewm-dotfiles-main'

    Invoke-WebRequest -UseBasicParsing -OutFile $zip `
        -Uri 'https://github.com/DEFALT314/glazewm-dotfiles/archive/refs/heads/main.zip'
    Remove-Item $unpacked -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zip $env:TEMP -Force
    # Must not fail silently: Move-Item into a leftover folder would nest the
    # new copy inside it and run the old install.ps1.
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Move-Item $unpacked $dest
    Remove-Item $zip

    # Run as a script block rather than a .ps1 file, so the execution policy
    # (Restricted by default on Windows) doesn't get in the way.
    & ([scriptblock]::Create((Get-Content -Raw (Join-Path $dest 'install.ps1')))) -Root $dest
}
