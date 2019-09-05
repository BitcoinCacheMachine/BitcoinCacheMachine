#!/bin/bash

set -Eeuo pipefail

# if the current cluster is not configured, let's bring it into existence.
if lxc info | grep -q "server_clustered: false"; then
    echo "ERROR: the current LXD instance '$BCM_CLUSTER_NAME' has not been initialized. Try running 'bcm cluster create' or 'bcm stack start'."
    exit
fi

echo ""
echo "LXD system containers:"
lxc list

echo ""
echo "LXD networks:"
lxc network list

echo ""
if lxc storage list --format csv | grep -q "bcm"; then
    echo "BTRFS volumes:"
    lxc storage volume list bcm
else
    echo "INFO:  Storage volume 'bcm' does not exist."
fi

echo ""
echo "LXD profiles:"
lxc profile list

echo ""
echo "LXD config:"
lxc config show

echo ""
echo "LXD images:"
lxc image list

if lxc info | grep -q "server_clustered: true"; then
    echo ""
    echo "LXD cluster:"
    lxc cluster list
fi

echo ""
echo "LXD Projects:"
lxc project list
