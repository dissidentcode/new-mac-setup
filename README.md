_🚨 HASN'T BEEN TESTED YET - FEEL FREE TO TEST YOURSELF ON A NEW MACHINE OR FRESH OS INSTALL- I'LL BE TESTING THIS SCRIPT ON AN OLDER MAC AND AGAIN IN A VIRTUAL MACHINE ON AN M1 - I'LL UPDATE THIS README WHEN FINISHED 🚨_

# Mac Development Environment Setup Script

Welcome to the Mac Development Environment Setup Script repository! This script is designed to automate the setup of a new Mac for development purposes. It's geared towards both experienced and novice developers looking for a seamless setup experience. It installs all of my personal picks for the best packages, tools, and software for Mac work.

## Features

- **Automated Installation**: Automates the installation of essential tools, utilities, and applications to get you up and running quickly.
- **Customizable**: Easily add or remove applications to suit your needs.
- **Error Handling**: Detects and logs errors to ensure a smooth setup process.
- **Idempotence**: Run the script multiple times without causing unwanted side effects.

## Getting Started

### Prerequisites

- Please make sure you have administrative access to your Mac.
- Please ensure you are logged into the App Store, as some installations require it.

### Usage

1. Clone this repository to your local machine:

```bash
git clone https://github.com/dissidentcode/new-mac-setup.git
```

2. Go to the directory and make the script executable:

```bash
cd mac-dev-setup-script
```

```bash
chmod +x setup.sh
```

3. Run the script:

```bash
./setup.sh
```

4. Follow the on-screen prompts. You might be asked to enter your password for specific installations.

## Customization

Feel free to customize the script to match your preferences. It is structured and commented to make understanding and customizing straightforward. Add or remove applications from the arrays defined in the script to tailor the setup process to your needs.

## Error Logging

If there are any errors during the setup process, they will be logged and displayed at the end of the script execution. This allows for easy troubleshooting and manual installation if necessary.

## Contribution

Feel free to fork this repository and submit pull requests for any enhancements, bug fixes, or additional features you think would be beneficial. All contributions are welcome!

## Contact

Don't hesitate to contact me at github.carry327@passinbox.com for any questions or feedback.

# Installed Software List

## Development Tools

- **Ansible**: An open-source automation platform that enables infrastructure as code, task automation, application deployment, and encryption.
- **Cask**: Extension for Homebrew for installing macOS native applications.
- **Homebrew**: The "missing package manager" for macOS, used to install and manage software.
- **Mas**: Mac App Store command-line interface that simplifies the installation of App Store applications.
- **Xcode Command Line Tools**: Essential tools for macOS development, including compilers and command-line utilities.

## Terminal and Shell

- **iTerm2**: This is a replacement for Terminal and the successor to iTerm that brings powerful features for command-line users.
- **Zsh**: Z shell, a Unix shell that can be used as an interactive login shell and a command interpreter for shell scripting.

## Shell Enhancements

- **Starship**: A powerful prompt crafting tool for your shell.
- **Zsh-autosuggestions**: Suggests commands as you type based on history and completions.
- **Zsh-syntax-highlighting**: Provides syntax highlighting for the shell zsh; it highlights commands, parameters, and other syntax elements.

## Text Editors

- **Neovim**: A hyper-extensible Vim-based text editor.
- **Visual Studio Code**: A lightweight but powerful source code editor that runs on your desktop and is available for Windows, macOS, and Linux.

## Command-Line Utilities

- **Aria2**: Torrenting tool for the command line.
- **Asciinema**: Terminal session recorder lets you record and share your command-line workflows.
- **Bat**: A clone of `cat` with syntax highlighting and Git integration.
- **Btop**: An interactive system monitor designed as an alternative to the Unix program 'top' (btop is way better than htop).
- **Colordiff**: A wrapper for `diff` and produces the same output but with colored syntax.
- **Diff-so-fancy**: Improves the display of `diff` outputs.
- **Duf**: A better alternative for checking device disk usage.
- **Dust**: An enhanced `du` written in Rust for a more intuitive and useful info display.
- **Eza**: This is a modern replacement for `ls`; it is better suited for listing only directories or files.
- **Fd**: A simple, fast, and user-friendly alternative to 'find'.
- **Ffmpeg**: FFmpeg is a versatile multimedia tool for audio and video processing, including conversion, compression, and streaming. It supports a wide range of formats.
- **Fio**: A versatile I/O benchmarking tool, ideal for testing and analyzing the performance of various storage devices. It provides insights into latency, throughput, and IOPS.
- **Fzf**: A flexible and fast command-line fuzzy finder to enhance shell command efficiency.
- **Gifsicle**: Gifsicle is a command-line tool for editing and optimizing GIF images. It isd known for efficiently reducing file sizes while maintaining quality.
- **Imagemagick** A versatile image processing tool that supports numerous formats and can resize, convert, and manipulate images.
- **Jpegoptim**: A utility to optimize and compress JPEG files without losing quality.
- **Jq**: A command-line tool for processing JSON data, allowing for filtering, transformation, and information extraction.
- **Lsd**: A modern replacement for `ls`; better suited for displaying all files and directories, hidden or otherwise.
- **Optipng**: A PNG optimizer that re-compresses image files to a smaller size without losing any information.
- **Pandoc**: A universal document converter.
- **Ranger**: A console file manager with VI key bindings, that offers a minimalistic and powerful visual interface.
- **Rar**: A command-line tool for creating and viewing RAR archives.
- **Speedtest-cli**: Command line interface for testing internet bandwidth using speedtest.net.
- **Tealdeer**: A BLAZINGLY fast implementation of `tldr` in Rust: Simplified and community-driven man pages.
- **Trash**: A safer alternative to `rm`, allowing you to move files to the trash instead of immediately irreversibly deleting them.
- **Tree**: A recursive directory listing command that produces a depth-indented listing of files.
- **Unar**: A command-line utility for extracting archives, it is known for supporting multiple formats and being cross-platform compatible.
- **Webp**: A command-line tool to convert images to the WebP format, which provides superior lossless and lossy compression for web images.
- **Wifi-password**: This shows the current WiFi network password, assuming you entered it at some point.
- **Z**: Tracks the most used directories to allow quick navigation.
- **Zip**: A command-line utility for packaging and compressing (archiving) files in a zip format, widely used for file distribution.

## Languages Support

- **Node.js**: A JavaScript runtime for server-side programming.
- **Python**: A versatile scripting language used for various applications.

## Productivity Tools

- **Alt-tab**: A window switcher for macOS that allows switching between windows more conveniently.
- **Cheatsheet**: An app that shows keyboard shortcuts in an overlay window.
- **DropOver**: A utility that makes dragging and dropping files or content easier.
- **Hidden Bar**: An ultra-light MacOS utility that helps hide menu bar icons.
- **LogSeq**: A privacy-first, open-source knowledge base that works on top of local plain-text Markdown and Org-mode files.
- **Raycast**: A productivity tool allowing you to control your tools with a few keystrokes.

## Browsers

- **Brave browser**: A free and open-source web browser based on the Chromium web browser and its Blink engine focused on privacy.

## Utility Applications

- **AlDente**: A charging limiter for MacBooks to help extend the battery's lifespan.
- **Clean My Mac X**: A cleaning and optimization tool for Mac.
- **UTM**: A virtual machines manager for Mac, designed to create virtual machines that can run on Apple Silicon.

## Font

- **JetBrainsMono Nerd Font**: This is an awesome developer font with all the necessary symbols for the custom prompt in the .zshrc config file.
