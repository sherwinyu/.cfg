function ToggleApp(appName)
	local app = hs.application.get(appName)
	print("Found app:", app)

	if app then
		if app:isFrontmost() then
			app:hide()
		else
			-- Bring to foreground if minimized or hidden
			if app:isHidden() then
				app:unhide()
			end
			-- Unminimize all windows if minimized
			local windows = app:allWindows()
			for _, window in ipairs(windows) do
				if window:isMinimized() then
					window:unminimize()
				end
			end
			app:activate()
		end
	else
		-- Start the app if it's not running
		hs.application.launchOrFocus(appName)
	end
end

local function listMenuItems(appName)
	local app = hs.application.get(appName)
	if not app then
		print("App not found: " .. appName)
		return
	end

	local menuItems = app:getMenuItems()
	hs.json.write(menuItems, "/Users/sherwin/cfg/hammerspoon/menuitems.json", true, true)
	print("Menu items saved to menuItems.json")
end

if false then
	listMenuItems("Arc")
end

-- Function to activate a specific menu item in TaskPaper
local function selectMenuItem(appName, menuHierarchy)
	-- Focus on the app
	local app = hs.application.get(appName)
	if not app then
		return
	end

	-- Trigger the menu item
	app:selectMenuItem(menuHierarchy)
end
-- General hotkeys

hs.hotkey.bind({}, "F7", function()
	ToggleApp("iTerm")
end)

hs.hotkey.bind({}, "F8", function()
	ToggleApp("TaskPaper")
end)

hs.hotkey.bind({}, "F9", function()
	ToggleApp("Oryoki")
end)

hs.hotkey.bind({}, "F10", function()
	ToggleApp("Arc")
end)

-- Define the "Hyper" key as Ctrl + Alt + Cmd + Shift
local hyper = { "ctrl", "alt", "cmd", "shift" }

local zoot = { "ctrl", "alt", "cmd" }

local TaskQueue = {}
TaskQueue.__index = TaskQueue

function TaskQueue.new()
	return setmetatable({ tasks = {} }, TaskQueue)
end

function TaskQueue:after(seconds, fn)
	table.insert(self.tasks, { seconds = seconds, fn = fn })
	return self
end

function TaskQueue:run()
	local delay = 0
	for _, task in ipairs(self.tasks) do
		delay = delay + task.seconds
		hs.timer.doAfter(delay, task.fn)
	end
end

function OpenWhatsapp(q)
	if not q then
		q = TaskQueue.new()
	end

	q:after(0.2, function()
		ToggleApp("Arc")
	end)
	q:after(0.2, function()
		selectMenuItem("Arc", { "Spaces", "Sherwin" })
	end)
	q:after(0.2, function()
		hs.eventtap.keyStroke({ "command" }, "2")
	end)
	return q
end

function MessageNadia(q)
	if not q then
		q = TaskQueue.new()
	end
	q = OpenWhatsapp(q)
	q:after(0.1, function()
		hs.eventtap.keyStroke({ "cmd" }, "k")
	end)
	q:after(0.1, function()
		hs.eventtap.keyStrokes("nadia")
	end)
	q:after(0.1, function()
		hs.eventtap.keyStroke({}, "return")
	end)
	return q
end

function OpenMaps(q)
	if not q then
		q = TaskQueue.new()
	end
	q:after(0.2, function()
		ToggleApp("Arc")
	end)
	q:after(0.2, function()
		selectMenuItem("Arc", { "Spaces", "Sherwin" })
	end)
	q:after(0.2, function()
		hs.eventtap.keyStroke({ "command" }, "6")
	end)
	return q
end

function OpenAsana(q)
	if not q then
		q = TaskQueue.new()
	end
	q:after(0.2, function()
		ToggleApp("Arc")
	end)
	q:after(0.2, function()
		selectMenuItem("Arc", { "Spaces", "Sherwin" })
	end)
	q:after(0.2, function()
		hs.eventtap.keyStroke({ "command" }, "3")
	end)
	return q
end

hs.hotkey.bind(hyper, "1", function()
	OpenWhatsapp():run()
end)

hs.hotkey.bind(hyper, "n", function()
	MessageNadia():run()
end)

hs.hotkey.bind(hyper, ";", function()
	ToggleApp("Spotify")
end)

hs.hotkey.bind(zoot, "p", function()
	ToggleApp("Chrome")
end)

hs.hotkey.bind(zoot, "0", function()
	ToggleApp("Arc")
end)

hs.hotkey.bind(zoot, "z", function()
	ToggleApp("Zed")
end)

hs.hotkey.bind(zoot, "j", function()
	ToggleApp("Slack")
end)

hs.hotkey.bind(zoot, "k", function()
	ToggleApp("Cursor")
end)

hs.hotkey.bind(zoot, ";", function()
	ToggleApp("Spotify")
end)

hs.hotkey.bind(zoot, ",", function()
	ToggleApp("ChatGPT")
end)

hs.hotkey.bind(zoot, ".", function()
	ToggleApp("Claude")
end)

hs.hotkey.bind(zoot, "h", function()
	ToggleApp("Habits 2025")
end)

hs.hotkey.bind(zoot, "m", function()
	ToggleApp("Google Maps")
end)

hs.hotkey.bind(zoot, "n", function()
	ToggleApp("Notion")
end)

hs.hotkey.bind(zoot, "o", function()
	-- soon to be Oryoki
	ToggleApp("Oryoki")
end)

hs.hotkey.bind(zoot, "-", function()
	ToggleApp("Dia")
end)

hs.hotkey.bind(hyper, "1", function()
	local audio = require("audio-test")
	local outputDevices = {
		"External Headphones",
		"Macbook Air Speakers",
	}
	local inputDevices = {
		"MacBook Air Microphone",
	}
	audio.setAudioConfig({ input = inputDevices, output = outputDevices })
end)

hs.hotkey.bind(hyper, "2", function()
	local audio = require("audio-test")
	local outputDevices = {
		"External Headphones",
		"Macbook Air Speakers",
	}
	local inputDevices = {
		"TOZO T10",
	}
	audio.setAudioConfig({ input = inputDevices, output = outputDevices })
end)

-- Create a table to hold the TaskPaper-specific hotkeys
local taskPaperHotkeys = {}

-- Function to enable TaskPaper hotkeys
local function enableTaskPaperHotkeys()
	taskPaperHotkeys = {
		hs.hotkey.bind({ "ctrl", "cmd" }, "S", function()
			selectMenuItem("TaskPaper", { "Edit", "Selection", "Select Branch" })
		end),
		hs.hotkey.bind({ "alt", "cmd" }, "'", function()
			selectMenuItem("TaskPaper", { "Item", "Format As", "Notes" })
		end),
		hs.hotkey.bind({ "alt", "cmd" }, "-", function()
			selectMenuItem("TaskPaper", { "Item", "Format As", "Tasks" })
		end),
		hs.hotkey.bind({ "cmd" }, "E", function()
			selectMenuItem("TaskPaper", { "Tag", "Due" })
		end),
		hs.hotkey.bind({ "cmd" }, "K", function()
			selectMenuItem("TaskPaper", { "Tag", "Remove Tags" })
		end),
		hs.hotkey.bind({ "ctrl" }, "down", function()
			selectMenuItem("TaskPaper", { "Item", "Move Down" })
		end),
		hs.hotkey.bind({ "ctrl" }, "up", function()
			selectMenuItem("TaskPaper", { "Item", "Move Up" })
		end),
		hs.hotkey.bind({ "ctrl" }, "]", function()
			selectMenuItem("TaskPaper", { "Outline", "Focus In" })
		end),
		hs.hotkey.bind({ "ctrl" }, "[", function()
			selectMenuItem("TaskPaper", { "Outline", "Focus Out" })
		end),
	}
end

-- Function to disable TaskPaper hotkeys
local function disableTaskPaperHotkeys()
	for _, hotkey in ipairs(taskPaperHotkeys) do
		hotkey:delete()
	end
	taskPaperHotkeys = {}
end

-- Create an application watcher to enable/disable TaskPaper-specific keybindings
local hotkeyWatcher = hs.application.watcher.new(function(appName, eventType)
	if eventType == hs.application.watcher.activated then
		if appName == "TaskPaper" then
			enableTaskPaperHotkeys()
		else
			disableTaskPaperHotkeys()
		end
	elseif eventType == hs.application.watcher.deactivated then
		if appName == "TaskPaper" then
			disableTaskPaperHotkeys()
		end
	end
end)

return hotkeyWatcher
