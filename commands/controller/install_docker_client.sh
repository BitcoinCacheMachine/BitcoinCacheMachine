#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if [[ ! -f "$(command -v docker)" ]]; then
    echo "INFO: Installing 'docker' locally using snap."
    sudo snap install docker --channel="stable"
    
    if ! grep -q docker /etc/group; then
        sudo groupadd docker
    fi
    
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
    fi
    
    # next we need to determine the underlying file system so we can upload the correct daemon.json
    DEVICE="$(df -h "$HOME" | grep ' /' | awk '{print $1}')"
    FILESYSTEM="$(mount | grep "$DEVICE")"
    
    DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/overlay_daemon.json"
    if echo "$FILESYSTEM" | grep -q "btrfs"; then
        DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/btrfs_daemon.json"
        DEST_DAEMON_FILE="/var/snap/docker/current/config/daemon.json"
        echo "INFO: Setting dockerd daemon settings to $DEST_DAEMON_FILE"
        sudo cp "$DAEMON_CONFIG" "$DEST_DAEMON_FILE"
        sudo snap restart docker
    fi
fi
