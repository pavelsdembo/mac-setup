#!/usr/bin/env bash
# Sign in to GitHub. The gh binary itself comes from the Brewfile.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "GitHub sign-in"

if ! have gh; then
  warn "gh is missing - run steps/packages.sh first"
  exit 0
fi

if gh auth status >/dev/null 2>&1; then
  skip "already signed in as $(gh api user --jq .login 2>/dev/null || printf '?')"
  exit 0
fi

# Nothing can answer gh without a terminal, so say what is left to do rather
# than hang on a prompt no one will read.
if [ ! -t 0 ]; then
  warn "not a terminal - sign in later with: gh auth login"
  exit 0
fi

# Not run through `task`: the one-time code and the credential-helper question
# both have to stay on screen.
info "gh will print a one-time code and open your browser"
if gh auth login --hostname github.com --git-protocol https --web; then
  ok "signed in as $(gh api user --jq .login 2>/dev/null || printf '?')"
else
  warn "sign-in did not finish - run 'gh auth login' when you are ready"
fi
