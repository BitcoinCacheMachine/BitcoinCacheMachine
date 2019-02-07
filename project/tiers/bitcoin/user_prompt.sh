#!/bin/bash

set -Eeuo pipefail

source "$BCM_GIT_DIR/env"
source ./env

CHOICE=

export DEPLOY_TESTNET=0
export UPLOAD_TESTNET_BLOCKS=0
export UPLOAD_TESTNET_CHAINSTATE=0
export DEPLOY_MAINNET=0
export UPLOAD_MAINNET_BLOCKS=0
export UPLOAD_MAINNET_CHAINSTATE=0

read -rp "Do you want to deploy bitcoin testnet (y/n)?: " CHOICE
if [[ $CHOICE == "y" ]]; then
    DEPLOY_TESTNET=1
    
    if [[ -d "$SRC_DIR/blocks" ]]; then
        CHOICE=
        read -rp "Do you want to upload bitcoin testnet blocks (y/n)?: " CHOICE
        if [[ $CHOICE == "y" ]]; then
            UPLOAD_TESTNET_BLOCKS=1
        fi
    else
        echo "Note: You can push the raw blockchain when the $SRC_DIR/blocks directory exists."
    fi
    
    
    if [[ -d "$SRC_DIR/chainstate" && "$UPLOAD_TESTNET_BLOCKS" == 1 ]]; then
        read -rp "Do you want to upload bitcoin testnet chainstate (y/n)?: " CHOICE
        if [[ $CHOICE == "y" ]]; then
            UPLOAD_TESTNET_CHAINSTATE=1
        fi
    else
        if [[ "$UPLOAD_TESTNET_BLOCKS" == 1 ]]; then
            echo "Note: You can push the chainstate when the $SRC_DIR/chainstate directory exists. Note also that this is not secure."
        fi
    fi
fi

read -rp "Do you want to deploy bitcoin mainnet (y/n)?: " CHOICE
if [[ $CHOICE == "y" ]]; then
    DEPLOY_MAINNET=1
    
    if [[ -d "$SRC_DIR/blocks" ]]; then
        CHOICE=
        read -rp "Do you want to upload bitcoin mainnet blocks (y/n)?: " CHOICE
        if [[ $CHOICE == "y" ]]; then
            UPLOAD_MAINNET_BLOCKS=1
        fi
    else
        echo "Note: You can push the raw blockchain when the $SRC_DIR/blocks directory exists."
    fi
    
    
    if [[ -d "$SRC_DIR/chainstate" && "$UPLOAD_MAINNET_BLOCKS" == 1 ]]; then
        read -rp "Do you want to upload bitcoin mainnet chainstate (y/n)?: " CHOICE
        if [[ $CHOICE == "y" ]]; then
            UPLOAD_MAINNET_CHAINSTATE=1
        fi
    else
        echo "Note: You can push the chainstate when the $SRC_DIR/chainstate directory exists. Note also that this is not secure."
    fi
fi

export DEPLOY_TESTNET="$DEPLOY_TESTNET"
export UPLOAD_TESTNET_BLOCKS="$UPLOAD_TESTNET_BLOCKS"
export UPLOAD_TESTNET_CHAINSTATE="$UPLOAD_TESTNET_CHAINSTATE"
export DEPLOY_MAINNET="$DEPLOY_MAINNET"
export UPLOAD_MAINNET_BLOCKS="$UPLOAD_MAINNET_BLOCKS"
export UPLOAD_MAINNET_CHAINSTATE="$UPLOAD_MAINNET_CHAINSTATE"

if [[ $BCM_DEBUG == 1 ]]; then
    echo "DEPLOY_TESTNET:  $DEPLOY_TESTNET"
    echo "UPLOAD_TESTNET_BLOCKS:  $UPLOAD_TESTNET_BLOCKS"
    echo "UPLOAD_TESTNET_CHAINSTATE:  $UPLOAD_TESTNET_CHAINSTATE"
    echo "DEPLOY_MAINNET:  $DEPLOY_MAINNET"
    echo "UPLOAD_MAINNET_BLOCKS:  $UPLOAD_MAINNET_BLOCKS"
    echo "UPLOAD_MAINNET_CHAINSTATE:  $UPLOAD_MAINNET_CHAINSTATE"
fi