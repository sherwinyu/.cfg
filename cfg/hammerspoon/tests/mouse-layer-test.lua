-- Pure gesture checks: no real input is posted and no apps are controlled.
local path = debug.getinfo(1, "S").source:sub(2):match("^(.*)/tests/")
local callback, sleepCallback
local types = setmetatable({}, { __index = function(_, key) return key end })
local function watcher()
	return { start = function(self) return self end, stop = function() end }
end
local fake = {
	eventtap = {
		event = {
			types = types,
			properties = { mouseEventButtonNumber = "button" },
			newKeyEvent = function(mods, key, down)
				return { mods = table.concat(mods, "+"), key = key, down = down }
			end,
		},
		new = function(_, fn) callback = fn; return watcher() end,
	},
	caffeinate = { watcher = {
		new = function(fn) sleepCallback = fn; return watcher() end,
		systemWillSleep = "sleep", screensDidLock = "lock",
	} },
}
local env = setmetatable({ hs = fake }, { __index = _G })
local chunk
if setfenv then
	chunk = assert(loadfile(path .. "/mouse-layer.lua"))
	setfenv(chunk, env)
else
	chunk = assert(loadfile(path .. "/mouse-layer.lua", "t", env))
end
local layer = chunk():start()
local count = 0
local function send(kind, button, suppressed, key, mods)
	local consumed, output = callback({
		getType = function() return kind end,
		getProperty = function() return button end,
	})
	assert(consumed == suppressed, kind .. ": unexpected suppression")
	if key then
		assert(output and #output == 2, "expected one key press/release")
		assert(output[1].key == key and output[2].key == key, "wrong action")
		assert(output[1].mods == (mods or "") and output[2].mods == (mods or ""), "wrong modifiers")
		assert(output[1].down and not output[2].down, "unbalanced output")
	else assert(output == nil, "premature or duplicate action") end
	count = count + 1
end
local function modifier(down)
	send(down and "otherMouseDown" or "otherMouseUp", 3, true)
end

-- Normal clicks and unrelated mouse buttons are untouched.
for _, button in ipairs({ "left", "right" }) do
	send(button .. "MouseDown", button == "left" and 0 or 1, false)
	send(button .. "MouseDragged", button == "left" and 0 or 1, false)
	send(button .. "MouseUp", button == "left" and 0 or 1, false)
end
modifier(true)
send("otherMouseDown", 4, false)
send("otherMouseUp", 4, false)
send("otherMouseDown", 2, false)
send("otherMouseUp", 2, false)
modifier(false)

-- Repeated singles, suppressed drags, and Button 4 alone.
modifier(true)
send("otherMouseDragged", 3, true)
for _ = 1, 2 do
	send("leftMouseDown", 0, true)
	send("leftMouseDragged", 0, true)
	send("leftMouseUp", 0, true, "[", "cmd")
	send("rightMouseDown", 1, true)
	send("rightMouseUp", 1, true, "]", "cmd")
end
modifier(false)

-- Both press orders and both release orders emit Enter exactly once.
for _, first in ipairs({ "left", "right" }) do
	for _, releasedFirst in ipairs({ "left", "right" }) do
		local second = first == "left" and "right" or "left"
		local releasedLast = releasedFirst == "left" and "right" or "left"
		modifier(true)
		send(first .. "MouseDown", first == "left" and 0 or 1, true)
		send(second .. "MouseDown", second == "left" and 0 or 1, true)
		send(releasedFirst .. "MouseUp", releasedFirst == "left" and 0 or 1, true)
		send(releasedLast .. "MouseUp", releasedLast == "left" and 0 or 1, true, "return")
		modifier(false)
	end
end

-- A captured click finishes even when the layer button is released first.
modifier(true)
send("leftMouseDown", 0, true)
modifier(false)
send("leftMouseDragged", 0, true)
send("leftMouseUp", 0, true, "[", "cmd")

-- A button pressed before entering the layer keeps its original release.
send("leftMouseDown", 0, false)
modifier(true)
send("leftMouseUp", 0, false)
modifier(false)

-- Sleep/lock and stop/start clear stale layer state.
for _, reason in ipairs({ "sleep", "lock" }) do
	modifier(true)
	send("leftMouseDown", 0, true)
	sleepCallback(reason)
	send("rightMouseDown", 1, false)
	send("rightMouseUp", 1, false)
end
modifier(true)
layer:stop():start():start()
send("leftMouseDown", 0, false)
send("leftMouseUp", 0, false)
print("PASS: " .. count .. " mouse-layer event checks")
