#!/bin/bash

# Codex notification script for WezTerm bell integration.
# Usage: notify.sh [message]

MESSAGE="${1:-Codex task completed}"

# Send a terminal bell to trigger WezTerm's notification handling.
printf '\a'

# Also send a macOS notification when AppleScript is available. Pass the
# message as an argument so quotes and other characters remain literal.
if command -v osascript >/dev/null 2>&1; then
    osascript - "$MESSAGE" <<'APPLESCRIPT'
on run argv
    display notification (item 1 of argv) with title "Codex"
end run
APPLESCRIPT
fi

echo "🔔 $MESSAGE"
