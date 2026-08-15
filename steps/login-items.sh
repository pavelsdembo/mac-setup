#!/usr/bin/env bash
# Register the launcher and menu bar utilities to open at login.
#
# Not redundant with each app's own "launch at login" key, written in
# app-prefs.sh and rectangle.sh. That key only records the app's intent; the
# app registers itself with macOS when the box is ticked in its UI. On a fresh
# machine the box reads as on while nothing is registered and nothing starts.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Overridable so tests can register a throwaway bundle. One path per line:
# the paths contain spaces, so this cannot be a plain list.
LOGIN_ITEM_APPS="${LOGIN_ITEM_APPS:-$(cat <<'EOF'
/Applications/Hidden Bar.app
/Applications/Raycast.app
/Applications/Rectangle.app
/Applications/Stats.app
EOF
)}"

step "Login items"

# The login item is named after the bundle, which is how System Events finds
# it again on a re-run.
add_login_item() {
  local app=$1 name
  name="$(basename "$app" .app)"

  if [ ! -d "$app" ]; then
    warn "$name is not installed, so it was not added to the login items"
    return 0
  fi

  if osascript -e "tell application \"System Events\" to get login item \"${name}\"" \
       >/dev/null 2>&1; then
    skip "$name already opens at login"
    return 0
  fi

  # Denied Automation access is the likely failure, and granting it is the
  # user's to do. Warn rather than take down the rest of the run.
  if ! osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"${app}\", hidden:true}" \
       >/dev/null 2>&1; then
    warn "$name was not added. Allow this terminal to control System Events under"
    warn "Privacy & Security > Automation, then re-run: ./setup-mac.sh login-items"
    return 0
  fi

  info "$name opens at login"
}

while IFS= read -r app; do
  [ -n "$app" ] || continue
  add_login_item "$app"
done <<< "$LOGIN_ITEM_APPS"
