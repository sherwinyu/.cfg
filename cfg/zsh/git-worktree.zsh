# Usage: gwt [-f] [-b] <pr-number|pr-url|branch> | gwt [-f] -l <issue-number|ABC-123>
# Examples:
#   gwt 123                                          (PR # — resolves against the repo in the current cwd)
#   gwt https://github.com/owner/repo/pull/123       (PR URL — cd to ~/projects/repo first, then resolve)
#   gwt feature/foo                                  (branch in the current cwd)
#   gwt -f 123                                        (force: blow away existing dir)
#   gwt -b new-branch-name                            (create a new local branch off HEAD, no push)
#   gwt -l 120                                        (find a Linear issue by number)
#   gwt -l SHE-120                                    (find a Linear issue by identifier)
# With -f (no -b): also creates a new branch off main if the branch doesn't exist on remote
# Linear lookup requires LINEAR_API_KEY and uses fzf when there are multiple matches.

# Local-only env/config files copied from the main repo into each new worktree
# (space-separated globs, relative to the repo root). Override in your shell to
# add/remove entries, e.g. export GWT_COPY_GLOBS=".env .env.* .envrc .tool-versions"
: ${GWT_COPY_GLOBS:=".env .env.* .envrc"}

_gwt_linear_api() {
  local query="$1" response error
  response=$(jq -nc --arg query "$query" '{query: $query}' |
    curl --silent --show-error --fail -X POST \
      -H 'Content-Type: application/json' \
      -H "Authorization: $LINEAR_API_KEY" \
      --data-binary @- https://api.linear.app/graphql) || {
    echo "Linear API request failed" >&2
    return 1
  }
  error=$(print -r -- "$response" | jq -r '.errors[0].message // empty') || return 1
  if [[ -n "$error" ]]; then
    echo "Linear API error: $error" >&2
    return 1
  fi
  print -r -- "$response"
}

_gwt_linear_target() {
  local issue="${(U)1}" identifier response query cursor after issue_list='[]'
  local attachments='[]' pr_list pr_count choice branch dependency

  if [[ -z "${LINEAR_API_KEY:-}" ]]; then
    echo "Set LINEAR_API_KEY to use gwt -l" >&2
    return 1
  fi
  for dependency in jq curl; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      echo "gwt -l requires $dependency" >&2
      return 1
    fi
  done

  if [[ "$issue" =~ '^[A-Z]{3}-[0-9]+$' ]]; then
    identifier="$issue"
  elif [[ "$issue" =~ '^[0-9]+$' ]]; then
    issue="$((10#$issue))"
    cursor=''
    while true; do
      after=''
      [[ -n "$cursor" ]] && after=", after: $(jq -Rn --arg value "$cursor" '$value')"
      query="query { issues(first: 100, includeArchived: true, filter: { number: { eq: $issue } }$after) { nodes { identifier title } pageInfo { hasNextPage endCursor } } }"
      response=$(_gwt_linear_api "$query") || return 1
      issue_list=$(print -r -- "$response" | jq -c --argjson previous "$issue_list" '$previous + (.data.issues.nodes // [])') || return 1
      if [[ "$(print -r -- "$response" | jq -r '.data.issues.pageInfo.hasNextPage')" != true ]]; then
        break
      fi
      cursor=$(print -r -- "$response" | jq -r '.data.issues.pageInfo.endCursor // empty')
      [[ -n "$cursor" ]] || { echo "Linear returned an incomplete issue page" >&2; return 1; }
    done
    local issue_count=$(print -r -- "$issue_list" | jq 'length')
    if (( issue_count == 0 )); then
      echo "No Linear issue found for number $issue" >&2
      return 1
    elif (( issue_count == 1 )); then
      identifier=$(print -r -- "$issue_list" | jq -r '.[0].identifier')
    else
      command -v fzf >/dev/null 2>&1 || { echo "Multiple Linear issues found; install fzf to choose one" >&2; return 1; }
      choice=$(print -r -- "$issue_list" | jq -r '.[] | [.identifier, (.title | gsub("[\\t\\r\\n]"; " "))] | @tsv' |
        fzf --prompt='Linear issue> ' --height=40% --reverse --delimiter=$'\t') || return 1
      identifier="${choice%%$'\t'*}"
    fi
  else
    echo "Expected a Linear issue number or three-letter identifier (e.g. SHE-120): $issue" >&2
    return 1
  fi

  cursor=''
  while true; do
    after=''
    [[ -n "$cursor" ]] && after=", after: $(jq -Rn --arg value "$cursor" '$value')"
    query="query { issue(id: \"$identifier\") { identifier title branchName attachments(first: 100$after) { nodes { url title } pageInfo { hasNextPage endCursor } } } }"
    response=$(_gwt_linear_api "$query") || return 1
    if [[ "$(print -r -- "$response" | jq -r '.data.issue.identifier // empty')" != "$identifier" ]]; then
      echo "Linear issue not found: $identifier" >&2
      return 1
    fi
    attachments=$(print -r -- "$response" | jq -c --argjson previous "$attachments" '$previous + (.data.issue.attachments.nodes // [])') || return 1
    if [[ "$(print -r -- "$response" | jq -r '.data.issue.attachments.pageInfo.hasNextPage')" != true ]]; then
      break
    fi
    cursor=$(print -r -- "$response" | jq -r '.data.issue.attachments.pageInfo.endCursor // empty')
    [[ -n "$cursor" ]] || { echo "Linear returned an incomplete attachment page" >&2; return 1; }
  done

  pr_list=$(print -r -- "$attachments" | jq -c '[.[] | select(.url | test("^https://github\\.com/[^/]+/[^/]+/pull/[0-9]+($|[/?#])"; "i"))] | unique_by(.url)') || return 1
  pr_count=$(print -r -- "$pr_list" | jq 'length')
  if (( pr_count == 1 )); then
    choice=$(print -r -- "$pr_list" | jq -r '.[0].url')
  elif (( pr_count > 1 )); then
    command -v fzf >/dev/null 2>&1 || { echo "Multiple Linear PRs found; install fzf to choose one" >&2; return 1; }
    choice=$(print -r -- "$pr_list" | jq -r '.[] | [.url, ((.title // "") | gsub("[\\t\\r\\n]"; " "))] | @tsv' |
      fzf --prompt="PR for $identifier> " --height=40% --reverse --delimiter=$'\t' --with-nth=2,1) || return 1
    choice="${choice%%$'\t'*}"
  else
    branch=$(print -r -- "$response" | jq -r '.data.issue.branchName // empty') || return 1
    if [[ -z "$branch" ]]; then
      echo "Linear issue $identifier has no linked GitHub PR or branch name" >&2
      return 1
    fi
    choice="$branch"
  fi
  echo "Linear $identifier → $choice" >&2
  print -r -- "$choice"
}

gwt() {
  local force=0 new_branch=0 linear_issue=''
  while [[ "$1" == -* ]]; do
    case "$1" in
      -f) force=1 ;;
      -b) new_branch=1 ;;
      -l)
        shift
        [[ -n "$1" && "$1" != -* ]] || { echo "Usage: gwt [-f] -l <issue-number|ABC-123>"; return 1; }
        linear_issue="$1" ;;
      *) echo "Unknown flag: $1"; return 1 ;;
    esac
    shift
  done

  local input="$1"
  if [[ -n "$linear_issue" ]]; then
    if (( new_branch )) || [[ -n "$input" ]]; then
      echo "Use -l with an issue only; it cannot be combined with -b or another target"
      return 1
    fi
    input=$(_gwt_linear_target "$linear_issue") || return 1
  fi
  if [[ -z "$input" ]]; then
    echo "Usage: gwt [-f] [-b] <pr-number|pr-url|branch> | gwt [-f] -l <issue-number|ABC-123>"
    return 1
  fi

  local branch
  if (( new_branch )); then
    # -b: treat input as a brand-new local branch name off current HEAD —
    # no PR/URL resolution, no fetch, no push.
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      echo "Not in a git repository: $(pwd)"
      return 1
    fi
    branch="$input"
  elif [[ "$input" =~ '^https?://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)' ]]; then
    # It's a PR URL — ignore cwd, switch to the main repo dir under ~/projects
    local pr_repo="${match[1]}/${match[2]}"
    local pr_num="${match[3]}"
    local repo_dir="$HOME/projects/${match[2]}"
    if [[ ! -d "$repo_dir" ]]; then
      echo "Repo directory not found: $repo_dir"
      return 1
    fi
    cd "$repo_dir" || return 1
    branch=$(gh pr view "$pr_num" --repo "$pr_repo" --json headRefName -q .headRefName) || return 1
    echo "PR #$pr_num ($pr_repo) → branch: $branch"
  else
    # PR number or branch — both resolve against the repo in the current cwd
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      echo "Not in a git repository: $(pwd)"
      echo "cd into a repo, or pass a full PR URL (https://github.com/owner/repo/pull/N)"
      return 1
    fi
    if [[ "$input" =~ ^[0-9]+$ ]]; then
      # It's a PR number — resolve the branch name
      branch=$(gh pr view "$input" --json headRefName -q .headRefName) || return 1
      echo "PR #$input → branch: $branch"
    else
      branch="$input"
    fi
  fi

  local src_dir="$(pwd)"

  # Base the new worktree's name on the *main* repo, not the cwd — if we're
  # already inside a worktree, basename "$src_dir" would stack another
  # "-wt-<branch>" suffix onto the existing one.
  local repo_root=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  repo_root="${repo_root%/.git}"
  local repo_name="$(basename "$repo_root")"
  local worktree_dir="../${repo_name}-wt-${branch//\//-}"

  # The branch may already be checked out as a worktree somewhere other than
  # the conventional path below (different naming, moved, etc) — find it by
  # branch rather than by directory so we don't collide with git.
  local existing_dir=$(git worktree list --porcelain | awk -v ref="refs/heads/$branch" '
    /^worktree / { dir=$2 }
    /^branch / && $2 == ref { print dir; exit }
  ')

  if [[ -n "$existing_dir" ]]; then
    if (( force )); then
      echo "Force: removing existing worktree at $existing_dir"
      git worktree remove "$existing_dir" --force 2>/dev/null
      command rm -rf "$existing_dir"
    else
      cd "$existing_dir" && echo "Worktree already exists at $existing_dir"
      return 0
    fi
  elif [ -d "$worktree_dir" ]; then
    if (( force )); then
      echo "Force: removing existing directory at $worktree_dir"
      git worktree remove "$worktree_dir" --force 2>/dev/null
      command rm -rf "$worktree_dir"
    else
      echo "Directory exists but is not a worktree for '$branch': $worktree_dir (use -f to force)"
      return 1
    fi
  fi

  if (( new_branch )); then
    git worktree add -b "$branch" "$worktree_dir" HEAD || return 1
    echo "Created new local branch '$branch' off HEAD (not pushed)"
  elif git fetch origin "$branch" 2>/dev/null; then
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
  # Copy local-only env/config files (see GWT_COPY_GLOBS above)
  local pat f
  for pat in ${(s: :)GWT_COPY_GLOBS}; do
    for f in "$src_dir"/${~pat}(N); do
      cp -p "$f" "$worktree_dir/${f:t}"
      echo "Copied ${f:t}"
    done
  done
  # direnv blocks a freshly-copied .envrc until it's allowed
  if [[ -f "$worktree_dir/.envrc" ]] && command -v direnv >/dev/null 2>&1; then
    (cd "$worktree_dir" && direnv allow) && echo "direnv allowed in worktree"
  fi

  cd "$worktree_dir" || return 1
  if command -v bun >/dev/null 2>&1; then
    bun install
  fi
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
