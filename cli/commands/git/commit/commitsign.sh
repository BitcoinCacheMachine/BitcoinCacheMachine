#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_PUBLIC_CERT_DIR=
BCM_GIT_COMMIT_MESSAGE=
BCM_GIT_REPO_DIR=
BCM_EMAIL_ADDRESS=
BCM_GPG_SIGNING_KEY_ID=

for i in "$@"
do
case $i in
    --cert-dir=*)
    BCM_PUBLIC_CERT_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --git-repo-dir=*)
    BCM_GIT_REPO_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --commit-message=*)
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

echo "BCM_PUBLIC_CERT_DIR: $BCM_PUBLIC_CERT_DIR"
echo "BCM_GIT_REPO_DIR: $BCM_GIT_REPO_DIR"
echo "BCM_TREZOR_USB_PATH: $BCM_TREZOR_USB_PATH"
echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
echo "BCM_EMAIL_ADDRESS: $BCM_EMAIL_ADDRESS"
echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"

# we need to stop any existing containers if there is any.
if [[ $(docker ps | grep "bcm-trezor-gitter") ]]; then
    docker kill bcm-trezor-gitter
    sleep 2
fi

# we need to stop any existing containers if there is any.
if [[ $(docker ps -a | grep "bcm-trezor-gitter") ]]; then
    docker system prune -f
    sleep 3
fi

if [[ ! -d $BCM_PUBLIC_CERT_DIR ]]; then
    echo "'$BCM_PUBLIC_CERT_DIR' does not exist. Exiting."
    exit
fi

bash -c "$BCM_LOCAL_GIT_REPO/mgmt_plane/build.sh"
docker build -t bcm-gpgagent:latest .

docker run -d --name=bcm-trezor-gitter \
    -v $BCM_PUBLIC_CERT_DIR:/root/.gnupg \
    -v $BCM_GIT_REPO_DIR:/gitrepo \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-gpgagent:latest

sleep 3

docker exec -t \
    -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
    -e BCM_EMAIL_ADDRESS="$BCM_EMAIL_ADDRESS" \
    -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
    -e BCM_GPG_SIGNING_KEY_ID="$BCM_GPG_SIGNING_KEY_ID" \
     bcm-trezor-gitter /bcm/commit_sign_git_repo.sh

docker kill bcm-trezor-gitter
docker system prune -f