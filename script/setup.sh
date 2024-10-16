#!/bin/bash

# Preparing a new Mac for development
# Script Created by DissidentCode github.carry327@passinbox.com

echo "Starting Development Environment Setup..."
failure_log=""

# Check if Command Line Tools for Xcode is installed
# **Xcode Command Line Tools**: Essential tools for macOS development, including compilers and command-line utilities.
if ! xcode-select -p &>/dev/null; then
	echo "Xcode Command Line Tools not found. Installing..."
	# Prompt user to install the Command Line Tools
	xcode-select --install
	# Wait until the Command Line Tools are installed
	until xcode-select -p &>/dev/null; do
		echo "Waiting for Command Line Tools to install..."
		sleep 5
	done
	echo "Xcode Command Line Tools installed."
else
	echo "Xcode Command Line Tools already installed."
fi

# Install Homebrew after architecture check; Set .zprofile config; Initialize immediately
# **Homebrew**: Known as Homebrew, it's a package manager for MacOS to install software from the terminal.
echo "You might be prompted for your password to install Homebrew and its dependencies."

# Determine the architecture of the machine
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
	HOMEBREW_PREFIX="/opt/homebrew"
else
	HOMEBREW_PREFIX="/usr/local"
fi

if ! command -v brew &>/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || failure_log+="Homebrew installation failed\n"
else
	echo "Homebrew already installed, skipping installation."
fi

# Initialize Homebrew
if ! grep -q 'eval "$('$HOMEBREW_PREFIX'/bin/brew shellenv)"' ~/.zprofile; then
	(
		echo
		echo 'eval "$('$HOMEBREW_PREFIX'/bin/brew shellenv)"'
	) >>~/.zprofile
fi
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)" || failure_log+="Homebrew initialization failed\n"
echo "Homebrew installed and configured."

#Now that the correct PATH is set we use 'brew' normally, and drop '$HOMEBREW_PREFIX'.
# Update and Upgrade Homebrew
brew update || failure_log+="Homebrew update failed\n"
brew upgrade || failure_log+="Homebrew upgrade failed\n"

# Function to check if a cask is installed
is_cask_installed() {
	brew list --cask | grep -q "$1"
}

# Function to check if a formula is installed
is_formula_installed() {
	brew list | grep -q "$1"
}

# Install iTerm2
# **iTerm2**: A replacement for Terminal and the successor to iTerm. It works on Macs and includes features like split panes, full-screen mode, and tabs.
if ! is_cask_installed iterm2; then
	brew install --cask iterm2 || failure_log+="iTerm2 installation failed\n"
fi

# Install ZSH and set as default shell
# **Zsh**: Zsh (Z shell) is a Unix shell with many features. Zsh is a superset of bash.
if ! is_formula_installed zsh; then
	brew install zsh || failure_log+="ZSH installation failed\n"
fi

# Download Zsh auto-suggestions, syntax-highlighting, and 'z' for directory navigation
echo "Installing Zsh plugins..."

ZSH_CUSTOM="$HOME/.zsh"

# Check if the directory exists for custom Zsh plugins, create if not
if [ ! -d "$ZSH_CUSTOM" ]; then
	mkdir -p "$ZSH_CUSTOM"
fi

# Clone Zsh auto-suggestions if it doesn't exist
if [ ! -d "$ZSH_CUSTOM/zsh-autosuggestions" ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/zsh-autosuggestions" || failure_log+="Zsh auto-suggestions installation failed\n"
else
	echo "Zsh auto-suggestions already installed."
fi

# Clone Zsh syntax-highlighting if it doesn't exist
if [ ! -d "$ZSH_CUSTOM/zsh-syntax-highlighting" ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/zsh-syntax-highlighting" || failure_log+="Zsh syntax-highlighting installation failed\n"
else
	echo "Zsh syntax-highlighting already installed."
fi

# Clone 'z' for directory navigation if it doesn't exist. Z will be installed via homebrew, but this is not a redundancy, this repo is needed for extended functionality allowed by using Zsh.
if [ ! -d "$ZSH_CUSTOM/z" ]; then
	git clone https://github.com/rupa/z.git "$ZSH_CUSTOM/z" || failure_log+="Z directory navigation installation failed\n"
else
	echo "'z' directory navigation already installed."
fi

echo "You might be prompted for your password to change the default shell."
if [ "$SHELL" != "/opt/homebrew/bin/zsh" ]; then
	chsh -s /opt/homebrew/bin/zsh || failure_log+="Changing default shell to ZSH failed\n"
fi

# Backup and download new .zshrc configuration
if [ -f ~/.zshrc ]; then
	# Create a backup with a timestamp
	cp ~/.zshrc ~/.zshrc.bak_$(date +%Y%m%d_%H%M%S)
	echo "Existing .zshrc file backed up."
fi

# Overwrite the existing .zshrc file with the new configuration
curl -o ~/.zshrc https://raw.githubusercontent.com/dissidentcode/dot-files/master/.zshrc || failure_log+=".zshrc configuration download failed\n"
echo ".zshrc configuration applied."

# Install Raycast
# **Raycast**: This productivity tool lets you control and automate tasks directly from your macOS toolbar with amazing keyboard shortcut support.
if ! is_cask_installed raycast; then
	brew install --cask raycast || failure_log+="Raycast installation failed\n"
fi

# Install Visual Studio Code (Vim, Emacs, and Notepad users, avert your eyes - or delete me!)
# **Visual Studio Code**: An open-source code editor developed by Microsoft.
if ! is_cask_installed visual-studio-code; then
	brew install --cask visual-studio-code || failure_log+="Visual Studio Code installation failed\n"
fi

# Install JetBrainsMono Nerd Font
# **JetBrainsMono Nerd Font**: An awesome developer font with all the Nerd Font symbols needed to take advantage of the custom prompt from the .zshrc config file included in this repo.
if ! is_cask_installed font-jetbrains-mono-nerd-font; then
	brew install --cask font-jetbrains-mono-nerd-font || failure_log+="JetBrainsMono Nerd Font installation failed\n"
fi

# Install mas (Mac App Store CLI)
# **Mas**: A command-line interface for the Mac App Store.
if ! is_formula_installed mas; then
	brew install mas || failure_log+="MAS installation failed\n"
fi

# Ensure the user is logged into the App Store
echo "Please ensure you are logged into the App Store. Press Enter when ready."
read -p ""

# *Install software from the App Store with app ID search in case you want to add applications to the 'apps' list/array*

# **Hidden Bar**: A Mac utility that helps to hide menu bar items to de-clutter the screen.
# **DropOver**: A MacOS app to create a temporary shelf for drag and drop files.
# Define the app names
apps=("Hidden Bar" "DropOver")

# Loop through the app names and install each one
for app in "${apps[@]}"; do
	# Search for the app and extract the ID using awk
	app_id=$(mas search "$app" | awk -F" " '/^ / {print $1; exit}')
	if [[ ! -z "$app_id" ]]; then
		# Install the app using the extracted ID
		mas install "$app_id" || failure_log+="$app installation failed\n"
	else
		failure_log+="$app ID lookup failed\n"
	fi
done

# *Install command-line tools and applications via Homebrew:*

# **Ansible**: An open-source automation platform that enables infrastructure as code, task automation, application deployment, and encryption.
# **Aria2**: A simple torrenting tool for the command line.
# **Asciinema**: An open-source solution for recording terminal sessions and sharing them.
# **Bat**: Adds syntax highlighting for many languages, git integration, etc to 'cat' command.
# **Btop**: An interactive system monitor designed as an alternative to the Unix program 'top' (btop is way better than htop).
# **Colordiff**: A wrapper for 'diff' that produces the same output but with colored syntax and vertical alignment.
# **Diff-so-fancy**: A series of scripts to make Git's diff output look fancier and easier to understand.
# **Duf**: Disk Usage/Free Utility with a best-in-slot visual presentation.
# **Dust**: An enhanced `du` written in rust for a more intuitive and useful information display.
# **Eza**: A modern replacement for `ls`; better suited for displaying all directories, or all files.
# **Fd**: A fast and user-friendly alternative to the terminal's classic 'find' command.
# **Ffmpeg**: FFmpeg is a versatile multimedia tool for audio and video processing, including conversion, compression, and streaming. It supports a wide range of formats.
# **Fio**: A versatile I/O benchmarking tool ideal for testing and analyzing the performance of various storage devices. It provides insights into latency, throughput, and IOPS.
# **Fzf**: A flexible and fast command-line fuzzy finder to enhance shell command efficiency.
# **Gifsicle**: Gifsicle is a command-line tool for editing and optimizing GIF images, known for efficiently reducing file sizes while maintaining quality.
# **Git**: An open-source version control system used to handle various projects, large and small.
# **ImageMagick**: A software suite that creates, edits, and composes bitmap images in various formats.
# **Jpegoptim**: A utility to optimize and compress JPEG files without losing quality.µ
# **Jq**: A command-line tool for processing JSON data, allowing for filtering, transformation, and extraction of information.
# **Lsd**: A modern replacement for `ls`; better suited for displaying all files and directories, hidden or otherwise.
# **Neofetch**: System profiler with ASCII art.
# **Neovim**: An extension of Vim that includes new features, simplified code, and a plugin architecture.
# **Optipng**: A PNG optimizer that recompresses image files to a smaller size without losing any information.
# **Pandoc**: A universal document converter that is able to convert files from one markup format into another.
# **Ranger**: A console file manager with VI key bindings offering a minimalistic and powerful visual interface.
# **Rar**: A command line utility to create RAR archives.
# **Speedtest-cli**: Command line interface for testing internet bandwidth using speedtest.net.
# **Starship**: A powerful prompt crafting tool for your shell.
# **Tealdeer**: A speedy implementation of 'tldr' client providing simplified, community-driven man pages.
# **Trash**: A safer alternative to `rm,` allowing you to move files to the trash instead of immediate, irreversible deletion.
# **Tree**: A recursive directory listing command that produces a depth-indented listing of files.
# **Unar**: A command-line utility for extracting archives, known for its support of multiple formats and its cross-platform compatibility.
# **Webp**: A command-line tool to convert images to the WebP format, which provides superior lossless and lossy compression for web images.
# **Wifi-password**: A script to quickly find the WiFi password you're connected to (this tool requires you to enter the network ID manually - I put together a small script that circumvents this, but it may trip up some of the new security features of Apple's latest OS release. If you're interested in how I did this, email me (github.carry327@passinbox.com), and I'll share the script. It's simple, you just need to know where to look and use some fancy RegEx to extract the network ID automatically ;))
# **Z**: A command line tool that allows you to navigate your filesystem super fast using 'frecency' (a combination of frequency and recency).
# **Zip**: A command-line utility for packaging and compressing (archiving) files in a zip format, widely used for file distribution.
brew install ansible aria2 asciinema bat btop colordiff diff-so-fancy duf dust eza fd ffmpeg fio fzf gifsicle git imagemagick jpegoptim jq neofetch neovim optipng lsd pandoc ranger rar speedtest-cli starship tealdeer trash tree unar webp wifi-password z zip || failure_log+="Installation of one or more command-line tools failed\n"

# *Install Node and Python via Homebrew:*

# **Node**: Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine.
# **Python**: Python is a programming language that lets you work quickly and integrate systems effectively.
brew install node python || failure_log+="Node or Python installation failed\n"

# *Install GUI applications via Homebrew Cask:*

# Install 1Password (paid yearly subscription—$36 as of 2023—worth the money, especially if you want to store sensitive data other than passwords) DEPRICATED - I'VE RECENTLY SWITCHED TO PROTON PASS - THEIR MAIL, PASSWORD MANAGER, AND VPN COMBO ARE A DEVENT VALUE.
# **1Password**: This password manager allows users to store various passwords, software licenses, and other sensitive information in a virtual vault locked with a PBKDF2-guarded master password. It is, in my opinion, the best-in-slot password manager.
# brew install --cask 1password || failure_log+="1Password installation failed\n"

# Install AlDente (paid features, but free version is great)
# **AlDente**: AlDente is a menu bar tool for MacOS that allows you to control your MacBook's battery charging threshold and helps extend battery life.
brew install --cask aldente || failure_log+="AlDente installation failed\n"

# Install Alt-Tab
# **Alt-Tab**: Alt-Tab is a small application that allows you to change the style of visuals displayed for alt-tabbing (bound to option+tab).
brew install --cask alt-tab || failure_log+="Alt-Tab installation failed\n"

# Install Brave Browser (Is Arc considered the cool kid on the block now?)
brew install --cask brave-browser || failure_log+="Brave Browser installation failed\n"

# Install Cheatsheet
# **Cheatsheet**: Cheatsheet is an application that provides quick reference for keyboard shortcuts. If you hold the ⌘-Key a bit longer, it will display a panel showing available shortcuts for the current application.
brew install --cask cheatsheet || failure_log+="Cheatsheet installation failed\n"

# Install Clean My Mac X (paid - yearly subscription - $39.95 as of 2023)
# **CleanMyMac X**: An all-in-one package for your Mac, it cleans junk and makes your computer run faster.
brew install --cask cleanmymac || failure_log+="Clean My Mac X installation failed\n"

# Install Logseq (paid syncing feature - not needed when using cloud service or git repo for storing your 'graph' e.g. your markdown files and directories)
# **Logseq**: A local-first, non-linear, outliner notebook for organizing and sharing your personal knowledge base. I have a strong personal preference for LogSeq over Obsidian. Recommended plugins: Tags, Heading level shortcuts, Markdown table editor, Bullet Threading, Git, Journal calendar, and GPT-3 OpenAI if you already pay for an API key.
brew install --cask logseq || failure_log+="Logseq installation failed\n"

# Install UTM
# **Utm**: A full-featured virtual machine host for iOS if you need to run Linux or Windows on your machine.
brew install --cask utm || failure_log+="UTM installation failed\n"

# Homebrew Cleanup
brew cleanup || failure_log+="Homebrew cleanup failed\n"

echo "Development Environment Setup Complete!"

if [[ -n $failure_log ]]; then
	echo -e "There were some errors during the setup:\n$failure_log"
	echo "You may need to install these applications manually."
fi

# *Additional Notes:*

# You may be prompted to input your password more than once.

# Error handling logs and lists errors at the end of the script, but the script will continue to run even if an error occurs.

# Feel free to remove or add packages and software to suit your needs. Keep in mind the top-to-bottom order of commands. If you want a cask package, Homebrew needs to be installed first. Also, anything installed from the App store needs to execute after the 'mas' installation on line 44.

# Ensure you've logged into the App Store before running this script since 'mas' requires you to be logged in. If you're adding software to the script from the App Store, be sure to use the appropriate ID number (App names do not work with mas).
