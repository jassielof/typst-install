#!/usr/bin/env pwsh
# Keep this script simple and easily auditable!
$ErrorActionPreference = 'Stop'

# --- Configuration ---
# You can override these variables, e.g. `OWNER=foo/bar ./install.ps1`
$Owner = if ($env:OWNER -and $env:OWNER.ToLower() -ne 'true') { $env:OWNER } else { 'jassielof/typst-install' }
$TypstRepo = 'typst/typst'
$CompletionsDir = 'completions'

# --- Argument Parsing ---
$Version = if ($Args.Length -ge 1) { $Args[0] } else { 'latest' }

# --- Environment Setup ---
$TypstInstall = if ($env:TYPST_INSTALL -and $env:TYPST_INSTALL.ToLower() -ne 'true') { $env:TYPST_INSTALL } else { (Join-Path $HOME '.typst') }
$BinDir = Join-Path $TypstInstall 'bin'
$Exe = Join-Path $BinDir 'typst.exe'

# --- Target Detection ---
# Currently, only x86_64-pc-windows-msvc is supported for Windows.
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
Write-Output "Downloading Typst from $URL"
if (!(Test-Path $TypstInstall)) {
  New-Item $TypstInstall -ItemType Directory -Force | Out-Null
}
if (!(Test-Path $BinDir)) {
  New-Item $BinDir -ItemType Directory -Force | Out-Null
}

$ArchivePath = Join-Path $TypstInstall $File
Invoke-WebRequest -Uri $URL -OutFile $ArchivePath

Write-Output "Extracting archive..."
Expand-Archive -Path $ArchivePath -DestinationPath $TypstInstall -Force
Remove-Item $ArchivePath

# --- File Organization ---
Move-Item -Path (Join-Path $TypstInstall $Folder 'typst.exe') -Destination $Exe -Force
# Clean up the now-empty extracted folder
Remove-Item (Join-Path $TypstInstall $Folder) -Recurse

# --- PATH Configuration ---
Write-Output "Adding Typst to PATH..."
# For current session
$env:Path = "$BinDir;$env:Path"

# For future sessions (User environment variable)
$UserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
if (!(";${UserPath};".ToLower().Contains(";$BinDir;".ToLower()))) {
  $NewPath = if ($UserPath) { "${UserPath};$BinDir" } else { $BinDir }
  [System.Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
}

# For GitHub Actions
if ($env:GITHUB_PATH) {
  Add-Content -Path $env:GITHUB_PATH -Value $BinDir
}

# --- Shell Completions ---
Write-Output "Installing PowerShell completions..."
try {
    $CompletionUrl = "https://raw.githubusercontent.com/$Owner/main/$CompletionsDir/typst.ps1"
    $CompletionFile = Join-Path $TypstInstall 'typst.ps1'

    Write-Output "Downloading completions from $CompletionUrl"
    Invoke-WebRequest -Uri $CompletionUrl -OutFile $CompletionFile

    if (!(Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    }

    $SourceCommand = ". `"$CompletionFile`""
    if (!(Select-String -Path $PROFILE -Pattern ([regex]::Escape($SourceCommand)) -Quiet)) {
        Add-Content -Path $PROFILE -Value "`n# Typst Completions`n$SourceCommand"
        Write-Output "Completions installed. Please restart your shell or run '. `$PROFILE`' to enable them."
    } else {
        Write-Output "Completions are already installed."
    }
} catch {
    Write-Warning "Failed to install PowerShell completions: $_"
}


# --- Final Message ---
Write-Output "Typst was installed successfully to $Exe"
Write-Output "Run 'typst --help' to get started."
Write-Output "Stuck? Open an Issue at https://github.com/$Owner/issues"
