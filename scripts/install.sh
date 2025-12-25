#!/usr/bin/env bash
# Keep this script simple and easily auditable!
set -euo pipefail

# --- Helper Functions ---
# Based on https://github.com/oven-sh/bun/blob/main/install.sh

# Reset
Color_Off=''
# Regular Colors
Red=''
Green=''
Dim=''
# Bold
Bold_Green=''
Bold_White=''

if [[ -t 1 ]]; then
    Color_Off='\033[0m' # Text Reset
    Red='\033[0;31m'    # Red
    Green='\033[0;32m'  # Green
    Dim='\033[0;2m'     # Dim
    Bold_Green='\033[1;32m'
    Bold_White='\033[1m'
fi

error() {
    echo -e "${Red}error${Color_Off}:" "$@" >&2
    exit 1
}

info() {
    echo -e "${Dim}$*${Color_Off}"
}

success() {
    echo -e "${Green}$*${Color_Off}"
}

tildify() {
    if [[ "$1" == "$HOME/"* ]]; then
        echo "\$HOME/${1#"$HOME/"}"
    else
        echo "$1"
    fi
}

# --- Configuration ---
OWNER="${OWNER:-jassielof/typst-install}"
TYPST_REPO="typst/typst"
BASE_URL="https://jassielof.github.io/typst-install"

# --- Main Script ---

if [[ ${OS:-} == "Windows_NT" ]]; then
    info "For Windows, please use the PowerShell script:"
    info "irm $BASE_URL/install.ps1 | iex"
    error "This script is not for Windows."
fi

# Check for required tools
command -v curl >/dev/null || error "curl is required to install Typst"
command -v tar >/dev/null || error "tar is required to install Typst"

# Determine target architecture
case "$(uname -sm)" in
"Darwin x86_64") target="x86_64-apple-darwin" ;;
"Darwin arm64") target="aarch64-apple-darwin" ;;
"Linux aarch64") target="aarch64-unknown-linux-musl" ;;
*) target="x86_64-unknown-linux-musl" ;;
esac

archive_ext=".tar.xz"
folder="typst-$target"
file="$folder$archive_ext"

# Determine installation directory
# Use XDG Base Directory specification on Linux, traditional approach on macOS
if [[ -z "${TYPST_INSTALL:-}" ]]; then
    if [[ "$(uname)" == "Linux" ]]; then
        # XDG Base Directory: use $HOME/.local for Linux
        typst_install="$HOME/.local"
        bin_dir="$typst_install/bin"
        data_dir="$typst_install/share/typst"
    else
        # macOS: keep using $HOME/.typst for backward compatibility
        typst_install="$HOME/.typst"
        bin_dir="$typst_install/bin"
        data_dir="$typst_install"
    fi
else
    typst_install="$TYPST_INSTALL"
    bin_dir="$typst_install/bin"
    data_dir="$typst_install"
fi
exe="$bin_dir/typst"

# Determine version to install
version="${1:-latest}"
if [[ "$version" == "latest" ]]; then
    url="https://github.com/$TYPST_REPO/releases/latest/download/$file"
else
    url="https://github.com/$TYPST_REPO/releases/download/v$version/$file"
fi

# Download and extract
info "Downloading Typst from $url"
# Create a temporary directory for extraction
temp_extract_dir=$(mktemp -d)
curl --fail --location --progress-bar -o "$temp_extract_dir/$file" "$url" || error "Failed to download Typst"

info "Extracting archive..."
tar -xJf "$temp_extract_dir/$file" -C "$temp_extract_dir" || error "Failed to extract Typst"
rm -f "$temp_extract_dir/$file"

# Organize files
mkdir -p "$bin_dir"
mkdir -p "$data_dir"

# Move the binary
mv -f "$temp_extract_dir/$folder/typst" "$exe"
chmod +x "$exe"

# Move license and other files to data directory
if [[ -d "$temp_extract_dir/$folder" ]]; then
    # Enable nullglob to handle empty directories safely
    shopt -s nullglob
    # Move remaining files (LICENSE, README, etc.) to data_dir
    for item in "$temp_extract_dir/$folder"/*; do
        mv -f "$item" "$data_dir/"
    done
    shopt -u nullglob
fi

# Clean up
rm -rf "$temp_extract_dir"

success "Typst was installed successfully to ${Bold_Green}$(tildify "$exe")"

# --- Shell Setup: PATH and Completions ---

# Detect all available shells
available_shells=()
available_paths=()

if [[ -f "$HOME/.config/fish/config.fish" ]] || command -v fish >/dev/null 2>&1; then
    available_shells+=("fish")
    available_paths+=("$HOME/.config/fish/config.fish")
fi

if [[ -f "$HOME/.zshrc" ]] || command -v zsh >/dev/null 2>&1; then
    available_shells+=("zsh")
    available_paths+=("$HOME/.zshrc")
fi

if [[ -f "$HOME/.bashrc" ]] || command -v bash >/dev/null 2>&1; then
    available_shells+=("bash")
    available_paths+=("$HOME/.bashrc")
fi

# Add to PATH if not already there
if ! command -v typst >/dev/null; then
    echo

    # For Linux with XDG, check if ~/.local/bin is already in PATH
    path_check_needed=true
    if [[ "$(uname)" == "Linux" && -z "${TYPST_INSTALL:-}" ]]; then
        case ":$PATH:" in
            *":$HOME/.local/bin:"*)
                info "Typst installed to $HOME/.local/bin, which is already in your PATH."
                info "You may need to restart your shell or run: hash -r"
                path_check_needed=false
                ;;
        esac
    fi

    if [[ "$path_check_needed" == "true" ]]; then
        info "Adding Typst to your PATH for all detected shells..."

        for i in "${!available_shells[@]}"; do
            shell_name="${available_shells[$i]}"
            profile_path="${available_paths[$i]}"

            case "$shell_name" in
            fish)
                # Check if already configured
                if [[ -f "$profile_path" ]]; then
                    if grep -q "TYPST_INSTALL" "$profile_path" 2>/dev/null; then
                        info "Fish already configured (TYPST_INSTALL), skipping..."
                        continue
                    fi
                    # Also check for XDG-style configuration
                    if [[ "$(uname)" == "Linux" && -z "${TYPST_INSTALL:-}" ]] && grep -q "TYPST_PACKAGE_PATH\|Typst environment" "$profile_path" 2>/dev/null; then
                        info "Fish already configured (Typst environment), skipping..."
                        continue
                    fi
                fi

                # For fish, determine what to add
                if [[ "$(uname)" == "Linux" && -z "${TYPST_INSTALL:-}" ]]; then
                    # XDG path on Linux
                    profile_cmd=$(
                        cat <<'EOF'
# Typst environment
fish_add_path "$HOME/.local/bin"
EOF
                    )
                else
                    install_dir_fish="$typst_install"
                    if [[ "$typst_install" == "$HOME/"* ]]; then
                        install_dir_fish="\$HOME/${typst_install#"$HOME/"}"
                    fi

                    profile_cmd=$(
                        cat <<EOF
set -gx TYPST_INSTALL $install_dir_fish
set -gx TYPST_ROOT $install_dir_fish
fish_add_path "\$TYPST_INSTALL/bin"
EOF
                    )
                fi
                ;;

            zsh | bash)
                # Check if already configured
                if [[ -f "$profile_path" ]]; then
                    if grep -q "TYPST_INSTALL" "$profile_path" 2>/dev/null; then
                        info "$shell_name already configured (TYPST_INSTALL), skipping..."
                        continue
                    fi
                    # Also check for XDG-style configuration
                    if [[ "$(uname)" == "Linux" && -z "${TYPST_INSTALL:-}" ]] && grep -q "TYPST_PACKAGE_PATH\|Typst environment" "$profile_path" 2>/dev/null; then
                        info "$shell_name already configured (Typst environment), skipping..."
                        continue
                    fi
                fi

                # For bash/zsh, determine what to add
                if [[ "$(uname)" == "Linux" && -z "${TYPST_INSTALL:-}" ]]; then
                    # XDG path on Linux
                    profile_cmd=$(
                        cat <<'EOF'
# Typst environment
export PATH="$HOME/.local/bin:$PATH"
EOF
                    )
                else
                    install_dir_bash="$typst_install"
                    if [[ "$typst_install" == "$HOME/"* ]]; then
                        install_dir_bash="\$HOME/${typst_install#"$HOME/"}"
                    fi

                    profile_cmd=$(
                        cat <<EOF
export TYPST_INSTALL="$install_dir_bash"
export TYPST_ROOT="$install_dir_bash"
export PATH="\$TYPST_INSTALL/bin:\$PATH"
EOF
                    )
                fi
                ;;
            esac

            # Write to profile
            if [[ -w "$profile_path" || (! -e "$profile_path" && -w "$(dirname "$profile_path")") ]]; then
                {
                    echo -e '\n# Typst'
                    echo "$profile_cmd"
                } >>"$profile_path"
                success "Added Typst to PATH in $(tildify "$profile_path")"
            else
                info "Could not automatically add Typst to $(tildify "$profile_path")"
                info "Please add manually: ${Bold_White}$profile_cmd${Color_Off}"
            fi
        done
    fi

    # Suggest how to reload the current shell
    echo
    if [[ -n "${SHELL:-}" ]]; then
        shell_name=$(basename "$SHELL")
        info "To use Typst in your current shell, run:"
        case "$shell_name" in
        fish) info "  ${Bold_White}source ~/.config/fish/config.fish${Color_Off}" ;;
        zsh) info "  ${Bold_White}source ~/.zshrc${Color_Off}" ;;
        bash) info "  ${Bold_White}source ~/.bashrc${Color_Off}" ;;
        *) info "  ${Bold_White}exec $SHELL${Color_Off}" ;;
        esac
    fi
fi

# Install shell completions for all detected shells
echo
info "Setting up shell completions for all detected shells..."

for i in "${!available_shells[@]}"; do
    shell_name="${available_shells[$i]}"
    profile_path="${available_paths[$i]}"

    case "$shell_name" in
    fish)
        completions_dir="$HOME/.config/fish/completions"
        completions_file="$completions_dir/typst.fish"

        if [[ -f "$completions_file" ]]; then
            info "Fish completions already installed."
        else
            if mkdir -p "$completions_dir" 2>/dev/null && [[ -w "$completions_dir" ]]; then
                "$exe" completions fish >"$completions_file"
                success "Fish completions installed to $(tildify "$completions_file")"
            else
                info "Could not install Fish completions to $(tildify "$completions_file")"
            fi
        fi
        ;;

    zsh)
        # shellcheck disable=SC2016
        completion_cmd='autoload -Uz compinit && compinit && eval "$('$exe' completions zsh)"'

        if ! grep -q "typst completions zsh" "$profile_path" 2>/dev/null; then
            if [[ -w "$profile_path" || (! -e "$profile_path" && -w "$(dirname "$profile_path")") ]]; then
                {
                    echo -e '\n# Typst completions'
                    echo "$completion_cmd"
                } >>"$profile_path"
                success "Zsh completions configured in $(tildify "$profile_path")"
            else
                info "Could not automatically add completions to $(tildify "$profile_path")"
                info "Please add: ${Bold_White}$completion_cmd${Color_Off}"
            fi
        else
            info "Zsh completions already configured."
        fi
        ;;

    bash)
        # shellcheck disable=SC2016
        completion_cmd='eval "$('$exe' completions bash)"'

        if ! grep -q "typst completions bash" "$profile_path" 2>/dev/null; then
            if [[ -w "$profile_path" || (! -e "$profile_path" && -w "$(dirname "$profile_path")") ]]; then
                {
                    echo -e '\n# Typst completions'
                    echo "$completion_cmd"
                } >>"$profile_path"
                success "Bash completions configured in $(tildify "$profile_path")"
            else
                info "Could not automatically add completions to $(tildify "$profile_path")"
                info "Please add: ${Bold_White}$completion_cmd${Color_Off}"
            fi
        else
            info "Bash completions already configured."
        fi
        ;;
    esac
done

# --- Test Installation ---
echo
if command -v typst >/dev/null 2>&1; then
    success "Installation verified! Running 'typst --version'..."
    "$exe" --version
else
    info "Installation complete! Reload your shell to use Typst."
fi

echo
info "Run 'typst --help' to get started."
info "Stuck? Open an Issue at https://github.com/$OWNER/issues"
