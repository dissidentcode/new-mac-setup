#!/bin/bash

# ------------------------------------------------------------
# Script: setup_dev_env.sh
# Description: Automates the setup of a development environment on macOS.
# Author: DissidentCode (github.carry327@passinbox.com)
# Created: 2023-10-XX
# ------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# if an undefined variable is used, and to catch errors in pipelines.
set -euo pipefail
IFS=$'\n\t'

# Initialize failure log
failure_log=""

# Function to log failures
log_failure() {
    failure_log+="$1\n"
    echo -e "\033[0;31mERROR:\033[0m $1"
}

# Function to log informational messages
log_info() {
    echo -e "\033[0;34mINFO:\033[0m $1"
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command -v brew &>/dev/null; then
        log_info "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || log_failure "Homebrew installation failed."
    else
        log_info "Homebrew is already installed."
    fi

    # Detect architecture and set Homebrew path
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        BREW_PATH="/opt/homebrew"
    else
        BREW_PATH="/usr/local"
    fi

    # Configure Homebrew environment
    if ! grep -q 'eval "$('"$BREW_PATH"'/bin/brew shellenv)"' ~/.zprofile; then
        echo 'eval "$('"$BREW_PATH"'/bin/brew shellenv)"' >> ~/.zprofile
        log_info "Homebrew environment added to ~/.zprofile."
    else
        log_info "Homebrew environment already present in ~/.zprofile."
    fi

    # Apply Homebrew environment
    eval "$("$BREW_PATH"/bin/brew shellenv)" || log_failure "Homebrew initialization failed."
    log_info "Homebrew environment configured."
}

# Function to update and upgrade Homebrew
update_upgrade_brew() {
    log_info "Updating Homebrew..."
    brew update || log_failure "Homebrew update failed."

    log_info "Upgrading Homebrew packages..."
    brew upgrade || log_failure "Homebrew upgrade failed."
}

# Function to install Xcode Command Line Tools
install_xcode_cli() {
    if ! xcode-select -p &>/dev/null; then
        log_info "Xcode Command Line Tools not found. Installing..."
        xcode-select --install

        # Wait until installation completes
        until xcode-select -p &>/dev/null; do
            log_info "Waiting for Xcode Command Line Tools to install..."
            sleep 5
        done
        log_info "Xcode Command Line Tools installed."
    else
        log_info "Xcode Command Line Tools are already installed."
    fi
}

# Function to install a Homebrew formula if not installed
install_formula() {
    local formula="$1"
    if ! brew list --formula | grep -q "^${formula}\$"; then
        brew install "$formula" || log_failure "Installation of formula '$formula' failed."
    else
        log_info "Formula '$formula' is already installed."
    fi
}

# Function to install a Homebrew cask if not installed
install_cask() {
    local cask="$1"
    if ! brew list --cask | grep -q "^${cask}\$"; then
        brew install --cask "$cask" || log_failure "Installation of cask '$cask' failed."
    else
        log_info "Cask '$cask' is already installed."
    fi
}

# Function to install Mac App Store (mas) apps
install_mas_app() {
    local app_name="$1"
    # Search for the app and retrieve the first matching ID
    local app_id
    app_id=$(mas search "$app_name" | grep -E '^\d+' | awk '{print $1}' | head -n1)

    if [[ -n "$app_id" ]]; then
        if ! mas list | grep -q "^$app_id "; then
            mas install "$app_id" || log_failure "Installation of App Store app '$app_name' (ID: $app_id) failed."
            log_info "Installed '$app_name' from App Store (ID: $app_id)."
        else
            log_info "App Store app '$app_name' is already installed."
        fi
    else
        log_failure "App Store app '$app_name' not found or no matching ID."
    fi
}

# Function to backup and configure Zsh
configure_zsh() {
    log_info "Configuring Zsh..."

    # Install Zsh via Homebrew if not installed
    install_formula "zsh"

    # Change default shell to Homebrew's Zsh if not already
    BREW_ZSH_PATH="/opt/homebrew/bin/zsh"
    if [[ "$SHELL" != "$BREW_ZSH_PATH" ]]; then
        if grep -Fxq "$BREW_ZSH_PATH" /etc/shells; then
            chsh -s "$BREW_ZSH_PATH" || log_failure "Changing default shell to Zsh failed."
            log_info "Default shell changed to Zsh."
        else
            log_failure "Zsh path '$BREW_ZSH_PATH' not found in /etc/shells."
        fi
    else
        log_info "Default shell is already Zsh."
    fi

    # Clone Zsh plugins
    ZSH_CUSTOM="$HOME/.zsh"

    mkdir -p "$ZSH_CUSTOM"

    install_zsh_plugin() {
        local repo_url="$1"
        local dest_dir="$2"
        if [ ! -d "$dest_dir" ]; then
            git clone "$repo_url" "$dest_dir" || log_failure "Cloning repository '$repo_url' failed."
            log_info "Installed Zsh plugin from '$repo_url'."
        else
            log_info "Zsh plugin '$dest_dir' is already installed."
        fi
    }

    install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/zsh-autosuggestions"
    install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/zsh-syntax-highlighting"
    install_zsh_plugin "https://github.com/rupa/z.git" "$ZSH_CUSTOM/z"

    # Backup existing .zshrc
    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc ~/.zshrc.bak_$(date +%Y%m%d_%H%M%S)
        log_info "Existing .zshrc backed up."
    fi

    # Download new .zshrc configuration
    curl -fsSL https://raw.githubusercontent.com/dissidentcode/dot-files/master/.zshrc -o ~/.zshrc || log_failure "Downloading new .zshrc failed."
    log_info "New .zshrc configuration applied."
}

# Function to install Zsh plugins sources (optional, can be expanded)
install_zsh_plugins() {
    log_info "Installing Zsh plugins..."

    # Plugins are already cloned in configure_zsh function
    # Ensure they are sourced in .zshrc
    if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
        echo "source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
    fi

    if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
        echo "source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
    fi

    if ! grep -q "source ~/.zsh/z.sh" ~/.zshrc; then
        echo "source ~/.zsh/z.sh" >> ~/.zshrc
    fi

    log_info "Zsh plugins configured in .zshrc."
}

# Main script execution starts here

log_info "Starting Development Environment Setup..."

# Install Xcode Command Line Tools
install_xcode_cli

# Install Homebrew
install_homebrew

# Update and upgrade Homebrew
update_upgrade_brew

# Define Homebrew Casks and Formulas
casks=(
    iterm2
    raycast
    visual-studio-code
    font-jetbrains-mono-nerd-font
    aldente
    alt-tab
    brave-browser
    cheatsheet
    cleanmymac
    logseq
    utm
)

formulas=(
    ansible
    aria2
    asciinema
    bat
    btop
    colordiff
    diff-so-fancy
    duf
    dust
    eza
    fd
    ffmpeg
    fio
    fzf
    gifsicle
    git
    imagemagick
    jpegoptim
    jq
    neofetch
    neovim
    optipng
    lsd
    pandoc
    ranger
    rar
    speedtest-cli
    starship
    tealdeer
    trash
    tree
    unar
    webp
    wifi-password
    z
    zip
    node
    python
    mas
)

# Install Homebrew formulas
log_info "Installing Homebrew formulas..."
for formula in "${formulas[@]}"; do
    install_formula "$formula"
done

# Install Homebrew casks
log_info "Installing Homebrew casks..."
for cask in "${casks[@]}"; do
    install_cask "$cask"
done

# Configure Zsh and install plugins
configure_zsh
install_zsh_plugins

# Install Mac App Store applications
declare -a mas_apps=("Hidden Bar" "DropOver")
log_info "Installing Mac App Store applications via mas..."
for app in "${mas_apps[@]}"; do
    install_mas_app "$app"
done

# Homebrew cleanup
log_info "Cleaning up Homebrew..."
brew cleanup || log_failure "Homebrew cleanup failed."

# Final messages
log_info "Development Environment Setup Complete!"

if [[ -n "$failure_log" ]]; then
    echo -e "\n\033[0;31mSome errors occurred during the setup:\033[0m"
    echo -e "$failure_log"
    echo -e "You may need to address these issues manually."
else
    echo -e "\033[0;32mAll tasks completed successfully!\033[0m"
fi

# Prompt user to restart the terminal or source the new .zshrc
echo -e "\nYou may need to restart your terminal or run 'source ~/.zshrc' to apply all changes."
```

---

### **Script Breakdown and Key Enhancements**

1. **Script Header and Metadata:**
   - Added a descriptive header with metadata for clarity and future reference.

2. **Strict Error Handling:**
   - Enabled `set -euo pipefail` and set `IFS` to handle errors gracefully and prevent unexpected behaviors.

3. **Logging Functions:**
   - `log_failure`: Logs errors in red for visibility.
   - `log_info`: Logs informational messages in blue.

4. **Homebrew Installation and Configuration:**
   - Checks for Homebrew presence and installs it if missing.
   - Automatically detects system architecture to set the correct Homebrew path.
   - Adds Homebrew to `.zprofile` if not already present and applies the environment.

5. **Updating and Upgrading Homebrew:**
   - Runs `brew update` and `brew upgrade` with error handling.

6. **Xcode Command Line Tools Installation:**
   - Checks for Xcode Command Line Tools and installs them if missing, waiting until installation completes.

7. **Installation of Homebrew Formulas and Casks:**
   - Defined `casks` and `formulas` arrays for organized and maintainable installations.
   - Utilizes loop functions `install_formula` and `install_cask` to install each item if not already installed.

8. **Zsh Configuration and Plugin Installation:**
   - Installs Zsh via Homebrew and sets it as the default shell.
   - Clones essential Zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, and `z`) into a custom directory.
   - Backs up existing `.zshrc` and applies a new configuration from a remote repository.
   - Ensures that cloned plugins are sourced in `.zshrc` to activate them.

9. **Mac App Store Applications Installation (`mas`):**
   - Defines a `mas_apps` array with desired App Store application names.
   - Utilizes the `install_mas_app` function to search for each app and install the first matching result.
   - Handles cases where the app is already installed or not found, logging appropriate messages.

10. **Homebrew Cleanup:**
    - Runs `brew cleanup` to remove outdated versions and unnecessary files.

11. **Final Messages and User Guidance:**
    - Informs the user upon successful completion or alerts them to any errors that occurred during the setup.
    - Suggests restarting the terminal or sourcing the new `.zshrc` to apply changes fully.

### **Important Considerations**

- **`mas` App IDs:**
  - Since you don't have specific `mas` IDs, the script attempts to fetch them by searching the App Store using app names. This method relies on accurate app names and the first search result being the desired application. It's crucial to verify the installed apps post-execution to ensure correctness.
  - If you encounter issues where the wrong app gets installed, consider manually retrieving the correct `mas` IDs and updating the `mas_apps` array accordingly.

- **Zsh Configuration:**
  - The script backs up your existing `.zshrc` to prevent loss of personal configurations.
  - It downloads a new `.zshrc` from your specified GitHub repository. Ensure that this configuration aligns with your preferences to avoid overwriting essential settings.

- **Execution Permissions:**
  - Before running the script, make sure it has execution permissions. You can set this using:
    ```bash
    chmod +x setup_dev_env.sh
    ```

- **Testing:**
  - It's recommended to run this script in a controlled environment or incrementally to ensure each section performs as expected, especially if making significant changes to your system.

- **Security:**
  - Always review scripts, especially those that execute commands fetched from the internet (`curl`), to ensure they don't perform unintended or harmful actions.

### **Executing the Script**

1. **Save the Script:**
   - Save the script to a file, for example, `setup_dev_env.sh`.

2. **Make the Script Executable:**
   ```bash
   chmod +x setup_dev_env.sh
   ```

3. **Run the Script:**
   ```bash
   ./setup_dev_env.sh
   ```

4. **Follow Prompts:**
   - The script may prompt you for your password to install certain applications or make system changes. Ensure you have the necessary permissions.

5. **Post-Execution:**
   - After completion, restart your terminal or source your `.zshrc` to apply all configurations:
     ```bash
     source ~/.zshrc

Feel free to reach out if you encounter any issues or need further customization of the script!
