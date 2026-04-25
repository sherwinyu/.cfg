# Usage: gwt <pr-number-or-branch>
# Examples: gwt 123, gwt feature/foo

gwt() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "Usage: gwt <pr-number|branch>"
    return 1
  fi

  local branch
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    # It's a PR number — resolve the branch name
    branch=$(gh pr view "$input" --json headRefName -q .headRefName) || return 1
    echo "PR #$input → branch: $branch"
  else
    branch="$input"
  fi

  local worktree_dir="../$(basename "$(pwd)")-wt-${branch//\//-}"

  git fetch origin "$branch" && \
  git worktree add "$worktree_dir" "origin/$branch" && \
  cd "$worktree_dir" && \
  echo "Worktree ready at $worktree_dir"
}

# Usage: gwtc
# Removes the current worktree and its branch, then cd's back to the main repo

gwtc() {
  local wt_dir="$(pwd)"
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  if [[ -z "$branch" ]]; then
    echo "Not in a git repository"
    return 1
  fi

  # Check we're actually in a worktree
  local git_dir=$(git rev-parse --git-dir 2>/dev/null)
  if [[ "$git_dir" != *".git/worktrees/"* ]]; then
    echo "Not in a worktree"
    return 1
  fi

  # Get the main repo path
  local main_repo=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  main_repo="${main_repo%/.git}"

  cd "$main_repo" && \
  git worktree remove "$wt_dir" --force && \
  git branch -D "$branch" 2>/dev/null
  echo "Removed worktree and branch: $branch"
}
