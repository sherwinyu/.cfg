# Local navigation workflow

Observed on **2026-10-28**. Inspect live configuration before relying on this
snapshot; the user's later edits take precedence.

## Device and configuration ownership

The connected device was an **ErgoDox EZ Glow**. Keymapp initially identified
layout `NKmeX`, revision `bvjVvA`, titled **Lumpy v2 final - new edit**. After the
navigation edits were compiled and the user flashed the keyboard, Keymapp
identified revision `WvRKvl`. These are historical identifiers, not a directive
to flash that revision again. Another Oryx window showed a Voyager layout during
the session; the frontmost browser tab was not reliable device identification.

The editable draft already contained **Mouse Button 6/7/8** assignments absent
from the old compiled view. The user explicitly approved including those edits.
That approval was for this build, not blanket authorization for future drafts.

| Owner | Source/interface | Role |
| --- | --- | --- |
| ErgoDox firmware | Keymapp Edit → Oryx, held D → nav layer 3 | Emits navigation signals directly |
| Apple keyboards | `~/cfg/karabiner-config/src/index.ts` | Apple-only D simlayer and D+S layer |
| WezTerm | `~/cfg/wezterm/wezterm.lua`; contract `FEATURES.md` | Pane/tab focus and rearrangement |
| Cursor | `~/cfg/cursor/keybindings.json` | Editor groups/tabs and movement |
| Arc | Native Settings → Shortcuts | Split View, tabs, Back/Forward |
| Mouse layer | `~/cfg/hammerspoon/mouse-layer.lua` | Button 4 chords send Back/Forward or Enter |

The Mouse Button 6/7/8 firmware edits and the Hammerspoon Button 4 layer are
separate workflows; do not conflate their numbering or behavior.

## Physical mnemonic and emitted keys

| Physical input | Event | Receiving action |
| --- | --- | --- |
| Hold D + U / I | F18 / F19 | Previous / next pane |
| Hold D + Y / O | Shift+F18 / Shift+F19 | Previous / next tab |
| Add Control to D + U / I | Ctrl+F18 / Ctrl+F19 | Rotate panes in WezTerm; move editor between groups in Cursor |
| Add Control to D + Y / O | Ctrl+Shift+F18 / Ctrl+Shift+F19 | Move tab left / right in WezTerm and Cursor |
| Hold D + H / J / K / L | Left / Down / Up / Right | Ordinary arrows, interpreted by the active app/mode |

The Apple D+S+U/I layer also emits the shifted F18/F19 pair. The exact optional
modifier handling differs between Karabiner's simlayer and duo-layer; inspect
the generated rules for a requested combination rather than generalizing from
one of them. Control-to-move actions were not configured in Arc during this session.

Keep Command-[ / Command-] available for Back/Forward. Control was already the
user's move modifier. Command+Option+Control+Left/Right also conflicted with
Rectangle's display-movement shortcuts, motivating the F18/F19 family.

In the scratch Neovim profile, ordinary Left/Right map to tabs and Up/Down to
pane cycling in normal mode. Inspect `~/cfg/nvim-configs/scratch/FEATURES.md` and
the active profile before changing Neovim behavior; firmware arrows do not imply
one universal action across apps or editing modes.

## Arc native shortcut recorder

1. Open Arc settings with Command-comma, then **Shortcuts**. Use its search field
   to narrow the list. Do not confuse this panel with `arc://extensions/shortcuts`.
2. For panes, find **Switch to previous Split View** and **Switch to next Split
   View**. For sequential tabs, find **Previous Tab / Next Tab**, including their
   **Alternate** entries. **Tab Switcher (forward/backward)** is a different action.
3. Click the small shortcut field at the right of the target row, then send the
   chord. Row selection alone only shows its description. The recorder may be
   absent from the accessibility tree, so locate it in a fresh screenshot.
4. Verify the resulting row text and, when useful, the customized-shortcuts list.
   Assigning an Alternate entry can display the ordinary action name after it
   moves into Customized Shortcuts. Judge by action and saved chord, not the old
   row position or the word Alternate alone.

The session used these computer-use key names:

```javascript
await arc.pressKey("F18");
await arc.pressKey("F19");
await arc.pressKey("shift+F18");
await arc.pressKey("shift+F19");
await arc.pressKey("super+bracketleft");
```

The saved result was F18/F19 for previous/next Split View, Shift+F18/F19 for
previous/next tab, and Command-[ / Command-] for Go Back/Go Forward. Go Back's
bracket entry had been unassigned (`---`) and was restored after freeing it from
pane navigation. Forward already had its bracket binding, so it needed no edit.
Unrelated alternative shortcuts and website-priority preferences were preserved.

## Local build and verification

Regenerate Karabiner from **its own directory**, using its documented command:

```sh
cd ~/cfg/karabiner-config
./node_modules/.bin/tsc --noEmit
npm run build
```

The build writes the named profile. Inspect the selected profile and affected
rules in `~/.config/karabiner/karabiner.json` afterward; source edits alone are not
deployment evidence. Check Apple-only device conditions as well as emitted keys.

For WezTerm, the installed version had no `show-config`. These validators worked:

```sh
wezterm --config-file ~/cfg/wezterm/wezterm.lua ls-fonts --text a
wezterm --config-file ~/cfg/wezterm/wezterm.lua show-keys --lua
```

They validated parsing and all eight F18/F19 assignments. The computer-use tool
blocked WezTerm, so real-window pane focus, zoom preservation, and movement were
**not tested** in this session. Arc's saved preferences were visually verified,
and the firmware flash was confirmed by Oryx's success screen plus Keymapp's
reconnected revision. Do not upgrade these observations into a claim that every
physical gesture or application behavior passed end to end.
