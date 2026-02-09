hs.timer.doAfter(1000, function()
	hs.alert.show("Config loaded..")
end)
local handleUnblockHotkey = require("hosts-manager")
local hyper = { "cmd", "alt", "ctrl", "shift" }
local zoot = { "cmd", "alt", "ctrl" }
hs.hotkey.bind(hyper, "u", handleUnblockHotkey)
hs.hotkey.bind(hyper, "r", function()
	hs.alert.show("Config reloading....")
	-- hs.reload()
	hs.timer.doAfter(0.5, function()
		hs.reload()
	end)
end)


local fuzzyFinder = require("fuzzy-finder")
hs.hotkey.bind(zoot, "space", function()
	fuzzyFinder.show()
end)

hs.hotkey.bind(zoot, "y", function()
	hs.application.launchOrFocus("WhatsApp")
end)

local audio = require("audio-test")
audio.setupAudioHotkeys()
print("printing......... ===HELLO", audio.listAudioDevices())

-- Config other Spoons
hs.loadSpoon("MouseFollowsFocus"):start()

local hotkeyWatcher = require("hotkeys")
hotkeyWatcher:start()

-- Window navigation (center-point based)
local windowNav = require("window-nav")
windowNav.bindHotkeys(zoot)
