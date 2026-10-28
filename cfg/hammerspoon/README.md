# Hammerspoon mouse layer

Hold **Button 4** (normally the mouse's Back/thumb button):

| While holding Button 4 | Action |
| --- | --- |
| Left click | Back (`Cmd+[`) |
| Right click | Forward (`Cmd+]`) |
| Left and right together | Enter |

Actions fire when all click buttons in the gesture are released. For Enter,
press the second click button before releasing the first; either order works.
There is no timing threshold. You can keep Button 4 held for repeated gestures.
Releasing Button 4 before the click buttons still finishes the captured gesture.
Button 4 alone does nothing. Other clicks work normally outside the layer.
Layer clicks and drags are consumed, so they do not click links or open menus.
Back/Forward use the application's keyboard shortcuts, so support depends on the app.

Implemented in `mouse-layer.lua`, loaded by `init.lua`. Button 4 corresponds to
Quartz/Hammerspoon event button number **3**, since those event numbers start at zero.
The layer resets on sleep or screen lock. A mouse utility must deliver Button 4
as a mouse button rather than translating it into a keyboard shortcut.

Run the gesture regression checks with:

```sh
luajit ~/cfg/hammerspoon/tests/mouse-layer-test.lua
```

To disable temporarily in the Hammerspoon Console:

```lua
require("mouse-layer"):stop()
```

Restart with `require("mouse-layer"):start()` or reload Hammerspoon.
