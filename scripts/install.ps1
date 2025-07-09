#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

# We wrap the entire logic in a function to prevent any output from leaking
# into the pipeline that Invoke-Expression is consuming.
function Install-Typst {
    # --- Configuration ---
    $Owner = if ($env:OWNER -and $env:OWNER.ToLower() -ne 'true') { $env:OWNER } else { 'jassielof/typst-install' }
    $TypstRepo = 'typst/typst'
    $CompletionsDir = 'completions'
    $BaseUrl = 'https://jassielof.github.io/typst-install'

    # --- Argument Parsing ---
    # In a function, arguments are accessed via the param block or $args.
    # $script:Args is used to access the script's original arguments.
    $Version = if ($script:Args.Length -ge 1) { $script:Args[0] } else { 'latest' }

    # --- Environment Setup ---
    $HomeDir = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
    $TypstInstall = if ($env:TYPST_INSTALL -and $env:TYPST_INSTALL.ToLower() -ne 'true') { $env:TYPST_INSTALL } else { Join-Path $HomeDir '.typst' }
    $BinDir = Join-Path $TypstInstall 'bin'
    $Exe = Join-Path $BinDir 'typst.exe'
    Write-Host "Installation path will be: $TypstInstall"

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
    Write-Host "Downloading Typst from $URL"
    if (!(Test-Path $TypstInstall)) {
      $null = New-Item $TypstInstall -ItemType Directory -Force
    }
    if (!(Test-Path $BinDir)) {
      $null = New-Item $BinDir -ItemType Directory -Force
    }

    $ArchivePath = Join-Path $TypstInstall $File
    # Using -UseBasicParsing is a robust choice for scripting.
    Invoke-WebRequest -Uri $URL -OutFile $ArchivePath -UseBasicParsing

    Write-Host "Extracting archive to $TypstInstall"
    # Using the compatibility of the initial script by checking for tar.exe.
    # GitHub runners have tar, so this is reliable.
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        tar.exe -xf $ArchivePath -C $TypstInstall
    } else {
        # Fallback for local machines that may not have tar
        Expand-Archive -Path $ArchivePath -DestinationPath $TypstInstall -Force
    }

    # Debug: Check if folder exists after extraction
    $ExtractedFolder = Join-Path $TypstInstall $Folder
    Write-Host "Checking for extracted folder: $ExtractedFolder. Exists: $(Test-Path $ExtractedFolder)"

    Remove-Item $ArchivePath

    # --- File Organization ---
    $TypstExeSource = Join-Path $ExtractedFolder 'typst.exe'
    Write-Host "Moving '$TypstExeSource' to '$Exe'"
    # Assigning to $null is the safest way to suppress output from this cmdlet.
    $null = Move-Item -Path $TypstExeSource -Destination $Exe -Force
    Write-Host "Removing temporary extracted folder..."
    $null = Remove-Item $ExtractedFolder -Recurse -Force

    # --- PATH Configuration ---
    Write-Host "Adding Typst to PATH..."
    # For current session, critical for subsequent steps in CI
    $env:Path = "$BinDir;$env:Path"

    # For future sessions
    $UserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if (!(";${UserPath};".ToLower().Contains(";$BinDir;".ToLower()))) {
      $NewPath = if ($UserPath) { "${UserPath};$BinDir" } else { $BinDir }
      [System.Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
      Write-Host "Permanently added to user PATH."
    }

    # For subsequent GitHub Actions steps
    if ($env:GITHUB_PATH) {
      Add-Content -Path $env:GITHUB_PATH -Value $BinDir
      Write-Host "Added to GITHUB_PATH for subsequent steps."
    }

    # --- Shell Completions ---
    Write-Host "Installing PowerShell completions..."
    # Wrap in try/catch to prevent a completions failure from stopping the whole script.
    try {
        $CompletionUrl = "$BaseUrl/$CompletionsDir/typst.ps1"
        $CompletionFile = Join-Path $TypstInstall 'typst.ps1'

        Write-Host "Downloading completions from $CompletionUrl"
        Invoke-WebRequest -Uri $CompletionUrl -OutFile $CompletionFile -UseBasicParsing

        if (!(Test-Path $PROFILE)) {
            Write-Host "Creating profile file: $PROFILE"
            $null = New-Item -Path $PROFILE -ItemType File -Force
        }

        $SourceCommand = ". `"$CompletionFile`""
        if (!(Select-String -Path $PROFILE -Pattern ([regex]::Escape($SourceCommand)) -Quiet)) {
            Add-Content -Path $PROFILE -Value "`n# Typst Completions`n$SourceCommand"
            Write-Host "Completions installed. Restart your shell or run '. `$PROFILE`' to enable them."
        } else {
            Write-Host "Completions are already installed."
        }
    } catch {
        # Using Write-Warning, which also goes to the host, not the success pipeline.
        Write-Warning "Failed to install PowerShell completions: $_"
    }

    # --- Final Message ---
    Write-Host "--------------------------------------------------" -ForegroundColor Green
    Write-Host "Typst was installed successfully to $Exe" -ForegroundColor Green
    Write-Host "Run 'typst --help' to get started."
    Write-Host "Stuck? Open an Issue at https://github.com/$Owner/issues"
    Write-Host "--------------------------------------------------" -ForegroundColor Green
}

# --- Main Execution ---
# By calling the function as the last step, we ensure all logic is contained
# and no intermediate output pollutes the pipeline for `iex`.
Install-Typst
