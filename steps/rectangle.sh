#!/usr/bin/env bash
# Rectangle window-management shortcuts.
#
# Each shortcut is a dictionary of two integers: a macOS virtual key code and
# the sum of the NSEvent modifier bitmasks below.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Overridable so tests can write to a throwaway domain.
DOMAIN="${RECTANGLE_DOMAIN:-com.knollsoft.Rectangle}"
RECTANGLE_APP="${RECTANGLE_APP:-Rectangle}"

SHIFT=131072    # 1 << 17
CTRL=262144     # 1 << 18
OPT=524288      # 1 << 19
CMD=1048576     # 1 << 20

LEFT=123
RIGHT=124
DOWN=125
UP=126
KEY_C=8
KEY_F=3
KEY_B=11
KEY_N=45
KEY_MINUS=27
KEY_EQUAL=24

shortcut() {
  local action="$1" keycode="$2" mods="$3"
  defaults write "$DOMAIN" "$action" -dict keyCode -int "$keycode" modifierFlags -int "$mods"
}

step "Rectangle"
quit_app "$RECTANGLE_APP"

# --- Halves ------------------------------------------------------ Cmd+Opt+Arrow
shortcut leftHalf    "$LEFT"  $((CMD + OPT))
shortcut rightHalf   "$RIGHT" $((CMD + OPT))
shortcut topHalf     "$UP"    $((CMD + OPT))
shortcut bottomHalf  "$DOWN"  $((CMD + OPT))

# --- Top corners ------------------------------------------------ Cmd+Ctrl+Arrow
shortcut topLeft     "$LEFT"  $((CMD + CTRL))
shortcut topRight    "$RIGHT" $((CMD + CTRL))

# --- Bottom corners --------------------------------------- Cmd+Ctrl+Shift+Arrow
shortcut bottomLeft  "$LEFT"  $((CMD + CTRL + SHIFT))
shortcut bottomRight "$RIGHT" $((CMD + CTRL + SHIFT))

# --- Sizing ---------------------------------------------------------- Cmd+Opt+_
shortcut maximize    "$KEY_F"     $((CMD + OPT))   # Cmd+Opt+F
shortcut center      "$KEY_C"     $((CMD + OPT))   # Cmd+Opt+C
shortcut larger      "$KEY_EQUAL" $((CMD + OPT))   # Cmd+Opt+=
shortcut smaller     "$KEY_MINUS" $((CMD + OPT))   # Cmd+Opt+-

# --- Todo mode ------------------------------------------------------ Ctrl+Opt+_
shortcut toggleTodo  "$KEY_B" $((CTRL + OPT))      # Ctrl+Opt+B
shortcut reflowTodo  "$KEY_N" $((CTRL + OPT))      # Ctrl+Opt+N

defaults write "$DOMAIN" launchOnLogin -bool true
defaults write "$DOMAIN" allowAnyShortcut -bool true
defaults write "$DOMAIN" alternateDefaultShortcuts -bool true
defaults write "$DOMAIN" subsequentExecutionMode -int 1              # cycle sizes on repeat
defaults write "$DOMAIN" footprintAnimationDurationMultiplier -int 0 # no animation
ok "16 shortcuts"

reload_prefs
info "open Rectangle to start it with these shortcuts"
