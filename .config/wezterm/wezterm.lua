local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = 'nord'
config.font = wezterm.font('MonoLisa Nerd Font', { weight = 'Regular'})
config.font_size = 21.0

-- Use the Metal-backed GPU frontend. Cap frames at the panel's actual refresh
-- rate (the DELL U2419H is 60Hz); anything higher just doubles the WindowServer
-- composite load for frames the display can never show.
config.front_end = 'WebGpu'
config.max_fps = 60

config.window_decorations = "RESIZE"

-- Start new panes/tabs with a beam cursor (matches zsh vi insert mode), so there's
-- no block->beam flash before zle-line-init runs. zsh still flips to a block in
-- vi normal mode via DECSCUSR escapes in ~/.zshrc.
config.default_cursor_style = 'SteadyBar'

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

-- Speak the current selection aloud, the terminal-side stand-in for the macOS
-- "Speak selection" hotkey (Option+Esc). That hotkey reads nothing here because
-- WezTerm exposes no accessibility text to macOS, so hand the selection over
-- explicitly. Cmd+Shift+S speaks; press it again while talking to stop.
local speak_file = '/tmp/wezterm-speak.txt'
local speak_bin = os.getenv('HOME') .. '/.local/bin/speak'

wezterm.on('speak-selection', function(window, pane)
  local sel = window:get_selection_text_for_pane(pane) or ''
  local f = io.open(speak_file, 'w')
  if f then
    f:write(sel)
    f:close()
  end
  -- An empty file makes ~/.local/bin/speak fall back to the tmux copy buffer,
  -- which is where a plain mouse drag lands while tmux owns mouse reporting.
  wezterm.background_child_process({ speak_bin, speak_file })
end)

table.insert(config.keys, {
  key = 's',
  mods = 'SUPER|SHIFT',
  action = act.EmitEvent 'speak-selection',
})

return config
