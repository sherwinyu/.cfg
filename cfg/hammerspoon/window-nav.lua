-- Window Navigation based on visual center points
-- Provides next/prev traversal in "reading order" (top-to-bottom, left-to-right)
-- and directional navigation (left/right/up/down)

local M = {}

-- Get center point of a window frame
local function getCenter(frame)
	return {
		x = frame.x + frame.w / 2,
		y = frame.y + frame.h / 2
	}
end

-- Check if a point is inside a frame
local function pointInFrame(point, frame)
	return point.x >= frame.x and point.x <= frame.x + frame.w and
	       point.y >= frame.y and point.y <= frame.y + frame.h
end

-- Get all visible windows whose centroid is not covered by another window
local function getWindowsWithCenters()
	-- orderedWindows returns front-to-back (topmost first)
	local orderedWindows = hs.window.orderedWindows()
	local result = {}

	for i, win in ipairs(orderedWindows) do
		if win:isStandard() and win:isVisible() then
			local frame = win:frame()
			local center = getCenter(frame)

			-- Check if any window in front (earlier in list) covers this centroid
			local isCovered = false
			for j = 1, i - 1 do
				local frontWin = orderedWindows[j]
				if frontWin:isStandard() and frontWin:isVisible() then
					local frontFrame = frontWin:frame()
					if pointInFrame(center, frontFrame) then
						isCovered = true
						break
					end
				end
			end

			if not isCovered then
				table.insert(result, {
					window = win,
					center = center,
					frame = frame
				})
			end
		end
	end

	return result
end

-- Sort windows in reading order: top-to-bottom, left-to-right
-- Uses a tolerance band for "same row" detection
local function sortReadingOrder(windows)
	local rowTolerance = 50 -- pixels - windows within this vertical range are "same row"

	table.sort(windows, function(a, b)
		-- If centers are within tolerance vertically, sort by X
		if math.abs(a.center.y - b.center.y) < rowTolerance then
			return a.center.x < b.center.x
		end
		-- Otherwise sort by Y
		return a.center.y < b.center.y
	end)

	return windows
end

-- Find index of current window in sorted list
local function findCurrentIndex(windows, currentWin)
	for i, w in ipairs(windows) do
		if w.window:id() == currentWin:id() then
			return i
		end
	end
	return nil
end

-- Navigate to next window in reading order
function M.focusNext()
	local currentWin = hs.window.focusedWindow()
	if not currentWin then return end

	local windows = sortReadingOrder(getWindowsWithCenters())
	if #windows < 2 then return end

	local currentIndex = findCurrentIndex(windows, currentWin)
	if not currentIndex then return end

	local nextIndex = (currentIndex % #windows) + 1
	windows[nextIndex].window:focus()
end

-- Navigate to previous window in reading order
function M.focusPrev()
	local currentWin = hs.window.focusedWindow()
	if not currentWin then return end

	local windows = sortReadingOrder(getWindowsWithCenters())
	if #windows < 2 then return end

	local currentIndex = findCurrentIndex(windows, currentWin)
	if not currentIndex then return end

	local prevIndex = ((currentIndex - 2) % #windows) + 1
	windows[prevIndex].window:focus()
end

-- Euclidean distance between two points
local function distance(p1, p2)
	local dx = p1.x - p2.x
	local dy = p1.y - p2.y
	return math.sqrt(dx * dx + dy * dy)
end

-- Directional navigation: find closest window in given direction
local function focusDirection(direction)
	local currentWin = hs.window.focusedWindow()
	if not currentWin then return end

	local currentFrame = currentWin:frame()
	local currentCenter = getCenter(currentFrame)
	local windows = getWindowsWithCenters()

	-- Filter candidates based on direction
	local candidates = {}
	for _, w in ipairs(windows) do
		if w.window:id() ~= currentWin:id() then
			local dominated = false
			if direction == "left" and w.center.x < currentCenter.x then
				dominated = true
			elseif direction == "right" and w.center.x > currentCenter.x then
				dominated = true
			elseif direction == "up" and w.center.y < currentCenter.y then
				dominated = true
			elseif direction == "down" and w.center.y > currentCenter.y then
				dominated = true
			end

			if dominated then
				table.insert(candidates, w)
			end
		end
	end

	if #candidates == 0 then return end

	-- Find closest candidate by euclidean distance
	local closest = nil
	local closestDist = math.huge

	for _, w in ipairs(candidates) do
		local dist = distance(currentCenter, w.center)
		if dist < closestDist then
			closestDist = dist
			closest = w
		end
	end

	if closest then
		closest.window:focus()
	end
end

function M.focusLeft()
	focusDirection("left")
end

function M.focusRight()
	focusDirection("right")
end

function M.focusUp()
	focusDirection("up")
end

function M.focusDown()
	focusDirection("down")
end

-- Setup hotkeys with given modifier
function M.bindHotkeys(mods)
	hs.hotkey.bind(mods, "u", M.focusPrev)
	hs.hotkey.bind(mods, "i", M.focusNext)
	-- Directional (optional, can bind separately)
	-- hs.hotkey.bind(mods, "h", M.focusLeft)
	-- hs.hotkey.bind(mods, "l", M.focusRight)
	-- hs.hotkey.bind(mods, "k", M.focusUp)
	-- hs.hotkey.bind(mods, "j", M.focusDown)
end

return M
