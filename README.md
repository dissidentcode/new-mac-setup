# Mac Development Environment Setup

Set up a brand-new Mac for development in one command. This script handles the tedious parts — installing developer tools, configuring your terminal, linking your dotfiles — so you can get back to actually using your computer.

It's designed to be safe to try, easy to stop, and easy to run again. If you've never used a script like this before, the [What this does](#what-this-does) section walks through every step in plain language, and you can preview the entire run without changing anything by adding `--dry-run`.

> **Heads up:** This script is built for **Apple Silicon Macs** (M1, M2, M3, M4, and newer). If you have an older Intel Mac, this isn't the right tool — the script will detect that and exit safely without making changes. macOS 16 (the latest) is recommended.

---

## Table of contents

- [Quick start](#quick-start)
- [What this does](#what-this-does)
- [Before you run it](#before-you-run-it)
- [Flags and options](#flags-and-options)
- [What gets installed](#what-gets-installed)
- [After it finishes](#after-it-finishes)
- [Customizing your setup](#customizing-your-setup)
- [Re-running and recovering from errors](#re-running-and-recovering-from-errors)
- [Troubleshooting](#troubleshooting)
- [How this is structured](#how-this-is-structured)
- [Contributing](#contributing)
- [License](#license)

---

## Quick start

Open the **Terminal** app (it's in `Applications → Utilities`, or press `Cmd-Space` and type "Terminal"), then paste these three lines:

```bash
git clone https://github.com/dissidentcode/new-mac-setup.git
cd new-mac-setup
./setup.sh
```

The script will narrate what it's doing and pause before anything that needs your attention (like signing into the Mac App Store). Plan for **20–45 minutes** depending on your internet speed.

**Want to see what it'll do without actually doing it?** Run `./setup.sh --dry-run`. It will print every action it would take and then exit. No files changed, nothing installed.

---

## What this does

The script runs ten steps in order. You can stop after any step, resume from any step, and skip steps you've already finished. Here's the plain-English version:

1. **Install Apple's command-line developer tools** — required by almost everything else. Apple itself ships these; the script just triggers the installer. A small system popup will appear; click "Install" and wait for it to finish.
2. **Install Homebrew** — the most popular Mac package manager. Think of it as the App Store for command-line tools, but free and open-source. Most software developers have it installed.
3. **Clone your dotfiles** — your personal config files (shell prompt, aliases, editor settings) live in a separate Git repository. The script downloads them to `~/.dotfiles`.
4. **Install everything in your Brewfile** — a `Brewfile` is a plain-text list of every app and tool you want. The script reads this list from your dotfiles and installs them all in one pass. You can edit this list anytime to add or remove things.
5. **Install npm global packages** — three AI command-line assistants (Claude, Gemini, Codex) get installed globally so you can call them from any folder.
6. **Install zsh plugins** — `zsh` is the default Mac shell since 2019. The script adds two plugins: one suggests commands as you type, the other colors your commands so syntax errors are obvious.
7. **Create symlinks** — symlinks are shortcuts that point your home folder at the configs in your dotfiles repo. Edit a config in one place, it takes effect everywhere.
8. **Configure your shell** — switches your default shell to the Homebrew-managed `zsh` (newer than the system one) and registers it with macOS.
9. **Verify Starship** — Starship is the prompt you see in your terminal (the part that shows your current folder, Git branch, etc.). The script confirms it's installed and configured.
10. **Cleanup** — runs `brew cleanup` to remove cached installer files and free up disk space.

Each step writes to a log file at `~/mac-setup.log` so you can see exactly what happened, and remembers in `~/.mac-setup-state` which steps finished — so if you have to stop and come back, you don't repeat work.

---

## Before you run it

Five things to have ready:

1. **An Apple Silicon Mac** running macOS 14 or newer (16 recommended). The script will refuse to run on Intel Macs.
2. **Your Apple ID password** — macOS will prompt for it during the Xcode tools install and the App Store steps.
3. **An administrator account.** The script uses `sudo` once (to register the new shell with macOS). It will explain when it needs your password.
4. **A Mac App Store login.** Some apps in the Brewfile come from the App Store (like Hidden Bar, Microsoft Outlook). Open the App Store app and sign in *before* running the script.
5. **A solid internet connection.** Most of the time is downloads.

Optional but nice:
- A backup. This script doesn't delete anything, but new Macs deserve Time Machine.
- 30–60 minutes of uninterrupted time. You can step away during downloads, but a few prompts need attention.

---

## Flags and options

| Flag | What it does | When to use it |
|---|---|---|
| `-y`, `--yes` | Skips the "press Enter to continue" prompts (Xcode CLI, App Store login). | When you've done this before and don't need the gentle pacing. |
| `-n`, `--dry-run` | Prints every action it *would* take, but doesn't change anything. | Always a safe first step. Use this to inspect what the script does before you commit to running it. |
| `-r`, `--resume [STEP]` | Skips steps already recorded as finished. Optionally start at a specific step. | After fixing a problem mid-run, or to retry just one piece. |
| `-h`, `--help` | Prints the help text and exits. | When you forget what the flags do. |

A few examples:

```bash
# preview the whole run without making changes
./setup.sh --dry-run

# run unattended (skip the keyboard prompts)
./setup.sh --yes

# something went wrong — pick up where it left off
./setup.sh --resume

# only re-run the package install step
./setup.sh --resume install_packages
```

The valid step names are: `install_xcode_cli`, `install_homebrew`, `clone_dotfiles`, `install_packages`, `install_npm_packages`, `install_zsh_plugins`, `create_symlinks`, `configure_shell`, `verify_starship`, `cleanup`.

---

## What gets installed

Two things to understand:

1. The **list of apps and tools** lives in `~/.dotfiles/Brewfile`, *not in this repository*. This script just reads that list. To add or remove something, edit the Brewfile.
2. The **AI CLIs** are hardcoded in `setup.sh` (under `NPM_GLOBALS`). They're separate because they come from npm, not Homebrew.

### AI command-line assistants (npm)

These are installed globally so they work from any folder:

- **Claude Code** (`@anthropic-ai/claude-code`) — Anthropic's terminal-based AI coding assistant. Talk to Claude inside your terminal, get help with code, run tasks. This is the same tool used to write parts of this README.
- **Gemini CLI** (`@google/gemini-cli`) — Google's terminal AI assistant.
- **Codex CLI** (`@openai/codex`) — OpenAI's terminal coding assistant.

You don't have to use all three. Pick the one(s) you have accounts for. They each have setup steps the first time you run them.

### Zsh plugins

These two get cloned into `~/.zsh/`:

- **zsh-autosuggestions** — as you type, it suggests commands you've used before in light gray. Hit the right arrow to accept. Saves a lot of typing.
- **zsh-syntax-highlighting** — colors your commands as you type. Valid commands turn green, errors stay red. Catches typos before you hit enter.

### What's typically in the Brewfile

The Brewfile in `~/.dotfiles/Brewfile` covers the categories below. **You don't have to use any of these — edit the Brewfile to taste.** Plain-English descriptions follow:

#### Terminal experience

- **WezTerm** — a fast, customizable terminal app. The thing you actually look at all day.
- **Monaspace font family** — Apple-quality coding fonts from GitHub. The script sets this as the primary terminal font.
- **Starship** — the colorful, informative prompt at the start of each terminal line. Shows your folder, Git branch, language version, and more.
- **Zsh + plugins** — the shell itself, plus the two plugins above.

#### Files and folders

- **bat** — a friendlier `cat`. Shows file contents with syntax colors and line numbers.
- **eza** and **lsd** — modern replacements for `ls`. Pretty colors, icons, Git status in the listing.
- **fd** — a friendlier `find`. Faster, simpler syntax.
- **fzf** — fuzzy file finder. Type a few letters and it finds the file. Game-changing.
- **ripgrep** (`rg`) — like `grep`, but blazing fast and respects `.gitignore`.
- **tree** — visualize a folder structure as a tree.
- **trash** — like `rm`, but sends files to the macOS Trash so you can undo.
- **yazi** — a terminal file manager. Browse folders without leaving the terminal.
- **zoxide** — a smarter `cd`. Type the start of any folder you've been to and it jumps you there.

#### Git tools

- **git** + **gh** — Git itself, plus GitHub's official CLI for managing pull requests and issues.
- **lazygit** — a friendly visual Git interface that runs in the terminal.
- **git-delta** — pretty, syntax-highlighted Git diffs.
- **onefetch** — shows a stylish summary card for any Git repository.

#### System info

- **btop** — a beautiful, real-time view of your CPU, memory, network, and processes.
- **duf** — disk-usage overview, prettier than `df`.
- **dust** — a friendlier `du`. Shows what's taking up space, visually.
- **fastfetch** — the system info card you see at the top of terminal screenshots.

#### Text and data

- **jq** — extracts and reformats data from JSON. Indispensable for working with APIs.
- **pandoc** — converts between document formats (Markdown ↔ Word ↔ PDF ↔ HTML).
- **tealdeer** (`tldr`) — quick, practical examples for any command. Like `man`, but useful.
- **glow** — renders Markdown in the terminal with formatting.

#### Media

- **ffmpeg**, **imagemagick** — the universal video and image converters. Almost every media tool on the internet uses one of these under the hood.
- **gifsicle**, **jpegoptim**, **optipng**, **webp** — file-size optimizers for the corresponding formats.
- **chafa**, **viu** — display images directly in the terminal.

#### Network

- **aria2** — robust download manager. Resumes interrupted downloads, downloads multiple files in parallel.
- **speedtest-cli** — internet speed test from the terminal.
- **wifi-password** — recovers your saved Wi-Fi password.
- **yt-dlp** — downloads videos from YouTube and many other sites.

#### Archives

- **p7zip**, **unar**, **zip**, **atool** — handle just about every archive format you'll encounter.

#### AI

- **llm** (Simon Willison's) — talk to language models from the command line. Plugin ecosystem, supports OpenAI, Anthropic, local models, more.

#### Editor

- **Neovim** — a modern, extensible terminal text editor. Steep learning curve, deep payoff.
- **Cursor** — an AI-powered code editor based on VS Code. Familiar interface plus built-in AI.

#### Programming languages and runtimes

- **node** — JavaScript runtime. Required for the AI CLIs.
- **python** — the latest Python.
- **go** — Google's Go language.
- **rustup** — installs and manages the Rust language.
- **bun** — a fast all-in-one JavaScript toolkit (runtime, bundler, package manager).
- **mise** — manages multiple versions of multiple languages. If you ever need to juggle Python 3.11 and 3.13 at the same time, this is the tool.
- **lua** — small embeddable scripting language. Powers Neovim's config.

#### Containers and virtualization

- **OrbStack** — a fast, lightweight Docker replacement for Mac. Way better than Docker Desktop.

#### Productivity apps

- **Raycast** — a launcher and command palette. Replaces Spotlight with a far more powerful, extensible alternative.
- **AlDente** — limits battery charging to extend battery lifespan.
- **Dropover** — a "shelf" for drag-and-drop. Drag files to the shelf, then drop them where they need to go later.
- **CleanMyMac** — system maintenance and cleanup.
- **Grammarly Desktop** — grammar and spell-check across all apps.
- **Microsoft Outlook** — email and calendar.
- **Hidden Bar** — hides menu-bar icons you rarely use.

#### Privacy and security

- **LuLu** — a free, open-source outbound firewall. Tells you which apps are phoning home.
- **Proton Pass** — Proton's password manager, integrates with the rest of the Proton ecosystem.
- **Stats** — a free, open-source system monitor in your menu bar. CPU, RAM, network, disk, all visible at a glance.

The full, current list lives in [`docs/tool-recommendations-2026-04.md`](./docs/tool-recommendations-2026-04.md), including which tools were dropped and why.

---

## After it finishes

Three small things to do:

1. **Restart your terminal** (close all windows, open a new one) or run `exec zsh` in the existing window. This loads the new shell config.
2. **Open WezTerm** and confirm it's using the Monaspace font. (WezTerm → Preferences, or edit `~/.wezterm.lua` if you're comfortable with that.)
3. **Try the AI CLIs.** Run `claude`, `gemini`, or `codex` in a terminal. Each will walk you through first-time login.

If anything looks off, the [Troubleshooting](#troubleshooting) section covers the common cases.

---

## Customizing your setup

Where to make changes:

- **Add or remove apps and command-line tools** — edit `~/.dotfiles/Brewfile`, then run `./setup.sh --resume install_packages` (or `brew bundle --file=~/.dotfiles/Brewfile` directly).
- **Change shell behavior, aliases, functions** — edit files in `~/.dotfiles/zsh/`. Open a new terminal to see changes.
- **Customize your prompt** — edit `~/.dotfiles/zsh/starship.toml`. Starship's [docs](https://starship.rs) explain every option.
- **Change which AI CLIs get installed** — edit the `NPM_GLOBALS` array near the top of `setup.sh`.

To **export your current Brewfile** (handy after you've installed things manually and want to record them):

```bash
brew bundle dump --file=~/.dotfiles/Brewfile --force
```

---

## Re-running and recovering from errors

The script is **idempotent** — a fancy word that means "safe to run as many times as you want." Steps that already finished are skipped. If something fails, fix the cause and run it again.

**To pick up where it left off:**
```bash
./setup.sh --resume
```

**To retry one specific step:**
```bash
./setup.sh --resume install_packages
```

**To force a complete fresh run** (rare — usually you don't want this):
```bash
rm ~/.mac-setup-state
./setup.sh
```

The state file at `~/.mac-setup-state` is just a plain-text list of finished step names. You can open it in any editor to see what's done. The log file at `~/mac-setup.log` records every action with timestamps.

---

## Troubleshooting

**App Store apps fail to install**
You're probably not signed into the Mac App Store. Open the App Store app, sign in, then re-run with `./setup.sh --resume`.

**The terminal prompt looks broken or shows boxes instead of icons**
The Monaspace font isn't being used. In WezTerm, set the font to "Monaspace". If you don't see Monaspace as an option, restart WezTerm or restart your Mac — the font cache sometimes needs a kick.

**Your default shell didn't change**
Run this manually:
```bash
chsh -s /opt/homebrew/bin/zsh
```
Then open a new terminal window.

**`mcfly` history is empty**
`mcfly` (a smart shell history search) builds its database from commands you actually run. Use the shell normally for a session and history will populate. Press `Ctrl-R` to search.

**Something else broke**
Open `~/mac-setup.log` and look for `[ERROR]` lines. Each one says exactly which step failed. The script does not abort on errors — it logs them and continues, then prints a summary at the end. You can then re-run with `--resume` after fixing the cause.

If you're stuck, [open an issue](https://github.com/dissidentcode/new-mac-setup/issues) with the relevant log lines and we'll take a look.

---

## How this is structured

This repository is the **runner**. It contains the orchestration script (`setup.sh`) and supporting docs.

The actual list of apps and tools lives in a separate repository: the **dotfiles repo** at `~/.dotfiles`. That's where the `Brewfile`, shell config, prompt config, and editor config live. The two repos are designed to evolve independently:

- Want a new app? Add a line to `~/.dotfiles/Brewfile`.
- Want to change *how* the script installs things? Edit `setup.sh` here.

This split keeps the runner small and reusable, and keeps your personal package list private (or public — your call) without entangling it with the script logic.

---

## Contributing

Contributions are welcome. A few ground rules:

1. **`shellcheck` clean.** Run `shellcheck setup.sh` before opening a PR. Zero warnings, zero errors.
2. **`bash -n setup.sh` passes.** Syntax check before commit.
3. **Apple Silicon only.** No Intel-compatibility patches; that ship has sailed.
4. **`bash 3.2` compatible.** macOS still ships bash 3.2 by default. Avoid `mapfile`, `${var,,}`, `declare -A`, and other bash 4+ features.
5. **Tool changes go through the recommendations doc**, not directly into `setup.sh`. See [`docs/tool-recommendations-2026-04.md`](./docs/tool-recommendations-2026-04.md) for the format.

For larger changes, open an issue first to discuss.

---

## License

MIT — see [LICENSE](./LICENSE). Use it, fork it, modify it, share it. Attribution appreciated but not required.

---

## Contact

Questions, suggestions, or just want to say hi: **github.carry327@passinbox.com**
