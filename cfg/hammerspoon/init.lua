local handleUnblockHotkey = require('hosts-manager')
local hyper = {"cmd", "alt", "ctrl", "shift"}
hs.hotkey.bind(hyper, "u", handleUnblockHotkey)
hs.hotkey.bind(hyper, "r", function()
  hs.alert.show("Config loaded")
  hs.reload()
end)

 -- Config other Spoons
hs.loadSpoon('MouseFollowsFocus'):start()

local hotkeyWatcher = require('hotkeys')
hotkeyWatcher:start()
