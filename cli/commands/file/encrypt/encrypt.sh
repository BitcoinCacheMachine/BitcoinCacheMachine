#!/bin/bash

set -eu
cd "$(dirname "$0")"

echo "BCM_CERT_DIR: $BCM_CERT_DIR"
echo "INPUT_FILE_DIR: $INPUT_FILE_DIR"
echo "INPUT_FILE_NAME: $INPUT_FILE_NAME"

source $BCM_CERT_DIR/.env
echo "BCM_CERT_NAME: $BCM_CERT_NAME"

# start the container / trezor-gpg-agent
docker run -it --rm  --name trezorencryptor \
    -v $BCM_CERT_DIR:/root/.gnupg \
    -v $INPUT_FILE_DIR:/sigdir \
    bcm-trezor:latest gpg --output /sigdir/$INPUT_FILE_NAME.gpg --encrypt --recipient $BCM_CERT_NAME /sigdir/$INPUT_FILE_NAME

if [[ -f $BCM_FILE_PATH.gpg ]]; then
    echo "Encrypted file created at $BCM_FILE_PATH.gpg"
fi