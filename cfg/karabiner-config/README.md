Run `npm install` and then run `npm run build`

The Apple-keyboard D navigation layer emits `F18/F19` for `U/I` (previous/next
pane), and `Shift+F18/F19` for `Y/O` (previous/next tab). `D+S+U/I` also emits the
shifted pair. Additional held modifiers, including Control for rearranging,
are preserved by the layer. H/J/K/L still emit arrow keys.

Bind these signals in each application; the custom mappings live in
`../wezterm/wezterm.lua` and `../cursor/keybindings.json`. Command-brackets are
available for application history. The ErgoDox implements the same navigation
signals in its Oryx firmware rather than in this Apple-only Karabiner layer.

Arc's native Settings > Shortcuts uses the same pair: `F18/F19` for
Switch to previous/next Split View, and `Shift+F18/F19` for Previous/Next Tab.
Go Back/Go Forward retain `Cmd+[` / `Cmd+]`. These Arc preferences are stored
by Arc, not generated from this repository.
