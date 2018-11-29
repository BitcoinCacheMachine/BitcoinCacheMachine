#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ -z $BCM_SSH_USERNAME ]]; then
    echo "BCM_SSH_USERNAME empty."
    cat ./help.txt
    exit
fi

if [[ -z $BCM_SSH_HOSTNAME ]]; then
    echo "BCM_SSH_HOSTNAME empty."
    exit
fi

# get the locatio of the trezor
source $BCM_LOCAL_GIT_REPO_DIR/controller/export_usb_path.sh
echo "BCM_TREZOR_USB_PATH: $BCM_TREZOR_USB_PATH"
echo "BCM_SSH_KEY_DIR: $BCM_SSH_KEY_DIR"
echo "BCM_SSH_USERNAME: $BCM_SSH_USERNAME"
echo "BCM_SSH_HOSTNAME: $BCM_SSH_HOSTNAME"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
    docker run -it --rm --add-host="$BCM_SSH_HOSTNAME:$(dig +short $BCM_SSH_HOSTNAME)" \
        -v $BCM_SSH_KEY_DIR:/root/.ssh \
        -e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
        -e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME --connect"
fi
