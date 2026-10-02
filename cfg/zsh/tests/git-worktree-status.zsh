#!/bin/zsh -f
# Run: zsh -f ~/cfg/zsh/tests/git-worktree-status.zsh
set -e
source "${0:A:h:h}/git-worktree.zsh"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/gwt-status-test.XXXXXX")
test_root=$(cd "$test_root" && pwd -P)
trap 'cd /; command rm -rf "$test_root"' EXIT
fail() { print -u2 -r -- "FAIL: $*"; exit 1; }
contains() { [[ "$output" == *"$1"* ]] || fail "Missing output: $1"; }
expect_failure() {
  if "$@" > "$test_root/failure.log" 2>&1; then
    fail "Unexpected success: $*"
  fi
}

repo="$test_root/repo with spaces"
git init -qb main "$repo"
git -C "$repo" config user.name 'GWT Test'
git -C "$repo" config user.email 'gwt@example.invalid'
git -C "$repo" config commit.gpgsign false
print -r -- committed > "$repo/file.txt"
git -C "$repo" add .
git -C "$repo" commit -qm baseline
git -C "$repo" switch -qc feature
git -C "$repo" remote add origin git@github.com:owner/fixture.git
cd "$repo"
print -r -- dirty > file.txt
before_status=$(git status --porcelain)
before_refs=$(git show-ref)

# GitHub responses are fixtures; no network access is needed for these checks.
fixture_mode=exists
fixture_prs='[
  {"number":1,"title":"Merged change","state":"MERGED","isDraft":false,"url":"https://github.com/owner/fixture/pull/1","headRefName":"feature","baseRefName":"main","mergedAt":"2026-10-01T00:00:00Z","closedAt":"2026-10-01T00:00:00Z","headRepository":{"name":"fixture"},"headRepositoryOwner":{"login":"owner"}},
  {"number":2,"title":"Closed change","state":"CLOSED","isDraft":false,"url":"https://github.com/owner/fixture/pull/2","headRefName":"feature","baseRefName":"main","mergedAt":null,"closedAt":"2026-10-01T01:00:00Z","headRepository":{"name":"fixture"},"headRepositoryOwner":{"login":"owner"}},
  {"number":3,"title":"Draft change","state":"OPEN","isDraft":true,"url":"https://github.com/owner/fixture/pull/3","headRefName":"feature","baseRefName":"main","mergedAt":null,"closedAt":null,"headRepository":{"name":"fixture"},"headRepositoryOwner":{"login":"owner"}},
  {"number":4,"title":"Unrelated fork","state":"MERGED","headRefName":"feature","headRepository":{"name":"fixture"},"headRepositoryOwner":{"login":"other"}}
]'
direct_pr=$(print -r -- "$fixture_prs" | jq -c '.[0]')
gh() {
  print -r -- "$*" >> "$test_root/gh.log"
  case "$1 $2" in
    'repo view')
      if [[ "$3" == git@github.com:fork/fixture.git ]]; then
        print -r -- fork/fixture
      else
        print -r -- owner/fixture
      fi ;;
    'pr list')
      [[ "$fixture_mode" != api-error ]] || { print -u2 'GitHub authentication failed'; return 1; }
      print -r -- "$fixture_prs" ;;
    'pr view') print -r -- "$direct_pr" ;;
    'api graphql')
      case "$fixture_mode" in
        query-error) print -u2 'Remote query failed'; return 1 ;;
        absent) return 0 ;;
        *) print -r -- 1234567890abcdef ;;
      esac ;;
    *) fail "Unexpected GitHub command: $*" ;;
  esac
}

gwt check-status > "$test_root/output.log"
output=$(<"$test_root/output.log")
contains 'Remote branch: exists'
contains 'PR #1: MERGED'
contains 'PR #2: CLOSED'
contains 'PR #3: OPEN (draft)'
contains 'merged 2026-10-01T00:00:00Z'
[[ "$output" != *'Unrelated fork'* ]] || fail 'Reported a PR from the wrong fork'
[[ "$(<"$test_root/gh.log")" == *'--state all'* ]] || fail 'Ignored closed/merged PRs'
[[ "$PWD" == "$repo" && "$(git status --porcelain)" == "$before_status" && "$(git show-ref)" == "$before_refs" ]] || fail 'Status changed repository state'

fixture_mode=absent
output=$(gwt --check-status feature)
contains 'Remote branch: absent'
contains 'PR #1: MERGED'
fixture_prs='[]'
output=$(gwt check-status unpublished__1)
contains 'PR: none found'
[[ "$output" != *MERGED* ]] || fail 'Inferred a merge from an absent branch'

# Tracking names can differ from local branch names and can use a fork remote.
git remote add fork git@github.com:fork/fixture.git
git config branch.feature.remote fork
git config branch.feature.merge refs/heads/remote-feature
fixture_mode=exists
output=$(gwt check-status)
contains 'Local branch: feature'
contains 'Branch: remote-feature'
contains 'Remote branch: exists (fork/fixture'
[[ "$(<"$test_root/gh.log")" == *'--head remote-feature'* && "$(<"$test_root/gh.log")" == *'ref=refs/heads/remote-feature'* ]] || fail 'Ignored configured tracking branch'

# PR numbers and URLs retain merged state even with no current worktree/branch.
output=$(gwt check-status 1)
contains 'PR #1: MERGED'
cd "$test_root"
output=$(gwt check-status https://github.com/owner/fixture/pull/1)
contains 'Repository: owner/fixture'
contains 'PR #1: MERGED'
expect_failure gwt check-status
cd "$repo"
git checkout -q --detach
expect_failure gwt check-status
output=$(gwt check-status feature)
contains 'Branch: remote-feature'

fixture_mode=query-error
expect_failure gwt check-status 1
output=$(<"$test_root/failure.log")
contains 'Remote branch: unknown'
contains 'PR #1: MERGED'
fixture_mode=api-error
expect_failure gwt check-status feature
[[ "$(<"$test_root/failure.log")" != *'none found'* ]] || fail 'Mistook authentication failure for no PR'
expect_failure gwt -f check-status
expect_failure gwt --check-status --clone
expect_failure gwt check-status feature extra
expect_failure gwt check-status bad..branch
print -r -- 'PASS: live-status formatting, merged/closed/draft PRs, absent branches, tracking/forks, read-only behavior, and errors'
