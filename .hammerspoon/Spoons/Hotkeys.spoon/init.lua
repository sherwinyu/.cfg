--- === MouseFollowsFocus ===
---
--- Set the mouse pointer to the center of the focused window whenever focus changes.
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MouseFollowsFocus.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MouseFollowsFocus.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "MouseFollowsFocus"
obj.version = "0.1"
obj.author = "Jason Felice <jason.m.felice@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- MouseFollowsFocus.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('MouseFollowsFocus')

--- MouseFollowsFocus:configure(configuration)
--- Method
--- Configures the spoon.  There is currently nothing to configure.
---
--- Parameters:
---   * configuration - :
function obj:configure(configuration)
end

--- MouseFollowsFocus:start()
--- Method
--- Starts updating the mouse position when window focus changes
---
--- Parameters:
function obj:start()


  self.window_filter = hs.window.filter.new()
    :setDefaultFilter({
      visible = true,
      allowRoles = {"AXStandardWindow"}  -- Include only standard windows
    })
    :setOverrideFilter({
      visible = true,
      allowRoles = {"AXStandardWindow"}  -- Include only standard windows
    })

  self.window_filter:subscribe({
    hs.window.filter.windowFocused
  }, function(window)
    self:updateMouse(window)
  end)
end

--- MouseFollowsFocus:stop()
--- Method
--- Stops updating the mouse position when window focus changes
---
--- Parameters:
function obj:stop()
  self.window_filter:unsubscribeAll()
  self.window_filter = nil
end


function obj:updateMouse(window)
  local current_pos = hs.mouse.getAbsolutePosition()
  local frame = window:frame()
  local frame_center = {x = frame.x + frame.w / 2, y = frame.y + frame.h / 2}

  -- Debugging output
  -- hs.alert.show("Current Pos: " .. tostring(current_pos.x) .. ", " .. tostring(current_pos.y))
  -- hs.alert.show("Frame Center: " .. tostring(frame_center.x) .. ", " .. tostring(frame_center.y))

  if not hs.geometry.point(current_pos):inside(frame) then
    hs.mouse.setAbsolutePosition(frame_center)
  end
end

return obj
