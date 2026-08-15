#!/usr/bin/env bash
# Install the Claude Code CLI with the official native installer, which
# auto-updates. The claude-code cask does not.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

INSTALLER_URL="https://claude.ai/install.sh"

step "Claude Code"

if have claude; then
  skip "already installed ($(claude --version 2>/dev/null | head -1))"
  exit 0
fi

task "installing from ${INSTALLER_URL}" \
  bash -c "curl -fsSL '${INSTALLER_URL}' | bash"

if ! have claude && [ -x "${HOME}/.local/bin/claude" ]; then
  info "installed to ~/.local/bin/claude; open a new shell to pick it up"
fi
