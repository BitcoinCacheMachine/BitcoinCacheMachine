#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

#bcm stack remove clightning --chain=testnet
bcm stack remove bitcoind --chain=testnet

# destroys the active cluster. Specify --cluster-name to destroy specific cluster.
bcm cluster destroy

# deletes certificates
bcm reset