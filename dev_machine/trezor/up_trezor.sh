#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

source $BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh

docker build -t bcmtrezor:latest .

# make the hwwallet_certs directory if it doesn't exist.
if [[ ! -d ~/.bcm/lxd_projects/$BCM_CURRENT_PROJECT_NAME ]]; then
    mkdir -p ~/.bcm/lxd_projects/$BCM_CURRENT_PROJECT_NAME
fi

source ./export_usb_path.sh

# if we don't already have a GPG key for the PROJECT_NAME
if [[ ! -z ~/.bcm/lxd_projects/$BCM_CURRENT_PROJECT_NAME/trezor/pubkey.asc ]]; then
    if [[ ! -z $TREZOR_USB_PATH ]]; then
        echo "Using USB device: $TREZOR_USB_PATH"
        docker run -it -v ~/.bcm/lxd_projects/$BCM_CURRENT_PROJECT_NAME:/root/.gnupg \
        -e BCM_CURRENT_PROJECT_NAME=$BCM_CURRENT_PROJECT_NAME \
        -e BCM_PROJECT_CERTIFICATE_EMAIL=$BCM_PROJECT_CERTIFICATE_EMAIL \
        --device=$TREZOR_USB_PATH \
        bcmtrezor:latest trezor-gpg init "$BCM_CURRENT_PROJECT_NAME <$BCM_PROJECT_CERTIFICATE_EMAIL>" 
        
        echo "Yay! Your LXC project root certificate (public key and public keyring) can be found at ~/.bcm/lxd_projects/$BCM_CURRENT_PROJECT_NAME/trezor"
    else
        echo "TREZOR_USB_PATH not set. Quitting script."
    fi
fi
