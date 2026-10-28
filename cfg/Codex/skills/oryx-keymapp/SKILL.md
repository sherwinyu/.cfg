---
name: oryx-keymapp
description: Edit ZSA keyboard layouts, layers, keycodes, and modifiers in Oryx, and inspect or flash connected keyboards with Keymapp. Use for requests involving the Oryx configurator, Keymapp (sometimes called Keymap), or ZSA keyboard firmware changes. Coordinate receiving app shortcuts when requested. Ordinary Karabiner-only or app-only remapping does not need this workflow.
---

# Oryx and Keymapp

Keep these states distinct:

**Requested physical gesture → firmware draft → compiled revision → flashed
device → emitted event → receiving app action.**

Success at one boundary does not establish the next. Verify each boundary the
available tools can actually exercise.

## Identify the keyboard and starting revision

- Open **Keymapp** (`keymapp` or bundle ID `io.zsa.keymapp`) and read the connected
  model and **My Layout / Edit** links. The attached keyboard's layout ID and
  revision are better starting points than whichever Oryx tab happens to be open.
- Follow **Edit** into Oryx using the existing authenticated browser when possible.
  It may open **Little Arc**, a separate window from the main Arc browser.
- Check whether the page is a read-only compiled revision, an editable draft, or
  a last-compiled view with **pending changes**. `latest` alone does not establish
  which state is displayed. Another browser profile may show a compiled public
  layout while the authenticated session contains pending edits.
- Inspect existing pending edits before including them in a firmware build.
  Preserve them. If flashing would deploy unrelated edits whose inclusion is not
  already authorized, prepare the requested changes for review and resolve that
  scope before flashing the combined draft. Do not discard them or replace them
  with an old compiled revision.

Do not ask again for a flash or setting change already authorized by the task.
Creating a skill, inspecting a layout, or proposing keys does not itself authorize
flashing a device or changing other applications.

## Change the intended action in Oryx

1. Inspect the base-layer key to find its held layer; open that layer and locate
   the physical keys being changed. Separate ordinary taps, holds, double taps,
   and tap-then-hold actions.
2. Open a key, then its existing **tapped** action (or the requested action).
   Use the key search, inspect the result, and select the keycode. A search for
   `F18` followed by Enter worked in this session, but Enter sent before the
   result appeared did not assign it.
3. Inspect and set modifiers explicitly after replacing the keycode. In the
   observed UI, replacing Command-bracket with F18 removed the old modifiers;
   Shift had to be added again for the tab keys. Check labels and per-key colors
   as well as other actions instead of assuming they survived the replacement.
4. **Close** the picker, dismiss the key popover, and verify the rendered layer
   labels. For example, `F18` and `Shift+F18` are different outcomes.

The modifier grid can appear as one aggregate text node in accessibility output.
When semantic actions cannot reach its controls, use a fresh screenshot to click
the actual modifier. Do not persist accessibility indices or pixel coordinates
in scripts: both change between keys, popovers, windows, and displays.

## Compile, flash, and reconnect

- Verify the final affected keys and modifier combinations before compiling.
  If a change note is available, describe the actual change and any approved
  pre-existing edits included in this build.
- Click **Compile this layout** and inspect the resulting state. **Compiling...**
  is intermediate; a compiled page or firmware download is not a completed flash.
- Follow **Save to my keyboard** or Keymapp **Flash** for the identified device.
  If a file chooser is involved, match the firmware to the intended model, layout,
  and compiled revision; do not choose a file by recency alone.
- A physical reset may require the user. Prepare the concrete firmware and reach
  that step before requesting the reset. **Ergodox in Reset Mode** means the
  device is ready for flashing, not that flashing succeeded.
- After the success/reboot screen, reconnect in Keymapp if needed and inspect its
  layout/revision links again. If the user says they flashed it themselves,
  verify the reconnected device rather than flashing a second time.

Report separately what was edited, compiled, flashed, reconnected, and tested.
When possible, test the requested physical gesture and its receiving application.
A rendered layout and matching revision support configuration/deployment claims;
they do not prove every physical chord works.

## Coordinate app bindings when requested

Inventory both the emitter and consumer before choosing replacement keys.
Firmware changes do not configure app shortcuts. A machine may also have a
Karabiner layer for its built-in keyboard that deliberately excludes the ZSA
device; do not apply both transformations to the same device accidentally.

Preserve the user's modifier relationships. In the workflow documented here,
Shift selects tabs and Control changes focus/switch into move/rearrange. Control
therefore cannot also become a required base modifier. Check global shortcuts
such as Rectangle before choosing a new chord family. F18/F19 are useful custom
signals when emitted from a layer, but each receiving app still needs bindings.

For local sources, the Arc recorder procedure, and the observed navigation scheme,
read [references/local-navigation.md](references/local-navigation.md). Treat its
dated layout revision as a breadcrumb and recheck current device state.

## Recover UI interaction without losing context

- Use the current computer-use API for UI work. Refresh its documentation after
  an interruption/context reset, then inspect the target window before acting.
- Selecting a shortcut row is not activating its recorder. Accessibility actions
  can work while coordinate clicks fail because a window is behind another app.
  In Arc, **Window → Bring All to Front**, followed by a fresh screenshot,
  resolved this session's coordinate hit-testing failures.
- Do not repeatedly move windows between monitors, guess scale factors, or retry
  stale coordinates. Use the original screenshot's coordinate system; translate
  cropped/downsampled previews back to it instead of applying Retina scaling twice.
- If the user changes the app, discard pending UI assumptions and inspect the new
  state. If simultaneous input continues, coordinate a brief clear window for UI
  work; continue independent source edits/checks meanwhile.
- If a tool blocks an app, do not switch input technologies to bypass that block.
  Use permitted configuration validation where available and disclose the missing
  live test. A CLI parsing a config is not a successful physical/UI workflow.
