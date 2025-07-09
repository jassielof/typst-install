#!/usr/bin/env pwsh
# Keep this script simple and easily auditable!
$ErrorActionPreference = 'Stop'

# --- Version Compatibility ---
$PSMajor = $PSVersionTable.PSVersion.Major
function Is-Pwsh7 { return $PSMajor -ge 7 }

# --- Configuration ---
# You can override these variables, e.g. `OWNER=foo/bar ./install.ps1`
$Owner = if ($env:OWNER -and $env:OWNER.ToLower() -ne 'true') { $env:OWNER } else { 'jassielof/typst-install' }
$TypstRepo = 'typst/typst'
$CompletionsDir = 'completions'
$BaseUrl = 'https://jassielof.github.io/typst-install'

# --- Argument Parsing ---
$Version = if ($Args.Length -ge 1) { $Args[0] } else { 'latest' }

# --- Environment Setup ---
$HomeDir = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$TypstInstall = if ($env:TYPST_INSTALL -and $env:TYPST_INSTALL.ToLower() -ne 'true') { $env:TYPST_INSTALL } else { Join-Path $HomeDir '.typst' }
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
Write-Output "gemini v2"
Write-Output "Downloading Typst from $URL"
if (!(Test-Path $TypstInstall)) {
  # CORRECTED: Assign output to $null
  $null = New-Item $TypstInstall -ItemType Directory -Force
}
if (!(Test-Path $BinDir)) {
  # CORRECTED: Assign output to $null
  $null = New-Item $BinDir -ItemType Directory -Force
}

$ArchivePath = Join-Path $TypstInstall $File
# Using -UseBasicParsing is a good practice for compatibility and performance in scripts.
Invoke-WebRequest -Uri $URL -OutFile $ArchivePath -UseBasicParsing

Write-Output "Extracting archive..."
if (Is-Pwsh7) {
    # CORRECTED: Assign output to $null
    $null = Expand-Archive -Path $ArchivePath -DestinationPath $TypstInstall -Force
} else {
    $ExtractedFolder = Join-Path $TypstInstall $Folder
    if (Test-Path $ExtractedFolder) {
        $null = Remove-Item $ExtractedFolder -Recurse -Force
    }
    # CORRECTED: Assign output to $null
    $null = Expand-Archive -Path $ArchivePath -DestinationPath $TypstInstall
}
Remove-Item $ArchivePath

# --- File Organization ---
$TypstExeSource = Join-Path $TypstInstall $Folder 'typst.exe'
# CORRECTED: This is the most critical fix. Assign Move-Item output to $null
$null = Move-Item -Path $TypstExeSource -Destination $Exe -Force
$null = Remove-Item (Join-Path $TypstInstall $Folder) -Recurse -Force

# --- PATH Configuration ---
Write-Output "Adding Typst to PATH..."
# For current session
$env:Path = "$BinDir;$env:Path"

# For future sessions
$UserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
if (!(";${UserPath};".ToLower().Contains(";$BinDir;".ToLower()))) {
  $NewPath = if ($UserPath) { "${UserPath};$BinDir" } else { $BinDir }
  [System.Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
}

if ($env:GITHUB_PATH) {
  Add-Content -Path $env:GITHUB_PATH -Value $BinDir
}

# --- Shell Completions ---
Write-Output "Installing PowerShell completions..."
try {
    $CompletionUrl = "$BaseUrl/$CompletionsDir/typst.ps1"
    $CompletionFile = Join-Path $TypstInstall 'typst.ps1'

    Write-Output "Downloading completions from $CompletionUrl"
    Invoke-WebRequest -Uri $CompletionUrl -OutFile $CompletionFile -UseBasicParsing

    if (!(Test-Path $PROFILE)) {
        $ProfileDir = Split-Path $PROFILE
        if (!(Test-Path $ProfileDir)) {
            $null = New-Item -Path $ProfileDir -ItemType Directory -Force
        }
        $null = New-Item -Path $PROFILE -ItemType File -Force
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
