#!/usr/bin/env bash
# Link the config files in home/ into place. Editing them in the repo edits
# the live config. Anything already at a destination is backed up first.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Sublime resolves color_scheme paths against this directory.
SUBLIME_PACKAGES="${HOME}/Library/Application Support/Sublime Text/Packages"

# source (relative to home/) | destination
LINKS=(
  ".claude/settings.json|${HOME}/.claude/settings.json"
  ".claude/statusline-command.sh|${HOME}/.claude/statusline-command.sh"
  ".claude/hooks/herdr-agent-state.sh|${HOME}/.claude/hooks/herdr-agent-state.sh"
  ".config/wezterm/wezterm.lua|${HOME}/.config/wezterm/wezterm.lua"
  "vscode/settings.json|${HOME}/Library/Application Support/Code/User/settings.json"
  "sublime/Preferences.sublime-settings|${SUBLIME_PACKAGES}/User/Preferences.sublime-settings"
  "sublime/Dracula.tmTheme|${SUBLIME_PACKAGES}/Dracula Color Scheme/Dracula.tmTheme"
)

step "Config files"

for entry in "${LINKS[@]}"; do
  src="${ROOT}/home/${entry%%|*}"
  dest="${entry##*|}"
  link_file "$src" "$dest"
done

if [ -d "$BACKUP_DIR" ]; then
  info "replaced files saved in ${BACKUP_DIR#"$HOME"/}"
fi
