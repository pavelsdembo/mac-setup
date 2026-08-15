#!/usr/bin/env bash
# A wrong brew flag only shows up when the step actually runs, and by then it
# has aborted the setup. These checks exercise the real invocation against an
# empty Brewfile: no network installs, no side effects.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v brew >/dev/null 2>&1 || { pass "skipped, brew not installed"; exit 0; }

TMP=$(test_tmproot packages)
EMPTY="${TMP}/Brewfile"
: > "$EMPTY"

# Pull the flags the step actually passes, so this tracks the step rather than
# a copy of it that can drift.
args=$(grep -E '^BUNDLE_ARGS=' "${ROOT}/steps/packages.sh")
assert_contains "$args" "--no-upgrade" "the step passes --no-upgrade"
assert_not_contains "$args" "--adopt" "--adopt is not passed to brew bundle"

# --adopt is a cask flag and must travel via the environment.
assert_contains "$(grep -E '^export HOMEBREW_CASK_OPTS' "${ROOT}/steps/packages.sh")" \
  "--adopt" "--adopt is passed through HOMEBREW_CASK_OPTS"

# The real thing: brew must accept this invocation.
if ! output=$(HOMEBREW_CASK_OPTS="--adopt" brew bundle --file="$EMPTY" --no-upgrade 2>&1); then
  fail "brew rejected the invocation: $(printf '%s' "$output" | tail -2)"
fi
assert_not_contains "$output" "invalid option" "brew accepts every flag the step uses"
pass "brew bundle runs with the step's flags"

# And the Brewfile itself must parse.
if ! output=$(brew bundle list --file="${ROOT}/Brewfile" 2>&1); then
  fail "Brewfile does not parse: $(printf '%s' "$output" | tail -2)"
fi
pass "the Brewfile parses"

# --- brew must be found by a step that did not inherit a shell's PATH ---
# setup-mac.sh runs each step in its own process, so the `eval brew shellenv`
# in steps/homebrew.sh cannot reach the steps after it. On a fresh machine
# that made packages.sh die with "Homebrew missing" one step after installing it.
if [ -x /opt/homebrew/bin/brew ]; then
  output=$(env -i HOME="$HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    bash -c '. "'"${ROOT}"'/lib/common.sh"; have brew && echo FOUND' 2>&1)
  assert_contains "$output" "FOUND" "a step finds brew without a login shell's PATH"
fi
