# PowerShell completion for typst

$scriptBlock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = $commandElements[1]

    # --- Data ---
    $commands = @{
        'compile' = 'Compiles an input file'
        'c'       = 'Alias for compile'
        'watch'   = 'Watches an input file for changes'
        'w'       = 'Alias for watch'
        'init'    = 'Initializes a new project'
        'query'   = 'Extracts metadata from a file'
        'fonts'   = 'Lists all discovered fonts'
        'update'  = 'Self-updates the Typst CLI'
        'help'    = 'Prints help information'
    }

    $globalOptions = '--help', '-h', '--version', '-V', '--color', '--cert'
    $compileWatchQueryOpts = '--root', '--input', '--font-path', '--ignore-system-fonts', '--package-path', '--package-cache-path', '--creation-timestamp', '--jobs', '-j', '--features', '--diagnostic-format'
    $compileWatchOpts = '--format', '-f', '--pages', '--pdf-standard', '--ppi', '--make-deps', '--open', '--timings'
    $watchOpts = '--no-serve', '--no-reload', '--port'
    $initOpts = '--package-path', '--package-cache-path'

    # --- Logic ---

    # Complete main command
    if ($commandElements.Count -eq 1) {
        return $commands.GetEnumerator() | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterName', $_.Value)
        }
    }

    # Get last token
    $lastToken = $commandElements[-1]
    if ($cursorPosition -gt $lastToken.Extent.StartOffset) {
        $lastWord = $lastToken.Value
    } else {
        $lastWord = ""
    }

    # Complete option arguments
    $prevToken = if ($commandElements.Count -gt 2) { $commandElements[-2].Value } else { '' }
    switch ($prevToken) {
        '--color' { return 'auto', 'always', 'never' | Where-Object { $_ -like "$wordToComplete*" } }
        '--format' { return 'pdf', 'png', 'svg', 'html' | Where-Object { $_ -like "$wordToComplete*" } }
        '--pdf-standard' { return '1.7', 'a-2b', 'a-3b' | Where-Object { $_ -like "$wordToComplete*" } }
        '--diagnostic-format' { return 'human', 'short' | Where-Object { $_ -like "$wordToComplete*" } }
        '--features' { return 'html' | Where-Object { $_ -like "$wordToComplete*" } }
    }

    # Complete options or file paths
    if ($wordToComplete.StartsWith('-')) {
        $options = switch ($command) {
            'compile' { $globalOptions + $compileWatchQueryOpts + $compileWatchOpts }
            'c'       { $globalOptions + $compileWatchQueryOpts + $compileWatchOpts }
            'watch'   { $globalOptions + $compileWatchQueryOpts + $compileWatchOpts + $watchOpts }
            'w'       { $globalOptions + $compileWatchQueryOpts + $compileWatchOpts + $watchOpts }
            'init'    { $globalOptions + $initOpts }
            'query'   { $globalOptions + $compileWatchQueryOpts }
            default   { $globalOptions }
        }
        return $options | Where-Object { $_ -like "$wordToComplete*" }
    }
    else {
        # Complete file paths for relevant commands
        switch ($command) {
            'compile' { return Get-ChildItem -Path "$wordToComplete*" | Where-Object { $_.Name -like '*.typ' -or $_.PSIsContainer } }
            'c'       { return Get-ChildItem -Path "$wordToComplete*" | Where-Object { $_.Name -like '*.typ' -or $_.PSIsContainer } }
            'watch'   { return Get-ChildItem -Path "$wordToComplete*" | Where-Object { $_.Name -like '*.typ' -or $_.PSIsContainer } }
            'w'       { return Get-ChildItem -Path "$wordToComplete*" | Where-Object { $_.Name -like '*.typ' -or $_.PSIsContainer } }
            'query'   { return Get-ChildItem -Path "$wordToComplete*" | Where-Object { $_.Name -like '*.typ' -or $_.PSIsContainer } }
            'init'    { return Get-ChildItem -Path "$wordToComplete*" -Directory }
        }
    }
}

Register-ArgumentCompleter -Native -CommandName 'typst' -ScriptBlock $scriptBlock
