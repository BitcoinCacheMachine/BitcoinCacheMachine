#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

#bcm stack remove clightning --chain=testnet
bcm stack remove bitcoind --chain=testnet

# removes the current project from the active cluster.
bcm deprovision --del-template --del-bcmbase

# destroys the active cluster unless --cluster-name is specified.
bcm cluster destroy --ssh-username="$(whoami)" --ssh-hostname="$(hostname)" --cluster-name=LocalCluster

# deletes certificates
bcm reset