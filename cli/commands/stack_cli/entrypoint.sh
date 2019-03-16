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
CHAIN="$BCM_DEFAULT_CHAIN"
CHAIN_TEXT="-$CHAIN"
CMD_TEXT=$(echo "$@" | sed 's/.* //')

# get the bitcoind instance
DOCKER_CONTAINER_ID=$(lxc exec bcm-bitcoin-01 -- docker ps | grep bcm-bitcoin-core: | awk '{print $1}')
if [[ $BCM_CLI_COMMAND == "bitcoin-cli" ]]; then
    lxc exec bcm-bitcoin-01 -- docker exec -it "$DOCKER_CONTAINER_ID" bitcoin-cli "$CHAIN_TEXT" "$CMD_TEXT"
    elif [[ $BCM_CLI_COMMAND == "lightning-cli" ]]; then
    lxc exec bcm-bitcoin-01 -- docker exec -it "$DOCKER_CONTAINER_ID" lightning-cli "$CMD_TEXT"
fi