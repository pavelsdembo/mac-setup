#!/usr/bin/env bash
# Shared primitives for the behaviour tests. Output is TAP-ish; a test file
# exits non-zero on the first failure.

if [ -n "${MAC_SETUP_TEST_LIB_SOURCED:-}" ]; then
  return 0
fi
MAC_SETUP_TEST_LIB_SOURCED=1

# shellcheck disable=SC2034
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }

# --- self-cleaning temp root ---

# Created and trapped here at source time, not inside test_tmproot: that runs
# as TMP=$(test_tmproot ...), and a trap set in the subshell would fire the
# moment the substitution ends, deleting the directory it just returned.
TEST_TMP_BASE="$(mktemp -d "${TMPDIR:-/tmp}/mac-setup-test.XXXXXX")"

test_cleanup() {
  [ -n "${TEST_TMP_BASE:-}" ] && [ -d "$TEST_TMP_BASE" ] && rm -rf "$TEST_TMP_BASE"
  return 0
}
trap test_cleanup EXIT

test_tmproot() {
  local prefix=${1:-t} dir
  dir="${TEST_TMP_BASE}/${prefix}.$$-${RANDOM}"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

# --- assertions ---

assert_eq() {
  local actual=$1 expected=$2 message=$3
  [ "$actual" = "$expected" ] || fail "$message (got '$actual', want '$expected')"
  pass "$message"
}

assert_contains() {
  local haystack=$1 needle=$2 message=$3
  case "$haystack" in
    *"$needle"*) pass "$message" ;;
    *) fail "$message (missing '$needle')" ;;
  esac
}

assert_not_contains() {
  local haystack=$1 needle=$2 message=$3
  case "$haystack" in
    *"$needle"*) fail "$message (unexpectedly found '$needle')" ;;
    *) pass "$message" ;;
  esac
}

assert_file() {
  local path=$1 message=$2
  [ -f "$path" ] || fail "$message (no file at $path)"
  pass "$message"
}

assert_symlink_to() {
  local link=$1 target=$2 message=$3
  [ -L "$link" ] || fail "$message ($link is not a symlink)"
  assert_eq "$(readlink "$link")" "$target" "$message"
}

# --- preference helpers ---

# Every step signs off with `killall cfprefsd`. A read that lands before the
# daemon is back comes back empty, so each of these retries briefly rather
# than reporting a preference the step did write as missing.

_read_retry() {
  local out="" tries=5
  while [ "$tries" -gt 0 ]; do
    out=$("$@" 2>/dev/null)
    [ -n "$out" ] && break
    tries=$((tries - 1))
    sleep 0.2
  done
  printf '%s\n' "$out"
}

read_default()      { _read_retry defaults read "$1" "$2"; }
read_default_type() { _read_retry defaults read-type "$1" "$2"; }

# A nested Rectangle-style shortcut, as "keyCode,modifierFlags". One read for
# both fields: reading twice made the race a coin toss between them.
read_shortcut() {
  local domain=$1 action=$2 out="" tries=5
  while [ "$tries" -gt 0 ]; do
    out=$(defaults read "$domain" "$action" 2>/dev/null)
    case "$out" in *keyCode*) break ;; esac
    tries=$((tries - 1))
    sleep 0.2
  done
  printf '%s,%s\n' \
    "$(printf '%s' "$out" | sed -n 's/.*keyCode = \([0-9]*\).*/\1/p')" \
    "$(printf '%s' "$out" | sed -n 's/.*modifierFlags = \([0-9]*\).*/\1/p')"
}
