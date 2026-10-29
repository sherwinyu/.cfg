local M = {}

function M.typeText(text, emptyMessage)
	if not text or text == "" then
		hs.alert.show(emptyMessage or "Clipboard has no text to type")
		return false
	end
	hs.eventtap.keyStrokes(text)
	return true
end

local function typeClipboardAsKeystrokes()
	M.typeText(hs.pasteboard.getContents())
end

local clipboardTapTimer
local clipboardCopyPending = false

-- A second trigger within 300 ms copies with Ctrl+Cmd+C before typing.
function M.trigger()
	if clipboardCopyPending then return end

	if clipboardTapTimer then
		clipboardTapTimer:stop()
		clipboardTapTimer = nil
		clipboardCopyPending = true
		-- Watch before sending the copy chord so even an immediate update is noticed.
		hs.pasteboard.callbackWhenChanged(2, function(changed)
			clipboardCopyPending = false
			if changed then
				typeClipboardAsKeystrokes()
			else
				hs.alert.show("Copy shortcut did not update the clipboard")
			end
		end)
		hs.eventtap.keyStroke({ "ctrl", "cmd" }, "c", 10000)
	else
		clipboardTapTimer = hs.timer.doAfter(0.3, function()
			clipboardTapTimer = nil
			typeClipboardAsKeystrokes()
		end)
	end
end

return M
