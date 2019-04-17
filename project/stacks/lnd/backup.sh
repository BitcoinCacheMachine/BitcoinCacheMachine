#!/bin/bash

# this script removes additional lnd-specific items such as docker volumes.
echo "Waiting 20 seconds for docker containers to detach from existing volumes."

# wait for 20 seconds for back-end containers to be unmounted.
sleep 20

BACKUP_DIR="$BCM_CLUSTER_DIR/stacks/lnd"

# push the stack and build files
BCM_BACKUP_DIR="/var/lib/docker/volumes/lnd-$BCM_ACTIVE_CHAIN""_lnd-certificate-data"
lxc file pull "$BCM_BITCOIN_HOST_NAME""/var/lib/docker/volumes/lnd-$BCM_ACTIVE_CHAIN""_lnd-certificate-data" "BACKUP_DIR/lnd-cer" -p -r

lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-certificate-data"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-data"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-log-data"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-macaroon-data"
