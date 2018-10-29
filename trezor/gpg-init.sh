#!/bin/bash

set -eu

echo ""
echo "Starting GPG init process."
echo "  BCM_PROJECT_DIR: $BCM_PROJECT_DIR"

docker build -t bcm-trezor:latest $BCM_LOCAL_GIT_REPO/trezor/

docker run -it --name trezorgpg --rm -v $BCM_PROJECT_DIR:/root/.gnupg \
    -e BCM_PROJECT_NAME=$BCM_PROJECT_NAME \
    -e BCM_PROJECT_USERNAME=$BCM_PROJECT_USERNAME \
    -e BCM_PROJECT_CLUSTERNAME=$BCM_PROJECT_CLUSTERNAME \
    --device=$BCM_TREZOR_USB_PATH \
    bcm-trezor:latest bash -c 'trezor-gpg init "$BCM_PROJECT_NAME <$BCM_PROJECT_USERNAME@$BCM_PROJECT_CLUSTERNAME>" && mkdir /root/.gnupg/trezor/ssh'

echo "Yay! Your LXC project root certificate (public key and public keyring) can be found at $BCM_PROJECT_DIR/trezor"