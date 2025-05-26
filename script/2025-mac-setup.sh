#!/bin/zsh
# macOS Bootstrap Script for @dissidentcode
# Fully configures a dev environment: installs tools, links dotfiles, sets shell, and applies prompt.

### ─── SETUP ────────────────────────────────────────────────────────
set -uo pipefail # We skip `-e` to allow script continuation on failures

LOGFILE="$HOME/bootstrap.log"
DOTFILES="$HOME/git_repos/dot-files"
REPO_URL="https://github.com/dissidentcode/dot-files"

exec > >(tee -a "$LOGFILE") 2>&1

echo "\n📦 Starting macOS bootstrap script..."

### ─── CLONE DOTFILES ───────────────────────────────────────────────
if [[ ! -d "$DOTFILES" ]]; then
  echo "📥 Cloning dotfiles from GitHub..."
  git clone "$REPO_URL" "$DOTFILES" || echo "❌ Failed to clone dotfiles" >>"$LOGFILE"
else
  echo "✅ Dotfiles already cloned."
fi

### ─── HOMEBREW INSTALL ─────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$($(brew --prefix)/bin/brew shellenv)"
else
  echo "✅ Homebrew already installed."
fi

### ─── BREW TAPS AND PACKAGES ───────────────────────────────────────
brew tap homebrew/cask-fonts || echo "⚠️ Failed to tap fonts cask" >>"$LOGFILE"

BREW_PACKAGES=(
  ansible bat btop colordiff diff-so-fancy duf dust eza fd ffmpeg fio fzf gifsicle highlight
  imagemagick jpegoptim jq lsd neovim onefetch pandoc p7zip poppler ranger tealdeer tree unzip
  webp xz zsh starship aria2 glow media-info trash z
)

CASK_APPS=(iterm2 visual-studio-code font-jetbrains-mono-nerd-font)

echo "🔧 Installing CLI packages..."
for pkg in "${BREW_PACKAGES[@]}"; do
  brew list "$pkg" &>/dev/null || brew install "$pkg" || echo "❌ Failed: $pkg" >>"$LOGFILE"
done

echo "💻 Installing GUI casks..."
for app in "${CASK_APPS[@]}"; do
  brew list --cask "$app" &>/dev/null || brew install --cask "$app" || echo "❌ Failed: $app" >>"$LOGFILE"
done

### ─── SYMLINKING FILES ─────────────────────────────────────────────
CONFIG_TARGETS=(
  "$DOTFILES/.config/nvim:$HOME/.config/nvim"
  "$DOTFILES/.config/sketchybar:$HOME/.config/sketchybar"
  "$DOTFILES/.config/lf:$HOME/.config/lf"
  "$DOTFILES/.config/starship:$HOME/.config/starship"
  "$DOTFILES/scripts:$HOME/scripts"
)

FILE_TARGETS=(
  "$DOTFILES/zsh/.zshrc:$HOME/.zshrc"
  "$DOTFILES/zsh/.alias.sh:$HOME/.zsh/.alias.sh"
  "$DOTFILES/zsh/.functions.sh:$HOME/.zsh/.functions.sh"
  "$DOTFILES/zsh/.motd.sh:$HOME/.zsh/.motd.sh"
  "$DOTFILES/zsh/.zsh-scripts:$HOME/.zsh-scripts"
  "$DOTFILES/.config/.aerospace.toml:$HOME/.aerospace.toml"
)

backup_and_link() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  [[ -e "$dest" && ! -L "$dest" ]] && mv "$dest" "${dest}.backup.$(date +%s)"
  ln -sfn "$src" "$dest"
  echo "🔗 Linked $dest → $src"
}

for pair in "${CONFIG_TARGETS[@]}"; do
  IFS=":" read -r src dest <<<"$pair"
  backup_and_link "$src" "$dest"
done

for pair in "${FILE_TARGETS[@]}"; do
  IFS=":" read -r src dest <<<"$pair"
  backup_and_link "$src" "$dest"
done

### ─── ZSH + STARSHIP INIT ──────────────────────────────────────────
echo "💡 Initializing shell environment..."
mkdir -p ~/.zsh
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Avoid duplicate lines in .zshrc
if ! grep -q 'starship init zsh' ~/.zshrc; then
  echo 'eval "$(starship init zsh)"' >>~/.zshrc
fi

### ─── ZSH DEFAULT SHELL ────────────────────────────────────────────
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [[ "$SHELL" != "$BREW_ZSH" ]]; then
  grep -Fxq "$BREW_ZSH" /etc/shells || echo "$BREW_ZSH" | sudo tee -a /etc/shells
  chsh -s "$BREW_ZSH"
  echo "✅ Default shell set to Homebrew Zsh"
else
  echo "✅ Default shell already set"
fi

### ─── PLUGINS CHECK ────────────────────────────────────────────────
ZSH_CUSTOM="$HOME/.zsh"
PLUGINS=(
  "https://github.com/zsh-users/zsh-autosuggestions:$ZSH_CUSTOM/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting:$ZSH_CUSTOM/zsh-syntax-highlighting"
)

for plugin in "${PLUGINS[@]}"; do
  IFS=":" read -r url dir <<<"$plugin"
  if [[ ! -d "$dir" ]]; then
    git clone "$url" "$dir" || echo "❌ Failed to clone $url" >>"$LOGFILE"
  else
    echo "✅ Plugin present: $dir"
  fi

  base=$(basename "$dir")
  if ! grep -q "$base" ~/.zshrc; then
    echo "source $dir/$base.zsh" >>~/.zshrc
  fi

done

### ─── DONE ─────────────────────────────────────────────────────────
echo "\n✅ Bootstrap complete. Log: $LOGFILE"
echo "Run 'exec zsh' or restart terminal to apply all changes."
