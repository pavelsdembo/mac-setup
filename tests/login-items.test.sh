#!/usr/bin/env bash
# steps/login-items.sh must register an app with macOS and leave an already
# registered one alone. Runs against a throwaway bundle, removed on exit.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

PROBE_NAME="mac-setup login item test"

login_items() {
  osascript -e 'tell application "System Events" to get the name of every login item' 2>&1
}

cleanup() {
  osascript -e "tell application \"System Events\" to delete login item \"${PROBE_NAME}\"" \
    >/dev/null 2>&1 || true
  test_cleanup
}
trap cleanup EXIT

# Automation access is a click the user has to make, and CI has nobody to make
# it. Skip rather than fail: the step warns in the same situation.
case "$(login_items)" in
  *"execution error"*)
    printf '# skipped - this terminal cannot control System Events\n'
    exit 0 ;;
esac

TMP="$(test_tmproot login-items)"
PROBE="${TMP}/${PROBE_NAME}.app"
mkdir -p "${PROBE}/Contents/MacOS"

run_step() { LOGIN_ITEM_APPS="$1" bash "${ROOT}/steps/login-items.sh" 2>&1; }

# --- a real bundle gets registered ---
output=$(run_step "$PROBE") || fail "login-items.sh exited non-zero: $output"
assert_contains "$(login_items)" "$PROBE_NAME" "the app was added to the login items"

# --- and a second run leaves it alone ---
output=$(run_step "$PROBE") || fail "login-items.sh exited non-zero on re-run: $output"
assert_contains "$output" "already opens at login" "a registered app is left alone"

count=$(login_items | tr ',' '\n' | grep -c "$PROBE_NAME")
assert_eq "$count" "1" "re-running does not add a duplicate"

# --- an app that is not installed warns instead of failing ---
output=$(run_step "${TMP}/Not Installed.app") \
  || fail "login-items.sh exited non-zero for a missing app: $output"
assert_contains "$output" "not installed" "a missing app is reported, not fatal"
assert_not_contains "$(login_items)" "Not Installed" "a missing app is not registered"

# --- every app the repo installs for the menu bar is covered ---
for app in "Hidden Bar" Raycast Rectangle Stats; do
  assert_contains "$(cat "${ROOT}/steps/login-items.sh")" "/Applications/${app}.app" \
    "${app} is in the login items list"
done
