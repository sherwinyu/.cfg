# ccq: ask Claude Code a one-off question (headless, read-only)
#
#   ccq what's going on with the deploy
#
# No quoting needed: the accept-line wrapper below quotes everything after
# `ccq ` before the shell parses the line, so apostrophes, ?, *, etc. are fine.

# Read anything; run only read-only commands. Anything else is denied (dontAsk).
CCQ_ALLOWED_TOOLS=(
  'Read(//**)' Glob Grep WebFetch WebSearch
  'Bash(ls:*)' 'Bash(pwd)'
  'Bash(git status:*)' 'Bash(git log:*)' 'Bash(git diff:*)' 'Bash(git show:*)'
  'Bash(git branch:*)' 'Bash(git blame:*)' 'Bash(git rev-parse:*)'
  'Bash(gh pr view:*)' 'Bash(gh pr list:*)' 'Bash(gh pr checks:*)'
  'Bash(gh run view:*)' 'Bash(gh run list:*)' 'Bash(gh issue view:*)'
  # Linear (read-only tools only), via the claude.ai connector or the plugin
  mcp__{claude_ai_Linear,plugin_productivity_linear}__{get_{issue,issue_status,project,milestone,team,user,workspace,document,attachment,comment,cycle,diff,diff_threads,notifications,release,release_note,status_updates,template,triage_responsibility,agent_skill},list_{issues,issue_statuses,issue_labels,projects,project_labels,milestones,teams,users,documents,comments,cycles,custom_views,diffs,releases,release_notes,release_pipelines,templates,agent_skills},search_documentation,extract_images}
)

ccq() {
  if (( $# == 0 )); then
    echo "usage: ccq <question>" >&2
    return 1
  fi
  claude -p "$*" --permission-mode dontAsk --allowedTools "${CCQ_ALLOWED_TOOLS[@]}"
}

_ccq_accept_line() {
  if [[ $BUFFER == ccq\ * ]]; then
    local q=${BUFFER#ccq }
    # Leave it alone if the user already quoted it
    [[ $q == [\'\"]* ]] || BUFFER="ccq ${(qq)q}"
  fi
  zle .accept-line
}
zle -N accept-line _ccq_accept_line
