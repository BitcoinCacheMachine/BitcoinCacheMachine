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
        *)
            # unknown option
        ;;
    esac
done

if [[ "$BCM_HELP_FLAG" == 1 ]]; then
    cat ./init-help.txt
    exit
fi

if [[ -z "$BCM_CERT_NAME" ]]; then
    echo "BCM_CERT_NAME not set. Please use '--cert-name='Satoshi Nakamoto'"
    exit
fi

if [[ -z "$BCM_CERT_USERNAME" ]]; then
    echo "BCM_CERT_USERNAME not set. Please use '--username='satoshi'"
    exit
fi

if [[ -z "$BCM_CERT_HOSTNAME" ]]; then
    echo "BCM_CERT_HOSTNAME not set. Please use '--hostname='bitcoin.org'"
    exit
fi

if [[ ! -d "$GNUPGHOME" ]]; then
    # shellcheck disable=SC2153
    bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $GNUPGHOME"
    
    bash -c "$BCM_GIT_DIR/controller/gpg-init.sh \
    --dir='$GNUPGHOME' \
    --name='$BCM_CERT_NAME' \
    --username='$BCM_CERT_USERNAME' \
    --hostname='$BCM_CERT_HOSTNAME'"
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