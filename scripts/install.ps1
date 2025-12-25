#!/usr/bin/env pwsh
# Keep this script simple and easily auditable!
$ErrorActionPreference = 'Stop'

function Install-Typst {
    # --- Configuration ---
    $Owner = if ($env:OWNER -and $env:OWNER.ToLower() -ne 'true') { $env:OWNER } else { 'jassielof/typst-install' }
    $TypstRepo = 'typst/typst'
    $BaseUrl = 'https://jassielof.github.io/typst-install'

    # --- Argument Parsing ---
    $Version = if ($script:Args.Length -ge 1) { $script:Args[0] } else { 'latest' }

    # --- Environment Setup ---
    $HomeDir = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
    $TypstInstall = if ($env:TYPST_INSTALL -and $env:TYPST_INSTALL.ToLower() -ne 'true') {
        $env:TYPST_INSTALL
    } else {
        Join-Path $HomeDir '.typst'
    }
    $BinDir = Join-Path $TypstInstall 'bin'
    $Exe = Join-Path $BinDir 'typst.exe'

    # --- Target Detection ---
    $Target = 'x86_64-pc-windows-msvc'
    $Folder = "typst-${Target}"
    $File = "$Folder.zip"

    # --- URL Construction ---
    $URL = if ($Version -eq 'latest') {
        "https://github.com/${TypstRepo}/releases/latest/download/$File"
    } else {
        "https://github.com/${TypstRepo}/releases/download/v${Version}/$File"
    }

    # --- Installation ---
    # Write-Host "Downloading Typst v$Version from $URL" # this results in vlatest if latest is used so let's resolve to the actual version to
    $Version = if ($Version -eq 'latest') {
        try {
            $LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/${TypstRepo}/releases/latest" -UseBasicParsing
            $LatestRelease.tag_name
        } catch {
            Write-Error "Failed to fetch the latest version information: $_"
            return
        }
    } else {
        $Version
    }
    Write-Host "Downloading Typst $Version from $URL"

    if (!(Test-Path $BinDir)) {
        $null = New-Item $BinDir -ItemType Directory -Force
    }

    $ArchivePath = Join-Path $TypstInstall $File
    Invoke-WebRequest -Uri $URL -OutFile $ArchivePath -UseBasicParsing

    Write-Host "Extracting archive..."
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        tar.exe -xf $ArchivePath -C $TypstInstall
    } else {
        $null = Expand-Archive -Path $ArchivePath -DestinationPath $TypstInstall -Force
    }
    Remove-Item $ArchivePath

    # --- File Organization ---
    $ExtractedFolder = Join-Path $TypstInstall $Folder
    $TypstExeSource = Join-Path $ExtractedFolder 'typst.exe'
    $null = Move-Item -Path $TypstExeSource -Destination $Exe -Force
    $null = Remove-Item $ExtractedFolder -Recurse -Force

    # --- Environment Variables ---
    Write-Host "Setting Typst environment variables..."
    $env:TYPST_INSTALL = $TypstInstall

    try {
        [System.Environment]::SetEnvironmentVariable('TYPST_INSTALL', $TypstInstall, 'User')
    } catch {
        Write-Warning "Failed to set environment variables permanently. You may need to do it manually."
    }

    # --- PATH Configuration ---
    Write-Host "Adding Typst to PATH..."
    $env:Path = "$BinDir;$env:Path"

    try {
        $UserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        if (!(";${UserPath};".ToLower().Contains(";$BinDir;".ToLower()))) {
            $NewPath = if ($UserPath) { "${UserPath};$BinDir" } else { $BinDir }
            [System.Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
        }
    } catch {
        Write-Warning "Failed to add Typst to permanent PATH. You may need to do it manually."
    }

    # For GitHub Actions
    if ($env:GITHUB_PATH) {
        Add-Content -Path $env:GITHUB_PATH -Value $BinDir
    }

    # --- Shell Completions ---
    Write-Host "Installing PowerShell completions..."
    try {
        if (!(Test-Path $PROFILE)) {
            $null = New-Item -Path $PROFILE -ItemType File -Force
        }

        $CompletionCommand = '(& typst completions powershell) | Out-String | Invoke-Expression'
        if (!(Select-String -Path $PROFILE -Pattern ([regex]::Escape($CompletionCommand)) -Quiet)) {
            Add-Content -Path $PROFILE -Value "`n# Typst Completions`n$CompletionCommand"
            Write-Host "Completions will be enabled in new PowerShell sessions."
        } else {
            Write-Host "Completions are already configured."
        }
    } catch {
        Write-Warning "Failed to install PowerShell completions: $_"
    }

    # --- Test Installation ---
    Write-Host ""
    if (Get-Command typst -ErrorAction SilentlyContinue) {
        Write-Host "Installation verified! Running 'typst --version'..." -ForegroundColor Green
        & $Exe --version
    } else {
        Write-Host "Installation complete! Restart your shell to use Typst." -ForegroundColor Green
    }

    # --- Final Message ---
    Write-Host ""
    Write-Host "Typst was installed successfully to '$Exe'" -ForegroundColor Green
    Write-Host "Run 'typst --help' to get started."
    Write-Host "Stuck? Open an Issue at https://github.com/$Owner/issues"
}

# --- Main Execution ---
Install-Typst
