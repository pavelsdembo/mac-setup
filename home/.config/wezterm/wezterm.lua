local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- The Dracula project's own variant. WezTerm ships four other Draculas.
config.color_scheme = "Dracula (Official)"

config.font = wezterm.font("Anonymous Pro", { weight = "Bold" })
config.font_size = 20.0

config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true

-- Not INTEGRATED_BUTTONS: it draws the window buttons in the tab bar, which is
-- hidden above for a single tab.
config.window_decorations = "TITLE | RESIZE"

-- Dim unfocused windows.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- get_config_overrides() returns a copy, so compare fields rather than
	-- identity. A redundant set_config_overrides() triggers a config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

return config
