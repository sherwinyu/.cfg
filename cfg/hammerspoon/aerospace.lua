-- Aerospace Window Manager Integration
-- Modal hotkey: Alt+W to enter window mode

local windowMode = hs.hotkey.modal.new()

-- Helper function to run aerospace commands
local function aerospace(cmd)
	hs.task.new("/opt/homebrew/bin/aerospace", nil, cmd):start()
end

-- Track workspace history
local workspaceHistory = {
	current = nil,
	previous = nil
}

-- Watch for workspace changes
local function updateWorkspaceHistory()
	local task = hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
		local newWorkspace = stdOut:match("%d+")
		if newWorkspace and newWorkspace ~= workspaceHistory.current then
			workspaceHistory.previous = workspaceHistory.current
			workspaceHistory.current = newWorkspace
		end
	end, {"list-workspaces", "--focused"})
	task:start()
end

-- Start tracking immediately and poll every 0.5 seconds
updateWorkspaceHistory()
hs.timer.doEvery(0.5, updateWorkspaceHistory)

-- Create persistent banner
local banner = nil

local function showBanner()
	local mainScreen = hs.screen.mainScreen()
	local mainFrame = mainScreen:frame()

	-- Get current workspace
	local currentWorkspace = workspaceHistory.current or "?"

	-- Create canvas at center of screen (2x larger)
	local bannerWidth = 400
	local bannerHeight = 120
	banner = hs.canvas.new({
		x = mainFrame.x + (mainFrame.w - bannerWidth) / 2,
		y = mainFrame.y + (mainFrame.h - bannerHeight) / 2,
		w = bannerWidth,
		h = bannerHeight
	})

	-- Background
	banner[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.95 },
		roundedRectRadii = { xRadius = 20, yRadius = 20 }
	}

	-- Window Mode text
	banner[2] = {
		type = "text",
		text = "WINDOW MODE",
		textAlignment = "center",
		textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
		textSize = 32,
		frame = { x = 0, y = 10, w = bannerWidth, h = 60 }
	}

	-- Workspace number
	banner[3] = {
		type = "text",
		text = "Workspace " .. currentWorkspace,
		textAlignment = "center",
		textColor = { red = 0.7, green = 0.7, blue = 0.7, alpha = 1 },
		textSize = 20,
		frame = { x = 0, y = 65, w = bannerWidth, h = 40 }
	}

	banner:show()
end

local function hideBanner()
	if banner then
		banner:delete()
		banner = nil
	end
end

-- Visual feedback when entering/exiting mode
windowMode.entered = function()
	showBanner()
	-- Set border to prominent glow
	hs.task.new("/opt/homebrew/bin/borders", nil, {"active_color=glow(0xff00d9ff)", "width=8.0"}):start()
end

windowMode.exited = function()
	hideBanner()
	-- Restore normal border
	hs.task.new("/opt/homebrew/bin/borders", nil, {"active_color=0xffe1e3e4", "width=6.5"}):start()
end

-- Bind Alt+G to enter/exit modal
hs.hotkey.bind({"alt"}, "g",
	function()
		windowMode:enter()
	end,
	function()
		windowMode:exit()
	end
)

-- Bind Alt+V to enter/exit modal (alternative)
hs.hotkey.bind({"alt"}, "v",
	function()
		windowMode:enter()
	end,
	function()
		windowMode:exit()
	end
)

-- === Window Focus (h/j/k/l) ===
-- Focus within workspace, crossing all monitors with wrap-around
windowMode:bind({}, "h", function()
	hs.alert.show("← Focus Left")
	aerospace({"focus", "--boundaries", "all-monitors-outer-frame", "--boundaries-action", "wrap-around-all-monitors", "left"})
end)

windowMode:bind({}, "j", function()
	hs.alert.show("↓ Focus Down")
	aerospace({"focus", "down"})
end)

windowMode:bind({}, "k", function()
	hs.alert.show("↑ Focus Up")
	aerospace({"focus", "up"})
end)

windowMode:bind({}, "l", function()
	hs.alert.show("→ Focus Right")
	aerospace({"focus", "--boundaries", "all-monitors-outer-frame", "--boundaries-action", "wrap-around-all-monitors", "right"})
end)

-- === Window Movement (Shift+h/j/k/l) ===
windowMode:bind({"shift"}, "h", function()
	hs.alert.show("⇐ Move Left")
	aerospace({"move", "--boundaries-action", "create-implicit-container", "left"})
end)

windowMode:bind({"shift"}, "j", function()
	hs.alert.show("⇓ Move Down")
	aerospace({"move", "--boundaries-action", "create-implicit-container", "down"})
end)

windowMode:bind({"shift"}, "k", function()
	hs.alert.show("⇑ Move Up")
	aerospace({"move", "--boundaries-action", "create-implicit-container", "up"})
end)

windowMode:bind({"shift"}, "l", function()
	hs.alert.show("⇒ Move Right")
	aerospace({"move", "--boundaries-action", "create-implicit-container", "right"})
end)

-- ===  Workspace Selection (1/2/3/4/0) ===
windowMode:bind({}, "0", function ()
  hs.alert.show("Workspace 0")
	aerospace({'workspace', '0'})
end)

windowMode:bind({}, "1", function ()
  hs.alert.show("Workspace 1")
	aerospace({'workspace', '1'})
end)
windowMode:bind({}, "2", function ()
  hs.alert.show("Workspace 2")
	aerospace({'workspace', '2'})
end)

windowMode:bind({}, "3", function ()
  hs.alert.show("Workspace 3")
	aerospace({'workspace', '3'})
end)

windowMode:bind({}, "4", function ()
  hs.alert.show("Workspace 4")
	aerospace({'workspace', '4'})
end)

-- ===  Move to Workspace  shift + 1/2/3/4/0 ===
windowMode:bind({"shift"}, "0", function ()
  hs.alert.show("Moved to 0")
	aerospace({'move-node-to-workspace', '--focus-follows-window', '0'})
end)

windowMode:bind({"shift"}, "1", function ()
  hs.alert.show("Moved to 1")
	aerospace({'move-node-to-workspace', '--focus-follows-window', '1'})
end)
windowMode:bind({"shift"}, "2", function ()
  hs.alert.show("Moved to 2")
	aerospace({'move-node-to-workspace', '--focus-follows-window', '2'})
end)

windowMode:bind({"shift"}, "3", function ()
  hs.alert.show("Moved to 3")
	aerospace({'move-node-to-workspace', '--focus-follows-window', '3'})
end)

windowMode:bind({"shift"}, "4", function ()
  hs.alert.show("Moved to 4")
	aerospace({'move-node-to-workspace', '--focus-follows-window', '4'})
end)


-- === DFS Window Navigation (u/i) ===
windowMode:bind({}, "u", function()
	hs.alert.show("← Prev Window")
	aerospace({"focus", "--boundaries-action", "wrap-around-the-workspace", "dfs-prev"})
end)

windowMode:bind({}, "i", function()
	hs.alert.show("→ Next Window")
	aerospace({"focus", "--boundaries-action", "wrap-around-the-workspace", "dfs-next"})
end)

-- === Layout Toggles ===
windowMode:bind({}, "space", function()
	hs.alert.show("⬚ Toggle Float")
	aerospace({"layout", "floating", "tiling"})
end)

windowMode:bind({}, "n", function()
	hs.alert.show("⬚ Toggle Float")
	aerospace({"layout", "floating", "tiling"})
end)

-- === Merge Window to Previous Workspace ===
windowMode:bind({}, "t", function()
	if workspaceHistory.previous then
		hs.alert.show("↶ Move to Workspace " .. workspaceHistory.previous)
		aerospace({"move-node-to-workspace", workspaceHistory.previous})
		aerospace({"workspace", workspaceHistory.previous})
	else
		hs.alert.show("No previous workspace")
	end
end)

windowMode:bind({}, "return", function()
	hs.alert.show("⛶ Toggle Fullscreen")
	aerospace({"fullscreen"})
end)

windowMode:bind({}, "delete", function()
	hs.alert.show("↔ Workspace Back/Forth")
	aerospace({"workspace-back-and-forth"})
end)

-- === Reset/Destroy All Workspaces (Shift+0) ===
windowMode:bind({"shift"}, "0", function()
	hs.alert.show("⟲ Reset All Workspaces")
	-- Get all windows and move them to workspace 0 as floating
	local task = hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
		local windowIds = {}
		for line in stdOut:gmatch("[^\r\n]+") do
			table.insert(windowIds, line)
		end

		-- Move each window to workspace 0 and set to floating
		for _, windowId in ipairs(windowIds) do
			aerospace({"--window-id", windowId, "layout", "floating"})
			aerospace({"--window-id", windowId, "move-node-to-workspace", "0"})
		end

		hs.alert.show("✓ All windows moved to workspace 0")
	end, {"list-windows", "--all", "--format", "%{window-id}"})
	task:start()
end)

-- === Workspace Navigation (d/f) ===
windowMode:bind({}, "d", function()
	hs.alert.show("← Prev Workspace")
	-- Focus previous workspace (cycle through 0-4)
	local task = hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
		local current = tonumber(stdOut:match("%d+"))
		if current then
			local prev = current == 0 and 4 or current - 1
			aerospace({"workspace", tostring(prev)})
		end
	end, {"list-workspaces", "--focused"})
	task:start()
end)

windowMode:bind({}, "g", function()
	hs.alert.show("→ Next Workspace")
	-- Focus next workspace (cycle through 0-4)
	local task = hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
		local current = tonumber(stdOut:match("%d+"))
		if current then
			local next = current == 4 and 0 or current + 1
			aerospace({"workspace", tostring(next)})
		end
	end, {"list-workspaces", "--focused"})
	task:start()
end)

-- === Monitor Navigation (m/,) ===
windowMode:bind({}, "m", function()
	hs.alert.show("← Prev Monitor")
	aerospace({"focus-monitor", "--wrap-around", "prev"})
end)

windowMode:bind({}, ",", function()
	hs.alert.show("→ Next Monitor")
	aerospace({"focus-monitor", "--wrap-around", "next"})
end)

-- === Move Workspace to Monitor (Shift+m/,) ===
windowMode:bind({"shift"}, "m", function()
	hs.alert.show("⇐ Move Workspace to Prev Monitor")
	aerospace({"move-workspace-to-monitor", "--wrap-around", "prev"})
end)

windowMode:bind({"shift"}, ",", function()
	hs.alert.show("⇒ Move Workspace to Next Monitor")
	aerospace({"move-workspace-to-monitor", "--wrap-around", "next"})
end)

-- Global hotkey: Ctrl+Alt+Cmd+T to merge to previous workspace
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "t", function()
	if workspaceHistory.previous then
		hs.alert.show("↶ Move to Workspace " .. workspaceHistory.previous)
		aerospace({"move-node-to-workspace", workspaceHistory.previous})
		aerospace({"workspace", workspaceHistory.previous})
	else
		hs.alert.show("No previous workspace")
	end
end)

return windowMode
