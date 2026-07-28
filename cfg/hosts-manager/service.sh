#!/bin/bash

PLIST_FILE="$HOME/cfg/hosts-manager/com.sherwin.unblock-server.plist"
DAEMON_PATH="/Library/LaunchDaemons/com.sherwin.unblock-server.plist"

case "$1" in
    install)
        echo "Installing unblock-server as a system service..."
        sudo cp "$PLIST_FILE" "$DAEMON_PATH"
        sudo chown root:wheel "$DAEMON_PATH"
        sudo chmod 644 "$DAEMON_PATH"
        sudo launchctl load "$DAEMON_PATH"
        echo "Service installed and started."
        ;;
    uninstall)
        echo "Uninstalling unblock-server service..."
        sudo launchctl unload "$DAEMON_PATH"
        sudo rm "$DAEMON_PATH"
        echo "Service uninstalled."
        ;;
    start)
        echo "Starting unblock-server service..."
        sudo launchctl start com.sherwin.unblock-server
        ;;
    stop)
        echo "Stopping unblock-server service..."
        sudo launchctl stop com.sherwin.unblock-server
        ;;
    restart)
        echo "Restarting unblock-server service..."
        sudo launchctl stop com.sherwin.unblock-server
        sleep 1
        sudo launchctl start com.sherwin.unblock-server
        ;;
    status)
        echo "Checking unblock-server service status..."
        sudo launchctl list | grep com.sherwin.unblock-server
        ;;
    logs)
        echo "Showing service logs..."
        tail -f "$HOME/cfg/hosts-manager/unblock_server.log"
        ;;
    *)
        echo "Usage: $0 {install|uninstall|start|stop|restart|status|logs}"
        exit 1
        ;;
esac
