#!/bin/bash

#TODO figure if there's a way to detect when a docker container is fully detached.

# this script removes additional lnd-specific items such as docker volumes.
echo "Waiting 20 seconds for docker containers to detach from existing volumes."

# wait for 20 seconds for back-end containers to be unmounted.
sleep 20

# push the stack and build files
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-certificate-data"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-data"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-log-data"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "lnd-$BCM_ACTIVE_CHAIN""_lnd-macaroon-data"
