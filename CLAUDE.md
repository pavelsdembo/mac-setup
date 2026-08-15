# Notes for agents

Decisions that look like obvious cleanups but are not. Each carries the reason
it would break, because a rule without one gets reverted.

- **App preferences are explicit `defaults write` calls**, in
  `steps/rectangle.sh` and `steps/app-prefs.sh`. Exported plists carried
  install identifiers, needed a strip pass before committing, and hid the
  settings in a binary format.

- **No `brew bundle --cleanup` / zap.** It uninstalls anything not in the
  Brewfile.

- **`steps/login-items.sh` is not redundant with the apps' own
  launch-at-login keys.** Those keys record intent; the app registers itself
  with macOS when the box is ticked in its UI. On a fresh machine the key
  alone leaves the box reading as on with nothing registered.

- **Raycast is installed, not configured.** Its plist holds onboarding state
  and anonymous IDs. Real config is server-side.

- **Keep the OFL text beside the `.ttf` files in `home/fonts/`.**
  Redistribution depends on it. The faces are stock Anonymous Pro 1.002, so
  the `font-anonymous-pro` cask would also do; vendoring pins the version and
  keeps the font available before Homebrew exists.

- **Fonts are copied, not linked.** macOS font registration is inconsistent
  about following symlinks out of `~/Library/Fonts`.

- **VS Code extensions come from `~/.vscode/extensions`, not
  `code --list-extensions`**, which reports only the active profile. For the
  same reason they are not `vscode` entries in the Brewfile. Regenerate with:

  ```sh
  ls ~/.vscode/extensions | grep -v '^\.' | grep -v '^extensions.json$' \
    | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+-[a-z0-9]+)?$//' \
    | sort -u > home/vscode/vscode-extensions.txt
  ```

- **`brew "node"` is required.** `home/.claude/settings.json` runs its
  statusline through `npx`.

- **Step order lives in `STEPS` in `setup-mac.sh`.** A file in `steps/` that is
  not listed aborts the run. Do not reintroduce numeric filename prefixes.

- **Only individual files under `~/.claude` are linked**, never the directory.
  It also holds caches, history and session state.

- **Git identity is not in this repo.** `setup-mac.sh` prints the commands.

- **VS Code profiles hold no settings here.** Profiles inherit from the default
  profile. Do not add `profiles/*/`: it is absolute paths and timestamps.

- **Nothing here uninstalls.** A normal run must stay safe to repeat, and a
  wipe-then-reinstall script is not worth the blast radius: `brew uninstall`
  takes dependencies other tools rely on, and `--zap` deletes application
  support data, including `~/.vscode` and the VS Code settings directory this
  repo symlinks into.

- **`task` is for commands that cannot prompt.** It collapses output onto a
  spinner line and closes stdin, so a password prompt would be invisible and
  the run would hang. The Homebrew installer and `brew bundle` (pkg casks ask
  for a password) print live instead.

- **There is no dry-run mode.** It printed commands without validating them,
  which hid a bad `brew bundle` flag through several previews. Steps are plain
  `defaults write` calls, so the file is the preview.

## Conventions

- `#!/usr/bin/env bash`, `set -euo pipefail`, quote every expansion.
- Resolve script directories with
  `"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"`.
- Preference changes belong in a step, not typed into a terminal.
- One `step` header per step file, then `ok` / `skip` / `warn` per result.
  Colour and the spinner turn themselves off when stdout is not a terminal.
- Comment the why, only where the code cannot show it. Most `defaults write`
  lines need nothing.

## Before changing a step

Run `./tests/run.sh`.
