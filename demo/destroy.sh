#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

#bcm stack remove clightning --chain=testnet
#bcm stack remove bitcoind --chain=testnet

# removes the current project from the active cluster.
bcm deprovision --del-template --del-lxcbase

# destroys the active cluster unless --cluster-name is specified.
bcm cluster destroy --ssh-username="ubuntu" --ssh-hostname="antsle"

# deletes certificates
bcm reset