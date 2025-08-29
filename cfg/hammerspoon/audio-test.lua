-- Audio device management examples

-- Get all audio devices
local function listAudioDevices()
	print("=== INPUT DEVICES ===")
	local inputDevices = hs.audiodevice.allInputDevices()
	for i, device in ipairs(inputDevices) do
		print(i .. ". " .. device:name() .. " (UID: " .. device:uid() .. ")")
	end

	print("\n=== OUTPUT DEVICES ===")
	local outputDevices = hs.audiodevice.allOutputDevices()
	for i, device in ipairs(outputDevices) do
		print(i .. ". " .. device:name() .. " (UID: " .. device:uid() .. ")")
	end
end

-- Get current default devices
local function showCurrentDefaults()
	local defaultInput = hs.audiodevice.defaultInputDevice()
	local defaultOutput = hs.audiodevice.defaultOutputDevice()

	print("Current default input: " .. (defaultInput and defaultInput:name() or "None"))
	print("Current default output: " .. (defaultOutput and defaultOutput:name() or "None"))
end

-- Set audio device by name
local function setAudioDevice(deviceName, isInput)
	local devices = isInput and hs.audiodevice.allInputDevices() or hs.audiodevice.allOutputDevices()

	for _, device in ipairs(devices) do
		if device:name() == deviceName then
			if isInput then
				device:setDefaultInputDevice()
			else
				device:setDefaultOutputDevice()
			end
			print("Set " .. (isInput and "input" or "output") .. " device to: " .. deviceName)
			return true
		end
	end
	print("Device not found: " .. deviceName)
	return false
end

local function setAudioConfig(config)
	config = config or {}
	local inputDevices = config.input or {}
	local outputDevices = config.output or {}

	local selectedOutput = nil
	local selectedInput = nil

	-- Set output device in priority order
	if #outputDevices > 0 then
		local availableOutputs = hs.audiodevice.allOutputDevices()
		for _, priorityDevice in ipairs(outputDevices) do
			for _, device in ipairs(availableOutputs) do
				if device:name() == priorityDevice then
					device:setDefaultOutputDevice()
					selectedOutput = priorityDevice
					print("Set output device to: " .. priorityDevice)
					goto nextInput
				end
			end
		end
		print("No priority output devices found")
	end

	::nextInput::
	-- Set input device in priority order
	if #inputDevices > 0 then
		local availableInputs = hs.audiodevice.allInputDevices()
		for _, priorityDevice in ipairs(inputDevices) do
			for _, device in ipairs(availableInputs) do
				if device:name() == priorityDevice then
					device:setDefaultInputDevice()
					selectedInput = priorityDevice
					print("Set input device to: " .. priorityDevice)
					break
				end
			end
		end
		if not selectedInput then
			print("No priority input devices found")
		end
	end

	-- Show notification with selected devices
	local notificationText = "Audio Config Updated"
	local details = {}

	if selectedOutput then
		table.insert(details, "Output: " .. selectedOutput)
	else
		table.insert(details, "Output: No change")
	end

	if selectedInput then
		table.insert(details, "Input: " .. selectedInput)
	else
		table.insert(details, "Input: No change")
	end

	local notification = hs.notify.new({
		title = notificationText,
		informativeText = table.concat(details, "\n"),
		withdrawAfter = 3,
	})

	notification:send()
	print("Notification sent successfully")
end

-- Example hotkeys for common audio switching scenarios
local function setupAudioHotkeys()
	-- List devices (for debugging)
	hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "l", function()
		listAudioDevices()
		showCurrentDefaults()
	end)

	-- Example: Switch to AirPods (you'll need to adjust device names)
	hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "a", function()
		setAudioDevice("AirPods Pro", false) -- output
		setAudioDevice("AirPods Pro", true) -- input
	end)

	-- Example: Switch to built-in (you'll need to adjust device names)
	hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "b", function()
		setAudioDevice("MacBook Pro Speakers", false) -- output
		setAudioDevice("MacBook Pro Microphone", true) -- input
	end)
end

return {
	listAudioDevices = listAudioDevices,
	showCurrentDefaults = showCurrentDefaults,
	setAudioDevice = setAudioDevice,
	setAudioConfig = setAudioConfig,
	setupAudioHotkeys = setupAudioHotkeys,
}
