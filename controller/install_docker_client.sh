#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# install docker if it doesn't exist.
if [ ! -x "$(command -v docker)" ]; then
    if ! grep -q docker /etc/group; then
        sudo addgroup docker
    fi
    
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
    fi
    
    if [ ! -x "$(command -v docker)" ]; then
        echo "Info: installing 'docker' locally."
        
        sudo snap install docker --channel=candidate
        
        # next we need to determine the underlying file system so we can upload the correct daemon.json
        DEVICE="$(df -h "$HOME" | grep ' /' | awk '{print $1}')"
        FILESYSTEM="$(mount | grep "$DEVICE")"
        DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/overlay_daemon.json"
        
        if echo "$FILESYSTEM" | grep -q "btrfs"; then
            DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/btrfs_daemon.json"
        fi
        
        sudo cp "$DAEMON_CONFIG" /var/snap/docker/current/config/daemon.json
        sudo snap restart docker
        sleep 5
    fi
fi
