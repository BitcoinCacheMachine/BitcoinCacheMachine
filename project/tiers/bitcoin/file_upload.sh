#!/bin/bash

set -Eeuo pipefail

# shellcheck disable=SC1091
source ./env

CHAIN=
UPLOAD_BLOCKS=
UPLOAD_CHAINSTATE=

for i in "$@"; do
    case $i in
        --chain=*)
            CHAIN="${i#*=}"
            shift # past argument=value
        ;;
        --blocks=*)
            UPLOAD_BLOCKS="${i#*=}"
            shift # past argument=value
        ;;
        --chainstate=*)
            UPLOAD_CHAINSTATE="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# validate the chain
if [[ "$CHAIN" != testnet && "$CHAIN" != mainnet ]]; then
    echo "Error: --chain must be either 'testnet' or 'mainnet'."
    exit
fi

DEST_DIR='/var/lib/docker/volumes/bitcoind-'"$CHAIN"'_bitcoin_data/_data'
if [[ $CHAIN == "testnet" ]]; then
    SRC_DIR="$SRC_DIR/testnet3"
    DEST_DIR="$DEST_DIR/testnet3"
fi

if [[ "$UPLOAD_BLOCKS" == 1 ]]; then
    lxc file push -r -p "$SRC_DIR/blocks" "bcm-bitcoin-01/$DEST_DIR"
fi

if [[ "$UPLOAD_CHAINSTATE" == 1 ]]; then
    lxc file push -r -p "$SRC_DIR/chainstate" "bcm-bitcoin-01/$DEST_DIR"
fi

lxc exec bcm-bitcoin-01 -- mkdir -p "$DEST_DIR"
lxc exec bcm-bitcoin-01 -- touch "$DEST_DIR/gogogo"