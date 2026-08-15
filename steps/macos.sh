#!/usr/bin/env bash
# macOS system preferences: Desktop & Stage Manager, Finder, Dock, menu bar.
# Tested on macOS 26 (Tahoe); also applies to Sonoma and Sequoia.
set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"


step "System preferences"

# Show Items: on the desktop, then in Stage Manager.
defaults write com.apple.WindowManager StandardHideDesktopIcons -bool true
defaults write com.apple.WindowManager HideDesktop -bool true
# Click wallpaper to reveal desktop: false = "Only in Stage Manager".
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager GloballyEnabled -bool false
defaults write com.apple.WindowManager StandardHideWidgets -bool true
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true
ok "Desktop & Stage Manager"


defaults write com.apple.finder ShowHardDrivesOnDesktop         -bool false
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop     -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop     -bool false

# New windows open Home. Both keys are required; the target alone reverts.
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# AppleShowAllExtensions lives in the global domain, not com.apple.finder.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# SCcf = current folder, SCev = this Mac, SCsp = previous scope.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar   -bool true
defaults write com.apple.finder ShowTabView   -bool true
ok "Finder"


defaults write com.apple.dock tilesize -int 32
defaults write com.apple.dock orientation -string "bottom"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock show-recents -bool false
ok "Dock"


# Visible = in the menu bar, VisibleCC = inside Control Centre.
defaults write com.apple.controlcenter "NSStatusItem Visible AirDrop"  -bool false
defaults write com.apple.controlcenter "NSStatusItem Visible BentoBox" -bool true
defaults write com.apple.controlcenter "NSStatusItem VisibleCC WiFi"        -bool true
defaults write com.apple.controlcenter "NSStatusItem VisibleCC Bluetooth"   -bool true
defaults write com.apple.controlcenter "NSStatusItem VisibleCC Clock"       -bool true
defaults write com.apple.controlcenter "NSStatusItem VisibleCC BentoBox-0"  -bool true

# `NSStatusItem Visible Item-N` and icon order are deliberately not set: the
# index is assigned per machine, and order is stored as screen coordinates.

# ShowDate is an integer: 0 auto, 1 always, 2 never.
defaults write com.apple.menuextra.clock IsAnalog                 -bool true
defaults write com.apple.menuextra.clock ShowAMPM                 -bool true
defaults write com.apple.menuextra.clock ShowDayOfWeek            -bool true
defaults write com.apple.menuextra.clock ShowDate                 -int 0
defaults write com.apple.menuextra.clock TimeAnnouncementsEnabled -bool false
ok "Menu bar"

for process in ControlCenter WindowManager Finder Dock; do
  killall "$process" 2>/dev/null || true
done
ok "restarted Finder, Dock, Control Centre and the window manager"
