# WezTerm feature spec

This is the behavior contract for the custom workflows in the WezTerm config (`~/cfg/wezterm`). It describes what the terminal must let a person do, independent of the Lua or shell code that provides it. Standard WezTerm behavior and every individual keymap are outside this spec; add a story here when a custom workflow becomes part of the expected experience.

The leader is `` ` `` (backtick), which opens a one-second key table, so "leader `r`" means `` ` `` then `r`. Unless a story says otherwise, state lasts for the life of the pane or the WezTerm GUI process and is not saved to disk.

## Pane badges

A badge answers "what is this tab for, and what is the agent in it doing?" at a glance, without switching to the tab. It is a terminal-native stand-in for iTerm2 badges, which WezTerm does not support ([wezterm#3312](https://github.com/wezterm/wezterm/issues/3312)). There are two kinds, and they never overwrite each other: a **manual badge** that belongs to the person, and an **agent badge** that belongs to whatever automation is running in the pane.

### WEZ-01 — Label a pane by hand

**Story:** As a person juggling several tabs, I can give a pane a short label so I can tell my tabs apart by purpose rather than by directory.

**Acceptance criteria**

- Leader `r` prompts for a badge for the active pane; submitting text sets it, submitting empty input clears it, and `Esc` leaves it unchanged.
- `badge <words>` sets the same badge from a shell in the pane, without quoting; `badge -c` clears it.
- The manual badge is short by design: at most 3 words. Extra words are dropped with a visible warning rather than rejected.
- The manual badge has one length and looks the same whether the tab bar is in short or long mode.
- Setting a new badge replaces the old one. The badge disappears when the pane closes.
- Leader `r` works whatever is running in the pane (a shell, an editor, an agent), not only at a shell prompt.

### WEZ-02 — Let an agent report what it is doing

**Story:** As someone running coding agents in several tabs, I can see each agent's current task in the tab bar so I know which tab needs me without opening each one.

**Acceptance criteria**

- `badge -a <short> [long]` sets the agent badge: a short form of at most 3 words and a long form of at most 9 words. The long form defaults to the short one. `badge -a -c` clears it.
- An agent can run `badge` from a subprocess that has no controlling terminal (for example, Claude Code's Bash tool), and the badge still lands on the pane the agent runs in.
- Setting or clearing the agent badge never changes the manual badge, and vice versa.
- If the command cannot find the pane's terminal, it fails with a clear message instead of silently doing nothing.

### WEZ-03 — Read badges in the tab bar

**Story:** As a person scanning my tabs, I can read badges next to each tab's title, distinguish my labels from agents' at a glance, and still see which tab is which.

**Acceptance criteria**

- Each tab shows its title, then the manual badge, then the agent badge, as visually distinct pills: the manual and agent badges use different colors that stay legible on both active and inactive tabs.
- A tab shows at most one badge of each kind. The active pane's badge wins; otherwise the first other pane in the tab that has one is shown, so an agent running in a split still marks its tab.
- The title is never squeezed out by badges: it keeps a minimum width, and when space runs short the badges are truncated, not the title.
- A tab with no badges looks exactly as it did before badges existed.

### WEZ-04 — Switch between short and long agent badges

**Story:** As a person who usually wants a compact tab bar, I can temporarily expand agent badges to their longer description when I need more detail.

**Acceptance criteria**

- Leader `b` toggles all windows between short and long agent badges; toggling again restores short.
- Long mode widens tabs enough for a title, a manual badge, and a 9-word agent badge; short mode returns to the normal tab width.
- If the requested length is empty, the other length is shown instead of nothing.
- The mode resets to short when the WezTerm GUI restarts.

## Pane and tab navigation

### WEZ-05 — Navigate and rearrange without using history shortcuts

**Story:** I can use the same D-layer keys on my Apple keyboard and ErgoDox to
focus panes, switch tabs, and rearrange them while leaving Command-brackets
available for application history.

**Acceptance criteria**

- `D+U/I` emits `F18/F19` and focuses the previous/next pane, preserving pane zoom.
- `D+Y/O` emits `Shift+F18/F19` and switches to the previous/next tab.
- Adding Control rotates panes for `U/I` or moves tabs left/right for `Y/O`.
- On the Apple keyboard, `D+S+U/I` also emits `Shift+F18/F19`.
- `D+H/J/K/L` continues emitting ordinary arrow keys.
- Command-brackets and their shifted/control variants no longer invoke these
  custom WezTerm pane/tab actions.

## Current interface and implementation

This table is a locator for maintainers. The stories above are the contract; these files can change.

| Stories | Current interface | Current implementation |
| --- | --- | --- |
| WEZ-01–02 | Leader `r`; `badge`, `badge -a`, `badge -c` (on `PATH` via `~/.local/bin/badge`) | `badge.sh` writes pane user vars (`badge`, `agent_badge_short`, `agent_badge_long`) with `OSC 1337 SetUserVar` to `$CLAUDE_WEZTERM_TTY` (set in `~/.zshrc`) or `/dev/tty`; leader `r` in `wezterm.lua` calls it with the pane's tty |
| WEZ-03 | Automatic | `get_tab_badges` and the `format-tab-title` handler in `wezterm.lua`; `config.tab_max_width` |
| WEZ-04 | Leader `b` | `wezterm.GLOBAL.badge_long` and per-window `tab_max_width` overrides in `wezterm.lua` |
| WEZ-05 | `F18/F19`; Shift selects tabs; Control rearranges | `config.keys` in `wezterm.lua`; Apple D-layer in `karabiner-config/src/index.ts`; ErgoDox nav layer 3 in Oryx |

Claude Code runs Bash commands in a sandbox that cannot write to the pane's tty, so `badge` and `badge.sh` are listed in `sandbox.excludedCommands` in `~/cfg/.claude/settings.local.json`.

## Changing an implementation

1. Read the affected stories before changing a handler, key binding, script, or user var.
2. Preserve the acceptance criteria and user-facing bindings when replacing an implementation. If the intended behavior changes, update the story and explain the migration in the same commit.
3. Verify the affected scenarios in a real WezTerm window: set and clear both badge kinds from a shell and from a Claude Code session, put an agent badge on a non-active split, and check a tab with long badges in both modes.
4. Update the implementation table when files move. Add a new story for each new custom workflow.

For a new workflow, copy this shape:

```markdown
### WEZ-XX — User-visible outcome

**Story:** As a [user], I can [action] so that [benefit].

**Acceptance criteria**

- Given [starting state], when [action], then [observable result].
- When [missing input or unsupported context], the terminal [clear fallback].
```
