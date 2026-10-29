local M = {}
local typing = require("clipboard-typing")
local database = os.getenv("HOME") .. "/Library/Application Support/Wispr Flow/flow.sqlite"
local query = [[
SELECT coalesce(editedText, formattedText, asrText) AS text
FROM History WHERE isArchived = 0
ORDER BY timestamp DESC LIMIT 1;
]]
local activeTask

-- Read only the latest transcript; do not log private history or touch the clipboard.
function M.readLatest(callback)
	if activeTask then return false end
	activeTask = hs.task.new("/usr/bin/sqlite3", function(exitCode, stdout)
		activeTask = nil
		if exitCode ~= 0 then
			callback(nil, "Could not read Wispr Flow history")
			return
		end
		if stdout:match("^%s*$") then
			callback(nil, "No Wispr Flow transcript to type")
			return
		end
		local ok, rows = pcall(hs.json.decode, stdout)
		if not ok or type(rows) ~= "table" then
			callback(nil, "Could not decode Wispr Flow history")
			return
		end
		local text = rows[1] and rows[1].text
		if type(text) ~= "string" or text == "" then
			callback(nil, "No Wispr Flow transcript to type")
			return
		end
		callback(text)
	end, { "-readonly", "-json", "-cmd", ".timeout 1000", database, query })
	if not activeTask or not activeTask:start() then
		activeTask = nil
		callback(nil, "Could not start the Wispr Flow history reader")
		return false
	end
	return true
end

function M.typeLatest()
	M.readLatest(function(text, err)
		if err then hs.alert.show(err); return end
		-- This is pasted Wispr Flow transcript.
		if not hs.pasteboard.setContents(text) then
			hs.alert.show("Could not copy the Wispr Flow transcript to the clipboard")
			return
		end
		typing.trigger()
	end)
end

return M
