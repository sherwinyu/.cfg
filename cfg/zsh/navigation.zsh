# makes cd pushd
setopt AUTO_PUSHD
cdpath=($HOME $HOME/projects $HOME/work $HOME, $HOME/Dropbox/writings)

# rr (repo root): cd to the top level of the current git repo
rr() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repository"
    return 1
  }
  cd "$root"
}
