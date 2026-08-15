#!/usr/bin/env bash
# Shared primitives for the step scripts. Exports ROOT, the repository root.

if [ -n "${MAC_SETUP_COMMON_SOURCED:-}" ]; then
  return 0
fi
MAC_SETUP_COMMON_SOURCED=1

# pwd -P so the repo still finds itself when it is linked rather than cloned.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export ROOT

# --- output ---

if [ -t 1 ]; then
  _TTY=1
  _BOLD=$'\033[1m'; _DIM=$'\033[2m'; _GREEN=$'\033[32m'; _RED=$'\033[31m'
  _YELLOW=$'\033[33m'; _RESET=$'\033[0m'
else
  _TTY=0
  _BOLD=""; _DIM=""; _GREEN=""; _RED=""; _YELLOW=""; _RESET=""
fi

step() { printf '%s%s%s\n' "$_BOLD" "$1" "$_RESET"; }
ok()   { printf '  %s✓%s %s\n' "$_GREEN" "$_RESET" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$_RED" "$_RESET" "$1" >&2; }
info() { printf '    %s\n' "$1"; }
skip() { printf '  %s· %s%s\n' "$_DIM" "$1" "$_RESET"; }
warn() { printf '  %s! %s%s\n' "$_YELLOW" "$1" "$_RESET" >&2; }
die()  { bad "$1"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Homebrew installs outside the default PATH, and the eval in steps/homebrew.sh
# dies with that step's process: setup-mac.sh runs each step separately. Every
# step picks brew up here instead, so the run never depends on the user having
# opened a new shell.
if ! have brew; then
  for _prefix in /opt/homebrew /usr/local; do
    if [ -x "${_prefix}/bin/brew" ]; then
      eval "$("${_prefix}/bin/brew" shellenv)"
      break
    fi
  done
fi

# --- tasks ---

_SPIN=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# task <message> <command...>
# Runs the command on a single spinning line that a tick replaces when it
# finishes. Output is held back and printed only if it fails.
#
# Not for anything that can prompt: a password prompt would land in the log
# where nobody can see it, and the run would hang on a spinner.
task() {
  local msg=$1; shift
  local log status=0 pid i=0

  log="$(mktemp "${TMPDIR:-/tmp}/mac-setup.XXXXXX")"

  # stdin is closed: a command that tries to prompt fails fast instead of
  # hanging on a spinner nobody can answer.
  if [ "$_TTY" != 1 ]; then
    "$@" >"$log" 2>&1 </dev/null || status=$?
  else
    "$@" >"$log" 2>&1 </dev/null &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s%s %s%s' "$_DIM" "${_SPIN[$((i % ${#_SPIN[@]}))]}" "$msg" "$_RESET"
      i=$((i + 1))
      sleep 0.08
    done
    wait "$pid" || status=$?
    printf '\r\033[2K'
  fi

  if [ "$status" -eq 0 ]; then
    ok "$msg"
  else
    bad "$msg"
    sed 's/^/    /' "$log" >&2
  fi

  rm -f "$log"
  return "$status"
}

# --- mutation ---

# A running app holds its preferences in memory and rewrites its plist on quit,
# silently undoing anything written underneath it.
quit_app() {
  local process=$1
  pgrep -x "$process" >/dev/null 2>&1 || return 0

  info "quitting $process"
  osascript -e "tell application \"${process}\" to quit" 2>/dev/null || true
  sleep 1
  pkill -x "$process" 2>/dev/null || true
  sleep 1
}

# cfprefsd caches preferences; restart it so apps read fresh values.
reload_prefs() { killall cfprefsd 2>/dev/null || true; }

# --- symlinking ---

BACKUP_DIR="${HOME}/.mac-setup-backup/$(date +%Y%m%d-%H%M%S)"

# link_file <source in repo> <destination>. Backs up whatever is already there.
link_file() {
  local src=$1 dest=$2

  [ -e "$src" ] || { warn "missing source $src"; return 1; }

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    skip "${dest#"$HOME"/} already linked"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${dest#"$HOME"/}")"
    mv "$dest" "$BACKUP_DIR/${dest#"$HOME"/}"
    info "backed up the existing ${dest#"$HOME"/}"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  ok "linked ${dest#"$HOME"/}"
}
