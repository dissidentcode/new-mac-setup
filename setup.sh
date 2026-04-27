#!/bin/bash
# =============================================================================
# macOS Setup Script
# Repository: new-mac-setup
# Description: Configures a fresh macOS install with development tools.
# Apple Silicon only. macOS 16+ recommended.
# Usage: ./setup.sh [--yes] [--dry-run] [--resume [STEP]] [--help]
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================
readonly DOTFILES_REPO="https://github.com/dissidentcode/dot-files"
readonly DOTFILES_DIR="$HOME/.dotfiles"
readonly ZSH_CUSTOM="$HOME/.zsh"
readonly LOG_FILE="$HOME/mac-setup.log"
readonly STATE_FILE="$HOME/.mac-setup-state"
readonly HOMEBREW_PREFIX="/opt/homebrew"
readonly BREW_ZSH="$HOMEBREW_PREFIX/bin/zsh"

# NPM globals to install. Edit this list to add/remove.
readonly NPM_GLOBALS=(
    "@anthropic-ai/claude-code"
    "@google/gemini-cli"
    "@openai/codex"
)

# Step order (used by --resume STEP).
readonly STEP_ORDER=(
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
)

declare -a FAILURES=()

SKIP_PROMPTS=false
DRY_RUN=false
RESUME=false
RESUME_FROM=""

# =============================================================================
# LOGGING
# Stderr gets ANSI color. Log file gets plain text.
# =============================================================================
_log() {
    local level="$1" color="$2" msg="$3" ts plain
    ts="$(date '+%H:%M:%S')"
    plain="[$level] $ts $msg"
    printf '\033[%sm%s\033[0m\n' "$color" "$plain" >&2
    printf '%s\n' "$plain" >> "$LOG_FILE"
}

log_info()    { _log "INFO"  "0;34" "$1"; }
log_success() { _log "OK"    "0;32" "$1"; }
log_warning() { _log "WARN"  "0;33" "$1"; }
log_error()   { _log "ERROR" "0;31" "$1"; FAILURES+=("$1"); }

# =============================================================================
# HELPERS
# =============================================================================
command_exists() {
    command -v "$1" &>/dev/null
}

# Run a command unless DRY_RUN is true. Returns the command's exit code.
do_run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[dry-run] would run: $*"
        return 0
    fi
    "$@"
}

# Append a literal line to a file. Idempotent if the line already exists.
append_to_file() {
    local file="$1" content="$2"
    if [[ -f "$file" ]] && grep -Fxq "$content" "$file" 2>/dev/null; then
        return 0
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[dry-run] would append to $file: $content"
        return 0
    fi
    printf '%s\n' "$content" >> "$file"
}

# Append via sudo (e.g. /etc/shells).
sudo_append_to_file() {
    local file="$1" content="$2"
    if grep -Fxq "$content" "$file" 2>/dev/null; then
        return 0
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[dry-run] would sudo-append to $file: $content"
        return 0
    fi
    echo "$content" | sudo tee -a "$file" > /dev/null
}

# Mark a step done in the state file.
mark_done() {
    local step="$1"
    [[ "$DRY_RUN" == "true" ]] && return 0
    if ! grep -Fxq "$step" "$STATE_FILE" 2>/dev/null; then
        echo "$step" >> "$STATE_FILE"
    fi
}

# Return 0 if the step should run, 1 if it should be skipped.
should_run() {
    local step="$1"
    if [[ "$RESUME" == "true" ]] && [[ -f "$STATE_FILE" ]]; then
        if grep -Fxq "$step" "$STATE_FILE"; then
            log_info "[$step] already done, skipping"
            return 1
        fi
    fi
    return 0
}

# Backup any existing non-symlink target, then create a symlink.
backup_and_link() {
    local src="$1" dest="$2" ts
    ts="$(date +%Y%m%d%H%M%S)"
    do_run mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        log_info "Backing up $dest -> ${dest}.backup.$ts"
        do_run mv "$dest" "${dest}.backup.$ts"
    fi
    if [[ -L "$dest" ]]; then
        do_run rm "$dest"
    fi
    do_run ln -sfn "$src" "$dest"
    log_success "Linked $dest -> $src"
}

# Wait for user OK unless --yes was passed.
wait_for_user() {
    local prompt="$1"
    if [[ "$SKIP_PROMPTS" == "true" ]]; then
        log_info "[--yes] auto-continuing past: $prompt"
        return 0
    fi
    read -r -p "$prompt"
}

# =============================================================================
# STEPS
# =============================================================================
install_xcode_cli() {
    should_run "install_xcode_cli" || return 0
    log_info "Checking Xcode Command Line Tools..."
    if xcode-select -p &>/dev/null; then
        log_success "Xcode CLI tools already installed"
        mark_done "install_xcode_cli"
        return 0
    fi
    log_info "Installing Xcode Command Line Tools..."
    do_run xcode-select --install || true
    echo ""
    echo "Please complete the Xcode CLI tools installation in the popup window."
    wait_for_user "Press Enter when the installation is complete..."
    if xcode-select -p &>/dev/null || [[ "$DRY_RUN" == "true" ]]; then
        log_success "Xcode CLI tools installed"
        mark_done "install_xcode_cli"
    else
        log_error "Xcode CLI tools installation may have failed"
        return 1
    fi
}

install_homebrew() {
    should_run "install_homebrew" || return 0
    log_info "Checking Homebrew..."
    if command_exists brew; then
        log_success "Homebrew already installed"
    elif [[ "$DRY_RUN" == "true" ]]; then
        log_info "[dry-run] would download and run the Homebrew installer"
    else
        log_info "Installing Homebrew..."
        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            log_error "Homebrew installation failed"
            return 1
        fi
        log_success "Homebrew installed"
    fi

    if [[ ! -f "$HOME/.zprofile" ]] || ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
        log_info "Adding Homebrew to ~/.zprofile..."
        append_to_file "$HOME/.zprofile" "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
        log_success "Added Homebrew to ~/.zprofile"
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    fi

    log_info "Updating Homebrew..."
    do_run brew update || log_warning "Homebrew update had warnings"
    mark_done "install_homebrew"
}

clone_dotfiles() {
    should_run "clone_dotfiles" || return 0
    log_info "Checking dotfiles repository..."
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_success "Dotfiles already cloned at $DOTFILES_DIR"
        log_info "Pulling latest dotfiles..."
        pushd "$DOTFILES_DIR" >/dev/null
        do_run git pull || log_warning "Could not pull latest dotfiles"
        popd >/dev/null
        mark_done "clone_dotfiles"
        return 0
    fi
    log_info "Cloning dotfiles from $DOTFILES_REPO..."
    do_run mkdir -p "$(dirname "$DOTFILES_DIR")"
    if ! do_run git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
        log_error "Failed to clone dotfiles"
        return 1
    fi
    log_success "Dotfiles cloned to $DOTFILES_DIR"
    mark_done "clone_dotfiles"
}

install_packages() {
    should_run "install_packages" || return 0
    log_info "Installing packages from Brewfile..."
    local brewfile="$DOTFILES_DIR/Brewfile"
    if [[ ! -f "$brewfile" ]] && [[ "$DRY_RUN" != "true" ]]; then
        log_error "Brewfile not found at $brewfile"
        return 1
    fi
    echo ""
    log_warning "Please ensure you are logged into the Mac App Store"
    wait_for_user "Press Enter when ready to continue..."
    echo ""
    if ! do_run brew bundle --file="$brewfile"; then
        log_error "brew bundle failed — some packages may not have installed; check output above"
        return 1
    fi
    log_success "Brewfile installation complete"
    mark_done "install_packages"
}

install_npm_packages() {
    should_run "install_npm_packages" || return 0
    log_info "Installing npm global packages..."
    if ! command_exists npm && [[ "$DRY_RUN" != "true" ]]; then
        log_error "npm not found — skipping npm packages"
        return 1
    fi
    local pkg failed=0
    for pkg in "${NPM_GLOBALS[@]}"; do
        log_info "Installing $pkg..."
        if ! do_run npm install -g "$pkg"; then
            log_error "npm install -g $pkg failed"
            failed=$((failed + 1))
        fi
    done
    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    log_success "npm packages installed"
    mark_done "install_npm_packages"
}

install_zsh_plugins() {
    should_run "install_zsh_plugins" || return 0
    log_info "Installing Zsh plugins..."
    do_run mkdir -p "$ZSH_CUSTOM"
    local failed=0

    if [[ -d "$ZSH_CUSTOM/zsh-autosuggestions" ]]; then
        log_success "zsh-autosuggestions already installed"
    else
        log_info "Cloning zsh-autosuggestions..."
        if ! do_run git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/zsh-autosuggestions"; then
            log_error "Failed to clone zsh-autosuggestions"
            failed=$((failed + 1))
        fi
    fi

    if [[ -d "$ZSH_CUSTOM/zsh-syntax-highlighting" ]]; then
        log_success "zsh-syntax-highlighting already installed"
    else
        log_info "Cloning zsh-syntax-highlighting..."
        if ! do_run git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/zsh-syntax-highlighting"; then
            log_error "Failed to clone zsh-syntax-highlighting"
            failed=$((failed + 1))
        fi
    fi

    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    log_success "Zsh plugins installed"
    mark_done "install_zsh_plugins"
}

create_symlinks() {
    should_run "create_symlinks" || return 0
    log_info "Creating symlinks..."
    do_run mkdir -p "$HOME/.zsh"
    do_run mkdir -p "$HOME/.config/starship"

    local -a dir_links=(
        "$DOTFILES_DIR/.config/nvim:$HOME/.config/nvim"
        "$DOTFILES_DIR/scripts:$HOME/scripts"
    )

    local -a file_links=(
        "$DOTFILES_DIR/zsh/.zshrc:$HOME/.zshrc"
        "$DOTFILES_DIR/zsh/.alias.sh:$HOME/.zsh/.alias.sh"
        "$DOTFILES_DIR/zsh/.functions.sh:$HOME/.zsh/.functions.sh"
        "$DOTFILES_DIR/zsh/.motd.sh:$HOME/.zsh/.motd.sh"
        "$DOTFILES_DIR/zsh/starship.toml:$HOME/.config/starship/starship.toml"
    )

    local -a optional_links=(
        "$DOTFILES_DIR/zsh/.zsh-scripts:$HOME/.zsh-scripts"
    )

    local link src dest
    for link in "${dir_links[@]}"; do
        IFS=":" read -r src dest <<< "$link"
        if [[ -d "$src" ]]; then
            backup_and_link "$src" "$dest"
        else
            log_warning "Directory not found (skipping): $src"
        fi
    done

    for link in "${file_links[@]}"; do
        IFS=":" read -r src dest <<< "$link"
        if [[ -f "$src" ]]; then
            backup_and_link "$src" "$dest"
        else
            log_warning "File not found (skipping): $src"
        fi
    done

    for link in "${optional_links[@]}"; do
        IFS=":" read -r src dest <<< "$link"
        if [[ -e "$src" ]]; then
            backup_and_link "$src" "$dest"
        fi
    done

    log_success "Symlinks created"
    mark_done "create_symlinks"
}

configure_shell() {
    should_run "configure_shell" || return 0
    log_info "Configuring shell..."
    if [[ ! -x "$BREW_ZSH" ]] && [[ "$DRY_RUN" != "true" ]]; then
        log_error "Homebrew zsh not found at $BREW_ZSH"
        return 1
    fi
    sudo_append_to_file /etc/shells "$BREW_ZSH"
    if [[ "$SHELL" != "$BREW_ZSH" ]]; then
        log_info "Changing default shell to $BREW_ZSH..."
        if ! do_run chsh -s "$BREW_ZSH"; then
            log_error "Failed to change default shell"
            return 1
        fi
        log_success "Default shell changed to $BREW_ZSH"
    else
        log_success "Default shell already set to $BREW_ZSH"
    fi
    mark_done "configure_shell"
}

verify_starship() {
    should_run "verify_starship" || return 0
    log_info "Verifying Starship configuration..."
    local issues=0
    if ! command_exists starship; then
        log_error "Starship not installed"
        issues=$((issues + 1))
    else
        log_success "Starship binary installed"
    fi

    local starship_config="$HOME/.config/starship/starship.toml"
    if [[ -L "$starship_config" && -f "$starship_config" ]]; then
        log_success "Starship config linked correctly"
    else
        log_warning "Starship config may not be linked correctly at $starship_config"
        issues=$((issues + 1))
    fi

    if [[ -f "$HOME/.zshrc" ]] && grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
        log_success "Starship init found in .zshrc"
    else
        log_warning "Starship init not found in .zshrc"
        issues=$((issues + 1))
    fi

    if [[ -d "$HOME/Library/Fonts" ]] && find "$HOME/Library/Fonts" -iname "*Monaspace*" -print -quit 2>/dev/null | grep -q .; then
        log_success "Monaspace font detected (user)"
    elif [[ -d "/Library/Fonts" ]] && find "/Library/Fonts" -iname "*Monaspace*" -print -quit 2>/dev/null | grep -q .; then
        log_success "Monaspace font detected (system)"
    else
        log_warning "Monaspace font may not be installed — check Font Book"
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "Starship verification complete — no issues found"
    else
        log_warning "Starship verification found $issues potential issue(s)"
    fi
    mark_done "verify_starship"
}

cleanup() {
    should_run "cleanup" || return 0
    log_info "Running cleanup..."
    do_run brew cleanup 2>/dev/null || log_warning "Brew cleanup had warnings"
    log_success "Cleanup complete"
    mark_done "cleanup"
}

# =============================================================================
# USAGE / SUMMARY
# =============================================================================
print_usage() {
    cat <<'USAGE'
macOS Setup Script (Apple Silicon only)

Usage: ./setup.sh [OPTIONS]

OPTIONS:
  -y, --yes              Skip interactive prompts (Xcode CLI, App Store login).
                         Sudo and chsh may still prompt — those are out of our control.
  -n, --dry-run          Print every action without executing. No side effects.
  -r, --resume [STEP]    Skip steps already recorded in ~/.mac-setup-state.
                         Optional STEP synthesizes state so the run starts at STEP.
  -h, --help             Show this message and exit.

STEPS (in order):
  install_xcode_cli, install_homebrew, clone_dotfiles, install_packages,
  install_npm_packages, install_zsh_plugins, create_symlinks, configure_shell,
  verify_starship, cleanup

LOG:   ~/mac-setup.log    (plain text)
STATE: ~/.mac-setup-state (delete to start fresh)
USAGE
}

print_summary() {
    echo ""
    echo "=============================================="
    echo "           SETUP COMPLETE"
    echo "=============================================="
    echo ""
    if [[ ${#FAILURES[@]} -gt 0 ]]; then
        printf '\033[0;33mWarnings/Failures:\033[0m\n'
        local failure
        for failure in "${FAILURES[@]}"; do
            echo "  - $failure"
        done
        echo ""
    else
        printf '\033[0;32mNo errors encountered!\033[0m\n'
        echo ""
    fi
    echo "Log file:   $LOG_FILE"
    echo "State file: $STATE_FILE (delete to start fresh)"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open WezTerm and set font to 'Monaspace'"
    echo "  3. Verify your prompt displays correctly"
    echo ""
    echo "Installed AI CLIs:"
    echo "  - claude  (Anthropic Claude Code)"
    echo "  - gemini  (Google Gemini CLI)"
    echo "  - codex   (OpenAI Codex CLI)"
    echo ""
}

# =============================================================================
# ARG PARSING
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)      SKIP_PROMPTS=true; shift ;;
            -n|--dry-run)  DRY_RUN=true; shift ;;
            -r|--resume)
                RESUME=true
                if [[ $# -ge 2 ]] && [[ "${2:-}" != -* ]] && [[ -n "${2:-}" ]]; then
                    RESUME_FROM="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            -h|--help)     print_usage; exit 0 ;;
            *)
                echo "Unknown option: $1" >&2
                print_usage
                exit 2
                ;;
        esac
    done
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    parse_args "$@"

    if [[ "$(uname -m)" != "arm64" ]]; then
        echo "Error: this script targets Apple Silicon (arm64) only. Detected: $(uname -m)" >&2
        exit 1
    fi

    : > "$LOG_FILE"
    echo "=== macOS Setup Log — $(date) ===" >> "$LOG_FILE"

    if [[ "$RESUME" != "true" ]]; then
        : > "$STATE_FILE"
    fi
    [[ -f "$STATE_FILE" ]] || touch "$STATE_FILE"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN — no side effects will occur"
    fi

    if [[ -n "$RESUME_FROM" ]]; then
        local found=false step
        : > "$STATE_FILE"
        for step in "${STEP_ORDER[@]}"; do
            if [[ "$step" == "$RESUME_FROM" ]]; then
                found=true
                break
            fi
            echo "$step" >> "$STATE_FILE"
        done
        if [[ "$found" != "true" ]]; then
            log_error "--resume STEP not recognized: $RESUME_FROM"
            log_error "Valid steps: ${STEP_ORDER[*]}"
            exit 2
        fi
        log_info "Resuming from step: $RESUME_FROM"
    fi

    echo ""
    echo "=============================================="
    echo "       macOS Development Setup"
    echo "       Architecture: arm64 (Apple Silicon)"
    echo "       Homebrew prefix: $HOMEBREW_PREFIX"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "       Mode: DRY RUN"
    fi
    echo "=============================================="
    echo ""

    install_xcode_cli    || true
    install_homebrew     || true
    clone_dotfiles       || true
    install_packages     || true
    install_npm_packages || true
    install_zsh_plugins  || true
    create_symlinks      || true
    configure_shell      || true
    verify_starship      || true
    cleanup              || true
    print_summary
}

main "$@"
