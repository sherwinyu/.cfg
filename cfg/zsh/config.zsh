# Aliases for managing dotfiles / config

# Set up config alias
alias -g CFG="GIT_DIR=~/.cfg GIT_WORK_TREE=~"
alias config="git --git-dir=$HOME/.cfg --work-tree=$HOME"
