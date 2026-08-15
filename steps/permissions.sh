#!/usr/bin/env bash
# Ask for the Automation permission up front, while someone is still watching.
#
# macOS raises the prompt the first time this terminal sends an AppleEvent, and
# grants it to the terminal rather than to a script. Asking here means the
# dialog is answered before the long part of the run, instead of at
# login-items.sh, which would skip every app with a warning.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Overridable so tests can probe without a GUI prompt.
PERMISSIONS_PROBE="${PERMISSIONS_PROBE:-osascript -e}"

step "Permissions"

info "macOS may ask to let this terminal control System Events - allow it"

# The lightest AppleEvent there is. It needs Automation and nothing else.
if $PERMISSIONS_PROBE 'tell application "System Events" to get name' >/dev/null 2>&1; then
  ok "this terminal can control System Events"
else
  warn "Automation is denied, so login items will be skipped."
  warn "Allow it under Privacy & Security > Automation, then re-run."
fi
