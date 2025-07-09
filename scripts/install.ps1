#!/usr/bin/env pwsh
# Keep this script simple and easily auditable!
$ErrorActionPreference = 'Stop'

# The main installation logic is wrapped in a function to prevent any output
# from leaking into the pipeline, which is critical when using `... | iex`.
function Install-Typst {
    # --- Configuration ---
    $Owner = if ($env:OWNER -and $env:OWNER.ToLower() -ne 'true') { $env:OWNER } else { 'jassielof/typst-install' }
    $TypstRepo = 'typst/typst'
    $CompletionsDir = 'completions'
    $BaseUrl = 'https://jassielof.github.io/typst-install'

    # --- Argument Parsing ---
    # Access the script's original arguments from within the function
    $Version = if ($script:Args.Length -ge 1) { $script:Args[0] } else { 'latest' }

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
    Write-Host "Downloading Typst v$Version from $URL"
    if (!(Test-Path $BinDir)) {
      # Create the full path in one go
      $null = New-Item $BinDir -ItemType Directory -Force
    }

    $ArchivePath = Join-Path $TypstInstall $File
    Invoke-WebRequest -Uri $URL -OutFile $ArchivePath -UseBasicParsing

    Write-Host "Extracting archive..."
    # Use tar.exe as it's reliable on GitHub runners and avoids potential
    # Expand-Archive output issues. Fallback to Expand-Archive for other systems.
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        tar.exe -xf $ArchivePath -C $TypstInstall
    } else {
        $null = Expand-Archive -Path $ArchivePath -DestinationPath $TypstInstall -Force
    }
    Remove-Item $ArchivePath

    # --- File Organization ---
    $ExtractedFolder = Join-Path $TypstInstall $Folder
    $TypstExeSource = Join-Path $ExtractedFolder 'typst.exe'

    # Assigning to $null is the most reliable way to suppress cmdlet output
    $null = Move-Item -Path $TypstExeSource -Destination $Exe -Force
    $null = Remove-Item $ExtractedFolder -Recurse -Force

    # --- PATH Configuration ---
    Write-Host "Adding Typst to PATH..."
    # For current session
    $env:Path = "$BinDir;$env:Path"

    # For future sessions (User environment variable)
    try {
        $UserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        if (!(";${UserPath};".ToLower().Contains(";$BinDir;".ToLower()))) {
            $NewPath = if ($UserPath) { "${UserPath};$BinDir" } else { $BinDir }
            [System.Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
        }
    } catch {
        Write-Warning "Failed to add Typst to the permanent user PATH. You may need to do it manually."
    }

    # For subsequent GitHub Actions steps
    if ($env:GITHUB_PATH) {
      Add-Content -Path $env:GITHUB_PATH -Value $BinDir
    }

    # --- Shell Completions ---
    Write-Host "Installing PowerShell completions..."
    try {
        $CompletionUrl = "$BaseUrl/$CompletionsDir/typst.ps1"
        $CompletionFile = Join-Path $TypstInstall 'typst-completions.ps1'

        Invoke-WebRequest -Uri $CompletionUrl -OutFile $CompletionFile -UseBasicParsing

        if (!(Test-Path $PROFILE)) {
            $null = New-Item -Path $PROFILE -ItemType File -Force
        }

        $SourceCommand = ". `"$CompletionFile`""
        if (!(Select-String -Path $PROFILE -Pattern ([regex]::Escape($SourceCommand)) -Quiet)) {
            Add-Content -Path $PROFILE -Value "`n# Typst Completions`n$SourceCommand"
            Write-Host "Completions enabled for future sessions. Please restart your shell or run '. `$PROFILE`'."
        } else {
            Write-Host "Completions are already configured."
        }
    } catch {
        Write-Warning "Failed to install PowerShell completions: $_"
    }

    # --- Final Message ---
    Write-Host "Typst was installed successfully to '$Exe'" -ForegroundColor Green
    Write-Host "Run 'typst --help' to get started."
    Write-Host "Stuck? Open an Issue at https://github.com/$Owner/issues"
}

# --- Main Execution ---
# Call the main function to run the installer.
Install-Typst
