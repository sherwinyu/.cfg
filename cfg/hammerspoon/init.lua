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

local audio = require("audio-test")
audio.setupAudioHotkeys()
print("printing......... ===HELLO", audio.listAudioDevices())

-- Config other Spoons
hs.loadSpoon("MouseFollowsFocus"):start()

local hotkeyWatcher = require("hotkeys")
hotkeyWatcher:start()

-- Aerospace window management modal
package.path = package.path .. ";" .. os.getenv("HOME") .. "/cfg/aerospace/?.lua"
require("aerospace")
