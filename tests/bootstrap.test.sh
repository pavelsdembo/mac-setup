#!/usr/bin/env bash
# bootstrap.sh runs on a machine that has none of this repo on it, fetched on
# its own over curl. Everything it can rely on is therefore different from
# every other script here, and these are the differences that matter.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BOOTSTRAP="${ROOT}/bootstrap.sh"

assert_file "$BOOTSTRAP" "bootstrap.sh is at the repo root"

# It is curled and run, so the bit has to be set in git, not just on disk.
mode=$(git -C "$ROOT" ls-files -s bootstrap.sh | cut -d' ' -f1)
assert_eq "$mode" "100755" "git tracks bootstrap.sh as executable"

# --- it must stand alone ---
# lib/common.sh lives in the repo bootstrap.sh exists to fetch, so sourcing it
# would fail on exactly the bare machine this is for. Matching `source` lines
# rather than the filename: the file names it in a comment explaining this.
sourced=$(grep -nE '^[[:space:]]*(\.|source)[[:space:]]' "$BOOTSTRAP" || true)
assert_eq "$sourced" "" "bootstrap.sh sources nothing from the repo"

# --- the four things that cannot be steps ---
# Each is here because setup-mac.sh cannot do it: three come before the repo
# exists, and the clone is what puts it there.
for needed in "install.sh" "brew install gh" "gh auth login" "git clone"; do
  assert_contains "$(cat "$BOOTSTRAP")" "$needed" "bootstrap.sh does $needed"
done

# --- arguments reach setup-mac.sh ---
# This is what makes `bootstrap.sh --list` a way to exercise the whole path
# without running a setup.
# shellcheck disable=SC2016  # matching the literal source text, not expanding it
assert_contains "$(cat "$BOOTSTRAP")" 'exec "${DEST}/setup-mac.sh" "$@"' \
  "bootstrap.sh hands its arguments to setup-mac.sh"

# --- it clones into the directory it was run from ---
# Not a fixed location, and not a setting: where the clone goes is whatever the
# user cd'd to. A hardcoded $HOME path would put it somewhere they did not ask
# for, and the symlinks all point back at wherever it lands.
# shellcheck disable=SC2016  # matching the literal source text, not expanding it
assert_contains "$(cat "$BOOTSTRAP")" 'DEST="${PWD}/${NAME}"' \
  "bootstrap.sh clones into the current directory"

home_path=$(grep -nE '\$\{?HOME\}?/' "$BOOTSTRAP" || true)
assert_eq "$home_path" "" "bootstrap.sh hardcodes no path under \$HOME"

# --- it refuses to run without a terminal ---
# Piping into bash makes the script text the answer to the first password
# prompt. Failing up front beats failing halfway through a Homebrew install.
output=$(bash "$BOOTSTRAP" </dev/null 2>&1)
status=$?
assert_eq "$status" "1" "bootstrap.sh exits non-zero with no terminal on stdin"
assert_contains "$output" "no terminal on stdin" "and says why"

# --- and the README tells people the form that keeps stdin ---
# shellcheck disable=SC2016  # matching the literal README text, not expanding it
assert_contains "$(cat "${ROOT}/README.md")" 'bash -c "$(curl -fsSL' \
  "README documents the form that leaves stdin free"
assert_not_contains "$(cat "${ROOT}/README.md")" 'curl -fsSL https://raw.githubusercontent.com/pavelsdembo/mac-setup/main/bootstrap.sh | bash' \
  "README does not tell people to pipe bootstrap.sh into bash"
