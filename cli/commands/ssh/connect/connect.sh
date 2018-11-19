#!/bin/bash

set -eu
cd "$(dirname "$0")"

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ -z $BCM_TREZOR_SSH_USERNAME ]]; then
    echo "BCM_TREZOR_SSH_USERNAME empty."
    cat ./help.txt
    exit
fi

if [[ -z $BCM_TREZOR_SSH_HOSTNAME ]]; then
    echo "BCM_TREZOR_SSH_HOSTNAME empty."
    exit
fi

if [[ -z $BCM_SSH_KEY_DIR ]]; then
    echo "BCM_SSH_KEY_DIR is empty. Setting to $HOME/.ssh"
    export BCM_SSH_KEY_DIR="$HOME/.ssh"
fi

# get the locatio of the trezor
source $BCM_LOCAL_GIT_REPO_DIR/mgmt_plane/export_usb_path.sh
echo "BCM_TREZOR_USB_PATH: $BCM_TREZOR_USB_PATH"
echo "BCM_SSH_KEY_DIR: $BCM_SSH_KEY_DIR"
echo "BCM_TREZOR_SSH_HOSTNAME: $BCM_TREZOR_SSH_HOSTNAME"
echo "BCM_TREZOR_SSH_USERNAME: $BCM_TREZOR_SSH_USERNAME"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
    docker run -it --rm --add-host="$BCM_TREZOR_SSH_HOSTNAME:$(dig +short $BCM_TREZOR_SSH_HOSTNAME)" \
        -v $BCM_SSH_KEY_DIR:/root/.ssh \
        -e BCM_TREZOR_SSH_USERNAME="$BCM_TREZOR_SSH_USERNAME" \
        -e BCM_TREZOR_SSH_HOSTNAME="$BCM_TREZOR_SSH_HOSTNAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest bash -c "trezor-agent $BCM_TREZOR_SSH_USERNAME@$BCM_TREZOR_SSH_HOSTNAME --connect"
fi
