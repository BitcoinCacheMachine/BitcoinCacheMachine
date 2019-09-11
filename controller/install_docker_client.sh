#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

if ! grep -q docker /etc/group; then
    sudo addgroup docker
fi

if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
fi

if ! snap list | grep -q docker; then
    echo "Info: installing 'docker' locally."
    sudo snap install docker --channel=candidate
fi

# next we need to determine the underlying file system so we can upload the correct daemon.json
DEVICE="$(df -h "$HOME" | grep ' /' | awk '{print $1}')"
FILESYSTEM="$(mount | grep "$DEVICE")"


DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/overlay_daemon.json"
if echo "$FILESYSTEM" | grep -q "btrfs"; then
    DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/btrfs_daemon.json"
fi

DAEMON_FILE="/var/snap/docker/current/config/daemon.json"
echo "INFO: Setting dockerd daemon settings to $DAEMON_FILE"
sudo cp "$DAEMON_CONFIG" "$DAEMON_FILE"

sudo snap restart docker
sleep 5
