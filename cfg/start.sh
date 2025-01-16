#!/bin/bash

# Navigate to note-app-prod and start the application
cd ~/projects/note-app-prod || { echo "Failed to change directory"; exit 1; }
yarn start-prod --latest > note-app-prod.log 2>&1 &

# Navigate to cfg/hosts-manager and run the unblock_server.py script
cd ~/cfg/hosts-manager || { echo "Failed to change directory"; exit 1; }
python3 unblock_server.py > unblock_server.log 2>&1 &
