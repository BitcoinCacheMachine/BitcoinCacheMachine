#!/bin/bash

set -Eeuo pipefail

# if the current cluster is not configured, let's bring it into existence.
if lxc info | grep -q "server_clustered: false"; then
    echo "ERROR: the current LXD instance '$BCM_SSH_HOSTNAME' has not been initialized."
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

echo ""
echo "LXD profiles:"
lxc profile list

echo ""
echo "LXD config:"
lxc config show

echo ""
echo "LXD images:"
lxc image list

# if lxc info | grep -q "server_clustered: true"; then
#     echo ""
#     echo "LXD cluster:"
#     lxc cluster list
# fi

echo ""
echo "LXD Projects:"
lxc project list

echo ""
echo "LXD Configuration"
lxd init --dump