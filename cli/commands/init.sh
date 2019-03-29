#!/bin/bash

set -Eeuox pipefail
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

if [[ -d "$GNUPGHOME" ]]; then
    exit
fi


if [[ ! -d "$GNUPGHOME" ]]; then
    echo "Your Trezor-backed GPG certificates do not exist. Let's create them now. Make sure you have your Trezor handy."
    
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
    bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $GNUPGHOME"
    
    if ! docker image list --format "{{.Repository}}" | grep -q "bcm-trezor"; then
        bash -c "$BCM_GIT_DIR/controller/build.sh"
    fi
    
    echo "Your certificate will appear as:  '$BCM_CERT_NAME $BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME'"
    
    # shellcheck disable=SC1091
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
        bcm-trezor:latest trezor-gpg init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
        
        echo "Your public key and public keyring material can be found at '$GNUPGHOME/trezor'."
    fi
    
    BCM_DEFAULT_KEY_ID=$(docker run -it --name trezorgpg --rm -v "$GNUPGHOME":/home/user/.gnupg bcm-trezor:latest gpg --no-permission-warning --list-keys --keyid-format LONG | grep nistp256 | grep pub | sed 's/^[^/]*:/:/')
    BCM_DEFAULT_KEY_ID="${BCM_DEFAULT_KEY_ID#*/}"
    BCM_DEFAULT_KEY_ID="$(echo "$BCM_DEFAULT_KEY_ID" | awk '{print $1}')"
    
    {
        echo "export BCM_DEFAULT_KEY_ID="'"'"$BCM_DEFAULT_KEY_ID"'"'
        # shellcheck disable=SC2086
        echo "export BCM_CERT_NAME="'"'$BCM_CERT_NAME'"'
        
        # shellcheck disable=SC2086
        echo "export BCM_CERT_USERNAME="'"'$BCM_CERT_USERNAME'"'
        
        # shellcheck disable=SC2086
        echo "export BCM_CERT_HOSTNAME="'"'$BCM_CERT_HOSTNAME'"'
    } >>"$GNUPGHOME/env"
else
    echo "ERROR: '$GNUPGHOME' already exists. You can delete your certificate store by running 'bcm reset'"
    exit
fi

if [[ ! -d "$PASSWORD_STORE_DIR" ]]; then
    # now let's initialize the password repository with the GPG key
    bcm pass init --name="$BCM_CERT_NAME" --username="$BCM_CERT_USERNAME" --hostname="$BCM_CERT_HOSTNAME"
    
    echo "Your GPG keys and password store have successfully initialized. Be sure to back it up!"
else
    echo "ERROR: $PASSWORD_STORE_DIR already exists."
    exit
fi