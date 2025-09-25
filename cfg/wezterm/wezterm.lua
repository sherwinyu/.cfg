local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font configuration
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 13.0

-- Color scheme
config.color_scheme = 'Tokyo Night'

-- Tab bar
config.hide_tab_bar_if_only_one_tab = false -- Show tab bar to display workspace
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = true
config.tab_max_width = 25
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false

-- Window configuration
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20
config.window_close_confirmation = 'NeverPrompt'

-- Initial window size
config.initial_cols = 120
config.initial_rows = 30

-- Scrollback
config.scrollback_lines = 10000

-- Key bindings
config.keys = {
  -- Split panes
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'D',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Navigate panes
  {
    key = 'LeftArrow',
    mods = 'CMD|OPT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CMD|OPT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'CMD|OPT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CMD|OPT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  -- Close pane
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  -- Line navigation
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' },
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'e', mods = 'CTRL' },
  },
  -- Tab navigation
  {
    key = '[',
    mods = 'CMD',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = ']',
    mods = 'CMD',
    action = wezterm.action.ActivateTabRelative(1),
  },
  -- Pane navigation
  {
    key = '[',
    mods = 'CMD|OPT',
    action = wezterm.action.ActivatePaneDirection 'Prev',
  },
  {
    key = ']',
    mods = 'CMD|OPT',
    action = wezterm.action.ActivatePaneDirection 'Next',
  },
  -- Pane zoom toggle
  {
    key = 'Enter',
    mods = 'CMD|SHIFT',
    action = wezterm.action.TogglePaneZoomState,
  },
  -- Launcher and navigator
  {
    key = 'k',
    mods = 'CMD',
    action = wezterm.action.ShowLauncher,
  },
  {
    key = 'k',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ShowTabNavigator,
  },
  -- Switch to last used tab
  {
    key = 'Tab',
    mods = 'CTRL',
    action = wezterm.action.ActivateLastTab,
  },
  -- Quick select and pane select
  {
    key = 's',
    mods = 'CMD',
    action = wezterm.action.QuickSelect,
  },
  {
    key = 'p',
    mods = 'CMD',
    action = wezterm.action.PaneSelect,
  },
  -- Copy mode and command palette
  {
    key = 's',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivateCopyMode,
  },
  {
    key = 'p',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivateCommandPalette,
  },
}

-- Mouse bindings
config.mouse_bindings = {
  -- Right click to paste
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

-- Performance
config.max_fps = 60
config.animation_fps = 1

-- Bell
config.audible_bell = 'SystemBeep'

-- Claude Code integration helpers
function claude_notify(title, message)
  wezterm.gui.gui_windows()[1]:toast_notification('Claude Code - ' .. title, message, nil, 4000)
end

function claude_permission_request(permission)
  claude_notify('Permission Required', 'Claude Code needs permission: ' .. permission)
end

function claude_task_complete(task)
  claude_notify('Task Complete', task)
end

-- Export for shell scripts
wezterm.on('user-var-changed', function(window, pane, name, value)
  if name == 'CLAUDE_NOTIFY_TITLE' and pane.user_vars.CLAUDE_NOTIFY_MESSAGE then
    claude_notify(value, pane.user_vars.CLAUDE_NOTIFY_MESSAGE)
  elseif name == 'CLAUDE_NOTIFY_MESSAGE' and pane.user_vars.CLAUDE_NOTIFY_TITLE then
    claude_notify(pane.user_vars.CLAUDE_NOTIFY_TITLE, value)
  end
end)

-- Custom tab bar to show workspace
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local workspace = tab.active_pane.user_vars.WEZTERM_WORKSPACE or
                   wezterm.mux.get_active_workspace()
  local title = tab.tab_title

  if title and #title > 0 then
    title = title
  else
    title = tab.active_pane.title
  end

  -- Show workspace name in first tab
  if tab.tab_index == 0 and workspace then
    title = string.format('[%s] %s', workspace, title)
  end

  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

-- Workspace creation functions
local function create_cfg_workspace()
  local mux = wezterm.mux

  -- Create main tab with splits
  local main_tab, main_pane, main_window = mux.spawn_window {
    workspace = 'cfg',
    cwd = wezterm.home_dir .. '/cfg',
  }
  main_tab:set_title('Main')

  -- Split for config status
  local config_pane = main_pane:split {
    direction = 'Right',
    size = 0.5,
  }
  config_pane:send_text('alias config="git --git-dir=/Users/sherwin/.cfg/ --work-tree=/Users/sherwin"\nconfig status\n')

  -- Split for claude sessions
  local claude_pane = config_pane:split {
    direction = 'Bottom',
    size = 0.5,
  }
  claude_pane:send_text('claude session list\n')

  -- Create Wez tab
  local wez_tab, wez_pane = main_window:spawn_tab {
    cwd = wezterm.home_dir .. '/cfg/wezterm',
  }
  wez_tab:set_title('Wez')

  -- Create nvim config tab
  local nvim_tab, nvim_pane = main_window:spawn_tab {
    cwd = wezterm.home_dir .. '/cfg/nvim',
  }
  nvim_tab:set_title('nvimc')

  -- Create karabiner tab
  local karabiner_tab, karabiner_pane = main_window:spawn_tab {
    cwd = wezterm.home_dir .. '/cfg/karabiner-config',
  }
  karabiner_tab:set_title('karabiner')

  -- Create hammerspoon tab
  local hammer_tab, hammer_pane = main_window:spawn_tab {
    cwd = wezterm.home_dir .. '/cfg/hammerspoon',
  }
  hammer_tab:set_title('hammerspoon')

  -- Activate main tab
  main_tab:activate()
end

local function create_gamma_workspace()
  local mux = wezterm.mux

  -- Create main tab
  local main_tab, main_pane, main_window = mux.spawn_window {
    workspace = 'gamma',
    cwd = wezterm.home_dir .. '/projects/gamma',
  }
  main_tab:set_title('Main')

  -- Setup direnv hook for main pane
  main_pane:send_text('eval "$(direnv hook zsh)"\n')

  -- Split for git status
  local git_pane = main_pane:split {
    direction = 'Right',
    size = 0.5,
    cwd = wezterm.home_dir .. '/projects/gamma',
  }
  git_pane:send_text('eval "$(direnv hook zsh)"\ngit status\n')

  -- Split for additional commands
  local extra_pane = git_pane:split {
    direction = 'Bottom',
    size = 0.5,
    cwd = wezterm.home_dir .. '/projects/gamma',
  }
  extra_pane:send_text('eval "$(direnv hook zsh)"\n')

  -- Create Dev tab with tall splits
  local dev_tab, dev_main_pane = main_window:spawn_tab {
    cwd = wezterm.home_dir .. '/projects/gamma',
  }
  dev_tab:set_title('Dev')

  -- Dev pane 1: git status
  dev_main_pane:send_text('eval "$(direnv hook zsh)"\ngs\n')

  -- Dev pane 2: client dev server (tall split)
  local client_pane = dev_main_pane:split {
    direction = 'Right',
    size = 0.33,
    cwd = wezterm.home_dir .. '/projects/gamma',
  }
  client_pane:send_text('eval "$(direnv hook zsh)"\ncd packages/client\nyarn dev:remote:turbo\n')

  -- Dev pane 3: server directory (tall split)
  local server_pane = client_pane:split {
    direction = 'Right',
    size = 0.5,
    cwd = wezterm.home_dir .. '/projects/gamma',
  }
  server_pane:send_text('eval "$(direnv hook zsh)"\ncd packages/server\n')

  -- Dev pane 4: hocuspocus server (tall split)
  local hocus_pane = server_pane:split {
    direction = 'Right',
    size = 1.0,
    cwd = wezterm.home_dir .. '/projects/gamma',
  }
  hocus_pane:send_text('eval "$(direnv hook zsh)"\nyarn workspace hocuspocus dev\n')

  -- Activate main tab
  main_tab:activate()
end

-- GUI startup event
wezterm.on('gui-startup', function(cmd)
  -- Create cfg workspace on startup
  create_cfg_workspace()

  -- Set cfg as the active workspace
  local mux = wezterm.mux
  mux.set_active_workspace('cfg')
end)

-- Key binding to switch to cfg workspace
table.insert(config.keys, {
  key = 'c',
  mods = 'CMD|SHIFT',
  action = wezterm.action.SwitchToWorkspace {
    name = 'cfg',
  },
})

-- Key binding to create/recreate cfg workspace
table.insert(config.keys, {
  key = 'c',
  mods = 'CMD|SHIFT|CTRL',
  action = wezterm.action_callback(function(window, pane)
    create_cfg_workspace()
    window:perform_action(
      wezterm.action.SwitchToWorkspace { name = 'cfg' },
      pane
    )
  end),
})

-- Key binding to switch to gamma workspace
table.insert(config.keys, {
  key = 'g',
  mods = 'CMD|SHIFT',
  action = wezterm.action.SwitchToWorkspace {
    name = 'gamma',
  },
})

-- Key binding to create/recreate gamma workspace
table.insert(config.keys, {
  key = 'g',
  mods = 'CMD|SHIFT|CTRL',
  action = wezterm.action_callback(function(window, pane)
    create_gamma_workspace()
    window:perform_action(
      wezterm.action.SwitchToWorkspace { name = 'gamma' },
      pane
    )
  end),
})

return config