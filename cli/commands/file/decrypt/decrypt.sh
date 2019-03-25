#!/bin/bash

echo "entering decrypt.sh"

# echo "BCM_PROJECT_DIR: $BCM_PROJECT_DIR"
# echo "File to decrypt: $BCM_TREZOR_FILE_PATH"

# INPUT_FILE_DIR=$(dirname $BCM_TREZOR_FILE_PATH)
# INPUT_FILE_NAME=$(basename $BCM_TREZOR_FILE_PATH)

# echo "INPUT_FILE_DIR: $INPUT_FILE_DIR"
# echo "INPUT_FILE_NAME: $INPUT_FILE_NAME"

# docker run -it --rm \
#     -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
#     -v $BCM_PROJECT_DIR:/home/user/.gnupg \
#     -v $INPUT_FILE_DIR:/sigdir \
#     --device=$BCM_TREZOR_USB_PATH \
#     bcm-trezor:latest gpg --output /sigdir/$INPUT_FILE_NAME.decrypted --decrypt /sigdir/$INPUT_FILE_NAME
