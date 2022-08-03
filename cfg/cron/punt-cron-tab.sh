#!/bin/bash
set -e
set -u
set -o pipefail

sudo crontab ~/cfg/cron/crontab.punted

echo 'Crontab contents are now:'
sudo crontab -l

