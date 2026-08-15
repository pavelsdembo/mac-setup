#!/usr/bin/env bash
# steps/permissions.sh runs first and asks macOS for Automation access. A
# refusal is the user's to fix, so the step must report it and let the run
# carry on: the other twelve steps do not need the permission.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

STEP="${ROOT}/steps/permissions.sh"

# `true` and `false` stand in for a granted and a denied probe. Both swallow
# the AppleScript argument, so no prompt is ever raised here.
output=$(PERMISSIONS_PROBE="true" bash "$STEP" 2>&1) \
  || fail "permissions.sh exited non-zero when Automation is granted: $output"
assert_contains "$output" "can control System Events" "a granted probe reports success"

output=$(PERMISSIONS_PROBE="false" bash "$STEP" 2>&1) \
  || fail "permissions.sh exited non-zero when Automation is denied: $output"
pass "a denied probe does not take the run down"
assert_contains "$output" "login items will be skipped" "a denied probe says what breaks"
assert_contains "$output" "Privacy & Security > Automation" "and where to fix it"
