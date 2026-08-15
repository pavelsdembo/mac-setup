#!/usr/bin/env bash
# steps/rectangle.sh must write the documented keyCode/modifierFlags pairs as
# real nested dictionaries. Runs against a throwaway domain.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TEST_DOMAIN="com.example.mac-setup-rectangle-test"

cleanup() {
  defaults delete "$TEST_DOMAIN" 2>/dev/null || true
  test_cleanup
}
trap cleanup EXIT

# RECTANGLE_APP points at a process that does not exist, so quit_app is a no-op
# and a running Rectangle is left alone.
RECTANGLE_DOMAIN="$TEST_DOMAIN" \
RECTANGLE_APP="MacSetupTestNoSuchApp" \
  bash "${ROOT}/steps/rectangle.sh" >/dev/null 2>&1 \
  || fail "rectangle.sh exited non-zero"

pass "rectangle.sh ran"

# Cmd+Opt = 1048576 + 524288 = 1572864
assert_eq "$(read_shortcut "$TEST_DOMAIN" leftHalf)"   "123,1572864" "leftHalf is Cmd+Opt+Left"
assert_eq "$(read_shortcut "$TEST_DOMAIN" rightHalf)"  "124,1572864" "rightHalf is Cmd+Opt+Right"
assert_eq "$(read_shortcut "$TEST_DOMAIN" topHalf)"    "126,1572864" "topHalf is Cmd+Opt+Up"
assert_eq "$(read_shortcut "$TEST_DOMAIN" bottomHalf)" "125,1572864" "bottomHalf is Cmd+Opt+Down"

# Cmd+Ctrl = 1048576 + 262144 = 1310720
assert_eq "$(read_shortcut "$TEST_DOMAIN" topLeft)"  "123,1310720" "topLeft is Cmd+Ctrl+Left"
assert_eq "$(read_shortcut "$TEST_DOMAIN" topRight)" "124,1310720" "topRight is Cmd+Ctrl+Right"

# Cmd+Ctrl+Shift = 1310720 + 131072 = 1441792
assert_eq "$(read_shortcut "$TEST_DOMAIN" bottomLeft)"  "123,1441792" "bottomLeft is Cmd+Ctrl+Shift+Left"
assert_eq "$(read_shortcut "$TEST_DOMAIN" bottomRight)" "124,1441792" "bottomRight is Cmd+Ctrl+Shift+Right"

assert_eq "$(read_shortcut "$TEST_DOMAIN" maximize)" "3,1572864"  "maximize is Cmd+Opt+F"
assert_eq "$(read_shortcut "$TEST_DOMAIN" center)"   "8,1572864"  "center is Cmd+Opt+C"

# Ctrl+Opt = 262144 + 524288 = 786432
assert_eq "$(read_shortcut "$TEST_DOMAIN" toggleTodo)" "11,786432" "toggleTodo is Ctrl+Opt+B"
assert_eq "$(read_shortcut "$TEST_DOMAIN" reflowTodo)" "45,786432" "reflowTodo is Ctrl+Opt+N"

# The shortcuts must be real dictionaries, not strings that merely look right.
assert_eq "$(read_default_type "$TEST_DOMAIN" leftHalf)" "Type is dictionary" \
  "shortcuts are written as dictionaries"

assert_eq "$(read_default "$TEST_DOMAIN" launchOnLogin)" "1" "launchOnLogin is set"
assert_eq "$(read_default "$TEST_DOMAIN" footprintAnimationDurationMultiplier)" "0" \
  "window animation is disabled"
