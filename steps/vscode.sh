#!/usr/bin/env bash
# Install the VS Code extensions listed in home/vscode/vscode-extensions.txt,
# into the default profile and into a profile named after the account.
#
# The default profile's settings are linked by steps/symlinks.sh. The named
# profile's are linked here instead, because the directory VS Code gives it is
# only known once the profile exists.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Overridable so tests can name a throwaway profile and not wait on it.
VSCODE_PROFILE="${VSCODE_PROFILE:-$(id -un)}"
VSCODE_PROFILE_WAIT="${VSCODE_PROFILE_WAIT:-30}"
CODE_USER_DIR="${CODE_USER_DIR:-${HOME}/Library/Application Support/Code/User}"

step "VS Code"

LIST="${ROOT}/home/vscode/vscode-extensions.txt"

# The cask puts `code` on PATH; VS Code installed by hand does not.
BUNDLED_CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if have code; then
  CODE="code"
elif [ -x "$BUNDLED_CODE" ]; then
  CODE="$BUNDLED_CODE"
else
  skip "VS Code is not installed yet"
  exit 0
fi

[ -f "$LIST" ] || { skip "no home/vscode/vscode-extensions.txt"; exit 0; }

# install_missing <what is already there> [extra code arguments...]
install_missing() {
  local installed=$1; shift
  local ext

  while read -r ext; do
    case "$ext" in ''|\#*) continue ;; esac

    if printf '%s\n' "$installed" | grep -qxF "$ext"; then
      skip "$ext"
      continue
    fi

    task "$ext" "$CODE" "$@" --install-extension "$ext" --force
  done < "$LIST"
}


# --- the default profile ---

# --list-extensions only reports the active profile, so read the extensions
# directory instead. -type d also skips the extensions.json manifest.
#
# The directory is absent until the first extension is installed. Testing for
# it first, rather than discarding find's stderr, keeps `set -e` from killing
# the step on a fresh machine with nothing to report.
EXT_DIR="${HOME}/.vscode/extensions"
installed=""
if [ -d "$EXT_DIR" ]; then
  installed=$(find "$EXT_DIR" -mindepth 1 -maxdepth 1 -type d \
    | sed -E 's|.*/||; s/-[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+-[a-z0-9]+)?$//' \
    | sort -u)
fi

install_missing "$installed"


# --- a profile named after the account ---

STORAGE="${CODE_USER_DIR}/globalStorage/storage.json"

# VS Code names the profile's directory with a hash it records in storage.json.
# There is no way to derive it, so read back what VS Code chose.
profile_location() {
  [ -f "$STORAGE" ] || return 1
  jq -r --arg name "$VSCODE_PROFILE" \
    'first((.userDataProfiles // [])[] | select(.name == $name) | .location) // empty' \
    "$STORAGE" 2>/dev/null
}

if ! have jq; then
  skip "jq is missing, so the ${VSCODE_PROFILE} profile is left alone"
  exit 0
fi

location="$(profile_location || true)"

if [ -z "$location" ]; then
  # `--profile` alone errors with "Profile not found": only the folder-opening
  # path creates one, so a window is what brings the profile into being. The
  # folder is an empty temp one so VS Code ties the profile to nothing real.
  seed="$(mktemp -d "${TMPDIR:-/tmp}/mac-setup-vscode.XXXXXX")"
  info "opening a VS Code window to create the ${VSCODE_PROFILE} profile"
  "$CODE" --profile "$VSCODE_PROFILE" "$seed" >/dev/null 2>&1 || true

  waited=0
  while [ "$waited" -lt "$VSCODE_PROFILE_WAIT" ]; do
    sleep 1
    waited=$((waited + 1))
    location="$(profile_location || true)"
    if [ -n "$location" ]; then break; fi
  done

  rmdir "$seed" 2>/dev/null || true
fi

if [ -z "$location" ]; then
  warn "could not create the ${VSCODE_PROFILE} profile - make it in VS Code and re-run"
  exit 0
fi

PROFILE_DIR="${CODE_USER_DIR}/profiles/${location}"
mkdir -p "$PROFILE_DIR"
link_file "${ROOT}/home/vscode/settings.json" "${PROFILE_DIR}/settings.json"

# A new profile starts with no extensions, sharing only the download cache. Ask
# the profile, not ~/.vscode/extensions, which answers for all of them at once.
profile_installed="$("$CODE" --profile "$VSCODE_PROFILE" --list-extensions 2>/dev/null || true)"
install_missing "$profile_installed" --profile "$VSCODE_PROFILE"
