-- Hold mouse Button 4 (Quartz button 3) to turn clicks into navigation.
local M = {}
local types = hs.eventtap.event.types
local buttonNumber = hs.eventtap.event.properties.mouseEventButtonNumber
local modifierDown = false
local pressed = {}
local seen = {}
local pasteTranscript
local transcriptDown = false

local function reset()
	transcriptDown = false
	modifierDown = false
	pressed = {}
	seen = {}
end

local function handle(event)
	local kind = event:getType()
	if pasteTranscript and event:getProperty(buttonNumber) == 7 then
		if kind == types.otherMouseDown then
			transcriptDown = true
		elseif kind == types.otherMouseUp and transcriptDown then
			transcriptDown = false
			pasteTranscript()
		end
		return true
	end
	if event:getProperty(buttonNumber) == 3 then
		if kind == types.otherMouseDown then
			modifierDown = true
			return true
		elseif kind == types.otherMouseUp then
			modifierDown = false
			-- Keep consuming a captured click even if Button 4 is released first.
			return true
		elseif kind == types.otherMouseDragged and modifierDown then
			return true
		end
	end

	local button, phase
	if kind == types.leftMouseDown then button, phase = "left", "down"
	elseif kind == types.rightMouseDown then button, phase = "right", "down"
	elseif kind == types.leftMouseUp then button, phase = "left", "up"
	elseif kind == types.rightMouseUp then button, phase = "right", "up"
	elseif kind == types.leftMouseDragged then button, phase = "left", "drag"
	elseif kind == types.rightMouseDragged then button, phase = "right", "drag"
	else return false end

	if phase == "down" then
		if not modifierDown then return false end
		pressed[button], seen[button] = true, true
		return true
	end
	-- Leave releases/drags alone if their press happened outside this layer.
	if not pressed[button] then return false end
	if phase == "drag" then return true end
	pressed[button] = nil
	if next(pressed) then return true end

	-- Decide only after all captured buttons are released, so a two-button
	-- chord never sends Back/Forward before Enter. Either press order works.
	local modifiers, key = { "cmd" }, seen.left and "[" or "]"
	if seen.left and seen.right then modifiers, key = {}, "return" end
	seen = {}
	return true, {
		hs.eventtap.event.newKeyEvent(modifiers, key, true),
		hs.eventtap.event.newKeyEvent(modifiers, key, false),
	}
end

function M:start(onPasteTranscript)
	if self.tap then return self end
	reset()
	pasteTranscript = onPasteTranscript
	self.tap = hs.eventtap.new({
		types.otherMouseDown, types.otherMouseUp, types.otherMouseDragged,
		types.leftMouseDown, types.leftMouseUp, types.leftMouseDragged,
		types.rightMouseDown, types.rightMouseUp, types.rightMouseDragged,
	}, handle):start()
	self.sleepWatcher = hs.caffeinate.watcher.new(function(event)
		if event == hs.caffeinate.watcher.systemWillSleep
			or event == hs.caffeinate.watcher.screensDidLock then reset() end
	end):start()
	return self
end

function M:stop()
	if self.tap then self.tap:stop(); self.tap = nil end
	if self.sleepWatcher then self.sleepWatcher:stop(); self.sleepWatcher = nil end
	reset()
	pasteTranscript = nil
	return self
end

return M
