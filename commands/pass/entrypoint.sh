#!/bin/bash

set -Eeuo nounset
cd "$(dirname "$0")"

BCM_CLI_VERB=
BCM_PASS_NAME=

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
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
    -v "$PASSWORD_STORE_DIR":/home/user/.password-store:rw \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" bash -c "pass generate $BCM_PASS_NAME --no-symbols 32 >>/dev/null"
    
    elif [[ $BCM_CLI_VERB == "init" ]]; then
    
    # This is where we will store our GPG-encrypted passwords.
    echo "PASSWORD_STORE_DIR: $PASSWORD_STORE_DIR"
    if [ ! -d "$PASSWORD_STORE_DIR" ]; then
        bash -c "$BCM_GIT_DIR/commands/git_init_dir.sh $PASSWORD_STORE_DIR"
    fi
    
    # let's call bcm pass init to initialze the password store using our
    # recently generated trezor-backed GPG certificates.
    # shellcheck disable=SC1090
    source "$BCM_GIT_DIR/controller/export_usb_path.sh"
    
    if [[ ! -f $GNUPGHOME/env ]]; then
        echo "$GNUPGHOME/env does not exist. Exiting"
        exit
    fi

    if [[ ! -d "$PASSWORD_STORE_DIR/.git" ]]; then
        (
            cd "$PASSWORD_STORE_DIR" || exit
            git init
            git config --local user.name "$BCM_CERT_USERNAME"
            git config --local user.email "$(whoami)@$BCM_CERT_HOSTNAME"
            touch debug.log
            echo "Created $PASSWORD_STORE_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." >"$PASSWORD_STORE_DIR/debug.log"
            git add "*"
            git commit -m "Initialized git repo."
        )
    fi
    
    # only run this if we don't have a .gpg-id file, which indicates it's
    # already been initialized
    if [[ ! -f "$GNUPGHOME/.gpg-id" ]]; then
        docker run -it --name pass --rm \
        -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
        -v "$GNUPGHOME":/home/user/.gnupg \
        -v "$PASSWORD_STORE_DIR":/home/user/.password-store \
        -e BCM_CERT_NAME="$BCM_CERT_NAME" \
        -e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
        -e BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        "bcm-trezor:$BCM_VERSION" pass init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
    else
        echo "WARNING: The password repo has already been initialized."
    fi
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
    -v "$PASSWORD_STORE_DIR":/home/user/.password-store \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass "$BCM_PASS_NAME"
    
    elif [[ $BCM_CLI_VERB == "list" || $BCM_CLI_VERB == "ls" ]]; then
    docker run -it --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:ro \
    -v "$PASSWORD_STORE_DIR":/home/user/.password-store \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass ls
    
    elif [[ $BCM_CLI_VERB == "rm" || $BCM_CLI_VERB == "remove" ]]; then
    docker run -it --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:rw \
    -v "$PASSWORD_STORE_DIR":/home/user/.password-store \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass rm "$BCM_PASS_NAME"
    
    elif [[ $BCM_CLI_VERB == "insert" ]]; then
    docker run -it --name pass --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg:rw \
    -v "$PASSWORD_STORE_DIR":/home/user/.password-store \
    -e BCM_PASS_NAME="$BCM_PASS_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" pass insert "$BCM_PASS_NAME"
fi