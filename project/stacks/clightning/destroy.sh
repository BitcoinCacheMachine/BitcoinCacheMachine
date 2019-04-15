#!/bin/bash

# this script removes additional lnd-specific items such as docker volumes.

# wait for 20 seconds for back-end containers to be unmounted.
sleep 20

# push the stack and build files
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "clightning-$BCM_ACTIVE_CHAIN""_clightning-data"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "clightning-$BCM_ACTIVE_CHAIN""_clightning-log-data"