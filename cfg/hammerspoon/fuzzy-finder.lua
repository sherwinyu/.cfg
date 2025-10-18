local M = {}

local commands = {
	{
		name = "hsconsole",
		description = "Show Hammerspoon Console",
		action = function()
			hs.openConsole()
		end,
	},
	{
		name = "ts",
		description = "Insert Current Time (HH:MM:SS)",
		action = function()
			local time = os.date("%H:%M:%S")
			hs.pasteboard.setContents(time)
			hs.eventtap.keyStrokes(time)
		end,
	},
	{
		name = "date",
		description = "Insert Current Date (YYYY-MM-DD)",
		action = function()
			local date = os.date("%Y-%m-%d")
			hs.pasteboard.setContents(date)
			hs.eventtap.keyStrokes(date)
		end,
	},
	{
		name = "td",
		description = "Insert Today's Date @ Time",
		action = function()
			local date = os.date("%Y-%m-%d")
			local time = os.date("%H:%M:%S")
			local result = date .. " @ " .. time
			hs.pasteboard.setContents(result)
			hs.eventtap.keyStrokes(result)
		end,
	},
	{
		name = "unblock",
		description = "Unblock websites",
		action = function()
			local handleUnblockHotkey = require("hosts-manager")
			handleUnblockHotkey()
		end,
	},
	{
		name = "hsreload",
		description = "Reload Hammerspoon config",
		action = function()
			hs.alert.show("Config reloading....")
			hs.timer.doAfter(0.5, function()
				hs.reload()
			end)
		end,
	},
	{
		name = "aerospace-reload",
		description = "Reload Aerospace config",
		action = function()
			hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
				if exitCode == 0 then
					hs.alert.show("⟲ Aerospace config reloaded")
				else
					hs.alert.show("✗ Aerospace reload failed")
				end
			end, {"reload-config"}):start()
		end,
	},
	{
		name = "aerospace-tiles",
		description = "Change layout to tiles",
		action = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, {"layout", "tiles"}):start()
			hs.alert.show("Layout: Tiles")
		end,
	},
	{
		name = "aerospace-accordion",
		description = "Change layout to accordion",
		action = function()
			hs.task.new("/opt/homebrew/bin/aerospace", nil, {"layout", "accordion"}):start()
			hs.alert.show("Layout: Accordion")
		end,
	},
	{
		name = "aerospace-reset",
		description = "Reset all workspaces (move all windows to workspace 0)",
		action = function()
			hs.alert.show("⟲ Resetting all workspaces...")
			local task = hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
				local windowIds = {}
				for line in stdOut:gmatch("[^\r\n]+") do
					table.insert(windowIds, line)
				end

				-- Move each window to workspace 0 and set to floating
				for _, windowId in ipairs(windowIds) do
					hs.task.new("/opt/homebrew/bin/aerospace", nil, {"--window-id", windowId, "layout", "floating"}):start()
					hs.task.new("/opt/homebrew/bin/aerospace", nil, {"--window-id", windowId, "move-node-to-workspace", "0"}):start()
				end

				hs.alert.show("✓ All windows moved to workspace 0")
			end, {"list-windows", "--all", "--format", "%{window-id}"})
			task:start()
		end,
	},
	{
		name = "aerospace-toggle-float",
		description = "Toggle float/tiling for current window",
		action = function()
			-- Get current window state
			hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
				local isFloating = stdOut:match("floating") ~= nil
				local newLayout = isFloating and "tiling" or "floating"
				local icon = isFloating and "⬚" or "⊞"

				-- Toggle layout
				hs.task.new("/opt/homebrew/bin/aerospace", nil, {"layout", "floating", "tiling"}):start()
				hs.alert.show(icon .. " " .. (isFloating and "Tiling" or "Floating"))
			end, {"list-windows", "--focused", "--format", "%{layout}"}):start()
		end,
	},
	{
		name = "aerospace-toggle-fullscreen",
		description = "Toggle fullscreen for current window",
		action = function()
			-- Get current fullscreen state
			hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
				local isFullscreen = stdOut:match("on") ~= nil
				local icon = isFullscreen and "⛶" or "⛶"

				-- Toggle fullscreen
				hs.task.new("/opt/homebrew/bin/aerospace", nil, {"fullscreen"}):start()
				hs.alert.show(icon .. " Fullscreen " .. (isFullscreen and "Off" or "On"))
			end, {"list-windows", "--focused", "--format", "%{is-fullscreen}"}):start()
		end,
	},
	{
		name = "aerospace-toggle-enable",
		description = "Toggle Aerospace on/off",
		action = function()
			-- Check if enabled
			hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
				local isEnabled = stdOut:match("on") ~= nil
				local command = isEnabled and "disable" or "enable"

				-- Toggle enable/disable
				hs.task.new("/opt/homebrew/bin/aerospace", function()
					hs.alert.show(isEnabled and "✗ Aerospace disabled" or "✓ Aerospace enabled")
				end, {command}):start()
			end, {"list-workspaces", "--monitor", "all"}):start()
		end,
	},
}

local chooser = nil

local function filterCommands(query)
	if not query or query == "" then
		return commands
	end

	local filtered = {}
	query = string.lower(query)

	for _, cmd in ipairs(commands) do
		local name = string.lower(cmd.name)
		local desc = string.lower(cmd.description)

		if string.find(name, query, 1, true) or string.find(desc, query, 1, true) then
			table.insert(filtered, cmd)
		end
	end

	return filtered
end

local function createChooserItems(filteredCommands)
	local items = {}

	for _, cmd in ipairs(filteredCommands) do
		table.insert(items, {
			["text"] = cmd.name,
			["subText"] = cmd.description,
			["uuid"] = cmd.name,
		})
	end

	return items
end

function M.show()
	if chooser then
		chooser:delete()
	end

	chooser = hs.chooser.new(function(choice)
		if choice then
			for _, cmd in ipairs(commands) do
				if cmd.name == choice.text then
					cmd.action()
					break
				end
			end
		end
	end)

	chooser:queryChangedCallback(function(query)
		local filtered = filterCommands(query)
		local items = createChooserItems(filtered)
		chooser:choices(items)
	end)

	chooser:searchSubText(true)
	chooser:width(20)
	chooser:rows(10)

	chooser:show()
	
	local filtered = filterCommands("")
	local items = createChooserItems(filtered)
	chooser:choices(items)
	
	hs.alert.show("Fuzzy finder loaded with " .. #items .. " commands")
end

return M

