#!/bin/bash

# Set a badge on the current WezTerm pane, shown as a pill in the tab bar.
# Leader+b in WezTerm toggles agent badges between short and long text.
#
# Usage:
#   badge <text>               manual badge (<=3 words)
#   badge -a <short> [long]    agent badge (short: <=3 words, long: <=9 words)
#   badge -c                   clear manual badge
#   badge -a -c                clear agent badge
#
# An agent's long text defaults to its short text. Works from Claude Code's
# Bash tool too: it writes to the tty captured by the shell at login
# ($CLAUDE_WEZTERM_TTY, see ~/.zshrc), since tool subprocesses have no
# controlling terminal.

usage() { sed -n '3,10s/^# \{0,1\}//p' "$0"; }

agent=
clear=
while [[ $1 == -* ]]; do
	case $1 in
	-a | --agent) agent=1 ;;
	-c | --clear) clear=1 ;;
	-h | --help) usage; exit 0 ;;
	*) echo "badge: unknown option $1" >&2; usage >&2; exit 1 ;;
	esac
	shift
done

if [[ -z $clear && -z $1 ]]; then
	usage >&2
	exit 1
fi

# First N words of $2; warns if anything was cut
take_words() {
	local n=$1 words
	read -ra words <<<"$2"
	if ((${#words[@]} > n)); then
		echo "badge: trimmed to $n words: ${words[*]:0:n}" >&2
	fi
	echo "${words[*]:0:n}"
}

if [[ $CLAUDE_WEZTERM_TTY == /dev/* && -w $CLAUDE_WEZTERM_TTY ]]; then
	tty_path=$CLAUDE_WEZTERM_TTY
elif { : >/dev/tty; } 2>/dev/null; then
	tty_path=/dev/tty
else
	echo "badge: no terminal to write to (is \$CLAUDE_WEZTERM_TTY set?)" >&2
	exit 1
fi

set_var() {
	printf '\033]1337;SetUserVar=%s=%s\007' "$1" "$(printf %s "$2" | base64)" >"$tty_path"
}

if [[ -n $agent ]]; then
	if [[ -n $clear ]]; then
		set_var agent_badge_short ""
		set_var agent_badge_long ""
	else
		set_var agent_badge_short "$(take_words 3 "$1")"
		set_var agent_badge_long "$(take_words 9 "${2:-$1}")"
	fi
elif [[ -n $clear ]]; then
	set_var badge ""
else
	set_var badge "$(take_words 3 "$*")"
fi
