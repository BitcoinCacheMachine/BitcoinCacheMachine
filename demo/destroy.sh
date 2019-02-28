#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

#bcm stack remove clightning --chain=testnet
bcm stack remove bitcoind --chain=testnet

# destroys the active cluster unless --cluster-name is specified.
bcm cluster destroy --ssh-username="$(whoami)" --ssh-hostname="$(hostname)" --cluster-name=LocalCluster
bcm cluster destroy --driver=multipass --cluster-name=bcm

# deletes certificates
bcm reset