#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_GIT_COMMIT_MESSAGE=
BCM_GIT_CLIENT_USERNAME=
BCM_EMAIL_ADDRESS=
BCM_GIT_REPO_DIR=$BCM_RUNTIME_DIR
BCM_CERTS_DIR=$BCM_RUNTIME_DIR/certs

for i in "$@"
do
case $i in
    --cert-dir=*)
    BCM_CERTS_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --git-repo-dir=*)
    BCM_GIT_REPO_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --git-commit-message=*)
    BCM_GIT_COMMIT_MESSAGE="${i#*=}"
    shift # past argument=value
    ;;
    --git-username=*)
    BCM_GIT_CLIENT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    --email-address=*)
    BCM_EMAIL_ADDRESS="${i#*=}"
    shift # past argument=value
    ;;
    --gpg-signing-key-id=*)
    BCM_GPG_SIGNING_KEY_ID="${i#*=}"
    shift # past argument=value
    ;;
    --trezor-usb-path=*)
    BCM_TREZOR_USB_PATH="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

# quit if a commit message wasn't passed.
if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
    echo "BCM_GIT_COMMIT_MESSAGE is not set. Exiting."
    exit
fi

# get the latest commit
cd $BCM_LOCAL_GIT_REPO_DIR
export GIT_COMMIT_VERSION=$(git log --format="%H" -n 1)
cd -

BCM_CERT_ENV=$BCM_RUNTIME_DIR/certs/.env
if [[ ! -f $BCM_CERT_ENV ]]; then
    echo "No $BCM_CERT_ENV file found so source."
    exit
fi

echo "Sourcing $BCM_CERT_ENV"
source $BCM_CERT_ENV
echo "------------$BCM_DEFAULT_KEY_ID----------------"

echo "BCM_DEFAULT_KEY_ID: $BCM_DEFAULT_KEY_ID"

bcm git commit \
    --cert-dir="$BCM_CERTS_DIR" \
    --git-repo-dir="$BCM_GIT_REPO_DIR" \
    --git-commit-message="$BCM_GIT_COMMIT_MESSAGE" \
    --git-username="$BCM_CERT_USERNAME" \
    --email-address="$BCM_CERT_USERNAME@$BCM_CERT_FQDN" \
    --gpg-signing-key-id="$BCM_DEFAULT_KEY_ID"
