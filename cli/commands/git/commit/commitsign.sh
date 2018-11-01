#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

docker build -t bcm-gpgagent:latest .

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
    echo "BCM_GIT_COMMIT_MESSAGE is not set. Exiting"
    exit
fi

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_GIT_REPO_DIR ]]; then
    echo "BCM_GIT_REPO_DIR is not set. Exiting"
    exit
fi

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_EMAIL_ADDRESS ]]; then
    echo "BCM_EMAIL_ADDRESS is not set. Exiting"
    exit
fi

# we need to stop any existing containers if there is any.
if [[ $(docker ps | grep "bcm-trezor-gitter") ]]; then
    docker kill bcm-trezor-gitter
fi

# we need to stop any existing containers if there is any.
if [[ $(docker ps -a | grep "bcm-trezor-gitter") ]]; then
    docker system prune -f
fi

bash -c "$BCM_LOCAL_GIT_REPO/mgmt_plane/build.sh"

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_PUBLIC_CERT_DIR ]]; then
    echo "BCM_PUBLIC_CERT_DIR is not set. Exiting"
    exit
else
    if [[ ! -d $BCM_PUBLIC_CERT_DIR ]]; then
        echo "'$BCM_PUBLIC_CERT_DIR' does not exist. Exiting."
        exit
    fi
fi

echo "BCM_PUBLIC_CERT_DIR: $BCM_PUBLIC_CERT_DIR"
echo "BCM_GIT_REPO_DIR: $BCM_GIT_REPO_DIR"
echo "BCM_TREZOR_USB_PATH: $BCM_TREZOR_USB_PATH"
echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
echo "BCM_EMAIL_ADDRESS: $BCM_EMAIL_ADDRESS"
echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"

docker run -d --name=bcm-trezor-gitter \
    -v $BCM_PUBLIC_CERT_DIR:/root/.gnupg \
    -v $BCM_GIT_REPO_DIR:/gitrepo \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-gpgagent:latest

sleep 2

docker exec -it \
    -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
    -e BCM_EMAIL_ADDRESS="$BCM_EMAIL_ADDRESS" \
    -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
    bcm-trezor-gitter /bcm/commit_sign_git_repo.sh

docker kill bcm-trezor-gitter
docker system prune -f