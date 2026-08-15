#!/usr/bin/env bash
# link_file must never destroy an existing file: anything real at the
# destination is moved into the backup directory before the link is made.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP=$(test_tmproot symlink)

# common.sh computes BACKUP_DIR from $HOME when it is sourced, so point HOME
# at the temp root before sourcing it.
export HOME="${TMP}/home"
mkdir -p "$HOME"

# shellcheck source=lib/common.sh
. "${ROOT}/lib/common.sh"

SRC="${TMP}/repo/config.json"
mkdir -p "$(dirname "$SRC")"
printf 'from repo\n' > "$SRC"

# --- case 1: destination does not exist ---
DEST="${HOME}/.config/app/config.json"
link_file "$SRC" "$DEST" >/dev/null
assert_symlink_to "$DEST" "$SRC" "links into a path that did not exist"
assert_eq "$(cat "$DEST")" "from repo" "linked file reads through to the repo"

# --- case 2: destination is a real file that must be preserved ---
DEST2="${HOME}/.config/app/existing.json"
printf 'precious user data\n' > "$DEST2"

link_file "$SRC" "$DEST2" >/dev/null
assert_symlink_to "$DEST2" "$SRC" "replaces an existing file with the link"

backed_up=$(find "${HOME}/.mac-setup-backup" -name 'existing.json' -type f 2>/dev/null | head -1)
[ -n "$backed_up" ] || fail "existing file was not backed up"
assert_eq "$(cat "$backed_up")" "precious user data" "backup preserves the original contents"

# --- case 3: already linked is a no-op ---
output=$(link_file "$SRC" "$DEST")
assert_contains "$output" "already linked" "re-linking is a skip, not a rewrite"
