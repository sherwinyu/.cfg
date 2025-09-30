# Tig integration for dotfiles config
# Creates 'ctig' alias to use tig with bare git repo

alias ctig='GIT_DIR=/Users/sherwin/.cfg GIT_WORK_TREE=/Users/sherwin tig'

# Function to auto-detect and use appropriate tig command
function smart_tig() {
    if [[ "$PWD" == "/Users/sherwin/cfg" || "$PWD" == "/Users/sherwin/cfg/"* ]]; then
        echo "Using tig with config setup..."
        GIT_DIR=/Users/sherwin/.cfg GIT_WORK_TREE=/Users/sherwin tig "$@"
    else
        tig "$@"
    fi
}

# Optional: uncomment to make 'tig' smart by default
# alias tig='smart_tig'