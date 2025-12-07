#!/bin/zsh
# macOS Bootstrap Script for @dissidentcode
# Sets up a development environment by installing tools, linking config files, and configuring the shell.

set -euo pipefail

### ─── CONFIGURATION ───────────────────────────────────────────────
DOTFILES="$HOME/git_repos/dot-files"
REPO_URL="https://github.com/dissidentcode/dot-files"
LOGFILE="$HOME/bootstrap.log"

# Directory symlinks to create: dotfiles on the left, targets on the right
CONFIG_TARGETS=(
  "$DOTFILES/.config/nvim:$HOME/.config/nvim"
  "$DOTFILES/.config/sketchybar:$HOME/.config/sketchybar"
  "$DOTFILES/.config/lf:$HOME/.config/lf"
  "$DOTFILES/.config/starship:$HOME/.config/starship"
  "$DOTFILES/scripts:$HOME/scripts"
)

# File symlinks to create: source in repo, target in system
FILE_TARGETS=(
  "$DOTFILES/zsh/.zshrc:$HOME/.zshrc"
  "$DOTFILES/zsh/.alias.sh:$HOME/.zsh/.alias.sh"
  "$DOTFILES/zsh/.functions.sh:$HOME/.zsh/.functions.sh"
  "$DOTFILES/zsh/.motd.sh:$HOME/.zsh/.motd.sh"
  "$DOTFILES/zsh/.zsh-scripts:$HOME/.zsh-scripts"
  "$DOTFILES/.config/.aerospace.toml:$HOME/.aerospace.toml"
)

# Log everything to a file for post-run review
exec > >(tee -a "$LOGFILE") 2>&1

### ─── GIT REPO CLONE ─────────────────────────────────────────────
# Clone the dotfiles repo if it doesn't exist
if [[ ! -d "$DOTFILES" ]]; then
  echo "📥 Cloning dotfiles repo..."
  git clone "$REPO_URL" "$DOTFILES"
else
  echo "✅ Dotfiles repo already present."
fi

### ─── HOMEBREW INSTALL ───────────────────────────────────────────
# Ensure Homebrew is installed before attempting any package installs
if ! command -v brew >/dev/null; then
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$($(brew --prefix)/bin/brew shellenv)"
else
  echo "✅ Homebrew already installed."
fi

### ─── INSTALL PACKAGES ───────────────────────────────────────────
BREW_PACKAGES=(
  ansible bat btop colordiff diff-so-fancy duf dust eza fd ffmpeg fio fzf gifsicle highlight imagemagick
  jpegoptim jq lsd neovim onefetch pandoc p7zip poppler ranger tealdeer tree unzip webp xz zsh starship
  aria2 glow media-info trash z
)

CASK_APPS=(iterm2 visual-studio-code)
MAS_APPS=(441258766) # Magnet (example)

echo "🔧 Installing brew packages..."
for pkg in "${BREW_PACKAGES[@]}"; do
  brew list "$pkg" &>/dev/null || brew install "$pkg" || echo "⚠️ Failed to install $pkg" >>"$LOGFILE"
done

brew tap homebrew/cask-fonts
for app in "${CASK_APPS[@]}"; do
  brew list --cask "$app" &>/dev/null || brew install --cask "$app" || echo "⚠️ Failed to install $app" >>"$LOGFILE"
done

# macOS App Store installs via mas-cli
if command -v mas >/dev/null; then
  echo "🛍️ Installing Mac App Store apps..."
  for mas_id in "${MAS_APPS[@]}"; do
    mas install "$mas_id" || echo "⚠️ Failed to install MAS app $mas_id" >>"$LOGFILE"
  done
else
  echo "⚠️ mas not installed; skipping Mac App Store installs."
fi

### ─── INSTALL PISTOL MANUALLY ────────────────────────────────────
# pistol is not available on brew, so install via Go
if ! command -v pistol >/dev/null; then
  if command -v go >/dev/null; then
    echo "📦 Installing pistol (via go install)..."
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"

    go install github.com/doronbehar/pistol/cmd/pistol@latest || echo "⚠️ Failed to install pistol via go" >>"$LOGFILE"

    grep -q 'export PATH="$HOME/go/bin' ~/.zshrc || {
      echo 'export PATH="$HOME/go/bin:$PATH"' >>~/.zshrc
    }
  else
    echo "⚠️ Go is not installed; skipping pistol." >>"$LOGFILE"
  fi
else
  echo "✅ pistol already installed."
fi

### ─── SYMLINK LOGIC ──────────────────────────────────────────────
# Backup old file if it exists and isn't a symlink, then link new one
backup_and_link() {
  local src="$1"
  local dest="$2"
  local ts=$(date +%Y%m%d%H%M%S)

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "📦 Backing up $dest → ${dest}.backup.$ts"
    mv "$dest" "${dest}.backup.$ts"
  fi

  ln -sfn "$src" "$dest"
  echo "🔗 Linked $dest → $src"
}

# Link all directories
for pair in "${CONFIG_TARGETS[@]}"; do
  IFS=":" read src dest <<<"$pair"
  backup_and_link "$src" "$dest"
done

# Link all individual files
for pair in "${FILE_TARGETS[@]}"; do
  IFS=":" read src dest <<<"$pair"
  backup_and_link "$src" "$dest"
done

### ─── ZSH + STARSHIP INIT ────────────────────────────────────────
echo "✨ Initializing Starship and Zsh prompt"
echo 'eval "$(starship init zsh)"' >>~/.zshrc
mkdir -p ~/.zsh

### ─── SET DEFAULT SHELL TO ZSH ───────────────────────────────────
BREW_ZSH_PATH="$(brew --prefix)/bin/zsh"
if [[ "$SHELL" != "$BREW_ZSH_PATH" ]]; then
  if ! grep -Fxq "$BREW_ZSH_PATH" /etc/shells; then
    echo "$BREW_ZSH_PATH" | sudo tee -a /etc/shells
  fi
  chsh -s "$BREW_ZSH_PATH"
  echo "✅ Default shell changed to Homebrew Zsh: $BREW_ZSH_PATH"
else
  echo "✅ Default shell already set to Homebrew Zsh."
fi

### ─── ALL DONE ───────────────────────────────────────────────────
echo "✅ Bootstrap complete. Run 'exec zsh' or restart your terminal to activate changes."
echo "📝 Log written to $LOGFILE"
