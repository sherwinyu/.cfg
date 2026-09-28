# `nvb` feature spec

This is the behavior contract for the custom workflows in the scratch Neovim profile (`nvb`). It describes what the editor must let a person do, independent of the plugin or Lua code that provides it. Standard Neovim behavior and every individual keymap are outside this spec; add a story here when a custom workflow becomes part of the expected experience.

`<Space>` means the normal-mode leader key. Unless a story says otherwise, state lasts for the current `nvb` process only.

## Discoverability

### NVB-01 — Find custom actions

**Story:** As an `nvb` user, I can browse named key bindings so I can find a workflow without remembering its keys.

**Acceptance criteria**

- `<Space>sk` opens a searchable list of key bindings with useful descriptions.
- Theme selection, Git baseline review, current-file diff and hunk actions, and the breadcrumb toggle appear in that list.
- Replacing a picker or plugin preserves these discoverable actions and their normal-mode bindings unless the binding change is an explicit product decision.

## Appearance

### NVB-02 — Follow the system appearance

**Story:** As a user who changes macOS appearance, I want `nvb` to start in the matching light or dark theme and update when I return to it.

**Acceptance criteria**

- Starting `nvb` in macOS Light or Dark mode applies a matching editor theme.
- A change to macOS appearance is applied when `nvb` gains focus or resumes.
- Appearance checks occur at startup, focus, and resume without periodic background polling. If macOS changes while `nvb` keeps focus, the theme updates on the next focus or resume event.
- Choosing a theme manually keeps that choice for the current session until macOS appearance changes or `nvb` restarts.

### NVB-03 — Try and choose a color scheme

**Story:** As a user, I can browse available color schemes, preview them, and choose one for the current session.

**Acceptance criteria**

- `<Space>sC` opens a searchable color-scheme picker, and it is discoverable through `<Space>sk`.
- Moving through choices previews their appearance; accepting a choice applies it, and canceling keeps the prior scheme.
- A manual choice does not change the configured light/dark defaults or the macOS appearance setting.

## Git review

### NVB-04 — Choose and retain a comparison base

**Story:** As a developer reviewing a change, I can choose a branch or commit as a baseline and keep using it while I move among files.

**Acceptance criteria**

- `<Space>dc` chooses a branch and `<Space>dC` chooses a commit, then opens a repository-wide review against that base.
- The chosen base is remembered after the review is closed and while other files in the same repository are opened.
- Each Git repository has its own remembered base; choosing one in repository A does not change repository B.
- Canceling the choice leaves the prior base intact. A new `nvb` process starts without a remembered base.
- `<Space>do` still opens the default index comparison, and `<Space>dq` closes the review.

### NVB-05 — Diff the current file against that base

**Story:** After choosing a baseline, I can open a side-by-side diff for whichever file I am currently editing, including a file I opened outside the review sidebar.

**Acceptance criteria**

- `<Space>dv` opens the current file against the remembered base for that file's repository.
- If no base has been chosen, `<Space>dv` compares the current file against the Git index.
- The comparison uses the current file, rather than an earlier file selected in the review sidebar.
- An unnamed buffer receives a clear message instead of opening an unrelated diff.

### NVB-06 — Inspect current-file hunks against that base

**Story:** In a normal file buffer, I can see and navigate changes relative to the chosen baseline without staying in the review sidebar.

**Acceptance criteria**

- `<Space>db` switches hunk signs for the current tracked file to its repository's remembered base. It does not silently change other files' hunk bases.
- `]c` and `[c` move through those hunks; `<Space>hp` previews a hunk; `<Space>hd` opens the current file's hunk comparison.
- `<Space>dB` returns the current file's hunk signs to the Git index comparison without forgetting the chosen review base.
- If no base is remembered or the file cannot show Git hunks, the action explains why and leaves the current comparison alone.

## Code context

### NVB-07 — Keep location visible while editing

**Story:** As I move through a nested file, I can see my file and enclosing code context at the top, even when the defining lines are still visible in the buffer.

**Acceptance criteria**

- The always-show view is the default for normal file windows and updates as the cursor moves.
- It shows the filename and, when syntax context is available, the enclosing scopes around the cursor. Long breadcrumb trails are shortened to fit narrow windows, favoring the nearest scopes.
- It works in split windows. When a parser or context query is unavailable, the filename remains visible and editing continues normally.
- It does not place a breadcrumb bar in utility or floating windows.

### NVB-08 — Switch between always-show and sticky context

**Story:** I can turn off the persistent breadcrumb bar and return to the earlier context display when I want more vertical space.

**Acceptance criteria**

- `<Space>uT` and `:ContextAlwaysToggle` switch between the always-show bar and the original sticky context display.
- In sticky mode, context lines appear when their defining lines have left the viewport. Switching back restores the always-show bar.
- Switching modes restores the prior window-bar contents in every open split; it does not leave stale breadcrumbs behind.
- The existing sticky-context toggle remains available through `<Space>ut`.

### NVB-09 — Jump to an enclosing context

**Story:** While editing nested code, I can jump outward to an enclosing code context and return to where I started.

**Acceptance criteria**

- `gk` and `:ContextUp` jump to an enclosing context when syntax context is available; a count can repeat the jump.
- The initial jump records the prior location as the previous-context mark so the user can return.
- If no enclosing context exists, the buffer is unchanged and I get a clear message.

## Current interface and implementation

This table is a locator for maintainers. The stories above are the contract; these libraries and files can change.

| Stories | Current interface | Current implementation |
| --- | --- | --- |
| NVB-01, NVB-03 | `<Space>sk`, `<Space>sC` | `lua/plugins/fzf-lua.lua` |
| NVB-02 | Automatic on startup, focus, and resume | `lua/plugins/ui.lua`; Tokyo Night Day / Moon today |
| NVB-04–06 | `<Space>dc`, `<Space>dC`, `<Space>dv`, `<Space>db`, `<Space>dB` | `lua/plugins/diffview.lua`, `lua/mylib/diff_base.lua`, `lua/plugins/gitsigns.lua` |
| NVB-07–09 | `<Space>uT`, `:ContextAlwaysToggle`, `<Space>ut`, `gk`, `:ContextUp` | `lua/plugins/treesitter.lua`, `lua/mylib/context_breadcrumbs.lua` |

## Changing an implementation

1. Read the affected stories before changing a plugin, command, mapping, or custom module.
2. Preserve the acceptance criteria and user-facing bindings when replacing an implementation. If the intended behavior changes, update the story and explain the migration in the same commit.
3. Verify the affected scenarios in a real `nvb` session or a focused headless check. For Git review, use a temporary repository with a baseline commit and a later change. For context, check a short nested file whose defining lines remain visible and a split window.
4. Update the implementation table when files or libraries move. Add a new story for each new custom workflow.

For a new workflow, copy this shape:

```markdown
### NVB-XX — User-visible outcome

**Story:** As a [user], I can [action] so that [benefit].

**Acceptance criteria**

- Given [starting state], when [action], then [observable result].
- When [missing input or unsupported context], the editor [clear fallback].
```
