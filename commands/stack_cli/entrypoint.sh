#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_COMMAND=

if [[ ! -z ${1+x} ]]; then
    BCM_CLI_COMMAND="$1"
else
    cat ./help.txt
    exit
fi

export BCM_CLI_COMMAND="$BCM_CLI_COMMAND"
CHAIN="$BCM_ACTIVE_CHAIN"
CHAIN_TEXT="-$CHAIN"
#CMD_TEXT=$(echo "$@" | sed 's/.* //')

# get the bitcoind instance
if [[ $BCM_CLI_COMMAND == "bitcoin-cli" ]]; then
    DOCKER_CONTAINER_ID=$(lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker ps | grep bcm-bitcoin-core: | awk '{print $1}')
    CMD_TEXT="$(echo "$@" | awk -F'bitcoin-cli ' '{print $2}')"
    
    if [[ ! -z $DOCKER_CONTAINER_ID ]]; then
        lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker exec -t "$DOCKER_CONTAINER_ID" bitcoin-cli "$CHAIN_TEXT" "$CMD_TEXT"
    else
        echo "WARNING: Docker container not found for clightning. You may need to run 'bcm stack start bitcoind'."
    fi
    
    elif [[ $BCM_CLI_COMMAND == "lightning-cli" ]]; then
    DOCKER_CONTAINER_ID="$(lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker ps | grep bcm-clightning: | awk '{print $1}')"
    CMD_TEXT="$(echo "$@" | awk -F'lightning-cli ' '{print $2}')"
    if [[ ! -z "$DOCKER_CONTAINER_ID" ]]; then
        
        lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker exec -t "$DOCKER_CONTAINER_ID" lightning-cli "$CMD_TEXT"
    else
        echo "WARNING: Docker container not found for clightning. You may need to run 'bcm stback deploy clightning'."
    fi
    
    elif [[ $BCM_CLI_COMMAND == "lncli" ]]; then
    DOCKER_CONTAINER_ID="$(lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker ps | grep bcm-lnd: | awk '{print $1}')"
    CMD_TEXT="$(echo "$@" | awk -F'lncli ' '{print $2}')"
    
    if [[ ! -z "$DOCKER_CONTAINER_ID" ]]; then
        # if the command is interactive, it goes in the if clause,
        # if command is non-interactive, it is executed in the else clause.
        if echo "$CMD_TEXT" | grep -q "create"; then
            lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker exec -it "$DOCKER_CONTAINER_ID" lncli --network="$BCM_ACTIVE_CHAIN" "$CMD_TEXT"
            elif echo "$CMD_TEXT" | grep -q "unlock"; then
            lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker exec -it "$DOCKER_CONTAINER_ID" lncli --network="$BCM_ACTIVE_CHAIN" "$CMD_TEXT"
        else
            lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker exec -t "$DOCKER_CONTAINER_ID" lncli --network="$BCM_ACTIVE_CHAIN" "$CMD_TEXT"
        fi
    else
        echo "WARNING: Docker container not found for clightning. You may need to run 'bcm stack start clightning'."
    fi
fi