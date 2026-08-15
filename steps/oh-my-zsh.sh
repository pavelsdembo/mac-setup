#!/usr/bin/env bash
# Install Oh My Zsh. It owns ~/.zshrc; Homebrew's PATH line goes in ~/.zprofile,
# so the two do not collide.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

INSTALLER_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# The installer honours $ZSH as the install location, so look where it would.
OMZ_DIR="${ZSH:-${HOME}/.oh-my-zsh}"

step "Oh My Zsh"

if [ -d "$OMZ_DIR" ]; then
  skip "already installed (${OMZ_DIR#"$HOME"/})"
  exit 0
fi

# git comes with the Xcode tools the Homebrew installer pulls in. Without it
# the installer fails partway, having already moved ~/.zshrc aside.
if ! have git; then
  warn "git is missing - run steps/homebrew.sh first"
  exit 0
fi

if [ -f "${HOME}/.zshrc" ]; then
  info "the existing ~/.zshrc will be kept as ~/.zshrc.pre-oh-my-zsh"
fi

# RUNZSH=no: the installer ends in `exec zsh`, which would hang the run behind
# a spinner. CHSH=no: zsh is already the login shell, and chsh asks for a
# password `task` gives nowhere to appear.
task "installing from ${INSTALLER_URL}" \
  env RUNZSH=no CHSH=no sh -c "curl -fsSL '${INSTALLER_URL}' | sh"

# CHSH=no means nothing changed the login shell, so say if it is the wrong one.
case "${SHELL:-}" in
  *zsh) ;;
  *) warn "the login shell is ${SHELL:-unset}, not zsh - Oh My Zsh will not load" ;;
esac
