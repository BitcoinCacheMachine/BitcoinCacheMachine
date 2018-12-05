#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/.env"

BCM_CLI_VERB=$2
BCM_PASS_NAME=

for i in "$@"
do
case $i in
    --name=*)
    BCM_PASS_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
    ;;
esac
done


if [[ -z $BCM_PASS_NAME ]]; then
    echo "BCM_PASS_NAME cannot be empty"
fi

source "$BCM_GIT_DIR/controller/export_usb_path.sh"
if [[ $BCM_CLI_VERB = "new" ]]; then
    # How we reference the password.
    docker run -it --name pass --rm \
        -v "$BCM_CERTS_DIR":/root/.gnupg \
        -v "$BCM_PASSWORDS_DIR":/root/.password-store \
        -e BCM_PASS_NAME="$BCM_PASS_NAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest bash -c "pass generate $BCM_PASS_NAME 32 >>/dev/null"

elif [[ $BCM_CLI_VERB = "get" ]]; then
    # How we reference the password.
    docker run -it --name pass --rm \
        -v "$BCM_CERTS_DIR":/root/.gnupg \
        -v "$BCM_PASSWORDS_DIR":/root/.password-store \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=1 \
        -e BCM_PASS_NAME="$BCM_PASS_NAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest pass $BCM_PASS_NAME
fi