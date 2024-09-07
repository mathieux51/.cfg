local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = 'nord'
config.font = wezterm.font('MonoLisa', { weight = 'Bold'})
config.font_size = 21.0

config.window_decorations = "RESIZE"

config.default_prog = tmux
config.hide_tab_bar_if_only_one_tab = true

-- if tmux == true then
config.keys = {
  { key = '1', mods = 'SUPER', action = act.SendString '\x01\x31' },
  { key = '2', mods = 'SUPER', action = act.SendString '\x01\x32' },
  { key = '3', mods = 'SUPER', action = act.SendString '\x01\x33' },
  { key = '4', mods = 'SUPER', action = act.SendString '\x01\x34' },
  { key = '5', mods = 'SUPER', action = act.SendString '\x01\x35' },
  { key = '6', mods = 'SUPER', action = act.SendString '\x01\x36' },
  { key = '7', mods = 'SUPER', action = act.SendString '\x01\x37' },
  { key = '8', mods = 'SUPER', action = act.SendString '\x01\x38' },
  { key = '9', mods = 'SUPER', action = act.SendString '\x01\x39' },
  { key = 't', mods = 'SUPER', action = act.SendString '\x01\x63' },
  { key = 'w', mods = 'SUPER', action = act.SendString '\x01\x26' },
  { key = 'f', mods = 'SUPER', action = act.SendString '\x01\x5b\x3f' },
  { key = 'Tab', mods = 'CTRL', action = act.SendString '\x01\x6e' },
  -- { key = 'Semicolon', mods = 'SUPER', action = act.SendString '\u0001:' },
}

-- config.enable_tab_bar = false

-- config.term = 'xterm-256color'

return config
