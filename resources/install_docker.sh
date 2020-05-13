#!/bin/bash

set -eux

# install docker
snap install docker --channel="stable"

if ! grep -q docker /etc/group; then
    addgroup --system docker
fi

if ! groups "$SUDO_USER" | grep -q docker; then
    adduser "$SUDO_USER" docker
fi

# next we need to determine the underlying file system so we can upload the correct daemon.json
DEVICE="$(df -h "$HOME" | grep ' /' | awk '{print $1}')"
FILESYSTEM="$(mount | grep "$DEVICE")"

DAEMON_CONFIG="$BCM_COMMAND_DIR/install/overlay_daemon.json"
if echo "$FILESYSTEM" | grep -q "btrfs"; then
    DAEMON_CONFIG="$BCM_COMMAND_DIR/install/btrfs_daemon.json"
    DEST_DAEMON_FILE="/var/snap/docker/current/config/daemon.json"
    echo "INFO: Setting dockerd daemon settings to $DEST_DAEMON_FILE"
    cp "$DAEMON_CONFIG" "$DEST_DAEMON_FILE"
    snap restart docker
fi
