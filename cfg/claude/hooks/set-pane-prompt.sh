#!/bin/bash
# Sets a WezTerm user var with the latest user prompt (truncated)
# Used by UserPromptSubmit hook

input=$(cat)
prompt=$(echo "$input" | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null)

if [[ -n "$prompt" ]]; then
  # Truncate to 80 chars
  prompt="${prompt:0:80}"
  # Set WezTerm user var via OSC 1337, writing to the pane's TTY.
  # This hook subprocess is detached from any controlling terminal, so
  # tty(1)/`/dev/tty` can't find it here - use the tty captured by the
  # shell at login instead (see ~/cfg/zsh/.zshrc).
  encoded=$(echo -n "$prompt" | base64)
  tty_path="$CLAUDE_WEZTERM_TTY"
  if [[ -n "$tty_path" && -w "$tty_path" ]]; then
    printf "\033]1337;SetUserVar=%s=%s\007" "claude_prompt" "$encoded" > "$tty_path" 2>/dev/null
  fi
fi
