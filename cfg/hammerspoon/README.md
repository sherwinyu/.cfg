# Hammerspoon configuration

## Mouse layer

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

## Type the clipboard

Hyper is Command+Option+Control+Shift. Tap **Hyper+V** once to type the current
clipboard as keystrokes after a 300 ms double-tap window.

Tap **Hyper+V** twice within that window to send **Control+Command+C**, wait up
to two seconds for the clipboard to change, then type the new contents. Further
taps are ignored while the copy is pending. An empty clipboard or a copy that
does not update it produces an alert instead of typing stale text.

Implemented in `hotkeys.lua`. The double-tap action depends on the active app
handling Control+Command+C; this configuration does not define that copy action.

## Peek at Linear issues and PRs

Select a Linear issue ID (`SHE-287`, `sherwin/she-287-fix`, a linear.app URL) or a
GitHub ref (`#335`, `owner/repo#12`, a PR/issue URL) in WezTerm to see a popover.
Linear issues show the ID, assignee with avatar, title, description, and workflow
state with its Linear-style icon and priority. GitHub PRs and issues show a state
icon (open, draft, merged, closed, not planned), title, `repo#number` and author,
description, and for PRs the changed files and `+additions -deletions`. The
description scrolls; clicking anywhere else on the card opens it.
Clicking the popover opens a Linear issue in the Linear desktop app (`linear://`,
falling back to the browser if it is not installed) and a GitHub ref in the browser.

| Trigger | Where |
| --- | --- |
| Select text containing a match (drag or double-click) | WezTerm |
| **Hyper+I** over a match (press again to close) | Any app |

Selection works because WezTerm copies a mouse selection to the clipboard on
release: after a left-button release in WezTerm, the clipboard is read only if it
changed within 150 ms. The first ref among the selected words wins; selections
over 200 characters are ignored. If a single-word selection does not match by
itself, it is extended to the on-screen word that contains it (OCR around the
release point), so selecting `123` in `#123` or `SHE` in `SHE-287` works.

The popover closes when the mouse leaves it and its anchor, on any key, or on
a scroll or click outside it. Bare `#123` resolves to `sherwinyu/oryoki`. Linear
IDs only match your Linear team keys (fetched daily), so `UTF-8` is ignored.

How it works: for the hotkey and for extending a selection, Hammerspoon snapshots a
560×56 pt strip around the mouse, and a
long-lived Swift helper (`hover-peek/ocr.swift`, Apple Vision) returns word boxes
(~50 ms warm). The helper is compiled to `~/.cache/hover-peek/hover-peek-ocr`
on first use and again whenever the source changes. Data comes from `linear-cli`
and `gh api`, cached in `~/.cache/hover-peek/cache.json`; entries older than 5
minutes are shown immediately and refreshed in the background.

Requires **Screen Recording** permission for Hammerspoon (System Settings →
Privacy & Security → Screen & System Audio Recording); without it, the OCR sees
only the wallpaper. Options (selection apps, hotkey, default repo, Linear desktop links, cache age)
are in `M.config` in `hover-peek.lua` and can be passed to `start()`.

```sh
luajit ~/cfg/hammerspoon/tests/hover-peek-test.lua
```
