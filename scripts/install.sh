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
temp_dir=$(mktemp -d)
mv "$typst_install/$folder"/* "$temp_dir/"
mv "$temp_dir"/* "$typst_install/"
rm -rf "$temp_dir"
rm -rf "${typst_install:?}/${folder:?}"

success "Typst was installed successfully to ${Bold_Green}$(tildify "$exe")"

# --- Shell Setup: PATH and Completions ---

# Detect all available shells
declare -A available_shells
[[ -f "$HOME/.config/fish/config.fish" ]] || command -v fish >/dev/null 2>&1 && available_shells[fish]="$HOME/.config/fish/config.fish"
[[ -f "$HOME/.zshrc" ]] || command -v zsh >/dev/null 2>&1 && available_shells[zsh]="$HOME/.zshrc"
[[ -f "$HOME/.bashrc" ]] || command -v bash >/dev/null 2>&1 && available_shells[bash]="$HOME/.bashrc"

# Add to PATH if not already there
if ! command -v typst >/dev/null; then
    echo
    info "Adding Typst to your PATH for all detected shells..."

    for shell_name in "${!available_shells[@]}"; do
        profile_path="${available_shells[$shell_name]}"

        case "$shell_name" in
        fish)
            # Check if already configured
            if [[ -f "$profile_path" ]] && grep -q "TYPST_INSTALL" "$profile_path" 2>/dev/null; then
                info "Fish already configured, skipping..."
                continue
            fi

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
            ;;

        zsh | bash)
            # Check if already configured
            if [[ -f "$profile_path" ]] && grep -q "TYPST_INSTALL" "$profile_path" 2>/dev/null; then
                info "$shell_name already configured, skipping..."
                continue
            fi

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

for shell_name in "${!available_shells[@]}"; do
    profile_path="${available_shells[$shell_name]}"

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
