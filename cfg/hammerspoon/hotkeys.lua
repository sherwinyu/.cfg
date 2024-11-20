-- General hotkeys
hs.hotkey.bind({}, "F7", function()
	hs.application.launchOrFocus("iTerm")
end)

hs.hotkey.bind({}, "F8", function()
	hs.application.launchOrFocus("TaskPaper")
end)

hs.hotkey.bind({}, "F9", function()
	hs.application.launchOrFocus("sherwinotes")
end)

hs.hotkey.bind({}, "F10", function()
	hs.application.launchOrFocus("Arc")
end)

-- Function to activate a specific menu item in TaskPaper
function selectMenuItem(appName, menuHierarchy)
	-- Focus on the app
	local app = hs.application.get(appName)
	if not app then
		return
	end

	-- Trigger the menu item
	app:selectMenuItem(menuHierarchy)
end

-- Create a table to hold the TaskPaper-specific hotkeys
local taskPaperHotkeys = {}

-- Function to enable TaskPaper hotkeys
function enableTaskPaperHotkeys()
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
function disableTaskPaperHotkeys()
	for _, hotkey in ipairs(taskPaperHotkeys) do
		hotkey:delete()
	end
	taskPaperHotkeys = {}
end

-- Create an application watcher to enable/disable TaskPaper-specific keybindings
hotkeyWatcher = hs.application.watcher.new(function(appName, eventType)
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
