#!/bin/bash

set -eu

if [[ -z $BCM_PROJECT_NAME ]]; then
    echo "BCM_PROJECT_NAME not set."
    exit
fi

if [[ -z $BCM_PROJECT_DIR ]]; then
    echo "BCM_PROJECT_DIR not set."
    exit
fi

echo "BCM_PROJECT_DIR: '$BCM_PROJECT_DIR'"

if [[ -z $BCM_TREZOR_FILE_PATH ]]; then
    echo "BCM_PROJECT_DIR not set."
    exit
else
    echo "File to encrypt: '$BCM_TREZOR_FILE_PATH'"
fi


INPUT_FILE_DIR=$(dirname $BCM_TREZOR_FILE_PATH)
INPUT_FILE_NAME=$(basename $BCM_TREZOR_FILE_PATH)

echo "INPUT_FILE_DIR: $INPUT_FILE_DIR"
echo "INPUT_FILE_NAME: $INPUT_FILE_NAME"

# start the container / trezor-gpg-agent
docker run -it --rm --name trezorencryptor \
    -v $BCM_PROJECT_DIR:/root/.gnupg \
    -v $INPUT_FILE_DIR:/sigdir \
    bcm-trezor:latest gpg --output /sigdir/$INPUT_FILE_NAME.gpg --encrypt --recipient $BCM_PROJECT_NAME /sigdir/$INPUT_FILE_NAME

if [[ -f $BCM_TREZOR_FILE_PATH.gpg ]]; then
    echo "Encrypted file created at $BCM_TREZOR_FILE_PATH.gpg"
fi