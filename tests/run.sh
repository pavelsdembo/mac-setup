#!/usr/bin/env bash
# Run every tests/*.test.sh and report a summary.
#
#     ./tests/run.sh
#
# Also runs shellcheck over the repo when it is installed.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

failed=0
total=0

for test in "${ROOT}"/tests/*.test.sh; do
  name="$(basename "$test")"
  printf '\n# %s\n' "$name"
  total=$((total + 1))
  if ! bash "$test"; then
    failed=$((failed + 1))
  fi
done

printf '\n# shellcheck\n'
if command -v shellcheck >/dev/null 2>&1; then
  # SC1091: shellcheck cannot follow the runtime-resolved source paths.
  if shellcheck -e SC1091 "${ROOT}"/*.sh "${ROOT}"/steps/*.sh \
       "${ROOT}"/lib/*.sh "${ROOT}"/tests/*.sh; then
    printf 'ok - shellcheck clean\n'
  else
    printf 'not ok - shellcheck reported issues\n'
    failed=$((failed + 1))
  fi
  total=$((total + 1))
else
  printf '# skipped - shellcheck not installed (brew bundle installs it)\n'
fi

printf '\n===================================================================\n'
if [ "$failed" -eq 0 ]; then
  printf '  all %d checks passed\n' "$total"
else
  printf '  %d of %d checks FAILED\n' "$failed" "$total"
fi
printf '===================================================================\n'

exit "$failed"
