-- Pure checks: no system clipboard is read and no input is posted.
local path = debug.getinfo(1, "S").source:sub(2):match("^(.*)/tests/")
local function setup(initial)
	local state = { clipboard = initial, typed = {}, alerts = {}, timers = {}, copies = 0 }
	local fake = {
		pasteboard = {
			getContents = function() return state.clipboard end,
			callbackWhenChanged = function(timeout, callback)
				assert(timeout == 2)
				state.changed = callback
			end,
		},
		alert = { show = function(message) table.insert(state.alerts, message) end },
		eventtap = {
			keyStrokes = function(text) table.insert(state.typed, text) end,
			keyStroke = function(mods, key)
				assert(table.concat(mods, "+") == "ctrl+cmd" and key == "c")
				state.copies = state.copies + 1
			end,
		},
		timer = { doAfter = function(delay, callback)
			assert(delay == 0.3)
			local timer = { stopped = false, stop = function(self) self.stopped = true end }
			timer.fire = function()
				if not timer.stopped then timer.stopped = true; callback() end
			end
			table.insert(state.timers, timer)
			return timer
		end },
	}
	local env = setmetatable({ hs = fake }, { __index = _G })
	local chunk
	if setfenv then
		chunk = assert(loadfile(path .. "/clipboard-typing.lua")); setfenv(chunk, env)
	else
		chunk = assert(loadfile(path .. "/clipboard-typing.lua", "t", env))
	end
	state.module = chunk()
	state.press = state.module.trigger
	return state
end

local s = setup("single")
s.press(); assert(#s.typed == 0 and s.copies == 0)
s.timers[1].fire(); assert(s.typed[1] == "single")
s = setup("stale")
s.press(); s.press(); assert(s.timers[1].stopped and s.copies == 1 and #s.typed == 0)
s.timers[1].fire(); assert(#s.typed == 0)
s.press(); assert(s.copies == 1 and #s.timers == 1)
s.clipboard = "fresh"; s.changed(true); assert(#s.typed == 1 and s.typed[1] == "fresh")
s.press(); s.timers[2].fire(); assert(#s.typed == 2)
s = setup("stale")
s.press(); s.press(); s.changed(false); assert(#s.typed == 0 and #s.alerts == 1)
s.press(); s.timers[2].fire(); assert(s.typed[1] == "stale")
for _, value in ipairs({ false, "" }) do
	s = setup(value or nil); s.press(); s.timers[1].fire()
	assert(#s.typed == 0 and #s.alerts == 1)
end
s = setup("clipboard untouched")
assert(s.module.typeText("transcript"))
assert(s.typed[1] == "transcript" and s.clipboard == "clipboard untouched" and s.copies == 0)
print("PASS: clipboard single/double tap, copy guard, timeout recovery, empty input, and direct typing")
