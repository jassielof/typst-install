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

# --- Configuration ---
# You can override these variables, e.g. `OWNER=foo/bar ./install.sh`
OWNER="${OWNER:-jassielof/typst-install}"
TYPST_REPO="typst/typst"
BASE_URL="https://jassielof.github.io/typst-install"

# --- Main Script ---

if [[ ${OS:-} == "Windows_NT" ]]; then
    # The error function exits, so this info message must come first.
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
typst_install="${TYPST_INSTALL:-$HOME/.typst}"
bin_dir="$typst_install/bin"
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
mkdir -p "$typst_install"
curl --fail --location --progress-bar -o "$typst_install/$file" "$url" || error "Failed to download Typst"

info "Extracting archive..."
tar -xJf "$typst_install/$file" -C "$typst_install" || error "Failed to extract Typst"
rm -f "$typst_install/$file"

# Organize files
mkdir -p "$bin_dir"
mv -f "$typst_install/$folder/typst" "$exe"
chmod +x "$exe"

# Move license and other files to the root of typst_install
# Use a temporary directory to avoid issues with `mv` source and destination being the same
temp_dir=$(mktemp -d)
mv "$typst_install/$folder"/* "$temp_dir/"
mv "$temp_dir"/* "$typst_install/"
rm -rf "$temp_dir"
rm -rf "${typst_install:?}/${folder:?}"

tildify() {
    if [[ "$1" == "$HOME/"* ]]; then
        echo "\$HOME/${1#"$HOME/"}"
    else
        echo "$1"
    fi
}

success "Typst was installed successfully to ${Bold_Green}$(tildify "$exe")"

# --- Shell Setup: PATH, TYPST_ROOT, and Completions ---

# Add to PATH if not already there
if ! command -v typst >/dev/null; then
    echo
    info "Adding Typst to your PATH..."

    shell_name=$(basename "$SHELL")
    profile_path=""
    profile_cmd=""
    refresh_cmd=""

    case "$shell_name" in
    fish)
        profile_path="$HOME/.config/fish/config.fish"
        # fish handles paths with spaces and tilde expansion differently
        install_dir_fish="\"$typst_install\""
        if [[ "$typst_install" == "$HOME/"* ]]; then
            install_dir_fish="\$HOME/${typst_install#"$HOME/"}"
        fi
        profile_cmd=$(cat <<EOF
set -gx TYPST_INSTALL $install_dir_fish
set -gx TYPST_ROOT $install_dir_fish
set -gx PATH "\$TYPST_INSTALL/bin" \$PATH
EOF
)
        refresh_cmd="source $(tildify "$profile_path")"
        ;;
    zsh | bash)
        if [[ "$shell_name" == "zsh" ]]; then
            profile_path="$HOME/.zshrc"
            refresh_cmd="exec $SHELL"
        else
            profile_path="$HOME/.bashrc"
            refresh_cmd="source $(tildify "$profile_path")"
            if [[ -f "$HOME/.bash_profile" && ! -L "$HOME/.bash_profile" ]]; then
                if ! grep -q ".bashrc" "$HOME/.bash_profile"; then
                    info "To make 'typst' available in login shells, please add 'source ~/.bashrc' to your ~/.bash_profile"
                fi
            fi
        fi

        # Using quoted string for install dir to handle spaces
        quoted_install_dir="\"${typst_install//\"/\\\"}\""
        if [[ $quoted_install_dir == "\"$HOME/"* ]]; then
            # Replace home path with $HOME for portability
            quoted_install_dir="\$HOME/${quoted_install_dir#\""$HOME"/}"
        fi

        profile_cmd=$(cat <<EOF
export TYPST_INSTALL=$quoted_install_dir
export TYPST_ROOT=$quoted_install_dir
export PATH="\$TYPST_INSTALL/bin:\$PATH"
EOF
)
        ;;
    *)
        # Fallback for other shells
        profile_path="$HOME/.profile"
        quoted_install_dir="\"${typst_install//\"/\\\"}\""
        if [[ $quoted_install_dir == "\"$HOME/"* ]]; then
            quoted_install_dir="\$HOME/${quoted_install_dir#\""$HOME"/}"
        fi
        profile_cmd=$(cat <<EOF
export TYPST_INSTALL=$quoted_install_dir
export TYPST_ROOT=$quoted_install_dir
export PATH="\$TYPST_INSTALL/bin:\$PATH"
EOF
)
        refresh_cmd="exec $SHELL"
        ;;
    esac

    if [[ -w "$profile_path" || (! -e "$profile_path" && -w "$(dirname "$profile_path")") ]]; then
        {
            echo -e '\n# Typst'
            echo "$profile_cmd"
        } >>"$profile_path"
        info "Added Typst to PATH in $(tildify "$profile_path")"
        echo
        info "To get started, run the following command or restart your shell:"
        echo
        info "${Bold_White}  $refresh_cmd${Color_Off}"
    else
        echo
        info "Could not automatically modify your shell profile."
        info "Please add the following to your shell configuration file ($(tildify "$profile_path")):"
        echo
        info "${Bold_White}$profile_cmd${Color_Off}"
    fi
fi

# Install shell completions using typst completions command
info "Setting up shell completions..."
shell_name=$(basename "$SHELL")
case "$shell_name" in
fish)
    completions_dir="$HOME/.config/fish/completions"
    mkdir -p "$completions_dir"
    completion_file="$completions_dir/typst.fish"
    echo "$exe completions fish | source" > "$completion_file"
    success "Fish completions configured at $(tildify "$completion_file")"
    info "Completions will be generated dynamically from the installed typst version."
    ;;
zsh)
    profile_path="$HOME/.zshrc"
    completion_cmd='eval "$('$exe' completions zsh)"'

    if ! grep -q "typst completions zsh" "$profile_path" 2>/dev/null; then
        if [[ -w "$profile_path" || (! -e "$profile_path" && -w "$(dirname "$profile_path")") ]]; then
            {
                echo -e '\n# Typst completions'
                echo "$completion_cmd"
            } >>"$profile_path"
            success "Zsh completions configured in $(tildify "$profile_path")"
            info "Completions will be generated dynamically from the installed typst version."
        else
            echo
            info "Could not automatically add completions to your .zshrc"
            info "Please add the following to $(tildify "$profile_path"):"
            echo
            info "${Bold_White}$completion_cmd${Color_Off}"
        fi
    else
        info "Zsh completions already configured."
    fi
    ;;
bash)
    profile_path="$HOME/.bashrc"
    completion_cmd='eval "$('$exe' completions bash)"'

    if ! grep -q "typst completions bash" "$profile_path" 2>/dev/null; then
        if [[ -w "$profile_path" || (! -e "$profile_path" && -w "$(dirname "$profile_path")") ]]; then
            {
                echo -e '\n# Typst completions'
                echo "$completion_cmd"
            } >>"$profile_path"
            success "Bash completions configured in $(tildify "$profile_path")"
            info "Completions will be generated dynamically from the installed typst version."
        else
            echo
            info "Could not automatically add completions to your .bashrc"
            info "Please add the following to $(tildify "$profile_path"):"
            echo
            info "${Bold_White}$completion_cmd${Color_Off}"
        fi
    else
        info "Bash completions already configured."
    fi
    ;;
*)
    info "Could not detect shell, skipping completion installation."
    ;;
esac


echo
info "Run 'typst --help' to get started."
info "Stuck? Open an Issue at https://github.com/$OWNER/issues"
