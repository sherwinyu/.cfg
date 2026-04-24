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
