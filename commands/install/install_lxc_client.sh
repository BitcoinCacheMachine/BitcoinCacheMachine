#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# install lxd via snap
# unless this is modified, we get snapshot creation in snap when removing lxd.
echo "Info: installing 'lxd' on $HOSTNAME."
sudo snap install lxd --channel="$BCM_LXD_SNAP_CHANNEL"
sleep 5
sudo snap set system snapshots.automatic.retention=no
sudo snap restart lxd
