#!/usr/bin/env bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./env
if [[ $BCM_DEPLOY_BITCOIND == 1 ]]; then
    
    CHOICE=
    DEPLOY_TESTNET=0
    UPLOAD_TESTNET_BLOCKS=0
    UPLOAD_TESTNET_CHAINSTATE=0
    read -rp "Do you want to deploy bitcoin testnet (y/n)?: " CHOICE
    if [[ $CHOICE == "y" ]]; then
        DEPLOY_TESTNET=1
        CHOICE=
        read -rp "Do you want to upload bitcoin testnet blocks (y/n)?: " CHOICE
        if [[ $CHOICE == "y" ]]; then
            UPLOAD_TESTNET_BLOCKS=1
        fi
        
        CHOICE=
        read -rp "Do you want to upload bitcoin testnet chainstate (y/n)?: " CHOICE
        if [[ $CHOICE == "y" ]]; then
            UPLOAD_TESTNET_CHAINSTATE=1
        fi
    fi
    
    
    source ./stacks/bitcoind/env
    BCM_STACK_FILE_DIRNAME=$(dirname ./stacks/bitcoind/env)
    bash -c "$BCM_GIT_DIR/project/shared/docker_image_ops.sh --build-context=$(pwd)/stacks/bitcoind/build --container-name=bcm-bitcoin-01 --image-name=$BCM_IMAGE_NAME --image-tag=$BCM_IMAGE_TAG"
    lxc file push -p -r "$BCM_STACK_FILE_DIRNAME/" "bcm-gateway-01/root/stacks/bitcoin/"
    CONTAINER_STACK_DIR="/root/stacks/bitcoin/$BCM_STACK_NAME"
    
    if [[ $DEPLOY_TESTNET == 1 ]]; then
        lxc exec bcm-gateway-01 -- bash -c "source $CONTAINER_STACK_DIR/env && env BCM_IMAGE_NAME=$BCM_PRIVATE_REGISTRY/$BCM_IMAGE_NAME:$BCM_IMAGE_TAG BCM_BITCOIN_CHAIN=testnet docker stack deploy -c $CONTAINER_STACK_DIR/$BCM_STACK_FILE $BCM_STACK_NAME-testnet"
        
        # upload the files to the following directory
        # /var/lib/docker/volumes/bitcoind-testnet_bitcoin_data/_data
        SRC_DIR="$HOME/.bitcoin/testnet3"
        DEST_DIR="/var/lib/docker/volumes/bitcoind-testnet_bitcoin_data/_data/testnet3"
        if [[ $UPLOAD_TESTNET_BLOCKS == 1 ]]; then
            lxc file push -r -p "$SRC_DIR/blocks" "bcm-bitcoin-01/$DEST_DIR"
        fi
        
        if [[ $UPLOAD_TESTNET_CHAINSTATE == 1 ]]; then
            lxc file push -r -p "$SRC_DIR/chainstate" "bcm-bitcoin-01/$DEST_DIR"
        fi
        
        lxc exec bcm-bitcoin-01 -- touch "$DEST_DIR/gogogo"
    fi
fi

# if [[ $BCM_DEPLOY_CLIGHTNING == 1 ]]; then
#     bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(readlink -f ./stacks/clightning/env)"
# fi
