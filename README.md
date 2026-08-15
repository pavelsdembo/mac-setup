# mac-setup

One command to set up a Mac for AI-assisted development: packages, apps,
system preferences, and agent configuration.

Idempotent. Tested on macOS 26 (Tahoe), Apple Silicon.

## Usage

On a bare machine, run this from the directory you want the clone in:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pavelsdembo/mac-setup/main/bootstrap.sh)"
```

It installs Homebrew and `gh`, signs you in, clones, and runs `setup-mac.sh`.
Use the `bash -c "$(curl ...)"` form; do not pipe it into bash.

With Homebrew and a GitHub sign-in already there:

```sh
git clone https://github.com/pavelsdembo/mac-setup.git
cd mac-setup
./setup-mac.sh
```

```sh
./setup-mac.sh --list           # print the steps in run order
./setup-mac.sh macos rectangle  # run only the named steps
./tests/run.sh                  # tests and shellcheck
```

Keep the clone somewhere permanent: the symlinks point back at it.

## What you get

**CLI**  `ripgrep`, `fd`, `fzf`, `jq`, `gh`, `lazygit`, `shellcheck`, `tree`,
`uv`, `node`

**Apps**  Claude, Raycast, Rectangle, Hidden Bar, Stats, WezTerm, VS Code,
Sublime Text, Obsidian, Google Chrome, Spotify, Git Credential Manager

**Claude Code**  Installed with the official native installer, which
auto-updates

**Shell**  Oh My Zsh. An existing `~/.zshrc` is kept as
`~/.zshrc.pre-oh-my-zsh`; Homebrew's PATH line goes in `~/.zprofile`

**GitHub**  `gh auth login`, unless you are signed in already

**Fonts**  Anonymous Pro, four faces, bundled in `home/fonts/`

**Desktop**  Nothing on the desktop, Stage Manager off, widgets off,
click-wallpaper-to-reveal limited to Stage Manager

**Finder**  No drives or servers on the desktop, new windows open Home, all
file extensions shown, no extension-change warning, search scoped to the
current folder, status bar, path bar and tab bar visible

**Dock**  Auto-hiding, no launch animation, no recent apps

**Menu bar**  AirDrop and the battery glyph hidden, Control Centre shown,
analog clock with day of week and AM/PM

**Keyboard**  Cmd-Space taken off Spotlight, free for Raycast

**Rectangle**  Halves on Cmd+Opt+Arrow, top corners on Cmd+Ctrl+Arrow, bottom
corners on Cmd+Ctrl+Shift+Arrow, maximize Cmd+Opt+F, center Cmd+Opt+C, resize
Cmd+Opt+= and Cmd+Opt+-, todo mode Ctrl+Opt+B and Ctrl+Opt+N

**Stats**  Battery glyph alone, clock on, disk off

**Login items**  Raycast, Rectangle, Hidden Bar and Stats open at login, hidden

**WezTerm**  Dracula, Anonymous Pro Bold 20, tab bar hidden for a single tab,
unfocused windows dimmed

**VS Code**  Settings and extensions from `home/vscode/`, in the default
profile and in one named after your account. Creating that profile opens a VS
Code window once.

**Agents**  `home/AGENTS.md` linked to `~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md` and `~/.config/opencode/AGENTS.md`

## Layout

```
bootstrap.sh   bare-machine entry point; ends by running setup-mac.sh
setup-mac.sh   entry point; STEPS declares the run order
Brewfile       packages and casks
CLAUDE.md      notes for agents working in this repo (AGENTS.md links to it)
lib/           logging, quit_app, link_file
steps/         one file per concern, run in the order STEPS lists
home/          config files, linked into place
tests/         behaviour tests and the shellcheck gate
```

Everything under `home/` is symlinked, except `home/fonts/`, which is copied,
and `home/vscode/vscode-extensions.txt`, which its step reads.

## Making it yours

- `Brewfile` - packages and apps.
- `steps/macos.sh` - system preferences.
- `steps/rectangle.sh`, `steps/app-prefs.sh` - app preferences.
- `steps/login-items.sh` - which apps open at login.
- `home/AGENTS.md` - agent policy.
- `home/vscode/` - editor settings and extension list.
- `home/fonts/` - replace the `.ttf` files and update the font name in
  `home/.config/wezterm/wezterm.lua` and `home/vscode/settings.json`.

Existing files are moved to `~/.mac-setup-backup/<timestamp>/` before a
symlink replaces them. Nothing is uninstalled.

## Manual steps

1. **Privacy & Security > Automation** - allow the terminal to control System
   Events. The first step asks; decline it and login items are skipped.
2. **Privacy & Security > Accessibility** - enable Rectangle.
3. **Raycast** - sign in, enable Cloud Sync, and take Cmd-Space as its hotkey.
4. **Hidden Bar** - Cmd-drag menu bar icons left of its divider.
5. **Git identity** - not managed here:
   ```sh
   git config --global user.name  "Your Name"
   git config --global user.email you@example.com
   ```

## Licence

MIT No Attribution. See `LICENSE`. Anonymous Pro is separately licensed under
the SIL Open Font License 1.1; see `home/fonts/LICENSE-Anonymous-Pro.txt`.
