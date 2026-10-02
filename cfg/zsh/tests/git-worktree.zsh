#!/bin/zsh -f
# Run: zsh -f ~/cfg/zsh/tests/git-worktree.zsh
set -e
source "${0:A:h:h}/git-worktree.zsh"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/gwt-test.XXXXXX")
test_root=$(cd "$test_root" && pwd -P)
trap 'cd /; command rm -rf "$test_root"' EXIT
fail() { print -u2 -r -- "FAIL: $*"; exit 1; }
expect_failure() {
  if "$@" >"$test_root/failure.log" 2>&1; then
    fail "Unexpected success: $*"
  fi
}
# Exercise installation without contacting services or running project scripts.
bun() { print -r -- "$*" >> "$test_root/bun.log"; }
direnv() { print -r -- "$*" >> "$test_root/direnv.log"; }

repo="$test_root/repo with spaces"
source_wt="$test_root/custom source"
git init -q -b main "$repo"
git -C "$repo" config user.name 'GWT Test'
git -C "$repo" config user.email 'gwt@example.invalid'
git -C "$repo" config commit.gpgsign false
mkdir -p "$repo/.claude" "$repo/nested"
print -r -- baseline > "$repo/code.txt"
print -r -- committed > "$repo/.env.example"
print -r -- committed > "$repo/.claude/tracked.txt"
print -r -- '{"name":"gwt-fixture","private":true}' > "$repo/package.json"
print -r -- '.env.local' > "$repo/.gitignore"
git -C "$repo" add .
git -C "$repo" commit -qm baseline
git -C "$repo" worktree add -qb agents/source "$source_wt"
mkdir -p "$source_wt/nested"
print -r -- source-commit > "$source_wt/code.txt"
git -C "$source_wt" commit -qam source
source_commit=$(git -C "$source_wt" rev-parse HEAD)
print -r -- staged-edit > "$source_wt/code.txt"
git -C "$source_wt" add code.txt
print -r -- dirty-edit > "$source_wt/.env.example"
print -r -- dirty-edit > "$source_wt/.claude/tracked.txt"
print -r -- local-fixture > "$source_wt/.env.local"
chmod 600 "$source_wt/.env.local"
print -r -- local-fixture > "$source_wt/.claude/local file.txt"
print -r -- local-fixture > "$source_wt/.claude/"$'line\nbreak.txt'
print -r -- excluded > "$source_wt/untracked.txt"
source_status=$(git -C "$source_wt" status --porcelain)

# Current source, including invocation from a subdirectory of a linked worktree.
cd "$source_wt/nested"
gwt --clone agents/one
clone_one="$test_root/repo with spaces-wt-agents-one"
[[ "$PWD" == "$clone_one" ]] || fail 'Did not enter the new sibling worktree'
[[ "$(git rev-parse HEAD)" == "$source_commit" ]] || fail 'Wrong source commit'
[[ "$(git branch --show-current)" == agents/one ]] || fail 'Wrong destination branch'
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || fail 'Committed files were changed'
[[ "$(<code.txt)" == source-commit && "$(<.env.example)" == committed ]] || fail 'Copied dirty code/config'
[[ "$(<.claude/tracked.txt)" == committed ]] || fail 'Copied dirty tracked Claude file'
[[ -f .claude/local\ file.txt && -f .claude/$'line\nbreak.txt' ]] || fail 'Lost local Claude setup'
[[ -f .env.local && ! -f untracked.txt ]] || fail 'Wrong untracked file selection'
[[ "$(stat -f %Lp .env.local)" == 600 ]] || fail 'Lost private env permissions'
[[ "$(git -C "$source_wt" status --porcelain)" == "$source_status" ]] || fail 'Changed source state'
[[ "$(<"$test_root/bun.log")" == 'install --frozen-lockfile' ]] || fail 'Clone install may rewrite lockfile'

# Automatic names skip branch-only and folder-only collisions, then keep the
# same numbering series when invoked again from the newly entered clone.
git branch agents/source__1
mkdir "$test_root/repo with spaces-wt-agents-source__2"
cd "$source_wt/nested"
gwt --clone
[[ "$(git branch --show-current)" == agents/source__3 ]] || fail 'Did not skip occupied automatic names'
[[ "$(git rev-parse HEAD)" == "$source_commit" ]] || fail 'Automatic clone used the wrong commit'
gwt -c
[[ "$(git branch --show-current)" == agents/source__4 ]] || fail 'Repeated clone did not increment the suffix'
[[ "$(git rev-parse HEAD)" == "$source_commit" ]] || fail 'Repeated clone used the wrong commit'
[[ -d "$test_root/repo with spaces-wt-agents-source__2" ]] || fail 'Removed occupied folder'
[[ "$(git -C "$source_wt" status --porcelain)" == "$source_status" ]] || fail 'Automatic clone changed source state'

# Explicit source from outside a repository, and detached HEAD support.
git -C "$source_wt" checkout -q --detach
cd "$test_root"
gwt -c agents/two "$source_wt"
[[ "$(git rev-parse HEAD)" == "$source_commit" ]] || fail 'Explicit source used a different HEAD'
[[ "$(git branch --show-current)" == agents/two ]] || fail 'Detached source did not get a new branch'
[[ -z "$(git remote)" ]] || fail 'Fixture unexpectedly acquired a remote'

# Repeated names and flattened folder-name collisions must preserve existing work.
print -r -- keep > marker.txt
expect_failure gwt --clone agents/two "$source_wt"
[[ "$(<marker.txt)" == keep ]] || fail 'Overwrote existing worktree'
expect_failure gwt --clone agents-two "$source_wt"
git show-ref --verify --quiet refs/heads/agents-two && fail 'Created branch despite folder collision'
git branch reserved
expect_failure gwt --clone reserved "$source_wt"
expect_failure gwt --clone 'bad..branch' "$source_wt"
expect_failure gwt --clone invalid-source "$test_root"
expect_failure gwt --clone '' "$source_wt"
expect_failure gwt -f --clone destructive "$source_wt"
expect_failure gwt -b --clone ambiguous "$source_wt"
expect_failure gwt -l SHE-120 --clone ambiguous "$source_wt"
expect_failure gwt --clone extra "$source_wt" unexpected
[[ "$(<marker.txt)" == keep ]] || fail 'Invalid invocation changed destination'

# Existing branch-creation/reuse behavior still uses the shared setup.
cd "$source_wt"
gwt -b legacy
[[ "$(git rev-parse HEAD)" == "$source_commit" ]] || fail 'Existing -b behavior regressed'
cd "$repo"
gwt legacy
[[ "$PWD" == "$test_root/repo with spaces-wt-legacy" ]] || fail 'Existing worktree reuse regressed'
cd "$repo"
gwt --clone
[[ "$(git branch --show-current)" == main__1 ]] || fail 'First automatic clone did not start at __1'
[[ "$(git rev-parse HEAD)" == "$(git -C "$repo" rev-parse HEAD)" ]] || fail 'Default clone used another worktree commit'
gwt --clone
[[ "$(git branch --show-current)" == main__2 ]] || fail 'Second automatic clone did not use __2'
gwt --help > "$test_root/help.log"
print -r -- 'PASS: clone state, automatic numbering, setup, detached/explicit sources, collisions, and existing workflows'
