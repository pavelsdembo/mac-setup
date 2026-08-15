#!/usr/bin/env bash
# Install everything declared in the Brewfile.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Packages"

have brew || die "Homebrew missing - run steps/homebrew.sh first"

# --adopt takes over an app already in /Applications instead of failing. It is
# a `brew install --cask` flag, not a `brew bundle` one, so it has to arrive
# through the environment.
export HOMEBREW_CASK_OPTS="${HOMEBREW_CASK_OPTS:-} --adopt"

# --no-upgrade installs what is missing without pulling new versions of
# everything else. Upgrade deliberately with `brew upgrade`.
BUNDLE_ARGS=(--file="${ROOT}/Brewfile" --no-upgrade)

# Not run through `task`: some casks install a pkg and ask for a password,
# which would prompt into a hidden log behind a spinner. brew draws its own
# progress anyway.
brew bundle "${BUNDLE_ARGS[@]}"
ok "Brewfile installed"
