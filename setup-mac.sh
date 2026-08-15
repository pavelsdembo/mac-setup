#!/usr/bin/env bash
# One-command Mac setup. Idempotent - safe to re-run.
#
#     ./setup-mac.sh                 run every step
#     ./setup-mac.sh macos rectangle run only the named steps
#     ./setup-mac.sh --list          list the steps in run order
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

# Run order. The comments mark the entries whose position matters.
STEPS=(
  permissions.sh   # first: the Automation prompt needs answering before login-items.sh
  fonts.sh         # before any app first launches
  homebrew.sh      # puts brew on PATH for everything below
  oh-my-zsh.sh     # its installer needs the git the Xcode tools bring in
  packages.sh      # installs the apps the steps below configure
  github.sh        # needs gh from packages.sh
  claude-code.sh
  vscode.sh        # needs the `code` CLI from packages.sh
  macos.sh
  app-prefs.sh
  rectangle.sh
  login-items.sh   # needs the apps from packages.sh to exist on disk
  symlinks.sh
  agents.sh
)

FILTERS=()
LIST_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --list)    LIST_ONLY=1 ;;
    -h|--help) sed -n '2,6p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        die "unknown option: $arg" ;;
    *)         FILTERS+=("$arg") ;;
  esac
done

# An unlisted step file would never run, and nothing would say so.
for script in "${SCRIPT_DIR}"/steps/*.sh; do
  name="$(basename "$script")"
  listed=0
  for s in "${STEPS[@]}"; do
    [ "$s" = "$name" ] && { listed=1; break; }
  done
  [ "$listed" -eq 1 ] || die "steps/${name} is not in STEPS in setup-mac.sh, so it would never run"
done

for s in "${STEPS[@]}"; do
  [ -f "${SCRIPT_DIR}/steps/${s}" ] || die "STEPS lists steps/${s}, which does not exist"
done

if [ "$LIST_ONLY" -eq 1 ]; then
  printf '%s\n' "${STEPS[@]}"
  exit 0
fi

wanted() {
  [ "${#FILTERS[@]}" -eq 0 ] && return 0
  local name=$1 f
  for f in "${FILTERS[@]}"; do
    case "$name" in "$f"*) return 0 ;; esac
  done
  return 1
}

total=0
for s in "${STEPS[@]}"; do
  wanted "$s" && total=$((total + 1))
done

n=0
for s in "${STEPS[@]}"; do
  wanted "$s" || continue
  n=$((n + 1))

  printf '\n%s[%d/%d] %s%s\n' "$_DIM" "$n" "$total" "$s" "$_RESET"
  bash "${SCRIPT_DIR}/steps/${s}"
done

printf '\n%sSetup complete%s\n' "$_BOLD" "$_RESET"

cat <<'EOF'

Left to do by hand:

  1. Privacy & Security > Accessibility: enable Rectangle.
  2. Raycast: sign in, turn on Cloud Sync, and set its hotkey to Cmd-Space,
     which is now free. Hotkeys, aliases and snippets live server-side.
  3. Hidden Bar: Cmd-drag menu bar icons left of its divider.
  4. git identity:
       git config --global user.name  "Your Name"
       git config --global user.email you@example.com

EOF
