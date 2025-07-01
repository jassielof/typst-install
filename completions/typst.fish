# fish completion for typst

# Clear existing completions
complete -c typst -e

# Helper function to check if we should complete files.
# We don't want to complete files if the user is typing an option.
function __typst_should_complete_files
    set -l cmd (commandline -opc)
    # Don't complete files if the last token starts with a dash
    if string match -q -- "-*" -- $cmd[-1]
        return 1
    end
    return 0
end

# --- Main Commands & Aliases ---
complete -c typst -n "__fish_use_subcommand" -a compile -d "Compiles an input file"
complete -c typst -n "__fish_use_subcommand" -a c -d "Alias for compile"
complete -c typst -n "__fish_use_subcommand" -a watch -d "Watches an input file"
complete -c typst -n "__fish_use_subcommand" -a w -d "Alias for watch"
complete -c typst -n "__fish_use_subcommand" -a init -d "Initializes a new project"
complete -c typst -n "__fish_use_subcommand" -a query -d "Processes an input file to extract provided metadata"
complete -c typst -n "__fish_use_subcommand" -a fonts -d "Lists all discovered fonts"
complete -c typst -n "__fish_use_subcommand" -a update -d "Self update the Typst CLI"
complete -c typst -n "__fish_use_subcommand" -a help -d "Print help"

# --- Global Options ---
complete -c typst -s h -l help -d "Print help"
complete -c typst -s V -l version -d "Print version"
complete -c typst -l color -r -a "auto always never" -d "Set color output"
complete -c typst -l cert -F -d "Path to a custom CA certificate"

# --- Command-specific Options ---

# `compile`, `watch`, and `query` share many options
set -l compile_watch_query_condition "__fish_seen_subcommand_from compile c watch w query"
complete -c typst -n "$compile_watch_query_condition" -l root -F -d "Configures the project root"
complete -c typst -n "$compile_watch_query_condition" -l input -r -d "Set a compile-time input (key=value)"
complete -c typst -n "$compile_watch_query_condition" -l font-path -F -d "Add a path to search for fonts"
complete -c typst -n "$compile_watch_query_condition" -l ignore-system-fonts -d "Do not search system fonts"
complete -c typst -n "$compile_watch_query_condition" -l package-path -F -d "Custom path to local packages"
complete -c typst -n "$compile_watch_query_condition" -l package-cache-path -F -d "Custom path to package cache"
complete -c typst -n "$compile_watch_query_condition" -l creation-timestamp -r -d "Set document's creation date (UNIX timestamp)"
complete -c typst -n "$compile_watch_query_condition" -s j -l jobs -r -d "Number of parallel jobs"
complete -c typst -n "$compile_watch_query_condition" -l features -r -a "html" -d "Enables in-development features"
complete -c typst -n "$compile_watch_query_condition" -l diagnostic-format -r -a "human short" -d "The format of diagnostics"

# `compile` and `watch` share many options
set -l compile_watch_condition "__fish_seen_subcommand_from compile c watch w"
complete -c typst -n "$compile_watch_condition; and __typst_should_complete_files" -F -a "(__fish_complete_suffix .typ)" -d "Input file"
complete -c typst -n "$compile_watch_condition" -s f -l format -r -a "pdf png svg html" -d "Output format"
complete -c typst -n "$compile_watch_condition" -l pages -r -d "Which pages to export (e.g. 1,3-5)"
complete -c typst -n "$compile_watch_condition" -l pdf-standard -r -a "1.7 a-2b a-3b" -d "PDF standard to enforce"
complete -c typst -n "$compile_watch_condition" -l ppi -r -d "The PPI for PNG export"
complete -c typst -n "$compile_watch_condition" -l make-deps -F -d "Write a Makefile with dependencies to a file"
complete -c typst -n "$compile_watch_condition" -l open -d "Open the output file after compilation"
complete -c typst -n "$compile_watch_condition" -l timings -F -d "Produce performance timings (JSON)"

# `watch` specific
set -l watch_condition "__fish_seen_subcommand_from watch w"
complete -c typst -n "$watch_condition" -l no-serve -d "Disables the built-in HTTP server for HTML export"
complete -c typst -n "$watch_condition" -l no-reload -d "Disables live reload for HTML export"
complete -c typst -n "$watch_condition" -l port -r -d "The port where HTML is served"

# `init`
set -l init_condition "__fish_seen_subcommand_from init"
complete -c typst -n "$init_condition" -l package-path -F -d "Custom path to local packages"
complete -c typst -n "$init_condition" -l package-cache-path -F -d "Custom path to package cache"
complete -c typst -n "$init_condition; and not __fish_seen_subcommand_from -o" -a "(__typst_complete_templates)" -d "Template to use"
complete -c typst -n "$init_condition; and __typst_should_complete_files" -F -d "Project directory"

# `query`
set -l query_condition "__fish_seen_subcommand_from query"
complete -c typst -n "$query_condition; and __typst_should_complete_files" -F -a "(__fish_complete_suffix .typ)"
