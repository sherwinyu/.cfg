# User Preferences for Agents

Global instructions for every coding agent session, in any directory. This is the source of truth: `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` are symlinks to this file. Instructions specific to the dotfiles repo live in `~/cfg/AGENTS.md`.

Please greet me at the start of the session as Captain.

## Agent Badges

When running in a WezTerm pane, set an agent badge so the user can see what you're doing from the tab bar (see `~/cfg/wezterm/FEATURES.md`, WEZ-02):

- When you start a substantial task, run `badge -a "<short>" "<long>"`. Use at most 3 words for the short form and at most 9 for the long form, e.g. `badge -a "fixing login" "fixing the SSO redirect loop on staging"`.
- Update it when the task changes meaningfully, for example to `badge -a "needs input" "waiting for your decision on the migration"` when you're blocked on the user.
- Run `badge -a -c` when the task is done.
- Never set or clear the manual badge (`badge` without `-a`); it belongs to the user.
- If `badge` fails (for example, outside WezTerm), carry on without it.
