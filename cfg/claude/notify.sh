#!/bin/bash

# Claude notification script for WezTerm bell integration
# Usage: notify.sh [message]

MESSAGE="${1:-Claude task completed}"

# Send terminal bell to trigger WezTerm notification
printf '\a'

# Optional: Also send a system notification
if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\""
fi

# Add a brief visual indicator
echo "🔔 $MESSAGE"