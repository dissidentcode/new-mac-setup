# new-mac-setup

This repo is the **runner**. It bootstraps a fresh macOS install. Package selection lives in the **dotfiles repo at `~/.dotfiles`**, not here.

## Hard rules

- **Apple Silicon only.** The script fails fast on Intel via the arch guard in `main()`.
- **shellcheck-clean is required.** Run `shellcheck setup.sh` before claiming a change works.
- **`bash -n setup.sh` syntax pass is required.**
- **The script must support `--dry-run`, `--yes`, `--resume`, `--help`.** Don't add a step without wiring it into `should_run` / `mark_done`.
- **Logs are plain text.** Stderr gets ANSI color; the log file does not. Don't `echo -e` ANSI escapes into `$LOG_FILE`.
- **Every `log_error` in a step function must be followed by `return 1`.** Silent failures hide from the summary.

## Architecture

- `setup.sh` — single canonical bootstrap script. 10 numbered steps from Xcode CLI to cleanup.
- `~/.dotfiles/` — separate repo, cloned by step 3. Holds the `Brewfile` (package source of truth) and zsh configs.
- `~/.mac-setup-state` — runtime state file used by `--resume`. Each step writes its name on success.
- `~/mac-setup.log` — plain-text log of the run.

## Conventions

- **Tool / app changes don't go directly into `setup.sh`.** They go through `docs/tool-recommendations-2026-04.md` (or a newer dated successor). The user applies the diff to `~/.dotfiles/Brewfile` manually.
- **NPM globals are hardcoded** in `setup.sh` under the `NPM_GLOBALS` array. Edit there to add or remove.
- **Symlinks are managed via the `dir_links`, `file_links`, and `optional_links` arrays** in `create_symlinks()`. Add new symlinks by appending to the appropriate array.
- **Every step function** follows this shape:

  ```bash
  step_name() {
      should_run "step_name" || return 0
      log_info "..."
      # work; use do_run for mutating commands
      mark_done "step_name"
  }
  ```

- **Use `do_run` to wrap mutating commands.** It honors `--dry-run`. Reads (e.g., `grep`, `command -v`, `[[ -d ... ]]`) don't need wrapping.
- **Use `append_to_file` and `sudo_append_to_file`** instead of raw `echo >>`. They check for the line first (idempotent) and honor `--dry-run`.
- **bash 3.2 compatibility.** macOS still ships bash 3.2 (GPLv3 holdout). The shebang is `#!/bin/bash`. Don't use `mapfile`, `${var,,}`, or `declare -A`.

## Out of scope (will not be added here)

- Editing `~/.dotfiles/Brewfile` directly. That's the user's call after reading the recommendations doc.
- `defaults write` macOS system tweaks.
- Data migration from another mac.
- The dotfiles repo's own structure or zsh config.

## When changing things

- A new tool / app for the user → propose it in the recommendations doc, not in `setup.sh`.
- A new step → add to `STEP_ORDER`, write the function, wire `should_run` / `mark_done`, run shellcheck.
- A flag change → update `parse_args`, `print_usage`, and this file.
