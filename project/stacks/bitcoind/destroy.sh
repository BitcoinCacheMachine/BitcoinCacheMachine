#!/bin/bash

SLEEP_TIME=30

# this script removes additional lnd-specific items such as docker volumes.
echo "Waiting $SLEEP_TIME seconds for docker containers to detach from existing volumes."
sleep "$SLEEP_TIME"

# push the stack and build files
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "bitcoind-$BCM_ACTIVE_CHAIN""_bitcoin_cli"
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker volume rm -f "bitcoind-$BCM_ACTIVE_CHAIN""_bitcoin-data"
