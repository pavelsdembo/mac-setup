#!/usr/bin/env bash
# steps/vscode.sh skips quietly when its list is missing, which is right on a
# machine without VS Code but would also hide a moved or renamed file. These
# checks make that failure loud instead.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

LIST="${ROOT}/home/vscode/vscode-extensions.txt"

# --- the list is where the step looks for it ---
# Read the path out of the step rather than hardcoding it here, so moving the
# file without updating the step fails this test.
step_path=$(grep -E '^LIST=' "${ROOT}/steps/vscode.sh" | head -1 | sed -E 's/^LIST="\$\{ROOT\}\/(.*)"$/\1/')
assert_eq "$step_path" "home/vscode/vscode-extensions.txt" "steps/vscode.sh points at the list"
assert_file "$LIST" "the extension list exists where the step expects it"

# --- and sits beside the settings it belongs with ---
assert_file "${ROOT}/home/vscode/settings.json" "settings.json is its neighbour"

# --- every line is a usable extension id ---
while IFS= read -r line; do
  case "$line" in ''|\#*) continue ;; esac
  printf '%s' "$line" | grep -qE '^[A-Za-z0-9][A-Za-z0-9_-]*\.[A-Za-z0-9][A-Za-z0-9_-]*$' \
    || fail "not a publisher.name extension id: '$line'"
done < "$LIST"
pass "every entry is a publisher.name extension id"

# --- no duplicates ---
total=$(grep -cvE '^\s*(#|$)' "$LIST")
unique=$(grep -vE '^\s*(#|$)' "$LIST" | sort -u | wc -l | tr -d ' ')
assert_eq "$total" "$unique" "the list has no duplicate entries"

# --- version suffixes must not leak in ---
# The list is derived from directory names like `ms-python.python-2026.4.0`,
# so a stripping mistake shows up as a trailing version.
assert_not_contains "$(cat "$LIST")" "-darwin-arm64" "no platform suffixes leaked in"
grep -qE '\-[0-9]+\.[0-9]+\.[0-9]+$' "$LIST" && fail "a version suffix leaked into the list"
pass "no version suffixes leaked in"

# --- a fresh machine has no extensions directory ---
# find exits 1 on a missing directory, pipefail propagates it and set -e kills
# the step, silently, taking the whole run with it. Only reproducible when
# ~/.vscode/extensions does not exist, which is exactly a new machine.
TMP=$(test_tmproot vscode)
export HOME="${TMP}/home"
mkdir -p "$HOME" "${TMP}/bin"

# A stub `code` so the step resolves a CLI without installing anything.
cat > "${TMP}/bin/code" <<'STUB'
#!/usr/bin/env bash
echo "$@" >> "${CODE_STUB_LOG}"
STUB
chmod +x "${TMP}/bin/code"
export CODE_STUB_LOG="${TMP}/installs.txt"
: > "$CODE_STUB_LOG"

output=$(PATH="${TMP}/bin:$PATH" VSCODE_PROFILE="mac-setup-test" VSCODE_PROFILE_WAIT=1 \
  bash "${ROOT}/steps/vscode.sh" 2>&1) \
  || fail "vscode.sh exited non-zero with no extensions directory: $output"
pass "vscode.sh survives a missing ~/.vscode/extensions"

wanted=$(grep -cvE '^\s*(#|$)' "$LIST")
got=$(grep -c -- '--install-extension' "$CODE_STUB_LOG")
assert_eq "$got" "$wanted" "every listed extension was installed"

# --- the named profile ---
# The stub cannot create a profile, which is also what a real failure looks
# like: VS Code never registers one and the wait times out. That must warn and
# let the run continue, not take it down.
assert_contains "$output" "could not create" "an uncreatable profile only warns"

# Nothing may be installed into a profile that does not exist, or the count
# above stops meaning anything.
assert_not_contains "$(cat "$CODE_STUB_LOG")" "--profile mac-setup-test --install-extension" \
  "no extensions are pushed into a profile that was never created"

# The name is the account name, which is what makes it match on a new machine.
name_line=$(grep -E '^VSCODE_PROFILE=' "${ROOT}/steps/vscode.sh")
assert_contains "$name_line" 'id -un' "the profile is named after the account"
