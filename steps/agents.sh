#!/usr/bin/env bash
# Link home/AGENTS.md into every agent tool's expected location.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

POLICY="${ROOT}/home/AGENTS.md"

TARGETS=(
  "${HOME}/.claude/CLAUDE.md"
  "${HOME}/.codex/AGENTS.md"
  "${HOME}/.config/opencode/AGENTS.md"
)

step "Agent instructions"

[ -f "$POLICY" ] || die "missing home/AGENTS.md"

for target in "${TARGETS[@]}"; do
  link_file "$POLICY" "$target"
done
