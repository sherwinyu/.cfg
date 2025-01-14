hs.timer.doAfter(1000, function()
	hs.reload()
end)
hs.alert.show("Config loaded..")
local handleUnblockHotkey = require("hosts-manager")
local hyper = { "cmd", "alt", "ctrl", "shift" }
hs.hotkey.bind(hyper, "u", handleUnblockHotkey)
hs.hotkey.bind(hyper, "r", function()
	hs.alert.show("Config reloading....")
	hs.timer.doAfter(1000, hs.reload)
end)

hs.hotkey.bind(hyper, "c", function()
	hs.alert.show("Show hammerspoon console")
	hs.cnsole.show()
end)

-- Config other Spoons
hs.loadSpoon("MouseFollowsFocus"):start()

local hotkeyWatcher = require("hotkeys")
hotkeyWatcher:start()
