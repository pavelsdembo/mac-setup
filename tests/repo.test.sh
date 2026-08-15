#!/usr/bin/env bash
# Repo-level invariants.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# AGENTS.md and CLAUDE.md must stay the same file. Replacing the symlink with
# a copy leaves two files that drift, and agents read whichever one their tool
# looks for.
assert_symlink_to "${ROOT}/AGENTS.md" "CLAUDE.md" "AGENTS.md links to CLAUDE.md"

# A relative target, so it resolves in any clone.
assert_not_contains "$(readlink "${ROOT}/AGENTS.md")" "/" "the link target is relative"

assert_eq "$(head -1 "${ROOT}/AGENTS.md")" "$(head -1 "${ROOT}/CLAUDE.md")" \
  "reading AGENTS.md gets CLAUDE.md's content"

# Git must store it as a symlink (mode 120000), not as a regular file.
mode=$(git -C "$ROOT" ls-files -s AGENTS.md | cut -d' ' -f1)
assert_eq "$mode" "120000" "git tracks AGENTS.md as a symlink"

# --- nothing is pinned to one particular Mac ---
# Every path in here has to resolve on someone else's machine, under a
# different account name. An absolute /Users/<someone> path is how that breaks,
# and it is easy to paste one in from a terminal without noticing. -I skips the
# bundled .ttf files, which are binary. This file is excluded because the
# pattern it looks for has to appear in it.
hardcoded=$(git -C "$ROOT" grep -In "/Users/" -- . ':!tests/repo.test.sh' || true)
assert_eq "$hardcoded" "" "no tracked file hardcodes a /Users/ path"
