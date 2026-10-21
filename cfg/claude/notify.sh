#!/bin/bash

# Claude notification script for WezTerm bell integration
# Usage: notify.sh [message]
#
# Note: osascript fails with "syntax error ... (-2740)" inside Claude Code's
# sandbox (no Apple Events), so this script is listed in sandbox.excludedCommands.

MESSAGE="${1:-Claude task completed}"

# Send terminal bell to trigger WezTerm notification
printf '\a'

# Optional: Also send a system notification. The message is passed as an
# argument rather than spliced into the script, so quotes in it are safe.
if command -v osascript >/dev/null 2>&1; then
    osascript - "$MESSAGE" <<'EOF' 2>/dev/null
on run argv
    display notification (item 1 of argv) with title "Claude Code"
end run
EOF
fi

# Add a brief visual indicator
echo "🔔 $MESSAGE"
