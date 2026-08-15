#!/usr/bin/env bash
# The bundled fonts must be real, complete, and installed without clobbering
# an identical file that is already in place.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FONT_DIR="${ROOT}/home/fonts"

# --- the four faces are present and are actually TrueType ---
for face in "Anonymous Pro.ttf" "Anonymous Pro B.ttf" "Anonymous Pro I.ttf" "Anonymous Pro BI.ttf"; do
  assert_file "${FONT_DIR}/${face}" "${face} is bundled"

  # A TrueType file starts with the sfnt version tag 0x00010000.
  magic=$(od -An -tx1 -N4 "${FONT_DIR}/${face}" | tr -d ' \n')
  assert_eq "$magic" "00010000" "${face} has a valid TrueType header"
done

# Redistribution depends on the OFL text travelling with the files.
assert_file "${FONT_DIR}/OFL.txt" "the OFL license ships alongside the fonts"

license=$(cat "${FONT_DIR}/OFL.txt")
assert_contains "$license" "SIL OPEN FONT LICENSE Version 1.1" "license text is the full OFL 1.1"
assert_contains "$license" "Mark Simonson" "license carries the copyright holder"

# --- installing into an empty destination ---
TMP=$(test_tmproot fonts)
export HOME="${TMP}/home"
mkdir -p "$HOME"

bash "${ROOT}/steps/fonts.sh" >/dev/null || fail "fonts.sh exited non-zero"

count=$(find "${HOME}/Library/Fonts" -name '*.ttf' -type f | wc -l | tr -d ' ')
assert_eq "$count" "4" "all four faces are installed"

assert_eq "$(cmp -s "${FONT_DIR}/Anonymous Pro.ttf" "${HOME}/Library/Fonts/Anonymous Pro.ttf" && echo same)" \
  "same" "installed font is byte-identical to the bundled one"

# --- re-running skips identical files ---
output=$(bash "${ROOT}/steps/fonts.sh")
assert_contains     "$output" "Anonymous Pro.ttf" "second run reports the font"
assert_not_contains "$output" "installed Anonymous Pro.ttf" "second run does not reinstall it"

# --- a corrupted destination is replaced ---
printf 'not a font\n' > "${HOME}/Library/Fonts/Anonymous Pro.ttf"
output=$(bash "${ROOT}/steps/fonts.sh")
assert_contains "$output" "installed Anonymous Pro.ttf" "a differing file is replaced"
assert_eq "$(cmp -s "${FONT_DIR}/Anonymous Pro.ttf" "${HOME}/Library/Fonts/Anonymous Pro.ttf" && echo same)" \
  "same" "replacement restores the correct bytes"
