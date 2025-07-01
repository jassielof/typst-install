# Typst completion script for Bash and Zsh
#
# To load completion for the current session:
# - Bash: source <(typst --completions bash)
# - Zsh:  source <(typst --completions zsh)
#
# To load completion permanently:
# - Bash: typst --completions bash > /etc/bash_completion.d/typst
# - Zsh:  typst --completions zsh > "${fpath[1]}/_typst"

_typst() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    # Main commands
    local commands="compile watch init query fonts update help"
    # Aliases
    local alias_c="c"
    local alias_w="w"

    # Options shared by compile, watch, query
    local compile_watch_query_opts="--root --input --font-path --ignore-system-fonts --package-path --package-cache-path --creation-timestamp --jobs -j --features --diagnostic-format"
    # Options shared by compile, watch
    local compile_watch_opts="--format -f --pages --pdf-standard --ppi --make-deps --open --timings"
    # Watch-specific options
    local watch_opts="--no-serve --no-reload --port"
    # Init-specific options
    local init_opts="--package-path --package-cache-path"
    # Query-specific options
    local query_opts="" # No specific options other than shared ones

    # Global options
    local global_opts="--help -h --version -V --color --cert"

    # Find the main command in the command line
    local command=""
    for word in "${words[@]}"; do
        case "$word" in
            compile|c|watch|w|init|query|fonts|update|help)
                command="$word"
                break
                ;;
        esac
    done

    # Main completion logic
    if [[ "$cword" -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands $alias_c $alias_w" -- "$cur"))
        return
    fi

    # Completion for options and arguments based on the command
    case "$command" in
        compile|c)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$global_opts $compile_watch_query_opts $compile_watch_opts" -- "$cur"))
            else
                _filedir 'typ'
            fi
            ;;
        watch|w)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$global_opts $compile_watch_query_opts $compile_watch_opts $watch_opts" -- "$cur"))
            else
                _filedir 'typ'
            fi
            ;;
        init)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$global_opts $init_opts" -- "$cur"))
            else
                _filedir -d # complete directories
            fi
            ;;
        query)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$global_opts $compile_watch_query_opts $query_opts" -- "$cur"))
            else
                _filedir 'typ'
            fi
            ;;
        fonts|update|help)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$global_opts" -- "$cur"))
            fi
            ;;
        *) # No command yet, or unknown command
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$global_opts" -- "$cur"))
            fi
            ;;
    esac

    # Handle completions for option arguments
    case "$prev" in
        --color)
            COMPREPLY=($(compgen -W "auto always never" -- "$cur"))
            ;;
        --format|-f)
            COMPREPLY=($(compgen -W "pdf png svg html" -- "$cur"))
            ;;
        --pdf-standard)
            COMPREPLY=($(compgen -W "1.7 a-2b a-3b" -- "$cur"))
            ;;
        --diagnostic-format)
            COMPREPLY=($(compgen -W "human short" -- "$cur"))
            ;;
        --features)
            COMPREPLY=($(compgen -W "html" -- "$cur"))
            ;;
        --root|--font-path|--package-path|--package-cache-path|--make-deps|--timings|--cert)
            _filedir
            ;;
    esac
}

# Register the completion function
if (complete &>/dev/null); then # bash
    complete -F _typst typst
elif (compdef &>/dev/null); then # zsh
    compdef _typst typst
fi
