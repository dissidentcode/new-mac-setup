# Mac Development Environment Setup

Automates the setup of a new Mac for development. Installs essential tools, configures the shell with a custom Starship prompt, and links dotfiles from a separate repository.

## Prerequisites

- Administrative access to your Mac
- Logged into the Mac App Store
- Internet connection

## Usage

```bash
# Clone and run
git clone https://github.com/dissidentcode/new-mac-setup.git
cd new-mac-setup
./setup.sh
```

The script will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Clone your [dotfiles repo](https://github.com/dissidentcode/dot-files)
4. Install all packages from the Brewfile
5. Install npm global packages (Claude Code, Gemini CLI)
6. Clone zsh plugins
7. Create symlinks for configs
8. Set Homebrew zsh as default shell

## What Gets Installed

### Terminal & Shell
- **WezTerm** - GPU-accelerated terminal emulator
- **Zsh** - Default shell with Homebrew's latest version
- **Starship** - Cross-shell prompt with custom config
- **zsh-autosuggestions** - Command suggestions from history
- **zsh-syntax-highlighting** - Syntax highlighting in terminal
- **z** - Directory navigation based on frecency
- **atuin** - Magical shell history search and sync

### CLI Tools
| Category | Tools |
|----------|-------|
| File Operations | `bat`, `eza`, `lsd`, `fd`, `fzf`, `ripgrep`, `tree`, `trash`, `ranger`, `lf`, `yazi` |
| Git | `git`, `gh`, `lazygit`, `diff-so-fancy`, `onefetch` |
| System Info | `btop`, `duf`, `dust`, `neofetch` |
| Text/Data | `jq`, `pandoc`, `tealdeer`, `glow` |
| Media | `ffmpeg`, `imagemagick`, `gifsicle`, `jpegoptim`, `optipng`, `webp`, `chafa`, `viu` |
| Network | `aria2`, `speedtest-cli`, `wifi-password`, `yt-dlp` |
| Archives | `p7zip`, `unar`, `zip`, `atool`, `rar` |

### AI Tools
- **Claude Code CLI** - Anthropic's AI coding assistant
- **Gemini CLI** - Google's AI assistant
- **aichat** - All-in-one AI chat CLI

### Development
- **Neovim** - Hyper-extensible text editor
- **Visual Studio Code** - Code editor
- **Node.js** - JavaScript runtime
- **Python** - Python interpreter
- **Go** - Go programming language
- **Docker** - Containerization
- **tmux** - Terminal multiplexer

### macOS Utilities
- **Aerospace** - Tiling window manager
- **SketchyBar** - Custom menu bar
- **borders** - Window borders
- **Alt-Tab** - Windows-like window switching
- **Hidden Bar** - Menu bar cleanup
- **Dropover** - Drag and drop shelf
- **AlDente** - Battery charge limiter
- **CleanMyMac** - System cleaner
- **Raycast** - Productivity launcher

### Fonts
- JetBrainsMono Nerd Font (primary)
- Fira Code, Hack Nerd Font, Monaspace, SF Mono, SF Pro

## Configuration

The script links configs from the [dotfiles repo](https://github.com/dissidentcode/dot-files):

| Source | Destination |
|--------|-------------|
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.alias.sh` | `~/.zsh/.alias.sh` |
| `zsh/.functions.sh` | `~/.zsh/.functions.sh` |
| `zsh/.motd.sh` | `~/.zsh/.motd.sh` |
| `zsh/starship.toml` | `~/.config/starship/starship.toml` |
| `.config/nvim` | `~/.config/nvim` |
| `.config/sketchybar` | `~/.config/sketchybar` |
| `.config/lf` | `~/.config/lf` |
| `.config/.aerospace.toml` | `~/.aerospace.toml` |
| `scripts` | `~/scripts` |

## Post-Install

1. Restart terminal or run `exec zsh`
2. Set WezTerm font to **JetBrainsMono Nerd Font**
3. Configure atuin: `atuin login` or `atuin register`
4. Test Claude Code: `claude`
5. Test Gemini: `gemini`

## Customization

- **Add/remove packages**: Edit `~/git_repos/dot-files/Brewfile`
- **Update package list**: Run `brew bundle dump --file=~/git_repos/dot-files/Brewfile --force`
- **Shell config**: Edit files in `~/git_repos/dot-files/zsh/`
- **Prompt**: Edit `~/git_repos/dot-files/zsh/starship.toml`

## Troubleshooting

Check the log file at `~/mac-setup.log` for any errors.

Common issues:
- **App Store apps fail**: Ensure you're logged in before running
- **Prompt looks wrong**: Check WezTerm is using a Nerd Font
- **Shell not changed**: Run `chsh -s /opt/homebrew/bin/zsh` manually

## License

MIT

## Contact

github.carry327@passinbox.com
