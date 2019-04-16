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
echo "BTRFS volumes:"
lxc storage volume list default


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
