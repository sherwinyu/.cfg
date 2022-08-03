#!/bin/bash
set -e
set -u
set -o pipefail

sudo crontab ~/cfg/cron/crontab

echo 'Restoring crontab from ~/cfg/cron/crontab'
echo 'Crontab contents are now:'
sudo crontab -l
