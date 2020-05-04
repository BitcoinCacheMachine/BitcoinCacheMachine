#!/bin/bash

set -Eeuo nounset
cd "$(dirname "$0")"

BCM_CLI_VERB=
BCM_PASS_NAME=

VALUE=${2:-}
if [ -n "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    cat ./help.txt
    exit
fi

for i in "$@"; do
    case $i in
        --name=*)
            BCM_PASS_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"
if [[ $BCM_CLI_VERB == "new" ]]; then
    
    if [[ -z $BCM_PASS_NAME ]]; then
        echo "BCM_PASS_NAME cannot be empty. Use '--name=<password_name>'"
        cat ./help.txt
        exit
    fi
    
    # How we reference the password.
    docker run -t --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:rw \
    -v "$PASSWDHOME":/home/user/.password-store:rw \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" bash -c "pass generate $BCM_PASS_NAME --no-symbols 32 >>/dev/null"
    
    elif [[ $BCM_CLI_VERB == "get" ]]; then
    
    if [[ -z $BCM_PASS_NAME ]]; then
        echo "BCM_PASS_NAME cannot be empty. Use '--name=<password_name>'"
        cat ./help.txt
        exit
    fi
    
    # How we reference the password.
    docker run -it --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:rw \
    -v "$PASSWDHOME":/home/user/.password-store \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass "$BCM_PASS_NAME"
    
    elif [[ $BCM_CLI_VERB == "list" || $BCM_CLI_VERB == "ls" ]]; then
    docker run -it --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:ro \
    -v "$PASSWDHOME":/home/user/.password-store \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass ls
    
    elif [[ $BCM_CLI_VERB == "rm" || $BCM_CLI_VERB == "remove" ]]; then
    docker run -it --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:rw \
    -v "$PASSWDHOME":/home/user/.password-store \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass rm "$BCM_PASS_NAME"
    
    elif [[ $BCM_CLI_VERB == "insert" ]]; then
    docker run -it --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:rw \
    -v "$PASSWDHOME":/home/user/.password-store \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass insert "$BCM_PASS_NAME"
fi