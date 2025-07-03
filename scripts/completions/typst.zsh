# TODO: Test Zsh completions
#compdef typst

# Zsh completion for typst
#
# To load completion for the current session:
#   source <(typst --completions zsh)
#
# To load completion permanently:
#   typst --completions zsh > "${fpath[1]}/_typst"
#   or link this file to a directory in your $fpath.

_typst() {
    local -a commands
    local ret=1

    _arguments -C \
        '(-h --help)'{-h,--help}'[Print help information]' \
        '(-V --version)'{-V,--version}'[Print version information]' \
        '--color[Set color output]:mode:(auto always never)' \
        '--cert[Path to a custom CA certificate]:file:_files' \
        '1: :->cmds' \
        '*:: :->args' && ret=0

    if (( ret )); then
        return
    fi

    case $state in
        cmds)
            commands=(
                'compile:Compiles an input file'
                'c:Alias for compile'
                'watch:Watches an input file for changes'
                'w:Alias for watch'
                'init:Initializes a new project'
                'query:Extracts metadata from a file'
                'fonts:Lists all discovered fonts'
                'update:Self-updates the Typst CLI'
                'help:Prints help information'
            )
            _describe 'command' commands
            ;;
        args)
            case $words[1] in
                compile|c)
                    _arguments \
                        '--root[Configures the project root]:path:_files -/' \
                        '--input[Set a compile-time input (key=value)]' \
                        '--font-path[Add a path to search for fonts]:path:_files -/' \
                        '--ignore-system-fonts[Do not search system fonts]' \
                        '--package-path[Custom path to local packages]:path:_files -/' \
                        '--package-cache-path[Custom path to package cache]:path:_files -/' \
                        '--creation-timestamp[Set document creation date (UNIX timestamp)]' \
                        '(-j --jobs)'{-j,--jobs}'[Number of parallel jobs]' \
                        '--features[Enables in-development features]:feature:(html)' \
                        '--diagnostic-format[The format of diagnostics]:format:(human short)' \
                        '(-f --format)'{-f,--format}'[Output format for the compiled file]:format:(pdf png svg html)' \
                        '--pages[The pages to compile]' \
                        '--pdf-standard[The PDF standard to use]:standard:(1.7 a-2b a-3b)' \
                        '--ppi[The pixels per inch to use for raster images]' \
                        '--make-deps[Output a Makefile-like dependency file]' \
                        '--open[Open the output file after compilation]' \
                        '--timings[Print timings for the compilation steps]' \
                        '*:input file:_files -g "*.typ"'
                    ;;
                watch|w)
                    _arguments \
                        '--root[Configures the project root]:path:_files -/' \
                        '--input[Set a compile-time input (key=value)]' \
                        '--font-path[Add a path to search for fonts]:path:_files -/' \
                        '--ignore-system-fonts[Do not search system fonts]' \
                        '--package-path[Custom path to local packages]:path:_files -/' \
                        '--package-cache-path[Custom path to package cache]:path:_files -/' \
                        '--creation-timestamp[Set document creation date (UNIX timestamp)]' \
                        '(-j --jobs)'{-j,--jobs}'[Number of parallel jobs]' \
                        '--features[Enables in-development features]:feature:(html)' \
                        '--diagnostic-format[The format of diagnostics]:format:(human short)' \
                        '(-f --format)'{-f,--format}'[Output format for the compiled file]:format:(pdf png svg html)' \
                        '--pages[The pages to compile]' \
                        '--pdf-standard[The PDF standard to use]:standard:(1.7 a-2b a-3b)' \
                        '--ppi[The pixels per inch to use for raster images]' \
                        '--make-deps[Output a Makefile-like dependency file]' \
                        '--open[Open the output file after compilation]' \
                        '--timings[Print timings for the compilation steps]' \
                        '--no-serve[Do not serve the output file]' \
                        '--no-reload[Do not reload the browser on changes]' \
                        '--port[The port to use for the web server]' \
                        '*:input file:_files -g "*.typ"'
                    ;;
                init)
                     _arguments \
                        '--package-path[Custom path to local packages]:path:_files -/' \
                        '--package-cache-path[Custom path to package cache]:path:_files -/' \
                        '*:project directory:_files -/'
                    ;;
                query)
                    _arguments \
                        '--root[Configures the project root]:path:_files -/' \
                        '--input[Set a compile-time input (key=value)]' \
                        '--font-path[Add a path to search for fonts]:path:_files -/' \
                        '--ignore-system-fonts[Do not search system fonts]' \
                        '--package-path[Custom path to local packages]:path:_files -/' \
                        '--package-cache-path[Custom path to package cache]:path:_files -/' \
                        '--creation-timestamp[Set document creation date (UNIX timestamp)]' \
                        '(-j --jobs)'{-j,--jobs}'[Number of parallel jobs]' \
                        '--features[Enables in-development features]:feature:(html)' \
                        '--diagnostic-format[The format of diagnostics]:format:(human short)' \
                        '*:input file:_files -g "*.typ"'
                    ;;
                fonts)
                    _arguments \
                        '--font-path[Add a path to search for fonts]:path:_files -/' \
                        '--ignore-system-fonts[Do not search system fonts]' \
                        '--variants[Also list font variants]'
                    ;;
                update|help)
                    # These commands have no specific options other than global ones.
                    ;;
            esac
            ;;
    esac
}

_typst "$@"
