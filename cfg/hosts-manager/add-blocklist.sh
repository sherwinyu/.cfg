#!/bin/bash
# Adds the default distraction blocklist to /etc/hosts via the `hosts` CLI.
# Each entry points at 0.0.0.0 and is tagged with the comment "blocklist" so
# the group can be found later: `hosts search blocklist`.
#
# Entries are added ENABLED (= blocked). Use the Hammerspoon Hyper+U chooser
# (or the unblock server) to temporarily unblock a domain for a set duration.
#
# Needs root to write /etc/hosts — re-execs itself under sudo if necessary.

set -u

HOSTS=/opt/homebrew/bin/hosts
IP=0.0.0.0
TAG=blocklist

# Re-exec under sudo with a single password prompt if not already root.
if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

domains=(
  # Facebook
  facebook.com www.facebook.com
  # Instagram
  instagram.com www.instagram.com
  # Reddit
  reddit.com www.reddit.com
  # Twitter / X
  twitter.com www.twitter.com x.com www.x.com
  # YouTube
  youtube.com www.youtube.com
  # Hacker News
  news.ycombinator.com www.news.ycombinator.com
  # TikTok
  tiktok.com www.tiktok.com
  # Wikipedia
  wikipedia.org www.wikipedia.org en.wikipedia.org m.en.wikipedia.org
  # LearnedLeague
  learnedleague.com www.learnedleague.com
)

added=0 skipped=0
for d in "${domains[@]}"; do
  if "$HOSTS" add "$IP" "$d" "$TAG" >/dev/null 2>&1; then
    echo "  added   $d"
    ((added++))
  else
    echo "  exists  $d (skipped)"
    ((skipped++))
  fi
done

echo
echo "Done: $added added, $skipped already present."
echo "Review with: hosts search $TAG"
