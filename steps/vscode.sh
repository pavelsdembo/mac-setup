#!/usr/bin/env bash
# Install the VS Code extensions listed in home/vscode/vscode-extensions.txt.
# Settings are linked by steps/symlinks.sh.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "VS Code extensions"

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

while read -r ext; do
  case "$ext" in ''|\#*) continue ;; esac

  if printf '%s\n' "$installed" | grep -qxF "$ext"; then
    skip "$ext"
    continue
  fi

  task "$ext" "$CODE" --install-extension "$ext" --force
done < "$LIST"
