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

