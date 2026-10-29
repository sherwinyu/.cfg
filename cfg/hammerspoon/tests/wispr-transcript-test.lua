-- Run via `hs -c 'return dofile(hs.configdir .. "/tests/wispr-transcript-test.lua")'`.
-- JSON uses Hammerspoon; tasks, clipboard, alerts, and typing are isolated doubles.
local path = debug.getinfo(1, "S").source:sub(2):match("^(.*)/tests/")
local tasks, typed, alerts = {}, {}, {}
local startWorks, createWorks = true, true
local clipboard, clipboardWorks = "original clipboard", true
local fake = {
	json = hs.json,
	pasteboard = { setContents = function(text)
		if not clipboardWorks then return false end
		clipboard = text
		return true
	end },
	alert = { show = function(message) table.insert(alerts, message) end },
	task = { new = function(executable, callback, args)
		assert(executable == "/usr/bin/sqlite3")
		assert(args[1] == "-readonly" and args[2] == "-json")
		assert(args[5]:match("Wispr Flow/flow%.sqlite$"))
		if not createWorks then return nil end
		local task = { complete = callback, start = function() return startWorks end }
		table.insert(tasks, task)
		return task
	end },
}
local env = setmetatable({
	hs = fake,
	require = function(name)
		assert(name == "clipboard-typing")
		return {
			trigger = function() table.insert(typed, clipboard) end,
			typeText = function() error("must use the Hyper+V clipboard handler") end,
		}
	end,
}, { __index = _G })
local module = assert(loadfile(path .. "/wispr-transcript.lua", "t", env))()

module.typeLatest()
module.typeLatest()
assert(#tasks == 1, "pending reads must not duplicate typing")
local text = 'A "quoted" transcript\nwith Unicode: café'
tasks[1].complete(0, hs.json.encode({ { text = text } }))
assert(#typed == 1 and typed[1] == text, "text must survive JSON without modification")
assert(clipboard == text, "the clipboard must be updated before Hyper+V is triggered")

local function fails(code, stdout, expected)
	local beforeTyped, beforeAlerts = #typed, #alerts
	local beforeClipboard = clipboard
	module.typeLatest()
	tasks[#tasks].complete(code, stdout)
	assert(#typed == beforeTyped, "failed reads must not type")
	assert(clipboard == beforeClipboard, "failed reads must preserve the clipboard")
	assert(#alerts == beforeAlerts + 1 and alerts[#alerts]:find(expected, 1, true))
end
fails(1, "", "Could not read")
fails(0, "invalid JSON", "Could not decode")
fails(0, "[]", "No Wispr")
fails(0, "", "No Wispr")
fails(0, '[{"text":""}]', "No Wispr")
fails(0, '[{"text":null}]', "No Wispr")

startWorks = false
module.typeLatest()
assert(alerts[#alerts]:find("Could not start", 1, true))
startWorks, createWorks = true, false
module.typeLatest()
assert(alerts[#alerts]:find("Could not start", 1, true))
createWorks = true
module.typeLatest()
tasks[#tasks].complete(0, hs.json.encode({ { text = "retry succeeded" } }))
assert(typed[#typed] == "retry succeeded", "reader must recover after errors")

clipboardWorks = false
local beforeTyped, beforeClipboard = #typed, clipboard
module.typeLatest()
tasks[#tasks].complete(0, hs.json.encode({ { text = "clipboard write fails" } }))
assert(#typed == beforeTyped and clipboard == beforeClipboard, "clipboard failure must not paste stale text")
assert(alerts[#alerts]:find("Could not copy", 1, true))
return "PASS: read-only query, transcript-to-clipboard-to-Hyper+V order, Unicode, errors, and recovery"
