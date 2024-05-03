local handleUnblockHotkey = require('hosts-manager')
local hyper = {"cmd", "alt", "ctrl", "shift"}
hs.hotkey.bind(hyper, "u", handleUnblockHotkey)
hs.hotkey.bind(hyper, "r", function()
  hs.reload()
  hs.alert.show("Config loaded")
end)

 -- Config other Spoons
hs.loadSpoon('MouseFollowsFocus'):start()
