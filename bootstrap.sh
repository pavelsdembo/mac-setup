#!/usr/bin/env bash
# Bring a bare Mac to the point where setup-mac.sh can take over, then hand it
# the run. cd to wherever you want the clone to live, then paste this into
# Terminal on a machine with nothing on it:
#
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pavelsdembo/mac-setup/main/bootstrap.sh)"
#
# Homebrew, gh, a GitHub sign-in and the clone. These four cannot live in
# steps/: the repo is private, so none of it is on the machine yet, which is
# the whole reason this file is fetched on its own.
#
# Arguments are passed straight to setup-mac.sh, so `--list` bootstraps and
# then prints the steps instead of running them.
set -euo pipefail

REPO="pavelsdembo/mac-setup"

# The clone lands where you ran this from. cd is the setting; there is no other.
NAME="${REPO##*/}"
DEST="${PWD}/${NAME}"

# No lib/common.sh: it is inside the repo this script exists to fetch.
if [ -t 1 ]; then
  _BOLD=$'\033[1m'; _DIM=$'\033[2m'; _GREEN=$'\033[32m'; _RED=$'\033[31m'
  _RESET=$'\033[0m'
else
  _BOLD=""; _DIM=""; _GREEN=""; _RED=""; _RESET=""
fi

step() { printf '\n%s%s%s\n' "$_BOLD" "$1" "$_RESET"; }
ok()   { printf '  %s✓%s %s\n' "$_GREEN" "$_RESET" "$1"; }
skip() { printf '  %s· %s%s\n' "$_DIM" "$1" "$_RESET"; }
info() { printf '    %s\n' "$1"; }
die()  { printf '  %s✗%s %s\n' "$_RED" "$_RESET" "$1" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Everything below prompts for something. Piped into bash, the script text
# becomes the answer to the first prompt, so refuse rather than half-finish.
if [ ! -t 0 ]; then
  # shellcheck disable=SC2016  # the $( ) is the command to type, not to run
  die 'no terminal on stdin - run: /bin/bash -c "$(curl -fsSL <url>)"'
fi


step "Homebrew"

if have brew; then
  skip "already installed"
else
  # Also installs the Xcode command line tools, where the clone's git comes from.
  info "the installer will ask for your password"
  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "installed"
fi

# The installer finishes by printing two commands and leaving them to you. This
# shell needs them now, and ~/.zprofile has not been read.
if ! have brew; then
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "${prefix}/bin/brew" ]; then
      eval "$("${prefix}/bin/brew" shellenv)"
      break
    fi
  done
fi
have brew || die "Homebrew installed but brew is still not on PATH"


step "GitHub CLI"

if have gh; then
  skip "already installed"
else
  brew install gh
  ok "installed"
fi


step "GitHub sign-in"

if gh auth status >/dev/null 2>&1; then
  skip "already signed in as $(gh api user --jq .login 2>/dev/null || printf '?')"
else
  # The clone below is the reason this is not optional: the repo is private.
  info "gh will print a one-time code and open your browser"
  gh auth login --hostname github.com --git-protocol https --web \
    || die "sign-in did not finish - the repo is private, so the clone needs it"
  ok "signed in as $(gh api user --jq .login 2>/dev/null || printf '?')"
fi


step "Clone"

if [ -d "${DEST}/.git" ]; then
  skip "already cloned to ${DEST}"
else
  # An `if`, not `&&`: under `set -e` the failing test would end the script on
  # the ordinary path, where the destination does not exist yet.
  if [ -e "$DEST" ]; then
    die "${DEST} exists and is not a clone - move it, or cd somewhere else"
  fi
  # gh rather than git: it already holds the credentials for a private repo.
  gh repo clone "$REPO" "$DEST" || die "could not clone ${REPO}"
  ok "cloned to ${DEST}"
fi

info "keep this clone where it is - the symlinks point at it"


step "Handing over to setup-mac.sh"

exec "${DEST}/setup-mac.sh" "$@"
