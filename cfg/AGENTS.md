# Codex Configuration Work

This document captures the established patterns for working with dotfiles and configuration files using Codex.

## Environment Setup

This is a bare git repository for dotfiles management using the pattern:
- Bare repo: `~/.cfg/`
- Work tree: `~` (home directory)
- Alias: `config` (already available) = `git --git-dir=/Users/sherwin/.cfg/ --work-tree=/Users/sherwin`

## Pre-approved Tool Permissions

When working on configuration files, Codex has permission to use these tools without asking:

```bash
# Read any config files
Read(//Users/sherwin/.config/**)
Read(//Users/sherwin/cfg/**)

# Check WezTerm configuration
Bash(WEZTERM_CONFIG_FILE="/Users/sherwin/cfg/wezterm/wezterm.lua" wezterm show-config)

# Fetch WezTerm documentation
WebFetch(domain:wezterm.org)

# Create symlinks (common pattern for dotfiles)
Bash(ln:*)

# Notification system
Bash(/Users/sherwin/cfg/Codex/notify.sh)
```

## Notification System

**IMPORTANT**: Codex must use the notification system to alert when human input is required or when completing significant tasks.

Always trigger notifications in these scenarios:
- When waiting for human input or confirmation
- When completing long-running tasks (>5 seconds)
- When encountering errors that require human attention
- When reaching a natural stopping point where user attention is needed
- Before asking questions that require user decision-making

**Usage**: Run `/Users/sherwin/cfg/Codex/notify.sh "message"` via the Bash tool.

**Examples**:
- `/Users/sherwin/cfg/Codex/notify.sh "Task completed - please review"`
- `/Users/sherwin/cfg/Codex/notify.sh "Human input required"`
- `/Users/sherwin/cfg/Codex/notify.sh "Error encountered - user attention needed"`

## Directory Structure Patterns

```
~/cfg/                          # Dotfiles repo
├── wezterm/                   # WezTerm config (top-level, no .config nesting)
├── nvim/                      # Neovim config
├── karabiner-config/          # Karabiner config
├── hammerspoon/               # Hammerspoon config
├── zsh/                       # Zsh config
└── AGENTS.md                  # This file
```

Symlinks:
```
~/.config/wezterm → ~/cfg/wezterm
# Other symlinks as needed
```

## WezTerm Workspace Setup

The `cfg` workspace is automatically created with:
- **Main tab**: ~/cfg with `config status` and `Codex session list`
- **Wez tab**: ~/cfg/wezterm
- **nvimc tab**: ~/cfg/nvim
- **karabiner tab**: ~/cfg/karabiner-config
- **hammerspoon tab**: ~/cfg/hammerspoon

Access: `Cmd+Shift+C` or through launcher (`Cmd+K`)

## Git Workflow

Use `config` command (pre-aliased) instead of `git`:
```bash
config status
config add <file>
config commit -m "message"
# No need to alias - already available
```

## Key Principles

1. **Avoid nested .config directories** - use top-level names (e.g., `cfg/wezterm/` not `cfg/.config/wezterm/`)
2. **Symlinks for system integration** - link from standard locations to repo
3. **Workspace-driven workflow** - dedicated workspace for config editing
4. **Automatic command execution** - workspaces run status commands automatically
5. **Commit with context** - include purpose and scope in commit messages

## Common Tasks

- **Setup new config**: Create directory, write config, create symlink, test, commit
- **Update existing config**: Edit in workspace, test functionality, commit changes
- **WezTerm changes**: Always update workspace function if paths change
- **Testing**: Use tool-specific commands to validate before committing
- **`nvb` feature changes**: Follow the feature documentation workflow below.

## `nvb` Feature Documentation

`nvim-configs/scratch/FEATURES.md` is the user-facing behavior contract for the scratch Neovim profile (`nvb`). Read the affected stories before changing a custom workflow.

- For each new custom workflow, add a user story with observable acceptance criteria and record its commands, bindings, and implementation in the table.
- When behavior or bindings change, update the affected stories and implementation table in the same commit as the code.
- When replacing a plugin or Lua module, preserve the documented workflow and acceptance criteria unless the behavior change is intentional and documented.
- Verify the affected acceptance criteria with a focused headless check or in a real `nvb` session before committing.

This setup enables efficient, keyboard-driven configuration management with automatic workspace setup and proper git integration.
