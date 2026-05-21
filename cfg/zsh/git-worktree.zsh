# Usage: gwt [-f] <pr-number-or-branch>
# Examples: gwt 123, gwt feature/foo, gwt -f 123 (force: blow away existing dir)
# With -f: also creates a new branch off main if the branch doesn't exist on remote

gwt() {
  local force=0
  if [[ "$1" == "-f" ]]; then
    force=1
    shift
  fi

  local input="$1"
  if [[ -z "$input" ]]; then
    echo "Usage: gwt [-f] <pr-number|branch>"
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

  local src_dir="$(pwd)"
  local worktree_dir="../$(basename "$src_dir")-wt-${branch//\//-}"

  if [ -d "$worktree_dir" ]; then
    if (( force )); then
      echo "Force: removing existing worktree at $worktree_dir"
      git worktree remove "$worktree_dir" --force 2>/dev/null
      rm -rf "$worktree_dir"
    elif git -C "$worktree_dir" rev-parse --git-dir 2>/dev/null | grep -q "/.git/worktrees/"; then
      cd "$worktree_dir" && echo "Worktree already exists at $worktree_dir"
      return 0
    else
      echo "Directory exists but is not a worktree: $worktree_dir (use -f to force)"
      return 1
    fi
  fi

  if git fetch origin "$branch" 2>/dev/null; then
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$worktree_dir" "$branch" || return 1
    else
      git worktree add -b "$branch" "$worktree_dir" "origin/$branch" || return 1
    fi
  elif (( force )); then
    git fetch origin main || return 1
    git worktree add -b "$branch" "$worktree_dir" "origin/main" || return 1
    git -C "$worktree_dir" push -u origin "$branch" || return 1
    echo "Created new branch '$branch' off main and pushed to remote"
  else
    echo "Branch '$branch' not found on remote (use -f to create off main)"
    return 1
  fi

  # Copy local-only (untracked/ignored) .claude files; tracked ones come from the checkout
  if [ -d "$src_dir/.claude" ]; then
    git -C "$src_dir" ls-files --others -- .claude/ | while IFS= read -r f; do
      mkdir -p "$worktree_dir/${f:h}"
      cp "$src_dir/$f" "$worktree_dir/$f"
    done
  fi
  for f in "$src_dir"/.env*(N); do
    cp "$f" "$worktree_dir/"
  done

  cd "$worktree_dir" || return 1
  bun install
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
