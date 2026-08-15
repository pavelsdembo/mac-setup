# Global Agent Instructions

One policy, shared by every coding agent on this machine. `steps/agents.sh` in
the mac-setup repo links this file into each tool's expected location, so there
is exactly one file to edit.

This file is global. Repo-specific conventions do not belong here; they go in
that repo's own `CLAUDE.md` or `AGENTS.md`.

## Working style

- Do the task that was asked. Don't quietly widen the scope, and don't narrow
  it either. If part of it is blocked, finish the rest and say what you left.
- Make routine judgment calls without asking. Ask only when two readings of
  the request would produce materially different work.
- Match the surrounding code: its naming, its idioms, its comment density.
  A change should be hard to spot as coming from somewhere else.
- Prefer editing an existing file over creating a new one.

## Technical decisions

- Do not give much weight to development cost. Prefer quality, simplicity,
  robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct
  end-to-end path. Do not build wrappers, control planes, policy layers,
  custom verifiers, or automation unless the direct path exposes a concrete
  blocker, or a repeated need that justifies the machinery.

Those two pull in opposite directions only if you read them as one rule.
Durable code earns the investment. One-off operational work does not, and
machinery built for it becomes something to maintain forever. Decide which of
the two you are writing before you choose.

## Bugs

Always start by reproducing the bug end to end, as close as possible to how a
real user hits it. Reproducing first is what makes sure you have found the
real problem, so the fix solves it rather than the nearest symptom.

## Verification and quality bar

- A claim that something works means it was run. If it wasn't run, say so.
- Report failures with the actual output, not a summary of it. A failing test
  is a result, not an embarrassment to smooth over.
- Don't re-read a file just to confirm an edit landed. The tool would have
  errored.
- When testing a product end to end, be picky about the UI you see and be
  obsessed with pixel perfection. If something clearly looks off, even when it
  is unrelated to the task, try to get it fixed along the way.
- Hold the same bar for engineering hygiene: lint, test failures, and test
  flakiness. If you see one, get it fixed, even when you did not cause it.

## Comments

- Explain *why*, not *what*. The code already says what it does.

## Writing

- Never use the em dash. Use a plain dash "-" instead.

## Git

- Never commit or push unless asked.
- Never force-push, never rewrite published history, never commit secrets.
- Branch before committing if the current branch is the default one.
- Never add yourself as a co-author. No `Co-Authored-By` trailer naming the
  agent or the model.
- Never hand-edit `CHANGELOG.md`, or any file marked as auto-generated.
  Change whatever generates it instead.

## Ask first

Confirm before anything hard to reverse: deleting files, dropping data,
rewriting history, or writing outside the working directory. Approval for one
such action is not approval for the next.

Before using dynamic workflows, ultra code, or any harness feature that
immediately spawns a large swarm of subagents, explain the tradeoffs and get
explicit approval.
