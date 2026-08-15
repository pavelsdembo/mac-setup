#!/usr/bin/env bash
# Install Homebrew if it is missing, and make sure it is on PATH.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Homebrew"

if have brew; then
  skip "already installed ($(brew --version | head -1))"
else
  # Interactive: it prompts for a password and installs the Xcode CLI tools,
  # so its output has to stay on screen.
  info "the installer will ask for your password"
  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # The installer finishes by printing two commands and leaving them to you.
  # Running them here is what lets the rest of the setup continue: the steps
  # after this one start their own shells, which have not read ~/.zprofile.
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "${prefix}/bin/brew" ]; then
      eval "$("${prefix}/bin/brew" shellenv)"
      break
    fi
  done

  have brew || die "Homebrew installed but brew is still not on PATH"
  ok "installed"
fi

# For future shells. This run does not depend on it.
if grep -q 'brew shellenv' "${HOME}/.zprofile" 2>/dev/null; then
  skip "already on PATH in ~/.zprofile"
else
  # shellcheck disable=SC2016  # the $( ) is meant to reach ~/.zprofile literally
  printf 'eval "$(%s shellenv)"\n' "$(command -v brew)" >> "${HOME}/.zprofile"
  ok "added to PATH in ~/.zprofile"
fi
