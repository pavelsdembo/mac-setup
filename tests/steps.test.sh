#!/usr/bin/env bash
# The explicit STEPS list is only safe if a step file left out of it fails
# loudly instead of silently never running.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

STRAY="${ROOT}/steps/zz-unlisted-test-step.sh"

cleanup() {
  rm -f "$STRAY"
  test_cleanup
}
trap cleanup EXIT

# --- every step on disk is listed, and every listed step exists ---
output=$(bash "${ROOT}/setup-mac.sh" --list 2>&1) \
  || fail "setup-mac.sh --list exited non-zero: $output"

for script in "${ROOT}"/steps/*.sh; do
  name="$(basename "$script")"
  assert_contains "$output" "$name" "steps/${name} is listed in STEPS"
done

listed_count=$(printf '%s\n' "$output" | grep -c '\.sh$')
on_disk_count=$(find "${ROOT}/steps" -name '*.sh' -type f | wc -l | tr -d ' ')
assert_eq "$listed_count" "$on_disk_count" "STEPS and steps/ hold the same number of files"

# --- a step file that is not listed must abort the run ---
cat > "$STRAY" <<'SH'
#!/usr/bin/env bash
echo "this step should never run"
SH
chmod +x "$STRAY"

# --list exits before running anything, so the guard is checked without
# executing a single step.
if output=$(bash "${ROOT}/setup-mac.sh" --list 2>&1); then
  fail "an unlisted step file did not abort the run"
fi
assert_contains "$output" "is not in STEPS" "unlisted step names itself in the error"
assert_not_contains "$output" "this step should never run" "unlisted step was not executed"

rm -f "$STRAY"

# --- ordering constraints that actually matter ---
order=$(bash "${ROOT}/setup-mac.sh" --list)
position() { printf '%s\n' "$order" | grep -n "^$1$" | cut -d: -f1; }

[ "$(position homebrew.sh)" -lt "$(position packages.sh)" ] \
  || fail "homebrew.sh must run before packages.sh"
pass "homebrew.sh runs before packages.sh"

# The Automation prompt is a dialog someone has to answer. Asking at the top
# means it is answered before the long part of the run, not eleven steps in.
[ "$(position permissions.sh)" -eq 1 ] \
  || fail "permissions.sh must run first, so the Automation prompt comes up front"
pass "permissions.sh runs first"

[ "$(position permissions.sh)" -lt "$(position login-items.sh)" ] \
  || fail "permissions.sh must run before login-items.sh, which needs the grant"
pass "permissions.sh runs before login-items.sh"

[ "$(position homebrew.sh)" -lt "$(position oh-my-zsh.sh)" ] \
  || fail "homebrew.sh must run before oh-my-zsh.sh (its installer needs git)"
pass "homebrew.sh runs before oh-my-zsh.sh"

[ "$(position packages.sh)" -lt "$(position github.sh)" ] \
  || fail "packages.sh must run before github.sh (it installs gh)"
pass "packages.sh runs before github.sh"

[ "$(position packages.sh)" -lt "$(position vscode.sh)" ] \
  || fail "packages.sh must run before vscode.sh (it installs the code CLI)"
pass "packages.sh runs before vscode.sh"

[ "$(position fonts.sh)" -lt "$(position packages.sh)" ] \
  || fail "fonts.sh must run before packages.sh installs the apps that use them"
pass "fonts.sh runs before packages.sh"

[ "$(position packages.sh)" -lt "$(position login-items.sh)" ] \
  || fail "packages.sh must run before login-items.sh (the bundles must exist)"
pass "packages.sh runs before login-items.sh"

# --- filtering ---
# Filtering is checked by reading the resolver rather than running steps.
wanted_block=$(sed -n '/^wanted()/,/^}/p' "${ROOT}/setup-mac.sh")
# shellcheck disable=SC2016  # matching the literal source text, not expanding it
assert_contains "$wanted_block" 'case "$name" in "$f"*)' "steps are matched by name prefix"
