#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

# shellcheck disable=SC1091
source ./env


source "$BCM_GIT_DIR/env"

CHAIN=
for i in "$@"; do
    case $i in
        --chain=*)
            CHAIN="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $CHAIN ]]; then
    echo "CHAIN not specified. Exiting"
    exit
fi

# validate the chain
if [[ "$CHAIN" != testnet && "$CHAIN" != mainnet ]]; then
    echo "Error: --chain must be either 'testnet' or 'mainnet'."
    exit
fi

bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=bitcoind-$CHAIN"
