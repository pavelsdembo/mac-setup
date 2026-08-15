# Applied by steps/packages.sh via `brew bundle`.
#
# Deliberately no `brew bundle --cleanup` / zap: it uninstalls anything not
# listed here.

# --- CLI ---
brew "ripgrep"
brew "fd"
brew "fzf"
brew "jq"
brew "gh"
brew "lazygit"
brew "shellcheck"
brew "tree"

# --- Runtimes ---
brew "uv"
# Required: home/.claude/settings.json runs the statusline through npx.
brew "node"

# --- Window management, launching, menu bar ---
cask "raycast"
cask "rectangle"
cask "hiddenbar"
cask "stats"

# --- Fonts ---
# Not `cask "font-anonymous-pro"`: the bundled Regular face has FiraCode
# ligatures, the cask does not. Installed from home/fonts/ by steps/fonts.sh.

# --- Apps ---
# The desktop app. The Claude Code CLI comes from steps/claude-code.sh.
cask "claude"
cask "wezterm"
cask "visual-studio-code"
cask "sublime-text"
cask "obsidian"
cask "google-chrome"
cask "spotify"
cask "git-credential-manager"
