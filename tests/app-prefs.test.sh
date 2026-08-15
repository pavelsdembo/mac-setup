#!/usr/bin/env bash
# steps/app-prefs.sh must write the documented values, with the right types.
# Runs against throwaway domains, so live settings are never touched.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

STATS="com.example.mac-setup-stats-test"
HIDDENBAR="com.example.mac-setup-hiddenbar-test"

cleanup() {
  defaults delete "$STATS" 2>/dev/null || true
  defaults delete "$HIDDENBAR" 2>/dev/null || true
  test_cleanup
}
trap cleanup EXIT

run_step() {
  STATS_DOMAIN="$STATS" HIDDENBAR_DOMAIN="$HIDDENBAR" APP_PREFS_QUIT=0 \
    bash "${ROOT}/steps/app-prefs.sh"
}

run_step >/dev/null 2>&1 || fail "app-prefs.sh exited non-zero"
pass "app-prefs.sh ran"

# --- Hidden Bar ---
assert_eq "$(read_default "$HIDDENBAR" isAutoStart)" "1" "Hidden Bar starts at login"
assert_eq "$(read_default "$HIDDENBAR" useFullStatusBarOnExpandEnabled)" "0" \
  "Hidden Bar does not take the full status bar on expand"

# --- Stats ---
assert_eq "$(read_default "$STATS" Clock_state)" "1" "clock module on"
assert_eq "$(read_default "$STATS" Disk_state)"  "0" "disk module off"
assert_eq "$(read_default "$STATS" LaunchAtLoginNext)" "1" "Stats starts at login"
assert_eq "$(read_default "$STATS" Battery_widget)" "battery" "battery shows the glyph alone"
# Battery_widget is a comma-separated list, so a comma means a second widget
# crept back into the module.
assert_not_contains "$(read_default "$STATS" Battery_widget)" "," \
  "no other battery widget is enabled"
assert_eq "$(read_default "$STATS" Battery_barChart_position)" "3" "battery element order"

# Booleans must be booleans and integers integers, or Stats ignores them.
assert_eq "$(read_default_type "$STATS" Battery_oneView)" "Type is boolean" \
  "booleans are written as booleans"
assert_eq "$(read_default_type "$STATS" Battery_mini_position)" "Type is integer" \
  "positions are written as integers"

# --- the clock blob round-trips ---
assert_eq "$(read_default_type "$STATS" Clock_list)" "Type is data" \
  "Clock_list is written as data"

decoded=$(python3 -c "
import subprocess, plistlib, sys
raw = subprocess.run(['defaults','export','$STATS','-'],capture_output=True).stdout
print(plistlib.loads(raw)['Clock_list'].decode())
")
assert_contains "$decoded" '"tz":"local"' "clock is the local timezone"
assert_contains "$decoded" 'E, MMM d' "clock keeps its custom format string"
