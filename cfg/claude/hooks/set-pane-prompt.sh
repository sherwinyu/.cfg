#!/bin/bash
# Sets a WezTerm user var with the latest user prompt (truncated)
# Used by UserPromptSubmit hook

input=$(cat)
prompt=$(echo "$input" | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null)

if [[ -n "$prompt" ]]; then
  # Truncate to 80 chars
  prompt="${prompt:0:80}"
  # Set WezTerm user var via OSC 1337, writing to the pane's TTY
  encoded=$(echo -n "$prompt" | base64)
  tty_path=$(tty 2>/dev/null)
  if [[ -n "$tty_path" && "$tty_path" != "not a tty" ]]; then
    printf "\033]1337;SetUserVar=%s=%s\007" "claude_prompt" "$encoded" > "$tty_path"
  else
    # Fallback: try /dev/tty (only if it's writable; suppress open errors)
    if [[ -w /dev/tty ]]; then
      printf "\033]1337;SetUserVar=%s=%s\007" "claude_prompt" "$encoded" 2>/dev/null > /dev/tty
    fi
  fi
fi
