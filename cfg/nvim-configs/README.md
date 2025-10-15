# Neovim Configuration Profiles

Multi-profile system with a stable default config and experimental profiles for testing different approaches.

## Architecture

Uses Neovim's `NVIM_APPNAME` environment variable for profile switching:

```
NVIM_APPNAME=profile-name → ~/.config/profile-name/ → ~/cfg/nvim-configs/actual-config/
```

Each experimental profile gets isolated:
- Config directory: `~/.config/nvim-configs-{profile}/`
- Data directory: `~/.local/share/nvim-configs-{profile}/`
- Plugin installations and state

## Default Config

**Main config** (`nvim` command)
- **Status**: Stable daily driver
- **Location**: `~/cfg/nvim/`
- **Symlink**: `~/.config/nvim → ~/cfg/nvim/`

## Experimental Profiles

### LazyVim (`nva`)
- **Approach**: Experiment with LazyVim distribution
- **Philosophy**: Start with opinionated defaults, customize down
- **Location**: `~/cfg/nvim-configs/lazyvim/`

### Scratch (`nvb`)
- **Approach**: Experiment building from ground up with lazy.nvim
- **Philosophy**: Understand each component, minimal essential setup
- **Location**: `~/cfg/nvim-configs/scratch/`

## Aliases

```bash
# Default stable config
nvim                                                 # Uses ~/cfg/nvim/

# Experimental profiles
alias nva='NVIM_APPNAME=nvim-configs-lazyvim nvim'   # LazyVim distribution experiment
alias nvb='NVIM_APPNAME=nvim-configs-scratch nvim'   # Scratch-built experiment
alias cdnva='cd ~/cfg/nvim-configs/lazyvim'          # Change to LazyVim config dir
alias cdnvb='cd ~/cfg/nvim-configs/scratch'          # Change to scratch config dir
```

## Symlink Structure

```
~/.config/nvim → ~/cfg/nvim/                                   (default/stable)
~/.config/nvim-configs-lazyvim → ~/cfg/nvim-configs/lazyvim/   (experimental)
~/.config/nvim-configs-scratch → ~/cfg/nvim-configs/scratch/   (experimental)
```

Perfect for safely testing different configuration approaches while maintaining a stable default config.