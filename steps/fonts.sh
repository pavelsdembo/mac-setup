#!/usr/bin/env bash
# Install home/fonts/*.ttf into ~/Library/Fonts.
#
# Copied, not symlinked: macOS font registration is inconsistent about
# following symlinks out of ~/Library/Fonts.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

SRC_DIR="${ROOT}/home/fonts"
DEST_DIR="${HOME}/Library/Fonts"

[ -d "$SRC_DIR" ] || die "missing home/fonts/"

step "Fonts"
mkdir -p "$DEST_DIR"

installed=0
while IFS= read -r font; do
  name="$(basename "$font")"
  dest="${DEST_DIR}/${name}"

  # cmp rather than a timestamp: byte-identical is already correct.
  if [ -f "$dest" ] && cmp -s "$font" "$dest"; then
    skip "$name"
    continue
  fi

  cp "$font" "$dest"
  ok "installed $name"
  installed=$((installed + 1))
done < <(find "$SRC_DIR" -maxdepth 1 -name '*.ttf' -type f | sort)

if [ "$installed" -gt 0 ]; then
  info "restart open apps to pick up the new fonts"
fi
