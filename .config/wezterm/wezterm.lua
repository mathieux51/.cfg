local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = 'nord'
config.font = wezterm.font('MonoLisa Nerd Font', { weight = 'Regular'})
config.font_size = 21.0

config.window_decorations = "RESIZE"

config.hide_tab_bar_if_only_one_tab = true

-- Bypass tmux mouse reporting when holding SUPER (Cmd) so links work
config.bypass_mouse_reporting_modifiers = 'SUPER'

-- Explicit mouse binding for opening hyperlinks with Cmd+Click
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = act.OpenLinkAtMouseCursor,
  },
}

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
  { key = 'e', mods = 'SUPER', action = act.SendString '\x65\x78\x69\x74\x0a' },
  { key = 'i', mods = 'SUPER|SHIFT', action = act.SendString '\x01\x49' },
  { key = 'Tab', mods = 'CTRL', action = act.SendString '\x01\x6e' },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.SendString '\x01\x70' },
  { key = 'w', mods = 'SUPER|SHIFT', action = act.CloseCurrentTab{confirm=false} },
}

-- config.enable_tab_bar = false

-- config.term = 'xterm-256color'

return config
