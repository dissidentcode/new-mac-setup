# Tool and app recommendations — 2026-04

Output of the new-mac-setup interview on 2026-04-26. Target machine: MacBook Pro, Apple Silicon Pro chip, 64 GB RAM. Apply changes manually to `~/.dotfiles/Brewfile`. The setup script reads packages from there.

## Status legend

- 🟢 **Add** — new entry to add to Brewfile
- 🔴 **Remove** — current entry to drop
- 🟡 **Replace** — swap one entry for another
- 🔵 **Keep** — already present, confirmed staying
- ⚪ **Defer** — discussed, decided to skip for now

## How to read this

Each category section lists decisions made during the interview. Each line cites the Brewfile section it lands in (`brew`, `cask`, `mas`, `vscode`, `tap`).

---

## A. Hardware and OS

- 🔵 **macOS 16 (latest)** confirmed.
- ⚪ **No local LLM runners.** Skipping Ollama and LM Studio. Sticking with hosted Claude and Gemini.

_(Intel-branch drop tracked in the setup.sh refactor, not here.)_

## B. Terminal stack

- 🔵 **WezTerm** — keep. `cask "wezterm"` stays.
- 🔵 **Zsh + Starship** — keep. `brew "zsh"`, `brew "starship"` stay.
- 🔵 **Monaspace** is the primary font. `cask "font-monaspace"` already present. **README correction needed**: drop the "JetBrainsMono Nerd Font (primary)" line and replace with Monaspace. Don't add JetBrainsMono.
- 🔴 **Remove `brew "atuin"`** from Brewfile.
- 🟢 **Add `brew "mcfly"`** to Brewfile. Replaces atuin for shell-history search. No sync, neural-net-ranked.
- ⚪ **Other fonts** (`font-fira-code`, `font-hack-nerd-font`, `font-sf-mono`, `font-sf-pro`) — left in place. Decision deferred unless flagged later.

**Follow-up needed:** the dotfiles `.zshrc` likely sources `atuin init zsh`. Switching to mcfly requires editing `.zshrc` to source `mcfly init zsh` instead. Out of scope here (lives in `~/.dotfiles`), but flag for the user.

## C. Editor / IDE

- 🟡 **VS Code → Cursor**. Drop the README claim of "Visual Studio Code". Add `cask "cursor"` to Brewfile. Cursor is a VS Code fork — extensions still install via Cursor's `cursor` CLI.
- 🔴 **Drop all 22 `vscode "..."` lines** from Brewfile. Reinstall extensions as needed inside Cursor on the new mac. Fresh slate.
- 🔵 **Keep `brew "neovim"`**.
- ⚪ **Neovim config rebuild on a distro** (LazyVim / AstroNvim / NvChad) — flagged as a separate config-side task. Lives in `~/.dotfiles/.config/nvim`, out of scope for this engagement.

**Follow-up needed:** the symlink at `~/.config/nvim` (created by setup.sh:266) will point at whatever distro you adopt. The setup script itself doesn't change.

## D. AI tooling

- 🔵 **claude-code** — keep. Already installed by setup.sh:213 as an npm global.
- 🔵 **gemini-cli** — keep. Already installed by setup.sh:217 as an npm global.
- 🔴 **Drop `brew "aichat"`** from Brewfile.
- 🟢 **Add `brew "llm"`** to Brewfile (Simon Willison's). Plugin ecosystem, model-agnostic, designed for piping.
- 🟢 **Add Codex CLI** as a third npm global in setup.sh. Add `npm install -g @openai/codex` alongside the existing claude-code and gemini-cli installs (setup.sh:202-220).
- ⚪ Aider, Opencode — declined.

**Follow-up needed:** setup.sh's `install_npm_packages` function (lines 202-220) currently hardcodes claude-code + gemini-cli. The refactor should add Codex CLI here, or generalize to a NPM_GLOBALS array.

## E. Window manager and menu bar

- 🔴 **Drop `cask "aerospace"`** — no tiling WM. Stage Manager + cmd-tab handle it.
- 🔴 **Drop `brew "felixkratz/formulae/sketchybar"`** — native menu bar.
- 🔴 **Drop `brew "felixkratz/formulae/borders"`**.
- 🔴 **Drop `cask "alt-tab"`**.
- 🔴 **Drop `tap "felixkratz/formulae"`** — both consumers (sketchybar, borders) are gone.
- 🔴 **Drop `tap "nikitabobko/tap"`** — only consumer (aerospace) is gone.
- 🔵 **Keep `mas "Hidden Bar"`**.

**Follow-up needed (script-level):** setup.sh:267 (`.config/sketchybar` symlink) and setup.sh:279 (`.aerospace.toml` symlink) become dead weight. Remove from the symlink arrays during Phase 2 refactor.

## F. Productivity and utility apps

- 🟢 **Add `cask "raycast"`** — README already claims it; finally aligns Brewfile to README.
- 🔵 **Keep `cask "aldente"`**.
- 🔵 **Keep `mas "Dropover"`**.
- 🔵 **Keep `mas "CleanMyMac"`**.
- 🔵 **Keep `cask "grammarly-desktop"`**.
- 🔵 **Keep `mas "Microsoft Outlook"`**.
- 🔴 **Drop `cask "colorsnapper"`**.
- 🔴 **Drop `cask "darktable"`**.
- 🔴 **Drop `cask "rar"`** — `unar` and `p7zip` already in Brewfile cover most archive needs.
- 🔴 **Drop `mas "Keynote"`**.
- 🔴 **Drop `mas "Numbers"`**.
- 🔴 **Drop `mas "Pages"`**.

## G. Dev runtimes

- 🟡 **Replace `brew "python@3.11"`** with `brew "python"` (unpinned, always latest stable).
- 🟢 **Add `brew "rustup"`** for the Rust toolchain. Homebrew renamed `rustup-init` → `rustup` in 2026; the old name 404s on the formulae API. Run `rustup-init -y` once installed to bootstrap the toolchain (the binary still ships under that name).
- 🟢 **Add `brew "oven-sh/bun/bun"`** (Bun runtime). Add the tap line `tap "oven-sh/bun"` if not auto-implied.
- 🟢 **Add `brew "mise"`** for runtime version management.
- 🟡 **Replace Docker CLI with OrbStack.** Drop `brew "docker"`. Add `cask "orbstack"`.
- 🔵 **Keep `brew "node"`**.
- 🔵 **Keep `brew "go"`**.
- ⚪ Deno, Java, .NET, Ruby, Zig, asdf, Colima, Docker Desktop — declined.

**Follow-up needed:** mise needs `eval "$(mise activate zsh)"` in `.zshrc` to take effect. Out of scope here (lives in `~/.dotfiles/zsh/.zshrc`), but flag for the user.

## H. Privacy and security

- 🟢 **Add `cask "lulu"`** — outbound firewall (Patrick Wardle / Objective-See, free, open-source).
- 🟢 **Add `cask "proton-pass"`** — Proton Pass (aligns with the user's existing Proton ecosystem at `codeshade@proton.me`).
- 🟢 **Add `cask "stats"`** — free menu-bar system monitor.
- ⚪ VPN — declined (no Tailscale, Mullvad, WireGuard).
- ⚪ GPG Suite, Karabiner-Elements, Maccy — declined.
- ⚪ 1Password, Bitwarden — declined (Proton Pass chosen).

## I. CLI tools long-tail audit

- 🔴 **Drop `brew "ranger"`** — yazi covers it.
- 🔴 **Drop `brew "lf"`** — yazi covers it.
- 🔴 **Drop `brew "midnight-commander"`** — yazi covers it.
- 🔴 **Drop `brew "jstkdng/programs/ueberzugpp"`** — was for ranger's image preview; yazi has its own.
- 🔴 **Drop `tap "jstkdng/programs"`** — ueberzugpp was the only consumer.
- 🔵 **Keep both `brew "eza"` and `brew "lsd"`**.
- 🟢 **Add `brew "shellcheck"`** — supports the project hard rule "shellcheck-clean is required" for `setup.sh`. Lets the script self-validate on the new mac without depending on a separate tool install.
- 🔴 **Drop `brew "cointop"`**.
- 🔴 **Drop `brew "testdisk"`**.
- 🔴 **Drop `brew "ansible"`**.
- 🔴 **Drop `brew "tesseract"`**.
- 🟡 **Replace `brew "neofetch"` with `brew "fastfetch"`** — neofetch project archived 2024.
- 🟡 **Replace `brew "z"` with `brew "zoxide"`** — actively maintained successor.
- 🟡 **Replace `brew "diff-so-fancy"` with `brew "git-delta"`** — best-in-class diff viewer.
- ⚪ hyperfine — declined.

### Items not covered in interview (defaults)

These weren't asked about. If any look obviously unused, flag them later:

- `brew "cask"` (Emacs dependency) — likely orphaned. **Suggest dropping** unless you still use Emacs.
- `brew "colordiff"` — superseded by delta. **Suggest dropping** after delta is in place.
- `brew "fdupes"` (duplicate finder) — niche, default keep.
- `brew "fio"` (I/O benchmark) — very niche, default keep.
- `brew "create-dmg"` — DMG builder, default keep.
- `brew "highlight"` (source-to-HTML) — default keep.
- `brew "atool"` (archive front-end) — default keep.
- `brew "media-info"` — default keep.
- `brew "switchaudio-osx"` — default keep.
- `brew "nowplaying-cli"` — default keep.
- `brew "speedtest-cli"` — default keep.
- `brew "wifi-password"` — default keep.
- `brew "w3m"` (text browser) — default keep.
- `brew "aria2"` (downloader) — default keep.
- 🔴 **Drop `brew "icu4c@75"`** — Homebrew **disabled** this versioned formula on 2025-10-24. `brew bundle` errors with `icu4c@75 has been disabled because it is a versioned formula!` and aborts the bundle on a fresh machine. Confirmed by smoke-test on 2026-04-27. `imagemagick` and other consumers track unversioned `icu4c` now; nothing in the Brewfile depends on the @75 pin.

---

## Final Brewfile diff (rolled up)

Apply the following changes to `~/.dotfiles/Brewfile`. Lines grouped by section.

### Taps to remove

```diff
- tap "felixkratz/formulae"        # consumers (sketchybar, borders) dropped
- tap "homebrew/bundle"            # `brew bundle` built into Homebrew now
- tap "homebrew/cask-fonts"        # deprecated 2024; fonts in homebrew/core
- tap "jstkdng/programs"           # consumer (ueberzugpp) dropped
- tap "nikitabobko/tap"            # consumer (aerospace) dropped
```

### Taps to add

```diff
+ tap "oven-sh/bun"                # for the bun runtime (auto-implied by `brew "oven-sh/bun/bun"`, listed for clarity)
```

### `brew` lines to remove

```diff
- brew "aichat"                    # replaced by llm
- brew "ansible"                   # not used
- brew "atuin"                     # replaced by mcfly
- brew "cask"                      # Emacs dep, likely orphaned (suggest)
- brew "cointop"                   # niche
- brew "colordiff"                 # superseded by git-delta (suggest)
- brew "diff-so-fancy"             # replaced by git-delta
- brew "docker"                    # replaced by OrbStack
- brew "icu4c@75"                  # disabled by Homebrew 2025-10-24 (versioned formula); aborts brew bundle
- brew "felixkratz/formulae/borders"
- brew "felixkratz/formulae/sketchybar"
- brew "jstkdng/programs/ueberzugpp"
- brew "lf"                        # yazi covers it
- brew "midnight-commander"        # yazi covers it
- brew "neofetch"                  # archived 2024; replaced by fastfetch
- brew "python@3.11"               # replaced by unpinned python
- brew "ranger"                    # yazi covers it
- brew "tesseract"                 # niche
- brew "testdisk"                  # niche
- brew "z"                         # replaced by zoxide
```

### `brew` lines to add

```diff
+ brew "fastfetch"                 # replaces neofetch
+ brew "git-delta"                 # replaces diff-so-fancy
+ brew "llm"                       # replaces aichat
+ brew "mcfly"                     # replaces atuin
+ brew "mise"                      # runtime version manager
+ brew "oven-sh/bun/bun"           # Bun JS runtime
+ brew "python"                    # unpinned, latest stable
+ brew "shellcheck"                # self-validate setup.sh on the new mac
+ brew "rustup"                    # Rust toolchain (renamed from rustup-init)
+ brew "zoxide"                    # replaces z
```

### `cask` lines to remove

```diff
- cask "aerospace"                 # tiling WM dropped
- cask "alt-tab"                   # menu/window helpers pruned
- cask "colorsnapper"              # not kept
- cask "darktable"                 # not kept
- cask "rar"                       # unar/p7zip cover archives
```

### `cask` lines to add

```diff
+ cask "cursor"                    # replaces VS Code
+ cask "lulu"                      # outbound firewall
+ cask "orbstack"                  # replaces Docker
+ cask "proton-pass"               # password manager
+ cask "raycast"                   # launcher (matches README)
+ cask "stats"                     # menu-bar system monitor
```

### `mas` lines to remove

```diff
- mas "Keynote", id: 409183694
- mas "Numbers", id: 409203825
- mas "Pages", id: 409201541
```

### `vscode` lines to remove

Drop **all 22** `vscode "..."` lines (Cursor uses the same extensions; reinstall as-needed inside Cursor).

```diff
- vscode "alefragnani.project-manager"
- vscode "bradlc.vscode-tailwindcss"
- vscode "dbaeumer.vscode-eslint"
- vscode "drmerfy.overtype"
- vscode "ecmel.vscode-html-css"
- vscode "esbenp.prettier-vscode"
- vscode "formulahendry.auto-close-tag"
- vscode "github.vscode-pull-request-github"
- vscode "glenn2223.live-sass"
- vscode "kamikillerto.vscode-colorize"
- vscode "monokai.theme-monokai-pro-vscode"
- vscode "ms-azuretools.vscode-docker"
- vscode "pkief.material-icon-theme"
- vscode "pranaygp.vscode-css-peek"
- vscode "ritwickdey.liveserver"
- vscode "streetsidesoftware.code-spell-checker"
- vscode "syler.sass-indented"
- vscode "visualstudioexptteam.intellicode-api-usage-examples"
- vscode "visualstudioexptteam.vscodeintellicode"
- vscode "wallabyjs.quokka-vscode"
- vscode "xabikos.javascriptsnippets"
```

(Side note: the Brewfile I read had only 21 `vscode` lines. The 22-count I mentioned earlier was off by one — confirmed against `~/.dotfiles/Brewfile:191-211`.)

### Summary counts

- 5 taps removed, 1 tap added (or 0 if `brew "oven-sh/bun/bun"` auto-taps).
- 20 brews removed, 10 brews added.
- 5 casks removed, 6 casks added.
- 3 mas entries removed.
- 21 vscode entries removed.

### Setup.sh-side changes (separate from Brewfile)

- `setup.sh:213-217` — keep claude-code, gemini-cli; **add** `npm install -g @openai/codex` for Codex CLI.
- `setup.sh:267` — remove the `.config/sketchybar` symlink (orphaned).
- `setup.sh:279` — remove the `.aerospace.toml` symlink (orphaned).
- `setup.sh:17` — `DOTFILES_DIR="$HOME/.dotfiles"`.
- `setup.sh:22-27` — drop Intel branch.

### Dotfiles-side follow-ups (out of scope, user-driven)

These live in `~/.dotfiles` and need user action separately:

1. `.zshrc` — replace `eval "$(atuin init zsh)"` with `eval "$(mcfly init zsh)"`.
2. `.zshrc` — replace `eval "$(zoxide init zsh)"` for `z` (or whatever shim was used).
3. `.zshrc` — add `eval "$(mise activate zsh)"` to enable mise.
4. `.zshrc` — `git-delta` configures via `~/.gitconfig`, not `.zshrc`.
5. Optional: rebuild Neovim config on a distro (LazyVim / AstroNvim / NvChad).
6. `.gitconfig` — set `delta` as the pager: `[core] pager = delta`.

### What about JetBrainsMono Nerd Font?

The README claims it as primary, but it's not in the Brewfile and the user picked Monaspace as primary. **Action: update the README** (Phase 3). No Brewfile change.

### Drop `font-fira-code`, `font-hack-nerd-font`, `font-sf-mono`, `font-sf-pro`?

Not asked, kept by default. If you want a leaner font set, drop the ones you don't actually pick in WezTerm or other apps.

## Notes

- Stale taps to drop unconditionally: `homebrew/cask-fonts` (deprecated 2024 — fonts moved to `homebrew/core`), `homebrew/bundle` (`brew bundle` is built in now).
- `brew "neofetch"` — project archived 2024. Replace with `brew "fastfetch"`.
- `brew "python@3.11"` — version pin worth questioning.
- `brew "icu4c@75"` — version pin worth questioning.
