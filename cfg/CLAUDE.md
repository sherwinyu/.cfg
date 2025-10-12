# Claude Code Configuration Work

This document captures the established patterns for working with dotfiles and configuration files using Claude Code.

## Environment Setup

This is a bare git repository for dotfiles management using the pattern:
- Bare repo: `~/.cfg/`
- Work tree: `~` (home directory)
- Alias: `config` (already available) = `git --git-dir=/Users/sherwin/.cfg/ --work-tree=/Users/sherwin`

## Pre-approved Tool Permissions

When working on configuration files, Claude has permission to use these tools without asking:

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
Bash(/Users/sherwin/cfg/claude/notify.sh)
```

## Notification System

**IMPORTANT**: Claude must use the notification system to alert when human input is required or when completing significant tasks.

Always trigger notifications in these scenarios:
- When waiting for human input or confirmation
- When completing long-running tasks (>5 seconds)
- When encountering errors that require human attention
- When reaching a natural stopping point where user attention is needed
- Before asking questions that require user decision-making

**Usage**: Run `/Users/sherwin/cfg/claude/notify.sh "message"` via the Bash tool.

**Examples**:
- `/Users/sherwin/cfg/claude/notify.sh "Task completed - please review"`
- `/Users/sherwin/cfg/claude/notify.sh "Human input required"`
- `/Users/sherwin/cfg/claude/notify.sh "Error encountered - user attention needed"`

## Directory Structure Patterns

```
~/cfg/                          # Dotfiles repo
├── wezterm/                   # WezTerm config (top-level, no .config nesting)
├── nvim/                      # Neovim config
├── karabiner-config/          # Karabiner config
├── hammerspoon/               # Hammerspoon config
├── zsh/                       # Zsh config
└── CLAUDE.md                  # This file
```

Symlinks:
```
~/.config/wezterm → ~/cfg/wezterm
# Other symlinks as needed
```

## WezTerm Workspace Setup

The `cfg` workspace is automatically created with:
- **Main tab**: ~/cfg with `config status` and `claude session list`
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

This setup enables efficient, keyboard-driven configuration management with automatic workspace setup and proper git integration.