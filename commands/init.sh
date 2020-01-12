#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=

for i in "$@"; do
    case $i in
        --cert-name=*)
            BCM_CERT_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --username=*)
            BCM_CERT_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --hostname=*)
            BCM_CERT_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --cert-dir=*)
            GNUPGHOME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ "$BCM_HELP_FLAG" == 1 ]]; then
    cat ./init-help.txt
    exit
fi

echo "INFO: your GNUPGHOME is uninitialized. Please plug in your trezor so we can generate some certificates in '$GNUPGHOME'."
while [[ -z "$BCM_CERT_NAME" ]]; do
    echo "Please enter the title of the certificate. This is usually your name:  "
    read -rp "Certificate Title:  "   BCM_CERT_NAME
done

while [[ -z "$BCM_CERT_USERNAME" ]]; do
    echo "Please enter the username of the certificate. This is the username part of an email address:  "
    read -rp "Username:  "   BCM_CERT_USERNAME
done

while [[ -z "$BCM_CERT_HOSTNAME" ]]; do
    echo "Please enter the domain name of the certificate. This is the FQDN/domain of the email address:  "
    read -rp "Domain Name:  "   BCM_CERT_HOSTNAME
done

# shellcheck disable=SC2153
bash -c "$BCM_GIT_DIR/commands/git_init_dir.sh $GNUPGHOME"

echo "Your certificate will appear as:  '$BCM_CERT_NAME $BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME'"

source "$BCM_GIT_DIR/controller/export_usb_path.sh"
if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
    # run the container.
    docker run -it --name trezorgpg --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$GNUPGHOME":/home/user/.gnupg \
    -e BCM_CERT_NAME="$BCM_CERT_NAME" \
    -e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
    -e BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" trezor-gpg init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
    
    echo "Your public key and public keyring material can be found at '$GNUPGHOME'."
fi

mkdir -p "$PASSWORD_STORE_DIR"
if [[ ! -d "$PASSWORD_STORE_DIR/.git" ]]; then
    # now let's initialize the password repository with the GPG key
    bash -c "$BCM_GIT_DIR/commands/pass/entrypoint.sh --name=$BCM_CERT_NAME --username=$BCM_CERT_USERNAME --hostname=$BCM_CERT_HOSTNAME"
    
    echo "Your GPG keys and password store have successfully initialized. Be sure to back it up!"
else
    echo "ERROR: $PASSWORD_STORE_DIR already exists."
    exit
fi
