#!/bin/bash

set -eu
cd "$(dirname "$0")"


# if BCM_PROJECT_DIR is empty, we'll check to see if someone over-rode
# the trezor directory. If so, we'll send that in instead.
if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./commands/git/commit/help.txt
    exit
fi

echo "BCM_CERT_DIR: $BCM_CERT_DIR"
echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"
echo "BCM_GIT_REPO_DIR: $BCM_GIT_REPO_DIR"
echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
echo "BCM_EMAIL_ADDRESS: $BCM_EMAIL_ADDRESS"
echo "BCM_GPG_SIGNING_KEY_ID: $BCM_GPG_SIGNING_KEY_ID"

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

bash -c "$BCM_LOCAL_GIT_REPO/mgmt_plane/build.sh"
if [[ ! -z $(docker image list | grep "bcm-gpgagent:latest") ]]; then
    docker build -t bcm-gpgagent:latest .
else
    # make sure the container is up-to-date, but don't display
    docker build -t bcm-gpgagent:latest . >> /dev/null
fi

# get the locatio of the trezor
export BCM_TREZOR_USB_PATH=$(bcm info | grep "TREZOR_USB_PATH" | awk 'NF>1{print $NF}')

docker run -d --name=bcm-trezor-gitter \
    -v $BCM_CERT_DIR:/root/.gnupg \
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

docker stop bcm-trezor-gitter
docker rm bcm-trezor-gitter
