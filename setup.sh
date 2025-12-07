#!/bin/bash
# =============================================================================
# macOS Setup Script
# Repository: new-mac-setup
# Description: Configures a fresh macOS install with development tools
# Usage: ./setup.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_REPO="https://github.com/dissidentcode/dot-files"
readonly DOTFILES_DIR="$HOME/git_repos/dot-files"
readonly ZSH_CUSTOM="$HOME/.zsh"
readonly LOG_FILE="$HOME/mac-setup.log"

# Architecture detection
readonly ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    readonly HOMEBREW_PREFIX="/opt/homebrew"
else
    readonly HOMEBREW_PREFIX="/usr/local"
fi
readonly BREW_ZSH="$HOMEBREW_PREFIX/bin/zsh"

# Track failures for summary
declare -a FAILURES=()

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================
log_info() {
    local msg="[INFO] $(date '+%H:%M:%S') $1"
    echo -e "\033[0;34m$msg\033[0m"
    echo "$msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[OK] $(date '+%H:%M:%S') $1"
    echo -e "\033[0;32m$msg\033[0m"
    echo "$msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="[WARN] $(date '+%H:%M:%S') $1"
    echo -e "\033[0;33m$msg\033[0m"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $(date '+%H:%M:%S') $1"
    echo -e "\033[0;31m$msg\033[0m"
    echo "$msg" >> "$LOG_FILE"
    FAILURES+=("$1")
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
command_exists() {
    command -v "$1" &>/dev/null
}

backup_and_link() {
    local src="$1"
    local dest="$2"
    local ts=$(date +%Y%m%d%H%M%S)

    # Create parent directory if needed
    mkdir -p "$(dirname "$dest")"

    # Backup existing file/directory (not symlink)
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        log_info "Backing up $dest -> ${dest}.backup.$ts"
        mv "$dest" "${dest}.backup.$ts"
    fi

    # Remove existing symlink if present
    if [[ -L "$dest" ]]; then
        rm "$dest"
    fi

    # Create symlink
    ln -sfn "$src" "$dest"
    log_success "Linked $dest -> $src"
}

# =============================================================================
# STEP 1: Xcode Command Line Tools
# =============================================================================
install_xcode_cli() {
    log_info "Checking Xcode Command Line Tools..."

    if xcode-select -p &>/dev/null; then
        log_success "Xcode CLI tools already installed"
        return 0
    fi

    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install

    echo ""
    echo "Please complete the Xcode CLI tools installation in the popup window."
    read -p "Press Enter when the installation is complete..."

    if xcode-select -p &>/dev/null; then
        log_success "Xcode CLI tools installed"
    else
        log_error "Xcode CLI tools installation may have failed"
    fi
}

# =============================================================================
# STEP 2: Homebrew Installation & Configuration
# =============================================================================
install_homebrew() {
    log_info "Checking Homebrew..."

    if command_exists brew; then
        log_success "Homebrew already installed"
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            log_error "Homebrew installation failed"
            return 1
        }
        log_success "Homebrew installed"
    fi

    # Configure shell environment for ~/.zprofile
    if [[ ! -f ~/.zprofile ]] || ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
        log_info "Adding Homebrew to ~/.zprofile..."
        echo '' >> ~/.zprofile
        echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\"" >> ~/.zprofile
        log_success "Added Homebrew to ~/.zprofile"
    fi

    # Initialize for current session
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

    # Update Homebrew
    log_info "Updating Homebrew..."
    brew update || log_warning "Homebrew update had warnings"
}

# =============================================================================
# STEP 3: Clone Dotfiles Repository
# =============================================================================
clone_dotfiles() {
    log_info "Checking dotfiles repository..."

    if [[ -d "$DOTFILES_DIR" ]]; then
        log_success "Dotfiles already cloned at $DOTFILES_DIR"
        # Pull latest changes
        log_info "Pulling latest dotfiles..."
        (cd "$DOTFILES_DIR" && git pull) || log_warning "Could not pull latest dotfiles"
        return 0
    fi

    log_info "Cloning dotfiles from $DOTFILES_REPO..."
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || {
        log_error "Failed to clone dotfiles"
        return 1
    }

    log_success "Dotfiles cloned to $DOTFILES_DIR"
}

# =============================================================================
# STEP 4: Install Packages via Brewfile
# =============================================================================
install_packages() {
    log_info "Installing packages from Brewfile..."

    local brewfile="$DOTFILES_DIR/Brewfile"
    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile not found at $brewfile"
        return 1
    fi

    # Ensure user is logged into App Store
    echo ""
    log_warning "Please ensure you are logged into the Mac App Store"
    read -p "Press Enter when ready to continue..."
    echo ""

    # Run brew bundle (continue on errors to get as much installed as possible)
    brew bundle --file="$brewfile" || {
        log_warning "Some packages may have failed to install - check output above"
    }

    log_success "Brewfile installation complete"
}

# =============================================================================
# STEP 5: Install NPM Global Packages
# =============================================================================
install_npm_packages() {
    log_info "Installing npm global packages..."

    if ! command_exists npm; then
        log_error "npm not found - skipping npm packages"
        return 1
    fi

    # Claude Code CLI
    log_info "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code || log_error "Claude Code CLI installation failed"

    # Gemini CLI
    log_info "Installing Gemini CLI..."
    npm install -g @google/gemini-cli || log_error "Gemini CLI installation failed"

    log_success "npm packages installed"
}

# =============================================================================
# STEP 6: Clone Zsh Plugins
# =============================================================================
install_zsh_plugins() {
    log_info "Installing Zsh plugins..."

    mkdir -p "$ZSH_CUSTOM"

    # zsh-autosuggestions
    if [[ -d "$ZSH_CUSTOM/zsh-autosuggestions" ]]; then
        log_success "zsh-autosuggestions already installed"
    else
        log_info "Cloning zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/zsh-autosuggestions" || {
            log_error "Failed to clone zsh-autosuggestions"
        }
    fi

    # zsh-syntax-highlighting
    if [[ -d "$ZSH_CUSTOM/zsh-syntax-highlighting" ]]; then
        log_success "zsh-syntax-highlighting already installed"
    else
        log_info "Cloning zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/zsh-syntax-highlighting" || {
            log_error "Failed to clone zsh-syntax-highlighting"
        }
    fi

    # Note: z plugin is installed via Homebrew, not git clone
    log_success "Zsh plugins installed"
}

# =============================================================================
# STEP 7: Create Symlinks
# =============================================================================
create_symlinks() {
    log_info "Creating symlinks..."

    # Ensure ~/.zsh directory exists
    mkdir -p "$HOME/.zsh"
    mkdir -p "$HOME/.config/starship"

    # Directory symlinks
    local -a dir_links=(
        "$DOTFILES_DIR/.config/nvim:$HOME/.config/nvim"
        "$DOTFILES_DIR/.config/sketchybar:$HOME/.config/sketchybar"
        "$DOTFILES_DIR/.config/lf:$HOME/.config/lf"
        "$DOTFILES_DIR/scripts:$HOME/scripts"
    )

    # File symlinks
    local -a file_links=(
        "$DOTFILES_DIR/zsh/.zshrc:$HOME/.zshrc"
        "$DOTFILES_DIR/zsh/.alias.sh:$HOME/.zsh/.alias.sh"
        "$DOTFILES_DIR/zsh/.functions.sh:$HOME/.zsh/.functions.sh"
        "$DOTFILES_DIR/zsh/.motd.sh:$HOME/.zsh/.motd.sh"
        "$DOTFILES_DIR/zsh/starship.toml:$HOME/.config/starship/starship.toml"
        "$DOTFILES_DIR/.config/.aerospace.toml:$HOME/.aerospace.toml"
    )

    # Optional symlinks (may not exist in all dotfiles setups)
    local -a optional_links=(
        "$DOTFILES_DIR/zsh/.zsh-scripts:$HOME/.zsh-scripts"
    )

    # Create directory symlinks
    for link in "${dir_links[@]}"; do
        IFS=":" read -r src dest <<< "$link"
        if [[ -d "$src" ]]; then
            backup_and_link "$src" "$dest"
        else
            log_warning "Directory not found (skipping): $src"
        fi
    done

    # Create file symlinks
    for link in "${file_links[@]}"; do
        IFS=":" read -r src dest <<< "$link"
        if [[ -f "$src" ]]; then
            backup_and_link "$src" "$dest"
        else
            log_warning "File not found (skipping): $src"
        fi
    done

    # Create optional symlinks (no warning if missing)
    for link in "${optional_links[@]}"; do
        IFS=":" read -r src dest <<< "$link"
        if [[ -e "$src" ]]; then
            backup_and_link "$src" "$dest"
        fi
    done

    log_success "Symlinks created"
}

# =============================================================================
# STEP 8: Configure Shell
# =============================================================================
configure_shell() {
    log_info "Configuring shell..."

    # Check if Homebrew zsh exists
    if [[ ! -x "$BREW_ZSH" ]]; then
        log_error "Homebrew zsh not found at $BREW_ZSH"
        return 1
    fi

    # Add Homebrew zsh to /etc/shells if not present
    if ! grep -Fxq "$BREW_ZSH" /etc/shells; then
        log_info "Adding $BREW_ZSH to /etc/shells (requires sudo)..."
        echo "$BREW_ZSH" | sudo tee -a /etc/shells > /dev/null
        log_success "Added $BREW_ZSH to /etc/shells"
    fi

    # Change default shell
    if [[ "$SHELL" != "$BREW_ZSH" ]]; then
        log_info "Changing default shell to $BREW_ZSH..."
        chsh -s "$BREW_ZSH" || log_error "Failed to change default shell"
        log_success "Default shell changed to $BREW_ZSH"
    else
        log_success "Default shell already set to $BREW_ZSH"
    fi
}

# =============================================================================
# STEP 9: Verify Starship Configuration
# =============================================================================
verify_starship() {
    log_info "Verifying Starship configuration..."

    local issues=0

    # Check starship is installed
    if ! command_exists starship; then
        log_error "Starship not installed"
        ((issues++))
    else
        log_success "Starship binary installed"
    fi

    # Verify config file exists and is linked
    local starship_config="$HOME/.config/starship/starship.toml"
    if [[ -L "$starship_config" && -f "$starship_config" ]]; then
        log_success "Starship config linked correctly"
    else
        log_warning "Starship config may not be linked correctly at $starship_config"
        ((issues++))
    fi

    # Verify .zshrc has starship init
    if [[ -f "$HOME/.zshrc" ]] && grep -q 'eval "$(starship init zsh)"' "$HOME/.zshrc" 2>/dev/null; then
        log_success "Starship init found in .zshrc"
    else
        log_warning "Starship init not found in .zshrc"
        ((issues++))
    fi

    # Verify Nerd Font is installed
    if [[ -d "$HOME/Library/Fonts" ]] && ls "$HOME/Library/Fonts" 2>/dev/null | grep -qi "JetBrains"; then
        log_success "JetBrainsMono Nerd Font appears to be installed"
    elif [[ -d "/Library/Fonts" ]] && ls "/Library/Fonts" 2>/dev/null | grep -qi "JetBrains"; then
        log_success "JetBrainsMono Nerd Font appears to be installed (system)"
    else
        log_warning "JetBrainsMono Nerd Font may not be installed - check Font Book"
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "Starship verification complete - no issues found"
    else
        log_warning "Starship verification found $issues potential issue(s)"
    fi
}

# =============================================================================
# STEP 10: Cleanup
# =============================================================================
cleanup() {
    log_info "Running cleanup..."
    brew cleanup 2>/dev/null || log_warning "Brew cleanup had warnings"
    log_success "Cleanup complete"
}

# =============================================================================
# SUMMARY
# =============================================================================
print_summary() {
    echo ""
    echo "=============================================="
    echo "           SETUP COMPLETE"
    echo "=============================================="
    echo ""

    if [[ ${#FAILURES[@]} -gt 0 ]]; then
        echo -e "\033[0;33mWarnings/Failures:\033[0m"
        for failure in "${FAILURES[@]}"; do
            echo "  - $failure"
        done
        echo ""
    else
        echo -e "\033[0;32mNo errors encountered!\033[0m"
        echo ""
    fi

    echo "Log file: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open WezTerm and set font to 'JetBrainsMono Nerd Font'"
    echo "  3. Verify your prompt displays correctly"
    echo ""
    echo "Installed tools you may want to configure:"
    echo "  - atuin: Run 'atuin login' or 'atuin register' for sync"
    echo "  - claude: Run 'claude' to start Claude Code CLI"
    echo "  - gemini: Run 'gemini' to start Gemini CLI"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    # Initialize log file
    echo "=== macOS Setup Log - $(date) ===" > "$LOG_FILE"

    echo ""
    echo "=============================================="
    echo "       macOS Development Setup"
    echo "       Architecture: $ARCH"
    echo "       Homebrew prefix: $HOMEBREW_PREFIX"
    echo "=============================================="
    echo ""

    install_xcode_cli
    install_homebrew
    clone_dotfiles
    install_packages
    install_npm_packages
    install_zsh_plugins
    create_symlinks
    configure_shell
    verify_starship
    cleanup
    print_summary
}

main "$@"
