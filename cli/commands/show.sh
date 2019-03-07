#!/bin/bash

set -Eeuo pipefail

if [[ $(lxc remote get-default) == "local" ]]; then
    echo "ERROR: current LXD remote is set to local. You may need to run 'bcm cluster create'."
    exit
fi

echo ""
echo "LXD system containers:"
lxc list

echo ""
echo "LXD networks:"
lxc network list

echo ""
echo "LXD storage pools:"
lxc storage list

if lxc storage list | grep -q bcm_btrfs; then
    echo ""
    echo "LXD storage bcm_btrfs volumes:"
    lxc storage volume list bcm_btrfs
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
echo "LXD projects:"
lxc project list
