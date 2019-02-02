#!/usr/bin/env bash

set -Eeuox pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/env"

# shellcheck disable=SC1091
source ./env
if [[ $BCM_DEPLOY_BITCOIND == 1 ]]; then
    
    CHOICE=
    CHAIN=
    UPLOAD_BLOCKS=0
    UPLOAD_CHAINSTATE=0
    SRC_DIR=
    
    read -rp "Do you want to deploy bitcoin testnet (y/n)?: " CHOICE
    if [[ $CHOICE == "y" ]]; then
        CHAIN=testnet
        
        if [[ $CHAIN == "testnet" ]]; then
            SRC_DIR="$HOME/.bitcoin/testnet3"
            elif [[ $CHAIN == "mainnet" ]]; then
            SRC_DIR="$HOME/.bitcoin"
        fi
        
        if [[ -d "$SRC_DIR/blocks" ]]; then
            CHOICE=
            read -rp "Do you want to upload bitcoin $CHAIN blocks (y/n)?: " CHOICE
            if [[ $CHOICE == "y" ]]; then
                UPLOAD_BLOCKS=1
            fi
        else
            echo "Note: You can push the raw blockchain when the $SRC_DIR/blocks directory exists."
        fi
        
        if [[ -d "$SRC_DIR/chainstate" ]]; then
            read -rp "Do you want to upload bitcoin $CHAIN chainstate (y/n)?: " CHOICE
            if [[ $CHOICE == "y" ]]; then
                UPLOAD_CHAINSTATE=1
            fi
        else
            echo "Note: You can push the chainstate when the $SRC_DIR/chainstate directory exists. Note also that this is not secure."
        fi
    fi
    
    # cd $BCM_GIT_DIR/project/tiers/bitcoin
    # source "$BCM_GIT_DIR/env"
    # CHAIN=testnet
    source ./stacks/bitcoind/env
    BCM_STACK_FILE_DIRNAME=$(dirname ./stacks/bitcoind/env)
    bash -c "$BCM_GIT_DIR/project/shared/docker_image_ops.sh --build-context=$(pwd)/stacks/bitcoind/build --container-name=bcm-bitcoin-01 --image-name=$BCM_IMAGE_NAME --image-tag=$BCM_IMAGE_TAG"
    lxc file push -p -r "$BCM_STACK_FILE_DIRNAME/" "bcm-gateway-01/root/stacks/bitcoin/"
    CONTAINER_STACK_DIR="/root/stacks/bitcoin/$BCM_STACK_NAME"
    lxc exec bcm-gateway-01 -- bash -c "source $CONTAINER_STACK_DIR/env && env BCM_IMAGE_NAME=$BCM_PRIVATE_REGISTRY/$BCM_IMAGE_NAME:$BCM_IMAGE_TAG BCM_BITCOIN_CHAIN=$CHAIN docker stack deploy -c $CONTAINER_STACK_DIR/$BCM_STACK_FILE $BCM_STACK_NAME-$CHAIN"
    
    # upload the files to the following directory
    # /var/lib/docker/volumes/bitcoind-$CHAIN_bitcoin_data/_data
    DEST_DIR='/var/lib/docker/volumes/bitcoind-'"$CHAIN"'_bitcoin_data/_data'
    if [[ $CHAIN == "testnet" ]]; then
        DEST_DIR="$DEST_DIR/testnet3"
    fi
    
    if [[ $UPLOAD_BLOCKS == 1 ]]; then
        lxc file push -r -p "$SRC_DIR/blocks" "bcm-bitcoin-01/$DEST_DIR"
    fi
    
    if [[ $UPLOAD_CHAINSTATE == 1 ]]; then
        lxc file push -r -p "$SRC_DIR/chainstate" "bcm-bitcoin-01/$DEST_DIR"
    fi
    
    lxc exec bcm-bitcoin-01 -- touch "$DEST_DIR/gogogo"
fi

# if [[ $BCM_DEPLOY_CLIGHTNING == 1 ]]; then
#     bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(readlink -f ./stacks/clightning/env)"
# fi
