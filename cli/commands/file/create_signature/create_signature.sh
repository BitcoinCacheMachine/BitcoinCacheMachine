#!/bin/bash

echo "entering create_signature.sh"
# echo "Signature file  will be created at $BCM_TREZOR_FILE_PATH.sig"

# INPUT_FILE_DIR=$(dirname $BCM_TREZOR_FILE_PATH)
# INPUT_FILE_NAME=$(basename $BCM_TREZOR_FILE_PATH)

# echo "INPUT_FILE_DIR: $INPUT_FILE_DIR"
# echo "INPUT_FILE_NAME: $INPUT_FILE_NAME"

# # will pgp sign a file uwing your trezor
# docker run -it -v $BCM_PROJECT_DIR:/home/user/.gnupg \
#     -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
#     -v $INPUT_FILE_DIR:/sigdir \
#     --device=$BCM_TREZOR_USB_PATH \
#     bcm-trezor:latest gpg --sign --detach-sig -s /sigdir/$INPUT_FILE_NAME

# if [[ -f $BCM_TREZOR_FILE_PATH.sig ]]; then
#     echo "Signature created at $BCM_TREZOR_FILE_PATH.sig"
# fi
