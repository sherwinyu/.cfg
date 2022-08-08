#!/bin/bash
set -e
set -u
set -o pipefail

echo 'Path =='
echo $PATH
echo 'Restoring crontab from ~/cfg/cron/crontab. Crontab is now...'

if [ $UID -eq 0 ]
then
  crontab /Users/sherwin/cfg/cron/crontab
  crontab -l
else
  sudo crontab ~/cfg/cron/crontab
  sudo crontab -l
fi
