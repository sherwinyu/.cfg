hs.timer.doAfter(1000, function()
	hs.alert.show("Config loaded..")
end)
local handleUnblockHotkey = require("hosts-manager")
local hyper = { "cmd", "alt", "ctrl", "shift" }
hs.hotkey.bind(hyper, "u", handleUnblockHotkey)
hs.hotkey.bind(hyper, "r", function()
	hs.alert.show("Config reloading....")
	-- hs.reload()
	hs.timer.doAfter(0.5, function()
		hs.reload()
	end)
end)

hs.hotkey.bind(hyper, "c", function()
	hs.alert.show("Show hammerspoon console")
	hs.openConsole()
end)

-- Config other Spoons
hs.loadSpoon("MouseFollowsFocus"):start()

local hotkeyWatcher = require("hotkeys")
hotkeyWatcher:start()
