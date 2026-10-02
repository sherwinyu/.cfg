# Usage: gwt [-f] [-b] <pr-number|pr-url|branch> | gwt [-f] -l <issue-number|ABC-123>
#        gwt -c|--clone [new-branch] [source-worktree]
#        gwt check-status [pr-number|pr-url|branch]
# Examples:
#   gwt 123                                          (PR # — resolves against the repo in the current cwd)
#   gwt https://github.com/owner/repo/pull/123       (PR URL — cd to ~/projects/repo first, then resolve)
#   gwt feature/foo                                  (branch in the current cwd)
#   gwt -f 123                                        (force: blow away existing dir)
#   gwt -b new-branch-name                            (create a new local branch off HEAD, no push)
#   gwt --clone                                      (auto-name: current-branch__1, __2, ...)
#   gwt --clone agent-b                               (duplicate current worktree's committed HEAD)
#   gwt -c agent-c ../repo-wt-agent-b                  (duplicate another worktree's committed HEAD)
#   gwt -l 120                                        (find a Linear issue by number)
#   gwt -l SHE-120                                    (find a Linear issue by identifier)
#   gwt check-status                                 (live remote branch/PR status, no checkout)
#   gwt check-status 123                              (status of a specific PR)
# With -f (no -b): also creates a new branch off main if the branch doesn't exist on remote
# Linear lookup uses linear-cli's browser OAuth login and fzf for multiple matches.
# Clone creates a fresh branch/folder without fetching or pushing. Only committed
# code plus the local-only setup below is copied; other untracked/dirty files are excluded.
# Automatic names skip existing branches/folders. Cloning a numbered clone continues
# its original branch's series. Detached HEAD requires an explicit new branch name.

# Local-only env/config files copied from the source into each new worktree
# (space-separated globs, relative to the repo root). Override in your shell to
# add/remove entries, e.g. export GWT_COPY_GLOBS=".env .env.* .envrc .tool-versions"
: ${GWT_COPY_GLOBS:=".env .env.* .envrc"}

_gwt_usage() {
  echo 'Usage: gwt [-f] [-b] <pr-number|pr-url|branch> | gwt [-f] -l <issue-number|ABC-123>'
  echo '       gwt -c|--clone [new-branch] [source-worktree]'
  echo '       Omit new-branch for source-branch__1, __2, ... (next available name)'
  echo '       gwt check-status [pr-number|pr-url|branch] (defaults to current branch)'
}

_gwt_check_status() {
  local target="$1" branch local_branch repo remote_repo remote remote_url merge_ref
  local prs pr query remote_oid result=0
  local fields='number,title,state,isDraft,url,headRefName,baseRefName,mergedAt,closedAt,headRepository,headRepositoryOwner'
  command -v gh >/dev/null 2>&1 || { echo 'gwt check-status requires gh' >&2; return 1; }
  command -v jq >/dev/null 2>&1 || { echo 'gwt check-status requires jq' >&2; return 1; }

  if [[ "$target" =~ '^https?://github\.com/[^/]+/[^/]+/pull/[0-9]+([/?#].*)?$' || "$target" =~ '^[0-9]+$' ]]; then
    pr=$(gh pr view "$target" --json "$fields") || return 1
    prs=$(print -r -- "$pr" | jq -c '[.]') || return 1
    branch=$(print -r -- "$pr" | jq -r '.headRefName') || return 1
    repo=$(print -r -- "$pr" | jq -r '.url | split("/") | .[3:5] | join("/")') || return 1
    remote_repo=$(print -r -- "$pr" | jq -r 'if .headRepository and .headRepositoryOwner then .headRepositoryOwner.login + "/" + .headRepository.name else empty end') || return 1
  else
    git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not in a git repository: $PWD" >&2; return 1; }
    branch="$target"
    if [[ -z "$branch" ]]; then
      branch=$(git symbolic-ref --quiet --short HEAD) || {
        echo 'Detached HEAD; supply a branch name, PR number, or PR URL' >&2
        return 1
      }
    fi
    git check-ref-format "refs/heads/$branch" >/dev/null 2>&1 || {
      echo "Invalid branch name: $branch" >&2
      return 1
    }
    local_branch="$branch"
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner) || return 1
    remote_repo="$repo"
    remote=$(git config --get "branch.$local_branch.remote") || remote=''
    merge_ref=$(git config --get "branch.$local_branch.merge") || merge_ref=''
    if [[ -n "$remote" && "$remote" != . && "$merge_ref" == refs/heads/* ]]; then
      branch="${merge_ref#refs/heads/}"
    else
      remote=origin
    fi
    if remote_url=$(git remote get-url "$remote" 2>/dev/null); then
      remote_repo=$(gh repo view "$remote_url" --json nameWithOwner -q .nameWithOwner) || return 1
    fi
    # Include merged/closed PRs, and distinguish identical branch names in forks.
    prs=$(gh pr list --repo "$repo" --head "$branch" --state all --limit 100 --json "$fields") || return 1
    prs=$(print -r -- "$prs" | jq -c --arg repo "$remote_repo" --arg branch "$branch" '
      [.[] | select(.headRefName == $branch and
        (.headRepositoryOwner.login + "/" + .headRepository.name) == $repo)]') || return 1
  fi

  print -r -- "Repository: $repo"
  [[ -z "$local_branch" || "$local_branch" == "$branch" ]] || print -r -- "Local branch: $local_branch"
  print -r -- "Branch: $branch"
  if [[ -n "$remote_repo" ]]; then
    query='query($owner: String!, $name: String!, $ref: String!) { repository(owner: $owner, name: $name) { ref(qualifiedName: $ref) { target { oid } } } }'
    if remote_oid=$(gh api graphql -f query="$query" -f owner="${remote_repo%%/*}" -f name="${remote_repo#*/}" -f ref="refs/heads/$branch" --jq '.data.repository.ref.target.oid // empty'); then
      if [[ -n "$remote_oid" ]]; then
        print -r -- "Remote branch: exists ($remote_repo at ${remote_oid[1,12]})"
      else
        print -r -- "Remote branch: absent ($remote_repo; deleted or never pushed)"
      fi
    else
      print -r -- 'Remote branch: unknown (GitHub query failed)'
      result=1
    fi
  else
    print -r -- 'Remote branch: unavailable (PR source repository was deleted)'
  fi
  if [[ "$(print -r -- "$prs" | jq 'length')" == 0 ]]; then
    print -r -- 'PR: none found for this branch (open, closed, or merged)'
  else
    print -r -- "$prs" | jq -r 'sort_by(.number) | reverse | .[] |
      "PR #\(.number): \(.state)\(if .state == "OPEN" and .isDraft then " (draft)" else "" end) → \(.baseRefName)\(if .mergedAt then " (merged " + .mergedAt + ")" elif .closedAt then " (closed " + .closedAt + ")" else "" end)\n  \(.title)\n  \(.url)"' || return 1
    (( $(print -r -- "$prs" | jq 'length') < 100 )) || print -r -- 'Showing up to 100 matching PRs; use a PR number to check a specific one.'
  fi
  return "$result"
}

_gwt_setup() {
  local src_dir="$1" worktree_dir="$2" clone="${3:-0}" pat f relative_file
  # Tracked files come from the commit, even if the source has local edits.
  if [[ -d "$src_dir/.claude" ]]; then
    while IFS= read -r -d '' relative_file; do
      [[ ! -e "$worktree_dir/$relative_file" && ! -L "$worktree_dir/$relative_file" ]] || continue
      mkdir -p "$worktree_dir/${relative_file:h}" || return 1
      cp -p "$src_dir/$relative_file" "$worktree_dir/$relative_file" || return 1
    done < <(git -C "$src_dir" ls-files --others -z -- .claude/)
  fi
  for pat in ${(s: :)GWT_COPY_GLOBS}; do
    for f in "$src_dir"/${~pat}(N); do
      [[ -f "$f" ]] || continue
      relative_file="${f#$src_dir/}"
      git -C "$src_dir" ls-files --error-unmatch -- "$relative_file" >/dev/null 2>&1 && continue
      [[ ! -e "$worktree_dir/${f:t}" && ! -L "$worktree_dir/${f:t}" ]] || continue
      cp -p "$f" "$worktree_dir/${f:t}" || return 1
      echo "Copied ${f:t}"
    done
  done
  if [[ -f "$worktree_dir/.envrc" ]] && command -v direnv >/dev/null 2>&1; then
    (cd "$worktree_dir" && direnv allow) && echo "direnv allowed in worktree"
  fi

  cd "$worktree_dir" || return 1
  if [[ -f package.json ]] && command -v bun >/dev/null 2>&1; then
    if (( clone )); then
      bun install --frozen-lockfile || return 1
    else
      bun install || return 1
    fi
  fi
  echo "Worktree ready at $worktree_dir"
}

_gwt_clone() {
  local branch="$1" source_dir="${2:-.}" src_dir commit repo_root worktree_dir
  local source_branch suffix=1
  src_dir=$(git -C "$source_dir" rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not a worktree directory: $source_dir" >&2
    return 1
  }
  commit=$(git -C "$src_dir" rev-parse --verify 'HEAD^{commit}') || return 1
  repo_root=$(git -C "$src_dir" rev-parse --path-format=absolute --git-common-dir) || return 1
  repo_root="${repo_root%/.git}"
  if [[ -z "$branch" ]]; then
    source_branch=$(git -C "$src_dir" symbolic-ref --quiet --short HEAD) || {
      echo 'Source has detached HEAD; supply a new branch name: gwt --clone <new-branch>' >&2
      return 1
    }
    if [[ "$source_branch" =~ '^(.+)__[0-9]+$' ]]; then
      source_branch="${match[1]}"
    fi
    while true; do
      branch="${source_branch}__${suffix}"
      worktree_dir="${src_dir:h}/${repo_root:t}-wt-${branch//\//-}"
      if ! git -C "$src_dir" show-ref --verify --quiet "refs/heads/$branch" &&
          [[ ! -e "$worktree_dir" && ! -L "$worktree_dir" ]]; then
        break
      fi
      (( suffix += 1 ))
    done
  fi
  git check-ref-format --branch "$branch" >/dev/null 2>&1 &&
    git check-ref-format "refs/heads/$branch" >/dev/null 2>&1 || {
    echo "Invalid new branch name: $branch" >&2
    return 1
  }
  worktree_dir="${src_dir:h}/${repo_root:t}-wt-${branch//\//-}"

  if git -C "$src_dir" show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Clone needs a new branch; '$branch' already exists" >&2
    return 1
  fi
  if [[ -e "$worktree_dir" || -L "$worktree_dir" ]]; then
    echo "Clone destination already exists: $worktree_dir" >&2
    return 1
  fi
  git -C "$src_dir" worktree add -b "$branch" "$worktree_dir" "$commit" || return 1
  echo "Cloned committed state of $src_dir at ${commit[1,12]} onto '$branch' (not pushed)"
  _gwt_setup "$src_dir" "$worktree_dir" 1
}

_gwt_linear_api() {
  local query="$1" response error
  response=$(linear-cli api query --output json --compact --no-pager "$query" 2>&1) || {
    error=$(print -r -- "$response" | jq -r '.message // empty' 2>/dev/null)
    if [[ "$error" == *'No workspace selected'* ]]; then
      error='Not signed in. Run: linear-cli auth oauth --secure --scopes read'
    fi
    echo "Linear CLI error: ${error:-${response:-query failed}}" >&2
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
  local attachments='[]' pr_list pr_count choice branch

  if ! command -v linear-cli >/dev/null 2>&1; then
    echo "gwt -l requires linear-cli: https://github.com/nesszer/linear-cli/releases" >&2
    echo "After installing, sign in: linear-cli auth oauth --secure --scopes read" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "gwt -l requires jq" >&2
    return 1
  fi

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
  local force=0 new_branch=0 clone=0 check_status=0 linear_issue=''
  while [[ "$1" == -* ]]; do
    case "$1" in
      -f) force=1 ;;
      -b) new_branch=1 ;;
      -c|--clone) clone=1 ;;
      --check-status) check_status=1 ;;
      -h|--help) _gwt_usage; return 0 ;;
      -l)
        shift
        [[ -n "$1" && "$1" != -* ]] || { echo "Usage: gwt [-f] -l <issue-number|ABC-123>"; return 1; }
        linear_issue="$1" ;;
      *) echo "Unknown flag: $1"; return 1 ;;
    esac
    shift
  done

  local input="$1"
  if [[ "$input" == check-status ]] && (( ! new_branch && ! clone )) && [[ -z "$linear_issue" ]]; then
    check_status=1
    shift
    input="$1"
  fi
  if (( check_status )); then
    if (( force || new_branch || clone )) || [[ -n "$linear_issue" || $# -gt 1 ]]; then
      echo 'Use check-status [pr-number|pr-url|branch]; it cannot be combined with -f, -b, --clone, or -l' >&2
      return 1
    fi
    _gwt_check_status "$input"
    return $?
  fi
  if (( clone )); then
    if (( force || new_branch )) || [[ -n "$linear_issue" || $# -gt 2 ]]; then
      echo 'Use --clone [new-branch] [source-worktree]; it cannot be combined with -f, -b, or -l' >&2
      return 1
    fi
    _gwt_clone "$input" "${2:-.}"
    return $?
  fi
  if [[ -n "$linear_issue" ]]; then
    if (( new_branch )) || [[ -n "$input" ]]; then
      echo "Use -l with an issue only; it cannot be combined with -b or another target"
      return 1
    fi
    input=$(_gwt_linear_target "$linear_issue") || return 1
  fi
  if [[ -z "$input" ]]; then
    _gwt_usage
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

  local src_dir=$(git rev-parse --show-toplevel) || return 1

  # Base the new worktree's name on the *main* repo, not the cwd — if we're
  # already inside a worktree, basename "$src_dir" would stack another
  # "-wt-<branch>" suffix onto the existing one.
  local repo_root=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  repo_root="${repo_root%/.git}"
  local repo_name="$(basename "$repo_root")"
  local worktree_dir="${src_dir:h}/${repo_name}-wt-${branch//\//-}"

  # The branch may already be checked out as a worktree somewhere other than
  # the conventional path below (different naming, moved, etc) — find it by
  # branch rather than by directory so we don't collide with git.
  local existing_dir=$(git worktree list --porcelain | awk -v ref="refs/heads/$branch" '
    /^worktree / { dir=substr($0, 10) }
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

  _gwt_setup "$src_dir" "$worktree_dir"
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
